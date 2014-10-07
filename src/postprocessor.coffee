# Created by Mikhail Zyatin on 03.10.14.

'use strict'


_ = require 'lodash'
utils = require './utils'


#
# @class Postprocessor
#
# @todo Put references into manipulated object
#
class Postprocessor
    @supportedRules = ['definition', 'enumeration', 'index', 'attribute', 'relation', 'link', 'meta']

    @directMetadata = ['title', 'description']

    #
    # Returns absolute reference path for class
    #
    # @param [String] className name of the class
    # @param [Object] ctx context for class
    # @return [String] context path for class
    #
    @absoluteReferencePathForClass: (className, ctx) ->
        "#{ctx.__path}/definitions/#{className}"

    #
    # Cleans up references
    #
    cleanRefs: () ->
        @typeRefs = []
        @typeDefs = {}
        @mainClass = false

    #
    # Processes whole raw output from jison parser to JSON Schema
    #
    # @param [*] data raw output from jison parser
    # @return [Object] JSON Schema
    #
    postprocess: (data) ->
        @cleanRefs()
        schema = @processRules(data, __path: '#')
        @resolveTypeReferences(schema)
        @cleanUpSchema(schema)
        schema

    #
    # Removes technical information from schema
    #
    # @param [Object] schema
    # @return [Object] schema
    #
    cleanUpSchema: (schema) ->
        # Remove context path from schema
        delete schema.__path

        # Remove context paths from type definitions
        _.forEach @typeDefs, (def) ->
            delete def.__path

        # Set main class if existed
        if @mainClass then _.defaults schema, @mainClass

        # Return schema
        schema

    #
    # Converts meta statement into JSON Schema object definition.
    #
    # @param [Object] meta raw definition of enumeration
    # @param [Object] ctx context for meta
    # @return [Object] JSON Schema definition
    #
    processMeta: (meta, ctx={}) ->
        # Save metadata directly into context
        if meta.key in @constructor.directMetadata
            ctx[meta.key] = meta.value
        # Or store into `metadata` container
        else
            utils.addAsObjectMember(ctx, 'metadata', meta.key, meta.value)
        # Return context
        ctx

    #
    # Converts enumeration into JSON Schema object definition.
    #
    # @param [Object] enumeration raw definition of enumeration
    # @param [Object] ctx context for enumeration
    # @return [Object] JSON Schema definition
    #
    processEnumeration: (enumeration, ctx={}) =>
        # Save elements
        elements = enumeration.elements.map (element) -> element.name
        destructuredClassTitle = "__#{enumeration.title}__"

        # Destructured class definition
        klass = _.merge _.omit(enumeration, ['elements']),
            title: destructuredClassTitle
            additionalProperties: false
            required: elements

        # New enumeration definition
        enumeration =
            __path: @constructor.absoluteReferencePathForClass(enumeration.title, ctx)
            type: 'array'
            title: enumeration.title
            elements: elements
            minItems: elements.length
            maxItems: elements.length

        enumeration.destructuredTo =
            $ref: @constructor.absoluteReferencePathForClass(destructuredClassTitle, enumeration)

        # Add class to definition to local definitions
        @processDefinition(klass, enumeration)

        # Add enumeration to context
        utils.addAsObjectMember(ctx, 'definitions', enumeration.title, enumeration)

        # Register enumeration definition for later referencing
        @registerDefinition enumeration

        # Return context
        ctx

    #
    # Converts class rule into JSON Schema object definition.
    #
    # @param [Object] klass raw definition of class
    # @param [Object] ctx context for class
    # @return [Object] context with class JSON Schema definition
    #
    processDefinition: (klass, ctx={}) =>
        # Set path for class
        klass.__path = @constructor.absoluteReferencePathForClass(klass.title, ctx)

        # Process class rules
        if klass.rules? and klass.rules.length > 0
            @processRules(klass.rules, klass)

        # Register as main definition if required
        if klass.isMainDefinition then @mainClass =
            title: klass.title
            type: klass.type
            $ref: klass.__path

        # Strip verbose fields
        klass = _.omit(klass, ['rules', 'rule', 'isMainDefinition'])

        # Add class to context
        utils.addAsObjectMember(ctx, 'definitions', klass.title, klass)

        # Register type definition for later referencing
        @registerDefinition klass

        # Return context
        ctx

    #
    # Processes passed rule with related method
    #
    # @param [Object] rule raw definition of rule
    # @param [Object] ctx context for rule
    # @return [Object] JSON Schema definition of rule
    #
    processRule: (rule, ctx) ->
        if (rule.rule in @constructor.supportedRules)
            method = "process#{utils.capitalizeFirst(rule.rule)}"
            @[method](rule, ctx)
        else throw new Error("Unrecognized Grypher rule #{rule.rule}.")

    #
    # Converts rules for context into JSON Schema object definition.
    #
    # @param [Array<Object>] rules raw definition of rules owner
    # @param [Object] ctx context for rules
    # @return [Object] JSON Schema definition
    #
    processRules: (rules, ctx={}) =>
        rules.forEach (rule) =>
            @processRule(rule, ctx)
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

        # Ensure that index keys are mentioned in schema
        index.key.forEach (key) =>
            # Add keys as properties if not already added
            if not ctx.properties?[key]?
                @addPropertyToContext(key, {}, ctx)
            # Mark key properties as required
            utils.pushAsArrayUniqueItem(ctx, 'required', key)

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
        # Process alias if required
        if property.attribute.aliasOf?
            utils.addAsObjectMember(ctx, 'aliases', property.attribute.name, property.attribute.aliasOf.name)

        # Create property schema
        name = property.attribute.name
        property = _.omit property.attribute, ['aliasOf', 'name']

        # Process property type
        @processPropertyType(property, ctx)

        # Add property to context
        @addPropertyToContext(name, property, ctx)

        # Return context
        ctx

    #
    # Adds property to specified context
    #
    #
    # @param [String] name property name
    # @param [Object] property definition of property
    # @param [Object] ctx context for property
    # @return [Object] property context JSON Schema definition
    #
    addPropertyToContext: (name, property, ctx) ->
        # Expand property if required
        property = @expandPropertyPath(name, property)

        # Leave only first node of the name
        name = name.split('.')[0]

        # Add property to context
        utils.addAsObjectMember(ctx, 'properties', name, property)

        # Return context
        ctx

    #
    # Expands properties specified with paths to JSON Schema embedded objects
    #
    # @param [String] name property name
    # @param [Object] property definition of property
    # @return [Object] property context JSON Schema definition
    #
    expandPropertyPath: (name, property) ->
        # Iterate over property path and expend it if required
        path = name.split('.')
        if path.length > 1
            # Create wrapper for property
            wrapper =
                type: 'object'
                properties: {}
            wrapper.properties[path[1]] = @expandPropertyPath(path.slice(1).join('.'), property)
            # Use wrapper as a new property
            property = wrapper

        # Return possibly modified property
        property

    #
    # Registers type reference
    #
    # @param [Object] property property that has a reference of type
    # @param [Object] ctx referencing context
    #
    registerTypeReference: (property, ctx) ->
        @typeRefs.push(property: property, ctx: ctx)

    #
    # Registers definition reference
    #
    # @param [Object] definition type definition schema
    #
    registerDefinition: (definition) ->
        @typeDefs[definition.__path] = definition

    #
    # Finds JSON schema reference to specified type in the context
    #
    # @param [String] name type name
    # @param [Object] ctx type context
    # @return [String|Boolean] JSON Schema reference or false
    #
    findTypeReference: (name, ctx) ->
        # Create reference for closest context path
        $ref = @constructor.absoluteReferencePathForClass(name, ctx)

        # Return reference if exists in context
        if @typeDefs[$ref]?
            $ref
        # Or try to look higher in hierarchy
        else
            # Create new path dropping last position in current one
            path = ctx.__path.split('/').slice(0, -1).join('/')
            # Try to find definition in parent context
            if path
                #todo Rethink API to avoid path wrapping/unwrapping
                @findTypeReference(name, __path: path)
            # Or return false in nothing can be found on schema
            else
                false

    #
    # Resolves type reference
    #
    # @param [Object] property property that has a type reference
    # @param [Object] unresolved container for unresolved types
    #
    resolveTypeReference: (property, unresolved) ->
        # Type reference
        ref = property.property

        # Find reference to type
        $ref = @findTypeReference(ref.type.title, property.ctx)

        # Save reference if found
        if $ref
            ref.type.$ref = $ref
        # Or assume that type is external to Schema
        else
            # Set type as it is
            ref.type.type = ref.type.title
            # Mark type as unresolved
            unresolved[ref.type.title] = true

        # Bubble up fields from type
        _.merge(property.property, _.omit(ref.type, ['title']))

    #
    # Processes type references for schema
    #
    # @param [Object] schema JSON schema
    # @return [Object] JSON schema
    #
    resolveTypeReferences: (schema) ->
        # Create container for unresolved types
        unresolved = {}

        # Iterate over type references
        @typeRefs.forEach (ref) =>
            @resolveTypeReference(ref, unresolved)

        # Save unresolved types to schema
        unresolved = Object.keys(unresolved)
        if unresolved.length > 0 then schema.unresolvedTypes = unresolved

        # Return schema
        schema

    #
    # Processes property type.
    #
    # @param [Object] property definition
    # @param [Object] ctx context for property
    # @return [Object] property context JSON Schema definition
    #
    processPropertyType: (property, ctx={}) ->
        # Process property type inline declaration
        if property.type?.rule?
            @processRule property.type, ctx
            property.type = _.pick(property.type, ['type', 'title', 'isArrayOf', 'arrayDepth'])

        # Process array properties
        if property.type?.isArrayOf
            @processArrayType(property, ctx)

        # Register reference for type
        if property.type?.type == 'object' then @registerTypeReference(property, ctx)

        # Return context
        ctx

    #
    # Converts array types to proper JSON schema.
    #
    # @param [Object] property type definition
    # @param [Object] ctx context for property
    # @return [Object] property context JSON Schema definition
    #
    processArrayType: (property, ctx) ->
        # We assuming that array is one level by default
        arrayDepth = property.type.arrayDepth || 1

        # Creating first level wrapper
        property.items = type: _.omit(property.type, ['isArrayOf', 'arrayDepth'])
        # Property now of type array
        property.type = 'array'

        # Save reference to type
        @registerTypeReference(property.items, ctx)

        # Further wrapping for multidimensional arrays
        while arrayDepth-- > 1
            property.items =
                type: 'array'
                items: property.items

        # Return context
        ctx

    #
    # Converts relation definition to JSON Schema entry.
    #
    # @param [Object] relation raw definition of relation
    # @param [Object] ctx context for relation
    # @return [Object] relation context JSON Schema definition
    #
    processRelation: (relation, ctx={}) ->
        # Process attribute
        @processAttribute(attribute: relation.attribute, ctx)

        # Create relation schema
        relation = _.merge _.omit(relation, ['rule', 'attribute']),
            #todo We need to get rid of ambiguity of `attribute` and `property` which are the same at this project.
            property: relation.attribute.name

        # Add relation to context and return context
        utils.addAsObjectMember(ctx, 'relations', relation.property, relation)

        # Return context
        ctx

    #
    # Converts link definition to JSON Schema entry.
    #
    # @param [Object] link raw definition of link
    # @param [Object] ctx context for link
    # @return [Object] link context JSON Schema definition
    #
    processLink: (link, ctx={}) ->
        # Process attribute
        @processAttribute(attribute: link.attribute, ctx)

        link = _.merge _.omit(link, ['rule', 'attribute']),
            property: link.attribute.name

        # Add link to context and return context
        utils.addAsObjectMember(ctx, 'links', link.property, link)

        # Return context
        ctx


module.exports = Postprocessor
