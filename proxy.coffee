proxy = require('express-http-proxy')
cookie = require('cookie')
cors = require('cors')
dateFormat = require('dateformat')
app = require('express')()
port = 8765
config = require('./config.json')

addParameters = (bodyContent, application, method) ->
  result = "application[apikey]=#{application.apikey}&application[uid]=#{application.uid}"

  console.log "bodyContent"
  console.log bodyContent.toString('utf8')
  if bodyContent
    content = bodyContent.toString('utf8')
    result = encodeURI("#{content}&#{result}")



  return result


app.use((req, res, next) ->
  now = Date.now()
  console.log dateFormat(now, "dddd, mmmm dS, yyyy, h:MM:ss TT")
  next()
)

# preflight options
corsOptions = exposedHeaders:  'x-token, x-token-exp'
app.options('/*', cors(corsOptions))

app.use '/', proxy(config.host,
  forwardPath: (req, res) ->
    # this option is only for
    # logging purposes
    path = require('url').parse(req.url).path
    console.log "#{req.method}: #{path}"

    return path


  intercept: (data, req, res, callback) ->
    res.setHeader("access-control-expose-headers", "x-token, X-CSRF-Token, x-token-exp")
    # callback = function(err, json)
    csrf      = res.getHeader('x-csrf-token')
    setCookie = res.getHeader('set-cookie')

    if setCookie
      cookieValues = cookie.parse(setCookie.toString())
      token        = cookieValues['_session_id']
      token_expire = cookieValues['expires']
      res.setHeader("x-token", token)
      res.setHeader("x-token-exp", token_expire)
      res.removeHeader("set-cookie");

    callback null, data

    return

  decorateRequest: (reqOpt ) ->
    if reqOpt.headers['x-token']
      cookieHeader = '_session_id=' + reqOpt.headers['x-token']
      reqOpt.headers['Cookie'] = cookieHeader

    app = config.application
    params = "application[apikey]=#{app.apikey}&application[uid]=#{app.uid}"

    if reqOpt.method is 'GET'
      path = reqOpt.path

      if path.match(/\?/)
        path = "#{path}&"
      else
        path = "#{path}?"

      reqOpt.path = encodeURI "#{path}#{params}"

    else # post,put etc
      content = reqOpt.bodyContent.toString('utf8')
      reqOpt.bodyContent = "#{content}&#{params}"

    # hostname: (typeof host == 'function') ? host(req) : host.toString(),
    # port: port,
    # headers: hds,
    # method: req.method,
    # path: path,
    # bodyContent: bodyContent

    logCurl = true

    if logCurl
      head = new String

      for key, value of reqOpt.headers
        head = head + "#{key}: #{value},"

      head = head.substring(0, head.length - 1) if head.length > 0

      console.log "curl https://#{reqOpt.hostname}#{reqOpt.path} -X #{reqOpt.method} --data '#{reqOpt.bodyContent}' -H \"#{head}\""

    return reqOpt
)

port = config.proxy.port

app.listen(port, config.proxy.host, ->
  console.log "Started listening #{port}"
)
