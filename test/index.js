var expect = require('chai').expect,
    nodeGrypher = require('..');

describe('node-grypher', function () {
    it('should export parser', function () {
        "use strict";
        expect(nodeGrypher).to.be.an('object');
        expect(nodeGrypher).to.respondTo('parse');
    });
});
