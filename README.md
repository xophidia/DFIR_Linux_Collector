# DFIR_Linux_Collector

Stand-alone collecting tools for Gnu/Linux
- Very low impact on the host
- No use of host binaries (anti hooking)
  - all binaries are included in the executable
- Export in json format (log) / raw (dump ram) and Text format
- Dump ram with avml (ref to compatilibilty https://github.com/microsoft/avml#tested-distributions)
- The result is a compressed archive

## Compatibility



| Distribution | Version | Ok | Error | Comments | 
| --- | --- | --- | --- | ---| 
| Ubuntu | 12 - 20 | :heavy_check_mark: |  --- | --- |
| Debian | > 8 | :heavy_check_mark: |  --- | --- |
| Fedora | 30| :heavy_check_mark: |  --- | --- |
| CentOS | 7| :heavy_check_mark: |  --- | --- |

The other distributions are not yet tested, still in progress ...


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
    +  lsmod ....................[success]
    +  passwd ...................[success]
    +  auth .....................[success]
    +  syslog ...................[success]
    +  date .....................[success]
    +  who ......................[success]
    +  cpuinfo ..................[success]
    +  group ....................[success]
    +  lsof .....................[success]
    +  mount ....................[success]
    +  sudoers ..................[success]


    Dump network artifacts
    +  ip .......................[success]
    +  netstat ..................[success]
    +  arp ......................[success]

    
    Dump process artifacts
    +  ps .......................[success]

    
    Dump user artifacts
    +  c_ssh ....................[success]
    +  firefox ..................[success]
    +  c_git ....................[success]
    +  chromium .................[success]
    +  google-chrome ............[success]
    +  command_history ..........[success]

    Dump artefacts / linux distribution
    +  Debian-like artifacts 
    +  installer debug ..........[success]
    +  installer syslog .........[success]

```

### Artifacts

:radio_button: Generic

| Command / file | Json | Text | Raw | 
| --- | --- | --- | --- |
| env | :heavy_check_mark: | --- | --- |
|uptime| :heavy_check_mark: | --- | --- |
|uname -a| :heavy_check_mark: | --- | --- |
|lsmod|  :heavy_check_mark: | --- | --- |
|/etc/passwd| :heavy_check_mark:  | --- | --- |
|/etc/group| :heavy_check_mark: | --- | --- |
|date| :heavy_check_mark: | --- | --- |
|who |:heavy_check_mark: | --- | --- |
|cpuinfo| :heavy_check_mark: | --- | --- |
|lsof| --- |  :heavy_check_mark: | --- |
|sudoers| :heavy_check_mark: | --- | --- |
|file -o=w -g=s | :heavy_check_mark: | --- | --- |
|mount| :heavy_check_mark: | --- | --- |
|fstab| :heavy_check_mark: | --- | --- |
|last| :heavy_check_mark: | --- | --- |

:radio_button: Ssh

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| authorized_keys | :heavy_check_mark: | --- | --- |
| known_hosts | :heavy_check_mark: | --- | --- |


:radio_button: Network

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| ip | :heavy_check_mark: | --- | --- |
| netstat | :heavy_check_mark: | --- | --- |
| arp | :heavy_check_mark: | --- | --- |

:radio_button: Processus

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| ps | :heavy_check_mark: | --- | --- |

:radio_button: Browser

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| Firefox | :heavy_check_mark: | --- | --- |
| Google Chrome | :heavy_check_mark: | --- | --- |
| Chromium | :heavy_check_mark: | --- | --- |

:radio_button: Log

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| auth.log | --- | :heavy_check_mark: | --- |
| syslog| :heavy_check_mark: | --- | --- |

:radio_button: Home

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| .gitconfig | :heavy_check_mark: | --- | --- |
| .command_history (bash + zsh) | :heavy_check_mark: | --- | --- |
| .viminfo | --- | :heavy_check_mark: | --- |

:radio_button: Files

| Command / file | Json | Text | Raw | Csv |
| --- | --- | --- | --- | --- |
| hashes MD5 | :heavy_check_mark: | :heavy_check_mark: | --- | --- |
| file -o=w -g=s | :heavy_check_mark: | --- | --- | --- |
| timeline | --- | --- | --- |:heavy_check_mark:|

:radio_button: Dump

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| avml | --- | --- | :heavy_check_mark: |
| LiME | :heavy_multiplication_x: | :heavy_multiplication_x: | :heavy_multiplication_x: |
| /boot/System.map-$(uname -r)   | --- | --- | :heavy_check_mark: |
| /boot/vmlinuz | --- | --- | :heavy_check_mark: |

:radio_button: Antivirus

| Command / file | Json | Text | Raw |
| --- | --- | --- | --- |
| ClamAV | :heavy_check_mark: | --- | --- |


## How to configure

Add the chosen method to the list to enable this action

Ex: add dump_ram() at the end of list_method 
```
list_method=(generic network process user artefactsDistribution exportRawKernelArtefacts antivirus interestFile dump_ram)
```
Then you need to make again

```
sudo make
sudo ./DFIR_linux_collector
```

All methods are in dlc.sh

## License


All the code of the project is licensed under the GNU Lesser General Public License


## Contributors 

:godmode: xophidia https://github.com/xophidia  
:godmode: Dupss https://github.com/dupss  
:godmode: leludo84 https://github.com/leludo84  

