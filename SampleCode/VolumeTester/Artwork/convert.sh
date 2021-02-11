#!/bin/sh

# Rename Illustrator files app_*.png to just *.png
find . -name app_\*.png -exec echo {} \; \
    | awk -F_ '{ print "mv "$0" "$2; }' \
    | sh

