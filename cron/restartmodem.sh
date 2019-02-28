#!/bin/bash
# частота запуска скрипта - каждые 4 секунды 12 раз в минуту
#если в теченнии 36 запусков статус модема постоянно Dialing/Ring/SMS, то перезапускаем модем

container="asterisk-dongle"
workdir="/usr/scripts"
modemcount=`/usr/bin/docker exec $container /usr/sbin/asterisk -rx "dongle show devices" | grep dongle | wc -l`
dirstatus="/usr/scripts/modemstatus"
mkdir -p $dirstatus
restartcount=36
repeat=12
delay=4
j=0

while (( j++ < repeat )); do
    for (( i=0; i<=$modemcount-1; i++ ))
    do
	modemstatus="$dirstatus/modem$i"
	status=`/usr/bin/docker exec $container /usr/sbin/asterisk -rx "dongle show device state dongle$i" | awk '/State/{print $3}'`
	echo $status
	num=0
	if [ "$status" == "Dialing" ] || [ "$status" == "Ring" ] || [ "$status" == "SMS" ]; then
	    test -f $modemstatus && read num < $modemstatus
	    let "num+=1"
	fi

	if  [ $num -gt $restartcount ]; then
	    result=`/usr/bin/docker exec $container /usr/sbin/asterisk -rx "dongle restart now dongle$i"`
	    echo `date` $result
	    num=0
	fi
	echo $num > $modemstatus
	done
	sleep $delay
    done
exit
