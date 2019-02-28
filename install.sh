#!/bin/bash

INSTALLDIR=/opt/asterisk-dongle

read -p "Installation path [$INSTALLDIR]:" ANSWER
if [ "$ANSWER" != "" ];then
    INSTALLDIR=$ANSWER
fi

echo "Installing in $INSTALLDIR..."

mkdir -p $INSTALLDIR

#DEFIF=`route -n | egrep "^0\.0\.0\.0" | awk '{print $8}'`

WORKDIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) >/dev/null && pwd )

cd $WORKDIR/docker
#docker build -t asterisk-dongle --force-rm .

cp -rf $WORKDIR/asterisk-config $INSTALLDIR/
cp -f $WORKDIR/run-asterisk.sh $INSTALLDIR/

$INSTALLDIR/run-asterisk.sh
