# Anonymize Libreoffice files

Usage quite simple. It's a bash script. Just go to the directory where you want to change personal information to make them anonymized or pseudonymized.

Suppose you are the autorh, therefore

	Bob Geldoff

And you don't want to appear.

then:

	anonymize.sh [filename.odt] ["Bob Geldoff"] ["Suzie Qu"]

You will find the new filename in 

	_anonymized_filename.odt

Uncompressed files are put in `/tmp/libreoffice`.  Therefore if you go there and do a grep, you can verify if everything has disappeared, like

	grep -ci "geldoff" /tmp/libreoffice/* -R

to make sure everything has been changed. If not, change the name of the temporary file and repeat with the offending information.

**Note** all *three* variables are required. If you put only two, a warning is displayed 

