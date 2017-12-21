# Anonymize Libreoffice files

Usage is quite simple. It's a bash script. Just go to the directory where you want to change personal information to make them anonymized or pseudonymized. Obviously it also works with .docx files, provided that they are converted in ODF. Perhaps it also works natively, but I don't dare testing them just yet. OOXML sucks.

## Requirements

- Libreoffice/Openoffice.org or something that uses ODF as working file format:
- Linux 
- Bash (just because it's what I use)
- sed and zip/unzip

Suppose you are the autorh, therefore

	Bob Geldoff

And you don't want to appear.

then:

	anonymize.sh [filename.odt] ["Bob Geldoff"] ["Suzie Qu"]

Where `filename.odt` is the file that you want to change; `Bob Geldoff` is your name and `Suzie Qu` is the name that you want to appear. You will find the modified file in 

	_anonymized_filename.odt

Uncompressed files are put in `/tmp/libreoffice`.  Therefore if you do a `grep`, you can verify if everything has disappeared, like:

	grep -ci "geldoff" /tmp/libreoffice/* -R

to make sure everything has been changed. If there is any occurence (perhaps you have used uncapitalized names, or trailing spaces, whatever), the number beside the filename is different from 0. Otherwise you should get:

	content.xml:0
	layout-cache:0
	manifest.rdf:0
	META-INF/manifest.xml:0
	meta.xml:0
	mimetype:0
	settings.xml:0
	styles.xml:0
	Thumbnails/thumbnail.png:0

If not, change the name of the temporary file and repeat with the offending information. Repeat until everything is in good order.

**Note** all *three* variables are required. If you put only two, a warning is displayed 

