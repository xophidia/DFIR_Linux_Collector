#!/bin/bash

for X in $(cut -f6 -d ':' /etc/passwd |sort |uniq); do
    if [ -s "${X}/.gitconfig" ]; then
        more ${X}/.gitconfig | awk '{print $3}' | awk '{print}' ORS=' ' | awk 'BEGIN{print "{ \"gitconfig\" : ["} {print "{\"email\": \"",$1,"\", \"user\": \"",$2,"\"},"} END{print "]}"} ENDFILE{print "{\"email\": \"",$1,"\", \"user\": \"",$2,"\"}"}' | jq 'del(.gitconfig[-1:])' |  jq --arg l_user $user --arg l_host $host --arg l_caseNumber $caseNumber --arg l_desc $desc '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >> $OUTPUT/user_gitconfig.json
    fi
done
