proxy = require('express-http-proxy')
cookie = require('cookie')
cors = require('cors')
dateFormat = require('dateformat')
app = require('express')()
port = 8765
config = require('./config.json')
winston = require('winston')

# Create logfile
logger = new (winston.Logger)(
  transports: [
    new (winston.transports.Console)(level: 'info')
    new (winston.transports.File)(
      filename : config.logfile
      level    : 'debug'
    )
  ]
)

addParameters = (bodyContent, application, method) ->
  result = "application[apikey]=#{application.apikey}&application[uid]=#{application.uid}"

  if bodyContent
    content = bodyContent.toString('utf8')
    result = encodeURI("#{content}&#{result}")

  return result

# preflight options
corsOptions = exposedHeaders:  'x-token, x-token-exp'

app.options('/*', (req, res) ->
  logger.info("#{req.method}")
  cors(corsOptions)(req,res)
)
# end preflight

app.use '/', proxy(config.host,
  forwardPath: (req, res) ->
    # this option is only for
    # logging purposes
    path = require('url').parse(req.url).path

    logger.info("#{req.method}: #{path}")

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
      curlStr = "curl https://#{reqOpt.hostname}#{reqOpt.path} -X #{reqOpt.method} --data '#{reqOpt.bodyContent}' -H \"#{head}\""
      logger.log('debug',curlStr);


    return reqOpt
)
# error handling
app.use((err, req, res, next) ->
  console.error(err.stack);
  res.status(500).send('Something broke!');
)

process.on('uncaughtException', (err) ->
  logger.error(err)
)

port = config.proxy.port

app.listen(port, config.proxy.host, ->
  console.log "Started listening #{port}"
)
