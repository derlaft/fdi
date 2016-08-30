import strutils, json, httpclient, parsecfg, strtabs

import ./config, ./util

let
  fbRedirectURL = "http://$1/fb_callback" % gatewayHost

  fbAppID = CFG.getSectionValue("Facebook", "appID")
  fbAppSecret = CFG.getSectionValue("Facebook", "appSecret")

const
  fbOauthURL = "https://www.facebook.com/dialog/oauth?client_id=$1&redirect_uri=$2"
  fbCheckURL = "https://graph.facebook.com/v2.3/oauth/access_token?client_id=$1&redirect_uri=$3&client_secret=$2&code=$4"

proc getFbRedirect(parameters: StringTableRef): Redirect {.procvar.} =
  Redirect(url: fbOauthURL % [fbAppID, fbRedirectURL])

proc doFbCheck(parameters: StringTableRef): CheckCode {.procvar.} =

  let code = parameters["code"]

  try:

    # check user supplied-code
    let URL = fbCheckURL % [fbAppID, fbAppSecret, fbRedirectURL, code]
    let res = parseJson(request(url=URL, timeout=defaultTimeout).body)

    let access_token =  $res["access_token"]
    if access_token == "":
      CheckCode(id: "fb", error: "Invalid Facebook token")
    else:
      CheckCode(id: "fb")

  except:

    CheckCode(error: getCurrentExceptionMsg())

let
  FB_METHOD* = Method(
    Redirect: getFbRedirect,
    CheckCode: doFbCheck,
    Enabled: fbEnabled,
    Primary: false,
    Hosts: @["facebook.com"],
  )
