# OpenWRT
## Installing OpenWRT on x86\_64

OpenWRT has to be directly installed to a drive from another computer. At least that's what I did. Download the x86 version OpenWRT. Unzip the image:

```plaintext
gunzip openwrt_2352.img.gz
```

I formatted the disk to exFAT, and then:

```plaintext
dd if=openwrt_2352.img bs=1M of=/dev/sdX
```

Remember to check `lsblk` to see which drive to write.

Then install the drive to the other computer. Boot it up and make sure it boots in UEFI, and secure boot is off. It should just boot into OpenWRT now.

### Installing OpenWRT on VM (QEMU)

You need to download any x86\_64 image. I'm using virt-manager as frontend. Make sure when starting the VM to select “Import existing disk image”.

When starting the VM, you need to change the ip address. Note down the subnet of the host's interface that QEMU is using (probably something like `virbr0`)

In this example, I assume that the WAN interface on the VM is br-lan and that the host's subnet is 192.168.122.0/24.

```plaintext
IN OPENWRT
----------
ifconfig # confirm the interface name
ifconfig br-lan 192.168.122.10 
ifconfig br-lan
```

You can now access the OpenWRT web interface on that IP.

## First setup

When setting up the first time, we need to configure the physicals ports of the router. Boot into the router. We need keyboard and screen since we probably still can't SSH into the machine.

```plaintext
vi /etc/config/network
```

Change the ‘lan’ interface and ‘wan’ interface to use the correct physical ports, save the config, and then restart the network service:

```plaintext
service restart network
```

Check if your connection is working by pinging.

## Releasing/Renewing IPs from DHCP

Make sure when setting up the DHCP server to lower the lease time to 1 or 2 minutes.

Usually, releasing and renewing IPs happens on clients:

```plaintext
WINDOWS
---
ipconfig /release
ipconfig /renew
```

```plaintext
Linux
---
dhcpclient -r <interface>
```

On mac, go to System Settings > Network > LAN Device > Details… > TCP/IP > Renew DHCP Lease.

## Wifi/Ethernet Drivers

One can always check the chip on the ethernet / wifi card to find the manufacturer. For smaller, embedded systems it's best not to install many drivers as they take space. On x86 or ARM systems with a lot of resources (>2GB storage, >2GB memory, >2 cores) it doesn't matter.

```plaintext
opkg install kmod-iwlwifi
opkg install iwlwifi-firmware
opkg install wpad
opkg install kmod-rtl8xxxu
```

## DNS

### Custom DNS Server

Using a custom DNS for a WAN interface:

**Network > Interfaces > wan interface > Edit > Advance Settings > Custom DNS**

DNS Forwarding:

**Network > DHCP and DNS > Forwards > DNS Forwarding**

### DNS Hijacking

Configure firewall to intercept DNS traffic.

Navigate to **LuCI → Network → Firewall → Port Forwards**.

Click **Add** and specify:

1.  Name: `Intercept-DNS`
2.  Restrict to address family: IPv4 and IPv6
3.  Protocol: TCP, UDP
4.  Source zone: `lan`
5.  External port: `53`
6.  Destination zone: unspecified
7.  Internal IP address: any
8.  Internal port: any

Click **Save**, then **Save & Apply**.

[More info](https://openwrt.org/docs/guide-user/firewall/fw3_configurations/intercept_dns)

### DNS Encryption

DoT: DNS over TLS

DoH: DNS over HTTPS

## 802.1q VLAN

802.1q or dot1q is a standard in networking, specifically defining VLANs. It is used to segregate a local network. A switch (that supports dot1q) can split frames into two or more VLANs.

Openwrt can either directly split up a network if it has enough physical ports, or through a trunk port. A trunk port (or tagged port) is one physical port that can manage traffic on several VLANs. For example, a router has only one physical LAN port, and the network devices are connected to managed switch that supports 802.1q VLAN. Splitting the network happens inside the switch, and the openwrt just manages and forwards the traffic accordingly.