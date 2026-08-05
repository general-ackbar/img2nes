#!/bin/zsh
mkdir data
for f in *.png; do ~/Downloads/img2nes -i $f -d -m 4 ;done;
for f in *.pal; do cat $f >> data/colors.pal; done;
for f in *.nmt; do cat $f >> data/frames.nmt; done;
for f in *.chr; do cat $f >> data/data.chr; done;
rm *.chr;
rm *.pal;
rm *.nmt;
rm *.asm
echo "Done"
