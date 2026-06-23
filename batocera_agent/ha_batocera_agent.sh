#!/bin/bash

###############################################################################

# HA-Batocera Agent
# Version: 1.0.0
# JBSLabs

###############################################################################

###############################################################################
# State Variables
###############################################################################

BASE_DIR="/userdata/system/homeassistant"
CONFIG_FILE="$BASE_DIR/config.conf"
LOG_FILE="$BASE_DIR/logs/homeassistant.log"

STATE_DIR="/tmp/playsession"

SERVICE_FLAG="$STATE_DIR/running"
GAME_FILE="$STATE_DIR/current_game"
LAST_GAME_FILE="$STATE_DIR/last_played_game"
EMULATOR_FILE="$STATE_DIR/emulator"
CURRENT_SESSION_START_FILE="$STATE_DIR/current_session_start"
LAST_SESSION_DURATION_FILE="$STATE_DIR/last_session_duration"

mkdir -p "$BASE_DIR/logs" "$STATE_DIR"

source "$CONFIG_FILE"

###############################################################################
# Logging + MQTT helpers
###############################################################################

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

mqtt_pub() {
  local topic="$1"
  local message="$2"
  local retain="${3:-true}"

  if [ "$retain" = "true" ]; then
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" -t "$topic" -m "$message" -r
  else
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" -t "$topic" -m "$message"
  fi
}

device_json() {
  echo "\"device\":{\"identifiers\":[\"$DEVICE_ID\"],\"name\":\"$DEVICE_NAME\",\"manufacturer\":\"Batocera\",\"model\":\"NucBox K6\",\"sw_version\":\"Batocera 43\"}"
}

###############################################################################
# MQTT Discovery
###############################################################################

publish_discovery() {
  local dev
  dev=$(device_json)

  # Status
  mqtt_pub "$DISCOVERY_PREFIX/binary_sensor/$DEVICE_ID/online/config" "{\"name\":\"Online\",\"unique_id\":\"${DEVICE_ID}_online\",\"state_topic\":\"$BASE_TOPIC/status\",\"payload_on\":\"online\",\"payload_off\":\"offline\",\"device_class\":\"connectivity\",$dev}"

  # Controls
  mqtt_pub "$DISCOVERY_PREFIX/button/$DEVICE_ID/wake/config" "{\"name\":\"Wake\",\"unique_id\":\"${DEVICE_ID}_wake\",\"command_topic\":\"$BASE_TOPIC/command/wake\",\"icon\":\"mdi:power\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/button/$DEVICE_ID/reboot/config" "{\"name\":\"Reboot\",\"unique_id\":\"${DEVICE_ID}_reboot\",\"command_topic\":\"$BASE_TOPIC/command/reboot\",\"icon\":\"mdi:restart\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/button/$DEVICE_ID/shutdown/config" "{\"name\":\"Shutdown\",\"unique_id\":\"${DEVICE_ID}_shutdown\",\"command_topic\":\"$BASE_TOPIC/command/shutdown\",\"icon\":\"mdi:power-off\",$dev}"

  # Controller + gaming
  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/controller_connected/config" "{\"name\":\"Controller Connected\",\"unique_id\":\"${DEVICE_ID}_controller_connected\",\"state_topic\":\"$BASE_TOPIC/controller_connected\",\"icon\":\"mdi:controller-classic\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/controller_count/config" "{\"name\":\"Controller Count\",\"unique_id\":\"${DEVICE_ID}_controller_count\",\"state_topic\":\"$BASE_TOPIC/controller_count\",\"icon\":\"mdi:controller-classic\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/emulator/config" "{\"name\":\"Emulator\",\"unique_id\":\"${DEVICE_ID}_emulator\",\"state_topic\":\"$BASE_TOPIC/emulator\",\"icon\":\"mdi:nintendo-game-boy\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/current_game/config" "{\"name\":\"Current Game\",\"unique_id\":\"${DEVICE_ID}_current_game\",\"state_topic\":\"$BASE_TOPIC/current_game\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/last_played_game/config" "{\"name\":\"Last Played Game\",\"unique_id\":\"${DEVICE_ID}_last_played_game\",\"state_topic\":\"$BASE_TOPIC/last_played_game\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/current_session/config" "{\"name\":\"Current Session\",\"unique_id\":\"${DEVICE_ID}_current_session\",\"state_topic\":\"$BASE_TOPIC/current_session\",\"icon\":\"mdi:timer-sand\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/last_session/config" "{\"name\":\"Last Session\",\"unique_id\":\"${DEVICE_ID}_last_session\",\"state_topic\":\"$BASE_TOPIC/last_session\",\"icon\":\"mdi:timer-sand-complete\",$dev}"

  # System usage
  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/cpu_temperature/config" "{\"name\":\"CPU Temperature\",\"unique_id\":\"${DEVICE_ID}_cpu_temperature\",\"state_topic\":\"$BASE_TOPIC/cpu_temperature\",\"icon\":\"mdi:thermometer\",\"unit_of_measurement\":\"°C\",\"device_class\":\"temperature\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/cpu_usage/config" "{\"name\":\"CPU Usage\",\"unique_id\":\"${DEVICE_ID}_cpu_usage\",\"state_topic\":\"$BASE_TOPIC/cpu_usage\",\"icon\":\"mdi:chip\",\"unit_of_measurement\":\"%\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/ram_usage/config" "{\"name\":\"RAM Usage\",\"unique_id\":\"${DEVICE_ID}_ram_usage\",\"state_topic\":\"$BASE_TOPIC/ram_usage\",\"icon\":\"mdi:memory\",\"unit_of_measurement\":\"%\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/ip_address/config" "{\"name\":\"IP Address\",\"unique_id\":\"${DEVICE_ID}_ip_address\",\"state_topic\":\"$BASE_TOPIC/ip_address\",\"icon\":\"mdi:ip\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/uptime/config" "{\"name\":\"Uptime\",\"unique_id\":\"${DEVICE_ID}_uptime\",\"state_topic\":\"$BASE_TOPIC/uptime\",\"icon\":\"mdi:chart-timeline-variant\",$dev}"

  # Storage + ROMs
  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/storage_used/config" "{\"name\":\"Storage Used\",\"unique_id\":\"${DEVICE_ID}_storage_used\",\"state_topic\":\"$BASE_TOPIC/storage/used\",\"icon\":\"mdi:harddisk\",\"unit_of_measurement\":\"GB\",\"device_class\":\"data_size\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/storage_available/config" "{\"name\":\"Storage Available\",\"unique_id\":\"${DEVICE_ID}_storage_available\",\"state_topic\":\"$BASE_TOPIC/storage/available\",\"icon\":\"mdi:harddisk\",\"unit_of_measurement\":\"GB\",\"device_class\":\"data_size\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/storage_total/config" "{\"name\":\"Storage Total\",\"unique_id\":\"${DEVICE_ID}_storage_total\",\"state_topic\":\"$BASE_TOPIC/storage/total\",\"icon\":\"mdi:harddisk\",\"unit_of_measurement\":\"GB\",\"device_class\":\"data_size\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/storage_percent/config" "{\"name\":\"Storage Percent\",\"unique_id\":\"${DEVICE_ID}_storage_percent\",\"state_topic\":\"$BASE_TOPIC/storage/percent\",\"icon\":\"mdi:percent-box\",\"unit_of_measurement\":\"%\",\"state_class\":\"measurement\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/rom_count/config" "{\"name\":\"ROM Count\",\"unique_id\":\"${DEVICE_ID}_rom_count\",\"state_topic\":\"$BASE_TOPIC/rom_count\",\"icon\":\"mdi:content-save\",\"state_class\":\"measurement\",$dev}"

  # Software
  mqtt_pub "$DISCOVERY_PREFIX/sensor/$DEVICE_ID/software_version/config" "{\"name\":\"Software Version\",\"unique_id\":\"${DEVICE_ID}_software_version\",\"state_topic\":\"$BASE_TOPIC/software_version\",\"icon\":\"mdi:package\",$dev}"

  mqtt_pub "$DISCOVERY_PREFIX/binary_sensor/$DEVICE_ID/update/config" "{\"name\":\"Update\",\"unique_id\":\"${DEVICE_ID}_update\",\"state_topic\":\"$BASE_TOPIC/update\",\"icon\":\"mdi:update\",\"payload_on\":\"ON\",\"payload_off\":\"OFF\",\"device_class\":\"update\",$dev}"

  log "MQTT discovery published"
}

###############################################################################
# Define Gaming Sensor Functions
###############################################################################

get_controller_count() {
  local count=0
  local js
  local base
  for js in /dev/input/js*; do
    [ -e "$js" ] || continue
    base=$(basename "$js")
    echo "$IGNORED_JOYSTICKS" | grep -qw "$base" && continue
    count=$((count + 1))
  done
  echo "$count"
}

get_controller_connected() {
  local names
  names=$(awk '
    /^N: Name=/ {
      name=$0
      sub(/^N: Name="/, "", name)
      sub(/"$/, "", name)
    }
    /^H: Handlers=/ {
      if ($0 ~ /js[0-9]/ &&
          name !~ /Mouse passthrough/ &&
          name !~ /batocera hotkeys/ &&
          name !~ /evmapy/) {
        print name
      }
    }
  ' /proc/bus/input/devices | paste -sd "," - | sed 's/,/, /g')
  if [ -z "$names" ]; then
    echo "Idle"
  else
    echo "$names"
  fi
}

get_current_game() {
  [ -f "$GAME_FILE" ] && cat "$GAME_FILE" || echo "Idle"
}

get_last_played_game() {
  [ -f "$LAST_GAME_FILE" ] && cat "$LAST_GAME_FILE" || echo "Idle"
}

get_emulator() {
  [ -f "$EMULATOR_FILE" ] && cat "$EMULATOR_FILE" || echo "Idle"
}

format_duration() {
  local elapsed="$1"
  printf "%02dh %02dm %02ds" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))
}

get_current_session() {
  if [ ! -f "$CURRENT_SESSION_START_FILE" ]; then
    echo "Idle"
    return
  fi
  local start
  local now
  local elapsed
  start=$(cat "$CURRENT_SESSION_START_FILE" 2>/dev/null)
  if ! echo "$start" | grep -Eq '^[0-9]+$'; then
    echo "Idle"
    return
  fi
  now=$(date +%s)
  elapsed=$((now - start))
  if [ "$elapsed" -lt 0 ]; then
    echo "Idle"
    return
  fi
  format_duration "$elapsed"
}

get_last_session() {
  [ -f "$LAST_SESSION_DURATION_FILE" ] && cat "$LAST_SESSION_DURATION_FILE" || echo "Idle"
}

###############################################################################
# Define Hardware Sensor Functions
###############################################################################

get_cpu_temp() {
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    awk '{printf "%.1f", (($1/1000) * 9/5) + 32}' /sys/class/thermal/thermal_zone0/temp
  else
    echo "unknown"
  fi
}

get_cpu_usage() {
  local first
  local second
  local cpu user nice system idle iowait irq softirq steal guest guest_nice
  local total1 idle1 total2 idle2 diff_total diff_idle usage

  first=$(grep '^cpu ' /proc/stat)
  sleep 1
  second=$(grep '^cpu ' /proc/stat)

  set -- $first
  cpu=$1; user=$2; nice=$3; system=$4; idle=$5; iowait=$6; irq=$7; softirq=$8; steal=$9; guest=${10}; guest_nice=${11}
  idle1=$((idle + iowait))
  total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

  set -- $second
  cpu=$1; user=$2; nice=$3; system=$4; idle=$5; iowait=$6; irq=$7; softirq=$8; steal=$9; guest=${10}; guest_nice=${11}
  idle2=$((idle + iowait))
  total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

  diff_total=$((total2 - total1))
  diff_idle=$((idle2 - idle1))

  if [ "$diff_total" -le 0 ]; then
    echo "unknown"
    return
  fi

  usage=$(awk -v total="$diff_total" -v idle="$diff_idle" 'BEGIN { printf "%.1f", (100 * (total - idle) / total) }')
  echo "$usage"
}

get_ram_usage() {
  awk '
    /MemTotal/ {total=$2}
    /MemAvailable/ {available=$2}
    END {
      if (total > 0) printf "%.1f", ((total - available) / total) * 100
      else print "unknown"
    }
  ' /proc/meminfo
}

get_ip() {
  ip -4 addr show eth1 | awk '/inet / {print $2}' | cut -d/ -f1
}

get_uptime() {
  awk '{printf "%dd %02dh %02dm", $1/86400, ($1%86400)/3600, ($1%3600)/60}' /proc/uptime
}

###############################################################################
# Define Storage Sensor Functions
###############################################################################

get_storage_used() {
  df -BG /userdata | awk 'NR==2 {gsub("G","",$3); print $3}'
}

get_storage_available() {
  df -BG /userdata | awk 'NR==2 {gsub("G","",$4); print $4}'
}

get_storage_total() {
  df -BG /userdata | awk 'NR==2 {gsub("G","",$2); print $2}'
}

get_storage_percent() {
  df /userdata | awk 'NR==2 {gsub("%","",$5); print $5}'
}

get_rom_count() {
  find /userdata/roms -type f 2>/dev/null | wc -l
}

###############################################################################
# Define Software Sensor Functions
###############################################################################

get_software_version() {
  local version
  version=$(cat /usr/share/batocera/batocera.version 2>/dev/null | awk '{print $1}')

  if [ -n "$version" ]; then
    echo "Batocera $version"
  else
    echo "Batocera Unknown"
  fi
}

get_update() {
  local output
  output=$(batocera-check-updates 2>/dev/null)

  echo "$output" | grep -qi "update available\|update found\|new version"

  if [ "$?" -eq 0 ]; then
    echo "ON"
  else
    echo "OFF"
  fi
}

###############################################################################
# Publish all sensors
###############################################################################

publish_sensors() {
  local controllers
  controllers=$(get_controller_count)

  # Status
  mqtt_pub "$BASE_TOPIC/status" "online"

  # Gaming
  mqtt_pub "$BASE_TOPIC/controller_count" "$controllers"
  mqtt_pub "$BASE_TOPIC/controller_connected" "$(get_controller_connected)"
  mqtt_pub "$BASE_TOPIC/emulator" "$(get_emulator)"
  mqtt_pub "$BASE_TOPIC/current_game" "$(get_current_game)"
  mqtt_pub "$BASE_TOPIC/last_played_game" "$(get_last_played_game)"
  mqtt_pub "$BASE_TOPIC/current_session" "$(get_current_session)"
  mqtt_pub "$BASE_TOPIC/last_session" "$(get_last_session)"

  # Hardware
  mqtt_pub "$BASE_TOPIC/cpu_temperature" "$(get_cpu_temp)"
  mqtt_pub "$BASE_TOPIC/cpu_usage" "$(get_cpu_usage)"
  mqtt_pub "$BASE_TOPIC/ram_usage" "$(get_ram_usage)"
  mqtt_pub "$BASE_TOPIC/ip_address" "$(get_ip)"
  mqtt_pub "$BASE_TOPIC/uptime" "$(get_uptime)"

  # Storage
  mqtt_pub "$BASE_TOPIC/storage/used" "$(get_storage_used)"
  mqtt_pub "$BASE_TOPIC/storage/available" "$(get_storage_available)"
  mqtt_pub "$BASE_TOPIC/storage/total" "$(get_storage_total)"
  mqtt_pub "$BASE_TOPIC/storage/percent" "$(get_storage_percent)"
  mqtt_pub "$BASE_TOPIC/rom_count" "$(get_rom_count)"

  # Software
  mqtt_pub "$BASE_TOPIC/software_version" "$(get_software_version)"
  mqtt_pub "$BASE_TOPIC/update" "$(get_update)"
}

###############################################################################
# Batocera event scripts
###############################################################################

install_event_scripts() {
  local event

  for event in game-start game-end system-selected controls-changed; do
    mkdir -p "/userdata/system/configs/emulationstation/scripts/$event"

    cat > "/userdata/system/configs/emulationstation/scripts/$event/homeassistant.sh" <<EOF
#!/bin/bash
/userdata/system/homeassistant/homeassistant.sh event "$event" "\$@"
EOF

    chmod +x "/userdata/system/configs/emulationstation/scripts/$event/homeassistant.sh"
  done

  log "Event scripts installed"
}

handle_event() {
  local event="$1"
  local rom
  local system
  local game
  local current_game
  local start
  local now
  local elapsed

  shift

  case "$event" in
    game-start)
      rom="$1"
      system=$(echo "$rom" | awk -F'/roms/' '{print $2}' | cut -d'/' -f1)

      game=$(basename "$rom")
      game="${game%.*}"
      game=$(echo "$game" | sed 's/\\ / /g; s/\\//g')

      echo "$game" > "$GAME_FILE"
      echo "$system" > "$EMULATOR_FILE"
      date +%s > "$CURRENT_SESSION_START_FILE"
    
      log "Game started: $game / $system"
      publish_sensors
      ;;
    
    game-end)
      current_game=$(cat "$GAME_FILE" 2>/dev/null)
      if [ -n "$current_game" ] && [ "$current_game" != "Idle" ] && [ "$current_game" != "unknown" ]; then
        echo "$current_game" > "$LAST_GAME_FILE"
      fi

      # Save completed session duration
      if [ -f "$CURRENT_SESSION_START_FILE" ]; then
        start=$(cat "$CURRENT_SESSION_START_FILE" 2>/dev/null)
        now=$(date +%s)
        if echo "$start" | grep -Eq '^[0-9]+$'; then
          elapsed=$((now - start))
          if [ "$elapsed" -ge 0 ]; then
            format_duration "$elapsed" > "$LAST_SESSION_DURATION_FILE"
          fi
        fi
      fi
      echo "Idle" > "$GAME_FILE"
      rm -f "$CURRENT_SESSION_START_FILE"
      log "Game ended"
      publish_sensors
      ;;

    system-selected)
      if [ -n "$1" ] && [ "$1" != "unknown" ] && [ "$1" != "Unknown" ]; then
        echo "$1" > "$EMULATOR_FILE"
        log "System selected: $1"
      else
        log "System selected event ignored because value was unknown"
      fi

      publish_sensors
      ;;

    controls-changed)
      log "Controls changed"
      publish_sensors
      ;;
  esac
}

###############################################################################
# Commands + service lifecycle
###############################################################################

listen_commands() {
  mosquitto_sub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" -v -t "$BASE_TOPIC/command/#" | while read -r topic payload
  do
    log "Command received: $topic $payload"

    case "$topic" in
      "$BASE_TOPIC/command/reboot")
        mqtt_pub "$BASE_TOPIC/status" "offline"
        reboot
        ;;

      "$BASE_TOPIC/command/shutdown")
        mqtt_pub "$BASE_TOPIC/status" "offline"
        poweroff
        ;;

      "$BASE_TOPIC/command/wake")
        log "Wake command received while already online"
        ;;
    esac
  done
}

start_service() {
  echo "running" > "$SERVICE_FLAG"
  echo "Idle" > "$GAME_FILE"
  echo "Idle" > "$EMULATOR_FILE"
  install_event_scripts
  publish_discovery
  publish_sensors
  log "Batocera Home Assistant service started"
  listen_commands &
  COMMAND_PID=$!
  while [ -f "$SERVICE_FLAG" ]; do
    publish_sensors
    if [ -f "$CURRENT_SESSION_START_FILE" ]; then
      sleep 10
    else
      sleep 30
    fi
  done
  kill "$COMMAND_PID" 2>/dev/null
}

stop_service() {
  rm -f "$SERVICE_FLAG"
  mqtt_pub "$BASE_TOPIC/status" "offline"
  log "Batocera Home Assistant service stopped"
}

case "$1" in
  start)
    start_service
    ;;

  stop)
    stop_service
    ;;

  restart)
    stop_service
    sleep 2
    start_service
    ;;

  install)
    install_event_scripts
    publish_discovery
    publish_sensors
    ;;

  event)
    shift
    handle_event "$@"
    ;;

  *)
    echo "Usage: $0 start|stop|restart|install|event"
    ;;
esac

