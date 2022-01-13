MAIN_PACKAGES=bash libgcc libstdc++ lsof musl iptables findutils audit-libs linux-pam sudo libcrypto1.1 libmagic musl openssl-dev libmagic pkgconf jq gawk ncurses net-tools
COMMUNITY_PACKAGES=patchelf 
ALPINE_REPO=http://dl-cdn.alpinelinux.org/alpine/v3.10
APK=http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/apk-tools-static-2.10.8-r0.apk 

all:	clean dlc package

dlc:
	mkdir alpine && cd alpine \
	&& wget $(APK) -O - | tar -xzv \
	&& mkdir -p run bin usr/bin usr/sbin target \
	&& cp -a ../busybox-1_34_1/busybox bin/busybox.static  \
	&& chroot ./ /bin/busybox.static --install \
	&& ./sbin/apk.static -X $(ALPINE_REPO)/main      -U --allow-untrusted -p ./ --initdb add $(MAIN_PACKAGES) \
	&& ./sbin/apk.static -X $(ALPINE_REPO)/community -U --allow-untrusted -p ./ add $(COMMUNITY_PACKAGES) \
	&& cp ../bootstrap.sh ../dlc.sh ./ \
	&& mkdir -p ../tools/ \
	&& cp -r ../tools ./ \
	&& cp -r ../scripts ./
	chmod +x ./*.sh ./tools/* ./scripts/*

package:
	# Copie de la config perso
	cp dlc.sh alpine/
	chmod +x alpine/dlc.sh alpine/bootstrap.sh alpine/tools/*
	makeself-2.4.5/makeself.sh ./alpine DFIR_linux_collector dlc ./bootstrap.sh

clean:
	rm -rf alpine DFIR_linux_collector output DLC_Collect*
