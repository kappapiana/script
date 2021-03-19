  #!/usr/bin/env bash

  deb_ver=$(cat /etc/debian_version)
  # red=$(tput setaf 1)
  green=$(tput setaf 76)
  normal=$(tput sgr0)
  bold=$(tput bold)

  video_id="/dev/video0" # default to first device

  if [[ -n $1 ]]; then
    video_id="/dev/video$1"
  fi

  declare -a controls_array=()
  declare -a controls_array_plus=()
  mapfile -t controls_array < <(v4l2-ctl -d "$video_id" --list-ctrls | awk '{print $1}')

  # stuff for debugging
  # i_ok() { printf "%s✔\n" "${green}" "${normal}"; }
  # i_ko() { printf "%s✖%s\n...exiting, check logs" "${green}" "${normal}"; }
  #
  #
  # function check_i {
  # #   if [ $? -eq 0 ]; then
  #     i_ok
  #   else
  #     i_ko; read -r
  #     exit
  #   fi
  # }

  function list_channels {

  printf "%s \n" "${controls_array[@]}"

  }

  function get_values {
    for i in "${controls_array[@]}" ; do
    v4l2-ctl -d "$video_id" --get-ctrl="${i}"
  done
  }

  function set_values {

  controls_array_plus=("${controls_array[@]}" "help" "list" "quit")
  quit_no=${#controls_array_plus[*]}
  list_no=$(( quit_no - 1 ))
  help_no=$(( quit_no - 2 ))

  PS3="Choose 1 to ${#controls_array[*]} to modify actual values;"$'\n'"${help_no} to help, ${list_no} to list, ${quit_no} to exit;"$'\n\n'"${green}Make your choice:${normal} "


  select value in "${controls_array_plus[@]}"
  do

  if [[  ${value} == "quit" ]] ; then
    printf "\\nThanks!\\n\\n%s We have set the following values%s:\\n\\n" "${green}" "${normal}"
    return 1
  elif [[ ${value} == "list" ]] ; then
    clear
    printf "These are the current settings: \\n\\n"
    get_values
    printf "\\n\\n%s you can choose between:%s \\n\\n" "${green}" "${normal}"
    set_values
    return 0

  elif [[ ${value} == "help" ]]; then

    printf "\\n----------------------------------------------------------------\\n"
    v4l2-ctl -d "$video_id" --list-ctrls-menus
    printf "\\n----------------------------------------------------------------\\n\\n"

  elif [[ $REPLY -le ${#controls_array_plus[@]} ]]; then

    printf "\\nadmissible values for %s%s%s are: \\n ->" "${bold}" "${value}" "${normal}"
    v4l2-ctl -d "$video_id" --list-ctrls | grep "${value} " | awk -F : '{print $2}'
    printf "\\nInsert the chosen value\\n\\n :> "
    read -r myvalue
    v4l2-ctl -d "$video_id" --set-ctrl "${value}"="${myvalue}" 2> /dev/null
    v4l2-ctl -d "$video_id" --get-ctrl="${value}"

  else

    printf "\\nSorry, I do not understand.\\nNumeric entry %s between 1 and %s%s is expected\\n\\n" "${bold}" "${#controls_array_plus[@]}" "${normal}"

  fi
  done
   }


  function checkinstalled { # Checks if program installed

  if ! which v4l2-ctl > /dev/null ; then
   printf "v4l2-ctl is not installed\n\n"
   if [ -z "$deb_ver" ] ; then
      printf "\nThis ain't no Debian-based  -- You should install it by hand \n\n" ; exit 1
   else
   printf "\ndo you want to install it? (requires sudo powers!)\n\n"
   sudo apt install -y v4l-utils v4l2loopback-utils
  fi
  fi
  }

  clear

  checkinstalled

  printf "Values for %s are: \n" "$video_id"

  get_values

  printf "\\nset the value you want to set: \\n\\n"

  if [[ -z $1 ]]; then
    printf "%s\n" "*******************" "You have not provided any arugments, you have the following devices"
    v4l2-ctl --list-devices
    printf "%s\n" "*******************"
  fi

  set_values

  get_values

  printf "\\n%sciao!%s\n\n" "${green}" "${normal}"
