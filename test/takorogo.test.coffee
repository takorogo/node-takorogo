# Created by Mikhail Zyatin on 03.10.14.

'use strict'


sinon = require('sinon')
sinonChai = require('sinon-chai')
chai = require('chai')
expect = chai.expect
parser = require('../lib/parser')
Takorogo = require('../lib/takorogo')
fs = require('fs')
tweetRules = fs.readFileSync('./test/fixtures/tweet.tako').toString()

chai.use(sinonChai)


describe 'takorogo', () ->
    it 'should export Takorogo class', () ->
        expect(Takorogo).to.be.a('function')

    it 'should wrap parser', () ->
        spy = sinon.spy(parser, 'parse')
        takorogo = new Takorogo(parser)

        expect(takorogo).to.respondTo('parse')
        takorogo.parse(tweetRules)

        expect(spy).have.been.called.once
        expect(spy).have.been.calledWith(tweetRules)

        spy.restore()
