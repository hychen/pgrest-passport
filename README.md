pgrest-passport
===============

pgrest plugin fo passportjs.

# Installation

```
$ npm i pgrest
$ npm i pgrest-passport
```

# Configuration example.

```
{
  "host": "0.0.0.0",
  "port": "3000",
  "prefix": "/collections",
  "dbconn": "tcp://postgres@localhost",
  "dbname": "mydb",
  "dbschema": "mydb",
  "auth": {
    "enable": true,
    "success_redirect": "/me",
    "logout_redirect": "/",
    "plugins": [
      "facebook"
    ],
    "providers_settings": {
      "facebook": {
        "clientID": ".....",
        "clientSecret": "...."
      },
      "twitter": {
        "consumerKey": null,
        "consumerSecret": null
      },
      "google": {
        "consumerKey": null,
        "consumerSecret": null
      }
    }
  }
}
```

# Run

```
$ pgrest-passport --config config.json.
```

# Used in PgRest APP.

```
require! pgrest
require! pgrest-passport
pgrest.use pgrest-passport
app <- pgrest.cli! {}, {}, [], null, null
```
