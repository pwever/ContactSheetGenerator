# Contactsheet.rb

Simple ruby script to generate contact sheets of one or more folders with JPG and/or PNG files.

## Usage:

ruby ContactSheet.rb [-b] image_folder [image_folder2]

## Notes

* PDF currently only accepts JPG and PNG files.
* Full size images are being *embedded* in the PDF file. This can lead to very big files. Use the ThumbGenerator script to create thumbnails first.
* All folders will be collapsed into a single contact sheet.

## Dependencies

* pdf/writer (gem install pdf-writer)
* RMagick (gem install rmagick)
* mini_exiftool (gem install mini_exiftool)




# ThumbGenerator.rb

Simple ruby script to generate thumbnail for folder full of images.

## Usage

ruby ThumbGenerator.rb [-r -i -t] folder_path [folder_path]"

## Notes

* Thumbnail folders are created next to the input folders.
* You can specify multiple output sizes. See THUMB_SIZES.
* Thumbnails respect the original dimensions.
* Icons are square, with the image filling the entire square. See ICON_SIZE

## Dependencies

* RMagick (gem install rmagick)





# Todo

* Look into RAW image support.
* Handle combined options (ie -ri for recursive _and_ icon generate)



