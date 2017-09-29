#!/usr/bin/env bash

export PATH=~/.local/bin/:$PATH

mkdir ./latex
mkdir ./latex/all
rm -rf ./latex/all

sphinx-build -b latex ./source ./latex/all && cd ./latex/all

pdflatex Arenadata.tex
makeindex Arenadata.idx
pdflatex Arenadata.tex
