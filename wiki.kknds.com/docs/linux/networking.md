---
sidebar_position: 2
---
# Networking

## SSH Keys
:::info
Make sure you have openssh. Usually comes with most Linux distributions.
:::
To use keys instead of passwords, you need first to generate the key pair on the machine that will connect to the server:

```bash
ssh-keygen
```

Then you need to copy the public key to the server, and add the private key to the machine identity list:

```bash
ssh-copy-id -i <path/to/publickey.pub> <user>@<host>
ssh-add <path/to/privatekey>
```

(ARCH-SPECIFIC) And finally on the server, you need to enable publickey authentication and disable password to avoid brute force attacks.

```bash
micro /etc/ssh/sshd_config.d/10-force_publickey.conf
----------------------------------------------
PasswordAuthentication no
AuthenticationMethods publickey
```

Restart the sshd daemon on the server and it should work.

## SSH Tunneling

SSH Tunnels are used to exposed ports to and from connected systems.

Forward Tunnels (or local port forwarding)are used to connect to a host and expose their ports that would othewise wouldn't be accessible creating access to webservers or services that are still not public. Forward tunnels are created with the -L flag. In this example, local will be the client and remote will be the server:

```bash
ssh -L local:localport:remote:remoteport user@serverip_or_domain_name
```
***
```bash
ssh -L localhost:888:11.22.33.44:80 admin@11.22.33.44
```

Reverse tunnels (or remote port forwarding) let you access a computer inside a private network. To do this, you usually need three systems:

- S1: The computer inside the private network (the one you want to access).
- S2: A public system that both you and S1 can connect to.
- S3: Your computer, trying to access S1.

S1 connects to S2 using SSH with the -R flag, creating a reverse tunnel. This forwards a port (like port 2222) on S2 back to S1's port 22 (SSH). Now, S3 can connect to S2 on port 2222, which forwards the connection back to S1, letting you access it as if you were inside its network.

This setup helps you bypass S1's firewall.

```bash
#FROM THE ENDPOINT SYSTEM
ssh -R S2:S2port:S1:S1port S2user@S2

#FROM THE CLIENT SYSTEM
ssh -p S2port S1user@S2
```

## SSH File Transfer

This should work with MacOS and any Linux distro:

```bash
scp <source path> <user>@<server>:<destination path>
```

Add the `-r` flag if it's a folder. To connect via SSH the format is `user@host:/path/to/folder/` eg.:

```bash
scp -r /etc/systemd/destroyd takis@29.231.0.43:/opt/something
```

You might need to add the SSH fingerprint.

## Network management

`systemd-networkd` - the system daemon running the network configuration. Is needed for ipvlans for docker.

`networkctl list` - show interfaces

## Force close ports

```bash
nmap [host] #to see if/what ports are open
ss -tlpn | grep [port] # OR
fuser [port]/tcp
```

Add flag -k to fuser to kill the task as well (needs root)

## Static IP Config (requires systemd-networkd)

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=enp1s0

[Network]
Address=10.1.10.9/24
Gateway=10.1.10.1
DNS=10.1.10.1
```

## Renaming an interface (requires systemd-networkd)

A .link file can be used to rename an interface. A useful example is to set a predictable interface name for a USB-to-Ethernet adapter based on its MAC address, as those adapters are usually given different names depending on which USB port they are plugged into.

```ini
# /etc/systemd/network/10-ethusb0.link
[Match]
MACAddress=12:34:56:78:90:ab

[Link]
Description=USB to Ethernet Adapter
Name=ethusb0
```


# Firewall

## Back-end

nftables is on it's way to replace iptables. For that, I decided to replace iptables with nftables already. As of now, Archlinux comes with both installed but is using iptables. Usually just stop/disabling iptables and enable/starting nftables is good enough.

To move rules from iptables to nftables you need to translate them. Iptables comes with a tool thankfully that does that. First you need to export to a file your iptables rules:

```bash
iptables-save > tables.txt
```

Then translate the rules and save them in another file:

```bash
iptables-restore-translate -f tables.txt > ruleset.nft
```

And then just import the rules to nft:

```bash
nft -f ruleset.nft
```

Nftables already comes with some basic rules. To clear the ruleset:

```bash
nft flush ruleset
```

## Front-end

These are the firewalls that support nftables:

- ufw
- firewalld
- nft-blackhole