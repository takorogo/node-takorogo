# Created by Mikhail Zyatin on 03.10.14.

'use strict'


#
# Pushes item to `container` array of object `ctx` creating it if necessary.
#
# @param [Object] ctx
# @param [String] container
# @param [*] item
#
module.exports.pushAsArrayItem = (ctx, container, item) ->
    ctx[container] = ctx[container] || []
    ctx[container].push(item)

#
# Assigns value to `container` hash inside `ctx` object creating it if necessary.
#
# @param [Object] ctx
# @param [String] container
# @param [String] key
# @param [*] value
#
module.exports.addAsObjectMember = (ctx, container, key, value) ->
    ctx[container] = ctx[container] || {}
    ctx[container][key] = value
