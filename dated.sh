#!/usr/bin/env bash

# simple oneliner to convert random date in YYYY-MM-DD hh:mm

date -d "$1" +"%Y-%m-%d %T %Z"
