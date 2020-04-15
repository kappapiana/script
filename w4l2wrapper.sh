#!/usr/bin/env bash

deb_ver=`cat /etc/debian_version`
# red=$(tput setaf 1)
green=$(tput setaf 76)
normal=$(tput sgr0)
bold=$(tput bold)

declare -a controls_array=()
declare -a controls_array_plus=()
mapfile -t controls_array < <(v4l2-ctl -d /dev/video0 --list-ctrls | awk '{print $1}')

function check_i {
  if [ $? -eq 0 ]; then
    i_ok
  else
    i_ko; read -r
    exit
  fi
}

function list_channels {

printf "%s \n" "${controls_array[@]}"

}

function get_values {
  for i in ${controls_array[@]} ; do
  v4l2-ctl --get-ctrl=${i}
done
}


function set_values {

controls_array_plus=("${controls_array[@]}" "list" "quit")

select value in ${controls_array_plus[@]}
do
if [[  ${value} == "quit" ]] ; then
  printf "\\nThanks!\\n\\nWe have set the following values:\\n\\n"
  return 1
elif [[ ${value} == "list" ]] ; then
  clear
  printf "These are the current settings: \\n\\n"
  get_values
  printf "\\n\\n${bold}you can choose between:${normal} \\n\\n"
  set_values
  return 0
else
  printf "admissible values for ${value} are: \\n ->"
  v4l2-ctl -d /dev/video0 --list-ctrls | grep "${value} " | awk -F : '{print $2}'
  printf "insert the chosen value\\n:> "
  read -r myvalue
  v4l2-ctl --set-ctrl=${value}=${myvalue} 2> /dev/null
  v4l2-ctl --get-ctrl=${value}

  quit_no=("${#controls_array_plus[*]}")
  list=$(( quit_no - 1 ))
  printf "\\nplease set another value or insert ${quit_no}"
  printf " to exit or ${list} to relist"

fi
done
 }


function checkinstalled { # Checks if program installed
which v4l2-ctl > /dev/null
if [[ $? != 0 ]] ; then
 printf "v4l2-ctl is not installed\n\n"
 if [ -z $deb_ver ] ; then
   i_ko
   printf "\nThis ain't no Debian-based  -- You should install it by hand \n\n" ; exit 1
 else
 printf "\ndo you want to install it? (requires sudo powers!)\n\n"
 sudo apt install -y v4l-utils v4l2loopback-utils
fi
fi
}

clear

checkinstalled

printf "Values are: \n"

get_values

printf "\\nset the value you want to set: \\n"

set_values

if [ $? = 6 ] ; then
printf "\\n\\n${bold}you can choose between:${normal} \\n\\n"
set_values
fi

get_values

printf "\\n${green}ciao!${normal}\n\n"
