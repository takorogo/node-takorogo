# Created by Mikhail Zyatin on 07.10.14.

'use strict'


Postprocessor = require './postprocessor'


#
# @class Takorogo
#
class Takorogo
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
        postprocessor = new Postprocessor
        postprocessor.postprocess(@parser.parse(data))


module.exports = Takorogo
    

