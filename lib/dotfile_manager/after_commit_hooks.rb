module DotfileManager
  module AfterCommitHooks
    HOOKS = Hash.new { |h, k| h[k] = [] }

    def self.[](mod)
      HOOKS[mod] || []
    end
  end
end
