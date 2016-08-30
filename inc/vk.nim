import strutils, json, httpclient, parsecfg, strtabs

import ./config, ./util

let
  vkRedirectURL = "http://$1/vk_callback" % gatewayHost

  vkAppID = CFG.getSectionValue("VK", "appID")
  vkAppSecret = CFG.getSectionValue("VK", "appSecret")

const
  vkOauthURL = "https://oauth.vk.com/authorize?client_id=$1&redirect_uri=$2&display=mobile&response_type=code&v=5.53"
  vkCheckURL = "https://oauth.vk.com/access_token?client_id=$1&client_secret=$2&redirect_uri=$3&code=$4"

proc getVkRedirect(parameters: StringTableRef): Redirect {.procvar.} =
  Redirect(url: vkOauthURL % [vkAppID, vkRedirectURL])

proc doVkCheck(parameters: StringTableRef): CheckCode {.procvar.} =

  let code = parameters["code"]

  try:

    # check user supplied-code
    let URL = vkCheckURL % [vkAppID, vkAppSecret, vkRedirectURL, code]
    let res = parseJson(request(url=URL, timeout=defaultTimeout).body)

    let access_token = $res.getOrDefault("access_token")
    let user_id = $res.getOrDefault("user_id")

    if access_token == "":
      CheckCode(id: "vk", error: "Invalid VK token ($1)" % $res["error_description"])
    else:
      CheckCode(id: "vk$1" % $userID)

  except:

    CheckCode(error: getCurrentExceptionMsg())

let
  VK_METHOD* = Method(
    Redirect: getVkRedirect,
    CheckCode: doVkCheck,
    Enabled: vkEnabled,
    Primary: true,
    Hosts: @["oauth.vk.com", "m.vk.com", "login.vk.com"],
  )
