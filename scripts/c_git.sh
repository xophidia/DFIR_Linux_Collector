#!/bin/bash

outputpath="$OUTPUT/Git"
outfile="$outputpath/git.json"

mkdir $outputpath

echo '{ "gitconfig": [],"metadata": { "CaseNumber": "'$caseNumber'", "Description" : "'$desc'", "Username": "'$user'", "Hostname": "'$host'"}}' > $outfile

COUNTER=0

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq);
do
    if [ -s "${X}/.gitconfig" ]; then
	mkdir -p $outputpath${X}
        cp ${X}/.gitconfig $outputpath${X}/gitconfig
	tmp=$(jq  '.gitconfig += [{"File": "'${X}'/.gitconfig","data" : []}]' $outfile) && echo $tmp > $outfile
	
	while read line
        do
            if [ ! -z "$line" ]; then
                tmp=$(jq --arg counter $COUNTER --arg line "$line" '.gitconfig['$counter'].data += [$line]' $outfile) && echo -E $tmp > $outfile
            fi
        done < $outputpath$X/gitconfig
	
	((COUNTER++))
    fi
done

