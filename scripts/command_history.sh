#!/bin/bash

outputpath="$OUTPUT/History"
outfile="$outputpath/commands_history.json"
historyfiles=( ".bash_history" ".zsh_history")
mkdir $outputpath

echo "{\"Command History\":[ " >> $outfile
for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    if [ -s "${X}/.bash_history" ] ; then
	mkdir -p $outputpath${X}
        cp ${X}/.bash_history $outputpath${X}/bash_history
	echo "{\"File\": \"$X/.bash_history\"," >> $outfile
	echo "\"Commands\" : [" >> $outfile
	#Delete non printable caracters
        sed "s/[^[:print:]]//g" $outputpath$X/bash_history > $outputpath$X/tmp_bash_history
	
	while read line 
	do
	    if [ ! -z "$line" ]; then
		echo \"${line//\"/\\\"}\", >> $outfile
		fi
	    done < $outputpath${X}/tmp_bash_history
	    tmp_history=$(sed '$ s/.$//' $outfile)
	    echo $tmp_history > $outfile
	    echo "]}," >> $outfile
	    rm -f $outputpath$X/tmp_bash_history
    fi
    if [ -s "${X}/.zsh_history" ]; then
	mkdir -p $outputpath${X}
        cp ${X}/.zsh_history $outputpath$X/zsh_history
	echo "{\"File\": \"$X/.zsh_history\"," >> $outfile
	echo "\"Commands\" : [" >> $outfile
	#Delete non printable caracters
        sed "s/[^[:print:]]//g" $outputpath$X/zsh_history > $outputpath$X/tmp_zsh_history
	while read line 
	do
	if [ ! -z "$line" ]; then
	    echo \"${line//\"/\\\"}\", >> $outfile
	fi
	done < ${X}/.zsh_history
	tmp_history=$(sed '$ s/.$//' $outfile)
	echo $tmp_history > $outfile
	echo "]}," >> $outfile
	rm -f $outputpath$X/tmp_zsh_history
    fi
done
        echo "{\"Metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}]}" >> $outfile

