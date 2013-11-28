``#!/usr/bin/env node``
require! pgrest
pgrest-passport = require \../
pgrest.use pgrest-passport
app <- pgrest.cli! {}, {}, [], null, null
