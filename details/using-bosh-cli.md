# Using the BOSH CLI

The primary interface to BOSH is a command-line tool, `bosh` that is distributed as a RubyGem `bosh_cli`.

To install the CLI and display its available operations:

```
$ gem install bosh_cli
$ bosh
usage: bosh [--verbose] [--config|-c <FILE>] [--cache-dir <DIR]
            [--force] [--no-color] [--skip-director-checks] [--quiet]
            [--non-interactive]
            command [<args>]

Currently available bosh commands are:

Deployment
...
Release management
...
Stemcells
...
User management
...
Job management
...
Log management
...
Task management
...
Property management
...
Maintenance
...
Misc
...
Remote access
...
Blob
...
```


## Common flags

There are common flags for all operations.

```
$ bosh -h
Usage: bosh [options]
    -c, --config FILE
        --cache-dir DIR
        --verbose
        --no-color
    -q, --quiet
    -s, --skip-director-checks
    -n, --non-interactive
    -d, --debug
        --target URL
        --user USER
        --password PASSWORD
        --deployment FILE
    -v, --version
```


## Patches to discuss


### Make CLI a little bit more SRE-friendly

http://reviews.cloudfoundry.org/#/c/7634/

* added `--target`, `--deployment`, `--user`, `--password` command line options that can be used to override config file values;
* added UUID check when working with deployment manifest to avoid deploying wrong manifest (it's easier to do by mistake with `--target` and `--deployment`);
* CLI also respects `BOSH_USER` and `BOSH_PASSWORD` env variables (when it's undesirable to specify them via cmd line for security reasons).

