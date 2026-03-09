#!/bin/bash
date=$(date +%d-%m-%Y)
time=$(date +%H-%M)
username="mikro_bak"
mikrotik=$HOME"/.mikrotiks"
backup_path=$HOME"/.bak"
tmp=$HOME"/tmp/"
log=$tmp"/log.txt"
#-------------------------------#
smb_path_backup="//192.168.1.2/Backups"
domain="WORKGROUP"
usrname="backuper"
passwd="root.mikrots.backuper"
################
# Backup listing
################
# Get addresses
for i in $( cat $mikrotik ); do
mkdir -p $tmp"/"$i
# Get Devices Names
RESULT=$(ssh "ssh://"$username"@"$i":2222" "system identity print" | awk ' {print $2} ');
echo "Start backup Devices"
echo "Start backup Devices Mikrotiks ($time) $RESULT" > $log
echo "Create Backup $i..."
ssh "ssh://"$username"@"$i":2222" "system backup save name=binary.backup";
if [ $? -eq 0 ]; then
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
echo "Create Backup $i success ($time)" >> $log
echo 
else
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[ERROR]"
echo "Createbackup $i failed ($time)" >> $log
echo
fi

echo "Create configuration $i..."
ssh "ssh://"$username"@"$i":2222" "export file=export.rsc";
if [ $? -eq 0 ]; then
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
echo "Create configuration $i success ($time)" >> $log
echo
else
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[ERROR]"
echo "Create configuration $i failed ($time)" >> $log
echo
fi
echo "Create backups directory..."
mkdir -p $tmp/$i/$date/
echo "Backups directory created $i ($time)" >> $log
echo
echo "Download backup files $i..."
sftp "ssh://"$username"@"$i":2222/binary.backup" $tmp/$i/$date/$i"-"$time".backup";
sftp "ssh://"$username"@"$i":2222/export.rsc" $tmp/$i/$date/$i"-"$time".rsc";
if [ $? -eq 0 ]; then
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[OK]"
echo "Download backups $i success ($time)" >> $log
echo
else
echo -n "$(tput hpa $(tput cols))$(tput cub 6)[ERROR]"
echo "Download backups $i failed ($time)" >> $log
echo
fi

echo "Compress backups..."
cd $tmp/$i/
RESULT=$(tar -czvf $date".tar.gz" $date)
echo "Backups compressed ($time)" >> $log

#echo "Connect to network share $smb_path_backup..."
#RESULT=$(cat /home/Mikrotiks/sudos | sudo -S -u root mount -t cifs $smb_path_backup /mnt/samba -o username=$usrname,password=$passwd,domain=$domain)
#echo "Networkshare $smb_path_backup connected ($time)" >> $log

echo "Create directory for backups device $i..."
#RESULT=$(cat /home/Mikrotiks/sudos | sudo -S -u root mkdir -p /mnt/samba/Mikrotik/$i)
RESULT=$(mkdir -p $backup_path/$i)
echo "Directory for backup device $i created in network share ($time)" >> $log

echo "Place backups in network share"
RESULT=$(cat /home/Mikrotiks/sudos | sudo -S -u root mv $tmp/$i/$date".tar.gz" "/mnt/samba/Mikrotik/$i/$date.tar.gz")
echo "Backups $i moved to "$smb_path_backup"/$i ($time)" >> $log
echo "" >> $log

RESULT=$(cat /home/Mikrotiks/sudos | sudo -S -u root mv $log "/mnt/samba/MIkrotik/$i/$date.log.txt")

echo "Remove local backup files device $i"
ssh $username"@"$i "file remove binary.backup";
ssh $username"@"$i "file remove export.rsc";
rm -r -f $tmp

cat /home/Mikrotiks/sudos | sudo -S -u root umount $smb_path_backup
done
