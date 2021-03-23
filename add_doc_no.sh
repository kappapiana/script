#!/usr/bin/env bash


# Creates a PDF with overlaying something on the first page
# REQUIRES pdftk
# usage: you create an overlay one-pager PDF (such as "document_no1.pdf")
# Then you pass the original document and this document as script variables

pdftkpath=$(command -v pdftk)

#checking if variables are all filled in

echo "+*******"
if [ "$2" = "" ]; then

	echo ""
	echo "|"
	echo "| missing variable (2 required)"
	echo "|"
	echo "| usage: [scriptname] [original filename] [overlay filename] "
	echo "|"
	echo "+******"
	echo ""

else

PAGES=$"$pdftkpath  $1 dump_data |grep NumberOfPages | awk '{print $2}'"

echo ""
echo "your document appears to be $PAGES pages long"
echo ""

$pdftkpath "$2".pdf multibackground "$1" output ~/temp.pdf

$pdftkpath A=~/temp.pdf B="$1" cat A1 B2-$PAGES output "$1_final".pdf

rm ~/temp.pdf

echo ""
echo "----"
echo ""
echo "$1_final.pdf successfully created"

fi
