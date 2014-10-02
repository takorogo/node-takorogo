/**
 * Created by Mikhail Zyatin on 03.10.14.
 */

(function () {
    "use strict";


    /**
     * Pushes item to `container` array of object `ctx` creating it if necessary.
     * @param {Object} ctx
     * @param {String} container
     * @param {*} item
     */
    function pushAsArrayItem(ctx, container, item) {
        ctx[container] = ctx[container] || [];
        ctx[container].push(item);
    }

    /**
     * Assigns value to `container` hash inside `ctx` object creating it if necessary.
     * @param {Object} ctx
     * @param {String} container
     * @param {String} key
     * @param {*} value
     */
    function addAsObjectMember(ctx, container, key, value) {
        ctx[container] = ctx[container] || {};
        ctx[container][key] = value;
    }


    module.exports.pushAsArrayItem = pushAsArrayItem;
    module.exports.addAsObjectMember = addAsObjectMember;
})();
