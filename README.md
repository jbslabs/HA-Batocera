# HA Batocera

Bring Batocera into Home Assistant with real-time MQTT sensors, game tracking, controller monitoring, and system statistics.

HA Batocera is a lightweight Batocera agent that publishes gaming and system data to Home Assistant through MQTT, allowing you to build dashboards, automations, notifications, and statistics around your retro gaming setup.

## Project Status

### ⚠️ In active development. Features and installation methods may change before v1.0.0.

Current Release: v0.9.0

HA Batocera is currently in pre-release status while the native Home Assistant integration is under development.

The Batocera MQTT Agent is fully functional and suitable for testing and daily use.

## Features

### Gaming

* Current game tracking
* Last played game tracking
* Current emulator tracking
* Current play session tracking
* Previous play session tracking
* Real-time game start and game end detection

### Controllers

* Controller count monitoring
* Connected controller name tracking
* Controller battery monitoring
* Real-time controller connection updates

### System Monitoring

* Online/Offline status monitoring
* CPU temperature monitoring
* CPU usage monitoring
* Memory usage monitoring
* IP address reporting
* System uptime monitoring

### Storage Monitoring

* Storage used
* Storage available
* Total storage capacity
* Storage utilization percentage
* ROM library count

### Software Monitoring

* Batocera version reporting
* Update availability detection

### Home Assistant Integration

* MQTT Discovery support
* Automatic entity creation
* Automatic device registration
* Home Assistant device grouping
* Real-time state updates
* Lightweight Bash-based implementation
* Designed specifically for Batocera Linux

### Remote Control

* Reboot command support
* Shutdown command support
* MQTT-based device control
* Easy integration with Wake-on-LAN, SwitchBot Bot, and Fingerbot power-on solutions through Home Assistant automations

## Requirements

### Batocera

* Batocera Linux
* MQTT client tools (`mosquitto_pub`)
* Network connectivity

### Home Assistant

* Home Assistant
* MQTT Broker
* MQTT Integration

## Installation

1. Copy `ha_batocera_agent.sh` to your Batocera system.
2. Configure MQTT settings inside the script.
3. Make the script executable:

```bash
chmod +x ha_batocera_agent.sh
```

4. Start the agent manually or configure it to launch automatically at boot.

## Published Data

HA Batocera publishes a variety of MQTT topics including:

### Gaming

* Current Game
* Current Emulator
* Current Session Duration
* Last Played Game
* Previous Session Duration

### Controllers

* Controllers Connected
* Controller Battery
* Controller Count

### System

* CPU Temperature
* CPU Usage
* RAM Usage
* IP Address
* System Uptime
* Storage Used
* Storage Available
* Storage Total
* Storage Utilization
* ROM Count
* Software Version
* Update Availability

## Home Assistant

The published MQTT data can be used to create:

* Dashboard cards
* Statistics
* Automations
* Notifications
* Gaming activity tracking
* Usage reports

## Screenshots

Example Batocera device page in Home Assistant.

<p align="center">
  <img src="./screenshots/hadevice.png" width="220" /> 
</p>

Example Home Assistant dashboard showing HA Batocera sensors and gaming statistics.

Coming Soon

## Roadmap

### Current Status (v0.9.x)

* MQTT Discovery
* Automatic Home Assistant entity creation
* Automatic device registration
* Game tracking
* Session tracking
* Controller monitoring
* Controller battery monitoring
* System monitoring
* Storage monitoring
* Software version monitoring
* Update detection
* Power management commands

### Planned for v1.0.0

* Native Home Assistant Integration
* HACS Installation Support
* Config Flow
* One-click Installation
* Diagnostics Support
* Automatic Updates

### Future Enhancements

* Dashboard Templates
* Additional Batocera Sensors

## Special Thanks

Special thanks to StePhan McKillen (myle) and the Home Assistant community for helping inspire this project through an MQTT discussion post:

https://community.home-assistant.io/t/batocera-to-home-assistant-via-mqtt/906675

The original discussion demonstrated how MQTT could be used to bridge Batocera and Home Assistant and helped inspire the development of HA Batocera.

## Acknowledgements

- Batocera Linux Team
- Home Assistant Community
- MQTT Community
- Everyone testing and providing feedback for HA Batocera

## License

Released under the MIT License. See the LICENSE file for details.
