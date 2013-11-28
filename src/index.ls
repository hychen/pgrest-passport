require! pgrest
require! passport
require! express

default_cb_logout = (req, res) ->
  console.log "user logout"
  req.logout!
  res.redirect opts.auth.logout_redirect

default_cb_after_auth = (token, tokenSecret, profile, done) ->
  user = do
    provider_name: profile.provider
    provider_id: profile.id
    username: profile.username
    name: profile.name
    emails: profile.emails
    photos: profile.photos
  console.log "user #{user.username} authzed by #{user.provider_name}.#{user.provider_id}"
  #@FIXME: need to merge multiple authoziation profiles
  param = [collection: \users, q:{provider_id:user.provider_id, provider_name:user.provider_name}]
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

export function posthook-pgrest-create-plx (opts, plx)
    <- plx.query """
      CREATE TABLE IF NOT EXISTS users (
        _id SERIAL UNIQUE,
        provider_name TEXT NOT NULL,
        provider_id TEXT NOT NULL,
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
  app.get "/loggedin", middleware, (req, res) ->
            if req.pgparam.auth? then res.send true else res.send false
  app.get "/logout", middleware, default_cb_logout

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
