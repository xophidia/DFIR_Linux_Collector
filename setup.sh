#!/bin/bash

unzip busybox-1_34_1.zip 2>/dev/null
if [ "$?" -eq 127 ]; then
  echo "unzip is not found, exiting!"
  exit 0
fi
chmod -Rf +x makeself-2.4.5/
sudo make
