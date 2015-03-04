proxy = require('express-http-proxy')
cookie = require('cookie')
cors = require('cors')
dateFormat = require('dateformat')
app = require('express')()
port = 8765
config = require('./config.json')

addParameters = (bodyContent, application) ->
  result = "application[apikey]=#{application.apikey}&application[uid]=#{application.uid}"

  if bodyContent
    content = bodyContent.toString('utf8')
    result = "#{content}&#{result}"

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
  intercept: (data, req, res, callback) ->
    console.log '---- intercept ---'

    console.log res.constructor.name

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
      console.log "Add cookie"
      cookieHeader = '_session_id=' + reqOpt.headers['x-token']
      reqOpt.headers['Cookie'] = cookieHeader

    reqOpt.bodyContent = addParameters(reqOpt.bodyContent, config.application)

    return reqOpt
)

app.listen port

console.log 'Started listening ' + port