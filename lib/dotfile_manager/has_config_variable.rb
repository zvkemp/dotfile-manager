module DotfileManager
  module HasConfigVariable
    def method_missing(name, *args, &block)
      config.variable(name.to_s, @template.mod) or super
    end
  end

  module HasTarget
    # usage:
    #   target :manjaro do
    #     ...
    #   end
    #
    #   target /manjaro/ do
    #     ...
    #   end
    #
    #   target -> (t) { t.start_with?(m) } do
    #     ...
    #   end
    #
    #   target
    def target(target)
      if target === @target
        if block_given?
          yield
        end

        return true
      end

      false
    end

    # FIXME: not sure I want to re-enable this.
    #
    # manjaro do
    #  ...
    # end
    #
    # VS:
    #
    # target :manjaro do
    #   ...
    # end
    # ^ seems better
    #
    # def method_missing(name, *args, &block)
    #   binding.pry
    #   query = name.to_s.end_with?('?')

    #   target = name.to_s.sub(/\?\Z/, '')

    #   if ::CONFIG['targets'][target]
    #     return false unless target == @target
    #     return true if query
    #     yield
    #   else
    #     return false if query
    #     super
    #   end
    # end
  end
end
