# Innate

Innate is the core of Ramaze, but useful on its own.


## Philosophy

The philosophy behind Innate is to provide a simple web-framework that:

* Stays below 2000 easily readable lines of code
* Has Rack as the only dependency
* Provides the default helpers
* Is easy to encapsulate and reuse in other contexts as a simple rack app
* Has a rock-solid and fast implementation
* Scores at least 95% in rcov
* Is fully documented using YARD


## Innate vs. Ramaze

Numerous people asked where Innate fits into the picture of Ramaze and when it
would be appropriate to use Innate alone.

The answer to this is not as simple as I thought, given that Ramaze improves on
it a lot by taking full advantage of the encapsulation.

Innate started out as I grew increasingly annoyed by the many hacks and add-ons
that diluted the original simplicity of Ramaze as we discovered ways to do
things better, so I went on to create something that is impossible to dilute and
simply works as a multiplier.

It does work standalone, and it might be suitable for applications that just
need the little extra over plain old Rack, making it easy to deploy and rely on
the stability that comes with simple code.
It's also the starting point if you want to study the inner workings of Ramaze
without being distracted, all you need to keep in mind is Rack.

If all you need is a couple of ERB templates and a few nodes then Innate is the
way to go.
Upgrading to Ramaze later is quite easy, just change a couple of lines and the
power of your code multiplies (again).

The split between Innate and Ramaze is clear cut and gives Ramaze freedom to
expand in any direction (and I have quite some ideas where to take it).

Ramaze adds things that require other dependencies, caching with memcached or
sequel, logging with analogger or growl, templating with haml or erubis, just to
name a few.

Ramaze also adds Apps to the mix, and it is easier to understand them when the
concepts of what's going on inside an App is completely abstracted by Innate.

To summarize, Innate really keeps it simple, acts as a learning tool and
encourages everybody to build on top of it whatever they want.


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
* No patching of ruby core or stdlib.
* Direct access to the current Request, Response, and Session from anywhere via
  Trinity
* Works out of the box with ERB the templating engine.
* Support for all rack-compatible web-servers.
* Dynamic content-representation.

[1]: What you may think of as Controller.
[2]: This includes: Ruby 1.8, Ruby 1.9.1, JRuby, Rubinius
[3]: Fiber is available on 1.9 only at this point.

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

Innate has support for only
Innate supports multiple templating engines and it is very easy to add your
own.
At the moment we offer following engines out of the box:

* [Builder](http://builder.rubyforge.org)
* [Haml](http://haml.hamptoncatlin.com/)
* [Sass](http://haml.hamptoncatlin.com/docs/sass)
* [Erubis](http://rubyforge.org/projects/erubis)
* [Tenjin](http://www.kuwata-lab.com/tenjin/)

How to build your own is discussed at
[HowTo:View](http://ramaze.net/HowTo:View).


### Controller

Innate follows a different approach than most frameworks, making the controller
subclassing obsolete. To make an object accessible from the outside simply
include Innate::Node and map it to the location you would like.


## Differences from Ramaze

Innate throws a lot overboard; it doesn't provide all the bells and whistles
that you may be used to. This makes Ramaze the way to go for larger
applications.

For this reason, Innate is not only a standalone framework, it is also the core
of Ramaze.

Ramaze started out without any of the benefits that Rack gives us these days,
especially regarding the server handlers, request/response, and middleware.

Still it tried to provide everything one might need with the least effort,
leading to a lot of incorporation of dependencies (we have things like bacon,
simple_http, gettext, mime types, ...)


### Configuration

Innate provides the Innate::Options DSL, in some aspects to the old
Ramaze::Global, but a lot more flexible.

Options has namespaces, inheritance, defaults, triggers, documentation, and a
sane name.

The definition syntax roughly resembles Ramaze::Global.

We break with the tradition where all options one would ever need were provided
in one file. It made maintenance rather difficult and the code hard to follow.
So the new approach is to put options where they belong, alongside the class or
module they are used in.

There are some things still in Innate.options, but they have large impact on the
whole system.

Options doesn't do things like merging env variables or parsing ARGV, these are
things that Ramaze adds.

What makes Options especially useful is that you can use it in your own
application to configure it without using diverse routes like putting config
into counter-intuitive yaml files, using global variables, or relying on yet
another dependency.

A small example:

    module Blog
      include Innate::Optioned

      options.dsl do
        o "Title of the blog", :title, "My Blog"
        o "Syntax highlighting engine for blog posts", :syntax, :coderay
      end

      class Articles
        Innate.node '/'

        def index
          "Welcome to #{Blog.options.title}"
        end
      end
    end


### Controller

Away with controllers, long live the Node.

Nodes are objects that include Innate::Node and are then considered rack
applications that get automatically hooked into the routing.

Since every existing Ramaze application relies on Ramaze::Controller and normal
subclassing is not without merits as well we keep that part entirely in Ramaze,
Controller simply includes Innate::Node and makes it suitable for the usage
within Apps.


#### Layouts

Since layouts were an afterthought in Ramaze, they were made normal actions
like every other on the respective controllers, leading to lots of confusion
over the correct way to use layouts, the Controller::layout syntax in respect
to the real location of layouts, how to exclude/include single actions, where
layouts should be stored, how to prevent lookup from external requests, ...

I made layouts just as important as views and methods for the Action in Innate,
and they have their own root directory to live in and will not be considered as
a normal view template, so they cannot be accidentally be rendered as their own
actions.

This strikes me as important, because I consider layouts to be superior to
Ezamar elements and equal to render_partial or render_template, just about
every application uses it, so they should be handled in the best way possible.

The root directory for layouts is in line with the other default locations:

    proto
    |-- layout
    |-- model
    |-- node
    |-- public
    `-- view

While none of these directories is necessary, they are the default locations and
should be included in a new proto for Ramaze (just that ramaze uses
`/controller` instead of `/node`.

Innate will not have project generating capabilities, so we just have to
document it very well and provide some example apps.


#### Provides

This is a major new feature stolen from Merb and adapted for the ease of use of
Innate/Ramaze.
It won't have all the capabilities one might be used to out of the box, but
extending them is easy.

Having "provides" means that every Action has different ways of being rendered,
depending on so-called wishes, that's what people usually call
content-representation.

A wish may be anything related to the request object, and by default it will
trigger on the filename extension asked for.
This enables you to create a single action that can be rendered in
json/rss/atom/yaml/xml/xhtml/html/wap or different languages...

The dispatching in Node depends on the filename extension by default, but more
decision paths can be added to Action by overriding some defaults.

Layouts map to wishes just like views, so every content representation can have
a suitable layout as well.

This is very alien to old Ramaze, which always has a 1:1 mapping between actions
and their views and how they are rendered, which made people wonder how to serve
sass as css or how to respond with json for a ajax request until they finally
were pointed to setting content-type, using respond and setting up custom
routes.

I hope this feature makes things simpler for people who care about it while it
can be ignored by people who don't.


### More specifics

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

There might be a couple of things I've forgotten, but that's what a quick
glance tells me.

Let's go through them one by one and consider what's gonna happen to them:


### Cache

Caching is a very important concern and one of the most difficult things to get
right for any web application.

Innate defines the caching API that enables everybody to add caches with very
little code.

Innate provides caching by following means:

* DRb
* Hash
* Marshal
* YAML

Ramaze adds:

* Memcached
* Sequel

And as time goes on there will be many more.


### Response

Very little code, just provide some options regarding default headers and easy
ways to reset the response.
Ramaze adds some more convenient methods.


### Tools

Innate doesn't provide any of the stuff in ramaze/tool and it was removed from
Ramaze as well, some of the reasoning is below.

#### Tool::Create

This has been used by `bin/ramaze --create`, bougyman is working on a new
`bin/ramaze` which won't use it, so we removed it.

#### Tool::ProjectCreator

Dependency for Tool::Create, removed as well.

##### Tool::Daemonize

Nothing but issues with this one although it is just a very thin wrapper for
the daemons gem. Nobody has contributed to this so far despite the issues and
it seems that there are a lot of different solutions for this problem.

This was removed from Ramaze and Innate. You may use the daemonize functionality
from rackup.

##### Ramaze::Record

Well, this might be the most obvious candidate for removal, maybe it can be
revived as middleware. The functionality itself was in the adapter and even
that's only a few lines. But so far I have never seen any usage of it.

##### Tool::Localize

Despite being quite popular it has many issues and is totally unusable if you
don't have full knowledge about what is going to be served.

I and a lot of other people have used this over time and it has proven itself
to be a very easy and straight-forward way of doing localization.

It think it is better suited as middleware which can be included into
rack-contrib and doesn't rely on the normal session but a simple unobfuscated
cookie.

Innate does not attempt to do anything related to localization. Ramaze builds
localization on top of Helper::Localize which does a much better job.

##### Tool::MIME

This one was removed, Rack::Mime is the way to go.


### Spec helpers

Over the years, Ramaze has collected a wide variety of spec helpers that are
not really compatible to each other and rely on real request/response with a
running server.

Innate provides a better alternative via Innate::Mock for specs, the output
formatting is done in a rake task.

There is some work in progress to integrate Innate and Ramaze with the rack-test
library which will allow us to run specs with webrat (which is able to run using
selenium and possibly watir in a DRY way).

Rack-test will provide us also with xpath checks, multipart requests, digest
authorization, etc.


### Snippets

Innate abandons the snippets, keeping your core clean.

Ramaze has still a lot of these snippets and will continue to, although I will
constantly strive to reduce them slowly.

### Gestalt

Gestalt has been the first "templating engine" for Ramaze and is still used in
some fractions of the code and various applications.  There are a lot of other
html/xml builders out there these days so I think this is no good choice for
inclusion into Innate. I will keep it inside Ramaze.

### Ramaze::Store::Default

This has been removed from Innate and Ramaze.
It started out as a simple wrapper for YAML::Store to make the tutorial easier,
but I think it gives a wrong impression of being anything else.

It's very slow, might raise exceptions under heavy load and a plain YAML::Store
or PStore or any other persistence mechanism is generally a better choice, so
there is no need to keep this around.

### Contrib

Ramaze got quite some things in contrib, some of them used widely, others not at
all.

I'm still going through these, putting what is suitable for a wider audience
into rack-contrib, including what fits into the Ramaze concept into Ramaze, but
none of these will find its way into Innate.

One exception, the file cache has been added to Innate already and the sequel
cache is in Ramaze proper.

The gzip filter has a more powerful and better maintained equivalent in
Rack::Deflater.

The profiling hook is obsolete as well, there is an equivalent in rack-contrib.

The emailer is really light-weight and but lacks support for many things you
will need, I'm working on a new Helper::Email that integrates with Mailit (a
fork of MailFactory).

Things I'll not touch for now are `facebook` and `gettext`.

The sequel related stuff will have to be removed and might find a place
somewhere else, (somebody start a sequel-contrib already!).

The `gems` was refactored and put into `ramaze/setup.rb`, where it provides you
with painless first-start experience.


### Adapters

These are entirely the responsibility of Rack/Innate now, Ramaze doesn't need to
worry about that. WEBrick will remain the default adapter since it is in the
Ruby stdlib.


### Templating

The basic functionality for templating is provided by Innate, it only provides a
`None` and `ERB` templating engine. The other engines are in Ramaze.

#### Ezamar

`Ezamar` has become a standalone project. It has been stable since a long time and
is suitable for other uses.
The battle for the place of the default templating engine in Ramaze is still
going on, competitors are `ERB`, `Ezamar`, and `Nagoro`.


### Bacon

Bacon is still a dependency for specs, but we don't ship it anymore, the stable
release includes all features we need.


### Dispatcher

Innate uses a stripped down version of the Ramaze dispatcher.  The Ramaze
dispatcher was strongly influenced by Nitro, but proved to be a difficult
part.  We are now using Rack's URLMap directly, and have a minimal dispatching
mechanism directly in Node (like we used to have one in Controller).

A lot of the functionality that used to be in the different dispatchers is now
provided by Rack middleware.

The Dispatcher itself isn't needed anymore. It used to setup
Request/Response/Session, which was superseded by Current, this again is now
superseded by STATE::wrap.

We are going to remove all the other dispatchers as well, providing default
ways to provide the same functionality, and various middleware to use.

#### Dispatcher::Action

This dispatcher was used to initiate the controller dispatching, this is now
not needed anymore.

#### Dispatcher::Directory

This will also be removed. There is a directory listing middleware already.

#### Dispatcher::Error

There's middleware for this as well, and a canonical way of routing errors to
other actions. This used to be one of the most difficult parts of Ramaze and
it was removed to make things simpler.

#### Dispatcher::File

This is a combination of the `ETag` and `ConditionalGet` middlewares, ergo Innate
and Ramaze will not serve static files themselves anymore, but leave the job to
Rack or external servers.
