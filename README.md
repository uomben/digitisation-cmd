# Windows CMD script templates for digitisation worklfows.
This set of script templates and scripts are derived from workflows I have developed for the University Digitisation Center at The university of Melbourne.   They are designed to work as "drag and drop" scripts taking an image file or a folder of images as an input.  The primary goal of this project was to develop a complete post-processing pipeline for a folder of images including:
- organising images into subfolders by filetype
- renaming files with new filenames derived from the folder name
- performing optical charater recognition with outputs of a linearised multi-page PDF and text file, and per-image text, alto XML and hOCR files
- embedding metadata from a metadata sidecar file (a separate pproject to develop a tool to create this XMP file is in the early stages of development) into all image formats.
- collecting EXIF metadata from all files
- creating checksums of all files
