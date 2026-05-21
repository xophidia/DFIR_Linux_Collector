# DFIR_Linux_Collector
![GitHub last commit](https://img.shields.io/github/last-commit/xophidia/DFIR_Linux_Collector) ![GitHub release-date](https://img.shields.io/github/release-date/xophidia/DFIR_Linux_Collector)

Outil de collecte autonome pour Gnu/Linux — **branche `feature/yaml-rules`**

- Très faible impact sur la machine cible
- N'utilise aucun binaire de l'hôte (anti-hooking)
  - tous les binaires nécessaires sont embarqués dans l'exécutable
- Export au format JSON / texte / raw (dump RAM)
- Dump RAM avec AVML (compatibilité : https://github.com/microsoft/avml#tested-distributions)
- Livre une archive compressée + fichier de checksums

---

## Nouvelle architecture (branche feature/yaml-rules)

```
DFIR_Linux_Collector/
├── dlc.sh              → Moteur générique (~290 lignes)
├── rules.json          → Toutes les règles de collecte (YAML-like JSON)
├── scripts/            → Scripts externes (firefox, chrome, ssh, etc.)
├── tools/              → Binaires embarqués (avml, sqlite3)
├── bootstrap.sh        → Lanceur standalone
└── Makefile            → Build de l'archive makeself
```

### Principe de fonctionnement

1. `dlc.sh` lit `rules.json` via `jq` (embarqué)
2. L'utilisateur choisit un mode (Light / Medium / Full)
3. Le moteur itère sur les catégories du mode sélectionné
4. Chaque commande est exécutée, formatée en JSON, enrichie des métadonnées
5. Les fonctions complexes (antivirus, kernel, RAM, etc.) restent en bash
6. Les scripts externes (navigateurs, SSH, etc.) sont appelés directement

### Formats de règles supportés

| Format | Description | Exemple |
|---|---|---|
| `wrap` | Sortie texte → encapsulée dans `{"cle": "valeur"}` | `uname -a`, `uptime` |
| `jsonl` | Sortie → transformée en JSONL par un formateur awk → tableau | `env`, `lsmod`, `ps` |
| `raw` | Copie brute dans un fichier texte | `lsof` |
| `function` | Fonction bash dédiée (logique complexe) | `antivirus`, `dump_ram` |
| `scripts` | Appel de scripts externes | `firefox.sh`, `c_ssh.sh` |

### Ajouter une nouvelle règle simple

Il suffit d'ajouter un bloc dans `rules.json`, catégorie `generic`, `network` ou `process` :

```json
{ "name": "hostname", "cmd": "hostname", "output": "gen_hostname.json", "format": "wrap", "key": "hostname" }
```

Pour une règle avec formatage tableau (awk) :

```json
{ "name": "timedatectl", "cmd": "timedatectl", "output": "gen_timedate.json", "format": "jsonl", "formatter": "fmt_timedate", "key": "timedate" }
```

Il faut alors créer la fonction `fmt_timedate` dans `dlc.sh` :

```bash
function fmt_timedate() {
    awk -F: '{gsub(/^[[:space:]]+/, "", $1); gsub(/^[[:space:]]+/, "", $2); print "{\"key\": \""$1"\", \"value\": \""$2"\"}"}'
}
```

### Modes de collecte

| Mode | Catégories incluses |
|---|---|
| **Light** | generic, network, process, user, artefactsDistribution, exportRawKernelArtefacts, antivirus |
| **Medium** | Light + interestFile (MD5, permissions, timeline) |
| **Full** | Medium + dump_ram (AVML) |

Définis dans `rules.json` — modification sans toucher au code.

---

## Compatibilité

| Distribution | Version | OK | Erreur | Commentaires |
|---|---|---|---|---|
| Ubuntu | 12 - 20 | :heavy_check_mark: | --- | --- |
| Debian | > 8 | :heavy_check_mark: | --- | --- |
| Fedora | 30 | :heavy_check_mark: | --- | --- |
| CentOS | 7 | :heavy_check_mark: | --- | --- |
| CentOS | 6 | --- | :heavy_multiplication_x: | Kernel trop ancien |

Les autres distributions n'ont pas encore été testées.

---

## Versions des composants embarqués

### Versions actuelles (Makefile actuel)

| Composant | Version | Date | État |
|---|---|---|---|
| Alpine Linux | **v3.10** | Oct 2019 | :warning: **EOL** (plus de mises à jour de sécurité) |
| apk-tools-static | **2.10.8-r0** | 2019 | :warning: Obsolète |
| busybox | **1.34.1** | Dec 2021 | :warning: Obsolète |
| jq | **1.6** | 2018 | OK (stable mais ancien) |

### Versions disponibles (mise à jour recommandée)

| Composant | Dernière stable | Lien |
|---|---|---|
| Alpine Linux | **v3.23.4** (15 Avr 2026) | https://alpinelinux.org |
| apk-tools-static | **3.0.6-r0** | https://pkgs.alpinelinux.org/package/edge/main/x86_64/apk-tools-static |
| busybox | **1.37.0** (27 Sep 2024) | https://busybox.net/downloads/busybox-1.37.0.tar.bz2 |
| jq | **1.8.1-r0** | Inclus dans Alpine v3.23 |

**Mise à jour recommandée dans le Makefile :**

```makefile
ALPINE_REPO=http://dl-cdn.alpinelinux.org/alpine/v3.23
APK=http://dl-cdn.alpinelinux.org/alpine/v3.23/main/x86_64/apk-tools-static-3.0.5-r0.apk
```

Et remplacer `busybox-1_34_1.zip` par `busybox-1.37.0.tar.bz2`.

:warning: **Important** : Alpine v3.10 → v3.23 nécessite de tester la compatibilité des paquets (`jq`, `lsof`, `findutils`, etc.). Les noms de paquets peuvent avoir changé.

---

## Quick start

![](dlc.gif)

```bash
git clone https://github.com/xophidia/DFIR_Linux_Collector.git
cd DFIR_Linux_Collector
git checkout feature/yaml-rules    # ← branche avec la nouvelle archi
./setup.sh
```

```bash
sudo ./DFIR_linux_collector
Verifying archive integrity...  100%   MD5 checksums are OK. All good.
Uncompressing orc  100%

    ██████╗ ██╗      ██████╗
    ██╔══██╗██║     ██╔════╝
    ██║  ██║██║     ██║      
    ██║  ██║██║     ██║     
    ██████╔╝███████╗╚██████╗
    ╚═════╝ ╚══════╝ ╚═════╝
                        
     DFIR Linux Collector

    Case Number : 10 
    Description : linux_host
    Examiner Name : Xophidia
    Hostname : 10_01

    Dump generic artifacts
    +  uname ....................[success]
    +  env ......................[success]
    +  uptime ...................[success]
    ...
```

---

## Artefacts collectés

### Generic

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| env | :heavy_check_mark: | --- | --- |
| uptime | :heavy_check_mark: | --- | --- |
| uname -a | :heavy_check_mark: | --- | --- |
| lsmod | :heavy_check_mark: | --- | --- |
| /etc/passwd | :heavy_check_mark: | --- | --- |
| /etc/group | :heavy_check_mark: | --- | --- |
| date | :heavy_check_mark: | --- | --- |
| who | :heavy_check_mark: | --- | --- |
| cpuinfo | :heavy_check_mark: | --- | --- |
| lsof | --- | :heavy_check_mark: | --- |
| sudoers | :heavy_check_mark: | --- | --- |
| mount | :heavy_check_mark: | --- | --- |
| fstab | :heavy_check_mark: | --- | --- |
| last | :heavy_check_mark: | --- | --- |

### SSH

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| authorized_keys | :heavy_check_mark: | --- | --- |
| known_hosts | :heavy_check_mark: | --- | --- |

### Network

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| ip | :heavy_check_mark: | --- | --- |
| netstat | :heavy_check_mark: | --- | --- |
| arp | :heavy_check_mark: | --- | --- |

### Processus

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| ps | :heavy_check_mark: | --- | --- |

### Browser

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| Firefox | :heavy_check_mark: | --- | --- |
| Google Chrome | :heavy_check_mark: | --- | --- |
| Chromium | :heavy_check_mark: | --- | --- |

### Logs

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| auth.log | --- | :heavy_check_mark: | --- |
| syslog | :heavy_check_mark: | --- | --- |

### Home

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| .gitconfig | :heavy_check_mark: | --- | --- |
| .command_history (bash + zsh) | :heavy_check_mark: | --- | :heavy_check_mark: |
| .viminfo | --- | :heavy_check_mark: | --- |

### Desktop

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| corbeille (trash) | --- | --- | :heavy_check_mark: |
| applications fréquentes (GNOME) | :heavy_check_mark: | --- | --- |

### Fichiers

| Commande / Fichier | Json | Texte | Raw | Csv |
|---|---|---|---|---|
| hashes MD5 | :heavy_check_mark: | :heavy_check_mark: | --- | --- |
| permissions (SUID/SGID) | :heavy_check_mark: | --- | --- | --- |
| timeline | --- | --- | --- | :heavy_check_mark: |

### Dump

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| AVML (RAM) | --- | --- | :heavy_check_mark: |
| LiME | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_multiplication_x: |
| /boot/System.map-$(uname -r) | --- | --- | :heavy_check_mark: |
| /boot/vmlinuz | --- | --- | :heavy_check_mark: |

### Antivirus

| Commande / Fichier | Json | Texte | Raw |
|---|---|---|---|
| ClamAV | :heavy_check_mark: | --- | --- |

---

## Développement avec Git

```bash
# Créer une branche pour une nouvelle fonctionnalité
git checkout main
git checkout -b feature/ma-fonctionnalite

# Après modifications
git add rules.json dlc.sh
git commit -m "feat: ajout de la collecte ..."

# Pousser la branche
git push -u origin feature/ma-fonctionnalite

# Fusionner dans main après validation
git checkout main
git merge feature/ma-fonctionnalite
git push origin main
```

---

## License

GNU Lesser General Public License

## Contributeurs

:godmode: xophidia https://github.com/xophidia  
:godmode: Dupss https://github.com/dupss  
:godmode: leludo84 https://github.com/leludo84
