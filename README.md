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

And add the innate/lib directory to your `RUBYLIB` environment variable.

For unixish systems you may want to add it to `~/.bashrc` or the equivalent for
your shell:

    export RUBYLIB="~/path/to/innate/lib:$RUBYLIB"

### Via gem install

#### From Github

    gem install manveru-innate --source=http://gems.github.com

#### From Rubyforge

Not yet, and not sure when I'll get around to do this, feel free to ask if you
want to maintain the project at rubyforge.

## Concepts

First let's see about the good old MVC:

### Model

Innate doesn't have any ties to models, it does not offer helpers or rake tasks
or whatever you may be expecting, there is no M, use whatever you like.
Innate is, however, known to be compatible with the ORMs listed below:

* ActiveRecord
* DataMapper
* M4DBI
* Og
* Sequel

Please consider giving us a heads up about what worked for you if it isn't in
the list yet.

### View

Innate supports multiple templating engines and it is very easy to add your own.
At the moment we offer following engines out of the box:

* [Builder](http://builder.rubyforge.org)
* [Haml](http://haml.hamptoncatlin.com/)
* [Sass](http://haml.hamptoncatlin.com/docs/sass)
* [Erubis](http://rubyforge.org/projects/erubis)
* [Tenjin](http://www.kuwata-lab.com/tenjin/)

How to build your own is discussed at [HowTo:View](http://ramaze.net/HowTo:View).

### Controller

Innate follows a different approach than most frameworks, making the controller
subclassing obsolete. To make an object accessible from the outside simply
include Innate::Node and map it to the location you would like.
