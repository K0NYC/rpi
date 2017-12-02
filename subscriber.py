#!/usr/bin/env python3

import paho.mqtt.client as mqtt
import RPi.GPIO as GPIO
import logging

# Define GPIO mode
GPIO.setmode(GPIO.BOARD)

# Define pins
relay = 26 #GPIO 7
GPIO.setwarnings (False)
GPIO.setup(relay, GPIO.OUT)

logging.basicConfig(filename='/var/log/messages',level=logging.INFO)

# This is the Subscriber

def on_connect(client, userdata, flags, rc):
        logging.info("Connected to broker with result code "+str(rc))
        client.subscribe("/livingroom/AC/power")

def on_message(client, userdata, msg):
        if msg.payload.decode() == "on":
                GPIO.output(relay, True)
        elif msg.payload.decode() == "off":
                GPIO.output(relay, False)


client = mqtt.Client()
client.connect("192.168.10.8",1883,60)

client.on_connect = on_connect
client.on_message = on_message

client.loop_forever()
