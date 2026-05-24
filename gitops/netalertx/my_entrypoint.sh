#!/bin/bash
# Configure Settings file
mkdir -p /data/{config,db}
chmod -R +rw /data/{config,db}
cp /config/app.conf /data/config/
echo -e "\nMQTT_PASSWORD='${MQTT_PASSWORD}'" >> /data/config/app.conf
echo -e "\API_TOKEN='${API_TOKEN}'" >> /data/config/app.conf

exec /entrypoint.sh