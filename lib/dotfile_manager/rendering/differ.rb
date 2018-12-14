module DotfileManager
  module Rendering
    class Differ
      def initialize(template)
        @template = template
      end

      def diff
        out, _ = Open3.capture2("diff #{comparison_path} -", stdin_data: @template.to_s)
        out
      end

      def diff
        return "[no current file at #{comparison_path}]" unless File.exists?(comparison_path)
        # FIXME: check if comparison file exists
        Open3.pipeline_rw(
          "diff -U3 --minimal #{comparison_path} -",
          "sed 's/^-/\x1b[1;31m-/;s/^+/\x1b[1;32m+/;s/^@/\x1b[1;34m@/;s/$/\x1b[0m/'"
        ) do |stdin, stdout, _thr|
          stdin.puts(@template.to_s)
          stdin.close

          stdout.read
        end
      end

      def comparison_path
        @template.target_path
      end
    end
  end
end


