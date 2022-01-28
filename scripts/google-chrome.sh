#!/bin/bash


##############################
#  CHROME/CHROMIUM ARTEFACTS
##############################

#search Account with Chrome Profile
browser="google-chrome"
homepaths=$(find /home \( -name "google-chrome" \)| awk -F"/" '{print "/"$2"/"$3"/"}'| uniq)

chromefiles=( "addons.json" "containers.json" )
if [[ -n $homepaths ]]; then
        for homepath in $homepaths; do
                username=$(echo $homepath | cut -d"/" -f3)
                #output_path="OUTPUT/Browser/${username}/Google-Chrome"
                output_path="${OUTPUT}/Browser/${username}/Google-Chrome"
                for file in "${chromefiles[@]}"; do
			mkdir -p $output_path && find $homepath -type f -name "$file" -exec cp {} "$output_path" \;
  
		done


		#HISTORY
                filepath=$(find $homepath -name History | grep $browser)
                #If Sqlite files exists
                if [[ -n $filepath ]]; then
			gethistory=$(./tools/sqlite3 --json ${filepath} "SELECT urls.url, urls.title, urls.visit_count, urls.typed_count, datetime(urls.last_visit_time/1e6-11644473600,'unixepoch','utc') AS lastvisit, urls.hidden, datetime(visits.visit_time/1e6-11644473600,'unixepoch','utc') AS visit_time , visits.from_visit, visits.transition FROM urls, visits WHERE urls.id = visits.url")
			if [[ -n $gethistory ]]; then
				echo "{\"Chrome History\": " >> $output_path/history.json
				echo "{\"File\": \"$filepath\", \"Data\": $gethistory}," >> $output_path/history.json
				tmp_history=$(sed '$ s/.$//' $output_path/history.json)
				echo "$tmp_history,\"metadata\": { \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/history.json
			fi

			getdownloads=$(./tools/sqlite3 --json ${filepath} "Select current_path, target_path, datetime(start_time/1e6-11644473600,'unixepoch','utc') AS start_time, received_bytes, total_bytes, state, danger_type, interrupt_reason, hash, datetime(end_time/1e6-11644473600,'unixepoch','utc') AS end_time, opened, datetime(last_access_time/1e6-11644473600,'unixepoch','utc') AS last_access_time, transient, referrer, site_url, tab_url, tab_referrer_url, http_method,by_ext_id, by_ext_name, etag, last_modified, mime_type, original_mime_type FROM downloads")
			if [[ -n $getdownloads ]]; then
				echo "{\"Chrome Downloads\": " >> $output_path/downloads.json
				echo "{\"File\": \"$filepath\", \"Data\": $getdownloads}," >> $output_path/downloads.json
				tmp_downloads=$(sed '$ s/.$//' $output_path/downloads.json)
				echo "$tmp_downloads,\"metadata\": { \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/downloads.json
			fi
		fi


		#Cookies
                filepath=$(find $homepath -name Cookies | grep $browser)
                #If Sqlite files exists
                if [[ -n $filepath ]]; then

			getcookies=$(./tools/sqlite3 --json ${filepath} "SELECT datetime(creation_utc/1e6-11644473600,'unixepoch','utc') AS creation_utc, host_key, top_frame_site_key, name, value, encrypted_value, path, datetime(expires_utc/1e6-11644473600,'unixepoch','utc') AS expires_utc, is_secure, is_httponly, datetime(last_access_utc/1e6-11644473600,'unixepoch','utc') AS last_access_utc, has_expires, is_persistent, priority, samesite, source_scheme, source_port, is_same_party FROM cookies")
			if [[ -n $getcookies ]]; then
				echo "{\"Chrome Cookies\": " >> $output_path/cookies.json
				echo "{\"File\": \"$filepath\", \"Data\": $getcookies}," >> $output_path/cookies.json
				tmp_history=$(sed '$ s/.$//' $output_path/cookies.json)
				echo "$tmp_history,\"metadata\": { \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $output_path/cookies.json
			fi
		fi

	done
fi
