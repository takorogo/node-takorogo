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


    describe 'properties', ->


    describe 'links', ->
