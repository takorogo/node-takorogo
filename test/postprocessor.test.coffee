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


describe 'postprocessor', () ->
    it 'should export Postprocessor class', () ->
        expect(Postprocessor).to.be.a('function')

    it 'should consume grypher parser results', () ->
        postprocessor = new Postprocessor
        expect(->
            postprocessor.postprocess(parser.parse(tweetRules))
        ).to.not.throw()


    describe 'classes', () ->


    describe 'enumerations', () ->


    describe 'indexes', () ->


    describe 'relations', () ->


    describe 'properties', () ->


    describe 'links', () ->
