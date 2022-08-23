#!/usr/bin/env bash


function ip2int(ip, slice) {
    split(ip, slice, ".")
    return or(lshift(slice[1], 24), lshift(slice[2], 16), lshift(slice[3], 8), slice[4])
}

function incidr4(ip, cidr, cidrslice) {
    split(cidr, cidrslice, "/")
    return and(ip2int(ip), compl(rshift(0xffffffff, cidrslice[2]))) == ip2int(cidrslice[1])
}

function ip6array(ip6, out,  halves, upperslice, lowerslice, upperlen, lowerlen) {
    split(ip6, halves, "::")
    upperlen = split(halves[1], upperslice, ":")
    lowerlen = split(halves[2], lowerslice, ":")
    for (n in upperslice) {
        out[n] = strtonum("0x" upperslice[n])
    }
    for (i = upperlen+1; i <= 8; i++) {
        out[i] = 0
    }
    for (n in lowerslice) {
        out[n+8-lowerlen] = strtonum("0x" lowerslice[n])
    }
}

function incidr6(ip, cidr,  cidrslice, iparray, addrarray, len) {
    split(cidr, cidrslice, "/")
    ip6array(ip, iparray)
    ip6array(cidrslice[1], addrarray)
    len = (cidrslice[2]-(cidrslice[2]%16))/16
    for (i = 1; i <= len; i++) {
        if (iparray[i] != addrarray[i]) {
            return false
        }
    }
    return and(iparray[len+1], compl(rshift(0xffff, cidrslice[2]%16))) == addrarray[len+1]
}

function findIpV6() {
    for _ip in `ip -j -6 addr | jq -r 'map(.addr_info) | flatten | map(select(.scope="global"))|.[].local'`; do
      if (incidr6(_ip, $1)) {
          echo $1
          break
    }
    done
}

function findIpV4() {
    for _ip in `ip -j addr | jq -r 'map(.addr_info) | flatten | map(select(.scope="global"))|.[].local'`; do
      if (incidr4(_ip, $1)) {
         echo $1
         break
    }
    done
}

{
    if [ "$2" = true ] ; then
        findIpV6 $1
      else
        findIpV4 $1
      fi
}
