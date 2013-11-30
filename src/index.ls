require! pgrest
require! passport
require! express

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

default_cb_after_auth = (plx, token, tokenSecret, profile, done) ->
  user = do
    authorization_provider: profile.provider
    authorization_id: profile.id
    username: profile.username
    name: profile.name
    emails: profile.emails
    photos: profile.photos
  console.log "user #{user.username} authzed by #{user.authorization_provider}.#{user.authorization_id}"
  #@FIXME: need to merge multiple authoziation profiles
  param = [collection: \users, q:{authorization_provider:user.authorization_provider, authorization_id:user.authorization_id}]
  [pgrest_select:res] <- plx.query "select pgrest_select($1)", param
  if res.paging.count == 0
    [pgrest_insert:res] <- plx.query "select pgrest_insert($1)", [collection: \users, $: [user]]
    [pgrest_select:res] <- plx.query "select pgrest_select($1)", param
  user.auth_id = res.entries[0]['_id']
  console.log user
  done null, user

pgparam-passport = (req, res, next) ->
  if req.isAuthenticated!
    console.log "#{req.path} user is authzed. init db sesion"
    req.pgparam.auth = req.user
  else
    console.log "#{req.path} user is not authzed. reset db session"
    req.pgparam = {}
  next!

export function boot (opts)
  passport.serializeUser (user, done) -> done null, user
  passport.deserializeUser (id, done) -> done null, id

export function posthook-pgrest-create-plx (opts, plx)
    <- plx.query """
      CREATE TABLE IF NOT EXISTS users (
        _id SERIAL UNIQUE,
        authorization_provider TEXT NOT NULL,
        authorization_id TEXT NOT NULL,
        username TEXT,
        name JSON,
        display_name TEXT,
        emails JSON,
        photos JSON,
        tokens JSON
    );
    """

export function posthook-pgrest-create-app (opts, app)
  app.use express.cookieParser!
  app.use express.bodyParser!
  app.use express.methodOverride!
  app.use express.session secret: 'test'
  app.use passport.initialize!
  app.use passport.session!

export function prehook-pgrest-mount-default (opts, plx, app, middleware)
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
            successRedirect: opts.auth.success_redirect or '/'
            failureRedirect: "/auth/#{provider_name}"
    app.get "/auth/#{provider_name}/callback", _auth
