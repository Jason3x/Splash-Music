#!/bin/bash

#-----------------------------------
# Splash music by Jason
#-----------------------------------

CURR_TTY="/dev/tty1"

sudo chmod 666 $CURR_TTY
reset

# Hide cursor
printf "\e[?25l" > $CURR_TTY
dialog --clear

export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/

if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
else
    sudo setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz
fi

pgrep -f gptokeyb | sudo xargs kill -9
pgrep -f osk.py | sudo xargs kill -9
printf "\033c" > $CURR_TTY
printf "Starting Splash Music. Please wait..." > $CURR_TTY

height="15"
width="55"

BACKTITLE="Splash Music by Jason"

musicPath="/roms/tools/startup-music"
serviceName="splash-music.service"
selected_music=""

# Fonction pour créer le service systemd
create_music_service() {
  if [ -n "$selected_music" ]; then
    sudo bash -c "cat > /etc/systemd/system/$serviceName <<EOF
[Unit]
Description=Splash Music Service
Before=emulationstation.service

[Service]
Type=simple  
User=ark 
ExecStart=/usr/bin/mpv --no-video \"$selected_music\"
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl daemon-reload
    sudo systemctl enable "$serviceName"
    sudo systemctl start "$serviceName"
    dialog --msgbox "Splash music has been successfully activated!" 6 50 > "$CURR_TTY"
  dialog --infobox "Restarting EmulationStation...." 3 40 > $CURR_TTY
  sleep 2  # Attendre 2 secondes pour que le message soit visible

  # Redémarrer EmulationStation proprement
  sudo systemctl restart emulationstation &  # Lancer en arrière-plan pour éviter un blocage
  exit 0
  else
    dialog --msgbox "No music selected. Please select a music first." 6 50 > "$CURR_TTY"
  fi
}

# Fonction pour désactiver la musique au démarrage
disable_music_service() {
  dialog --infobox "Deactivating splash music..." 3 40 > $CURR_TTY
  if [ -f "/etc/systemd/system/$serviceName" ]; then
    sudo systemctl stop "$serviceName" || true
    sudo systemctl disable "$serviceName" > /dev/null 2>&1 || true
    sudo rm "/etc/systemd/system/$serviceName"
    sudo systemctl daemon-reload
    dialog --msgbox "Splash music has been successfully disabled!" 6 50 > "$CURR_TTY"
  else
    dialog --msgbox "The Splash music service is not enabled." 6 50 > "$CURR_TTY"
  dialog --infobox "Restarting EmulationStation...." 3 40 > $CURR_TTY
  sleep 2  # Attendre 2 secondes pour que le message soit visible

  # Redémarrer EmulationStation proprement
  sudo systemctl restart emulationstation &  # Lancer en arrière-plan pour éviter un blocage

  
  fi
  exit 0
}

  ExitMenu() {
    printf "\033c" > "$CURR_TTY"
    pgrep -f gptokeyb | sudo xargs kill -9
    exit 0
}

# Fonction pour sélectionner une musique et l'activer immédiatement
select_and_activate_music() {
  if [ ! -d "$musicPath" ] || [ -z "$(find "$musicPath" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \) )" ]; then
    dialog --msgbox "No music found! Please add your music files to '$musicPath'." 10 60 > "$CURR_TTY"
    return
  fi

  local music_files=($(find "$musicPath" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \)))
  local choices=()

  for file in "${music_files[@]}"; do
    choices+=("$(basename "$file")" "")
  done

  selected_file=$(dialog --clear \
    --backtitle "Splash Music by Jason" \
    --title "Available Music" \
    --menu "Select a music file to play at splash" 15 55 10 \
    "${choices[@]}" 2>&1 > "$CURR_TTY")

  if [ -n "$selected_file" ]; then
    selected_music="$musicPath/$selected_file"
    echo "$selected_music" | sudo tee /etc/startup-music-selected > /dev/null # Sauvegarder la musique sélectionnée
    
    dialog --infobox "Selected music: $selected_file" 4 50 > "$CURR_TTY"
  sleep 2
  
    dialog --infobox "Activating splash music..." 3 40 > $CURR_TTY
    
    # Activer immédiatement la musique sélectionnée
    create_music_service 
  fi
}

MainMenu() {
  while true; do
    mainselection=(dialog \
        --backtitle "$BACKTITLE" \
        --title "Splash Music Menu" \
        --clear \
        --cancel-label "Exit" \
        --menu "Select an option:" $height $width 15)
    mainoptions=(
        1 "Select and activate splash music"
        2 "Disable splash music"
        3 "Exit"
    )
    mainchoices=$("${mainselection[@]}" "${mainoptions[@]}" 2>&1 > $CURR_TTY)
    
    if [[ $? != 0 ]]; then
      exit 1
    fi

    for mchoice in $mainchoices; do
      case $mchoice in
        1) select_and_activate_music ;;
        2) disable_music_service ;;
        3) ExitMenu ;;
      esac
    done
  done
}

# Contrôle du joystick (si applicable)
sudo chmod 666 /dev/uinput
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
pgrep -f gptokeyb > /dev/null && pgrep -f gptokeyb | sudo xargs kill -9
/opt/inttools/gptokeyb -1 "Splash-Music.sh" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &
printf "\033c" > $CURR_TTY

dialog --clear

trap exit EXIT

# Lancer le menu principal
MainMenu
