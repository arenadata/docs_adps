#!/usr/bin/env bash

rm -rf ./latex && mkdir ./latex &&

export PATH=~/.local/bin/:$PATH
sphinx-build -b latex ./source/ ./latex/ && cd ./latex/

pdflatex Arenadata.tex
makeindex Arenadata.idx
pdflatex Arenadata.tex
