# Created by Mikhail Zyatin on 03.10.14.

'use strict'


grypher = require('..')
fs = require('fs')
tweetRules = fs.readFileSync(__dirname + '/fixtures/tweet.gry').toString()
schema = grypher.parse(tweetRules)
tmpDir = "#{__dirname}/tmp"


# Create temporary directory if not exists
if !fs.existsSync(tmpDir) then fs.mkdirSync(tmpDir, 0o744)

# Write JSON Schema of tweet
fs.writeFileSync("#{tmpDir}/tweet.schema.json", JSON.stringify(schema, null, "    "))