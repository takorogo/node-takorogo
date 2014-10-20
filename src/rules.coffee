# Created by Mikhail Zyatin on 17.10.14.

'use strict'


class FlatList
    constructor: (item) ->
        @items = []
        if item then @add(item)

    add: (item) ->
        # Add item for exact type
        if item.constructor.name is @constructor.name
            item = item.items
        @items.concat(item)


class Array
    constructor: (type, length) ->
        @dimensions = [length]

        if type instanceof Array
            @itmes = type.items
            @dimensions = @dimensions.concat(type.dimensions)
        else
            @items = type


class Type
    constructor: (@node) ->


class Attribute
    constructor: (@definition) ->


class Property
    constructor: (@definition) ->


class Renaming
    constructor: (@source, @target) ->


class Destructure
    constructor: (@node, @destructuredTo) ->


class Tuple extends FlatList
    constructor: (args...) ->
        super args...


class Key extends FlatList
    constructor: (args...) ->
        super args...


class Index
    constructor: (@key) ->


class Relation
    constructor: (@body, @target) ->


class Link
    constructor: (@key, @body, @target) ->


class RelationDefinition
    constructor: (@name, @attributes) ->


class RelationOptions
    constructor: (left, right) ->
        if right?
            @['in'] = left
            @out = right
        else
            @any = left


class RelationBody
    constructor: (@type, options) ->
        # Prepare for unnamed relations
        unless options?
            options = any: true
            @isUnnamed = true

        # Determine and configure relation directions
        switch type
            when 'in' then @['in'] = options.in || options.any
            when 'out' then @out = options.out || options.any
            when 'bilateral'
                if options.any? then @bilateral = options.any
                else options
            else throw new Error("Unsupported relation body type #{type}.")


class ClassDefinitionRule
    constructor: (@statement) ->


class Class
    constructor: (@name, @rules) ->


class Embedded
    constructor: (@attribute, @rules) ->


class Meta
    constructor: (@name, @value) ->


class Schema
    constructor: (@rules) ->


module.exports =
    Schema: Schema
    Meta: Meta
    Class: Class
    Embedded: Embedded
    ClassDefinitionRule: ClassDefinitionRule
    Type: Type
    Array: Array
    Property: Property
    Attribute: Attribute
    Renaming: Renaming
    Destructure: Destructure
    Key: Key
    Tuple: Tuple
    Index: Index
    Relation: Relation
    Link: Link
    RelationBody: RelationBody
    RelationOptions: RelationOptions
    RelationDefinition: RelationDefinition