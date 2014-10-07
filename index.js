var
    parser = require('./lib/parser'),
    Grypher = require('./lib/grypher');


module.exports = new Grypher(parser);
