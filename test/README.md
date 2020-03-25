<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

<!--
    Copyright 2020 Joyent, Inc.
-->

# Testing

There is no automated testing at this time.  The following manual tests likely
point to the start of tests that should be automated.

This testing uses CoaL or a standalone SmartOS instance using the same network
configuration as CoaL.  If your networking config is different, you will need to
modify `import-and-start`.

## Download the image

Save the `.imgmanifest` and `.zfs.gz` file for the image on local storage.

## Import the image and start the instance

If there is a specific ssh public key that you would like to use to access the
instance, copy that public key into the current working directory as
`id_rsa.pub` (regardless of whether it is really an rsa key or not).  If no such
file exists in the current working directory, a new key pair will be generated.

Use [`import-and-start`](import-and-start) to import the image (if not already
imported/installed) and start the instance.  It will automatically connect you
to the console.

```
# ./import-and-start centos-6-20191113.imgmanifest bhyve
```

1. Ensure that the grub menu is displayed and that you can interact with it.

2. Select the appropriate entry to boot the instance.

3. Verify that the banner before the login prompt has Joyent branding and that
it has the appropriate release and date stamp, as shown below.

```
...
Starting crond: [  OK  ]

   __        .                   .
 _|  |_      | .-. .  . .-. :--. |-
|_    _|     ;|   ||  |(.-' |  | |
  |__|   `--'  `-' `;-| `-' '  ' `-'
                   /  ;  Instance (CentOS 6.10 20191113)
                   `-'   https://docs.joyent.com/images/linux/centos

centos-6-20191113 login:
```

4. Verify that the hostname in the login prompt matches that set in the
   `vmadm create` payload.

### Verify console login

1. Login on the console as root with no password.

```
centos-6-20191113 login: root
   __        .                   .
 _|  |_      | .-. .  . .-. :--. |-
|_    _|     ;|   ||  |(.-' |  | |
  |__|   `--'  `-' `;-| `-' '  ' `-'
                   /  ;  Instance (CentOS 6.10 20191113)
                   `-'   https://docs.joyent.com/images/linux/centos

[root@centos-6-20191113 ~]#
```

2. Verify that the motd is displayed and the prompt contains the appropriate
hostname.

### Verify ssh configuration

1. Verify that ssh host keys are generated and were created after this instance
   booted.

```
[root@centos-6-20191113 ~]# find /etc/ssh -type f -newer /proc/1
/etc/ssh/ssh_host_dsa_key.pub
/etc/ssh/ssh_host_rsa_key.pub
/etc/ssh/sshd_config
/etc/ssh/ssh_host_key
/etc/ssh/ssh_host_key.pub
/etc/ssh/ssh_host_rsa_key
/etc/ssh/ssh_host_dsa_key
```

2. Verify that there are no ssh host keys that existed prior to this boot.

```
[root@centos-6-20191113 ~]# find /etc/ssh \! -newer /proc/1
/etc/ssh/ssh_config
/etc/ssh/moduli
```

3. Verify sshd is running

On CentOS 6:

```
[root@centos-6-20191113 ~]# service sshd status
openssh-daemon (pid  1351) is running...
```

On later releases:

```
[root@centos-7-20191113 ~]# systemctl status sshd.service
● sshd.service - OpenSSH server daemon
   Loaded: loaded (/usr/lib/systemd/system/sshd.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2019-11-14 14:55:10 UTC; 2min 3s ago
     Docs: man:sshd(8)
           man:sshd_config(5)
 Main PID: 1169 (sshd)
   CGroup: /system.slice/sshd.service
           └─1169 /usr/sbin/sshd -D

Nov 14 14:55:09 centos-7-20191113.json systemd[1]: Starting OpenSSH server da...
Nov 14 14:55:10 centos-7-20191113.json sshd[1169]: Server listening on 0.0.0....
Nov 14 14:55:10 centos-7-20191113.json sshd[1169]: Server listening on :: por...
Nov 14 14:55:10 centos-7-20191113.json systemd[1]: Started OpenSSH server dae...
Hint: Some lines were ellipsized, use -l to show in full.
```

4. Verify that .ssh/authorized_keys contains only the key that was added via
   `root_authorized_keys`.

5. Verify that there is a firewall rule that allows incoming ssh.

```
[root@centos-6-20191113 ~]# iptables -L | grep ssh
ACCEPT     tcp  --  anywhere             anywhere            state NEW tcp dpt:ssh
```

6. Verify that password authentication via ssh to the root account is not
   allowed.

```
[root@centos-6-20191113 ~]# ssh localhost
The authenticity of host 'localhost (::1)' can't be established.
RSA key fingerprint is 7d:93:49:7b:de:ad:f3:44:e4:5b:42:63:e7:81:2f:60.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'localhost' (RSA) to the list of known hosts.
Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

7. Verify that key-based authentication via ssh to the root account is allowed.
   This is run from another machine that holds the private key associated with
   the public key added earlier.

```
$ ssh -o stricthostkeychecking=false -o userknownhostsfile=/dev/null root@10.88.88.217
Warning: Permanently added '10.88.88.217' (RSA) to the list of known hosts.
Last login: Thu Nov 14 04:21:30 2019
   __        .                   .
 _|  |_      | .-. .  . .-. :--. |-
|_    _|     ;|   ||  |(.-' |  | |
  |__|   `--'  `-' `;-| `-' '  ' `-'
                   /  ;  Instance (CentOS 6.10 20191113)
                   `-'   https://docs.joyent.com/images/linux/centos

[root@centos-6-20191113 ~]# exit
```

8. Verify that an ssh server on another port is not reachable.

```
[root@centos-6-20191113 ~]# /usr/sbin/sshd -d -p 222
debug1: sshd version OpenSSH_5.3p1
debug1: read PEM private key done: type RSA
debug1: private host key: #0 type 1 RSA
debug1: read PEM private key done: type DSA
debug1: private host key: #1 type 2 DSA
debug1: rexec_argv[0]='/usr/sbin/sshd'
debug1: rexec_argv[1]='-d'
debug1: rexec_argv[2]='-p'
debug1: rexec_argv[3]='222'
Set /proc/self/oom_score_adj from 0 to -1000
debug1: Bind to port 222 on 0.0.0.0.
Server listening on 0.0.0.0 port 222.
debug1: Bind to port 222 on ::.
Server listening on :: port 222.
```

When the following is executed from the same host as used in step 7, the
connection should not be allowed and the sshd process should not see the
traffic.

```
$ ssh -o stricthostkeychecking=false -o userknownhostsfile=/dev/null root@10.88.88.217 -p 222
ssh: connect to host 10.88.88.217 port 222: Connection refused
```

9. Verify that disabling the firewall allows the sshd on port 222.

On CentOS 6:

```
[root@centos-6-20191113 ~]# service iptables stop
iptables: Setting chains to policy ACCEPT: filter [  OK  ]
iptables: Flushing firewall rules: [  OK  ]
iptables: Unloading modules: [  OK  ]
[root@centos-6-20191113 ~]# /usr/sbin/sshd -d -p 222
...
```

On later versions:

```
[root@centos-7-20191113 ~]# systemctl stop firewalld.service
[  420.357355] Ebtables v2.0 unregistered
[root@centos-7-20191113 ~]# /usr/sbin/sshd -d -p 222
...
```

Common to all versions:

```
$ ssh -o stricthostkeychecking=false -o userknownhostsfile=/dev/null root@10.88.88.217 -p 222
Warning: Permanently added '[10.88.88.217]:222' (RSA) to the list of known hosts.
Last login: Thu Nov 14 04:31:43 2019 from 10.88.88.1
   __        .                   .
 _|  |_      | .-. .  . .-. :--. |-
|_    _|     ;|   ||  |(.-' |  | |
  |__|   `--'  `-' `;-| `-' '  ' `-'
                   /  ;  Instance (CentOS 6.10 20191113)
                   `-'   https://docs.joyent.com/images/linux/centos

debug1: PAM: reinitializing credentials
...
[root@centos-6-20191113 ~]# ^D
```

### Verify yum configuration

1. Run `yum update` to ensure it can reach repositories

Note: this may find some updates to install, which is fine.

```
[root@centos-6-20191113 ~]# yum update -y
Loaded plugins: fastestmirror
Setting up Update Process
Determining fastest mirrors
epel/metalink                                            |  13 kB     00:00
 * base: mirror.fileplanet.com
 * epel: mirror.uic.edu
 * extras: centos.mirrors.tds.net
 * updates: mirror.fileplanet.com
base                                                     | 3.7 kB     00:00
base/primary_db                                          | 4.7 MB     00:22
epel                                                     | 5.3 kB     00:00
epel/primary_db                                          | 6.1 MB     00:00
extras                                                   | 3.4 kB     00:00
extras/primary_db                                        |  29 kB     00:00
updates                                                  | 3.4 kB     00:00
updates/primary_db                                       | 7.1 MB     00:33
No Packages marked for Update
```

### Verify disks

```
[root@centos-6-20191113 ~]# df -h
Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup-lv_root
                      8.3G  1.2G  6.8G  15% /
tmpfs                 488M     0  488M   0% /dev/shm
/dev/vda1             477M   30M  422M   7% /boot
/dev/vdb              488M  396K  462M   1% /data
```

1. `/` should be about 8 GiB in size
2. `/boot` should exist on its own partition
3. `/dev/vdb` should contain a file system mounted at /data
4. There should be a swap partition or volume.

```
[root@centos-6-20191113 ~]# cat /proc/swaps
Filename				Type		Size	Used	Priority
/dev/dm-1                               partition	1048572	0	-1
```

### Verify mdata utilities

```
[root@centos-6-20191113 ~]# mdata-list
root_authorized_keys
[root@centos-6-20191113 ~]# mdata-put foo bar
[root@centos-6-20191113 ~]# mdata-list
root_authorized_keys
foo
[root@centos-6-20191113 ~]# mdata-get foo
bar
[root@centos-6-20191113 ~]# mdata-delete foo
[root@centos-6-20191113 ~]# mdata-list
root_authorized_keys
```

### Verify node and json are available

```
[root@centos-6-20191113 ~]# node --version
v0.10.48
[root@centos-6-20191113 ~]# json --version
json 9.0.6
written by Trent Mick
https://github.com/trentm/json
```

### reboot

From the console window, reboot.  Do not interact with the cosnsole during
reboot to ensure that the system boots without interaction.


### Verify sudo works

Log in via ssh, then:

```
useradd -s /bin/bash foo
echo 'foo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/foo
su - foo
```

1. Verify that this user can do privileged operations

```
[foo@centos-6-20191114 ~]$ sudo tail -1 /etc/shadow
foo:!!:18214:0:99999:7:::
```

2. Verify that removal of `/etc/sudoers.d/foo` results in loss of power

```
[foo@centos-6-20191114 ~]$ sudo rm /etc/sudoers.d/foo
[foo@centos-6-20191114 ~]$ sudo tail -1 /etc/shadow
[sudo] password for foo: ^C
```

### Destroy the vm

Detach from the console with `^].` (or just `^]` when repeating this test with
kvm).

```
[root@buglets ~/c6]# vmadm delete bdebac29-7197-e1df-c25d-b387f4ca041b
Successfully deleted VM bdebac29-7197-e1df-c25d-b387f4ca041b
```

## basic kvm tests

Repeat the tests above using kvm.  Start with:

```
# ./import-and-start centos-6-20191113.imgmanifest kvm
```
