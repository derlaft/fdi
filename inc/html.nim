import templates

import ./config

type pageCtx* = ref object
  revisited*: bool
  error*: string

let

  # fuck that nim; for some reason tmpli html does not work here
  header = """
<!DOCTYPE html>
<html lang="en">
 <head>
   <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0,minimum-scale=1.0, maximum-scale=1.0, user-scalable=no">
   <meta name="HandheldFriendly" content="true">
   <title>Интернет</title>
   <link rel="stylesheet" href="style.css">
 </head>
 <body>
 <div id="img">
   <a href="http://""" & gatewayHost & """/">
   <img src="/wifi.svg" alt="" />
   </a>
 </div>
"""

  footer = """
   </body>
   </html>
  """

proc mainPage*(ctx: pageCtx): string = tmpli html"""
$header
<div id="class">

  $if ctx.error != "" {
    <div class="error">
      <span>
        Произошла ошибка! Пожалуйста, попробуйте снова. Если ошибка повторяется, попробуйте другой способ входа.
      </span>
      <!-- ctx.error -->
    </div>
  }

  $if ctx.revisited {
    <div id="welcomeback">Добро пожаловать обратно.</div>
  }

  <div id="info">
    <p>Согласно законам РФ, для получения доступа к Интернету вы <b>обязаны</b> подтвердить свою личность.</p>
    $if smsEnabled or okEnabled or fbEnabled or vkEnabled {
      <p>Это можно сделать следующими способами:</p>
    }
    $else {
      <p>Нет доступных способов подтверждения личности. Доступ в интернет отключен.</p>
    }
  </div>

  $if smsEnabled {
    <div id="phone-cap">По номеру телефона:</div>
    <form action="/sms_redirect" method="get">
      <input class="phone" required name="phone" type="text" pattern="7[0-9]{10}" placeholder="79991237733">
      <input type="submit" value="Отправить">
    </form>
  }

  $if vkEnabled or okEnabled or fbEnabled {
    <div id="socnetworks">
      <p>При помощи социальных сетей:</p>

      $if vkEnabled {
        <a href="http://$gatewayHost/vk_redirect"><img class="snimg" src="/vk.png" alt="Вконтакте" /></a>
      }

      $if okEnabled {
        <a href="http://$gatewayHost/ok_redirect"><img class="snimg" src="/ok.png" alt="Одноклассники" /></a>
      }

      $if fbEnabled and ctx.revisited {
        <a href="http://$gatewayHost/fb_redirect"><img class="snimg" src="/fb.png" alt="Facebook" /></a>
      }
    </div>
  }
</div>
$footer
"""

proc smsCode*(phone, error: string): string = tmpli html"""
$header
  <div id="class">
    $if error != "" {
      <div class="error">
        <span> Ошибка! Неправильный код </span>
        <!--  -->
      </div>
    }
    <p>Введите код, отправленный при помоши SMS-сообщения:</p>
    <form action="/sms_callback" method="get">
        <input name="phone" type="hidden" value="$phone">
        <input class="code" required name="code" type="text" pattern="[0-9]{5}" placeholder="12345">
        <input type="submit" value="OK">
    </form>
  </div>
$footer
"""

