var
    parser = require('./lib/parser').parser,
    Scope = require('./lib/scope');


parser.yy = { scope: new Scope() };

module.exports.parse = function (input) {
    "use strict";
    return parser.parse(input);
};