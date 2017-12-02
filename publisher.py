#!/usr/bin/env python3

import paho.mqtt.client as mqtt
from w1thermsensor import W1ThermSensor
from  time import sleep
import logging

logging.basicConfig(filename='/var/log/messages',level=logging.INFO)

sensor = W1ThermSensor()

# This is the Publisher
client = mqtt.Client()
client.connect("192.168.10.8",1883,60)
logging.info('Publisher started')

while True:
    client.publish("/livingroom/AC/temp", sensor.get_temperature(W1ThermSensor.DEGREES_F));
    sleep(3)
    
