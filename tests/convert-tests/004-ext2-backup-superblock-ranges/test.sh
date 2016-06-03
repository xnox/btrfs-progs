#!/bin/bash

# Specially created e2image dump to test backup superblock migration for
# new convert.
# These images will cause the following problems if convert doesn't handle
# backup superblock migration well:
# 1) Assert while building free space tree
# 2) Error copying inodes
# 3) Discontinuous file extents after convert
# 4) Overlap file extents
# 5) Unable to rollback

source $TOP/tests/common

check_prereq btrfs-convert
check_prereq btrfs
check_prereq btrfs-show-super
check_global_prereq e2fsck
check_global_prereq xzcat

setup_root_helper
prepare_test_dev 512M

for src in $(find . -iname "*.e2image.raw.xz"); do
	extracted=$(extract_image "$src")
	run_check $SUDO_HELPER e2fsck -n -f $extracted
	run_check $SUDO_HELPER $TOP/btrfs-convert $extracted
	run_check $SUDO_HELPER $TOP/btrfs check $extracted
	run_check $SUDO_HELPER $TOP/btrfs-show-super $extracted

	run_check $SUDO_HELPER mount -o loop $extracted $TEST_MNT
	run_check $SUDO_HELPER e2fsck -n -f $TEST_MNT/ext2_saved/image
	run_check $SUDO_HELPER umount $TEST_MNT

	run_check $SUDO_HELPER $TOP/btrfs check $extracted
	run_check $SUDO_HELPER $TOP/btrfs-convert -r $extracted
	run_check $SUDO_HELPER e2fsck -n -f $extracted
	rm -f $extracted
done
