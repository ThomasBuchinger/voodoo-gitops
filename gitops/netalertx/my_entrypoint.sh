#!/bin/bash
mkdir -p /data/{config,db}
chmod -R +rw /data/{config,db}
cp /config/app.conf /data/config/
echo -e "\nMQTT_PASSWORD='${MQTT_PASSWORD}'" >> /data/config/app.conf

exec /entrypoint.sh