#!/usr/bin/env lsc -cj
author:
  name: ['Chen Hsin-Yi']
  email: 'ossug.hychen@gmail.com'
name: 'pgrest-passport'
description: 'pgrest plugin for passportjs'
version: '0.0.3'
main: \lib/index.js
repository:
  type: 'git'
  url: 'git://github.com/hychen/pgrest-passport.git'
scripts:
  test: """
    mocha
  """
  prepublish: """
    lsc -cj package.ls &&
    lsc -bc -o lib src
  """
  postinstall: """
 	if [ ! -e ./lib ]; then npm i LiveScript; lsc -bc -o lib src; fi
  """
engines: {node: '*'}
dependencies:
  trycatch: \1.0.x
  passport: \0.1.x
  'express-jwt': \0.2.x
  'jsonwebtoken': \0.4.x
devDependencies:
  mocha: \1.14.x
  supertest: \0.7.x
  chai: \1.8.x
  LiveScript: \1.2.x
  pgrest: \0.1.x
peerDependencies:
  pgrest: \0.1.x
optionalDependencies:
  'passport-facebook': \1.0.x
  'passport-twitter': \1.0.x
  'passport-google-oauth': \0.1.x
