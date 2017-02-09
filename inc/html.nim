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
 <body lang="ru">
 <script src="/jquery.js"></script>
 <script src="/masked.js"></script>
 <script>
jQuery(function($){
   $(".phone").inputmask("+7 (999) 999-99-99");
});
</script>

 <div id="img">
   <a href="http://""" & gatewayHost & """/">
   <img class="logo" src="/logo_big.png" alt="" />
   <img class="logo_small" src="/logo.png" alt="" />
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

  <div class="shitty big">Зарегистрируйтесь, дорогие мои!</div>

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

    $if smsEnabled or okEnabled or fbEnabled or vkEnabled {
        <h1>Войдите через</h1>
    }

    $else {
      <p>Извините, доступ в сеть временно отключен</p>
    }
  </div>

  $if vkEnabled or okEnabled or fbEnabled {
    <div id="socnetworks">
      $if vkEnabled {
        <a href="http://$gatewayHost/vk_redirect"><img class="snimg" src="/vk.png" alt="Вконтакте" /></a>
      }

      $if okEnabled {
        <a href="http://$gatewayHost/ok_redirect"><img class="snimg" src="/ok.png" alt="Одноклассники" /></a>
      }

      $if fbEnabled and ctx.revisited {
        <a href="http://$gatewayHost/fb_redirect"><img class="snimg" src="/fb.png" alt="Facebook" /></a>
      }

      <h1>или</h1>
    </div>
  }

  $if smsEnabled {
    <form action="/sms_redirect" method="get">
      <div class="smoothinputcontainer">
        <div class="smoothinput">
          <img class="icon" src="/phone.png" alt="">
          <input class="phone" required name="phone" type="text" placeholder="+7 (___) ___-__-__" size="18">
          <input class="send" type="image" alt="->" src="/send.png">
        </div>
      </div>
    </form>
  }

<hr class="line" style="height: 2px;width: 100%;border-color: white;" />
   <div class="shitty medium">«Наслаждайтесь просторами Интернетов, дорогие&nbsp;мои!»</div>
   <div class="curved medium">Ваша Нью-Йоркская Бабушка</div>
   <div id="space"></div>

  <div id="info">
    <div class="small">Любимое всеми нами законодательство РФ обязывает идентифицировать каждого пользователя перед доступом в публичную Wi-Fi сеть, поэтому зарегистрируйтесь, Дорогие мои!</div>
    <div id="space"></div>
  </div>

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
        <div class="smoothinputcontainer">
          <div class="smoothinput">
            <img class="icon" src="/letter.png" alt="">
            <input class="code" required name="code" type="text" pattern="[0-9]{5}" placeholder="12345" size="5">
            <input class="send" type="image" alt="->" src="/send.png">
          </div>
        </div>
    </form>

   <div id="space"></div>
      <h1></h1>
   <div class="shitty medium">«Наслаждайтесь просторами Интернетов, дорогие&nbsp;мои!»</div>
   <div class="curved medium">Ваша Нью-Йоркская Бабушка</div>
   <div id="space"></div>

  </div>
$footer
"""

proc allOk*(): string = tmpli html"""
$header
  <div id="class">
    <div class="shitty big">Отлично! Можно пользоваться интернетом.</div>
  </div>
$footer
"""

