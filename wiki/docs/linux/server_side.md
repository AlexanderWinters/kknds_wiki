# Server Side
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

## Background Processes and 'Hang-Ups'

**MOVE THIS DOCUMENTATION TO BE CENTRALIZED**

Running processes as background in bash is done by adding the ampersand `&` symbol at the end of a command. You can investigate the active background jobs by:

```bash
jobs
```

and you can bring a background process to foreground again by:

```bash
fg
```

Nonetheless, most of the processes one wants to run in background are done through SSH. That means that the process should not hang up when we disconnect and continue running in the background. We do that by passing `nohup` at the beginning of the command. In addition, it is useful to also pass the standard output and errors to a file, and also not wait for any standard input. Example:

```plaintext
nohup myscript.sh >myscript.log 2>&1 </dev/null &
#\__/             \___________/ \__/ \________/ ^
# |                    |          |      |      |
# |                    |          |      |  run in background
# |                    |          |      |
# |                    |          |   don't expect input
# |                    |          |   
# |                    |        redirect stderr to stdout
# |                    |           
# |                    redirect stdout to myscript.log
# |
# keep the command running 
# no matter whether the connection is lost or you logout 
```

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