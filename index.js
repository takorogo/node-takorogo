var
    parser = require('./lib/parser'),
    Postprocessor = require('./lib/postprocessor');


module.exports = new Postprocessor(parser);
