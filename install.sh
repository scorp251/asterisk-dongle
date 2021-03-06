#!/bin/bash

INSTALLDIR=/opt/asterisk-dongle
NUM_MODEM=1

runOnMac=false
int2ip() { printf ${2+-v} $2 "%d.%d.%d.%d" \
        $(($1>>24)) $(($1>>16&255)) $(($1>>8&255)) $(($1&255)) ;}
ip2int() { local _a=(${1//./ }) ; printf ${2+-v} $2 "%u" $(( _a<<24 |
                  ${_a[1]} << 16 | ${_a[2]} << 8 | ${_a[3]} )) ;}
while IFS=$' :\t\r\n' read a b c d; do
    [ "$a" = "usage" ] && [ "$b" = "route" ] && runOnMac=true
    if $runOnMac ;then
        case $a in
            gateway )    gWay=$b  ;;
            interface )  iFace=$b ;;
        esac
    else
        [ "$a" = "0.0.0.0" ] && [ "$c" = "$a" ] && iFace=${d##* } gWay=$b
    fi
done < <(route -n 2>&1 || route -n get 0.0.0.0/0)
ip2int $gWay gw
while read lhs rhs; do
    [ "$lhs" ] && {
        [ -z "${lhs#*:}" ] && iface=${lhs%:}
        [ "$lhs" = "inet" ] && [ "$iface" = "$iFace" ] && {
            mask=${rhs#*netmask }
            mask=${mask%% *}
            [ "$mask" ] && [ -z "${mask%0x*}" ] &&
                printf -v mask %u $mask ||
                ip2int $mask mask
            ip2int ${rhs%% *} ip
            (( ( ip & mask ) == ( gw & mask ) )) &&
                int2ip $ip myIp && int2ip $mask netMask
        }
    }
done < <(ifconfig)
LOCALIP=$myIp

read -p "Installation path [$INSTALLDIR]:" ANSWER
if [ "$ANSWER" != "" ];then
    INSTALLDIR=$ANSWER
fi

read -p "Local ip address [$LOCALIP]:" ANSWER
if [ "$ANSWER" != "" ];then
    LOCALIP=$ANSWER
fi

echo "Installing in $INSTALLDIR..."

mkdir -p $INSTALLDIR

WORKDIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) >/dev/null && pwd )

cd $WORKDIR/docker

IMAGENUM=`/usr/bin/docker images | grep asterisk-dongle | wc -l`
if [ $IMAGENUM -gt 0 ]; then
    read -p "Image asterisk-dongle exists. Would you like to build new image? y/N: " ANSWER
    if [ "$ANSWER" == "y" ]; then
        docker build -t asterisk-dongle --force-rm .
    fi
else
    docker build -t asterisk-dongle --force-rm .
fi

cp -rf $WORKDIR/asterisk-config $INSTALLDIR/
cp -f $WORKDIR/run-asterisk.sh $INSTALLDIR/
sed -i 's/externaddr.*/externaddr='$LOCALIP'/' $INSTALLDIR/asterisk-config/sip.conf

read -p "Number of GSM modems for first run [Default $NUM_MODEM]:" ANSWER
if [ "$ANSWER" != "" ];then
    $INSTALLDIR/run-asterisk.sh $ANSWER
else
    $INSTALLDIR/run-asterisk.sh $NUM_MODEM
fi
