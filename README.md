# trickle
:potable_water: A script to slowly copy files (namely photos and videos) from one system to another.

I'm getting into photography and want to back up my stuff. Here's how I get media off my camera currently:

1. Put a SD card into my computer.
2. Copy all photos to a local folder on my computer (this is usually a multi-gig transfer that can take as long as 10 minutes)
3. Mount my media server via ssh-fs as a local volume.
4. Manually sort through all the pictures, and dump the ones that were taken on any given day in that day's folder. Each transfer takes a really long time.
5. Once I'm sure that all my data has made it to the server, unmount the media server.

## My new method
```
================ LAN ====================        ======= WAN =======

-------------      ----------------------        -------------------
| My laptop |  =>  | A "trickle" server |  ====> | My media server |
-------------      ----------------------        -------------------
```

1. Put a SD card into my computer.
2. Copy all images to my "trickle" server over scp: `scp *.jpg trickle:/data`

Behind the scenes, this "trickle" server will slowly send data to my media server. Once an image has been completly copied over and the remote file has the same hash as the local file, the file is deleted. Best of all this all happens in the background so I don't have to tie up my laptop while this process is happening.

## Installing
1. Copy `trickle.sh` into your `PATH`.
2. Add the below files to their respective locations:
```
# /lib/systemd/system/trickle.service
[Unit]
Description=trickle data to the serial server
After=network.service

[Service]
ExecStart=trickle.sh /data
Type=oneshot
User=trickle
WorkingDirectory=/home/trickle

[Install]
WantedBy=multi-user.target
```

```
# /lib/systemd/system/trickle.timer
[Unit]
Description=timer for trickling data

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min

[Install]
WantedBy=app.target
```

3. Run `systemctl daemon-reload`.
4. Kick off a manual sync with `systemctl start trickle`
