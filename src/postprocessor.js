/**
 * Created by Mikhail Zyatin on 02.10.14.
 */


(function () {
    "use strict";


    var utils = require('./utils');


    /**
     * Converts class into JSON Schema object definition.
     * @param {Object} item
     * @returns {Object}
     */
    function processClass(item) {
        if (item.rules !== 'undefined' && item.rules.length > 0) {
            item.rules = item.rules.filter(function (rule) {
                switch (rule.rule) {
                    case 'index':
                        utils.pushAsArrayItem(item, 'indexes', processIndex(rule));
                        return false;
                    case "attribute":
                        utils.addAsObjectMember(item, 'properties', rule.attribute.name,
                            processProperty(rule.attribute));
                        return false;
                    case "relation":
                        utils.addAsObjectMember(item, 'relations', rule.attribute.name,
                            processRelation(rule));
                        return false;
                    case "link":
                        utils.addAsObjectMember(item, 'links', rule.attribute.name,
                            processLink(rule));
                        return false;
                }
                return true;
            });
        }
        return item;
    }

    /**
     * Converts property definition to JSON Schema entry.
     * @param {Object} property raw definition
     * @returns {Object} JSON Schema definition
     */
    function processProperty(property) {
        return property;
    }

    /**
     * Converts index definition to JSON Schema entry.
     * @param {Object} index raw definition
     * @returns {Object} JSON Schema definition
     */
    function processIndex(index) {
        return index;
    }

    /**
     * Converts relation definition to JSON Schema entry.
     * @param {Object} relation raw definition
     * @returns {Object} JSON Schema definition
     */
    function processRelation(relation) {
        return relation;
    }

    /**
     * Converts link definition to JSON Schema entry.
     * @param {Object} relation raw definition
     * @returns {Object} JSON Schema definition
     */
    function processLink(relation) {
        return relation;
    }

    /**
     * Processes whole raw output from jison parser to JSON Schema.
     * @param {*} data raw output from jison parser
     * @returns {*} JSON Schema
     */
    function postprocess(data) {
        return data.map(function (item) {
            if (item.type !== 'undefined') {
                switch (item.type) {
                    case 'class':
                        return processClass(item);
                }
            }
            return item;
        });
    }

    /**
     * Wraps parser with postprocessor.
     * @param {Object} parser jison parser
     * @returns {Object} wrapped parser
     */
    function wrap(parser) {
        var _parse = parser.parse;
        parser.parse = function parse() {
            return postprocess(_parse.apply(parser, arguments));
        };

        return parser;
    }


    module.exports.processRelation = processRelation;
    module.exports.processLink = processLink;
    module.exports.processIndex = processIndex;
    module.exports.processProperty = processProperty;
    module.exports.processClass = processClass;
    module.exports.postprocess = postprocess;
    module.exports.wrap = wrap;
})();
