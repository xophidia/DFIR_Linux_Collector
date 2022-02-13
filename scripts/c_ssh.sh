#!/bin/bash

outputpath="$OUTPUT/Ssh"
outfile="$outputpath/ssh_config.json"

mkdir $outputpath

echo '{ "ssh": [],"metadata": { "CaseNumber": "'$caseNumber'", "Description" : "'$desc'", "Username": "'$user'", "Hostname": "'$host'"}}' > $outfile

COUNTER=0

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq);
do
    if [ -s "${X}/.ssh/authorized_keys" ]; then
	mkdir -p $outputpath${X}
        cp ${X}/.ssh/authorized_keys $outputpath${X}/authorized_keys
	tmp=$(jq  '.ssh += [{"File": "'${X}'/.ssh/authorized_keys","authorized_keys" : []}]' $outfile) && echo $tmp > $outfile
	while read line
        do
            if [ ! -z "$line" ]; then
                tmp=$(jq --arg line "$line" '.ssh['${COUNTER}'].authorized_keys += [$line]' $outfile) && echo -E $tmp > $outfile
            fi
        done < $outputpath$X/authorized_keys
	((COUNTER++))
    fi
    if [ -s "${X}/.ssh/known_hosts" ]; then
	mkdir -p $outputpath${X}
        cp ${X}/.ssh/known_hosts $outputpath${X}/known_hosts
	tmp=$(jq  '.ssh += [{"File": "'${X}'/.ssh/known_hosts","known_hosts" : []}]' $outfile) && echo $tmp > $outfile
	while read line
        do
            if [ ! -z "$line" ]; then
                tmp=$(jq --arg line "$line" '.ssh['${COUNTER}'].known_hosts += [$line]' $outfile) && echo -E $tmp > $outfile
	    fi
        done < $outputpath$X/known_hosts
	((COUNTER++))

    fi
done
