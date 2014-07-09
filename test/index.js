/**
 * Created by Mikhail Zyatin on 07.07.14.
 */


var expect = require('chai').expect,
    grypher = require('..'),
    fs = require('fs'),
    tweetRules = fs.readFileSync('./test/fixtures/tweet.gry').toString();


describe('grypher', function () {
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

    describe('relations', function () {
        it('should support embed object rules', function () {
            expect(grypher.parse('-->metadata')).to.be.deep.equal([
                {
                    _rule: "relation",
                    type: "embed",
                    attribute: { name: "metadata" }
                }
            ]);
        });

        it('should support out relations', function () {
            expect(grypher.parse('--[SPAM]-->spam:Spam')).to.be.deep.equal([
                {
                    _rule: "relation",
                    out: { name: "SPAM" },
                    type: {
                        _type: "class",
                        name: "Spam"
                    },
                    attribute: { name: "spam" }
                }
            ]);
        });

        it('should support in relations', function () {
            expect(grypher.parse('<--[EGGS]--eggs:Eggs')).to.be.deep.equal([
                {
                    _rule: "relation",
                    in: { name: "EGGS" },
                    type: {
                        _type: "class",
                        name: "Eggs"
                    },
                    attribute: { name: "eggs" }
                }
            ]);
        });

        it('should support bidirectional relations', function () {
            expect(grypher.parse('<--[HAM|SPAM]-->spam:Spam')).to.be.deep.equal([
                {
                    _rule: "relation",
                    in: { name: "HAM" },
                    out: { name: "SPAM" },
                    type: {
                        _type: "class",
                        name: "Spam"
                    },
                    attribute: { name: "spam" }
                }
            ]);
        });

        it('should support inline class definitions', function () {
            expect(grypher.parse('--[SPAM]-->spam:Spam(eggs)')).to.be.deep.equal([
                {
                    _rule: "relation",
                    out: { name: "SPAM" },
                    type: {
                        _type: "class",
                        name: "Spam",
                        rules: [
                            {
                                _rule: "index",
                                index: [
                                    { name: "eggs" }
                                ],
                                type: "unique"
                            }
                        ]
                    },
                    attribute: { name: "spam" }
                }
            ]);
        });

        it('should support relation attributes', function () {
            expect(grypher.parse('--[PARTICIPATE_IN(score, wins)]--> game:Game')).to.be.deep.equal([
                {
                    _rule: "relation",
                    out: {
                        name: "PARTICIPATE_IN",
                        keys: [
                            { name:"score" },
                            { name:"wins" }
                        ]
                    },
                    type: {
                        _type: "class",
                        name: "Game"
                    },
                    attribute: { name: "game" }
                }
            ]);
        });
    });
});
