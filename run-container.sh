#!/bin/bash

WORKDIR=/usr/src/asterisk-dongle
mkdir -p $WORKDIR/asterisk-log
chown -R 999:999 $WORKDIR/asterisk-log

docker stop asterisk-dongle

docker run --detach --rm --name asterisk-dongle \
    --device=/dev/ttyUSB0 \
    --device=/dev/ttyUSB1 \
    --device=/dev/ttyUSB2 \
    --device=/dev/ttyUSB3 \
    --device=/dev/ttyUSB4 \
    --device=/dev/ttyUSB5 \
    -v $WORKDIR/asterisk-config:/etc/asterisk \
    -v $WORKDIR/asterisk-log:/var/log/asterisk \
    -p 5060:5060/udp \
    -p 5060:5060/tcp \
    asterisk-dongle

docker exec asterisk-dongle chown root:asterisk /dev/ttyUSB*
