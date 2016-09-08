import secureHash, cgi, strutils, os, times, strtabs

import ./config

const
  # no hash extenstion attackh
  hashtail = "nohashextensionaрttack"

  # command to enable internet access for a user
  setmark = """/bin/sh -c "iptables -t mangle -A PREROUTING \
    -m mac --mac-source $$(cat /proc/net/arp | grep '^$1 ' | awk '{print $$4}') \
    -p tcp -j MARK --set-mark 0x1" """

  allowIPcmd = """/bin/sh -c "iptables -I zone_$3_forward \
    -m mac --mac-source $$(cat /proc/net/arp | grep '^$1 ' | awk '{print $$4}') \
    -m time --utc --datestop  $4 \
    -p tcp -d $2 --dport 443 -j ACCEPT" """

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


proc allowInternetAccess*(ip: string) =
  discard osExec(setmark % ip)

proc date*(): string = format(getLocaltime(getTime()), "ddMMMMyyyy")

# allow ip access (port 443) for 2 minutes
proc allowIP*(who, what: string)  =

  let allowUpTo = format( getGMTime((getTime() + 2.minutes)), "yyyy-MM-dd'T'HH:mm")

  discard osExec(allowIPcmd % [
    who, # ip address of sender
    what, # ip address we allow access for
    zone, # firewall zone
    allowUpTo
  ])
