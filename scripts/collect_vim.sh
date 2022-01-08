#!/bin/bash


for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    if [ -s "${X}/.viminfo" ]; then
	    mkdir -p $OUTPUT/Vim${X}
    	    cp ${X}/.viminfo $OUTPUT/Vim${X}/viminfo
    fi
done
