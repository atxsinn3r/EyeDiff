require 'eyediff/env'
require 'eyediff/references'
require 'json'
require 'uri'
require 'terminal-table'

module EyeDiff
  class Report
    def has_json?(type)
      case type
      when :images
        File.exists?(EyeDiff::Env.image_json_location)
      when :notes
        File.exists?(EyeDiff::Env.notes_json_location)
      end
    end

    def init_json(type)
      case type
      when :images
        File.open(EyeDiff::Env.image_json_location, 'wb') { |f| f.write('{}') }
      when :notes
        File.open(EyeDiff::Env.notes_json_location, 'wb') { |f| f.write('{}') }
      end

      '{}'
    end

    def load_json(type)
      case type
      when :images
        File.read(EyeDiff::Env.image_json_location)
      when :notes
        File.read(EyeDiff::Env.notes_json_location)
      end
    end

    def save_json(type, json)
      data = json.to_json
      case type
      when :images
        path = EyeDiff::Env.image_json_location
      when :notes
        path = EyeDiff::Env.notes_json_location
      end

      File.open(path, 'wb') do |f|
        f.write(json)
      end
    end

    def save_image(fname, image_data)
      path = File.expand_path(File.join(EyeDiff::Env.report_image_location, fname))
      File.open(path, 'wb') { |f| f.write(image_data) }
    end

    def self.make_local_report_data(fname, image_data, notes='')
      report = self.new
      fname = Helper::Converter.normalize_uri_filename(fname)
      report.save_image(fname, image_data)

      # Create image list in JSON
      image_json = JSON.parse(report.has_json?(:images) ? report.load_json(:images) : report.init_json(:images))
      image_json[fname] = Helper::Converter.to_md5(image_data)
      report.save_json(:images, image_json.to_json)

      # Creates notes in JSON
      notes_json = JSON.parse(report.has_json?(:notes) ? report.load_json(:notes) : report.init_json(:notes))
      notes_json[fname] = notes
      report.save_json(:notes, notes_json.to_json)
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
      Helper::Output.print_status('Popularity Table:')
      puts table
    end
  end
end
