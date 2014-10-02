/**
 * Created by Mikhail Zyatin on 02.10.14.
 */


function postprocess(data) {
    "use strict";
    return data;
}


module.exports = function (parser) {
    "use strict";

    var _parse = parser.parse;
    parser.parse = function parse() {
        return postprocess(_parse.apply(parser, arguments));
    };

    return parser;
};
