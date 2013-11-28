should = (require \chai).should!
expect = (require \chai).expect
{mk-pgrest-fortest} = require \./testlib

require! pgrest
var pgrest-passport, plx

describe 'pgrest-assport', ->
  describe 'posthook-pgrest-create-plx', -> ``it``
    beforeEach (done) ->
      pgrest-passport := require \..
      _plx <- mk-pgrest-fortest!
      plx := _plx
      done!
    afterEach (done) ->
      <- plx.query "DROP TABLE users;"
      done!
    .. 'should create a users table.', (done) ->
      pgrest.try-invoke! [pgrest-passport], \posthook-pgrest-create-plx, null, plx
      res <- plx.query """
      SELECT count(*)
      FROM information_schema.tables
      WHERE table_name = 'users'
      """
      res.0.count.should.eq \1
      done!
  describe 'posthook-pgrest-create-app', -> ``it``
    .. 'should configure express to use passportjs.', (done) ->
      used = []
      app = do
        use: -> used.push it
      pgrest.try-invoke! [pgrest-passport], \posthook-pgrest-create-app, null, app
      used.length.should.eq 6
      done!
