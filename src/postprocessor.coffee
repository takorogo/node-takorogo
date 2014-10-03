# Created by Mikhail Zyatin on 03.10.14.

'use strict'


utils = require './utils'


#
# @class Postprocessor
#
class Postprocessor
    #
    # @param [Object] parser
    #
    constructor: (@parser) ->

    #
    # Executes jison parser and converts it's result to JSON Schema
    #
    # @param [String] data
    # @return [Object] JSON Schema
    #
    parse: (data) ->
        @postprocess(@parser.parse(data))

    #
    # Processes whole raw output from jison parser to JSON Schema
    #
    # @param [*] data raw output from jison parser
    # @return [Object] JSON Schema
    #
    postprocess: (data) ->
        data.map (item) =>
            if item.type?
                switch item.type
                    when 'class' then @processClass(item)
                    else item
            item

    #
    # Converts class into JSON Schema object definition.
    #
    # @param [Object] item raw definition of class
    # @return [Object] JSON Schema definition
    #
    processClass: (item) =>
        if item.rules? and item.rules.length > 0
            @processRules(item)
        item

    #
    # Converts rules for item into JSON Schema object definition.
    #
    # @param [Object] item raw definition of rules owner
    # @return [Object] JSON Schema definition
    #
    processRules: (item) =>
        item.rules = item.rules.filter (rule) =>
            switch rule.rule
                when 'index'
                    utils.pushAsArrayItem(item, 'indexes', @processIndex(rule))
                    false
                when 'attribute'
                    utils.addAsObjectMember(item, 'properties', rule.attribute.name, @processProperty(rule.attribute))
                    false
                when 'relation'
                    utils.addAsObjectMember(item, 'relations', rule.attribute.name, @processRelation(rule))
                    false
                when 'link'
                    utils.addAsObjectMember(item, 'links', rule.attribute.name, @processLink(rule))
                    false
                else
                    true

    #
    # Converts index definition to JSON Schema entry.
    #
    # @param [Object] index raw definition of index
    # @return [Object] JSON Schema definition
    #
    processIndex: (index) -> index

    #
    # Converts property definition to JSON Schema entry.
    #
    # @param [Object] property raw definition of property
    # @return [Object] JSON Schema definition
    #
    processProperty: (property) -> property

    #
    # Converts relation definition to JSON Schema entry.
    #
    # @param [Object] relation raw definition of relation
    # @return [Object] JSON Schema definition
    #
    processRelation: (relation) -> relation

    #
    # Converts link definition to JSON Schema entry.
    #
    # @param [Object] link raw definition of link
    # @return [Object] JSON Schema definition
    #
    processLink: (link) -> link


module.exports = Postprocessor
