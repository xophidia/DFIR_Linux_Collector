# DFIR_Linux_Collector
![Last commit](https://img.shields.io/badge/last%20commit-2026-brightgreen) ![Release](https://img.shields.io/badge/release-2026-brightgreen)

Stand-alone collecting tools for GNU/Linux
- Very low impact on the host
- No use of host binaries (anti hooking)
  - all binaries are included in the executable
- Export in JSON format (logs) / raw (RAM dump) and text format
- RAM dump with AVML (ref to compatibility https://github.com/microsoft/avml#tested-distributions)
- The result is a compressed archive and a checksum file

---

## Architecture

```
DFIR_Linux_Collector/
├── dlc.sh              → Generic engine (~290 lines)
├── rules.json          → Collection rules (YAML-like JSON)
├── scripts/            → External scripts (firefox, chrome, ssh, zeitgeist, etc.)
├── tools/              → Bundled binaries (avml, sqlite3)
├── bootstrap.sh        → Standalone launcher
└── Makefile            → Build makeself archive
```

### How it works

1. `dlc.sh` reads `rules.json` via bundled `jq`
2. User selects a mode (Light / Medium / Full)
3. Engine iterates over categories for the selected mode
4. Each command is executed, formatted to JSON, enriched with metadata
5. Complex functions (antivirus, kernel, RAM, etc.) remain in bash
6. External scripts (browsers, SSH, etc.) are called directly

### Supported rule formats

| Format | Description | Example |
|---|---|---|
| `wrap` | Text output → wrapped in `{"key": "value"}` | `uname -a`, `uptime` |
| `jsonl` | Output → JSONL via awk formatter → array | `env`, `lsmod`, `ps` |
| `raw` | Raw copy to text file | `lsof` |
| `function` | Dedicated bash function (complex logic) | `antivirus`, `dump_ram` |
| `scripts` | External scripts call | `firefox.sh`, `c_ssh.sh` |

### Adding a new rule

Add a block to `rules.json` in category `generic`, `network` or `process`:

```json
{ "name": "hostname", "cmd": "hostname", "output": "gen_hostname.json", "format": "wrap", "key": "hostname" }
```

For tabular data requiring awk formatting:

```json
{ "name": "timedatectl", "cmd": "timedatectl", "output": "gen_timedate.json", "format": "jsonl", "formatter": "fmt_timedate", "key": "timedate" }
```

Then create the `fmt_timedate` function in `dlc.sh`:

```bash
function fmt_timedate() {
    awk -F: '{gsub(/^[[:space:]]+/, "", $1); gsub(/^[[:space:]]+/, "", $2); print "{\"key\": \""$1"\", \"value\": \""$2"\"}"}'
}
```

### Collection modes

| Mode | Included categories |
|---|---|
| **Light** | generic, network, process, user, artefactsDistribution, exportRawKernelArtefacts, antivirus |
| **Medium** | Light + interestFile (MD5 hashes, SUID/SGID, timeline) |
| **Full** | Medium + dump_ram (AVML) |

Defined in `rules.json` — no code modification required.

---

## Compatibility

| Distribution | Version | OK | Error | Comments |
|---|---|---|---|---|
| Ubuntu | 12 - 20 | ✓ | --- | --- |
| Debian | > 8 | ✓ | --- | --- |
| Debian | 13 (Trixie) | ✓ | --- | --- |
| Fedora | 30 | ✓ | --- | --- |
| CentOS | 7 | ✓ | --- | --- |
| CentOS | 6 | --- | ✗ | Kernel too old |

Other distributions not yet tested, still in progress ...

---

## Bundled components versions

| Component | Version |
|---|---|---|
| Alpine Linux | **v3.23.4** (Apr 2026) |
| busybox | **1.37.0** (static) |
| apk-tools-static | **3.0.6-r0** |
| jq | **1.8.1-r0** |
| patchelf | **0.18.0-r0** |

---

## Quick start

![](dlc.gif)

```
git clone https://github.com/xophidia/DFIR_Linux_Collector.git
cd DFIR_Linux_Collector
./setup.sh
```

```
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
    +  uname ....................✓
    +  env ......................✓
    +  uptime ...................✓
    ...
```

---

## Collected artifacts

### Generic

| Command / File | Json | Text | Raw |
|---|---|---|---|
| env | ✓ | --- | --- |
| uptime | ✓ | --- | --- |
| uname -a | ✓ | --- | --- |
| lsmod | ✓ | --- | --- |
| /etc/passwd | ✓ | --- | --- |
| /etc/group | ✓ | --- | --- |
| date | ✓ | --- | --- |
| who | ✓ | --- | --- |
| cpuinfo | ✓ | --- | --- |
| lsof | --- | ✓ | --- |
| sudoers | ✓ | --- | --- |
| mount | ✓ | --- | --- |
| fstab | ✓ | --- | --- |
| last | ✓ | --- | --- |
| timedatectl | --- | ✓ | --- |
| lastlog | ✓ | --- | --- |
| hostname | ✓ | --- | --- |

### SSH

| Command / File | Json | Text | Raw |
|---|---|---|---|
| authorized_keys | ✓ | --- | --- |
| known_hosts | ✓ | --- | --- |

### Network

| Command / File | Json | Text | Raw |
|---|---|---|---|
| ip | ✓ | --- | --- |
| netstat | ✓ | --- | --- |
| arp | ✓ | --- | --- |
| ss (sockets) | ✓ | --- | --- |
| lsof -i | --- | ✓ | --- |

### Process

| Command / File | Json | Text | Raw |
|---|---|---|---|
| ps | ✓ | --- | --- |
| docker ps | ✓ | --- | --- |
| systemctl services | ✓ | --- | --- |

### Browser

| Command / File | Json | Text | Raw |
|---|---|---|---|---|
| Firefox | ✓ | --- | --- |
| Google Chrome | ✓ | --- | --- |
| Chromium | ✓ | --- | --- |

### Applications

| Command / File | Json | Text | Raw |
|---|---|---|---|---|
| FileZilla (servers.xml, recentservers.xml) | ✓ | --- | ✓ |
| Zeitgeist (last 200 activities) | ✓ | --- | --- |
| Developer history (.mysql, .psql, .sqlite, .nano, .lesshst, .wget-hsts, .bashrc) | ✓ | --- | ✓ |

### Logs

| Command / File | Json | Text | Raw |
|---|---|---|---|
| auth.log | --- | ✓ | --- |
| syslog | ✓ | --- | --- |

### Home

| Command / File | Json | Text | Raw |
|---|---|---|---|
| .gitconfig | ✓ | --- | --- |
| .command_history (bash + zsh) | ✓ | --- | ✓ |
| .viminfo | --- | ✓ | --- |

### Desktop

| Command / File | Json | Text | Raw |
|---|---|---|---|
| trash | --- | --- | ✓ |
| frequent apps (GNOME) | ✓ | --- | --- |

### Files

| Command / File | Json | Text | Raw | Csv |
|---|---|---|---|---|
| MD5 hashes | ✓ | ✓ | --- | --- |
| SUID/SGID permissions | ✓ | --- | --- | --- |
| timeline | --- | --- | --- | ✓ |

### Dump

| Command / File | Json | Text | Raw |
|---|---|---|---|
| AVML (RAM) | --- | --- | ✓ |
| LiME | ✗ | ✗ | ✗ |
| /boot/System.map-$(uname -r) | --- | --- | ✓ |
| /boot/vmlinuz | --- | --- | ✓ |

### Antivirus

| Command / File | Json | Text | Raw |
|---|---|---|---|
| ClamAV | ✓ | --- | --- |

---

## License

GNU Lesser General Public License

## Contributors

:godmode: xophidia https://github.com/xophidia  
:godmode: Dupss https://github.com/dupss  
:godmode: leludo84 https://github.com/leludo84
