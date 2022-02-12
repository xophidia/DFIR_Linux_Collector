#!/bin/bash

outputpath="$OUTPUT/History"
outfile="$outputpath/commands_history.json"
historyfiles=( ".bash_history" ".zsh_history")
mkdir $outputpath

echo '{ "command_history": [],"metadata": { "CaseNumber": "'$caseNumber'", "Description" : "'$desc'", "Username": "'$user'", "Hostname": "'$host'"}}' > $outfile

COUNTER=0
for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq);
do
    #bash_history
    if [ -s "${X}/.bash_history" ] ; then
	mkdir -p $outputpath${X}
        cp ${X}/.bash_history $outputpath${X}/bash_history
	tmp=$(jq  '.command_history += [{"File": "'${X}'/.bash_history","Commands" : []}]' $outfile) && echo $tmp > $outfile
	
	while read line
        do
            if [ ! -z "$line" ]; then
		    tmp=$(jq --arg counter $COUNTER --arg line "$line" '.command_history['$counter'].Commands += [$line]' $outfile) && echo -E $tmp > $outfile
		    #cmd=$($line | sed 's/[^[:print:]]//g;s/\\/\\\\/g;s/\"/\\"/g')
	            #echo \"${line//\"/\\\"}\",
                fi
        done < $outputpath$X/bash_history
	
	((COUNTER++))
    fi
done

	

        #Delete non printable caracters, escape special caracters
        #sed 's/[^[:print:]]//g' $outputpath$X/bash_history > $outputpath$X/tmp_bash_history
	
	#while read line
        #do
        #    if [ ! -z "$line" ]; then
        #        #echo $line
#		cmd=$($line | sed 's/[^[:print:]]//g;s/\\/\\\\/g;s/\"/\\"/g')
#                #echo $cmd
#                echo \"${line//\"/\\\"}\",
#                echo "===="
#                fi
#        done < $outputpath$X/tmp_bash_history


	
	#tmp_history=$(sed '$ s/.$//' $outfile)
	#echo $tmp_history > $outfile
	#echo "]}," >> $outfile
	#rm -f $outputpath$X/tmp_bash_history
    #fi
#done
