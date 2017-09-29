#!/usr/bin/env bash

export PATH=~/.local/bin/:$PATH
mkdir ../html

for dir in `ls -d */`; do
    if [ ${dir} != "imgs/" ] && [ ${dir} != "_static/" ]
    then

        echo ${dir}
        cp ./conf.py ./${dir}
        cp -r ./_static/ ./${dir}

        mkdir ../html/${dir}
        rm -rf ../html/${dir}
        
        sphinx-build -b html ./${dir} ../html/${dir} && cd ../html/${dir}

        cd ../../source
        rm ./${dir}conf.py
        rm -rf ./${dir}_static
    fi
done
