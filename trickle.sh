#!/bin/bash
HOST=magnam # where to scp files, must be passwordless (ie, with a private key)
BASEPATH=/volumes/hdd0/raw # where to copy the media on the serverside
MOUNTEDAT="$(echo $1 | sed 's_/*$__')" # remove trailing slashes from the path

if [ "$MOUNTEDAT" ]; then
  # Move to the location of all the media
  # FROMPATH="$MOUNTEDAT/DCIM/100MSDCF"
  FROMPATH="$MOUNTEDAT"
  FILES=$(ls "$FROMPATH")

  # For each file...
  for i in $FILES; do
    FILE="$FROMPATH/$i"
    # NOTE: the below date command needs to change to work on linux
    DATE=$(date -r "$FILE")

    # Get date info
    YEAR="$(echo $DATE | awk '{ print $6 }')"
    MONTH="$(echo $DATE | awk '{ print $3 }')"
    DAY="$(echo $DATE | awk '{ print $2 }')"

    # Assemble the path on the server to put the given file.
    DIREC="$BASEPATH/$YEAR/$MONTH/$DAY"

    # Check to see if the image is already on the server before copying it over.
    FILE_EXISTS=$(ssh $HOST stat "$DIREC/$i" | sed -n '/File/p' 2> /dev/null)

    if [ "$FILE_EXISTS" ]; then
      echo "* $DIREC/$i already exists, skipping..."
    else

      # Create the directory, and copy the file.
      echo "* Creating $DIREC..."
      ssh $HOST mkdir -p $DIREC

      echo "* Copying $DIREC/$i..."
      rsync -avz --partial "$FILE" $HOST:"$DIREC/$i"

      # notate that the file was copied
      echo "$(date) %% $i" >> copied.out

      # If the file size on the server is the same as the file size locally, delete the local file.
      LOCAL_FILE_SIZE=$(stat "$FILE" | awk '/Size/ { print $2 }' 2> /dev/null)
      REMOTE_FILE_SIZE=$(ssh $HOST stat "$DIREC/$i" | awk '/Size/ { print $2 }' 2> /dev/null)
      if [ "$LOCAL_FILE_SIZE" = "$REMOTE_FILE_SIZE" ]; then
        echo "File $FILE exists on the server (and is the same size) as $DIREC/$i, removing from local disk..."
        rm -rf "$FILE"
      fi
    fi
  done
else
  echo "Usage: ./carder.sh /mount/point/to/card"
fi
