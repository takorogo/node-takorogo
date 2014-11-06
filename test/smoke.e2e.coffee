# Created by Mikhail Zyatin on 03.10.14.

'use strict'


takorogo = require('..')
fs = require('fs')
inspect = require('eyes').inspector()
_ = require('lodash')

# Create temporary directory if not exists
tmpDir = "#{__dirname}/tmp"
if !fs.existsSync(tmpDir) then fs.mkdirSync(tmpDir, 0o744)

rules =
    tweet: 'tweet'
    takorogo: 'takorogo'

_.map rules, (rule) ->
    # Load
    script = fs.readFileSync("#{__dirname}/fixtures/#{rule}.tako").toString()
    # Parse
    schema = takorogo.parse(script)
    # Write JSON Schema of tweet
    fs.writeFileSync("#{tmpDir}/#{rule}.schema.json", JSON.stringify(schema, null, "    "))
    # Inspect
    inspect(schema)
