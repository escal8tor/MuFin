#!/bin/bash

. /etc/os-release

if [ -v NAME ]; then
  OS_NAME=$NAME
fi

case $OS_NAME in

  MustardOS)
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

    if [[ -f "$RUNPATH/bin/mpv" ]]; then
        export LD_LIBRARY_PATH="$RUN_PATH/bin/libs.aarch64/mpv/:$LD_LIBRARY_PATH"
        $RUN_PATH/bin/mpv --fs $@ #--msg-level=all=debug &> data/playback.log
    else
        /usr/bin/mpv --fs $@ #--msg-level=all=debug &> data/playback.log
    fi

    pkill -9 -f gptokeyb2
    $GPTOKEYB2 "love" -c "$RUN_PATH/res/input/gp2k_client.ini" &
    kill -CONT $(pidof love)

    unset SDL_HQ_SCALER SDL_ROTATION SDL_BLITTER_DISABLED
    exit 0
    ;;

  ROCKNIX)
    . /etc/profile
    . /usr/config/PortMaster/control.txt >/dev/null

    #kill -STOP $(pidof love)
    kill -9 $(pidof gptokeyb2 mpv)

    set_kill set "mpv"
    systemctl start mpv

    RUN_PATH="/storage/roms/ports/MuFin"
    FBWIDTH="$(fbwidth)"
    FBHEIGHT="$(fbheight)"

    if [[ ${FBWIDTH} -ge ${FBHEIGHT} ]]; then
      RES="${FBWIDTH}x${FBHEIGHT}"
    else
      RES="${FBHEIGHT}x${FBWIDTH}"
    fi

    #export LD_LIBRARY_PATH="$RUN_PATH/bin/libs.aarch64/mpv/:$LD_LIBRARY_PATH"

    $GPTOKEYB2 "mpv" -c "$RUN_PATH/res/input/gp2k_player.ini" &
    /usr/bin/mpv --fullscreen --geometry=${RES} --hwdec=auto-safe $@ #--input-ipc-server=/tmp/mpvsocket "${1}" --input-gamepad=yes

    systemctl stop mpv
    kill -9 $(pidof mpv gptokeyb2)
    $GPTOKEYB2 "love" -c "$RUN_PATH/res/input/gp2k_client.ini" &
    #kill -CONT $(pidof love)

    exit 0
    ;;

esac
