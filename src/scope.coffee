# Created by Mikhail Zyatin on 15.10.14.

'use strict'


utils = require('./utils')
rules = require('./rules')


class Scope
    @supportedOperations:
        create: [
            'schema',
            'meta_extension',
            'meta',
            'class',
            'type_hierarchy_expression',
            'alias',
            'member',
            'node',
            'path',
            'embedded',
            'type',
            'any_type',
            'type_variations',
            'array',
            'property',
            'attribute',
            'renaming',
            'destructure',
            'key',
            'method',
            'batch_rename',
            'tuple',
            'index',
            'relation'
            'link',
            'link_body',
            'relation_body',
            'relation_options',
            'relation_definition',
        ]

    constructor: ->

    camelCase: (string) ->
        string.split('_').map((entry) -> utils.capitalizeFirst(entry)).join('')

    create: (type, subject...) ->
        rule = @camelCase(type)
        method = "create#{rule}"
        constructor = rules[rule]

        # Try to create entity by dedicated method or directly with constructor
        if type in @constructor.supportedOperations.create
            if @[method]?
                return @[method](subject...)
            else if constructor?
                return new constructor(subject...)

        throw new Error("Creation of elements of type #{type} is unsupported.")


    addMeta: (statement, meta)->
        statement.meta = statement.meta || []
        statement.meta.push(meta)
        statement

    createMetaExtension: (statement, tag, options) ->
        meta = if options
            tag: tag
            options: options
        else
            tag
        @addMeta(statement, meta)

    createBatchRename: (source, target) ->
        new Tuple(@zipBatch(source, target))

    zipBatch: (source, target) ->
        source.items.map (value, key) ->
            new rules.Renaming(source, target.items[key])


module.exports = Scope
    

