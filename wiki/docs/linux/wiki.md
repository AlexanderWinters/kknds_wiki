---
sidebar_position: 1
---

# General

## Installing/Updating

To get started, just rip the .iso and boot. Make sure all the settings in BIOS force UEFI boot (hardware needs to be compatible as well). You might need a hardwired internet connection. Run:

```bash
pacman -S archinstall
```

And then run `archinstall`. This is the closest you will get to a guided OS installation with Arch.
Alternatively, you can manually install with the official installation guide.

To update:

```bash
pacman -Syu
```

You can also check if you need to restart with:

```bash
checkservices
```

Or just compare the version of the kernel installed vs the version running:

```bash
pacman -Q linux
uname -a
```

If the kernels don't match, you need to reboot.

### Packages to get started (check arch-wiki too)

* **cronie / fcron**: Cron jobs, for automating stuff or running scripts every given time. To add/edit/remove jobs:
* **crontabs -e**
* **micro**: Basically the easiest text editor to use with a mouse. All commands are the same as in the OS. EG, ctrl + c is copy, ctrl + v is paste, ctrl + s is save, ctrl + q is quit, etc.
* **nano**: Another simple text editor
* **docker**: Container driver. Used in conjunction the orchestration tool, docker-compose. Docker Documentation.
* **git**: GIT cli client
* **gnome**: Desktop Environment. Also check gnome-extras, gnome-shell-extensions.
* **nftables**: Firewall rules. Good idea to replace iptables as they are slowly getting deprecated.
* **vnstat**: Network traffic monitor
* **wireshark-cli**: Packet sniffer. Use with termshark.
* **lf**: 'list-files' ... basically ranger.

## Useful Commands

Delete all empty folders:

```bash
find . -empty -type d -delete
```
## ZSH

Zsh is the superior shell, so use this instead of bash. All plugins and customizations for zsh happen in the `.zshrc` file in your home directory.

### Default console text editor

Edit `.bashsrc` and `.bash_profile`

Add:

```bash title="~/.bashrc OR ~/.bash_profile"
export EDITOR = [text_editor] #---this goes to bashrc
export VISUAL = [text_editor] #---this goes to bash_profile
```

If using different shell usually it's the same files to the corresponding shell, eg, for zsh it's `.zshrc` and `.zprofile`

### Change Default Shell

List all available shells:

```bash
chsh -l
```

Change:

```bash
chsh -s /path/to/shell
```

### To highlight folders:

```bash title="~/.zshrc"
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
```

### For shell suggestions

Install `zsh-autosuggestions` and source to the `.zshrc` file.

### For syntax highlighting

Install `zsh-syntax-highlighting` and source to the `.zshrc` file.

### For amazing cat

Install bat and then replace cat with alias in the `.zshrc` file:

```bash
alias cat=batcat
```

In some distros it's simply bat, in some other distros it might be batcat.

### To change the default prompt look

Add the following to `.zshrc`:

```bash
PROMPT="%F{red}%n%f %~ > "
```

You can customize the prompt to your liking.

## Disabling system suspend

When using a device as e.g. a server, suspending might not be needed or it could even be undesired. To configure system sleep states:

```bash title="/etc/systemd/sleep.conf.d/disable-suspend.conf"
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
```

## VMs

First, you need the QEMU server, which is the backend for the VMs, the libvirt manager, and optionally the cockpit web interface.

```bash
pacman -S qemu-full libvirt virt-manager cockpit cockpit-machines
```

You need to also enable/start libvirtd.

For cockpit you might need dnsmasq for DCHP for the VMs

```bash
pacman -S dnsmasq
```

```bash
Enable/Start dnsmasq
```

For simpler VM frontend you can use Gnome Boxes which is included with the gnome-extra package.

```bash
pacman -S gnome-extra
```

Software for TPM emulator. Needed for Windows 11.

```bash
pacman -S swtpm
```

### For Windows 11

1. Download Win11 iso.
2. Open gnome boxes.
3. Start a new VM from local files.
4. Edit memory to at least 4GB.
5. Edit storage to at least 100GB.
6. Edit the configuration file to enable TPM. Append:

```xml
<tpm model="tpm-crb">
    <backend type="emulator" version="2.0"/>
</tpm>
```

Save and start the VM.

In Windows 11 installation, to skip the internet connection requirement, hit Shift + F10 to bring up the console and type OOBE\BYPASSNRO and restart. Remember to disconnect the host from the internet so no internet passes through to the guest OS.

## GUI / CLI Boot

You can swap between using a desktop environment or just CLI. To force CLI:

```bash
systemctl set-default multi-user.target
```

To force Desktop Environment:

```bash
systemctl set-default graphical.target
```

## Generate Keys

You can use the openssl command to generate keys together with rand. Optionally, you can pass as flags the format you want and the number of digits.

For base64 and 60 digits key:

```bash
openssl rand -base64 60
```

For hexadecimal and 32 digits key:

```bash
openssl rand -hex 32
```

## Faillock

After 3 attempts of sudo, the account is locked. Check first the failed attempts with `faillock` and make sure it's actually you. Then you can reset the account fails with:

```bash
faillock --user <user> --reset
```

## Archiving and Compression

Archivers are used to put multiple files into a single file. Compressors are used to reduce the size of a file. These two tools are used together usually when packaging applications or backing up. One combo is tar + gzip. Tar creates and extracts files from archives. Gzip compresses and decompresses the archive files.

Tar flags:

-c Create a new archive. We use this flag whenever we need to create a new archive.
-z Use gzip compression. When we specify this flag, it means that archive will be created using gzip compression.
-v Provide verbose output. Providing the -v flag shows details of the files compressed.
-f Archive file name. Archive file names are mapped using the -f flag.
-x Extract from a compressed file. We use this flag when files need to be extracted from an archive.

Creating an archive and compressing it:

```bash
tar -czf example_archive.tar.gz /path/to/files
```

Extracting an archive (remember the -z flag if it's compressed):

```bash
tar -xzf example_archive.tar.gz
```

One can use the -C to specific location of extraction:

```bash
tar -xzf example_archive.tar.gz -C /path/to/extraction
```

## Password Store

`pass` is an unix password manager. It stores the passwords in a gpg file and uses git to sync.

You need to generate a gpg key to initialize pass:

```bash
pass init <your_public_gpg_key>
```

You can then initialize git for pass store:

```bash
pass git init
```

You can use normal git commands to view history, push, pull and sync your passwords across devices.

To add an existing password:

```bash
pass insert github
```

Where "github" is any password you want to add. `pass` is using normal files to save your passwords so you can nest them in folders.

```bash
pass insert websites/github
```

You can see all the stored passwords by running pass.

To generate a new password:

```bash
pass generate github
```

To show a password:

```bash
pass show websites/github
```

If you want to add an url, an email, or any data to a password, you can add it as metadata on the password file:

```bash title="pass edit websites/github"
random_password
email: hello@world.com
URL: https://eelslap.com/
```

## Cryptography

Generating a new gpg key:

```bash
gpg --gen-key
```

You can check the public id of your key by:

```bash
gpg -K
```

To access and edit the key, copy the ID and:

```bash
gpg --edit-key <key_public_id>
```

You can also access the key with your email:
```bash
gpg --edit-key my-email@example.com
```
By default, gpg keys expire, but you change that by editing your key and then, in the gpg prompt run ```expire``` and follow the prompt.

If you want to change the password of your key, enter again the edit-key menu, run `passwd` and again, follow the prompt.

You can find additional commands in the edit-key menu by running `help`.

When moving your key to different machine, remember that you need both your private and public keys. This especially needed with Password Store since it uses
your gpg keys to encrypt your password. 

Create a temp folder:
```bash
mkdir exported_keys
cd exported_keys
```
Create an export of your public key:
```bash
gpg --output --public.gpg --armor --export my-email@example.com
```

Create an export of your private key as well. You will be prompted to type your key password:
```bash
gpg --output --private.gpg --armor --export-secret-key my-email@example.com
```

Transfer the files via `scp` to the other machine. `cd` to that folder and import the keys. Start with the private one:
`gpg --import private.gpg` enter your key password, and then import the public key: `gpg --import public.gpg`


Finally, you will need to max the trust level of the public key for it to work properly. Edit the key, run `trust` and select `5` in the trust prompt. 
## Background Processes and 'Hang-Ups'

Running processes as background in bash is done by adding the ampersand `&` symbol at the end of a command. You can investigate the active background jobs by:

```bash
jobs
```
You can also push an actively running command to the background by suspending it with `Ctrl + Z` and then run `bg` to activate it in the background.

You can bring a background process to foreground again by:

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

