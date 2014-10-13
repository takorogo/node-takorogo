# Created by Mikhail Zyatin on 03.10.14.

'use strict'


sinon = require('sinon')
sinonChai = require('sinon-chai')
chai = require('chai')
expect = chai.expect
parser = require('../lib/parser')
Postprocessor = require('../lib/postprocessor')
fs = require('fs')
tweetRules = fs.readFileSync('./test/fixtures/tweet.gry').toString()

chai.use(sinonChai)


describe 'postprocessor', ->
    postprocessor = null

    beforeEach ->
        postprocessor = new Postprocessor

    it 'should export Postprocessor class', ->
        expect(Postprocessor).to.be.a('function')

    it 'should consume grypher parser results', ->
        expect(->
            postprocessor.postprocess(parser.parse(tweetRules))
        ).to.not.throw()


    describe 'classes', ->
        it 'should move definitions to dedicated hash', ->
            expect(postprocessor.postprocess [
                type: 'object'
                rule: 'definition'
                title: 'Tweet'
            ]).to.be.deep.equal
                definitions:
                    Tweet:
                        type: 'object'
                        title: 'Tweet'

        it 'should treat main classes as schema definitions', ->
            schema = postprocessor.postprocess([
                type: 'object'
                rule: 'definition'
                isMainDefinition: true
                title: 'Tweet'
            ])

            expect(schema).to.have.property('$ref', '#/definitions/Tweet')
            expect(schema).to.have.property('title', 'Tweet')
            expect(schema).to.have.property('type', 'object')


    describe 'enumerations', ->
        simpleEnumerationSchema = null
        enumerationDefinition = null

        beforeEach ->
            simpleEnumerationSchema = postprocessor.postprocess([
                type: 'object'
                rule: 'enumeration'
                title: 'Coordinates'
                elements: [
                    { name: 'longitude' }
                    { name: 'latitude' }
                ]
            ])
            enumerationDefinition = simpleEnumerationSchema.definitions.Coordinates

        it 'should describe enumerations as extended definition', ->
            expect(simpleEnumerationSchema.definitions).to.have.property('Coordinates')

        it 'should describe enumeration as arrays with strict item count', ->
            expect(enumerationDefinition).to.have.property('type', 'array')
            expect(enumerationDefinition).to.have.property('maxItems', 2)
            expect(enumerationDefinition).to.have.property('minItems', 2)

        it 'should list array item names', ->
            expect(enumerationDefinition).to.have.property('elements').deep.equal([
                'longitude'
                'latitude'
            ])

        it 'should refer to destructured object definition', ->
            expect(enumerationDefinition).to.have.property('destructuredTo')
            expect(enumerationDefinition.destructuredTo)
                .to.have.property('$ref', '#/definitions/Coordinates/definitions/__Coordinates__')

        it 'should generate definition for object to which array should be converted', ->
            expect(enumerationDefinition.definitions).to.have.property('__Coordinates__')
            
        
        describe 'destructured object definition', ->
            destructuredObjectDefinition = null

            beforeEach ->
                destructuredObjectDefinition =
                    enumerationDefinition.definitions.__Coordinates__
            
            it 'should be a definition', ->
                expect(destructuredObjectDefinition).to.have.property('title', '__Coordinates__')
                expect(destructuredObjectDefinition).to.have.property('type', 'object')

            it 'should describe destructured properties', ->
                expect(destructuredObjectDefinition).to.have.property('properties')
                expect(destructuredObjectDefinition.properties).to.have.property('longitude')
                expect(destructuredObjectDefinition.properties).to.have.property('latitude')

            it 'should restrict properties exactly to what was destructured from array', ->
                expect(destructuredObjectDefinition).to.have.property('additionalProperties', false)
                expect(destructuredObjectDefinition).to.have.property('required').deep.equal([
                    'longitude'
                    'latitude'
                ])


    describe 'indexes', ->
        indexSchema = null

        beforeEach ->
            indexSchema = postprocessor.postprocess([
                type: 'object'
                rule: 'definition'
                isMainDefinition: true
                title: 'Tweet'
                rules: [
                    rule: 'index'
                    key: [ name: 'id' ]
                    type: 'unique'
                ]
            ])

        it 'should save indexes to dedicated hash', ->
            expect(indexSchema.definitions.Tweet).to.have.property('indexes').deep.equals [
                key: [ 'id' ]
                type: 'unique'
            ]

        it 'should add index properties and make them required if necessary', ->
            expect(indexSchema.definitions.Tweet)
                .to.have.property('properties').deep.equals(id: {})
            expect(indexSchema.definitions.Tweet)
                .to.have.property('required').deep.equals([ 'id' ])


    describe 'relations', ->
        relationDefinition = null

        beforeEach ->
            relationDefinition = postprocessor.postprocess([
                rule: 'relation'
                out:
                    name: 'CREATED_BY'
                    attributes: [
                        name: 'when'
                        type: 'object'
                        title: 'DateTime'
                    ]
                attribute:
                    name: 'author'
                    type:
                        type: 'object'
                        title: 'User'
            ])

        it 'should save relations to dedicated hash', ->
            expect(relationDefinition.relations).to.have.property('author')

        it 'should save relation direction', ->
            expect(relationDefinition.relations.author.out).to.have.property('name', 'CREATED_BY')

        it 'should save relation attributes', ->
            expect(relationDefinition.relations.author.out).to.have.property('attributes')
            expect(relationDefinition.relations.author.out.attributes).to.contain('when')

        it 'should treat relations as implicit properties declarations', ->
            expect(relationDefinition.properties).to.have.property('author')
            expect(relationDefinition.properties.author).to.have.property('type', 'User')

        it 'should specify what property is managed by relation', ->
            expect(relationDefinition.relations.author).to.have.property('property', 'author')

        it 'should treat relation attributes as implicit properties declarations', ->
            expect(relationDefinition.properties).to.have.property('when').deep.equals
                type: 'object'
                title: 'DateTime'

        describe 'resolving', ->
            resolvedRelationDefinition = null

            beforeEach ->
                resolvedRelationDefinition = postprocessor.postprocess([
                    rule: 'resolvedRelation'
                    out:
                        name: 'PLAYS'
                    attribute:
                        name: 'game'
                        type:
                            type: 'object'
                            title: 'Game'
                    resolve:
                        key: [
                            {
                                name: 'x'
                                aliasOf:
                                    name: 'longitude'
                            }
                            {
                                name: 'y'
                                aliasOf:
                                    name: 'latitude'
                            }
                        ]
                ])

            it 'should properly work with actual properties names', ->
                expect(resolvedRelationDefinition.properties).to.have.property('x')
                expect(resolvedRelationDefinition.aliases).to.have.property('x', 'longitude')
                expect(resolvedRelationDefinition.properties).to.have.property('y')
                expect(resolvedRelationDefinition.aliases).to.have.property('y', 'latitude')

            it 'should mark attributes as required', ->
                expect(resolvedRelationDefinition.required).to.contain('x')
                expect(resolvedRelationDefinition.required).to.contain('y')

            it 'should add relation at the end', ->
                expect(resolvedRelationDefinition.relations).has.property('game')

            it 'should put keys for resolving relations', ->
                expect(resolvedRelationDefinition.relations.game).has.property('resolve')
                expect(resolvedRelationDefinition.relations.game.resolve.key).to.contain('x')
                expect(resolvedRelationDefinition.relations.game.resolve.key).to.contain('y')

            it 'should not put relation attribute to schema', ->
                expect(resolvedRelationDefinition.properties).not.to.have.property('game')


    describe 'links', ->
        linkDefintion = null

        beforeEach ->
            linkDefintion = postprocessor.postprocess([
                rule: 'link'
                attribute:
                    name: 'metadata'
            ])

        it 'should store links into dedicated hash', ->
            expect(linkDefintion.links).to.have.property('metadata')

        it 'should point links to managed property', ->
            expect(linkDefintion.links.metadata).to.have.property('property', 'metadata')

        it 'should treat links as implicit properties declarations', ->
            expect(linkDefintion.properties).to.have.property('metadata')


    describe 'properties', ->
        propertyDefinition = null

        beforeEach ->
            propertyDefinition = postprocessor.postprocess([
                rule: "attribute"
                attribute:
                    name: 'place.country'
                    type:
                        type: 'object'
                        title: 'Country'
                    aliasOf:
                        name: 'profile.place.country'
            ])

        it 'should transform properties with paths into objects', ->
            expect(propertyDefinition.properties).to.have.property('place')
            expect(propertyDefinition.properties.place.properties)
                .to.have.property('country').deep.equals(type: 'Country')

        it 'should process aliases', ->
            expect(propertyDefinition.aliases).to.have.property('place.country', 'profile.place.country')


        describe 'inline definitions', ->
            inlineDefinition = null

            beforeEach ->
                inlineDefinition = postprocessor.postprocess([
                    rule: "attribute"
                    attribute:
                        name: 'country'
                        type:
                            type: 'object'
                            title: 'Country'
                            rules: [
                                rule: 'index'
                                key: [
                                    name: 'name'
                                ]
                                type: 'unique'
                            ]
                            rule: 'definition'
                ])

            it 'should properly resolve inline definitions', ->
                expect(inlineDefinition.properties.country).to.have.property('$ref', '#/definitions/Country')

            it 'should save inner type definitions', ->
                expect(inlineDefinition.definitions).to.have.property('Country')


        describe 'arrays', ->
            arrayDefinition = null

            beforeEach ->
                arrayDefinition = postprocessor.postprocess([
                    rule: "attribute"
                    attribute:
                        name: 'comment'
                        type:
                            type: 'object'
                            title: 'Comment'
                            isArrayOf: true
                            arrayDepth: 2
                            rules: [
                                    rule: 'index'
                                    key: [
                                        name: 'id'
                                    ]
                                    type: 'unique'
                            ]
                            rule: 'definition'

                ])

            it 'should wrap properly describe arrays', ->
                expect(arrayDefinition.properties.comment).to.have.property('type', 'array')
                expect(arrayDefinition.properties.comment).to.have.property('items')
                expect(arrayDefinition.properties.comment.items).to.have.property('type', 'array')
                expect(arrayDefinition.properties.comment.items).to.have.property('items')
                expect(arrayDefinition.properties.comment.items.items).to.have.property('type', 'object')

            it 'should properly resolve inline definitions', ->
                expect(arrayDefinition.properties.comment.items.items)
                    .to.have.property('$ref', '#/definitions/Comment')

            it 'should save inner type definitions', ->
                expect(arrayDefinition.definitions).to.have.property('Comment')


    describe 'types', ->
        classesDefinition = null

        beforeEach ->
            classesDefinition = postprocessor.postprocess([
                {
                    type: 'object'
                    rule: 'definition'
                    title: 'Tweet'
                    rules: [
                        rule: 'attribute'
                        attribute:
                            name: 'author'
                            type:
                                type: 'object'
                                title: 'User'
                    ]
                },
                {
                    type: 'object'
                    rule: 'definition'
                    title: 'User'
                    rules: [
                        rule: 'attribute'
                        attribute:
                            name: 'age'
                            type:
                                type: 'object'
                                title: 'Integer'
                    ]
                }
            ])

        it 'should resolve defined types', ->
            expect(classesDefinition.definitions).has.property('Tweet')
            expect(classesDefinition.definitions).has.property('User')
            expect(classesDefinition.definitions.Tweet.properties.author).has.property('$ref', '#/definitions/User')

        it 'should specify unresolvable types directly', ->
            expect(classesDefinition.definitions.User.properties.age).has.property('type', 'Integer')

        it 'should collect unresolvable types in special hash', ->
            expect(classesDefinition.unresolvedTypes).to.contain('Integer')


    describe 'meta definitions', ->

        it 'should support reserved global keywords', ->
            ['title', 'description'].forEach (key) ->
                expect(postprocessor.postprocess([
                    rule: 'meta'
                    key: key
                    value: 'Spam'
                ])).to.have.property(key, 'Spam')

        it 'should pit not-reserved meta definitions in dedicated hash', ->
            ['eggs', 'worship'].forEach (key) ->
                expect(postprocessor.postprocess([
                    rule: 'meta'
                    key: key
                    value: 'Spam'
                ]).metadata).to.have.property(key, 'Spam')
