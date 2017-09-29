#!/usr/bin/env bash

export PATH=~/.local/bin/:$PATH
mkdir ../latex

for dir in `ls -d */`; do
    if [ ${dir} != "imgs/" ] && [ ${dir} != "_static/" ]
    then
    
        echo ${dir}
        cp ./conf.py ./${dir}
        
        mkdir ../latex/${dir}
        rm -rf ../latex/${dir}
        sphinx-build -b latex ./${dir} ../latex/${dir} && cd ../latex/${dir}
        
        pdflatex Arenadata.tex
        makeindex Arenadata.idx
        pdflatex Arenadata.tex
        
        cd ../../source
        rm ./${dir}/conf.py
    fi
done
