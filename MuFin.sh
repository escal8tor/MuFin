#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present redwolftech
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

. /etc/profile
. /usr/config/PortMaster/control.txt >/dev/null

set_kill set "love"
#systemctl start love

RUN_PATH="/storage/roms/ports/MuFin"
FBWIDTH="$(fbwidth)"
FBHEIGHT="$(fbheight)"

if [[ ${FBWIDTH} -ge ${FBHEIGHT} ]]; then
  RES="${FBWIDTH}x${FBHEIGHT}"
else
  RES="${FBHEIGHT}x${FBWIDTH}"
fi

cd "$RUN_PATH" || exit 1
export LD_LIBRARY_PATH="$RUN_PATH/bin/libs.aarch64/love/:$LD_LIBRARY_PATH"

$GPTOKEYB2 "love" -c "$RUN_PATH/res/input/gp2k_client.ini" &
./bin/love .

#systemctl stop love
pkill -9 -f gptokeyb2
exit 0

