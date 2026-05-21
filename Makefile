# Alpine Linux v3.23 (Avril 2026) — busybox 1.36.1 — jq 1.8.1 — OpenSSL 3.x
ALPINE_REPO=http://dl-cdn.alpinelinux.org/alpine/v3.23
APK=http://dl-cdn.alpinelinux.org/alpine/v3.23/main/x86_64/apk-tools-static-3.0.5-r0.apk

# Paquets installés via apk dans le chroot Alpine
MAIN_PACKAGES=bash libgcc libstdc++ lsof musl iptables findutils audit-libs linux-pam sudo libcrypto3 openssl jq gawk ncurses net-tools grep
COMMUNITY_PACKAGES=patchelf

all:	clean dlc package

dlc:
	mkdir alpine && cd alpine \
	&& wget $(APK) -O - | tar -xzv \
	&& mkdir -p run bin usr/bin usr/sbin target etc lib lib64 tmp proc sys dev \
	&& ./sbin/apk.static -X $(ALPINE_REPO)/main      -U --allow-untrusted -p ./ --initdb add busybox-static \
	&& chroot ./ /bin/busybox.static --install \
	&& ./sbin/apk.static -X $(ALPINE_REPO)/main      -U --allow-untrusted -p ./ add $(MAIN_PACKAGES) \
	&& ./sbin/apk.static -X $(ALPINE_REPO)/community -U --allow-untrusted -p ./ add $(COMMUNITY_PACKAGES) \
	&& cp ../bootstrap.sh ../dlc.sh ../rules.json ./ \
	&& mkdir -p ../tools/ \
	&& cp -r ../tools ./ \
	&& cp -r ../scripts ./
	chmod +x alpine/*.sh alpine/tools/* alpine/scripts/*

package:
	cp dlc.sh rules.json alpine/
	chmod +x alpine/dlc.sh alpine/bootstrap.sh alpine/tools/*
	makeself-2.4.5/makeself.sh ./alpine DFIR_linux_collector dlc ./bootstrap.sh

clean:
	rm -rf alpine DFIR_linux_collector output DLC_Collect*
