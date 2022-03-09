#!/bin/bash


#Todo
# timedatectl
# w (logged users)
# faillog -a
# chkconfig --list (list services)
# cat /etc/pam.d/common/*

# Set start date
start=`date +%s`

# Set collect mode methods
list_method_light=(generic network process user artefactsDistribution exportRawKernelArtefacts antivirus)
list_method_medium=(generic network process user artefactsDistribution exportRawKernelArtefacts antivirus interestFile)
list_method_full=(generic network process user artefactsDistribution exportRawKernelArtefacts antivirus interestFile dump_ram)

# OS list
ver_dist=(redhat centos fedora debian lsb gentoo SuSE)

# Fedora logs list
log_fedora=(program.log storage.log yum.log syslog)

# Custom scripts list
action=(c_ssh firefox c_git chromium google-chrome command_history vim trash frequent_apps)

# Set colors
white=$(tput setaf 7)
white_background=$(tput setab 7)
black=$(tput setaf 0)
blue=$(tput setaf 4)
blue_background=$(tput setab 4)
yellow=$(tput setaf 3)
yellow_background=$(tput setab 3)
green=$(tput setaf 2)
green_background=$(tput setab 2)
red=$(tput setaf 1)
red_background=$(tput setab 1)
normal=$(tput sgr0)
bold=$(tput bold)

function banner()
{

echo "



    ██████╗ ██╗      ██████╗
    ██╔══██╗██║     ██╔════╝
    ██║  ██║██║     ██║     
    ██║  ██║██║     ██║     
    ██████╔╝███████╗╚██████╗
    ╚═════╝ ╚══════╝ ╚═════╝
                        
     DFIR Linux Collector


"
}


function verif()
{
    if [[ $1 -eq 0 ]]; then
	    printf  "   ${red} + ${normal} $2 "
	    size=$(wc -c <<< $2)
            val=$(( 26 - $size ))

	    for (( i=0; i<$val; i++ )) 
	    do 
		    printf '.'
	    done; 
	    printf "${green}[success]${normal}\n"
    else
	    printf "   ${red} + ${normal} $2 "
	    size=$(wc -c <<< $2)
            val=$(( 26 - $size ))

	    for (( i=0; i<$val; i++ )) 
	    do 
		    printf '.'
	    done; 
	    printf "${red}[failed]${normal}\n"
    fi
}



function interestFile()
{

    echo "    
    Dump files artifacts"
    printf "    ${yellow}-${normal} Please wait, it may take some time ...\n"
    

    #HASHS MD5

    outputpath="$OUTPUT/Hashes/"
    outfile="$outputpath/MD5_hashes.json"
    mkdir $outputpath
    find / -type f -xdev -executable -not \( -path "/proc/*" -o -path "/sys/*" \) -exec md5sum {} \; 2>/dev/null > $outputpath/MD5_hashes
    cat $outputpath/MD5_hashes | awk -F' ' 'BEGIN{print "{ \"MD5 Hashes\" : ["}  {print "{\"hash\": \"",$1,"\", \"file\": \"",$2,"\"},"}' >> $outfile
    tmp=$(sed '$ s/.$//' $outfile)
    #Remove spaces
    tmp_final=$(echo $tmp| sed 's/\ //g')
    echo "$tmp_final],\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $outfile
    verif $? "MD5 Hashes (executable files)"

    #Files with interesting rights

    outfile=$OUTPUT/interest_files.json
    echo "{\"interest_files\": {" >> $outfile
    action=('-o=s' '-u=s' '-g=s')
    for act in ${action[@]}
    do
        echo "\"File ${act}\":[ ">> $outfile
        tmp=$(find /  -xdev -path /proc -prune -o -type f -perm ${act} -exec echo "{\"Path\": \"{}\"}," \; 2>/dev/null | sed 's/\\/\\\\/g')
        echo $tmp | sed '$ s/.$//' >> $outfile
        echo "]," >> $outfile
    done

    finaltmp=$(sed '$ s/.$//' $outfile)
    echo "$finaltmp, \"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}}" > $outfile
    verif $? "interestFile"
    
    #TIMELINE
    
    outfile="$OUTPUT/timeline.csv"
    printf "Access Date,Access Time,Modify Date,Modify Time,Create Date,Create Time,Permissions,User ID,Group ID,File Size,Filename\n" >> $outfile
    find / -xdev -printf "%Ax,%AT,%Tx,%TT,%Cx,%CT,%m,%U,%G,%s,%p\n" 2>>/dev/null >> $outfile
    if [[ ! -z "$outfile" ]]; then
    	verif "0" "timeline"
    else
    	verif $? "timeline"
    fi
}

function exportRawKernelArtefacts()
{

    echo "
    Dump kernel artifacts"

  test -f /boot/vmlinuz-$(uname -r)

  if [[ $? -eq 0 ]]; then
     cp  /boot/vmlinuz-$(uname -r) $OUTPUT/vmlinuz-$(uname -r)
     verif $? "vmlinuz"
  fi

  test -f /boot/System.map-$(uname -r)

  if [[  $? -eq 0 ]]; then
    cp  /boot/System.map-$(uname -r) $OUTPUT/System.map-$(uname -r)
    verif $? "System.map"
  fi


}


function artefactsDistribution()
{

    echo "
    Dump artifacts / linux distribution"

    for distr in ${ver_dist[@]}
    do
	test -f /etc/$distr-release 
        if [[ $? -eq 0 ]]; then
	        export distri_id=$distr
        fi
    done


    case $distri_id in

       "lsb" | "debian")
               printf "   ${red} + ${normal} Debian-like artifacts \n"
               test -f /var/log/installer/debug
	       if [[ $? -eq 0 ]]; then
	           more /var/log/installer/debug > $OUTPUT/$distri_id"installer_debug.txt"
	           verif $? "installer debug"
	       fi
	       test -f /var/log/installer/syslog
               if [[ $? -eq 0 ]]; then
		   more /var/log/installer/syslog > $OUTPUT/$distri_id"installer_syslog.txt"
	           verif $? "installer syslog"
	       fi
	       test -f /var/log/auth.log
               if [[ $? -eq 0 ]]; then
    	           more /var/log/auth.log > $OUTPUT/gen_auth
                   verif $? "auth"
	       fi

    	       more /var/log/syslog | sed 's/\\/\\\\/g' | sed s/"\""/"'"/g | sed s/"\t"//g | awk 'BEGIN{print "{ \"syslog\" : ["}  {print "{\"data\": \"",$0,"\"},"} END{print "]}"}  ENDFILE{print "{\"data\": \"",$0,"\"}"}'| jq 'del(.auth[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_syslog.json
               verif $? "syslog"
               ;;
      
       "redhat" | "fedora" | "centos" )
	       printf "   ${red} + ${normal} RedHat-like artifacts \n"
               for el in ${log_fedora[@]}
               do
                   test -f /var/log/anaconda/$el
                   if [[ $? -eq 0 ]]; then
			   more /var/log/anaconda/$el > $OUTPUT/fedora_installer_anaconda.$el
                   
                   fi
               done
               ;;
       
       "gentoo")
               echo "gentoo"
               ;;

       "SuSE")
               printf "   ${red} + ${normal} Suse-like artifacts \n"
	       ;;

       *)
               ;;
    esac

}



function generic()
{
    
    echo "
    Dump generic artifacts"
    jq --raw-input '{"uname": '.'}' < <(uname -a)  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_uname.json
    verif $? "uname"

    env | awk -F= 'BEGIN{print "{ \"env\" : ["} {print "{\"envars\": \"",$1,"\", \"data\": \"",$2,"\"},"} END{print "]}"} ENDFILE{print "  {\"envars\": \"",$1,"\", \"data\": \"",$2,"\"}"}'  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_env.json
    verif $? "env"

    jq --raw-input '{"uptime": '.'}' < <(uptime) | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_uptime.json
    verif $? "uptime"

    lsmod | awk 'BEGIN{print "{ \"lsmod\" : ["} {print "  {\"Module\": \"",$1,"\", \"Size\": \"",$2,"\", \"UsedBy\": \"",$3,"\", \"NotTainted\": \"",$4,"\"},"}  END{print "]}"} ENDFILE{print "  {\"Module\": \"",$1,"\", \"Size\": \"",$2,"\", \"UsedBy\": \"",$3,"\", \"NotTainted\": \"",$4,"\"}"}' | jq 'del(.env[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_lsmod.json
    verif $? "lsmod"

    more /etc/passwd | awk -F: 'BEGIN{print "{ \"pwd\" : ["} {print "  {\"user\": \"",$1,"\", \"user_group\": \"",$3,$4,"\",\"Home\": \"",$6,"\",\"shell\": \"",$7"\"},"} END{print "]}"} ENDFILE{print "  {\"user\": \"",$1,"\", \"user_group\": \"",$3,$4,"\",\"Home\": \"",$6,"\",\"shell\": \"",$7"\"}"}' | jq 'del(.pwd[-1:])'  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_passwd.json
    verif $? "passwd"

    jq --raw-input '{"date": '.'}' < <(date)  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >$OUTPUT/gen_date.json
    verif $? "date"

    jq --raw-input '{"who": '.'}' < <(who)  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >$OUTPUT/gen_who.json
    verif $? "who"

    more /proc/cpuinfo | awk -F':' 'BEGIN{print "{ \"cpuinfo\" : ["}  gsub(/[[:blank:]]/,"",$1) gsub(/[[:blank:]]/,"",$2) {print "{\"id\": \""$1"\", \"data\": \""$2"\"},"} END{print "]}"}  ENDFILE{print "{\"id\": \"",$1,"\", \"data\": \"",$2,"\"}"}' | jq 'del(.cpuinfo[-1:])'  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >$OUTPUT/gen_cpuinfo.json
    verif $? "cpuinfo"
    
    more /etc/group | awk -F':' 'BEGIN{print "{ \"group\" : ["}  {print "{\"user\": \"",$1,"\", \"group\": \"",$3,"\"},"} END{print "]}"} ENDFILE {print "{\"user\": \"",$1,"\", \"group\": \"",$3,"\"}"}' | jq 'del(.group[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' >$OUTPUT/gen_group.json
    verif $? "group"
    
    lsof > $OUTPUT/gen_lsof 2>/dev/null
    verif $? "lsof"

    mount 2>/dev/null | awk 'BEGIN{print "{ \"mount\" : ["} {print "{\"device\": \""$1"\", \"mountpoint\": \""$3"\", \"type\": \""$5"\", \"attributes\": \""$6"\"},"} END{print "]}"} ENDFILE {print "{\"device\": \"",$1,"\", \"mountpoint\": \"",$3,"\", \"type\": \"",$5,"\", \"attributes\": \"",$6,"\"}"}' | jq 'del(.mount[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_mount.json
    verif $? "mount"

    more /etc/sudoers | grep -v '#\|Defaults' | awk 'NF' | awk '$1=$1' |awk -F= 'BEGIN{print "{ \"sudoers\" : ["} {print "{\"user\": \""$1"\", \"data\": \""$2"\"},"} END{print "]}"} ENDFILE{print "{\"user\": \""$1"\", \"data\": \""$2"\"}"}' | jq 'del(.sudoers[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_sudoers.json
    verif $? "sudoers"

    more /etc/fstab | grep -v '#\|Defaults' | awk 'NF' | awk '$1=$1' |awk -F: 'BEGIN{print "{ \"fstab\" : ["} {print "{\"line\": \""$1"\"},"} END{print "]}"} ENDFILE{print "{\"line\": \""$1"\"}"}' | jq 'del(.fstab[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/gen_fstab.json
    verif $? "fstab"


    #Last
    outfile="$OUTPUT/gen_last.json"
    echo "{ \"last\": [" >> $outfile
     last | while read line
            do
                if [ ! -z "$line" ]; then
                        echo \"${line}\",>> $outfile
                fi
	done
    tmp_last=$(sed '$ s/.$//' $outfile)
    echo "$tmp_last],\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $outfile
    verif $? "last"
    
}

function antivirus()
{
    test -f /var/log/syslog
    if [[ $? -eq 0 ]]; then
    	echo "

    Dump antivirus artifacts"
    
    	# CLamAV
    	clamav_version=$(cat /var/log/syslog | grep freshclam | grep "Local version" | awk -F: '{print $7}' | cut -d " " -f2 | tail -1)
  	update_date=$(cat /var/log/syslog | grep freshclam | grep "daily.cld" | tail -1 | cut -d " " -f1-3)
   	sign=$(cat /var/log/syslog | grep freshclam | grep "daily.cld" | tail -1 | cut -d "(" -f2 | cut -d "," -f1 | cut -d " " -f2)

   	echo "{ \"ClamAV\" : { \"Version\": \"$clamav_version\",\"Update date\": \"$update_date\",\"Signature\": \"$sign\"}}" | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/av.json
   	verif $? "ClamAV"
    fi
}


function network()
{
    echo "

    Dump network artifacts"

    jq --raw-input '{"ip_info": [inputs | capture("^[0-9]+: (?<ifname>[^[:space:]]+)[[:space:]]+inet (?<addr>[^[:space:]/]+)(/(?<masklen>[[:digit:]]+))?")]}' < <(ip -o addr list)  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/network_ip.json
    verif $? "ip"	

    netstat -r -n | sed -e '1,2d' | awk 'BEGIN{print "{ \"netstat\": ["} {print "  {\"Destination\": \"",$1,"\", \"Gateway\": \"",$2,"\", \"Genmask\": \"",$3,"\", \"Iface\": \"",$8,"\"},"} END{print "]}"} ENDFILE{print "  {\"Destination\": \"",$1,"\", \"Gateway\": \"",$2,"\", \"Genmask\": \"",$8,"\", \"Iface\": \"",$4,"\"}"}'  | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' | jq 'del(.netstat[-1:])' > $OUTPUT/network_netstat.json
    verif $? "netstat"
 

    arp |sed -e '1d'| awk 'BEGIN{print "{ \"arp\" : ["} {print "  {\"Address\": \"",$1,"\", \"HWType\": \"",$2,"\", \"HWaddress\": \"",$3,"\", \"Flags\": \"",$4,"\", \"Iface\": \"",$5,"\"},"}  END{print "]}"} ENDFILE{print "  {\"Address\": \"",$1,"\", \"HWType\": \"",$2,"\", \"HWaddress\": \"",$3,"\", \"Flags\": \"",$4,"\", \"Iface\": \"",$5,"\"}"}' | jq 'del(.arp[-1:])' |jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/network_arp.json
    verif $? "arp"

}


function process()
{
    echo "
    
    Dump process artifacts"
    ps -o user,group,pid,ppid,stat,args | awk 'BEGIN{print "{ \"ps\" : ["} {print "  {\"USER\": \"",$1,"\", \"GROUP\": \"",$2,"\", \"PID\": \"",$3,"\", \"PPID\": \"",$4,"\", \"STAT\": \"",$5,"\", \"CMD\": \"",$6,"\"},"} END{print "]}"} ENDFILE {print "  {\"USER\": \"",$1,"\", \"GROUP\": \"",$2,"\", \"PID\": \"",$3,"\", \"PPID\": \"",$4,"\", \"STAT\": \"",$5,"\", \"CMD\": \"",$6,"\"}"}' | jq 'del(.ps[-1:])' | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/processus_ps.json
    verif $? "ps"
}


function user()
{
    echo "
    
    Dump user artifacts"
    for act in ${action[@]}
    do
        bash ./scripts/$act.sh 2>/dev/null
        verif $? $act
    done
}



function dump_ram()
{
    echo "
 
    Dump RAM"	
    ./tools/avml-minimal $OUTPUT/memory_dump.raw
    verif $? "RAM"
}


function collect()
{
    local -n list_method=$1

    for method in ${list_method[@]}
    do
        $method
    done
}

banner

read -p "    Case Number : " caseNumber
while [ -z "$caseNumber" ] 
do
    echo "${red}You must enter a case number${normal}"
    read -p "    Case Number : " caseNumber
done

read -p "    Description : " desc
while [ -z "$desc" ] 
do
    echo "${red}You must enter a description${normal}"
read -p "    Description : " desc
done


read -p "    Examiner Name : " user
while [ -z "$user" ] 
do
    echo "${red}You must enter an Examiner Name${normal}"
read -p "    Examiner Name : " user
done


read -p "    Hostname : " host
while [ -z "$host" ] 
do
    echo "${red}You must enter a HostName${normal}"
read -p "    Hostname : " host
done

# pour les scripts externes

export user="$user"
export host="$host"
export desc="$desc"
export caseNumber="$caseNumber"

echo ""
echo "${white_background}${black}==========================="
echo "Please select collect mode:"
echo "==========================="
PS3="Choose an option [1-4]:${normal}  "
options=("Light" "Medium (Light mode + File Artifacts)" "Full (Medium mode + Memory Dump)" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Light")
	    echo ""
            echo "${blue_background}${bold}>>>>>>>> Light mode selected <<<<<<<<${normal}"
	    echo ""
	    collect list_method_light
	    break
            ;;
        "Medium (Light mode + File Artifacts)")
	    echo ""
            echo "${yellow_background}${bold}>>>>>>>> Medium mode selected <<<<<<<<${normal}"
	    echo ""
	    collect list_method_medium
	    break
            ;;
        "Full (Medium mode + Memory Dump)")
	    echo ""
            echo "${red_background}${bold}>>>>>>>> Full mode selected <<<<<<<<${normal}"
	    echo ""
	    collect list_method_full
	    break
            ;;
        "Quit")
	    echo "${red}Bye!${normal}"	
	    exit 0
            ;;	    
        *) echo "${red_background}Invalid option, please retry! $REPLY${normal}";;
    esac
done


# Set end time
end=`date +%s`
runtime=$((end-start))


echo ""
echo "#################################"
echo "${green}Collect completed in $((runtime / 60))min $((runtime % 60))sec${normal}"
echo "#################################"
echo ""

