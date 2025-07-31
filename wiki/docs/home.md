# Home automation

I will explore how to set up home automations, both in hardware and software. I mainly use ESPHome and Home Assistant.

## Custom Dimmer

The dimmer I created doesn't not connect directly to the house's main power; instead, it connects to Home Assistant via WiFi and manages the lights with a rotary encoder. The hardware I use is: 
- A [Waveshare ESP32 C6 Zero](https://www.waveshare.com/wiki/ESP32-C6-Zero)
- A [KY040 rotary encoder](https://www.amazon.se/roterande-kodmodul-graders-kodbrytare-potentiometer/dp/B0D5D23Y6V?crid=3883SLFOVV7DV&dib=eyJ2IjoiMSJ9.e8BC75T-RHyemKR-0FvQNx96RfkAFaM3EUYFrur0J5F-BLCfQ4VAzfZ5SWXxdTYpvW38W48kyvxlsYhwM46Aob4b1852FJnuFvEjNXvy596FNwnxehb-VUypCbH04GSs43Y7Ryia9J8R8RaoHmcWvb7lcpiFWmlLVJXx-pAyy4WfP1VQzOU2wvvWRhP51OzySUsMKznetHONu5wKrUoqWTv-kU_oEIW7SweIfp3EAxPM-C2uDTWyKKdmPe0UvqxkvQuoUAEj17uEt-TcRCG03lgYF4CWO1tC6mZVXuAhnEk.EbpMKo65Xqv48n8IdtuHqSq_8h0miyFuOdkjfLD4DFM&dib_tag=se&keywords=ky040&qid=1753954885&sprefix=ky040%2Caps%2C93&sr=8-3)






## Monitor Network Traffic

There might be several tools available for traffic monitoring, but the most common and applicable to most routers is [SNMP](/docs/openwrt#snmp). 
I use an OpenWRT router, but most routers, especially ones with custom firmware, support SNMP. Install and configure SNMP on your router.
Then on edit your ```configuration.yaml```. This file is accessible by different means, depending on your Home Assistant deployment:
- For Docker, you will need to mount it to the container, and the edit from there.
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


