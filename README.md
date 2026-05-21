# DFIR_Linux_Collector
![GitHub last commit](https://img.shields.io/github/last-commit/xophidia/DFIR_Linux_Collector) ![GitHub release-date](https://img.shields.io/github/release-date/xophidia/DFIR_Linux_Collector)

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
├── scripts/            → External scripts (firefox, chrome, ssh, etc.)
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
| Ubuntu | 12 - 20 | :heavy_check_mark: | --- | --- |
| Debian | > 8 | :heavy_check_mark: | --- | --- |
| Debian | 13 (Trixie) | :heavy_check_mark: | --- | --- |
| Fedora | 30 | :heavy_check_mark: | --- | --- |
| CentOS | 7 | :heavy_check_mark: | --- | --- |
| CentOS | 6 | --- | :heavy_multiplication_x: | Kernel too old |

Other distributions not yet tested, still in progress ...

---

## Bundled components versions

| Component | Version |
|---|---|
| Alpine Linux | **v3.23.4** (Apr 2026) |
| busybox | **1.37.0** (static) |
| apk-tools-static | **3.0.6-r0** |
| jq | **1.8.1-r0** |

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
    +  uname ....................[success]
    +  env ......................[success]
    +  uptime ...................[success]
    ...
```

---

## Collected artifacts

### Generic

| Command / File | Json | Text | Raw |
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

| Command / File | Json | Text | Raw |
|---|---|---|---|
| authorized_keys | :heavy_check_mark: | --- | --- |
| known_hosts | :heavy_check_mark: | --- | --- |

### Network

| Command / File | Json | Text | Raw |
|---|---|---|---|
| ip | :heavy_check_mark: | --- | --- |
| netstat | :heavy_check_mark: | --- | --- |
| arp | :heavy_check_mark: | --- | --- |

### Process

| Command / File | Json | Text | Raw |
|---|---|---|---|
| ps | :heavy_check_mark: | --- | --- |

### Browser

| Command / File | Json | Text | Raw |
|---|---|---|---|
| Firefox | :heavy_check_mark: | --- | --- |
| Google Chrome | :heavy_check_mark: | --- | --- |
| Chromium | :heavy_check_mark: | --- | --- |

### Logs

| Command / File | Json | Text | Raw |
|---|---|---|---|
| auth.log | --- | :heavy_check_mark: | --- |
| syslog | :heavy_check_mark: | --- | --- |

### Home

| Command / File | Json | Text | Raw |
|---|---|---|---|
| .gitconfig | :heavy_check_mark: | --- | --- |
| .command_history (bash + zsh) | :heavy_check_mark: | --- | :heavy_check_mark: |
| .viminfo | --- | :heavy_check_mark: | --- |

### Desktop

| Command / File | Json | Text | Raw |
|---|---|---|---|
| trash | --- | --- | :heavy_check_mark: |
| frequent apps (GNOME) | :heavy_check_mark: | --- | --- |

### Files

| Command / File | Json | Text | Raw | Csv |
|---|---|---|---|---|
| MD5 hashes | :heavy_check_mark: | :heavy_check_mark: | --- | --- |
| SUID/SGID permissions | :heavy_check_mark: | --- | --- | --- |
| timeline | --- | --- | --- | :heavy_check_mark: |

### Dump

| Command / File | Json | Text | Raw |
|---|---|---|---|
| AVML (RAM) | --- | --- | :heavy_check_mark: |
| LiME | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_multiplication_x: |
| /boot/System.map-$(uname -r) | --- | --- | :heavy_check_mark: |
| /boot/vmlinuz | --- | --- | :heavy_check_mark: |

### Antivirus

| Command / File | Json | Text | Raw |
|---|---|---|---|
| ClamAV | :heavy_check_mark: | --- | --- |

---

## License

GNU Lesser General Public License

## Contributors

:godmode: xophidia https://github.com/xophidia  
:godmode: Dupss https://github.com/dupss  
:godmode: leludo84 https://github.com/leludo84
