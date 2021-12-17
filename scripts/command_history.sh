#!/bin/bash

outfile="$OUTPUT/commands_history.json"
#outfile="commands_history.json"
historyfiles=( ".bash_history" ".zsh_history")
echo "{\"Command History\":[ " >> $outfile
for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    if [ -s "${X}/.bash_history" ] ; then
	    echo "{\"File\": \"$X/.bash_history\"," >> $outfile
	    echo "\"Commands\" : [" >> $outfile
	    while read line 
	    do
		if [ ! -z "$line" ]; then
	 		echo \"${line//\"/\\\"}\", >> $outfile
		fi
	    done < ${X}/.bash_history
	    tmp_history=$(sed '$ s/.$//' $outfile)
	    echo $tmp_history > $outfile
	    echo "]}," >> $outfile
    fi
    if [ -s "${X}/.zsh_history" ]; then
	    echo "{\"File\": \"$X/.zsh_history\"," >> $outfile
	    echo "\"Commands\" : [" >> $outfile
	    while read line 
	    do
		if [ ! -z "$line" ]; then
	 		echo \"${line//\"/\\\"}\", >> $outfile
		fi
	    done < ${X}/.zsh_history
	    tmp_history=$(sed '$ s/.$//' $outfile)
	    echo $tmp_history > $outfile
	    echo "]}," >> $outfile
    fi
done
        echo "{\"Metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}]}" >> $outfile
