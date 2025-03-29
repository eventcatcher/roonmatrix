#!/bin/bash

read -p "Enter the filename for the screenshot: " filename

mkdir -p f_screenshots

# Set default filename as "screenshot" if filename is empty
if [[ -z $filename ]]; then
  filename="screenshot.png"
fi

# Add ".png" to filename if it is not already added
if [[ $filename != *".png" ]]; then
  filename="$filename.png"
fi

counter=1
new_filename="$filename"
while [[ -e "f_screenshots/$new_filename" ]]; do
  counter=$((counter + 1))
  new_filename="${filename%.*}_$counter.${filename##*.}"
done

fvm flutter screenshot -o "f_screenshots/$new_filename"
echo "Screenshot saved to f_screenshots/$new_filename"
