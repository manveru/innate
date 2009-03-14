module Innate
  # this has to be run after a couple of other files have been required

  options.dsl do
    o "Indicate that calls Innate::start will be ignored",
      :started, false

    o "Will send ::setup to each element during Innate::start",
      :setup, [Innate::Cache, Innate::Node]

    o "Trap this signal to issue shutdown, nil/false to disable trap",
      :trap, 'SIGINT'

    o "The compiler for middleware",
      :middleware_compiler, Innate::MiddlewareCompiler

    o "Indicates which default middleware to use, (:dev|:live)",
      :mode, :dev

    trigger(:mode){|v| Innate.middleware_recompile(v) }
  end
end
