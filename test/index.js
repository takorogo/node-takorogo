/**
 * Created by Mikhail Zyatin on 07.07.14.
 */


var expect = require('chai').expect,
    grypher = require('..'),
    fs = require('fs'),
    tweetRules = fs.readFileSync('./test/fixtures/tweet.gry').toString();


describe('node-grypher', function () {
    "use strict";

    it('should export parser', function () {
        expect(grypher).to.be.an('object');
        expect(grypher).to.respondTo('parse');
    });

    it('should parse tweet rules', function () {
        expect(function () {
            grypher.parse(tweetRules);
        }).to.not.throw();
    });
});
