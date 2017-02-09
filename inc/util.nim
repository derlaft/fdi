import secureHash, cgi, strutils, os, times, strtabs, random

import ./config

const
  # no hash extenstion attackh
  hashtail = "nohashextensionaрttack"

  # command to enable internet access for a user
  setmark = """/bin/sh -c "iptables -t nat -I PREROUTING \
    -m time --utc --datestop $2 \
    -p tcp -s $1 -j MARK --set-mark 0x1" """

  allowIPcmd = """/bin/sh -c "for host in $2; do
    for port in 80 443; do
    iptables -I zone_$3_forward \
    -m time --utc --datestop $4 \
    -p tcp -s $1 -d \$$host --dport \$$port -j ACCEPT; done; done" """

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
  var res = execShellCmd(cmd)
  D("Exec `$1` returned $2" % [cmd, $res])
  return res

proc stripNewline(str: string): string = str.split(NewLines).join("")

# there are problems with execCmdEx when on low mem
# emulate it with tmp file
proc execCmdExWithoutPipe(cmd: string): tuple[output: string, exitCode: int] =
  let tmpFile = "/tmp/fdi$1" % $random(9999)
  let realCMD = """/bin/sh -c "($1) > $2" """ % [cmd, tmpFile]
  D("Runnin $1??" % realCMD)
  result[1] = execShellCmd(realCMD)
  D("... exitcode=$1" % $result[1])
  if existsFile tmpFile:
    result[0] = readFile(tmpFile)
    removeFile(tmpFile)
  else:
    result[0] = ""
  D("... and result $2" % [$result[1], result[0]])

proc allowInternetAccess*(ip: string): int =

  let allowUpTo = format( getGMTime((getTime() + 420.minutes)), "yyyy-MM-dd'T'HH:mm")

  osExec(setmark % [ip, allowUpTo])

proc date*(): string = format(getLocaltime(getTime()), "ddMMMMyyyy")

# allow ip access (port 443) for 2 minutes
proc allowIP*(who: string, what: seq[string]): int =

  let whatString = what.join(" ")

  let allowUpTo = format( getGMTime((getTime() + 2.minutes)), "yyyy-MM-dd'T'HH:mm")

  osExec(allowIPcmd % [
    who, # mac address of sender
    whatString, # ip address we allow access for
    zone, # firewall zone
    allowUpTo
  ])

