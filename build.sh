#!/bin/sh

CROSS="/home/user/openwrt/staging_dir/toolchain-mips_34kc_gcc-4.8-linaro_uClibc-0.9.33.2/bin/mips-openwrt-linux-uclibc-"

flags=(
  --deadCodeElim:on # remove unused code
  --verbosity:2     # verbose gcc output log
  -d:ssl            # enable SSL support; enable only when needed: social networks _require_ it; sms may require

  # social networks
  -d:with_sms
  -d:with_vk
  -d:with_ok
  -d:with_fb

#    -d:uClibc         # uClibc-specific code
#    --os=linux        # target OS
#    --cpu=mips        # target CPU
)

if [[ "$1" == 'release' ]]; then
  flags+=(
		-d:release					# enable release mode (disables various checks and etc)
    --passL="-Os -flto" # enable flto on linker time
		--opt:size					# optimeze for size
    -d:uClibc         # uClibc-specific code
    --os=linux        # target OS
    --cpu=mips        # target CPU
  )
fi

if nim c "${flags[@]}" main.nim; then
  if [[ "$1" == 'release' ]]; then
    ${CROSS}strip main
  fi

  du -hs main
  true
else
  false
fi
