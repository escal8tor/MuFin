#! /bin/bash

function local_network {
    # Get local network subnet.
    local def_if=$(ip -o r | awk '/default/ {print $5}')
    echo $(ip -o r | grep $def_if | awk '/\// {print $1}')
}

function ip_range {
    # Generate a range of IPv4 addresses in a subnet.
    # ref: https://stackoverflow.com/a/58218274
    local a b c d mask ip start end
    local base=${1%/*}
    local cidr=${1#*/}
    local ifs=$IFS

    IFS='.'
    read a b c d <<<$base
    IFS=$ifs

    ((mask=0xFFFFFFFF<<(32-$cidr)))
    ((ip=($b<<16)+($c<<8)+$d))
    ((start=$ip&$mask))
    ((end=($start|~$mask)&0x7FFFFFFF))

    seq $start $end | while read i; do
        ((b=($i&0xFF0000)>>16))
        ((c=($i&0xFF00)>>8))
        ((d=$i&0x00FF))

        echo "$a.$b.$c.$d"
    done
}

function scan_host {
    # Test Jellyfin host url.
    local url="$1://$4:$2"
    local rsp=$(curl "$url/System/Info/Public" -k -s --connect-timeout $3)
    [[ -n $rsp ]] && echo -e "$url" || exit 1
}

export -f scan_host

SUBNET=${1:-`local_network`} # local network CIDR
PROTO=${2:-https} # protocol 'http|https'
PORT=${3:-8920} # port on which to connect
TIMEOUT=${4:-.5} # connection timeout
#OUTPATH=${3:-"$LOVEDIR/data/scan_results"}

ip_range $SUBNET | 
xargs -n1 -P0 bash -c 'scan_host "$@"' _ $PROTO $PORT $TIMEOUT