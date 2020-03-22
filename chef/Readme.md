# Configure my Debian machines

This cookbook configure two types of [Debian](https://www.debian.org) machines
- Raspberry Pi runnning [Home Assistant](https://www.home-assistant.io)
and [snapcast](https://github.com/badaix/snapcast).
- Workstation for development with a private and a work user.

## Workstation

Do a [Debian net installation](https://www.debian.org/distrib/netinst).

- Do not create users.
- Use an EFI boot.
- Configure the root disk using GPT with these paritions.
  - Do not configure a swap parition but do create an unused partition whose name ends in `swapcrypted`.
  - Configure the root partition as btrfs
  - Configure the boot partition as btrfs

| Number | Start (sector) | End (sector) | Size       | Code | Name                 |
| ------ | -------------- | ------------ | ---------- | ---- | -------------------- |
|   1    |         2048   |       999423 |  487.0 MiB | 8300 | 7480bootdev          |
|   2    |       999424   |      1499135 |  244.0 MiB | EF00 | EFI System Partition |
|   3    |      1499136   |      9312255 |  3.7 GiB   | 8300 | 7480swapcrypted      |
|   4    |      9312256   |   1000214527 |  472.5 GiB | 8300 | 7480rootcrypted      |

- After configuring the disks, open a shell,
  - `btrfs subvolume create /target/root`
  - `mv /target/etc /target/media /target/root/`
  - `btrfs subvolume list /target`
  - `btrfs subvolume set-default XXX /target` (XXX is the ID of /target/root)
  - `grep target /proc/mounts`
  - `umount /target/boot/efi /target/boot /target`
  - `mount -o compress=zstd YYY /target` (YYY is device for /target above)
  - `mount AAA /boot` (AAA is boot's device from above)
  - `mount BBB /boot/efi` (BBB is efi's device from above)
- Continue the install
- After the first boot
  - checkout this [repo](https://github.com/stuart12/stuart-system)
  - run `chef/converge`
  - Create an attribute file using `5spook7480latitude.rb` as an example.
    - Update the UUID to the UUID of your root filesystem
    - Activate the services that interest you.
  - run `chef/converge`

(The above instructions are from memory.)

## Override an attribute
In your attribute file add:

    CfgHelper.override(
      %w[git config sections user],
      email: 'jill35@users.noreply.github.com',
    )

