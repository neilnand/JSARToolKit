process.chdir __dirname

# Web Server
express = require "express"
bodyParser = require "body-parser"

# Info
PORT = process.argv[2]
PUBLIC = "./"

# Setup Express Web Server
app = express()
app.use bodyParser.urlencoded {extended: false}
app.use bodyParser.json()
app.use express.static PUBLIC

# Start
app.listen PORT, ->
  console.log 'Server: http://localhost:%d in %s mode', PORT, app.settings.env