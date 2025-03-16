---
side_position: 3 
---

# Disk Management

## Partitioning
:::warning
Partitioning deletes everything on your disk!
:::

`lsblk` Will show all the drives on the computer. Find the drive you want to partition and memorize the drive's path. I'll use sda for this example:

```bash
fdisk /dev/sda
```

Make sure the drive is unmounted.

```bash
umount <device>
```

Then fdisk starts and you will have a new prompt. For most cases:

- `g` make a new GPT partition table
- `n` create a new partition
- select the number assigned. Default picks the next available.
- select start of the sector. Default picks the first available byte.
- select the end of the sector. If you want one partition on the whole disk, then use default.
- `t` if you want to change the partition type. You might need this if you're setting up a RAID.
- `w` to write the partition and exit.

## Formatting

:::warning
Formatting deletes everything on your disk!
:::

`lsblk` Will show all the drives on the computer. Find the partition you want to format and memorize the path. I'll use /dev/sda1 for this example.

Make sure the drive is unmounted.

```bash
umount <device>
```

You need to figure out what file system you want. Usually btrfs or ext4 is best for Linux. I do ext4 for single disks and btrfs for RAID arrays.

```bash
mkfs.ext4 /dev/sda1
```

You might need to mount the drive.

## RAID

You need to download mdadm.

```bash
pacman -S mdadm
```

Make sure you have partitioned the drives you want to use and the partition type is Linux RAID (it might work on empty space as well).

Also make sure the drives are unmounted.

```bash
umount <device1>
umount <device2>
```

Then you can build the array:

```bash
mdadm --create --verbose --level=0 --metadata=1.2 --raid-devices=2 /dev/md/myRAIDarray /dev/sda1 /dev/sdb1
```

- `--level` determines the RAID type. level 0 is RAID0, level 1 is RAID1, level 5 is RAID5, level 10 is RAID10, etc.
- `--metadata` default is 1.2 and should stay like that. If you are writing an OS on the RAID, then you probably need 1.0.
- `--raid-devices` the number of partitions in the RAID array.
- The path will be the path of your new RAID partition. The rest are the partitions to be used in the RAID.

Once the array is created, you double check it's ready with:

```bash
cat /proc/mdstat
```

and:

```bash
mdadm --detail --scan
```

You will then need to format the new array, and mount:

```bash
mkfs.<FILESYSTEM> -F /path/to/dev
mount /path/to/mount /path/to/dev
```

You can double check that the array is available with df.

We need to then save the array layout so it's available at boot. We do that by writing the details of the array to mdadm.conf in etc.

```bash
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
```

We can also update the initramfs so the array is available early in the boot process:

```bash
sudo update-initramfs -u
```

You can also add the array to fstab so it automatically mounts on startup.

## Mounting

```bash
mount /path/to/dev /path/to/mount
```

If you want to permanently mount a drive you have to add it to fstab

```ini title="/etc/fstab"
# <device>                                <dir> <type> <options> <dump> <fsck>
UUID=0a3407de-014b-458b-b5c1-848e92a327a3 /     ext4   defaults  0      1
UUID=f9fe0b69-a280-415d-a03a-a32752370dee none  swap   defaults  0      0
UUID=b411dc99-f0a0-4c87-9e05-184977be8539 /home ext4   defaults  0      2
```

To find your device UUID:

```bash
lsblk -f
```

- `<device>` describes the block special device or remote file system to be mounted.
- `<dir>` describes the mount directory.
- `<type>` the file system type.
- `<options>` the associated mount options.
- `<dump>` is checked by the dump(8) utility. This field is usually set to 0, which disables the check.
- `<fsck>` sets the order for file system checks at boot time. For the root device it should be 1. For other partitions it should be 2, or 0 to disable checking.

Once you are done editing the fstab, reload the system daemon and mount all drives:

```bash
systemctl daemon-reload
mount -a
```

## Automount with systemd

If the partition is pretty big, you can automount with systemd. You need to add x-systemd.automount in the options field. eg:

```ini title="/etc/fstab"
# <device>                                <dir> <type> <options>                  <dump> <fsck>
UUID=0a3407de-014b-458b-b5c1-848e92a327a3 /     ext4   defaults,x-systemd.automount  0      1
```

## Disk Usage

I recommend ncdu to check disk usage.

```bash
pacman -S ncdu
```

and then to run it, just:

```bash
ncdu
```

You can also check free space with:

```bash
df -h
```
