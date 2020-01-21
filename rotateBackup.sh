#!/bin/bash

#
# Schu's backup rotation script
#

# get config
if [ -f /etc/rotateBackup.conf ]; then
  . /etc/rotateBackup.conf
else
  echo "Can't open config file"
  exit
fi

# get date
DATE=`date +%Y%m%d%H%M%S`

# make sure we're running as root
if (( `id -u` != 0 )); then { echo "Sorry, must be root.  Exiting..."; exit; } fi

# if the excludes file does exist then touch it
if [ ! -f $EXCLUDES ]; then
  touch $EXCLUDES
fi

# if the includes file does exist then touch it
if [ ! -f $INCLUDES ]; then
  touch $INCLUDES
fi

if [ -n "$BWLIMIT" ]; then
  LIMIT="--bwlimit=$BWLIMIT"
fi

echo "#################################################"
echo "# Staring backup at `date`"
# now find the existing snapshots
if [ -z "$REMOTEHOST" ]; then
  echo "# Destination $BACKUPDEST on localhost"
  SNAPSHOTS=`ls -c $BACKUPDEST | egrep "^$PREFIX-" 2>/dev/null`
else
  echo "# Destination $BACKUPDEST on $REMOTEHOST"
  SNAPSHOTS=`ssh $REMOTEHOST "ls -c $BACKUPDEST | egrep \"^$PREFIX-\" 2>/dev/null"`
fi
echo "#################################################"

# delete expired snapshots and add the rest to an array
if [ ! -z "$SNAPSHOTS" ]; then
  COUNT=1
  for SNAPSHOT in $SNAPSHOTS; do
    if [ "$COUNT" -lt "$ROTATIONS" ]; then
      OLDSNAPSHOTS[$COUNT]=$SNAPSHOT
    else 
      echo
      echo "Removing $BACKUPDEST/$SNAPSHOT"
      if [ -z "$REMOTEHOST" ]; then
        time rm -rf $BACKUPDEST/$SNAPSHOT
      else
        time ssh $REMOTEHOST "rm -rf $BACKUPDEST/$SNAPSHOT"
      fi
    fi
    ((COUNT++))
  done
fi

# create the new snapshot directory
NEWSNAPSHOT="$PREFIX-$DATE"
if [ -z "$REMOTEHOST" ]; then
  mkdir $BACKUPDEST/$NEWSNAPSHOT
else
  ssh $REMOTEHOST "mkdir $BACKUPDEST/$NEWSNAPSHOT"
fi

# copy the last snapshot to the current one using hard links
if [ ! -z ${OLDSNAPSHOTS[1]} ]; then
  echo
  echo "Copying hardlinks from $BACKUPDEST/${OLDSNAPSHOTS[1]}/ to $BACKUPDEST/$NEWSNAPSHOT"
  if [ -z "$REMOTEHOST" ]; then
    time cp -al $BACKUPDEST/${OLDSNAPSHOTS[1]}/* $BACKUPDEST/$NEWSNAPSHOT
  else
    time ssh $REMOTEHOST "cp -al $BACKUPDEST/${OLDSNAPSHOTS[1]}/* $BACKUPDEST/$NEWSNAPSHOT"
  fi
fi

# rsync from the system into the latest snapshot rync behaves like 
# cp --remove-destination by default, so the destination is unlinked first.
echo
echo "Rsync system to $BACKUPDEST/$NEWSNAPSHOT"
if [ -z "$REMOTEHOST" ]; then
  time rsync -va -r --delete --delete-excluded --files-from="$INCLUDES" --exclude-from="$EXCLUDES" $BACKUPSOURCE/ $BACKUPDEST/$NEWSNAPSHOT
else
  time rsync -e ssh $LIMIT -z -va -r --delete --delete-excluded --files-from="$INCLUDES" --exclude-from="$EXCLUDES" $BACKUPSOURCE/ $REMOTEHOST:$BACKUPDEST/$NEWSNAPSHOT
fi

echo "#################################################"
echo "# Backup complete at `date`"
echo "#################################################"

