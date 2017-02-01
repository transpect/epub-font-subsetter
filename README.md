# epub-font-subsetter

This pipeline can be used as a frontend project to create subsets of embedded fonts from a EPUB file. It uses the font tools python libary https://github.com/fonttools/fonttools

`git clone https://github.com/transpect/epub-font-subsetter --recursive`

Usage: 

`$ ../calabash/calabash.sh epub-fontsubset.xpl epubfile=path/to/your/epub.epub`


The pipeline creates a charset with all used characters for each embedded font and will create a subset called `"myfont.otf.subset.otf"`
