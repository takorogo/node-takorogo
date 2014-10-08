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
        simpleEnumerationDefinition = null

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
            simpleEnumerationDefinition = simpleEnumerationSchema.definitions.Coordinates

        it 'should describe enumerations as extended definition', ->
            expect(simpleEnumerationSchema.definitions).to.have.property('Coordinates')

        it 'should describe enumeration as arrays with strict item count', ->
            expect(simpleEnumerationDefinition).to.have.property('type', 'array')
            expect(simpleEnumerationDefinition).to.have.property('maxItems', 2)
            expect(simpleEnumerationDefinition).to.have.property('minItems', 2)

        it 'should list array item names', ->
            expect(simpleEnumerationDefinition).to.have.property('elements').deep.equal([
                'longitude'
                'latitude'
            ])

        it 'should refer to destructured object definition', ->
            expect(simpleEnumerationDefinition).to.have.property('destructuredTo')
            expect(simpleEnumerationDefinition.destructuredTo)
                .to.have.property('$ref', '#/definitions/Coordinates/definitions/__Coordinates__')

        it 'should generate definition for object to which array should be converted', ->
            expect(simpleEnumerationDefinition.definitions).to.have.property('__Coordinates__')
            
        
        describe 'destructured object definition', ->
            simpleDestructuredObjectDefinition = null

            beforeEach ->
                simpleDestructuredObjectDefinition =
                    simpleEnumerationDefinition.definitions.__Coordinates__
            
            it 'should be a definition', ->
                expect(simpleDestructuredObjectDefinition).to.have.property('title', '__Coordinates__')
                expect(simpleDestructuredObjectDefinition).to.have.property('type', 'object')

            it 'should describe destructured properties', ->
                expect(simpleDestructuredObjectDefinition).to.have.property('properties')
                expect(simpleDestructuredObjectDefinition.properties).to.have.property('longitude')
                expect(simpleDestructuredObjectDefinition.properties).to.have.property('latitude')

            it 'should restrict properties exactly to what was destructured from array', ->
                expect(simpleDestructuredObjectDefinition).to.have.property('additionalProperties', false)
                expect(simpleDestructuredObjectDefinition).to.have.property('required').deep.equal([
                    'longitude'
                    'latitude'
                ])


    describe 'indexes', ->
        simpleIndexSchema = null

        beforeEach ->
            simpleIndexSchema = postprocessor.postprocess([
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
            expect(simpleIndexSchema.definitions.Tweet).to.have.property('indexes').deep.equals [
                key: [ 'id' ]
                type: 'unique'
            ]

        it 'should add index properties and make them required if necessary', ->
            expect(simpleIndexSchema.definitions.Tweet)
                .to.have.property('properties').deep.equals(id: {})
            expect(simpleIndexSchema.definitions.Tweet)
                .to.have.property('required').deep.equals([ 'id' ])


    describe 'relations', ->
        simpleRelationDefinition = null

        beforeEach ->
            simpleRelationDefinition = postprocessor.postprocess([
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
            expect(simpleRelationDefinition.relations).to.have.property('author')

        it 'should save relation direction', ->
            expect(simpleRelationDefinition.relations.author.out).to.have.property('name', 'CREATED_BY')

        it 'should save relation attributes', ->
            expect(simpleRelationDefinition.relations.author.out).to.have.property('attributes')
            expect(simpleRelationDefinition.relations.author.out.attributes).to.contain('when')

        it 'should treat relations as implicit properties declarations', ->
            expect(simpleRelationDefinition.properties).to.have.property('author')
            expect(simpleRelationDefinition.properties.author).to.have.property('type', 'User')

        it 'should specify what property is managed by relation', ->
            expect(simpleRelationDefinition.relations.author).to.have.property('property', 'author')

        it 'should treat relation attributes as implicit properties declarations', ->
            expect(simpleRelationDefinition.properties).to.have.property('when').deep.equals
                type: 'object'
                title: 'DateTime'


    describe 'links', ->


    describe 'properties', ->


    describe 'types', ->


    describe 'schema', ->
