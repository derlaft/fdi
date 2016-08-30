import re, random, httpclient, strutils, cgi, strtabs, parsecfg, times

import ./config, ./expiretable, ./util

type SmsSendResult = ref object
  success: bool
  message: string

var
  codes = newStringTable()

let
  smsRestURL = CFG.getSectionValue("SMS", "restURL")
  smsMessageFormat* = CFG.getSectionValue("SMS", "messageFormat")

  myLittleRedis = newExpire()

const
  SMS_LIMITER = "smslimit"


proc correctPhone(phone: string): bool = phone.match(re"^7[0-9]{10}$")

proc generateCode(): int = (10000 + random(89999))

proc sendSMS(phone, message: string): SmsSendResult =

  D("Sending SMS: +$1: $2" % [phone, message])

  try:
    let resp = request(
      url=smsRestURL % [phone, encodeURL(message)],
      timeout=defaultTimeout
    ).body

    D("Sending SMS resp: $1" % resp)

    if resp.contains("accepted"):
      SmsSendResult(success: true, message: resp)
    else:
      SmsSendResult(success: false, message: resp)
  except:
    SmsSendResult(success: false, message: getCurrentExceptionMsg())

proc getSMSRedirect(parameters: StringTableRef): Redirect {.procvar.} =

  let phone = parameters["phone"]

  # ignore bad numbers
  if not correctPhone(phone):
    return Redirect(error: "Incorrect phone number")

  # limit sms per minutes to 5
  if myLittleRedis.get(SMS_LIMITER) > 5:
    return Redirect(error: "Plase wait")
  D("Incrementing SMS_LIMITER")
  myLittleRedis.inc(SMS_LIMITER, 1.minutes)

  # generate and save code
  let code = generateCode()
  myLittleRedis.put(phone, code, 5.minutes)

  # send SMS
  let message = smsMessageFormat % $code
  let res = sendSMS(phone, message)

  # checker result
  if res.success:
    Redirect(url: "http://$1/sms_code?phone=$2" % [gatewayHost, phone])
  else:
    Redirect(error: res.message)

proc doSMSCheck(parameters: StringTableRef): CheckCode {.procvar.} =

  let phone = parameters["phone"]
  # ignore bad numbers; really necessary because we keep both codes and tries in myLittleRedis
  if not correctPhone(phone):
    return CheckCode(error: "Incorrect phone number")

  let code = parameters["code"]
  let savedCode = myLittleRedis.get(phone)

  D("Checking sms $1: $2 ==? $3" % [phone, code, $savedCode])

  if savedCode > 0 and $savedCode == code:
    CheckCode(id: phone)
  else:
    CheckCode(error: "Incorrect code")

let
  SMS_METHOD* = Method(
    Redirect: getSMSRedirect,
    CheckCode: doSMSCheck,
    Enabled: smsEnabled,
    Primary: true,
  )
