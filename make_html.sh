#!/usr/bin/env bash

export PATH=~/.local/bin/:$PATH

mkdir ./html
mkdir ./html/all
rm -rf ./html/all

sphinx-build -b html ./source/ ./html/all
