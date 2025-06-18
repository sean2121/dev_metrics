require 'json'
require_relative 'format_base'

module DevMetrics
  class Json < FormatBase

    def call
      write
    end

    private

    def write
      data = {}
      columns.each_with_index do |col, idx|
        key = col['label'] || col['key'] || col
        data[key] = build_row[idx]
      end
      File.open(file_name, "w") do |file|
        file.puts JSON.pretty_generate(data)
      end
    end

    def file_name
      "output.json"
    end
  end
end