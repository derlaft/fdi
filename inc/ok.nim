import strutils, json, httpclient, parsecfg, strtabs, md5, re

import ./config, ./util

let
  okRedirectURL = "http://$1/ok_callback" % gatewayHost

  okAppID = CFG.getSectionValue("OK", "appID")
  okAppSecret = CFG.getSectionValue("OK", "appSecret")
  okAppPublic = CFG.getSectionValue("OK", "appPublic")

const
  okOauthURL = "https://connect.ok.ru/oauth/authorize?client_id=$1&response_type=code&redirect_uri=$2&layout=m&scope="
  okCheckURL = "https://api.ok.ru/oauth/token.do?client_id=$1&client_secret=$2&redirect_uri=$3&grant_type=authorization_code&code=$4"

  okGetUserURL = "https://api.ok.ru/fb.do?application_key=$1&method=users.getLoggedInUser&sig=$3&access_token=$2&format=json"

proc okStrip(a: string): string = a.strip(chars={'"'})

proc getOkUID(accessToken: string): string =
  try:
    let secretKey = getMD5(accessToken & okAppSecret)
    let sig = getMD5("application_key=$1format=jsonmethod=users.getLoggedInUser$2" % [okAppPublic, secretKey])
    let URL = okGetUserURL % [okAppPublic, accessToken, sig]
    let body = request(url=URL, httpMethod=httpPOST, timeout=defaultTimeout).body
    D("OK got body ($1): $2" % [URL, body])

    if body.match(re"""^"[0-9]+"$"""):
      return body.okStrip()

    return nil
  except:
    D("WUT $1" % getCurrentExceptionMsg())
    return nil

proc getOkRedirect(parameters: StringTableRef): Redirect {.procvar.} =
  Redirect(url: okOauthURL % [okAppID, okRedirectURL])

proc doOkCheck(parameters: StringTableRef): CheckCode {.procvar.} =

  let code = parameters["code"]

  try:

    # check user supplied-code
    let URL = okCheckURL % [okAppID, okAppSecret, okRedirectURL, code]
    let res = parseJson(request(url=URL, timeout=defaultTimeout, httpMethod=httpPOST).body)

    let access_token = ($res.getOrDefault("access_token")).okStrip()
    D("Acess token=$1; checking" % access_token)
    let user_id = getOkUID(access_token)

    if access_token == "" or userID == nil:
      CheckCode(id: "ok", error: "Invalid token")
    else:
      CheckCode(id: "ok$1" % $userID)

  except:

    CheckCode(error: getCurrentExceptionMsg())

let
  OK_METHOD* = Method(
    Redirect: getOkRedirect,
    CheckCode: doOkCheck,
    Enabled: okEnabled,
    Primary: true,
    Hosts: @["connect.ok.ru", "ok.ru"],
  )
