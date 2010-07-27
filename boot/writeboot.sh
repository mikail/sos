cat boot.bin /dev/zero | dd bs=512 count=2880 of=../bin/bootdisc.img
