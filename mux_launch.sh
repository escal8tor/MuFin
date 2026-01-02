#!/bin/bash
# HELP: MuFin
# ICON: MuFin
# GRID: MuFin

source /opt/muos/script/var/func.sh
source /mnt/mmc/MUOS/PortMaster/muos/control.txt >/dev/null

if pgrep -f "playbgm.sh" >/dev/null; then
	killall -q "playbgm.sh" "mpg123"
fi

echo app >/tmp/act_go

SETUP_SDL_ENVIRONMENT
RUN_PATH="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/MuFin/app"

cd "$RUN_PATH" || exit 1
SET_VAR "system" "foreground_process" "love"

$GPTOKEYB2 "love" -c "$RUN_PATH/res/input/gp2k_client.ini" &
export LD_LIBRARY_PATH="$RUN_PATH/bin/libs.aarch64/love/:$LD_LIBRARY_PATH"
./bin/love .

kill -9 $(pidof gptokeyb2)