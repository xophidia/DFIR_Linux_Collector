#!./bin/busybox.static sh

export PATH=$PWD/bin:$PWD/sbin:$PWD/usr/bin:$PWD/usr/sbin
export -n LD_LIBRARY_PATH
export OUTPUT="output"

echo "Preparing environment ..."
# Changement path du linker pour les binaires liés dynamiquement (ex: python3)
# https://www.it-swarm-fr.com/fr/linux/plusieurs-bibliotheques-glibc-sur-un-seul-hote/957545379/
#patcher également toutes les commandes utilisée (anti RK)
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/lsof 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /bin/bash 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /sbin/iptables 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/sudo 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/find 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/xargs 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/gawk 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/jq 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/sed 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /usr/bin/tput 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /sbin/arp 2>/dev/null
chroot ./ /usr/bin/patchelf --set-interpreter $PWD/lib/ld-musl-x86_64.so.1 /bin/netstat 2>/dev/null
mkdir output


echo "Launching tools ..."
export LD_LIBRARY_PATH=$PWD/lib:$PWD/usr/lib:$PWD/usr/lib/sudo


if [ "$1" = "full" ]; then
    bash ./dlc.sh full 2>&1 | tee $OUTPUT/dlc.log
elif [ "$1" = "full" ]; then
    bash ./dlc.sh full 2>&1 | tee $OUTPUT/dlc.log
elif [ "$1" = "rescue" ]; then
    echo "**** Mode rescue. ****"
    echo "Les commandes que vous tapez sont sécurisées."
    bash
    echo "Fin mode rescue."
else
    bash ./dlc.sh 2>&1 | tee $OUTPUT/dlc.log
fi


echo ""
echo "Archive creation ..."

tar -czvf $USER_PWD/DLC_Collect-$HOSTNAME-`date +%F`.tgz output/
