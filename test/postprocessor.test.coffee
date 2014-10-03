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

    it.only 'should wrap parser', () ->
        spy = sinon.spy(parser, 'parse')
        postprocessor = new Postprocessor(parser)

        expect(postprocessor).to.respondTo('parse')
        postprocessor.parse(tweetRules)

        expect(spy).have.been.called.once
        expect(spy).have.been.calledWith(tweetRules)

        spy.restore()
