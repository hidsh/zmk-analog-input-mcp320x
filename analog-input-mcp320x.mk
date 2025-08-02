# Makefile for zmk
#
# Install:
#   1. cd PATH/TO/zmk/app
#   2. ln -s PATH/TO/THIS.mk ./Makefile
#
# Usage:
#   1. cd PATH/TO/zmk/app
#   2. make

SHIELD = analog-input-mcp320x
BOARD = seeeduino_xiao_ble
DRV_NAME = XIAO
KBD_PID = 615e					# product id

# abs path to this makefile
mkpath = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# for usb-debugging, or comment out if you don't need it
OPT_USB_LOGGING = --snippet zmk-usb-logging

# for un-official drivers
#         -DZMK_EXTRA_MODULES='/PATH/TO/foo;/PATH/TO/bar;...'
# OPT_DRV = -DZMK_EXTRA_MODULES='${mkpath}/zmk-modules/zmk-analog-input-driver'

# for save *.i to check macro expansion `#define XXX`
# OPT_C_FLAGS = -DCMAKE_C_FLAGS="-save-temps"


.PHONY: build flash info

flash: build
	@echo -n ':: Flashing: '
	@find $$(pwd) -name *.uf2 | xargs ls -l | cut -d ' ' -f 6-
	@echo -n '::           '
	@find $$(pwd) -name *.uf2 | xargs file -b | cut -d ',' -f 1,2
	@echo ':: DOUBLE CLICK RESET BUTTON ON XIAO!!'
	@until mount | grep --quiet ${DRV_NAME}; do echo -n '.'; sleep 1; done; echo
	@-west flash 2> /dev/null
	@sleep 1
	@echo -n ':: '
	@timeout 5s sh -c "until grep --ignore-case --fixed-strings '${SHIELD}' /proc/bus/input/devices | cut -d ' ' -f 2-; do sleep 1; done"
	@cyme | grep ${KBD_PID}
	@echo ':: done flashing.'

build: info
	west build  --pristine \
	            --board ${BOARD} \
	            ${OPT_USB_LOGGING} \
	            --  -DSHIELD=${SHIELD} \
	                -DZMK_CONFIG='${mkpath}/config' \
	                ${OPT_DRV} \
	                ${OPT_C_FLAGS}

info:
	@echo -n ':: Reading: '
	@find $$(pwd) -maxdepth 1 -name $(firstword $(MAKEFILE_LIST)) | xargs ls -l | cut -d ' ' -f 8-
	@echo '::   Board:   '${BOARD}
	@echo '::   Shield:  '${SHIELD}
	@echo '::   KBD_PID: '${KBD_PID}
