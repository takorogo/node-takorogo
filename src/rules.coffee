# Created by Mikhail Zyatin on 17.10.14.

'use strict'


class FlatList
    constructor: (item) ->
        @items = []
        if item then @add(item)

    add: (item) ->
        # Add item for exact type flattering it's container
        if item.constructor.name is @constructor.name
            @items = @items.concat(item.items)
        # Or simply push it into array
        else
            @items.push(item)
        # Return items
        @items


class Node
    constructor: (@node) ->


class Path extends Node
    constructor: (node, @prefix) ->
        super(node)


class Property extends Node
    constructor: (node, @type) ->
        super(node)


class Type extends Path
    constructor: (@path) ->


class AnyType extends Type
    constructor: () ->


class TypeVariations extends Type
    constructor: (args...) ->
        FlatList.apply(@, args)

    add: (args...) ->
        FlatList.prototype.add.apply(@, args)


class Array extends Type
    constructor: (type, length) ->
        @dimensions = [length]

        if type instanceof Array
            @itmes = type.items
            @dimensions = @dimensions.concat(type.dimensions)
        else
            @items = type


class Attribute extends Property
    constructor: (@property) ->


class Renaming extends Attribute
    constructor: (@source, @target) ->


class Destructure extends Attribute
    constructor: (@node, @destructuredTo) ->


class Key extends FlatList
    constructor: (args...) ->
        super args...


class Method
    constructor: (@name, @parameters, @returns) ->


class Tuple extends Key
    constructor: (args...) ->
        super args...


class Index
    constructor: (@key) ->


class Relation
    constructor: (@body, @target) ->


class LinkBody
    constructor: (@body, @target) ->


class Link extends Relation
    constructor: (@key, body) ->
        super(body.body, body.target)


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


class Member
    constructor: (@definition) ->


class Class
    constructor: (classType, @rules) ->
        classType.configure(@)


class TypeHierarchyExpression
    constructor: (@name, @ancestors, @interfaces) ->

    configure: (subject) ->
        for prop in Object.keys(@) when @[prop]?
            subject[prop] = @[prop]


class Alias extends Class
    constructor: (@name, @type) ->


class Embedded
    constructor: (@attribute, @rules) ->


class Meta
    constructor: (@tag, @options) ->


class Schema
    constructor: (@rules) ->


module.exports =
    Schema: Schema
    Meta: Meta
    Class: Class
    TypeHierarchyExpression: TypeHierarchyExpression
    Alias: Alias
    Embedded: Embedded
    Member: Member
    Node: Node
    Path: Path
    Type: Type
    AnyType: AnyType
    TypeVariations: TypeVariations
    Array: Array
    Property: Property
    Attribute: Attribute
    Renaming: Renaming
    Destructure: Destructure
    Key: Key
    Method: Method
    Tuple: Tuple
    Index: Index
    Relation: Relation
    LinkBody: LinkBody
    Link: Link
    RelationBody: RelationBody
    RelationOptions: RelationOptions
    RelationDefinition: RelationDefinition