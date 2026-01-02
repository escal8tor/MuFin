#!/bin/sh

# DESCRIPTION: Initiates playback for a url
# AUTHOR: nvcuong1312

source /opt/muos/script/var/func.sh
source /mnt/mmc/MUOS/PortMaster/muos/control.txt >/dev/null

SETUP_SDL_ENVIRONMENT
RUN_PATH="$(GET_VAR "device" "storage/rom/mount")/MUOS/application/MuFin/app"
SDL_HQ_SCALER="$(GET_VAR "device" "sdl/scaler")"
SDL_ROTATION="$(GET_VAR "device" "sdl/rotation")"
SDL_BLITTER_DISABLED="$(GET_VAR "device" "sdl/blitter_disabled")"
export SDL_HQ_SCALER SDL_ROTATION SDL_BLITTER_DISABLED

kill -STOP $(pidof love)
pkill -9 -f gptokeyb2 

cd "$RUNPATH" || exit 1
SET_VAR "system" "foreground_process" "mpv"

$GPTOKEYB2 "mpv" -c "$RUN_PATH/res/input/gp2k_player.ini" &
export LD_LIBRARY_PATH="$RUN_PATH/bin/libs.aarch64/mpv/:$LD_LIBRARY_PATH"
$RUN_PATH/bin/mpv --fs $@  #--msg-level=all=debug &> data/playback.log

pkill -9 -f gptokeyb2
$GPTOKEYB2 "love" -c "$RUN_PATH/res/input/gp2k_client.ini" &
kill -CONT $(pidof love)

unset SDL_HQ_SCALER SDL_ROTATION SDL_BLITTER_DISABLED