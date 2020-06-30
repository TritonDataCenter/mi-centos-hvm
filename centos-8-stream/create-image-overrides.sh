#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2020 Joyent, Inc.
#

# Sets global variables iso_file and iso_sha
get_iso_file_sha() {
    local file

    if [[ -n $iso_file ]]; then
        return
    fi

    echo "Checking to see if we have the iso for $distro $release:"
    for file in CHECKSUM CHECKSUM.asc; do
        curl -s -o $iso_dir/$file $ISO_URL/$file
    done
    gpg --verify $iso_dir/CHECKSUM.asc

    # As new dot releases come out, the name of the iso file changes according
    # to a predictable pattern. The CHECKUSM file contains the proper
    # name.
    eval $(awk '$2 ~ "CentOS-Stream-8-x86_64-[0-9]+-dvd1.iso.$" {
            gsub("[()]", "", $2);
		    printf("iso_sha=%s; iso_file=%s;", $NF, $2);
        }' $iso_dir/CHECKSUM)
    if [[ -z $iso_file || -z $iso_sha ]]; then
        echo "$0: unable to determine ISO file and/or sha256" 1>&2
        exit 1
    fi
}

