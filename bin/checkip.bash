#! /bin/bash
ip=`curl -4s icanhazip.com`
previpfile=~/tmp/previp
if [ -f $previpfile ]; then
    previp=`cat $previpfile`
    if [ "$ip" != "$previp" ]; then
        echo changed from $previp to $ip
    fi
fi
mkdir -p ${previpfile%/*}
echo $ip > $previpfile
