#!/usr/bin/env bash

rm -rf ./html && mkdir ./html &&

export PATH=~/.local/bin/:$PATH
sphinx-build -b html ./source/ ./html/ && cd ./html/
