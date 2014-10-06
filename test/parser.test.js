/**
 * Created by Mikhail Zyatin on 07.07.14.
 */


var expect = require('chai').expect,
    parser = require('../lib/parser'),
    fs = require('fs'),
    tweetRules = fs.readFileSync('./test/fixtures/tweet.gry').toString();


describe('parser', function () {
    "use strict";

    it('should export parser', function () {
        expect(parser).to.be.an('object');
        expect(parser).to.respondTo('parse');
    });

    it('should parse tweet rules', function () {
        expect(function () {
            parser.parse(tweetRules);
        }).to.not.throw();
    });

    describe('relations', function () {
        it('should support unnamed relations for embedded objects', function () {
            expect(parser.parse('-->metadata')).to.be.deep.equal([
                {
                    rule: "link",
                    attribute: {
                        name: "metadata"
                    }
                }
            ]);
        });

        it('should support out relations', function () {
            expect(parser.parse('--[SPAM]-->spam:Spam')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: { name: "SPAM" },
                    attribute: {
                        name: "spam",
                        type: {
                            type: "object",
                            title: "Spam"
                        }
                    }
                }
            ]);
        });

        it('should support in relations', function () {
            expect(parser.parse('<--[EGGS]--eggs:Eggs')).to.be.deep.equal([
                {
                    rule: "relation",
                    in: { name: "EGGS" },
                    attribute: {
                        name: "eggs",
                        type: {
                            type: "object",
                            title: "Eggs"
                        }
                    }
                }
            ]);
        });

        it('should support bidirectional relations', function () {
            expect(parser.parse('<--[HAM|SPAM]-->spam:Spam')).to.be.deep.equal([
                {
                    rule: "relation",
                    in: { name: "HAM" },
                    out: { name: "SPAM" },
                    attribute: {
                        name: "spam",
                        type: {
                            type: "object",
                            title: "Spam"
                        }
                    }
                }
            ]);
        });

        it('should support relation attributes', function () {
            expect(parser.parse('--[PARTICIPATE_IN(score, wins)]--> game:Game')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: {
                        name: "PARTICIPATE_IN",
                        attributes: [
                            { name: "score" },
                            { name: "wins" }
                        ]
                    },
                    attribute: {
                        name: "game",
                        type: {
                            type: "object",
                            title: "Game"
                        }
                    }
                }
            ]);
        });
    });

    describe('attributes', function () {
        it('should support property paths', function () {
            expect(parser.parse('--[CITIZEN_OF]--> place.country:Country')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: { name: "CITIZEN_OF" },
                    attribute: {
                        name: "place.country",
                        type: {
                            type: "object",
                            title: "Country"
                        }
                    }
                }
            ]);
        });

        it('should support attribute rewrite', function () {
            expect(parser.parse('--[CITIZEN_OF]--> place.country => country:Country')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: { name: "CITIZEN_OF" },
                    attribute: {
                        name: "country",
                        type: {
                            type: "object",
                            title: "Country"
                        },
                        aliasOf: { name: "place.country"}
                    }
                }
            ]);
        });

        it('should support attribute type constraints', function () {
            expect(parser.parse('+ firstName :String')).to.be.deep.equal([
                {
                    rule: "attribute",
                    attribute: {
                        name: "firstName",
                        type: {
                            type: "object",
                            title: "String"
                        }
                    }
                }
            ]);
        });
    });

    describe('indices', function () {
        it('should support unique indices', function () {
            expect(parser.parse('UNIQUE(id)')).to.be.deep.equal([
                {
                    rule: "index",
                    key: [
                        { name: "id" }
                    ],
                    type: "unique"
                }
            ]);
        });

        it('should support compound unique indices', function () {
            expect(parser.parse('UNIQUE(firstName, lastName)')).to.be.deep.equal([
                {
                    rule: "index",
                    key: [
                        { name: "firstName" },
                        { name: "lastName" }
                    ],
                    type: "unique"
                }
            ]);
        });
    });

    describe('types', function () {
        it('should support types for attributes', function () {
            expect(parser.parse('UNIQUE(id:Int)')).to.be.deep.equal([
                {
                    rule: "index",
                    key: [
                        {
                            name: "id",
                            type: {
                                type: "object",
                                title: "Int"
                            }
                        }
                    ],
                    type: "unique"
                }
            ]);
        });

        it('should treat class references as types', function () {
            expect(parser.parse('--> tweet:Tweet')).to.be.deep.equal([
                {
                    rule: "link",
                    attribute: {
                        name: "tweet",
                        type: {
                            type: "object",
                            title: "Tweet"
                        }
                    }
                }
            ]);
        });

        it('should support array of type', function () {
            expect(parser.parse('--> comments:Comment[]')).to.be.deep.equal([
                {
                    rule: "link",
                    attribute: {
                        name: "comments",
                        type: {
                            type: "object",
                            title: "Comment",
                            isArrayOf: true,
                            arrayDepth: 1
                        }
                    }
                }
            ]);
        });

        it('should support arrays of arrays for type', function () {
            expect(parser.parse('--> commentSets:Comment[][][]')).to.be.deep.equal([
                {
                    rule: "link",
                    attribute: {
                        name: "commentSets",
                        type: {
                            type: "object",
                            title: "Comment",
                            isArrayOf: true,
                            arrayDepth: 3
                        }
                    }
                }
            ]);
        });

        it('should support untyped arrays', function () {
            expect(parser.parse('--> issues[]')).to.be.deep.equal([
                {
                    rule: "link",
                    attribute: {
                        name: "issues",
                        type: "array"
                    }
                }
            ]);
        });

        it('should not allow array ambiguities', function () {
            expect(function() {
                parser.parse('--> issues[]:Issue');
            }).to.throw();
        });

        it.only('should support arrays of immediately defined classes', function () {
            expect(parser.parse('--> issues:Issue(id)[]')).to.be.deep.equal([
                {
                    rule: "link",
                    attribute: {
                        name: "issues",
                        type: {
                            type: "object",
                            title: "Issue",
                            arrayDepth: 1,
                            isArrayOf: true,
                            rules: [
                                {
                                    rule: "index",
                                    key: [
                                        { name: "id" }
                                    ],
                                    type: "unique"
                                }
                            ],
                            rule: "definition"
                        }
                    }
                }
            ]);
        });
    });

    describe('classes', function () {
        it('should support simple class declaration', function () {
            expect(parser.parse('def Tweet')).to.be.deep.equal([
                {
                    type: "object",
                    rule: "definition",
                    title: "Tweet"
                }
            ]);
        });

        it('should support class declaration with plain index', function () {
            expect(parser.parse('def HashTag(text)')).to.be.deep.equal([
                {
                    type: "object",
                    title: "HashTag",
                    rules: [
                        {
                            rule: "index",
                            key: [
                                { name: "text" }
                            ],
                            type: "unique"
                        }
                    ],
                    rule: "definition"
                }
            ]);
        });

        it('should support class declaration with compound index', function () {
            expect(parser.parse('def Person(firstname, lastname)')).to.be.deep.equal([
                {
                    type: "object",
                    title: "Person",
                    rules: [
                        {
                            rule: "index",
                            key: [
                                { name: "firstname" },
                                { name: "lastname" }
                            ],
                            type: "unique"
                        }
                    ],
                    rule: "definition"}
            ]);
        });

        it('should support paths for indices in class declarations', function () {
            expect(parser.parse('def Citizen(credentials.passport.number)')).to.be.deep.equal([
                {
                    type: "object",
                    title: "Citizen",
                    rules: [
                        {
                            rule: "index",
                            key: [
                                { name: "credentials.passport.number" }
                            ],
                            type: "unique"
                        }
                    ],
                    rule: "definition"}
            ]);
        });

        it('should support array destructing for index at class definition', function () {
            expect(parser.parse('def Location(coordinates[longitude, latitude])')).to.be.deep.equal([
                {
                    type: "object",
                    title: "Location",
                    rules: [
                        {
                            rule: "index",
                            key: [
                                {
                                    name: "coordinates",
                                    keys: [
                                        { name: "longitude" },
                                        { name: "latitude" }
                                    ]
                                }
                            ],
                            type: "unique"
                        }
                    ],
                    rule: "definition"}
            ]);
        });

        it('should support class declaration with multiple rules', function () {
            expect(parser.parse('def User(passport.id) {' +
                '    --[CHILD_OF]--> father:Person' +
                '}')).to.be.deep.equal([
                    {
                        type: "object",
                        title: "User",
                        rules: [
                            {
                                rule: "relation",
                                out: { name: "CHILD_OF" },
                                attribute: {
                                    name: "father",
                                    type: {
                                        type: "object",
                                        title: "Person"
                                    }
                                }
                            },
                            {
                                rule: "index",
                                key: [
                                    { name: "passport.id" }
                                ],
                                type: "unique"
                            }
                        ],
                        rule: "definition"
                    }
                ]);
        });

        describe('enumerations', function () {
            it('should be defined by array syntax', function () {
                expect(parser.parse('def Coordinates [ longitude, latitude ]')).to.be.deep.equal([
                    {
                        type: "object",
                        rule: "enumeration",
                        title: "Coordinates",
                        elements: [
                            { name: "longitude" },
                            { name: "latitude" }
                        ]
                    }
                ]);
            });

            it('should support rules definition for enumerations', function () {
                expect(parser.parse('def VendorCoordinates [ longitude, latitude, vendor ] {' +
                    'UNIQUE(longitude, latitude, vendor.id)' +
                    '}')).to.be.deep.equal([
                    {
                        type: "object",
                        rule: "enumeration",
                        title: "VendorCoordinates",
                        elements: [
                            { name: "longitude" },
                            { name: "latitude" },
                            { name: "vendor" }
                        ],
                        rules: [
                            {
                                rule: "index",
                                key: [
                                    { name: "longitude" },
                                    { name: "latitude" },
                                    { name :"vendor.id"}
                                ],
                                type: "unique"
                            }
                        ]
                    }
                ]);
            });
        });

        describe('inline declarations', function () {
            it('should support inline dummy class definitions', function () {
                expect(parser.parse('--[POPULATED_WITH]--> comment:Comment()')).to.be.deep.equal([
                    {
                        rule: "relation",
                        out: { name: "POPULATED_WITH" },
                        attribute: {
                            name: "comment",
                            type: {
                                type: "object",
                                title: "Comment",
                                rule: "definition",
                                rules: []
                            }
                        }
                    }
                ]);
            });

            it('should support inline class definitions with indices', function () {
                expect(parser.parse('--[POPULATED_WITH]--> comment:Comment(id)')).to.be.deep.equal([
                    {
                        rule: "relation",
                        out: { name: "POPULATED_WITH" },
                        attribute: {
                            name: "comment",
                            type: {
                                type: "object",
                                title: "Comment",
                                rule: "definition",
                                rules: [
                                    {
                                        rule: "index",
                                        key: [
                                            { name: "id" }
                                        ],
                                        type: "unique"
                                    }
                                ]
                            }
                        }
                    }
                ]);
            });
        });
    });
});
