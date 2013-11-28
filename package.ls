#!/usr/bin/env lsc -cj
author:
  name: ['Chen Hsin-Yi']
  email: 'ossug.hychen@gmail.com'
name: 'pgrest-passport'
description: 'pgrest plugin for passportjs'
version: '0.0.1'
main: \lib/index.js
bin:
  pgrest-passport: 'bin/cmd.js'
repository:
  type: 'git'
  url: 'git://github.com/hychen/pgrest-passport.git'
scripts:
  test: """
    mocha
  """
  prepublish: """
    lsc -cj package.ls &&
    lsc -bpc bin/cmd.ls > bin/cmd.js &&
    chmod 755 bin/cmd.js &&
    lsc -bc -o lib src
  """
engines: {node: '*'}
dependencies:
  trycatch: \1.0.x
  passport: \0.1.x
  express: \*
devDependencies:
  mocha: \*
  supertest: \0.7.x
  chai: \*
  LiveScript: \1.1.x
peerDependencies:
  pgrest: \*
optionalDependencies:
  'passport-facebook': \1.0.x
  'passport-twitter': \1.0.x
  'passport-google-oauth': \0.1.x
