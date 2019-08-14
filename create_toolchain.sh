#/bin/bash!

wget https://github.com/lierdakil/pandoc-crossref/releases/download/v0.3.4.1a/linux-pandoc_2_7_3.tar.gz

unzip linux-pandoc_2_7_3.tar.gz

sudo mv pandoc-crossref /usr/local/bin

sudo apt update

sudo apt install python-pip python3-pip

sudo pip install include-pandoc && sudo include-pandoc

apm install alpianon/atom-inline-git-diff

sudo pip3 install pandoc-inline-headers

sudo pip3 install pandoc-mustache
