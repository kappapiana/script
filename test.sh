#!/usr/bin/env bash

dir=$(pwd)

for f in $dir/*
do
  cd $f
  dir=$(pwd)
  for f in $dir/*
  do
  echo "dir è $dir"
    cd $f
    echo "siamo ora in $f sotto"
    for i in $f
    do
      cd $i
      sa=$(pwd)
      echo "eccoci $sa"
    done
    cd - &> /dev/null
  done
  l=$(pwd)
  echo "siamo ora in $l"
  cd - &> /dev/null
done
