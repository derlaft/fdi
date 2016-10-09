import secureHash, cgi, strutils, os, times, strtabs, osproc

import ./config

const
  # no hash extenstion attackh
  hashtail = "nohashextensionaрttack"

  # command to enable internet access for a user
  setmark = """/bin/sh -c "iptables -t mangle -A PREROUTING \
    -m mac --mac-source $1 \
    -p tcp -j MARK --set-mark 0x1" """

  allowIPcmd = """/bin/sh -c "for host in $2; do
    for port in 80 443; do
    iptables -I zone_$3_forward \
    -m mac --mac-source $1 \
    -m time --utc --datestop $4 \
    -p tcp -d \$$host --dport \$$port -j ACCEPT; done; done" """

  getMACfromARP = """/bin/sh -c "cat /proc/net/arp | grep '^$1 ' | tr ' ' '\n' | grep :" """
  getMACcmd = """/bin/sh -c "arping -I wlan0 $1 -c1 | tr ' ' '\n' | grep : | tr -d '[]' | grep :" """

type
  Redirect* = ref object
    url*: string
    error*: string

  CheckCode* = ref object
    id*: string
    error*: string

  Method* = ref object
    # oauth step1 func
    Redirect*:  proc(t: StringTableRef): Redirect
    # oauth step2 func
    CheckCode*:  proc(t: StringTableRef): CheckCode
    Enabled*: bool
    # we can allow login only if primary method is remembered
    Primary*: bool
    # hosts to temporary allow
    Hosts*: seq[string]

# debug functions; disabled in release mode
when not defined(release):
  import logging
  template D*(a: string) = debug(a)
else:
  template D*(a: string) = discard a

proc cryptoHash*(a: string): string = $secureHash(secret & a & hashtail)

proc `%%`*(a: string): string = encodeURL(a)

proc osExec(cmd: string): int =
  when not defined(release):
    var res = execShellCmd(cmd)
    D("Exec `$1` returned $2" % [cmd, $res])
    return res
  else:
    execShellCmd(cmd)

proc stripNewline(str: string): string = str.split(NewLines).join("")

proc resolveMac(ip: string): string =

  let (mac, errC) = execCmdEx( getMACfromARP % ip )

  if errC == 0 and mac != "00:00:00:00:00:00":
    return stripNewline(mac)

  for tries in countdown(5, 1):

    let (pingedMac, exitCode) = execCmdEx(getMACcmd % ip)

    D("TRY $1: got $2" % [$tries, $exitCode])
    if exitCode == 0:
      return stripNewline(pingedMac)

  return nil

proc allowInternetAccess*(ip: string): int =

  let mac = resolveMac(ip)
  if mac == nil:
    return 1

  osExec(setmark % mac)

proc date*(): string = format(getLocaltime(getTime()), "ddMMMMyyyy")

# allow ip access (port 443) for 2 minutes
proc allowIP*(who: string, what: seq[string]): int =

  let whatString = what.join(" ")

  let allowUpTo = format( getGMTime((getTime() + 2.minutes)), "yyyy-MM-dd'T'HH:mm")

  let mac = resolveMac(who)
  if mac == nil:
    return 1

  osExec(allowIPcmd % [
    mac, # mac address of sender
    whatString, # ip address we allow access for
    zone, # firewall zone
    allowUpTo
  ])

