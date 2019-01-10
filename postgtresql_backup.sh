#!/bin/sh
echo "" > /tmp/db_backup.log
echo "" > /tmp/db_backup_info.log
date_str=$(date +"%Y%m%d_%H%M%S")
backup_dir=/var/lib/postgresql/backup/psql_backup_$date_str

mkdir $backup_dir

databases=`sudo -u postgres psql -Upostgres -lt | grep -v : | cut -d \| -f 1 | grep -v template | grep -v postgres | grep -v -e '^\s*$' | sed -e 's/  *$//'|  tr '\n' ' '`
echo "Will be backed up: $databases to $backup_dir" >> /tmp/db_backup_info.log
for db in $databases; do
  echo "Starting databases backup for $db" >> /tmp/db_backup_info.log
  filename=$db.$date_str.sql
  dbfolder=$db
  mkdir $backup_dir/$dbfolder
  sudo -u postgres vacuumdb --analyze -Upostgres $db >> /tmp/db_backup.log
  sudo -u postgres pg_dump -Upostgres -v $db -F p 2>> /tmp/db_backup.log > $backup_dir/$dbfolder/$filename
  size=`stat $backup_dir/$dbfolder/$filename --printf="%s"`
  kb_size=`echo "scale=2; $size / 1024.0" | bc`
  echo "Finished backup for $db - size is $kb_size KB" >> /tmp/db_backup_info.log
done

echo "Backup completed!" >> /tmp/db_backup_info.log

su - root -c "rsync -avh --update /var/lib/postgresql/backup/psql_backup_*/* /data/backup/postgresql/"
