#!/bin/bash


for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
  for suffix in "" "2"; do
    if [ -s "${X}/.ssh/authorized_keys$suffix" ]; then
	    jq --raw-input '{"authorized_keys": '.'}' < <(cat "${X}/.ssh/authorized_keys$suffix")  | jq --arg l_user $user --arg l_host $host --arg l_caseNumber $caseNumber --arg l_desc $desc '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >> $OUTPUT/ssh_authorized_keys.json
    fi;
   done;
    if [ -s "${X}/.ssh/known_hosts" ]; then
            jq --raw-input '{"known_hosts": '.'}' < <(cat "${X}/.ssh/known_hosts")  | jq --arg l_user $user --arg l_host $host --arg l_caseNumber $caseNumber --arg l_desc $desc '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >> $OUTPUT/ssh_known_hosts.json
    fi
done
