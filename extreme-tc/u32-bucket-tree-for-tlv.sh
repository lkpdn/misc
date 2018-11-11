#!/bin/bash

ip l add ifb0 type dummy
ip l set dev ifb0 up

# u32 bucket tree for TLV packet.
#
#   The action is for RADIUS User-Name AVP, which is highly likely to be in the position
#   less than eighth Attribute. In other words, u32 deadloop is eight so we cannot
#   reach that far if it were to be such a peculiar RADIUS request.
#
tc qdisc add dev eth0 ingress
tc qdisc add dev ifb0 root handle 1: htb default 1
tc filter add dev eth0 parent ffff: prio 99 handle 800::1 u32 match u32 0 0 flowid 1:1 action mirred egress mirror dev ifb0
alias tfilter='tc filter add dev ifb0 parent 1: prio 99'
tfilter handle fe:: u32 divisor 1
tfilter handle ff:: u32 divisor 256
tfilter handle fe::1 u32 ht fe:: match u8 0 0 link ff:: hashkey mask 0xf0000000 at 0
tfilter handle ff:1:1 u32 ht ff:: match u8 0 0 offset plus 2 action pedit pedit munge offset 2 u16 set 0xffff
for i in $(seq 2 255); do
  x=$(printf "%x" $i)
  tfilter handle ff:$x:1 u32 ht ff:$x: match u8 0 0 link ff:: hashkey mask 0xf0000000 at 0 offset at 0 mask 0x0f00 shift 0 eat
done
tfilter u32 ht 800: match ip protocol 17 0xff offset plus 8 at 0 mask 0x0f00 shift 6 eat link fe::
