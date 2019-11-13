<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

<!--
    Copyright 2019 Joyent, Inc.
-->

# Centos Image Builder

This repo allows one to create custom CentOS images for use with Triton.

Configuration files and scripts that are common to many images should be
maintained in [sdc-vmtools](https://github.com/joyent/sdc-vmtools).

## Requirements

In order to use this repo, you need to have a SmartOS "joyent" brand zone that
is capable of running qemu.  In order to run qemu the instance needs
customization beyond what can be done with Triton APIs.  That is, an operator
needs to customize the instance.  This is typically accomplished by running the
following commands on the apprporiate compute node:

```
uuid=XXX	# Change this to the instance uuid

topds=zones/$uuid/data
zfs create -o zoned=on -o mountpoint=/data $topds

zonecfg -z $uuid <<EOF
add dataset
set name=$topds
end
add fs
set dir=/smartdc
set special=/smartds
set type=lofs
set options=ro
end
add device
set match=kvm
end
EOF
```

## Setup

This relies on the sdc-vmtools repo as a submodule.  You can get the right
version of that with:

```
git submodules update --init
```

If you forget to do that, `create-image` will do it before it tries to use
anything from that submodule.

## Using

To generate a CentOS `<version>` image run:

```
# ./create-image -r <version>
```

While the primary focus of `create-image` is CentOS, it should be
straight-forward to generate RHEL and Fedora images with this repo.  Once
support is added, other distributions may be specified with the `-d` option.

```
$ ./create-image -h
Usage:
        ./create-image [options] [command ...]
option:
        -h          This message
        -d          Distro name. One of centos, redhat, fedora
        -r          Distro release

Commands:
        fetch       Fetch the installation ISO
        ks_iso      Create a kickstart ISO
        image       Generate the image
```

### fetch

Download the distribution's NetInstall media (.iso) and verify its integrity.
If the required ISO already exists, its integrity is verified.  If it is found
to be corrupt it is fetched again.

This image will be automaticlaly mounted at `/run/install/repo` during
installation.

### ks_iso

Generate a kickstart ISO image.  This will contain the following:

* `ks.cfg` - From `<distro>-<release>/ks.cfg`.
* `sdc-vmtools` - The current content of the
  [sdc-vmtools](https://github.com/joyent/sdc-vmtools) repo.

This image is not automatically mounted, but may be mounted via `%pre` or
`%post` blocks within `ks.cfg`.  It has `kickstart` as its volume name, making
it easy to find under `/dev/disk/by-name`.  For example:

```
%pre
#! /bin/bash

set -ex
mkdir /run/install/joyks
mount /dev/disk/by-name/kickstart /run/install/joyks
%end
```

### image

This runs qemu in a way that allows unattended installation using the media and
kickstart ISO images described above.  Once qemu exits, a Triton-compatible
image is generated and stored in the current directory as
`<distro>-<release>-<timestamp>.{json,tar.gz}`.

The actual image creation is handled by `sdc-vmutils/bin/create-hybrid-iamge`.

## Default Settings For Images

Each image has the following characteristics.  See
`<distro>-<release>/ks.cfg` for details on which packages are included.

* Disk is 10GB in size (8GB for / and the rest for swap)
* Stock Kernel
* US Keyboard and Language
* Firewall enabled with SSH allowed
* Passwords are using SHA512
* Firstboot disabled
* SELinux is set to permissive
* Timezone is set to UTC
* Console is on ttyS0
* Root password is blank: console login is allowed without a password
* Configuration from the SmartOS metadata service is performed using cloud-init.

## Development

The following serves as a guide for adding support for new RHEL-like
distributions and versions of existing distributions.

Distribution-specific content is found in a per-distro subdirectory.  For
example, CentOS 7 bits are in the `centos-7` directory.  Directory names are
always lower-case.

The following subsections describe the content that may be in a per-distro
directory.

### ks.cfg file

The kickstart configuration file.  Notable parts of this include:

* `cloud-init` is installed, as it is responsible for interacting with the
  host's metadata service to configure networking, run user scripts, etc.  It
  requires `pyserial`, but for "reasons" the cloud-init developers have avoided
  adding pyserial as a dependency.
* `cloud-init` requires configuration in
  `/etc/cloud/cloud.cfg.d/90\_smartos.cfg` to only enable the SmartOS
  datasource, among other things.
* A `%pre` block is used to tail the most useful installation logs and write
  them to `/dev/ttyS0`.  `qemu` runs in such a way that the guest's `ttyS0`
  appears on `qemu`'s `stdout`, thus allowing the installation log to be
  captured by Jenkins or similar automation that may be creating an image.
* Before trying to copy anything from the `sdc-vmtools` subdirectory of the
  kickstart ISO, the ISO must be mounted as described above.

Each `%pre` and `%post` section should begin with the following, with a unique
`JOYENT_STATUS_<foo>` tag for each.  If the set of tags used does not exactly
match `JOYENT_STATUS_PRE JOYENT_STATUS_POST`,
`<distro>-<release>/create-image-overrides.sh` must declare `JOYENT_STATUS_VARS`
as an array of the expected tags.

```
#! /bin/bash

joyent_status=fail
trap 'echo JOYENT_STATUS_PRE=$joyent_status' EXIT

set -ex
```

and end with:

```
set +x
joyent_status=ok
```

`create-image` will verify that all `JOYENT_STATUS_<foo>` tags are set to `ok`,
which only happens if the script in that section runs to completion.

### RPMS directory

Any `\*.rpm` file in this directory will be copied to the `Packages` subdirectory
of the kickstart ISO.

This directory does not exist if not needed.

### RPMS.remote file

A list of RPM files that will be downloaded and stored in the `Packages`
subdirectory of the kickstart ISO.  See *RPMS directory* above.

This file does not exist if not needed.

### keys directory

Each GPG key found in the keys directory will be imported into the keyring of
the user running this command.  These keys are used for authenticating the media
that is downloaded by the `fetch` command.

### create-image-overrides.sh

If the distribution requires overrides of any functionality, it should be added
here.  This file is sourced by `create-image` just before processing commands.
In general, the global variables that are all-uppercase are good candidates for
being overridden.

This file does not exist if not needed.
