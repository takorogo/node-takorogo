var
    parser = require('./lib/parser'),
    postprocessor = require('./lib/postprocessor');


module.exports = postprocessor(parser);
