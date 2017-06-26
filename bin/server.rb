#!/usr/bin/env ruby

lib = File.expand_path(File.join(__FILE__, '..', '..','lib'))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'eyediff'
require 'helper'
require 'xmlrpc/server'

class EyeDiffServer
  PORT = 3000

  class HandlerNames
    IDENTIFY  = 'diff.identify'
    ADDREF    = 'diff.addreference'
    EXCEPTION = 'diff.exception'
  end

  class Handlers
    def initialize
      @cache = EyeDiff::Cache.new
    end

    def identify(encoded_data)
      image_data = Helper::Converter.to_binary(encoded_data)

      if image_data.empty?
        results = ''
      else
        results = id_image(image_data)
      end

      { message: results }
    end

    def add_exception(md5)
      Helper::Output.print_status("Adding #{md5} to blacklist")
      msg = ''

      if @cache.is_md5_in_blacklist?(md5)
        msg = "#{md5} already in blacklist"
      else
        @cache.add_md5_to_blacklist(md5)
        msg = "#{md5} added to blacklist"
      end

      Helper::Output.print_status(msg)

      { message: msg }
    end

    def add_reference(args)
      name   = args[0]
      images = []
      notes  = args[2]

      if EyeDiff::Security.is_path_malicious?(name)
        raise XMLRPC::FaultException(0, 'The reference path looks malicious.')
      end

      args[1].each { |item|
        item['data'] = Helper::Converter.to_binary(item['data'])
        images << Helper::Converter.hash_key_strings_to_symbols(item)
      }

      EyeDiff::References.add(name, images, notes)
      image_names = EyeDiff::References.get_image_paths(name)
      @cache.add(name: name, paths: image_names)

      { message: 'OK' }
    end

    def close
      @cache.close
      { messages: 'OK' }
    end

    def md5_match(image_data)
      @cache.each do |ref_name, refs|
        refs.each do |ref|
          md5 = ref[:md5]
          diff = EyeDiff::Differ::MD5.new(image_data, md5)
          return ref_name if diff.same?
        end
      end

      nil
    end

    def pixel_match(image)
      @cache.each do |ref_name, refs|
        begin
          refs.each do |ref|
            ref_data = File.read(ref[:path])
            diff = EyeDiff::Differ::Pixel.new(image, ref_data)
            return ref_name if diff.similar?
          end
        rescue EyeDiff::Differ::Pixel::Error => e
          Helper::Output.print_error(e.message)
          return false
        end
      end

      nil
    end

    def id_image(image)
      if @cache.is_in_blacklist?(image)
        Helper::Output.print_status("Image in black list")
        return {}
      end

      Helper::Output.print_status("Identifying image...")

      name = md5_match(image) || pixel_match(image)
      if name
        Helper::Output.print_status("Found a match: #{name}")
        @cache.increase_popularity(name)
        notes = EyeDiff::References.get_notes(name)
        results = {}
        results[:name] = name
        results[:notes] = notes if notes
        return results
      else
        @cache.add_to_blacklist(image)
        Helper::Output.print_status('Updated the blacklist')
      end

      {}
    end

  end

  def self.run
    h = Handlers.new
    begin
      server = XMLRPC::Server.new(PORT)
      server.add_handler(EyeDiffServer::HandlerNames::IDENTIFY) { |encoded_data| h.identify(encoded_data) }
      server.add_handler(EyeDiffServer::HandlerNames::ADDREF) { |*args| h.add_reference(args) }
      server.add_handler(EyeDiffServer::HandlerNames::EXCEPTION) { |md5| h.add_exception(md5) }
      server.set_default_handler { |name, *args| raise XMLRPC::FaultException.new(-99, 'Error') }
      server.serve
    ensure
      h.close
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  EyeDiffServer.run
end
