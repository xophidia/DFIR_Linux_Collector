#!/bin/bash

outputpath="$OUTPUT/FileZilla"
outfile="$outputpath/servers.json"
mkdir -p $outputpath

echo '{ "filezilla_servers": [], "metadata": { "CaseNumber": "'$caseNumber'", "Description" : "'$desc'", "Username": "'$user'", "Hostname": "'$host'" } }' > $outfile

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    config="${X}/.config/filezilla"
    if [ -d "$config" ]; then
        userpath=$outputpath$(echo $X | sed 's|/|_|g')
        mkdir -p $userpath

        for f in sitemanager.xml recentservers.xml filezilla.xml queue.sqlite; do
            if [ -f "${config}/${f}" ]; then
                cp "${config}/${f}" "$userpath/" 2>/dev/null
            fi
        done

        if [ -f "${config}/sitemanager.xml" ]; then
            hosts=$(grep -oP '(?<=<Host>).*?(?=</Host>)' "${config}/sitemanager.xml" 2>/dev/null | head -50)
            while IFS= read -r host; do
                [ -n "$host" ] && tmp=$(jq ".filezilla_servers += [{\"User\": \"${X}\", \"Host\": \"$host\"}]" $outfile) && echo -E $tmp > $outfile
            done <<< "$hosts"
        fi
    fi
done
