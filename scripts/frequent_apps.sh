#!/bin/bash

# Frequent App Data

outfile="$OUTPUT/frequent_app.json"
echo "{\"frequent apps\": [" >> $outfile
for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    # GNOME Desktop

    if [ -f "${X}/.local/share/gnome-shell/application_state" ]; then
	    echo "{\"User\": \"${X}\", \"apps\": [" >> $outfile
            while read line 
            do
            if [[ "$line" == *"application id"* ]]; then
		    app=$(echo $line | awk -F' ' '{print $2}'| cut -d"=" -f2)
		    score=$(echo $line | awk -F' ' '{print $3}' | cut -d"=" -f2)
		    last_seen=$(echo $line | awk -F' ' '{print $4}'| cut -d"=" -f2 | cut -d"\"" -f2)
		    last_executed_date=$(date -d @$last_seen)
		    echo "{\"app\": $app, \"score\" : $score, \"last executed\": \"$last_executed_date\"}," >> $outfile
	    fi
	    
            done < "${X}/.local/share/gnome-shell/application_state"
	    # Delete last comma
	    tmp=$(sed '$ s/.$//' $outfile)
            echo $tmp > $outfile
	    echo "]}," >> $outfile
    fi
done
tmp=$(sed '$ s/.$//' $outfile)
echo "$tmp],\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $outfile
