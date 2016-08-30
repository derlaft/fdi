import jester, asyncdispatch, re, strutils, random, times

import ./inc/config, ./inc/util, ./inc/html

# emulate virtual host, lol
template thisHost (truth : bool = true): bool =
  (request.host == config.gatewayHost) == truth

# redirect client to error landing
proc errorRedirect (err: string): string = (errorPageLocation & %%err)

proc revisited(req: Request): bool =
  try:
    cryptoHash(req.cookies["id"]) == req.cookies["sign"]
  except:
    false

import httpclient
proc remoteLog(a: string): bool =
  try:
    let res = request(url=logURL % (%%a), timeout=defaultTimeout).body
    if res.contains("ok"):
      true
    else:
      false
  except:
    false

proc redirectedFrom(request: Request): string =
  # https redirects do not work %) so assumming http
  "http://$1:$2$3" % [request.host, $request.port, request.path]

var methods = initTable[string, Method]()

when SMS_ENABLED:
  import ./inc/sms
  methods["sms"] = SMS_METHOD

  proc errorSMSRedirect (phone, err: string): string =
    "http://$1/sms_code?phone=$2&error=$3" % [gatewayHost, phone, %%err]

when FB_ENABLED:
  import ./inc/fb
  methods["fb"] = FB_METHOD

when VK_ENABLED:
  import ./inc/vk
  methods["vk"] = VK_METHOD

when OK_ENABLED:
  import ./inc/ok
  methods["ok"] = OK_METHOD

routes:
  get "/":
    if request.params.hasKey("from"):
      setCookie("from", @"from", daysForward(1))

    cond thisHost
    resp html.mainPage(pageCtx(
      error: @"error",
      revisited: revisited request,
    ))

  # redirect rule (any transparent-proxied URL will be redirected to our host 
  get re".*":
    cond thisHost false
    headers["Cache-Control"] = "no-store"
    headers["Connection"] = "close"
    redirect "http://$1/?from=$2" % [config.gatewayHost, %%(redirectedFrom request)]

  # oauth step1 (redirect to outside login page)
  get re"^\/(.*)_redirect$":
    cond thisHost
    let auth = methods[request.matches[0]]
    # well; first check is not really needed -- it generates exception
    cond auth != nil and auth.Enabled
    cond auth.Primary or revisited request

    let res = auth.Redirect(request.params)

    if res.error != nil:
      redirect errorRedirect res.error
    else:
      # redirecting! do the stuff and redirect
      for host in auth.Hosts:
        allowIP(who=request.ip, what=host)
      redirect res.url

  # oauth step2 (redirected from outside login page; must check supplied code)
  get re"^\/(.*)_callback$":
    cond thisHost
    let auth = methods[request.matches[0]]
    cond auth != nil and auth.Enabled
    cond auth.Primary or revisited request

    let res = auth.CheckCode(request.params)
    if res.error != nil:
      # sms need another page
      when SMS_ENABLED:
        if request.matches[0] == "sms":
          redirect errorSMSRedirect(@"phone", res.error)

      redirect errorRedirect res.error
    else:
      if auth.Primary: # save identity
        setCookie("id", res.id, daysForward(365 * 5))
        setCookie("sign", cryptoHash(res.id), daysForward(365 * 5))
        if not remoteLog("Id: $1;\t\t\t\t\tIp addr: $2" % [res.id, request.ip]):
          redirect errorRedirect "Could not log"
      else:
        if not remoteLog("Id: $1;\tSecondary Id: $2;\tIp addr: $3" % [request.cookies["id"], res.id, request.ip]):
          redirect errorRedirect "Could not log"

      # success! allow internet access and all the stuff
      allowInternetAccess request.ip

      if request.cookies.hasKey("from"):
        redirect request.cookies["from"]
      else:
        redirect website

  # we are self SMS-oauth provider -- serve code enter page
  get "/sms_code":
    when SMS_ENABLED: # save binary size if it's disabled
      cond smsEnabled
      resp html.smsCode(@"phone", @"error")

randomize() # make sure codes are always different
runForever()
