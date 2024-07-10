#!/bin/bash

if [ "${1}" == "" ]; then
  echo "provide a sequence number."
  exit 1
fi

fileExtension="-$(date +%Y-%m-%d)_$1.xlsx"
echo "fe=${fileExtension}"


if [ -f ~/Downloads/UnitProgressExport.xlsx ]; then
  mv ~/Downloads/UnitProgressExport.xlsx ./UnitProgressExport${fileExtension}
fi
if [ -f ~/Downloads/UnitProgressCamper.xlsx ]; then
  mv ~/Downloads/UnitProgressCamper.xlsx ./UnitProgressCamper${fileExtension}
fi
if [ -f ~/Downloads/UnitProgressBadge.xlsx ]; then
  mv ~/Downloads/UnitProgressBadge.xlsx UnitProgressBadge${fileExtension}
fi
