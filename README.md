# Innate

Innate is the new core of Ramaze, but useful on its own.

## Features

* Powerful Helper system
* Nodes[1] simply include Innate::Node, so class inheritance is your choice.
* The only hard dependency is Rack
* Easy to get started
* Compatible with major Ruby implementations[2].
* Usage of Fiber[3] instead of Thread if possible.
* Namespaced serializable configuration system
* Simple testing without need of a running server
* No clutter in your application directory structure, scales from a single file
  upwards
* Seamless integration with Rack middleware
* No patching[4] of ruby core or stdlib.
* Direct access to the current Request, Response, and Session from anywhere via
  Trinity
* Supporting numerous templating engines.
* Any action can be presented in multiple ways.

[1]: What you may think of as Controller.
[2]: This includes: Ruby 1.8, Ruby 1.9.1, JRuby, Rubinius
[3]: Fiber is available on 1.9 only at this point.
[4]: However, we add String#each if it isn't there to be compatible with Rack.
[5]: As far as 

## Installation

### Via git (recommended)

Installing Innate from git is highly recommended, since it gives you easy
access to alternate branches, bugfixes, and new features.

    git clone git://github.com/manveru/innate.git

and add the innate/lib directory to your `RUBYLIB` environment variable.

For unixish systems you may want to add it to `~/.bashrc` or the equivalent for
your shell:

    export RUBYLIB="~/path/to/innate/lib:$RUBYLIB"

### Via gem install

#### From github

    gem install manveru-innate --source=http://gems.github.com

#### From rubyforge

Not yet, and not sure when i'll get around to do this, feel free to ask if you
want to maintain the project at rubyforge.
