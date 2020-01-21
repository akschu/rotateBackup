# rotateBackup
Simple rsync rotatebackup script.

rotateBackup.sh reads rotateBackup.conf and figures out what to use for number of rotations, prefix, source and destination directory, and also optionally a remote host server and bandwidth limit.

To backup from /dir1 to /dir2 simply use:

ROTATIONS=5
PREFIX=server
BACKUPSOURCE=/dir1
BACKUPDEST=/dir2
EXCLUDES=/etc/rotateBackup.excludes
INCLUDES=/etc/rotateBackup.includes

The define all of the files you want to include or exclude.  If you want everything then:

echo "*" > /etc/rotateBackup.includes

Suppose you want to backup an entire linux host to somewhere else:

ROTATIONS=5
PREFIX=servertobackup
BACKUPSOURCE=/
BACKUPDEST=/mnt/backupofserver
EXCLUDES=/etc/rotateBackup.excludes
INCLUDES=/etc/rotateBackup.includes

Then on the source server:

ls / | egrep -v "proc|sys|mnt" > /etc/rotateBackup.includes

Have Fun!
