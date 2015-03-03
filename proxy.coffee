proxy = require('express-http-proxy')
cookie = require('cookie')
app = require('express')()
cors = require('cors')
port = 8765
config = require('./config.json')

addParameters = (bodyContent, application) ->
  result = "application[apikey]=#{application.apikey}&application[uid]=#{application.uid}"

  if bodyContent
    content = bodyContent.toString('utf8')
    result = "#{content}&#{result}"

  console.log result
  return result


app.use '/', proxy(config.host,
  forwardPath: (req, res) ->
    console.log 'forwardPath'
    require('url').parse(req.url).path

  intercept: (data, req, res, callback) ->
    console.log 'intercept'
    # callback = function(err, json)
    csrf = res.getHeader('x-csrf-token')
    setCookie = res.getHeader('set-cookie')
    cookieValues = undefined
    token = undefined
    token_expire = undefined
    if setCookie
      cookieValues = cookie.parse(setCookie.toString())
      token = cookieValues['_session_id']
      token_expire = cookieValues['expires']
    if token
      console.log 'Set-Token!!'
      res.append 'token', token
    if token_expire
      res.append 'token-exp', token_expire
    # add expose headers
    res.setHeader 'Access-Control-Expose-Headers', 'X-CSRF-Token, token, token-exp'
    callback null, data
    return

  decorateRequest: (req) ->
    console.log 'decorateRequest'
    if req.headers['token']
      cookieHeader = '_session_id=' + req.headers['token']
      req.headers['Cookie'] = cookieHeader
      delete req.headers['token']
    console.log req.headers
    req.bodyContent = addParameters(req.bodyContent, config.application)
    return req
)
app.listen port
console.log 'Started listening ' + port