/**
 * Created by Mikhail Zyatin on 02.10.14.
 */

var grypher = require('..'),
    fs = require('fs'),
    tweetRules = fs.readFileSync(__dirname + '/fixtures/tweet.gry').toString();


grypher.parse(tweetRules);