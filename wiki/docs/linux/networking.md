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

```bash title="/etc/ssh/sshd_config.d/10-force_publickey.conf"
PasswordAuthentication no
AuthenticationMethods publickey
```

Restart the sshd daemon on the server and it should work.

## SSH Tunneling

SSH Tunnels are used to exposed ports to and from connected systems.

Forward Tunnels (or local port forwarding) are used to connect to a host and expose their ports that would othewise wouldn't be accessible creating access to webservers or services that are still not public. Forward tunnels are created with the -L flag. In this example, local will be the client and remote will be the server:

```bash
ssh -L local:localport:remote:remoteport user@serverip_or_domain_name
```
***
```bash
ssh -L localhost:888:111.222.333.444:80 admin@111.222.333.444
```

Reverse tunnels (or remote port forwarding) let you access a computer inside a private network. In a usual scenario, you will have three computers:

- S1: The computer inside the private network (the one you want to access).
- S2: A public computer that both you and S1 can connect to.
- S3: Your computer, trying to access S1.

S1 connects to S2 using SSH with the -R flag, creating a reverse tunnel. This forwards a port (like port 2222) on S2 back to S1's port 22 (SSH). Now, S3 can connect to S2 on port 2222, which forwards the connection back to S1, letting you access it as if you were inside its network.

This setup helps you bypass S1's firewall.

```bash
#FROM THE ENDPOINT SYSTEM
ssh -R S2:S2port:S1:S1port S2user@S2

#FROM THE CLIENT SYSTEM
ssh -p S2port S1user@S2
```
:::warning
In reality, you are creating a back-door to the S1 computer, exposing it to the internet; Use at your own risk!
:::

## SSH File Transfer

This should work with MacOS and any Linux distro:

```bash
scp <source path> <destination path>
```

Add the `-r` flag if it's a folder. To connect via SSH the format is `user@host:/path/to/folder/` eg.:

```bash
scp -r /etc/systemd/destroyd takis@29.231.0.43:/opt/something
```

You might need to add the SSH fingerprint and the user password. If the destination doesn't allow SSH passwords, you need to install your public key to the destination.

## Network management

`systemd-networkd` - the system daemon running the network configuration. Is needed for ipvlans for docker.

`networkctl list` - show interfaces

### Force close ports

```bash
nmap [host] #to see if/what ports are open
ss -tlpn | grep [port] # OR
fuser [port]/tcp
```

Add the flag `-k` to `fuser` to kill the task as well (needs root)

### Static IP Config (requires systemd-networkd)

```ini title="/etc/systemd/network/20-wired.network"
[Match]
Name=enp1s0

[Network]
Address=10.1.10.9/24
Gateway=10.1.10.1
DNS=10.1.10.1
```

### Renaming an interface (requires systemd-networkd)

A .link file can be used to rename an interface. A useful example is to set a predictable interface name for a USB-to-Ethernet adapter based on its MAC address, as those adapters are usually given different names depending on which USB port they are plugged into.

```ini title="/etc/systemd/network/10-ethusb0.link"
[Match]
MACAddress=12:34:56:78:90:ab

[Link]
Description=USB to Ethernet Adapter
Name=ethusb0
```
## Reverse Proxy

There are several options for reverse-proxying, but we explore here NGINX. NGINX is a web server that handles internet traffic. It's mainly used to serve websites and route internet requests.

To make sure HTTPS works, we need to generate self-signed SSL certificates.

1\. create a 2048-bit RSA private key:

```plaintext
openssl genrsa -out server.key 2048
```

2\. create a self-signed request. You need to fill the prompts. If you want to leave something empty use ‘.’:

```plaintext
openssl req -new -key server.key -out server.csr
```

3\. create the SSL certificate. You can adjust the expiration date of the SSL certificate here. Best practice is to the update them every year (365 days):

```plaintext
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

4\. test the certificate:

```plaintext
openssl x509 -in server.crt -text -noout
```

You can optionally combine the key and certificate into one file; sometimes useful for some web servers:

```plaintext
cat server.crt server.key > server.pem
```

You can either use an NGINX docker container or the NGINX daemon. For the daemon, you can create your configurations in `/etc/nginx/sites-available/my.conf`. Example conf for a service on localhost:8080:

```nginx title="/etc/nginx/sites-available/page.conf"
server {
    listen 443 ssl;
    server_name your_domain_or_ip;

    ssl_certificate /path/to/your/fullchain.pem;
    ssl_certificate_key /path/to/your/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

server {
    listen 80;
    server_name your_domain_or_ip;
    return 301 https://$host$request_uri;
}
```

Replace `your_domain_or_ip` and the correct paths to the SSL certificates and keys. Enable then the new nginx conf:

```plaintext
sudo ln -s /etc/nginx/sites-available/jira.conf /etc/nginx/sites-enabled/
sudo nginx -t   # Check for syntax errors
sudo systemctl restart nginx
```

For the docker container version, you would again create a `.conf` file and pass it to the container when creating it. 

## Firewall

### Back-end

Nftables is on it's way to replace iptables. For that, I decided to replace iptables with nftables already. As of now, Archlinux comes with both installed but is using iptables. Usually just stop/disabling iptables and enable/starting nftables is good enough.

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

### Front-end

These are the firewalls that support nftables:

- ufw
- firewalld
- nft-blackhole


## CIDR Cheatsheet

|     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
| **Prefix** | **\# of former class C networks** | **Potential Hosts** | **Actual Hosts** | **Netmask** | **\# of subnets** |
| /31 | 1/128 | 2   | 0   | 255.255.255.254 | 128 |
| /30 | 1/64 | 4   | 2   | 255.255.255.252 | 64  |
| /29 | 1/32 | 8   | 6   | 255.255.255.248 | 32  |
| /28 | 1/16 | 16  | 14  | 255.255.255.240 | 16  |
| /27 | 1/8 | 32  | 30  | 255.255.255.224 | 8   |
| /26 | 1/4 | 64  | 62  | 255.255.255.192 | 4   |
| /25 | 1/2 | 128 | 126 | 255.255.255.128 | 2   |
| /24 | 1   | 256 | 254 | 255.255.255.0 | 1   |
| /23 | 2   | 512 | 510 | 255.255.254.0 | 128 |
| /22 | 4   | 1,024 | 1,022 | 255.255.252.0 | 64  |
| /21 | 8   | 2,048 | 2,046 | 255.255.248.0 | 32  |
| /20 | 16  | 4,096 | 4,094 | 255.255.240.0 | 16  |
| /19 | 32  | 8,192 | 8,190 | 255.255.224.0 | 8   |
| /18 | 64  | 16,384 | 16,382 | 255.255.192.0 | 4   |
| /17 | 128 | 32,768 | 32,766 | 255.255.128.0 | 2   |
| /16 | 256 = 1 class B network | 65,536 | 65,534 | 255.255.0.0 | 1   |
| /15 | 512 = 2 B networks | 131,072 | 131,070 | 255.254.0.0 | 128 |
| /14 | 1,024 = 4 B networks | 262,144 | 262,142 | 255.252.0.0 | 64  |
| /13 | 2,048 = 8 B networks | 524,288 | 524,286 | 255.248.0.0 | 32  |
| /12 | 4,096 = 16 B networks | 1,048,576 | 1,048,574 | 255.240.0.0 | 16  |
| /11 | 8,192 = 32 B networks | 2,097,152 | 2,097,150 | 255.224.0.0 | 8   |
| /10 | 16,384 = 64 B networks | 4,194,304 | 4,194,302 | 255.192.0.0 | 4   |
| /9  | 32,768 = 128 B networks | 8,388,608 | 8,388,606 | 255.128.0.0 | 2   |
| /8  | 65,536 = 256 B/1 A network | 16,777,216 | 16,777,214 | 255.0.0.0 | 1   |
| /7  | 131,072 = 2 A networks | 33,554,432 | 33,554,430 | 254.0.0.0 | 128 |
| /6  | 262,144 = 4 A networks | 67,108,864 | 67,108,862 | 252.0.0.0 | 64  |
| /5  | 524,888 = 8 A networks | 134,217,728 | 134,217,726 | 248.0.0.0 | 32  |
| /4  | 1,048,576 = 16 A networks | 268,435,456 | 268,435,454 | 240.0.0.0 | 16  |
| /3  | 2,097,152 = 32 A networks | 536,870,912 | 536,870,910 | 224.0.0.0 | 8   |
| /2  | 4,194,304 = 64 A networks | 1,073,741,824 | 1,073,741,822 | 192.0.0.0 | 4   |
| /1  | 8,388,608 = 128 A networks | 2,147,483,648 | 2,147,483,646 | 128.0.0.0 | 2   |
| /0  | 16,777,216 = 256 A networks | 4,294,967,296 | 4,294,967,294 | 0.0.0.0 | 1   |