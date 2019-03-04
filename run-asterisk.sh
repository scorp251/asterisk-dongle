#!/bin/bash


WORKDIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) >/dev/null && pwd )

mkdir -p $WORKDIR/asterisk-log
chown -R 999:999 $WORKDIR/asterisk-log

docker rm -f asterisk-dongle 2>&1 >/dev/null

docker run --detach --restart always --name asterisk-dongle --hostname asterisk-dongle\
    -v $WORKDIR/asterisk-config:/etc/asterisk \
    -v $WORKDIR/asterisk-log:/var/log/asterisk \
    --device=/dev/ttyUSB0 \
    --device=/dev/ttyUSB1 \
    --device=/dev/ttyUSB2 \
    --device=/dev/ttyUSB3 \
    --device=/dev/ttyUSB4 \
    --device=/dev/ttyUSB5 \
    --device=/dev/ttyUSB6 \
    --device=/dev/ttyUSB7 \
    --device=/dev/ttyUSB8 \
    --device=/dev/ttyUSB9 \
    --device=/dev/ttyUSB10 \
    --device=/dev/ttyUSB11 \
    -p 5060:5060/udp \
    -p 5060:5060/tcp \
    asterisk-dongle

docker exec asterisk-dongle chown root:asterisk /dev/ttyUSB*
