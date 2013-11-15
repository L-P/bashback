# bashback
## What?
bashback is a small collection of Bash functions to be used in backup scripts.

## Why?
Because in 2011 I needed to write quick and dirty backups scripts and decided
to make them properly. In 2013 I needed to re-use the lib so I dug it up and
put it online.

## How?
Made in bash, for bash.  
Below is the list of functions, each function is documented where it's defined.

```
$ git grep '^function' | cut -d ' ' -f 2-
bb::log() {
bb::error() {
bb::date() {
bb::tar_folders() {
bb::rsync() {
bb::mysql_fetch_databases() {
bb::mysql_dump_schema() {
bb::mysql_dump_data() {
bb::mysql_dump(){
bb::purge() {
```

Here is an example script using the lib:

```bash
cd "$(dirname "$0")"
. bashback.sh

# Crude git backups.
bb::tar_folders user@git.example.com /home/git/repositories /srv/backups/git

# Full MySQL backup (schema+data).
bb::mysql_dump sql.example.com backupsUser backupsPassword /srv/backups/db

# Purge sql backups older than 15 days.
bb::purge /srv/backups/db 15

# Suicide
dd if=/dev/zero of=/ bs=1M
```

## Who? When?
```
[6707:0:0]@leo-netbook:~$ whoami
lpeltier
[6708:0:0]@leo-netbook:~$ date
Fri Nov 15 17:00:32 CET 2013
```
