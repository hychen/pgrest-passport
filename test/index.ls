should = (require \chai).should!
expect = (require \chai).expect

require! pgrest

var pgrest-passport

describe 'pgrest-assport', ->
  pgrest-passport := require \..
  describe 'is valid pgrest plugin.', -> ``it``
    .. 'passes pgrest validation.', (done) ->
      pgrest.use.should.be.ok
      pgrest.use pgrest-passport
      pgrest.used.0.should.be.eq pgrest-passport
      done!
