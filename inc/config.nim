import parsecfg, strutils

const 

  defaultTimeout* = 30000

  SMS_ENABLED* = defined(with_sms)
  VK_ENABLED* = defined(with_vk)
  OK_ENABLED* = defined(with_ok)
  FB_ENABLED* = defined(with_fb)

let
  CFG* = loadConfig("gateway.cfg")

  gatewayHost* = CFG.getSectionValue("Gateway", "host")
  secret* = CFG.getSectionValue("Gateway", "secret")
  website* = CFG.getSectionValue("Gateway", "website")
  zone* = CFG.getSectionValue("Gateway", "zone")

  errorPageLocation* = "http://$1/?error=" % gatewayHost
  smsErrorPageLocation* = "http://$1/sms_code?error=" % gatewayHost

  smsEnabled* = SMS_ENABLED and parseBool(CFG.getSectionValue("SMS", "enabled"))
  vkEnabled* = VK_ENABLED and parseBool(CFG.getSectionValue("VK", "enabled"))
  fbEnabled* = FB_ENABLED and  parseBool(CFG.getSectionValue("Facebook", "enabled"))
  okEnabled* = OK_ENABLED and parseBool(CFG.getSectionValue("OK", "enabled"))
