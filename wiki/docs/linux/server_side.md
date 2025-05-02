# Server Side

Tools and things I use for backend and server side management. 

## Restic
Restic is a super simple backup tool. It's a CLI only tool, but it's so famous that there are a bunch of GUI forks. 
It also has a very wide backend support. I use [S3 storage](./../development#minio) for my set up.

First, I need to export the following variables to the OS (since this is super sensitive data, disable your shell history):
```bash
unset HISTFILE
export AWS_ACCESS_KEY_ID=<MINIO_ACCESS_KEY>
export AWS_SECRET_ACCESS_KEY=<MINIO_SECRET_KEY>
export RESTIC_REPOSITORY="s3:http://your_minio_ip:1234/bucket"
export RESTIC_PASSWORD="your_restic_password"
```
Or to make variables permanent, add them to your `.zshrc` or `.bashrc` file. 

The access key and secret you get from Minio. The repo is the URL to the Minio bucket. Initialize the repo:
```bash
restic init 
```

If everything is correct, you should receive in stdout a message that the repo is created. To backup, run `restic backup`
and the path you want to back up:
```bash
restic backup /path/to/backup
```

You can then check your snapshots with:
```bash
restic snapshots
```
:::tip
If your machine blows up, you can access the restic repo by just using the S3 creds, url, and your repo password. 
Keep your password somewhere accessible. 
:::

### Scheduled backups and change detection
Restic automatically detects if there are changes in the backed-up files. 
You can also skip making a new snapshot adding the flag `--skip-if-unchanged` (**This seems to be deprecated now!**).

Additionally, if you want to turn off change detection,
you can add the flag `--force`.

Restic does not have a scheduler, but if you set up the environmental variables, you can run cron jobs. 
Check [crontab guru](https://crontab.guru/) to generate your own retentions. 

I recommend making scripts that cron runs instead of running restic commands directly. 
You can also add a cleanup policy in your script if you don't need to keep all snapshots. Make sure the script is executable:
```bash title="~/backup.sh"
#!/bin/zsh

#Backup job
restic backup /path/to/backup

#Cleanup job
restic forget --keep-within-weekly 5d

```
```bash
chmod +x ~/backup.sh
```
```plaintext title="crontab -e"
0 0 1 * * ~/backup.sh
```

## Mounting Full Disk

When installing ubuntu server, sometimes, it might skip to allocating the full disk the partition (probably if you add the boot drive to a LVM group). You can extend the filesystem by:

Check the volume group first to confirm it's not fully using the disk:

```bash
vgdisplay
```

Extend the partition:

```bash
lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
```

And resize the filesystem:

```bash
resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```

Make sure the device paths are correct. You can check with `df -T` for your device paths. You will need root privileges.

## Ranger / LF Keybindings

`ranger` and `lf` are tools for visual directory management. Basically a file explorer for CLI. Here are the keybindings for `ranger`:

**MAIN** **BINDINGS** 

```plaintext
h, j, k, l    Move left, down, up or right

^D or J, ^U or K 	Move a half page down, up

H, L          Move back and forward in the history

gg            Move to the top

G             Move to the bottom

^R            Reload everything

^L            Redraw the screen

i             Display the current file in a bigger window.

E             Edit the current file in $EDITOR ("nano" by default)

S             Open a shell in the current directory

?             Opens this man page

<octal>=, +<who><what>, -<who><what>    Change the permissions of the selection.  
For example, "777=" is equivalent
to "chmod 777 %s", "+ar" does "chmod a+r %s", "-ow" does "chmod o-w %s" etc.

yy            Copy (yank) the selection, like pressing Ctrl+C in modern GUI programs.

dd            Cut the selection, like pressing Ctrl+X in modern GUI programs.

pp            Paste the files which were previously copied or cut, like pressing Ctrl+V in
                     modern GUI programs.

 po           Paste the copied/cut files, overwriting existing files.

mX            Create a bookmark with the name X

`X            Move to the bookmark with the name X

n             Find the next file.  By default, this gets you to the newest file in the
 directory, but if you search something using the keys /, cm, ct, ...,
 it will get you to the next found entry.

N             Find the previous file.

oX            Change the sort method (like in mutt)

zX            Change settings.  See the settings section for a list of settings and their hotkey.

u?            Universal undo-key.  Depending on the key that you press after "u", it
                     either restores closed tabs (uq), removes tags (ut), clears the copy/cut
                     buffer (ud), starts the reversed visual mode (uV) or clears the selection
                     (uv).

f             Quickly navigate by entering a part of the filename.

Space         Mark a file.

v             Toggle the mark-status of all files

V             Starts the visual mode, which selects all files between the starting point
                     and the cursor until you press ESC.  To unselect files in the same way, use
                     "uV".

/             Search for files in the current directory.

:             Open the console.

Alt-N         Open a tab. N has to be a number from 0 to 9. If the tab doesn't exist yet,
                     it will be created.

gn, ^N        Create a new tab.

gt, gT        Go to the next or previous tab. You can also use TAB and SHIFT+TAB instead.

gc, ^W        Close the current tab.  The last tab cannot be closed this way.
```

## Network management with Netplan

You can manage networking and network configurations with netplan. It uses .yaml configs and applies the settings and configurations using either NetworkManager or systemd-networkd. The configurations are saved in `/etc/netplan`.

You can network status and configurations with `netplan status`.

Here is an example config for static IP:

```yaml title="/etc/netplan/01-eth0-static.yaml"
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.11.100.155/24]
      gateway4: 10.11.100.1
      nameservers:
        addresses: [1.1.1.1]
```

You can try if a configuration works with `netplan try` and then apply it with `netplan apply`.