#!/usr/bin/ruby

require "rubygems"
require "pdf/writer"
require "RMagick"
require "mini_exiftool"



# Settings
CONTACTSHEET_FILENAME = "Contactsheet.pdf" # relative to the script location
ACCEPTED_IMAGE_EXTENSIONS = "jpg jpeg png".split(" ").map {|ext| ".%s" % ext}
COLS = 8
ROWS = 14

# Tabloid
CANVAS_W_CM = 27.94
CANVAS_H_CM = 43.18

# Text
FONT = "Helvetica"
FONT_SIZE = 6
FONT_COLOR = Color::RGB::Gray
BORDER_COLOR = Color::RGB.from_html("666")
BACKGROUND_COLOR = Color::RGB::Black




def print_help
  puts "Usage:"
  puts "-b draw background"
  puts "ruby %s [-b] folder_path [folder_path]" % __FILE__
end





class ContactSheet

  def initialize cols=COLS, rows=ROWS, 
        width=CANVAS_W_CM, height=CANVAS_H_CM,
        margin=1, gutter=0.1
    
    @cols = cols
    @rows = rows
    
    @page_w = PDF::Writer.cm2pts(width)
    @page_h = PDF::Writer.cm2pts(height)
    
    @margin = PDF::Writer.cm2pts(margin)
    @canvas_w = @page_w - @margin*2
    @canvas_h = @page_h - @margin*2
    
    @gutter = PDF::Writer.cm2pts(gutter)
    @cell_w = (@canvas_w / @cols)
    @cell_h = (@canvas_h / @rows)
    @max_image_w = @cell_w - @gutter*2
    @max_image_h = @cell_h - @gutter*2 - FONT_SIZE
    
    @image_counter = 0
    
    @pdf = PDF::Writer.new(:paper => [width, height], :orientation => :portrait)
    paint_background() if $draw_background
    set_font();
    @pdf.stroke_color BORDER_COLOR
  end
  
  def set_font
    @pdf.fill_color FONT_COLOR
    @pdf.select_font(FONT)
    @pdf.font_size = FONT_SIZE
  end
  
  def point_background
    @pdf.fill_color BACKGROUND_COLOR
    @pdf.rectangle(0, 0, @page_w, @page_h).fill
  end
  
  def process path
    files = Dir.entries(path)
    image_files = files.select { |file| is_image(file) }
    image_files.map! do |img| 
      File.join(path, img)
    end
    image_files.each do |img|
      add_image img
    end
    if $do_recurse
      dirs = files.select { |f| is_dir(File.join(path,f)) }
      dirs.each do |dir|
        process File.join(path,f)
      end
    end
  end
  
  def is_image path
    ACCEPTED_IMAGE_EXTENSIONS.each do |ext|
      return true if path.downcase.include?(ext)
    end
    false
  end
  
  def is_dir path
    return false unless File.directory?(path)
    IGNORE_FOLDERS.each do |ignore|
      return false if path.include?(ignore)
    end
    true
  end
  
  def add_images image_list
    image_list.each do |img|
      add_image img
    end
  end
  
  def add_image path
    
    if (@image_counter>=(@cols*@rows))
      @pdf.start_new_page
      @image_counter = 0
      paint_background() if $draw_background
      set_font()
      @pdf.stroke_color Color::RGB::Gray
    end
    
    pos_x = @margin + (@image_counter % @cols) * @cell_w
    pos_y = @margin + @canvas_h - @cell_h - (@image_counter / @cols).floor * @cell_h
    
    info  = MiniExiftool.new(path)
    img_w = info["ImageWidth"]
    img_h = info["ImageHeight"]
    
    @pdf.translate_axis(pos_x, pos_y)
    #@pdf.rectangle(0,0,@cell_w,@cell_h).stroke # draw cell
    @pdf.add_text_wrap(0, FONT_SIZE/2, @cell_w, File.basename(path), 6, :center, 0, false)
  
    if (img_w>=img_h)
      w_ratio = @max_image_w / img_w
      h_ratio = @max_image_h / img_h
      ratio = (w_ratio<=h_ratio) ? w_ratio : h_ratio
      
      x_offset = (@cell_w - ratio * img_w) / 2
      y_offset = @gutter + FONT_SIZE #(@cell_h - ratio * img_h) - @gutter
      image = @pdf.add_image_from_file(path, x_offset, y_offset, img_w * ratio)
      @pdf.rectangle(x_offset, y_offset, img_w * ratio, img_h * ratio).stroke
    else
      @pdf.rotate_axis(90)
      w_ratio = @max_image_w / img_h
      h_ratio = @max_image_h / img_w
      ratio = (w_ratio<=h_ratio) ? w_ratio : h_ratio
      
      x_offset = @gutter + FONT_SIZE #(@cell_h - ratio * img_w) - @gutter
      y_offset = (@cell_w - ratio * img_h) / 2
      image = @pdf.add_image_from_file(path, x_offset, y_offset-@cell_w, img_w * ratio)
      @pdf.rectangle(x_offset, y_offset-@cell_w, img_w * ratio, img_h * ratio).stroke
      @pdf.rotate_axis(-90)
    end
    
    @image_counter += 1
    @pdf.translate_axis(-pos_x, -pos_y)
  end
  
  def save_pdf
    @pdf.save_as(CONTACTSHEET_FILENAME)
    exec "open %s" % CONTACTSHEET_FILENAME
  end
  
  def to_s
    "Contactsheet Object"
  end
  
end













if __FILE__==$0
  images_folders = []
  $draw_background = false
  
  $*.each do |arg|
    if (arg[0,1]=="-")
      case arg
      when "-b" then $draw_background = true
      end
    elsif arg.is_a?(String) && !arg.strip.empty?
      images_folders.push arg
    end
  end
  
  if (images_folders.length<1) 
    print_help()
    exit
  end
  
  contact_sheet = ContactSheet.new
  images_folders.each do |image_folder|
    if File.directory?(image_folder) then
      puts "Processing %s" % image_folder
      contact_sheet.process image_folder
    else
      puts "Not a folder: %s" % image_folder
    end
  end
  contact_sheet.save_pdf
  
end















