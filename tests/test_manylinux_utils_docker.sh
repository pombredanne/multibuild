# Tests for manylinux utils that must run inside docker

source manylinux_utils.sh
source tests/utils.sh

suppress yum_install rsync && suppress yum erase -y rsync \
    || ingest "yum_install valid"
suppress bash -c '! yum_install nonexistent' || ingest "yum_install nonexistent"

barf