Event Socket stream parser
--------------------------

    querystring = require 'querystring'

    module.exports = class Parser

The Event Sokcet parser will parse an incoming ES stream, whether your code is acting as a client (connected to the FreeSwitch ES server) or as a server (called back by FreeSwitch when the "socket" application command is started).

      constructor: (@socket) ->
        @body_length = 0
        @buffer = ""

### Capture body

      capture_body: (data) ->

When capturing the body, `buffer` contains the current data (text), and `body_length` contains how many bytes are expected to be read in the body.

        @buffer += data

As long as the whole body hasn't been received, keep adding the new data into the buffer.

        if @buffer.length < @body_length
          return

Consume the body once it has been fully received.

        body = @buffer.substring(0,@body_length)
        @buffer = @buffer.substring(@body_length)
        @body_length = 0

process the content

        @process @headers, body
        @headers = {}

Re-parse whatever data was left after the body was fully consumed.

        @capture_headers ''

### Capture headers

      capture_headers: (data) ->

Capture headers, meaning up to the first blank line.

        @buffer += data

Wait until we reach the end of the header.

        header_end = @buffer.indexOf("\n\n")
        if header_end < 0
          return

Consume the headers

        header_text = @buffer.substring(0,header_end)
        @buffer = @buffer.substring(header_end+2)

Parse the header lines

        @headers = parse_header_text(header_text)

Figure out whether a body is expected

        if @headers["Content-Length"]
          @body_length = @headers["Content-Length"]

Parse the body (and eventually process)

          @capture_body ''

        else

Process the (header-only) content

          @process @headers
          @headers = {}

Re-parse whatever data was left after these headers were fully consumed.

          @capture_headers ''

### Dispatch incoming data into the header or body parsers.

      on_data: (data) ->
        if exports.debug
          util.log "on_data(#{data})"

Capture the body as needed

        if @body_length > 0
          return @capture_body data
        else
          return @capture_headers data

For completeness provide an `on_end()` method.
TODO: it probably should make sure the buffer is empty?

      on_end: () ->
        if exports.debug
          util.log "Parser: end of stream"
          if @buffer.length > 0
            util.log "Buffer is not empty, left over: #{@buffer}"

Headers parser
--------------

Event Socket framing contains headers and a body.
The header must be decoded first to learn the presence and length of the body.

    parse_header_text = (header_text) ->
      if exports.debug
        util.log "parse_header_text(#{header_text})"

      header_lines = header_text.split("\n")
      headers = {}
      for line in header_lines
        do (line) ->
          [name,value] = line.split /: /, 2
          headers[name] = value

Decode headers: in the case of the "connect" command, the headers are all URI-encoded.

      if headers['Reply-Text']?[0] is '%'
        for name of headers
          headers[name] = querystring.unescape(headers[name])

      return headers
