require 'eyediff/env'
require 'helper'

module EyeDiff
  module Cache
    class References

      REFDIR    = EyeDiff::Env.reference_directory
      NOTESNAME = 'notes.txt'

      def self.each
        get_names.each do |name|
          paths = get_image_paths(name)
          yield name, paths
        end
      end

      def self.get_notes(name)
        dir = File.join(REFDIR, name)
        fname = File.join(dir, NOTESNAME)
        return File.read(fname) if File.exists?(fname)

        nil
      end

      def self.get_image_paths(name)
        image_paths = []
        dir = File.join(REFDIR, name)
        return image_paths unless Dir.exists?(dir)
        Dir.entries(dir).keep_if { |e| e !~ /^\./ && e !~ /^notes\.txt$/i }.map { |fname| File.join(REFDIR, name, fname)}
      end

      def self.get_names
        dir = File.join(REFDIR)
        Dir.entries(dir).keep_if { |e| e !~ /^\./ && File.directory?(File.join(REFDIR, e)) }
      end

      def self.add(name, images, notes=nil)
        folder_path = File.join(REFDIR, name)

        unless Dir.exists?(folder_path)
          Dir.mkdir(folder_path)
          Helper::Output.print_status("Reference directory added: #{name}")
        end

        add_image(name, images)
        add_notes(name, notes) if notes && !notes.empty?
      end

      private

      def self.add_image(ref_name, images)
        folder_path = File.join(REFDIR, ref_name)

        images.each do |image|
          fname = File.basename(image[:fname])
          data  = image[:data]
          File.open(File.join(folder_path, fname), 'wb') do |f|
            Helper::Output.print_status("Adding reference #{fname} for #{ref_name}")
            f.write(data)
          end
        end

        nil
      end

      def self.add_notes(ref_name, notes)
        path = File.expand_path(File.join(REFDIR, ref_name, EyeDiff::References::NOTESNAME))

        Helper::Output.print_status("Adding notes for #{ref_name}")
        File.open(path, 'wb') do |f|
          f.write(notes)
        end

        nil
      end
    end
  end
end
