#!/bin/bash

#simple script to control the camera, eg. at start time

sleep 10

v4l2-ctl -d /dev/video2 -c brightness=125
v4l2-ctl -d /dev/video2 -c contrast=108
v4l2-ctl -d /dev/video2 -c saturation=96
v4l2-ctl -d /dev/video2 -c white_balance_automatic=0
v4l2-ctl -d /dev/video2 -c gain=33
v4l2-ctl -d /dev/video2 -c power_line_frequency=2
v4l2-ctl -d /dev/video2 -c white_balance_temperature=5060
v4l2-ctl -d /dev/video2 -c sharpness=124
v4l2-ctl -d /dev/video2 -c backlight_compensation=0
v4l2-ctl -d /dev/video2 -c auto_exposure=1
v4l2-ctl -d /dev/video2 -c exposure_time_absolute=80
v4l2-ctl -d /dev/video2 -c exposure_dynamic_framerate=0
v4l2-ctl -d /dev/video2 -c pan_absolute=0
v4l2-ctl -d /dev/video2 -c tilt_absolute=0
v4l2-ctl -d /dev/video2 -c focus_absolute=30
v4l2-ctl -d /dev/video2 -c focus_automatic_continuous=0
v4l2-ctl -d /dev/video2 -c zoom_absolute=130
v4l2-ctl -d /dev/video2 -c led1_mode=3
v4l2-ctl -d /dev/video2 -c led1_frequency=0

