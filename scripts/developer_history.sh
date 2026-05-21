#!/bin/bash

outputpath="$OUTPUT/DeveloperHistory"
outfile="$outputpath/developer_history.json"
mkdir -p $outputpath

echo '{ "developer_history": [], "metadata": { "CaseNumber": "'$caseNumber'", "Description" : "'$desc'", "Username": "'$user'", "Hostname": "'$host'" } }' > $outfile

history_files=(".mysql_history" ".psql_history" ".sqlite_history" ".nano_history" ".lesshst" ".wget-hsts" ".bashrc" ".bash_profile" ".profile")

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    userpath=$outputpath$(echo $X | sed 's|/|_|g')
    mkdir -p $userpath

    for hf in "${history_files[@]}"; do
        src="${X}/${hf}"
        if [ -f "$src" ] && [ -s "$src" ]; then
            cp "$src" "$userpath/${hf#.}" 2>/dev/null
            tmp=$(jq ".developer_history += [{\"User\": \"${X}\", \"File\": \"${hf}\"}]" $outfile) && echo -E $tmp > $outfile
        fi
    done
done
