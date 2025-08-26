# Home Automation

I will explore how to set up home automations, both in hardware and software. I mainly use ESPHome and Home Assistant.

## Backups and Restore
I had to migrate my home server a couple of times, but luckily, it's super easy with Home Assistant.
Simply create a backup from the UI, deploy the new server, and restore the backup.

## Monitor Router Network Traffic

There might be several tools available for traffic monitoring, but the most common and applicable to most routers is [SNMP](/docs/openwrt#snmp). 
I use an OpenWRT router, but most routers, especially ones with custom firmware, support SNMP. Install and configure SNMP on your router.
Then on edit your ```configuration.yaml```. This file is accessible by different means, depending on your Home Assistant deployment:
- For Docker, you will need to mount it to the container and the edit from there.
- For Home Assistant OS, you can edit it directly from the UI, just install the "Terminal & SSH" add-on.

In my setup, I monitor the current traffic on both the WAN and LAN interfaces (Kbps), the volume of the current traffic(GB/day), and the volume of the total traffic(GB all time).
To achieve this, we need to manipulate the SNMP data, since the data from SNMP is the raw total traffic for each interface in bytes. 

For current traffic (Kbps), we can measure the difference between the current raw bytes, the raw bytes from 1 seconds ago, and the raw bytes from 2 seconds ago. 
This is a floating average, or the Bytes per Second, which we multiply by 8 to convert bytes to bits, and then 10^3 to get the Kbps.

For the daily traffic, we just poll the SNMP server once a day and then multiply the raw bytes by 2^30 to get the GB.

For total traffic, we just multiply by 2^30 to get the GB.

We start by creating a new sensor in Home Assistant, and reading the raw SNMP data:

```yaml title="configuration.yaml"
... # Your existing configuration
sensor:
  - platform: snmp
    host: 192.168.1.1 #Your router IP
    community: public #Your router SNMP community
    version: 2c
    accept_errors: true
    name: "Incoming WAN"
    baseoid: 1.3.6.1.2.1.2.2.1.10 # find this number using snmpwalk
    unit_of_measurement: "bytes"
  - platform: snmp
    host: 192.168.1.1 #Your router IP
    community: public #Your router SNMP community
    version: 2c
    accept_errors: true
    name: "Outgoing WAN"
    baseoid: 1.3.6.1.2.1.2.2.1.11 # find this number using snmpwalk
    unit_of_measurement: "bytes"
```

```Basesoid``` is the OID of the interface you want to monitor. OIDs are codes for specific data in the SNMP server. 
They are rather cryptic, but you can find them using ```snmpwalk```. Check out the [SNMP](/docs/openwrt#snmp) page for more information.
:::important
I found out that the OID from the ```snmpwalk``` has a different format than the one in the ```configuration.yaml```. OID from ```snmpwalk``` is ```iso.3.6.1.2.1.31.1.1.1.19.2```, but in the configuration.yaml it should be ```1.3.6.1.2.1.31.1.1.1.19.2```;
we replace ```iso.``` with ```1.```
:::

Do this for all the interfaces you want to monitor.

Then we create a ```derivative``` sensor to calculate the current traffic in Bytes per Second:
:::info 
This can be set up in the frontend as well! Simply go to Settings > Devices & Services > Helpers > Create helper > Derivative Sensor.
:::
```yaml title="configuration.yaml"
... # Your existing configuration
sensor:
  - platform: derivative
    source: sensor.incoming_wan_traffic
    name: "Incoming WAN Traffic bps"
    unit_time: s
    round: 2
  - platform: derivative
    source: sensor.outgoing_wan_traffic
    name: "Outgoing WAN Traffic bps"
    unit_time: s
    round: 2
```

Lastly, we create ```template``` sensors to calculate the current traffic in Kbps and the daily traffic in GB:
:::info
Template sensors can also be set up in the frontend.
:::
```yaml title="configuration.yaml"
template:
  - sensor:
    - name: "Incoming WAN GB"
      unique_id: wan_rx_gb
      unit_of_measurement: GB
      state: "{{ ((states('sensor.wan_rx') | int) / 2**30) | round(2) }}"
      icon: mdi:cloud-download
      state_class: total_increasing
    - name: "Outgoing WAN GB"
      unique_id: wan_tx_gb
      unit_of_measurement: GB
      state: "{{ ((states('sensor.wan_tx') | int) / 2**30) | round(2) }}"
      icon: mdi:cloud-upload
      state_class: total_increasing


    - name: "Incoming WAN Traffic"
      unique_id: wan_rx_traffic
      unit_of_measurement: Kbps
      state: "{{ ((state('sensor.wan_rx_bps') | int) * 8 / 10**3) | round (1) }}"
      icon: mdi:cloud-download
      state_class: measurement
    - name: "Outgoing WAN Traffic"
      unique_id: wan_tx_traffic
      unit_of_measurement: Kbps
      state: "{{ ((state('sensor.wan_tx_bps') | int) * 8 / 10**3) | round (1) }}"
      icon: mdi:cloud-upload
      state_class: measurement
```

## Monitoring Servers
I used Glances to monitor all the servers. Easiest way to deploy is with Docker. Deploy this docker-compose file on every server you want to monitor:
```bash
ssh <YOUR_SERVER>
touch docker-compose.yml # Paste the following yaml with your favorite editor
```
```yaml title="docker-compose.yml"
services:
  glances:
    container_name: glances
    image: nicolargo/glances
    pid: host
    restart: always
    ports:
      - 61208:61208
    environment:
      - "GLANCES_OPT=-w"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /etc/os-release:/etc/os-release:ro
```
```bash
docker-compose up -d
```
Make sure it's working by going to YOUR_SERVER_IP:61208.

Home assistant has a native integration for Glances, so you can just enable it in the UI through Settings > Devices & Services > Integrations.

## Projects
Custom hardware and software projects to implement for tracking, monitoring, and controlling home automation.
You will need to install ESPHome Builder either through add-ons on Home Assistant or a separate docker container.

### Custom Dimmer

The dimmer I created does not connect directly to the house's main power; instead, it connects to Home Assistant via WiFi and manages the lights with a rotary encoder (effectively a digital dimmer).
This way is a bit safer—no need to fidel with main power—and it's easier to retrofit, but requires you to use dimmable smart lights that Home Assistant can control.

The hardware I use is:
- [Waveshare ESP32 C6 Zero](https://www.waveshare.com/wiki/ESP32-C6-Zero)
- [KY040 rotary encoder](https://www.amazon.se/roterande-kodmodul-graders-kodbrytare-potentiometer/dp/B0D5D23Y6V?crid=3883SLFOVV7DV&dib=eyJ2IjoiMSJ9.e8BC75T-RHyemKR-0FvQNx96RfkAFaM3EUYFrur0J5F-BLCfQ4VAzfZ5SWXxdTYpvW38W48kyvxlsYhwM46Aob4b1852FJnuFvEjNXvy596FNwnxehb-VUypCbH04GSs43Y7Ryia9J8R8RaoHmcWvb7lcpiFWmlLVJXx-pAyy4WfP1VQzOU2wvvWRhP51OzySUsMKznetHONu5wKrUoqWTv-kU_oEIW7SweIfp3EAxPM-C2uDTWyKKdmPe0UvqxkvQuoUAEj17uEt-TcRCG03lgYF4CWO1tC6mZVXuAhnEk.EbpMKo65Xqv48n8IdtuHqSq_8h0miyFuOdkjfLD4DFM&dib_tag=se&keywords=ky040&qid=1753954885&sprefix=ky040%2Caps%2C93&sr=8-3)


ESPHome configuration: 

```yaml
esphome:
  name: living-room-dimmer
  friendly_name: living room dimmer

#Make sure to use the correct specifications of your controller
esp32:                                      
  board: esp32-c6-devkitc-1
  variant: esp32c6
  flash_size: 4MB
  framework:
    platform_version: 6.6.0
    type: esp-idf
    version: 5.2.1
    sdkconfig_options:
      CONFIG_ESPTOOLPY_FLASHSIZE_4MB: y


# Enable logging
logger:

# Enable Home Assistant API
api:
  encryption:
    key: "encrypted_key"

ota:
  - platform: esphome
    password: "password"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password
  
sensor:
  - platform: rotary_encoder
    name: Dimmer
    pin_a: 3
    pin_b: 4
    min_value: 0
    max_value: 9
    resolution: 1

binary_sensor:
  - platform: gpio
    pin:
      number: 5
      mode: INPUT_PULLUP
      inverted: True
    name: "Dimmer Switch"
    on_press: 
      then:
        - logger.log: "dimmer pressed"
```

- ```esp32```: The microcontroller used.
- ```logger```: Enable logging.
- ```api```: Enable Home Assistant API.
- ```ota```: Enable Over-the-Air updates.
- ```wifi```: WiFi settings.
- ```sensor```: The rotary encoder used to control the dimmer. 
- ```binary_sensor```: The KY040 has a switch as well that I use as a light switch. It can also be used to reset the dimmer steps. 

:::tip
Use your router's 2.4 GHz channel for the controller so it has a longer and more stable connection.
:::

If it's the first time flashing the controller, you will need to use [ESPHome Web](https://web.esphome.io/), which is basically a JavaScript that flashes your controller.
ESPHome Web only runs on Chromium browsers. Download the config file from ESPHome Builder (on your home assistant installation) and flash it using ESPHome Web.

Once installed, check the logs to make sure the controller is working. You can now use OTA to update it from now on, no need for ESPHome Web.

Once everything is working, we need to create a new automation to control the dimmer. I find it easier to just write the automation in YAML: 
```yaml 
alias: Living Room Dimmer
description: Adjust the brightness of the living room
triggers:
  - entity_id: sensor.esp_dimmer_dimmer
    trigger: state
conditions: []
actions:
  - data:
      entity_id: light.master

#The formula is 255 (max brightness) / 10 (total steps). Adjust the steps as needed.
      brightness: "{{ (trigger.to_state.state | int) * 25.5 | round | int }}" 
    action: light.turn_on
mode: single
```

We can also use exponential scaling to make the dimmer 'feel' more 'natural'.
```yaml
brightness: {{ (trigger.to_state.state | int / 9) ** 2 * 255) | round | int }}
```

This effectively creates the following adjustment curve:
`|-|--|----|------|--------|----------|-----------|`

:::tip
I recommend also creating a separate automation to turn off the lights if the dimmer clocks 0 in case the dimmer and the lights go out of sync with each other. 
:::

I also add an automation to controller the switch and use it as a light toggle: 
```yaml
alias: "Dimmer Switch"
description: "Click the dimmer switch to toggle the light"
triggers:
  - trigger: state
    entity_id:
      - binary_sensor.esp_remote_dimmer_dimmer_switch
    from: "off"
    to: "on"
conditions: []
actions:
  - action: light.toggle
    metadata: {}
    data: {}
    target:
      entity_id: light.spotlights
mode: single
```

### Reed Switch Sensor + Lights
I made a nice cabinet for storage, and I added a LED strip. The cabinet has a glass door that I want to open the LED strip when the door is opened. 

The hardware:
- [Seeed Studio XIAO ESP32C3](https://www.aliexpress.com/item/1005005382287176.html?spm=a2g0o.productlist.main.1.3e9916caGY5i7i&algo_pvid=70318051-252f-4d24-8e01-1dea6d435054&algo_exp_id=70318051-252f-4d24-8e01-1dea6d435054-0&pdp_ext_f=%7B%22order%22%3A%22481%22%2C%22eval%22%3A%221%22%7D&pdp_npi=6%40dis%21SEK%2197.24%2160.25%21%21%219.91%216.14%21%402103273e17547283965631336e8eb8%2112000037754252110%21sea%21SE%210%21ABX%211%210%21n_tag%3A-29910%3Bm03_new_user%3A-29895&curPageLogUid=0uGdylqjxaTd&utparam-url=scene%3Asearch%7Cquery_from%3A)
- [Packaged Reed Switch](https://www.aliexpress.com/item/1005006368391270.html?spm=a2g0o.productlist.main.6.395a388fPfaPw7&algo_pvid=bf03a2ce-5cb3-4bde-9176-85df0b0921eb&algo_exp_id=bf03a2ce-5cb3-4bde-9176-85df0b0921eb-5&pdp_ext_f=%7B%22order%22%3A%22591%22%2C%22eval%22%3A%221%22%7D&pdp_npi=6%40dis%21SEK%2120.12%219.71%21%21%212.05%210.99%21%402103247917547284144761376ebb88%2112000036920431423%21sea%21SE%210%21ABX%211%210%21m03_new_user%3A-29895%3Bn_tag%3A-29910%3BpisId%3A5000000174222028&curPageLogUid=TuaWPkWWBGmc&utparam-url=scene%3Asearch%7Cquery_from%3A)
- Any light that Home Assistant can control

ESPHome configuration:
```yaml
esphome:
  name: magnet-switch
  friendly_name: Magnet Switch

esp32:
  board: esp32-c3-devkitm-1
  variant: ESP32C3
  framework:
    type: esp-idf

binary_sensor:
  - platform: gpio
    name: "Door"
    pin:
      number: GPIO10
      mode: INPUT_PULLUP
      inverted: False
    device_class: door

# Enable logging
logger:

# Enable Home Assistant API
api:
  encryption:
    key: "key"

ota:
  - platform: esphome
    password: "password"

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

  # Enable fallback hotspot (captive portal) in case wifi connection fails
  ap:
    ssid: "Magnet-Switch Fallback Hotspot"
    password: "password"

captive_portal:

```

Then create two new automations to control the lights:
```yaml
alias: door sensor
description: ""
triggers:
  - trigger: state
    entity_id:
      - binary_sensor.magnet_switch
    from: "off"
    to: "on"
conditions: []
actions:
  - action: light.turn_on
    metadata: {}
    data: {}
    target:
      entity_id: light.doored_light
mode: single
```

```yaml
alias: door sensor off
description: ""
triggers:
  - trigger: state
    entity_id:
      - binary_sensor.magnet_switch
    from: "on"
    to: "off"
conditions: []
actions:
  - action: light.turn_off
    metadata: {}
    data: {}
    target:
      entity_id: light.doored_light
mode: single
```

:::info
You can probably also control the lights with a single automation and using toggles instead. The issue is that the sensor is not directly connected to the light so they might get out of sync and flip the functionality.
:::

### Weather Station (WIP)

Electronics Parts:
- UV Sensor
- DHT22 Sensor (temp and humidity)
- Wind Speed sensor 
- Wind direction sensor
- Rain Gauge (automatically draining)
- Air Quality Sensor
- Soil Moisture Sensor
- LoRa OR Long Range ZWave

Covers and mechanical parts:
- Gill Shield (for temp sensor)
- Wind Vane (Wind direction)
- Anemometer (Wind speed)
- 

Tips:
- Make it maximum 3m long. 

It is important to consider lightning strikes. The weather station will probably be on an open field. Since it's metal construction, it will probably attract lightning.
Make sure it's **under 3 meters**. If it's longer, you will probably need to install a lightning rod with a professional. 