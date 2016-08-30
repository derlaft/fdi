#!/bin/sh

flags=(
  --deadCodeElim:on # remove unused code
#  -d:uClibc         # uClibc-specific code
#  --os=linux        # target OS
#  --cpu=mips        # target CPU
  --verbosity:2     # verbose gcc output log
  -d:ssl            # enable SSL support; enable only when needed: social networks _require_ it; sms may require

  # social networks
  -d:with_sms
  -d:with_vk
  -d:with_ok
  -d:with_fb
)

if [[ "$1" == 'release' ]]; then
  flags+=(
		-d:release					# enable release mode (disables various checks and etc)
    --passL="-Os -flto" # enable flto on linker time
		--opt:size					# optimeze for size
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
