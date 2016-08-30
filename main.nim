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

var methods = initTable[string, Method]()

when SMS_ENABLED:
  import ./inc/sms
  methods["sms"] = SMS_METHOD

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
    cond thisHost
    resp html.mainPage(pageCtx(
      error: @"error",
      revisited: revisited request,
    ))

  # redirect rule (any transparent-proxied URL will be redirected to our host 
  get re".*":
    cond thisHost false
    redirect "http://$1/" % config.gatewayHost

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
      redirect errorRedirect res.error
    else:
      # save identity
      setCookie("id", res.id, daysForward(365 * 5))
      setCookie("sign", cryptoHash(res.id), daysForward(365 * 5))
      # success! allow internet access and all the stuff
      allowInternetAccess request.ip
      redirect website

  # we are self SMS-oauth provider -- serve code enter page
  get "/sms_code":
    when SMS_ENABLED: # save binary size if it's disabled
      cond smsEnabled
      resp html.smsCode(@"phone")

randomize() # make sure codes are always different
runForever()
