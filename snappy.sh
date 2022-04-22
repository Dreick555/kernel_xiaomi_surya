#!/bin/bash
#
# Copyright (C) 2022 TheStrechh (Carlos Arriaga).
#



HOME="/home/carlos/kernel"
SECONDS=0 # builtin bash timer
ZIPNAME="Snappy-surya-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="/home/carlos/kernel/tc/yuki-clang"
GCC_64_DIR="/home/carlos/kernel/tc/aarch64-linux-android-4.9"
GCC_32_DIR="/home/carlos/kernel/tc/arm-linux-androideabi-4.9"
AK3_DIR="/home/carlos/kernel/AnyKernel3"
DEFCONFIG="surya_defconfig"

if [[ $1 = "-r" || "$regen" = yes ]]; then
	make O=out ARCH=arm64 $DEFCONFIG
	cp out/.config arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

if [[ $1 = "-c" || "$clean" = yes ]]; then
	rm -rf out
	rm -rf *.zip
	echo -e "\nSuccessfully delete all shit"
	exit
fi

if [[ $1 = "-b" || "$build" = yes ]]; then
mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j4 O=out ARCH=arm64 CC=clang CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz dtbo.img

kernel="out/arch/arm64/boot/Image.gz"
dtb="out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtb" ] && [ -f "$dtbo" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if [ -d "$AK3_DIR" ]; then
		cp -r $AK3_DIR AnyKernel3
	elif ! git clone -q https://github.com/TheStrechh/AnyKernel3 -b master; then
		echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
		exit 1
	fi
	cp $kernel $dtbo AnyKernel3
	cp $dtb AnyKernel3/dtb
	rm -rf out/arch/arm64/boot
	cd AnyKernel3
	git checkout master &> /dev/null
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
else
	echo -e "\nCompilation failed!"
	exit 1
fi
fi
