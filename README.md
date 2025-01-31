# Windows CMD script templates for digitisation worklfows.
This set of script templates and scripts are derived from workflows I have developed for the University Digitisation Center at The university of Melbourne.   They are designed to work as "drag and drop" scripts taking a single TIF file or a folder of TIF files as an input.  The primary goal of this project was to develop a complete post-processing pipeline for a folder of images including:
- creating a copy of the folder as a backup in case something goes wrong
- organising images into subfolders by filetype
- renaming files with new filenames derived from the folder name
- creating JPEG derivatives and thumbnails
- performing optical charater recognition with outputs of a linearised multi-page PDF and text file, and per-image text, alto XML and hOCR files
- embedding metadata from a metadata sidecar file (a separate pproject to develop a tool to create this XMP file is in the early stages of development) into all image formats.
- collecting EXIF metadata from all files
- creating checksums of all files

## Installation
1. Install 3rd party utilies (see our blog page ["Command line tools for digitisation"](https://blogs.unimelb.edu.au/digitisation-lab/command-line-tools-for-digitisation/) for now).
2. Edit the xxx_header.txt files in the "templates" folder with the application and folder paths for your environment, creating additional folders if required.
3. Run make.bat to compile the CMD scripts into the "cmd" folder
4. \[Optional\] Move the CMD files to your preferred location

Sample image/xmp files for testing can be downloaded from [https://files.digitisation.unimelb.edu.au/github/windows-cmd/](https://files.digitisation.unimelb.edu.au/github/windows-cmd/)

## Usage
Drag a folder of TIF images onto a script or call the script with the target folder path as an argument.

Additional documentation will be prepared as the project progresses but for now it's assumed that you have some basic knowledge of CMD scripts.
