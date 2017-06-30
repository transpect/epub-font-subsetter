# epub-font-subsetter

This pipeline can be used as a frontend project to create subsets of embedded fonts from a EPUB file. It uses the font tools python libary https://github.com/fonttools/fonttools

Clone the project with:
`git clone https://github.com/transpect/epub-font-subsetter --recursive`

Usage: 

`~/epub-font-subsetter
$ calabash/calabash.sh  xpl/epub-fontsubset.xpl epubfile=path/to/my_epub.epub`
Important: Choose your cwd like mentioned above. This pipeline uses an p:exec step to call a bash script, that calls the pyftsubset python script, and unfortunatly choosing the correct cwd is kind of tricky.


The pipeline creates a charset with all used characters for each embedded font and will create a subset called `"myfont.otf.subset"`
NEW: The main output of this pipeline is an EPUB file with all subsetted fonts embedded, called `subset_my_epub.epub`. By using the option `delete-not-used-font='true'` the embedded but not used fonts (no character with this font can be found in the epub) will be deleted.
`$ calabash/calabash.sh  xpl/epub-fontsubset.xpl epubfile=path/to/my_epub.epub delete-not-used-font=false`
