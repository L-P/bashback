#!/usr/bin/env bash
# bashback by Léo Peltier <contact@leo-peltier.fr>
# A collection of bash functions to use in backup scripts.
# Licensed under the BSD 2-Clause license, please see the LICENSE file.

txtblu='\e[0;34m' # Blue
txtrst='\e[0m'    # Text Reset
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txttab='\e[60G'   # Tab

# Logs something to stdout
function bb::log() {
	echo -e "$txtblu[BB $(date +%s)]$txtrst $@"
}


# Logs something to stderr
function bb::error() {
	echo -e "$txtred[BB $(date +%s)]$txtrst $@" 1>&2
}


# Outputs the current date in a proper format
function bb::date() {
	date --rfc-3339=s | sed 's/ /_/g'
}


# Uses tar on all folders contained in a remote folder.
# bb::tar_folders [login@]host dir_remote dir_local
function bb::tar_folders() {
	local ssh="ssh $1"
	local dir_remote="$2"
	local dir_local="$3"
	local date="$(bb::date)"
	local error=0

	for folder in $($ssh "cd '$dir_remote' && find ./* -maxdepth 0 -type d"); do
		local folder="$(basename "$folder")"
		local archive="$dir_local/${folder}_$(bb::date).tar.bz2"

		bb::log "Archiving $1:$dir_remote/$folder"
		$ssh "cd '$dir_remote' && tar -cO '$folder'" | bzip2 > "$archive"

		if [ ! $? -eq 0 ]; then
			bb::error "Failed to archive $1:$dir_remote/$folder"
			error=$(($error+1))
		fi
	done

	return $error
}


# Rsync a remote folder to a local one.
# bb::rsync [login@]host:[remote_path] local_path
function bb::rsync() {
	local remote="$1"
	local local="$2"
	local options='-aq'
	local error=0

	bb::log "Rsync from $remote to $local"
	rsync $options $remote $local
	error=$?

	if [ ! $error -eq 0 ]; then
		bb::error "Failed to rsync $remote to $local"
	fi

	return $error
}


# Get the list of MySQL databases in a server.
# mysql and {performance,information}_schema will be omitted
# bb::mysql_fetch_databases host user pass
function bb::mysql_fetch_databases() {
	local host="$1"
	local user="$2"
	local pass="$3"

	echo "show databases;" | mysql -h$host -u$user -p$pass -N | grep -Ev '^(mysql|performance_schema|information_schema)$'
}


# Dumps the schema of a MySQL database.
# bb::mysql_dump_schema host user pass local_dir
function bb::mysql_dump_schema() {
	local host="$1"
	local user="$2"
	local pass="$3"
	local error=0
	local options="$5"
	cd "$4"

	# Notice the -d
	options="$options --single-transaction --flush-logs --dump-date --routines --events -d"

	for db in $(bb::mysql_fetch_databases $host $user $pass); do
		local local="$db.schema_$(bb::date).sql"
		bb::log "Dumping schema of $host:$db"
		mysqldump -h$host -u$user -p$pass $options $db > $local

		if [ ! $? -eq 0 ]; then
			bb::error "Failed to dump schema of $host:$db"
			error=$(($error+1))
		else
			# Compress after the dump to avoid locking tables during the compression.
			bzip2 $local
		fi
	done

	return $error
}


# Dumps the data of a MySQL database.
# bb::mysql_dump_data host user pass local_dir
function bb::mysql_dump_data() {
	local host="$1"
	local user="$2"
	local pass="$3"
	local error=0
	local options="$5"
	cd "$4"

	# Notice the -t and the -q, we don't want to fill the RAM
	options="$options --single-transaction --flush-logs --dump-date --routines --events -q -t"

	for db in $(bb::mysql_fetch_databases $host $user $pass); do
		local local="$db.data_$(bb::date).sql"
		bb::log "Dumping data of $host:$db"
		mysqldump -h$host -u$user -p$pass $options $db > $local

		if [ ! $? -eq 0 ]; then
			bb::error "Failed to dump data of $host:$db"
			error=$(($error+1))
		else
			bzip2 $local
		fi
	done

	return $error
}


# Dumps a whole MySQL server.
# bb::mysql_dump host user pass local_dir
function bb::mysql_dump(){
	local host="$1"
	local user="$2"
	local pass="$3"
	local path="$4"
	local options="$5"
	local error=0

	bb::mysql_dump_schema $host $user $pass $path $options
	error=$?
	bb::mysql_dump_data $host $user $pass $path $options
	error=$(($error+$?))
	return $error
}


# Deletes all files in a directory older than n days.
function bb::purge() {
	local dir="$1"
	local days="$2"

	find "$dir" -maxdepth 1 -type f -mtime +$days -delete
}

