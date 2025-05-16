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
## Remote Access
If you want to access your backend servers, and/or your services through your home network, you will need either a tunneling service or a VPN server. 

### Tunneling Services / Token Servers
Tunneling services are great because they encrypt your traffic and usually include SSL certificates. You can also use them as reverse proxies for your services. 
The downsides of tunnels, they are usually paid services, and you need to trust the service with your unencrypted traffic. 
I use Cloudflare as my domain registrar, which also offers tunneling. It works great for me because I can have my services publicly accessible
without exposing my network to the internet.

### VPN Server
The alternative is setting up your own VPN server. My current setup is a Raspberry Pi 3 Model B+ and [PiVPN](https://www.pivpn.io/). PiVPN is a plug-n-play setup for turning your Rpi to a VPN Server. 
You can then use either OpenVPN or Wireguard as backend. I went with Wireguard since it's a little more modern and faster. 

Installing is pretty straight forward if you have internet access:
```bash
curl -L https://install.pivpn.io | bash
```

I highly recommend using a domain name and [DDNS](/docs/openwrt#ddns-with-cloudflare) 
so you don't have to fetch your public IP everytime it rotates by your ISP. You check if it's up by `ping` or `traceroute` your domain name.

On your router, you will need to forward all traffic from UDP port 51820 to your Pi.

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