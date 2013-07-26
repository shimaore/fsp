# Incomplete test
# Verify either with
#     nc localhost 7000
# or by connecting from a real server using the "socket" application.
port = 7000

FS = require '../lib/index'

server = FS.server (pv) ->
  util.log 'Call connected'
  pv
    .hangup()

server.listen port
