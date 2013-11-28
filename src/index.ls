require! pgrest
require! passport

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
