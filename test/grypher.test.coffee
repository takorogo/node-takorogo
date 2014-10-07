# Created by Mikhail Zyatin on 03.10.14.

'use strict'


sinon = require('sinon')
sinonChai = require('sinon-chai')
chai = require('chai')
expect = chai.expect
parser = require('../lib/parser')
Grypher = require('../lib/grypher')
fs = require('fs')
tweetRules = fs.readFileSync('./test/fixtures/tweet.gry').toString()

chai.use(sinonChai)


describe 'grypher', () ->
    it 'should export Grypher class', () ->
        expect(Grypher).to.be.a('function')

    it 'should wrap parser', () ->
        spy = sinon.spy(parser, 'parse')
        grypher = new Grypher(parser)

        expect(grypher).to.respondTo('parse')
        grypher.parse(tweetRules)

        expect(spy).have.been.called.once
        expect(spy).have.been.calledWith(tweetRules)

        spy.restore()
