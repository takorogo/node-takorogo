# Created by Mikhail Zyatin on 03.10.14.

'use strict'


_ = require 'lodash'
utils = require './utils'


#
# @class Postprocessor
#
class Postprocessor
    @supportedRules = ['definition', 'enumeration', 'index', 'attribute', 'relation', 'link']

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
    # @param [Object] ctx context for enumeration
    # @return [Object] JSON Schema definition
    #
    processEnumeration: (enumeration, ctx={}) =>
        @processDefinition(enumeration, ctx)

    #
    # Converts class rule into JSON Schema object definition.
    #
    # @param [Object] klass raw definition of class
    # @param [Object] ctx context for class
    # @return [Object] context with class JSON Schema definition
    #
    processDefinition: (klass, ctx={}) =>
        # Process class rules
        if klass.rules? and klass.rules.length > 0
            @processRules(klass.rules, klass)

        # Strip verbose fields
        klass = _.omit(klass, ['rules', 'rule'])

        # Add class to context
        utils.addAsObjectMember(ctx, 'definitions', klass.title, klass)

        # Return context
        ctx

    #
    # Converts rules for context into JSON Schema object definition.
    #
    # @param [Array<Object>] rules raw definition of rules owner
    # @param [Object] ctx context for rules
    # @return [Object] JSON Schema definition
    #
    processRules: (rules, ctx={}) =>
        rules.forEach (rule) =>
            if (rule.rule in Postprocessor.supportedRules)
                method = "process#{utils.capitalizeFirst(rule.rule)}"
                @[method](rule, ctx)
            else throw new Error("Unrecognized Grypher rule #{rule.rule}.")
        ctx

    #
    # Converts index definition to JSON Schema entry.
    #
    # @param [Object] index raw definition of index
    # @param [Object] ctx context for index
    # @return [Object] context with index JSON Schema definition
    #
    processIndex: (index, ctx={}) ->
        # Strip verbose fields
        index = _.omit(index, ['rule'])

        # Process keys
        index.key = index.key.map (field) =>
            # Save keys as properties if they specified in extended format
            if field.type?
                # Note that field should be wrapped with attribute rule
                @processAttribute(attribute: field, ctx)
            # We need only attribute names here
            field.name

        # Add index to context
        utils.pushAsArrayItem(ctx, 'indexes', index)

        # Return context
        ctx

    #
    # Converts property definition to JSON Schema entry.
    #
    # @param [Object] property raw definition of property
    # @param [Object] ctx context for property
    # @return [Object] property context JSON Schema definition
    #
    processAttribute: (property, ctx={}) ->
        # Add property to context and return context
        utils.addAsObjectMember(ctx, 'properties', property.attribute.name, property.attribute)
        ctx

    #
    # Converts relation definition to JSON Schema entry.
    #
    # @param [Object] relation raw definition of relation
    # @param [Object] ctx context for relation
    # @return [Object] relation context JSON Schema definition
    #
    processRelation: (relation, ctx={}) ->
        # Add relation to context and return context
        utils.addAsObjectMember(ctx, 'relations', relation.attribute.name, relation)
        ctx

    #
    # Converts link definition to JSON Schema entry.
    #
    # @param [Object] link raw definition of link
    # @param [Object] ctx context for link
    # @return [Object] link context JSON Schema definition
    #
    processLink: (link, ctx={}) ->
        # Add link to context and return context
        utils.addAsObjectMember(ctx, 'links', link.attribute.name, link)
        ctx


module.exports = Postprocessor
