#!/usr/bin/env bash

if [[ ! -v ERROR_REQUIRE_FILE ]]; then
	readonly ERROR_REQUIRE_FILE=-3
fi
if [[ ! -v ERROR_ILLEGAL_PARAMETERS ]]; then
	readonly ERROR_ILLEGAL_PARAMETERS=-4
fi
if [[ ! -v ERROR_REQUIRE_TARGET ]]; then
	readonly ERROR_REQUIRE_TARGET=-5
fi

update_bootloader() {
	local DEVICE=$1

    if [[ -f "$SCRIPT_DIR/boot0_sdcard_sun55iw3p1.bin" ]] && [[ -f "$SCRIPT_DIR/boot_package.fex" ]]; then
		dd conv=notrunc,fsync if="$SCRIPT_DIR/boot0_sdcard_sun55iw3p1.bin" of="$DEVICE" bs=512 seek=256
		dd conv=notrunc,fsync if="$SCRIPT_DIR/boot_package.fex" of="$DEVICE" bs=512 seek=24576
	elif [[ -f "$SCRIPT_DIR/u-boot-sunxi-with-spl.bin" ]]; then
		dd conv=notrunc,fsync if="$SCRIPT_DIR/u-boot-sunxi-with-spl.bin" of="$DEVICE" bs=512 seek=256
    else
        echo "Missing U-Boot binary!" >&2
        return "$ERROR_REQUIRE_FILE"
	fi
	sync "$DEVICE"
}

erase_bootloader() {
	local DEVICE=$1

	dd conv=notrunc,fsync if=/dev/zero of="$DEVICE" bs=512 seek=256 count=1
	sync "$DEVICE"
}

erase_emmc_boot() {
	if [[ -f "/sys/class/block/$(basename "$1")/force_ro" ]]; then
		echo 0 >"/sys/class/block/$(basename "$1")/force_ro"
	fi
	blkdiscard -f "$@"
}

# https://stackoverflow.com/a/28776166
is_sourced() {
	if [ -n "$ZSH_VERSION" ]; then
		case $ZSH_EVAL_CONTEXT in
		*:file:*)
			return 0
			;;
		esac
	else # Add additional POSIX-compatible shell names here, if needed.
		case ${0##*/} in
		dash | -dash | bash | -bash | ksh | -ksh | sh | -sh)
			return 0
			;;
		esac
	fi
	return 1 # NOT sourced.
}

if ! is_sourced; then

	set -euo pipefail
	shopt -s nullglob

	SCRIPT_DIR="$(dirname "$(realpath "$0")")"

	ACTION="$1"
	shift

	if [[ $(type -t "$ACTION") == function ]]; then
		$ACTION "$@"
	else
		echo "Unsupported action: '$ACTION'" >&2
		exit "$ERROR_ILLEGAL_PARAMETERS"
	fi

fi
