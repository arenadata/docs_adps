#!/usr/bin/env bash

export PATH=~/.local/bin/:$PATH

mkdir ./latex
mkdir ./pdf
#mkdir ./latex/all
#rm -rf ./latex/all
#
#sphinx-build -b latex ./source ./latex/all && cd ./latex/all
#
#pdflatex Arenadata.tex
#makeindex Arenadata.idx
#pdflatex Arenadata.tex
#
#cd ../..

for dir in `find source -maxdepth 1 -type d -printf "%P\n"`; do
    if [ ${dir} != "imgs" ] && [ ${dir} != "_static" ]  && [ ${dir} != "_templates" ]
    then
        echo ${dir}
        cp ./source/conf.py ./source/${dir}
        
        mkdir ./latex/${dir}
        rm -rf ./latex/${dir}
        sphinx-build -b latex ./source/${dir} ./latex/${dir} && cd ./latex/${dir}
        
        pdflatex Arenadata.tex
        makeindex Arenadata.idx
        pdflatex Arenadata.tex
        
        mv Arenadata.pdf ../../pdf/ADH_${dir}.pdf
        
        cd ../..
        rm ./source/${dir}/conf.py
    fi
done
