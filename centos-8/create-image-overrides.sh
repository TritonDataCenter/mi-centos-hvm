#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2019 Joyent, Inc.
#

BOOT_DVD_VOLUME_ID=CentOS-8-BaseOS-x86_64

# Sets global variables iso_file and iso_sha
get_iso_file_sha() {
    local file

    if [[ -n $iso_file ]]; then
        return
    fi

    echo "Checking to see if we have the iso for $distro $release:"
    file=CHECKSUM.asc
    curl -s -o $iso_dir/$file $ISO_URL/$file
    gpg --verify $iso_dir/$file

    # As new dot releases come out, the name of the iso file changes according
    # to a predictable pattern.  The sha256sums.txt file contains the proper
    # name.
    eval $(awk '$2 ~ "^.CentOS-8-x86_64-[0-9]{4}-dvd1.iso.$" {
            gsub("[()]", "", $2);
		    printf("iso_sha=%s; iso_file=%s;", $NF, $2);
        }' $iso_dir/$file)
    if [[ -z $iso_file || -z $iso_sha ]]; then
        echo "$0: unable to determine ISO file and/or sha256" 1>&2
        exit 1
    fi
}

