#!/usr/bin/ruby

require "rubygems"
require "RMagick"

THUMB_SIZES   = [[1200,800],[300,200]]
ICON_SIZE     = 75 # => for flickr style cropping
IMG_EXTENSIONS = "jpg jpeg gif png".split(" ").map {|ext| ".%s" % ext} # crw cr2 raf orf nef





def print_help
  puts "Usage:"
  puts "ruby %s [options] folder_path [folder_path]" % __FILE__
  puts "-r recurse"
  puts "-i generate icon files into folders."
  puts "-t generate thumb files into folders."
end





class ImageFolder
  
  def initialize source
    @source_folder = source
    files = Dir.entries(source)
    @image_files = files.select { |file| is_image(file) }
    @directories = files.select { |file| File.directory?(File.join(source,file)) }
  end
  
  def is_image path
    return false if (path[0,1]==".")
    IMG_EXTENSIONS.each do |ext|
      return true if path.downcase.include?(ext)
    end
    false
  end
  
  def generate_thumbs sizes=THUMB_SIZES
    return unless has_images?()
    
    sizes.each do |dimensions|
      suffix = "-%ix%i" % dimensions
      thumb_folder = File.join(File.dirname(@source_folder), File.basename(@source_folder) + suffix)
      Dir.mkdir(thumb_folder) unless File.directory?(thumb_folder)

      @image_files.each do |file|
        components = file.split(".")
        components[-2] += suffix
        components[-1] = "jpg"
        outfilename = File.join(thumb_folder, components.join("."))
        unless (File.exists?(outfilename))
          img = Magick::Image.read(File.join(@source_folder, file)).first
          # if (img.columns<img.rows)
          #   img.rotate!(90)
          # end
          img.resize_to_fit!(dimensions[0], dimensions[1])
          img.write(outfilename)
        end
      end
    end
  end
  
  def generate_icons size=ICON_SIZE
    return unless has_images?()
    
    suffix = "-%i" % size
    icon_folder = File.join(File.dirname(@source_folder), File.basename(@source_folder)+suffix)
    Dir.mkdir(icon_folder) unless File.directory?(icon_folder)

    @image_files.each do |file|
      components = file.split(".")
      components[-2] += suffix
      components[-1] = "jpg"
      outfilename = File.join(icon_folder, components.join("."))
      unless (File.exists?(outfilename))
        img = Magick::Image.read(File.join(@source_folder, file)).first
        img.crop_resized!(size, size, Magick::NorthGravity)
        img.write(outfilename)
      end
    end
  end
  
  def has_images?
    return (@image_files.length > 0)
  end
  
  def get_images
    @image_files.map {|img| File.join(@source_folder, img)}
  end
  
  def get_directories
    dirs = @directories.reject {|f| !f.match(/-\d+x\d+/).nil? || f=="." || f==".."}
    dirs.map! {|f| File.join(@source_folder, f)}
  end
  
  def to_s
    "Image folder object"
  end
  
end









def process_folder path, do_recurse=false, do_icons=true, do_thumbs=false
   if File.directory?(path) then
      puts "Processing %s." % path
      f = ImageFolder.new path
      f.generate_icons if do_icons
      f.generate_thumbs if do_thumbs
      
      if (do_recurse)
        f.get_directories().each do |path|
          process_folder(path, do_recurse, do_icons, do_thumbs)
        end
      end
    else
      puts "Not a folder: %s" % path
    end
end

if __FILE__==$0
  
  images_folders = []
  do_recurse = false
  do_icons = false
  do_thumbs = false
  $*.each do |arg|
    if (arg[0,1]=="-")
      case arg
      when "-r" then do_recurse = true
      when "-i" then do_icons = true
      when "-t" then do_thumbs = true
      end
    elsif arg.is_a?(String) && !arg.strip.empty?
      images_folders.push arg
    end
  end
  
  if (images_folders.length < 1 || (!do_icons && !do_thumbs))
    print_help
    exit
  end
    
  images_folders.each do |path|
    process_folder path, do_recurse, do_icons, do_thumbs
  end
  
end















