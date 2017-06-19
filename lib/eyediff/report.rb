require 'eyediff/env'
require 'eyediff/references'
require 'eyediff/logger'
require 'json'
require 'uri'
require 'terminal-table'

module EyeDiff
  class Report
    def has_json?
      File.exists?(EyeDiff::Env.json_location)
    end

    def init_json
      File.open(EyeDiff::Env.json_location, 'wb') { |f| f.write('{}') }
      '{}'
    end

    def load_json
      File.read(EyeDiff::Env.json_location)
    end

    def save_json(json)
      data = json.to_json
      File.open(EyeDiff::Env.json_location, 'wb') do |f|
        f.write(json)
      end
    end

    def save_image(fname, image_data)
      path = File.expand_path(File.join(EyeDiff::Env.json_location, '..', '..', 'report', 'images', fname))
      File.open(path, 'wb') { |f| f.write(image_data) }
    end

    def self.make_local_report_data(fname, image_data, notes='')
      report = self.new
      fname = Helper::Converter.normalize_uri_filename(fname)
      report.save_image(fname, image_data)

      json = JSON.parse(report.has_json? ? report.load_json : report.init_json)
      json[fname] = notes
      report.save_json(json.to_json)

      EyeDiff::Logger.log("#{fname} saved to JSON.")
    end

    def self.print_notes(name)
      notes = References.get_notes(name)
      puts
      puts notes
    end

    def self.print_popularity(cache)
      rows = []

      cache.keys.each do |name|
        rows << [name, cache[name][:popularity]]
      end

      table = Terminal::Table.new(rows: rows)
      EyeDiff::Logger.log('Popularity Table:')
      puts table
    end
  end
end
