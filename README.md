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

## Usage

A simple example of using Innate that also shows you how to add your custom
middleware, write specs and the overall concept:

    require 'innate'

    Innate.setup_middleware

    Innate.map('/') do |env|
      Rack::Response.new(['Hello, World!']).finish
    end

    Innate::Mock.get('/')

And another example, using Node with a normal server:

    require 'innate'

    class Hi
      include Innate::Node
      map '/'

      def index
        "Hello, World!"
      end
    end

    Innate.start :adapter => :mongrel

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

## Differences to Ramaze

Innate throws a lot over board that makes Ramaze a very good option for large
apps and doesn't provide all the bells and whistles that you may be used to.

This is the reason why Innate won't only be a standalone framework but also the
new core for Ramaze.

Ramaze started out without any of the benefits that Rack gives us these days, especially regarding the server handlers, request/response, and the various middlewares.
Still it tried to provide everything one might need with the least effort,
leading to a lot of inlining of dependencies (we have things like bacon,
simple_http, gettext, mime types, ...)

Here I try to list the most important things that Ramaze will offer but that
are not included in Innate itself in terms of globs:

* cache.rb and cache/*.rb
* current/response.rb
* tool/{create,mime,localize,daemonize,record,project_creator}.rb
* spec/helper/*.rb
* snippets/**/*.rb
* gestalt.rb
* store/default.rb
* contrib.rb or any contribs
* adapter/*.rb (superseded by a lightweight adapter.rb)
* template/ezamar*/*
* bacon.rb
* dispatcher.rb
* dispatcher/*.rb

There might be a couple of things i've forgotten, but that's what a quick
glance tells me.

Let's go through them one by one and decide what's gonna happen to them:

### Cache

Caching is a very important concern and one of the most difficult things to get
right for any web application.
Ramaze tried to get caching done right and I consider it fairly successful when it comes to that.
There are a myriad of options available for caching, different caching
mechanisms such as marshal to filesystem, memcached, in-memory, yaml to
filesystem, etc.
The granularity can be chosen depending on the usecase, distributed caching of
sessions, actions, single key/value pairs, and so on, fine-tuning each of those
to use a different mechanism is done as painless as possible.

We have gone through a lot of difficulties, memory-leaks, disputes, and
challenges to get this done, but most users won't realize this until they
encounter a problem.

At this point I would really like to thank all of the people who contributed to
caching as it is today.

I will move caching in a lighter form to Innate, mostly what is needed for
distributed sessions, giving Ramaze the opportunity to add new kinds.

### Response

This was always a very little class since Rack started providing more features,
I think it's time to retire it and lobby for integration of features into Rack
itself.

### Tools

Ramaze acquired quite a lot of tools, some of those are not useful anymore,
other ones might have to stick around.

#### Tool::Create

This has been used by `bin/ramaze --create` and I think it will stick around for some more time.

#### Tool::ProjectCreator

Dependency for Tool::Create, should get a lot more documentation and exposure
because I think it can be very useful for sharing and creating basic
application skeletons.
Another route would be to find a better tool and make it a dependency for
`ramaze --create`, but that would give a terrible out-of-the-box experience.

##### Tool::Daemonize

Nothing but issues with this one although it is just a very thin wrapper for the daemons gem. Nobody has contributed to this so far despite the issues and it seems that there are a lot of different solutions for this problem.
This will be removed from both Ramaze and Innate.

##### Ramaze::Record

Well, this might be the most obvious candidate for removal, maybe it can be
revived as a middleware.
The functionality itself is in the adapter and even that's only a few lines.
But so far I have never seen any usage for it.

##### Tool::Localize

I and a lot of other people have used this over time and it has proven itself
to be a very easy and straight-forward way of doing localization.

It think it is better suited as a middleware which can be included into rack-contrib
and doesn't rely on the normal session but a simple unobfuscated cookie.

##### Tool::MIME

This one will be removed, Rack::Mime is a viable alternative.

### Spec helpers

Over the years, Ramaze has collected a wide variety of spec helpers that are
not really compatible to each other and rely on real request/response with a
running server.
Innate provides a better alternative via Innate::Mock for its own specs,
applications will need the power of a real scraping library and we will provide
a canonical way of running a server in the background before running the specs.
There will not be any other helpers in Innate, but Ramaze might provide a few
standard ones to get up and running (hpricot, rexml).

Regarding the spec output parsers, that's a different issue.
Providing readable output while running specs is a major feature that must be included in order to keep frustration low.
We will provide a suitable logger replacement so one can simply extend Bacon
with that in order to get nice summaries and good error output.

### Snippets

Snippets have been in Ramaze since day 1, but I think it is wrong for Innate to
provide those. Over the years there have been lots of libraries that all
provide their own core extensions and interference is a major issue. Innate
will keep everything as clean as possible, doing subclasses inside the Innate
namespace where it needs to change things.
Two things that we need are (currently) String#each, because Rack relies on it,
and BasicObject as superclass for the Option class. They are only applied on demand.
These are in the directory called core_extensions, to make it very, very clear
what we are doing and how we are doing it.

Ramaze has still a lot of these snippets and will continue to, although I will
constantly strive to reduce them slowly.

### Gestalt

Gestalt has been the first "templating_engine" for Ramaze and is still used in some fractions of the code and various applications. There are a lot of other html/xml builders out there these days so I think this is no good choice for inclusion into Innate.
I will keep it inside Ramaze.

### Ramaze::Store::Default

I will remove this class from both Innate and Ramaze. It started out as a
simple wrapper for YAML::Store to make the tutorial easier, but I think it
gives a wrong impression of being anything else.

It's very slow, might raise under heavy load and a plain YAML::Store or PStore
or any other persistence mechanism is generally a better choice, no need to
keep this around.

### Contrib

There's a lot in there, and some of these things are used widely, others not at all.
Some things are better suited as middleware, I will move them to rack-contrib ASAP:
* gzip_filter
* profiling 

Then there's things that don't see much use, they should stay in the future
ramaze contrib or face removal:
* facebook
* gettext
* maruku_uv
* sequel_cache
* rest

And other things that should be moved into Ramaze proper:
* email
* file_cache (done)
* gems

Neither of them will be added to Innate


