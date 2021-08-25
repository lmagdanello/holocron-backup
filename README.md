# Holocron

Holocron is a shell script designed to back up remote directories on a local machine, with tar.gz compression.

Holocron works using a few different tools. With a yaml configuration file (/etc/holocron/holocron.yaml), you can define the remote servers, the remote directory to be backed up and the local directory where it will be saved.

---
yq version: https://github.com/mikefarah/yq/releases/tag/3.4.0

Install yq:
```console
wget https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
```
---

- holocron.yaml template:

```console
---
servers:
  types:                                <-- types of servers (can be logins, managements nodes, etc...)
   jedi: 
     - luke                             <-- servers (RSA key required)
     - yoda
   sith:
     - vader
     - sidious 
sources:                                <-- remote dir to be backup
  - /naboo
destiny: /coruscant                     <-- local dir where it will be saved
mail: false                             <-- works with the mail function, to send an email with the status of the backup - switch to 'true' for thath
to: death-start@GalacticEmpire.com      <-- destination email
source: darth-vader@GalacticEmpire.com  <-- source mail
```
--- 
To install, clone the repo and give execute permissions to the holocron.sh script (chmod +x holocron.sh) and execute:

```console
./holocron.sh -i || ./holocron.sh --install
```

This will create a template file in /etc/holocron/holocron.yaml. Change it as needed. Be careful with indentation (yaml).
A log file will also be created (/var/log/holocron/holocron.log), which saves the start date of the backup, the servers and the time spent running;

---
##### Feel free to change the script to your needs.
---
TO-DO:
- [ ] E-mail template
- [ ] Tuning transfer, because is taking a long time yet
---

Author:
*Leonardo Araujo - leonardo.araujo@atos.net*
