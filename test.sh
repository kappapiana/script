#!/usr/bin/env bash

dir=$(pwd)

for f in $dir/*
do
  cd $f
  dir=$(pwd)
  for f in $dir/*
  do
    cd $f
    l=$(pwd)
    echo "siamo ora in $l sotto"
    cd - &> /dev/null
  done
  l=$(pwd)
  echo "siamo ora in $l"
  cd - &> /dev/null
done
