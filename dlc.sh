#!/bin/bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="$SCRIPT_DIR/rules.json"
OUTPUT="${OUTPUT:-$SCRIPT_DIR/output}"

start=$(date +%s)

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
        printf "   ${red} + ${normal} $2 "
        size=$(wc -c <<< $2)
        val=$(( 26 - $size ))
        for (( i=0; i<$val; i++ )); do printf '.'; done
        printf "${green}[success]${normal}\n"
    else
        printf "   ${red} + ${normal} $2 "
        size=$(wc -c <<< $2)
        val=$(( 26 - $size ))
        for (( i=0; i<$val; i++ )); do printf '.'; done
        printf "${red}[failed]${normal}\n"
    fi
}

function add_metadata()
{
    jq '. + {metadata: {"Case Number": env.caseNumber, "Description": env.desc, "Username": env.user, "Hostname": env.host}}'
}

function fmt_env()
{
    awk -F= '{print "{\"envars\": \""$1"\", \"data\": \""$2"\"}"}'
}

function fmt_lsmod()
{
    awk 'NR>1 {print "{\"Module\": \""$1"\", \"Size\": \""$2"\", \"UsedBy\": \""$3"\", \"NotTainted\": \""$4"\"}"}'
}

function fmt_passwd()
{
    awk -F: '{print "{\"user\": \""$1"\", \"user_group\": \""$3$4"\", \"Home\": \""$6"\", \"shell\": \""$7"\"}"}'
}

function fmt_cpuinfo()
{
    awk -F: '{gsub(/[[:blank:]]/,"",$1); gsub(/[[:blank:]]/,"",$2); if($1 && $2) print "{\"id\": \""$1"\", \"data\": \""$2"\"}"}'
}

function fmt_group()
{
    awk -F: '{print "{\"user\": \""$1"\", \"group\": \""$3"\"}"}'
}

function fmt_mount()
{
    awk '{print "{\"device\": \""$1"\", \"mountpoint\": \""$3"\", \"type\": \""$5"\", \"attributes\": \""$6"\"}"}'
}

function fmt_sudoers()
{
    grep -v '#\|Defaults' | awk 'NF' | awk '$1=$1' | awk -F= '{print "{\"user\": \""$1"\", \"data\": \""$2"\"}"}'
}

function fmt_fstab()
{
    grep -v '#\|Defaults' | awk 'NF' | awk '$1=$1' | awk -F: '{print "{\"line\": \""$1"\"}"}'
}

function fmt_netstat()
{
    sed -e '1,2d' | awk '{print "{\"Destination\": \""$1"\", \"Gateway\": \""$2"\", \"Genmask\": \""$3"\", \"Iface\": \""$8"\"}"}'
}

function fmt_arp()
{
    sed -e '1d' | awk '{print "{\"Address\": \""$1"\", \"HWType\": \""$2"\", \"HWaddress\": \""$3"\", \"Flags\": \""$4"\", \"Iface\": \""$5"\"}"}'
}

function fmt_ps()
{
    awk 'NR>1 {print "{\"USER\": \""$1"\", \"GROUP\": \""$2"\", \"PID\": \""$3"\", \"PPID\": \""$4"\", \"STAT\": \""$5"\", \"CMD\": \""$6"\"}"}'
}

function fmt_last()
{
    while read line; do
        if [ -n "$line" ]; then
            echo "{\"line\": \"$line\"}"
        fi
    done
}

function fmt_ip()
{
    jq -R 'capture("^[0-9]+: (?<ifname>[^[:space:]]+)[[:space:]]+inet (?<addr>[^[:space:]/]+)(/(?<masklen>[[:digit:]]+))?") // empty'
}

function interestFile()
{
    echo "
    Dump files artifacts"
    printf "    ${yellow}-${normal} Please wait, it may take some time ...\n"

    outputpath="$OUTPUT/Hashes/"
    outfile="$outputpath/MD5_hashes.json"
    mkdir -p $outputpath
    find / -type f -xdev -executable -not \( -path "/proc/*" -o -path "/sys/*" \) -exec md5sum {} \; 2>/dev/null > $outputpath/MD5_hashes
    cat $outputpath/MD5_hashes | awk -F' ' 'BEGIN{print "{ \"MD5 Hashes\" : ["}  {print "{\"hash\": \"",$1,"\", \"file\": \"",$2,"\"},"}' >> $outfile
    tmp=$(sed '$ s/.$//' $outfile)
    tmp_final=$(echo $tmp| sed 's/\ //g')
    echo "$tmp_final],\"metadata\": { \"Case Number\": \"$caseNumber\", \"Description\" : \"$desc\", \"Username\": \"$user\", \"Hostname\": \"$host\" }}" > $outfile
    verif $? "MD5 Hashes (executable files)"

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
        cp /boot/vmlinuz-$(uname -r) $OUTPUT/vmlinuz-$(uname -r)
        verif $? "vmlinuz"
    fi

    test -f /boot/System.map-$(uname -r)
    if [[ $? -eq 0 ]]; then
        cp /boot/System.map-$(uname -r) $OUTPUT/System.map-$(uname -r)
        verif $? "System.map"
    fi
}

function artefactsDistribution()
{
    ver_dist=(redhat centos fedora debian lsb gentoo SuSE)
    log_fedora=(program.log storage.log yum.log syslog)

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
        "redhat" | "fedora" | "centos")
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

function antivirus()
{
    test -f /var/log/syslog
    if [[ $? -eq 0 ]]; then
        echo "  Dump antivirus artifacts"
        clamav_version=$(cat /var/log/syslog | grep freshclam | grep "Local version" | awk -F: '{print $7}' | cut -d " " -f2 | tail -1)
        update_date=$(cat /var/log/syslog | grep freshclam | grep "daily.cld" | tail -1 | cut -d " " -f1-3)
        sign=$(cat /var/log/syslog | grep freshclam | grep "daily.cld" | tail -1 | cut -d "(" -f2 | cut -d "," -f1 | cut -d " " -f2)
        echo "{ \"ClamAV\" : { \"Version\": \"$clamav_version\",\"Update date\": \"$update_date\",\"Signature\": \"$sign\"}}" | jq --arg l_user "$user" --arg l_host "$host" --arg l_caseNumber "$caseNumber" --arg l_desc "$desc" '. + {metadata: { "Case Number":  ($l_caseNumber), "Description" : ($l_desc), "Username": ($l_user), "Hostname": ($l_host) } }' > $OUTPUT/av.json
        verif $? "ClamAV"
    fi
}

function dump_ram()
{
    echo "
    Dump RAM"
    ./tools/avml-minimal $OUTPUT/memory_dump.raw
    verif $? "RAM"
}

function run_category()
{
    local category=$1
    local cat_json=$(jq -c ".categories[\"$category\"]" "$RULES_FILE")
    local cat_type=$(echo "$cat_json" | jq -r '.type // "commands"')
    local description=$(echo "$cat_json" | jq -r '.description // ""')

    echo ""
    echo "    $description"

    if [ "$cat_type" = "function" ]; then
        local func_name=$(echo "$cat_json" | jq -r '.function')
        $func_name
    elif [ "$cat_type" = "scripts" ]; then
        for script in $(echo "$cat_json" | jq -r '.scripts[]'); do
            bash ./scripts/$script.sh 2>/dev/null
            verif $? "$script"
        done
    else
        local count=$(echo "$cat_json" | jq '.commands | length')
        for i in $(seq 0 $((count - 1))); do
            local cmd=$(echo "$cat_json" | jq -r ".commands[$i].cmd")
            local output=$(echo "$cat_json" | jq -r ".commands[$i].output")
            local name=$(echo "$cat_json" | jq -r ".commands[$i].name")
            local format=$(echo "$cat_json" | jq -r ".commands[$i].format")
            local key=$(echo "$cat_json" | jq -r ".commands[$i].key // \"$name\"")
            local formatter=$(echo "$cat_json" | jq -r ".commands[$i].formatter // \"\"")

            case "$format" in
                "jsonl")
                    if [ -n "$formatter" ] && declare -F "$formatter" > /dev/null 2>&1; then
                        eval "$cmd" 2>/dev/null | $formatter 2>/dev/null | jq -s "{\"$key\": .}" 2>/dev/null | add_metadata > "$OUTPUT/$output" 2>/dev/null
                    else
                        eval "$cmd" 2>/dev/null | jq -s "{\"$key\": .}" 2>/dev/null | add_metadata > "$OUTPUT/$output" 2>/dev/null
                    fi
                    verif $? "$name"
                    ;;
                "wrap")
                    local val=$(eval "$cmd" 2>/dev/null)
                    echo "$val" | head -1 | jq -R "{\"$key\": .}" 2>/dev/null | add_metadata > "$OUTPUT/$output" 2>/dev/null
                    verif $? "$name"
                    ;;
                "raw")
                    eval "$cmd" > "$OUTPUT/$output" 2>/dev/null
                    verif $? "$name"
                    ;;
                *)
                    eval "$cmd" 2>/dev/null
                    verif $? "$name"
                    ;;
            esac
        done
    fi
}

function collect()
{
    local mode_name=$1
    for category in $(jq -r ".modes[\"$mode_name\"][]" "$RULES_FILE"); do
        run_category "$category"
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
            collect "light"
            break
            ;;
        "Medium (Light mode + File Artifacts)")
            echo ""
            echo "${yellow_background}${bold}>>>>>>>> Medium mode selected <<<<<<<<${normal}"
            echo ""
            collect "medium"
            break
            ;;
        "Full (Medium mode + Memory Dump)")
            echo ""
            echo "${red_background}${bold}>>>>>>>> Full mode selected <<<<<<<<${normal}"
            echo ""
            collect "full"
            break
            ;;
        "Quit")
            echo "${red}Bye!${normal}"
            exit 0
            ;;
        *) echo "${red_background}Invalid option, please retry! $REPLY${normal}";;
    esac
done

end=$(date +%s)
runtime=$((end-start))

echo ""
echo "#################################"
echo "${green}Collect completed in $((runtime / 60))min $((runtime % 60))sec${normal}"
echo "#################################"
echo ""
