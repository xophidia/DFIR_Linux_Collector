#!/bin/bash

outputpath="$OUTPUT/Zeitgeist"
outfile="$outputpath/zeitgeist.json"
mkdir -p $outputpath

echo '{ "zeitgeist": [], "metadata": { "CaseNumber": "'$caseNumber'", "Description" : "'$desc'", "Username": "'$user'", "Hostname": "'$host'" } }' > $outfile

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    db="${X}/.local/share/zeitgeist/activity.sqlite"
    if [ -f "$db" ] && [ -s "$db" ]; then
        mkdir -p $outputpath$(echo $X | sed 's|/|_|g')
        data=$(./tools/sqlite3 --json "$db" \
            "SELECT datetime(timestamp/1000000,'unixepoch') AS date, subject_uri, interpretation \
             FROM event ORDER BY timestamp DESC LIMIT 200" 2>/dev/null)
        if [ -n "$data" ]; then
            tmp=$(jq ".zeitgeist += [{\"User\": \"${X}\", \"Data\": $data}]" $outfile) && echo -E $tmp > $outfile
        fi
    fi
done
