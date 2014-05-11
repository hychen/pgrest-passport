require! pgrest
require! passport
require! express

DEFAULT_SETTINGS = do
  jwt_secret: 'wtfwtfbacwtf'
  enable: false
  success_redirect: '/me'
  logout_redirect: '/'
  plugins: []
  providers_settings:
    facebook:
      clientID: null
      clientSecret: null
    twitter:
      consumerKey: null
      consumerSecret: null
    google:
      consumerKey: null
      consumerSecret: null

pgparam-passport = (req, res, next) ->
  if req.isAuthenticated!
    console.log "#{req.path} user is authzed. init db sesion"
    req.pgparam.auth = req.user
  else
    console.log "#{req.path} user is not authzed. reset db session"
    req.pgparam = {}
  next!

export function process-opts (opts)
  opts.auth = opts.argv.auth or opts.cfg.auth or DEFAULT_SETTINGS

export function isactive (opts)
  opts.auth.enable == true

export function initialize (opts)
  passport.serializeUser (user, done) -> done null, user
  passport.deserializeUser (id, done) -> done null, id

export function posthook-cli-create-plx (opts, plx)
  <- plx.query """
    CREATE EXTENSION if not exists "uuid-ossp";
    CREATE TABLE IF NOT EXISTS users (
      _id uuid UNIQUE default(uuid_generate_v4()),
      auth_provider text[],
      username text UNIQUE,
      profile JSON,
      display_name TEXT,
      tokens JSON
    );
  """
#  plx.query """
#   create index users_auth_provider on users using gin (auth_provider);
# """, ->, -> console.log \meh
  <- pgrest.bootstrap plx, "pgrest-passport" require.resolve \../package.json

export function posthook-cli-create-app (opts, app)
  app.use express.bodyParser!
  app.use express.methodOverride!
  app.use passport.initialize!

export function prehook-cli-mount-default (opts, plx, app, middleware)
  default_cb_profile = (req, res) ->
    if req.isAuthenticated!
      res.send req.user
    else
      res.send 403
  default_cb_loggedin = (req, res) ->
    if req.pgparam.auth?
      res.send true
    else
      res.send false
  default_cb_logout = (req, res) ->
    console.log "user logout"
    req.logout!
    res.redirect opts.auth.logout_redirect
  default_cb_after_auth = (token, tokenSecret, profile, done) ->
    console.log \aftercb token, tokenSecret
    user = do
      auth_provider: ["#{profile.provider}:#{profile.id}"]
      profile: profile
    console.log "user #{user.username} authn as #{user.auth_provider.0}"
    param = [collection: \users, q:{auth_provider: { '$contains': user.auth_provider.0 }}]
    [pgrest_select:res] <- plx.query "select pgrest_select($1)", param
    if res.paging.count == 0
      [pgrest_insert:res] <- plx.query "select pgrest_insert($1)", [collection: \users, $: [user]]
    [pgrest_select:res] <- plx.query "select pgrest_select($1)", param
    user.user_id = res.entries[0]['_id']
    console.log user
    done null, user
  express-jwt = require 'express-jwt'
  middleware.push express-jwt secret: opts.auth.jwt_secret
  middleware.push pgparam-passport

  app.get "/loggedin", middleware, default_cb_loggedin
  app.get "/logout", middleware, default_cb_logout
  app.get "/me", middleware, default_cb_profile

  for provider_name in opts.auth.plugins
    provider_cfg = opts.auth.providers_settings[provider_name]
    throw "#{provider_name} settings is required" unless provider_cfg
    console.log "enable auth #{provider_name}"
    # passport settings
    provider_cfg['callbackURL'] = "http://#{opts.host}:#{opts.port}/auth/#{provider_name}/callback"
    console.log provider_cfg
    module_name = switch provider_name
                  case \google then "passport-google-oauth"
                  default "passport-#{provider_name}"
    _Strategy = require(module_name).Strategy
    passport.use new _Strategy provider_cfg, default_cb_after_auth
    # register auth endpoint
    app.get "/auth/#{provider_name}", (passport.authenticate "#{provider_name}", provider_cfg.scope)
    _auth = passport.authenticate "#{provider_name}", do
      failureRedirect: "/auth/#{provider_name}"
    jwt = require 'jsonwebtoken'

    app.get "/auth/#{provider_name}/callback", _auth, ({user}:req, res) ->
      console.log \authcb, req.headers.accept
      token = jwt.sign {user.user_id}, opts.auth.jwt_secret, expiresInMinutes: 60*5
      res.redirect '/me#' + token

export function pgrest_getauth
    throw "logged out" unless plv8x.auth
    plv8x.auth.auth_id

pgrest_getauth.$plv8x = '():int'
pgrest_getauth.$bootstrap = true
