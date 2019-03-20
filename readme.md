# Quick and Dirty Anonymize Libreoffice files

Usage is quite simple. It's a dull bash script. Just go to the directory where you want to change personal information to make them anonymized or pseudonymized. Obviously it also works with .docx files, provided that they are converted in ODF. Perhaps it also works natively, but I don't dare testing them just yet. OOXML sucks.

## Requirements

- Libreoffice/Openoffice.org or something that uses ODF as working file format:
- Linux
- Bash (just because it's what I use)
- sed and zip/unzip

## HOWTO

Suppose you are the author, but you don't want to appear as such, or there are many authors and you want them to come up as one, under an arbitrary name.

then:

	anonymize.sh [filename.odt]

Where `filename.odt` is the file that you want to change. You will be asked if you want to just change one name into another, or all names in one single run. Then it will ask you to insert the name to be changed (in the first case) and the name the author(s) shall be changed into.

You will find the modified file in

	_anonymized_filename.odt

Uncompressed files are put in `/tmp/libreoffice`.  Therefore if you do a `grep`, you can verify if everything has disappeared, like:

	grep -ci "[oldname]" /tmp/libreoffice/* -R

to make sure everything has been changed. If there is any occurrence (perhaps you have used uncapitalized names, or trailing spaces, whatever), the number beside the filename is different from 0. Otherwise you should get:

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
