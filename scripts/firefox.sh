#!/bin/bash

#########################
#   Firefox artefacts   #
#########################

#search Account with Firefox Profile
homepaths=$(find /home -name firefox | cut -d"." -f1 | uniq)
firefoxfiles=( "addons.json" "containers.json" "times.json" "handlers.json" "extensions.json" )
if [[ -n $homepaths ]]; then
	for homepath in $homepaths; do
	
		username=$(echo $homepath | cut -d"/" -f3)
		#output_path="OUTPUT/Browser/${username}/Firefox"
		output_path="${OUTPUT}/Browser/${username}/Firefox"
		for file in "${firefoxfiles[@]}"; do
			mkdir -p $output_path && find $homepath -type f -name "$file" -exec cp {} "$output_path" \;

		done

		#Search for places.sqlite file
		filepath=$(find $homepath -name places.sqlite)
	
		#If Sqlite files exists
		if [[ -n $filepath ]]; then
		
	# History

			gethistory=$(./tools/sqlite3 --json ${filepath} "SELECT datetime(moz_historyvisits.visit_date/1000000,'unixepoch') AS Date, moz_places.url AS URL, moz_places.title AS Title FROM moz_places, moz_historyvisits WHERE moz_places.id = moz_historyvisits.place_id")
			if [[ -n $gethistory ]]; then
				echo "{\"Firefox History\": " >> $output_path/history.json
				echo "{\"File\": \"$filepath\", \"Data\": $gethistory}," >> $output_path/history.json
				tmp_history=$(sed '$ s/.$//' $output_path/history.json)
				echo "$tmp_history,\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/history.json
			fi
	# Downloads

			getdownloads=$(./tools/sqlite3 --json ${filepath} "SELECT datetime(lastModified/1000000,'unixepoch') AS Date, content as File, url as URL FROM moz_places, moz_annos WHERE moz_places.id = moz_annos.place_id;")
			if [[ -n $getdownloads ]]; then
				echo "{\"Firefox Downloads\": " >> $output_path/downloads.json
				echo "{\"File\": \"$filepath\", \"Data\": $getdownloads}," >> $output_path/downloads.json
				tmp_downloads=$(sed '$ s/.$//' $output_path/downloads.json)
				echo "$tmp_downloads,\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/downloads.json
			fi
		fi
	#Cookies
		filepath=$(find $homepath -name cookies.sqlite)
		if [[ -n $filepath ]]; then
			getcookies=$(./tools/sqlite3 --json ${filepath} "SELECT datetime(lastAccessed/1000000,'unixepoch') AS lastAccessed, datetime(creationTime/1000000,'unixepoch') AS creationTime, name,value,host,path,expiry,isSecure,isHttpOnly,inBrowserElement,sameSite,rawSameSite schemeMap from moz_cookies;")
			if [[ -n $getcookies ]]; then
				echo "{\"Firefox Cookies\": " >> $output_path/cookies.json
				echo "{\"File\": \"$filepath\", \"Data\": $getcookies}," >> $output_path/cookies.json
				tmp_cookies=$(sed '$ s/.$//' $output_path/cookies.json)
	        		echo "$tmp_cookies,\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/cookies.json
			fi
		fi

	#Form History
		filepath=$(find $homepath -name formhistory.sqlite)
		if [[ -n $filepath ]]; then
			gettables=$(./tools/sqlite3 --json ${filepath} .tables)
			#if [[ echo "$gettables" |grep "moz_sources" ]]; then
			if grep -sq 'moz_sources' <<< "$gettables"; then
				getformhistory=$(./tools/sqlite3 --json ${filepath} "Select fieldname,value,history_id,source,datetime(firstUsed/1000000,'unixepoch','localtime' ) as 'firstUsed',datetime(lastUsed/1000000,'unixepoch','localtime' ) as 'lastUsed',timesUsed,guid from moz_sources LEFT JOIN moz_history_to_sources ON moz_history_to_sources.source_id = moz_sources.id LEFT JOIN moz_formhistory ON moz_history_to_sources.history_id = moz_formhistory.id;")
			else
				getformhistory=$(./tools/sqlite3 --json ${filepath} "Select fieldname,value,datetime(firstUsed/1000000,'unixepoch','localtime' ) as 'firstUsed',datetime(lastUsed/1000000,'unixepoch','localtime' ) as 'lastUsed',timesUsed,guid from moz_formhistory;")
			fi
			if [[ -n $getformhistory ]]; then
		        	echo "{\"Firefox FormHistory\": " >> $output_path/formhistory.json
				echo "{\"File\": \"$filepath\", \"Data\": $getformhistory}," >> $output_path/formhistory.json
				tmp_formhistory=$(sed '$ s/.$//' $output_path/formhistory.json)
        			echo "$tmp_formhistory,\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/formhistory.json
			fi
		fi
	
	#Permissions
		filepath=$(find $homepath -name permissions.sqlite)
		if [[ -n $filepath ]]; then
			getpermissions=$(./tools/sqlite3 --json ${filepath} "Select origin,type,permission,expireType,dateTime(expireTime/1000000,'unixepoch','localtime') as 'Last' from moz_perms")
			if [[ -n $getpermissions ]]; then
        			echo "{\"Firefox Permissions\": " >> $output_path/permissions.json
				echo "{\"File\": \"$filepath\", \"Data\": $getpermissions}," >> $output_path/permissions.json
				tmp_permissions=$(sed '$ s/.$//' $output_path/permissions.json)
        			echo "$tmp_permissions,\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/permissions.json
			fi
		fi


	#WebAppStore
		filepath=$(find $homepath -name webappsstore.sqlite)
		if [[ -n $filepath ]]; then
			getwebappsstore=$(./tools/sqlite3 --json ${filepath} "Select * from webappsstore2")
			if [[ -n $getpermissions ]]; then
		        	echo "{\"Firefox Webappsstore\": " >>  $output_path/webappsstore.json
				echo "{\"File\": \"$filepath\", \"Data\": $getwebappsstore}," >> $output_path/webappsstore.json
				tmp_webappsstore=$(sed '$ s/.$//' $output_path/webappsstore.json)
	        		echo "$tmp_webappsstore,\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/webappsstore.json
			fi
		fi
	done
fi

