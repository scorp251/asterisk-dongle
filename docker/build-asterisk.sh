#!/bin/bash
PROGNAME=$(basename $0)

if test -z ${ASTERISK_VERSION}; then
    echo "${PROGNAME}: ASTERISK_VERSION required" >&2
    exit 1
fi

set -ex

mkdir -p /usr/src/asterisk
cd /usr/src/asterisk

curl -vsL http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz |
    tar --strip-components 1 -xz

# 1.5 jobs per core works out okay
: ${JOBS:=$(( $(nproc) + $(nproc) / 2 ))}

./configure  --with-resample --with-jansson-bundled --libdir=/usr/lib64

make menuselect/menuselect menuselect-tree menuselect.makeopts

# disable BUILD_NATIVE to avoid platform issues
menuselect/menuselect --disable BUILD_NATIVE menuselect.makeopts

# enable good things
menuselect/menuselect --enable BETTER_BACKTRACES menuselect.makeopts
menuselect/menuselect --enable codec_opus menuselect.makeopts
#menuselect/menuselect --disable res_pjsip menuselect.makeopts

# download more sounds
for i in CORE-SOUNDS-EN MOH-OPSOUND EXTRA-SOUNDS-EN; do
#    for j in ULAW ALAW G722 GSM SLN16; do
#        menuselect/menuselect --enable $i-$j menuselect.makeopts
#    done
    menuselect/menuselect --enable $i-WAV menuselect.makeopts
done

make -j ${JOBS} all
make install
chown -R asterisk:asterisk /var/*/asterisk
chmod -R 750 /var/spool/asterisk
mkdir -p /etc/asterisk/

# copy default configs
cp /usr/src/asterisk/configs/basic-pbx/*.conf /etc/asterisk/
#rm -f /etc/asterisk/pjsip.conf
cp /usr/src/asterisk/configs/samples/sip.conf.sample /etc/asterisk/sip.conf

# set runuser and rungroup
sed -i -E 's/^;(run)(user|group)/\1\2/' /etc/asterisk/asterisk.conf

cd /usr/src
git clone https://github.com/wdoekes/asterisk-chan-dongle
cd asterisk-chan-dongle
./bootstrap
./configure --with-asterisk=/usr/src/asterisk/include --with-astversion=${ASTERISK_VERSION}
make
make install

cd /
rm -rf /usr/src/asterisk*
