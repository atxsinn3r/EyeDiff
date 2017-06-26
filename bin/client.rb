#!/usr/bin/env ruby

lib = File.expand_path(File.join(__FILE__, '..', '..', 'lib'))
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'xmlrpc/client'
require 'eyediff'
require 'helper'
require 'optparse'

class EyeDiffClient

  class Error < ::RuntimeError; end

  POOLSIZE = 5

  attr_accessor :server

  def initialize(host)
    path = '/'
    port = 3000
    timeout = 604800 # 7 days, that should be fine right?
    @server = XMLRPC::Client.new(host, path, port, nil, nil, nil, nil, nil, timeout)
  end

  def identify_single(image_path)
    unless File.exists?(image_path)
      raise EyeDiffClient::Error, "#{image_path} does not exist."
    end

    data = File.read(image_path)
    server.call_async('diff.identify', Helper::Converter.pack_binary(data))
  end

  def identify_multiple(dir)
    pool = EyeDiff::ThreadPool.new(POOLSIZE)
    images = get_images_from_dir(dir)

    begin
      images.each do |fname|
        short_name = File.basename(fname)
        pool.schedule do
          Helper::Output.print_status("Attempting to identify #{short_name}")
          results = identify_single(fname)
          unless results['message'].empty?
            Helper::Output.print_status("#{short_name} found a match as #{results['message']['name']}")
            pool.mutex.synchronize do
              notes = results['message']['notes'] || ''
              EyeDiff::Report.make_local_report_data(short_name, File.read(fname), notes)
            end
          end
        end

        sleep(0.1)
      end
    ensure
      pool.shutdown
    end

    sleep(0.5) until pool.eop?
  end

  def get_images_from_dir(dir)
    raise EyeDiffClient::Error, "Directory #{dir} not found." unless Dir.exists?(dir)
    fnames = Dir.entries(dir).keep_if { |fname| fname =~ /\.png$/i }.map { |fname| File.join(dir, fname) }
    Helper::Output.print_status("Number of images to look up: #{fnames.length}")
    fnames
  end

  def add_exception(md5)
    results = server.call('diff.exception', md5)
    Helper::Output.print_status(results['message'])
  end

  def add_reference(dir)
    raise EyeDiffClient::Error, "Directory #{dir} not found." unless Dir.exists?(dir)

    image_paths = Dir.entries(dir).keep_if { |fname| fname =~ /\.png$/i }.map { |fname| File.join(dir, fname) }
    ref_name = File.basename(dir)
    images = image_paths.collect { |image_path|
      fname = File.basename(image_path)
      data  = Helper::Converter.pack_binary(File.read(image_path))
      { fname: fname, data: data }
    }
    Helper::Output.print_status("Adding #{images.length} references for #{ref_name}")
    notes_path = File.join(dir, 'notes.txt')
    notes = File.exists?(notes_path) ? File.read(notes_path) : ''
    results = server.call('diff.addreference', ref_name, images, notes)
    Helper::Output.print_status(results['message'])
  end

  def self.get_user_inputs
    inputs = { arg: nil, action: nil, host: nil }

    parser = OptionParser.new do |opt|
      opt.banner = "Usage: #{__FILE__} [options]"
      opt.separator ''
      opt.separator 'Specific options:'

      opt.on('-h', '--host <String>', 'Required. IP to the image diffing server.') do |v|
        inputs[:host] = v
      end

      opt.on('-d', '--dir <String>', 'A directory of images to identify') do |v|
        inputs[:action] = :dir
        inputs[:arg] = v
      end

      opt.on('-s', '--single--image <String>', 'Identify a single image') do |v|
        inputs[:action] = :single
        inputs[:arg] = v
      end

      opt.on('-a', '--add <String>', 'Add a new reference from a directory') do |v|
        inputs[:action] = :add
        inputs[:arg] = v
      end

      opt.on('-e', '--except <String>', 'MD5 Hash of the image you wish to add to the black list') do |v|
        inputs[:action] = :except
        inputs[:arg] = v
      end

      opt.on_tail('--help', 'Show this message') do
        puts opt
        exit
      end
    end

    parser.parse!(ARGV)

    inputs
  end

  def self.run
    inputs = get_user_inputs
    raise EyeDiffClient::Error, 'Host not set' unless inputs[:host]
    cli = self.new(inputs[:host])

    case inputs[:action]
    when :dir
      cli.identify_multiple(inputs[:arg])
    when :single
      results = cli.identify_single(inputs[:arg])
      if results['message'].empty?
        Helper::Output.print_status("No match found for #{File.basename(inputs[:arg])}")
      else
        Helper::Output.print_status("Found match for #{File.basename(inputs[:arg])}: #{results['message']['name']}")
      end
    when :add
      cli.add_reference(inputs[:arg])
    when :except
      cli.add_exception(inputs[:arg])
    end
  end

end

if __FILE__ == $PROGRAM_NAME
  begin
    EyeDiffClient.run
  rescue EyeDiffClient::Error, OptionParser::InvalidOption => e
    Helper::Output.print_error("Error: #{e.message}")
  end
end
