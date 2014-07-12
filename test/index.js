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
        it('should support flattening of embedded objects', function () {
            expect(grypher.parse('-->metadata')).to.be.deep.equal([
                {
                    rule: "flatten",
                    attribute: { name: "metadata" }
                }
            ]);
        });

        it('should support out relations', function () {
            expect(grypher.parse('--[SPAM]-->spam:Spam')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: { name: "SPAM" },
                    attribute: {
                        name: "spam",
                        type: {
                            type: "class",
                            name: "Spam"
                        }
                    }
                }
            ]);
        });

        it('should support in relations', function () {
            expect(grypher.parse('<--[EGGS]--eggs:Eggs')).to.be.deep.equal([
                {
                    rule: "relation",
                    in: { name: "EGGS" },
                    attribute: {
                        name: "eggs",
                        type: {
                            type: "class",
                            name: "Eggs"
                        }
                    }
                }
            ]);
        });

        it('should support bidirectional relations', function () {
            expect(grypher.parse('<--[HAM|SPAM]-->spam:Spam')).to.be.deep.equal([
                {
                    rule: "relation",
                    in: { name: "HAM" },
                    out: { name: "SPAM" },
                    attribute: {
                        name: "spam",
                        type: {
                            type: "class",
                            name: "Spam"
                        }
                    }
                }
            ]);
        });

        it('should support relation attributes', function () {
            expect(grypher.parse('--[PARTICIPATE_IN(score, wins)]--> game:Game')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: {
                        name: "PARTICIPATE_IN",
                        keys: [
                            { name: "score" },
                            { name: "wins" }
                        ]
                    },
                    attribute: {
                        name: "game",
                        type: {
                            type: "class",
                            name: "Game"
                        }
                    }
                }
            ]);
        });
    });

    describe('attributes', function () {
        it('should support property paths', function () {
            expect(grypher.parse('--[CITIZEN_OF]--> place.country:Country')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: { name: "CITIZEN_OF" },
                    attribute: {
                        name: "place.country",
                        type: {
                            type: "class",
                            name: "Country"
                        }
                    }
                }
            ]);
        });

        it('should support attribute rewrite', function () {
            expect(grypher.parse('--[CITIZEN_OF]--> place.country => country:Country')).to.be.deep.equal([
                {
                    rule: "relation",
                    out: { name: "CITIZEN_OF" },
                    attribute: {
                        name: "country",
                        type: {
                            type: "class",
                            name: "Country"
                        },
                        aliasOf: { name: "place.country"}
                    }
                }
            ]);
        });

        it('should support attribute type constraints', function () {
            expect(grypher.parse('+ firstName :String')).to.be.deep.equal([
                {
                    rule: "attribute",
                    attribute: {
                        name: "firstName",
                        type: {
                            type: "class",
                            name: "String"
                        }
                    }
                }
            ]);
        });
    });

    describe('indices', function () {
        it('should support unique indices', function () {
            expect(grypher.parse('UNIQUE(id)')).to.be.deep.equal([
                {
                    rule: "index",
                    index: [
                        { name: "id" }
                    ],
                    type: "unique"
                }
            ]);
        });

        it('should support compound unique indices', function () {
            expect(grypher.parse('UNIQUE(firstName, lastName)')).to.be.deep.equal([
                {
                    rule: "index",
                    index: [
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
            expect(grypher.parse('UNIQUE(id:Int)')).to.be.deep.equal([
                {
                    rule: "index",
                    index: [
                        {
                            name: "id",
                            type: {
                                type: "class",
                                name: "Int"
                            }
                        }
                    ],
                    type: "unique"
                }
            ]);
        });

        it('should treat class references as types', function () {
            expect(grypher.parse('--> tweet:Tweet')).to.be.deep.equal([
                {
                    rule: "flatten",
                    attribute: {
                        name: "tweet",
                        type: {
                            type: "class",
                            name: "Tweet"
                        }
                    }
                }
            ]);
        });

        it('should support array of type', function () {
            expect(grypher.parse('--> comments:Comment[]')).to.be.deep.equal([
                {
                    rule: "flatten",
                    attribute: {
                        name: "comments",
                        type: {
                            type: "class",
                            name: "Comment",
                            isArrayOf: true,
                            arrayDepth: 1
                        }
                    }
                }
            ]);
        });
    });

    describe('classes', function () {
        it('should support simple class declaration', function () {
            expect(grypher.parse('def Tweet')).to.be.deep.equal([
                {
                    type: "class",
                    rule: "definition",
                    name: "Tweet"
                }
            ]);
        });

        it('should support class declaration with plain index', function () {
            expect(grypher.parse('def HashTag(text)')).to.be.deep.equal([
                {
                    type: "class",
                    name: "HashTag",
                    rules: [
                        {
                            rule: "index",
                            index: [
                                { name: "text" }
                            ],
                            type: "unique"
                        }
                    ],
                    rule: "definition"}
            ]);
        });

        it('should support class declaration with compound index', function () {
            expect(grypher.parse('def Person(firstname, lastname)')).to.be.deep.equal([
                {
                    type: "class",
                    name: "Person",
                    rules: [
                        {
                            rule: "index",
                            index: [
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
            expect(grypher.parse('def Citizen(credentials.passport.number)')).to.be.deep.equal([
                {
                    type: "class",
                    name: "Citizen",
                    rules: [
                        {
                            rule: "index",
                            index: [
                                { name: "credentials.passport.number" }
                            ],
                            type: "unique"
                        }
                    ],
                    rule: "definition"}
            ]);
        });

        it('should support array destructing for index at class definition', function () {
            expect(grypher.parse('def Location(coordinates[longitude, latitude])')).to.be.deep.equal([
                {
                    type: "class",
                    name: "Location",
                    rules: [
                        {
                            rule: "index",
                            index: [
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
            expect(grypher.parse('def User(passport.id) {' +
                '    --[CHILD_OF]--> father:Person' +
                '}')).to.be.deep.equal([
                    {
                        type: "class",
                        name: "User",
                        rules: [
                            {
                                rule: "relation",
                                out: { name: "CHILD_OF" },
                                attribute: {
                                    name: "father",
                                    type: {
                                        type: "class",
                                        name: "Person"
                                    }
                                }
                            },
                            {
                                rule: "index",
                                index: [
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
                expect(grypher.parse('def Coordinates [ longitude, latitude ]')).to.be.deep.equal([
                    {
                        type: "class",
                        rule: "enumeration",
                        name: "Coordinates",
                        elements: [
                            { name: "longitude" },
                            { name: "latitude" }
                        ]
                    }
                ]);
            });

            it('should support rules definition for enumerations', function () {
                expect(grypher.parse('def VendorCoordinates [ longitude, latitude, vendor ] {' +
                    'UNIQUE(longitude, latitude, vendor.id)' +
                    '}')).to.be.deep.equal([
                    {
                        type: "class",
                        rule: "enumeration",
                        name: "VendorCoordinates",
                        elements: [
                            { name: "longitude" },
                            { name: "latitude" },
                            { name: "vendor" }
                        ],
                        rules: [
                            {
                                rule: "index",
                                index: [
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
                expect(grypher.parse('--[POPULATED_WITH]--> comment:Comment()')).to.be.deep.equal([
                    {
                        rule: "relation",
                        out: { name: "POPULATED_WITH" },
                        attribute: {
                            name: "comment",
                            type: {
                                type: "class",
                                name: "Comment",
                                rule: "definition",
                                rules: []
                            }
                        }
                    }
                ]);
            });

            it('should support inline class definitions with indices', function () {
                expect(grypher.parse('--[POPULATED_WITH]--> comment:Comment(id)')).to.be.deep.equal([
                    {
                        rule: "relation",
                        out: { name: "POPULATED_WITH" },
                        attribute: {
                            name: "comment",
                            type: {
                                type: "class",
                                name: "Comment",
                                rule: "definition",
                                rules: [
                                    {
                                        rule: "index",
                                        index: [
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
