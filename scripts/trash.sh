#!/bin/bash


# Trash 

outputpath="$OUTPUT/Trash"
outfile=$outputpath/trash_files.json
mkdir -p $outputpath
echo "{\"Trash files\": [" >> $outfile

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    if [ -d "${X}/.local/share/Trash" ]; then
        trash_files=$(find ${X}/.local/share/Trash/info/*.trashinfo)
        if [[ -n $trash_files ]]; then
            mkdir -p $outputpath${X}
	    for file in $trash_files; do
                # Get trash file
	        cp $file $outputpath${X}
            
                # Export file to json
	        file_path=$(more $file | grep "Path" | cut -f2 -d "=")
	        deletion_date=$(more $file | grep "DeletionDate" | cut -f2 -d "=")
	        echo "{\"Path\": \"$file_path\"," >> $outfile
	        echo "\"Deletion Date\": \"$deletion_date\" },">> $outfile
	    done
        fi
    fi
done
tmp_trash=$(sed '$ s/.$//' $outfile)
echo "$tmp_trash],\"Metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $outfile
    

# Frequent App Data

outputpath="$OUTPUT/frequent_app.json"

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    if [ -f "${X}/.local/share/gnome-shell/application_state" ]; then
	    more "${X}/.local/share/gnome-shell/application_state" 
    fi
done



        
    
