# fdi
Openwrt-based router auth system

# Installation (on deb-based example)

* Get a nim compiler: ```apt install nim build-essential```
* Install needed dependencies: ```nimble install jester template```
* Install LEDE/openwrt toolchain and build it for your router. Your target is ```make toolchain/gcc```. See [openwrt instructions](https://wiki.openwrt.org/doc/howto/buildroot.exigence).
* Clone this repository: ```git clone https://github.com/derlaft/fdi.git```
* Edit build.sh, change openwrt toolchain path and architecture if needed.
* Run build: ```bash ./build.sh```
* If everything is OK, you will get an executable named ```main```. Place it, ```gateway.cfg``` and ```public/``` directory to the router.
* On the router, you will need to install some packages: ```opkg install libpthread librt libopenssl libpcre```
* Make sure you have enough RAM and disk space. I recommend at least 8Mb disk space. Install ```zram-swap``` package if you are low on mem.
