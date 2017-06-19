require 'eyediff/env'
require 'eyediff/logger'
require 'chunky_png'

module EyeDiff
  class References

    REFDIR    = Env.reference_directory
    NOTESNAME = 'notes.txt'

    def self.get_notes(name)
      dir = File.join(REFDIR, name)
      fname = File.join(dir, NOTESNAME)
      if File.exists?(fname)
        return File.read(fname)
      end

      nil
    end

    def self.get_image_paths(name)
      image_paths = []
      dir = File.join(REFDIR, name)
      return image_paths unless Dir.exists?(dir)
      Dir.entries(dir).keep_if { |e| e !~ /^\./ && e !~ /^notes\.txt$/i }.map { |fname| File.join(name, fname)}
    end

    def self.get_names
      dir = File.join(REFDIR)
      Dir.entries(dir).keep_if { |e| e !~ /^\./ && File.directory?(File.join(REFDIR, e)) }
    end

    def self.add(name, images, notes=nil)
      folder_path = File.join(REFDIR, name)

      unless Dir.exists?(folder_path)
        Dir.mkdir(folder_path)
        EyeDiff::Logger.log("Reference directory added: #{name}")
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
          EyeDiff::Logger.log("Adding reference #{fname} for #{ref_name}")
          f.write(data)
        end
      end

      nil
    end

    def self.add_notes(ref_name, notes)
      path = File.join(REFDIR, ref_name, Eyediff::References::NOTESNAME)

      EyeDiff::Logger.log("Adding notes for #{ref_name}")
      File.open(path, 'wb') do |f|
        f.write(notes)
      end

      nil
    end

  end
end
