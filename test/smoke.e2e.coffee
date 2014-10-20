# Created by Mikhail Zyatin on 03.10.14.

'use strict'


takorogo = require('..')
fs = require('fs')
inspect = require('eyes').inspector()
tweetRules = fs.readFileSync(__dirname + '/fixtures/tweet.tako').toString()
schema = takorogo.parse(tweetRules)
tmpDir = "#{__dirname}/tmp"


# Create temporary directory if not exists
if !fs.existsSync(tmpDir) then fs.mkdirSync(tmpDir, 0o744)

# Write JSON Schema of tweet
fs.writeFileSync("#{tmpDir}/tweet.schema.json", JSON.stringify(schema, null, "    "))
inspect(schema)
