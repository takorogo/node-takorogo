# Created by Mikhail Zyatin on 03.10.14.

'use strict'


_ = require 'lodash'
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
        @processRules(data)

    #
    # Converts enumeration into JSON Schema object definition.
    #
    # @param [Object] enumeration raw definition of enumeration
    # @return [Object] JSON Schema definition
    #
    processEnumeration: (enumeration) =>
        @processClass(enumeration)

    #
    # Converts class into JSON Schema object definition.
    #
    # @param [Object] klass raw definition of class
    # @return [Object] JSON Schema definition
    #
    processClass: (klass) =>
        if klass.rules? and klass.rules.length > 0
            @processRules(klass.rules, klass)

        _.omit(klass, ['rules', 'rule'])

    #
    # Converts rules for context into JSON Schema object definition.
    #
    # @param [Array<Object>] rules raw definition of rules owner
    # @param [Object] ctx context for rules
    # @return [Object] JSON Schema definition
    #
    processRules: (rules, ctx={}) =>
        rules.forEach (rule) =>
            switch rule.rule
                when 'definition'
                    utils.addAsObjectMember(ctx, 'definitions', rule.title, @processClass(rule))
                when 'enumeration'
                    utils.addAsObjectMember(ctx, 'definitions', rule.title, @processEnumeration(rule))
                when 'index'
                    utils.pushAsArrayItem(ctx, 'indexes', @processIndex(rule))
                when 'attribute'
                    utils.addAsObjectMember(ctx, 'properties', rule.attribute.name, @processProperty(rule.attribute))
                when 'relation'
                    utils.addAsObjectMember(ctx, 'relations', rule.attribute.name, @processRelation(rule))
                when 'link'
                    utils.addAsObjectMember(ctx, 'links', rule.attribute.name, @processLink(rule))
                else
                    throw new Error("Unrecognized Grypher rule #{rule.rule}.")
        ctx

    #
    # Converts index definition to JSON Schema entry.
    #
    # @param [Object] index raw definition of index
    # @return [Object] JSON Schema definition
    #
    processIndex: (index) ->
        index.index.map (field) -> field.name

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
