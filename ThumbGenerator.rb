#!/usr/bin/ruby

require "rubygems"
require "pdf/writer"
require "RMagick"
require "mini_exiftool"

THUMB_PREFIX  = "_thumb_" # => "_thumbs_300x200"
THUMB_POSTFIX = "-thumb"
THUMB_SIZES   = [[1200,800],[300,200]]
ICON_PREFIX   = "_icons_"
ICON_POSTFIX  = "-icon"
ICON_SIZE     = 75 # => for flickr style cropping
IMG_EXTENSIONS = "jpg jpeg gif png crw cr2 raf orf".split(" ").map {|ext| ".%s" % ext}





class ImageFolder
  
  def initialize source
    @source_folder = source
    files = Dir.entries(source)
    @image_files = files.select { |file| is_image(file) }
    @directories = files.select { |file| File.directory?(File.join(source,file)) }
  end
  
  def is_image path
    IMG_EXTENSIONS.each do |ext|
      return true if path.downcase.include?(ext)
    end
    false
  end
  
  def generate_thumbs sizes=THUMB_SIZES
    sizes.each do |dimensions|
      thumb_folder = File.join(@source_folder, "%s%ix%i" % [THUMB_PREFIX].concat(dimensions))
      Dir.mkdir(thumb_folder) unless File.directory?(thumb_folder)

      @image_files.each do |file|
        components = file.split(".")
        components[-2] += THUMB_POSTFIX
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
    icon_folder = File.join(@source_folder, ICON_PREFIX+size.to_s)
    Dir.mkdir(icon_folder) unless File.directory?(icon_folder)

    @image_files.each do |file|
      components = file.split(".")
      components[-2] += ICON_POSTFIX
      outfilename = File.join(icon_folder, components.join("."))
      unless (File.exists?(outfilename))
        img = Magick::Image.read(File.join(@source_folder, file)).first
        img.crop_resized!(size, size, Magick::NorthGravity)
        img.write(outfilename)
      end
    end
  end
  
  def get_images
    @image_files.map {|img| File.join(@source_folder, img)}
  end
  
  def get_directories
    dirs = @directories.reject {|f| f.include?(THUMB_PREFIX) || f.include?(ICON_PREFIX) || f=="." || f==".."}
    dirs.map! {|f| File.join(@source_folder, f)}
  end
  
  def to_s
    "Image folder object"
  end
  
end







def print_help
  p "Usage:"
  p "ruby %s [options] folder_path" % __FILE__
  p "-r recurse"
  p "-i generate icon files into %s folders." % ICON_PREFIX
  p "-t generate thumb files into %s folders." % THUMB_PREFIX
end

def process_folder path, do_recurse=false, do_icons=true, do_thumbs=false
   if File.directory?(path) then
      p "Processing %s." % path
      f = ImageFolder.new path
      f.generate_icons if do_icons
      f.generate_thumbs if do_thumbs
      
      if (do_recurse)
        f.get_directories().each do |path|
          process_folder(path, do_recurse, do_icons, do_thumbs)
        end
      end
    else
      p "Not a folder: %s" % path
    end
end

if __FILE__==$0
  if ($*.length < 1)
    print_help
    exit
  end
  
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
    
  images_folders.each do |path|
    process_folder path, do_recurse, do_icons, do_thumbs
  end
  
end















