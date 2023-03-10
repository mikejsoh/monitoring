#!/usr/bin/env bash

apt update
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.31.0/prometheus-2.31.0.linux-amd64.tar.gz
tar -xvf prometheus-*.linux-amd64.tar.gz
rm prometheus-*.linux-amd64.tar.gz
cd prometheus-*.linux-amd64
mv prometheus promtool /usr/local/bin/
mv consoles/ console_libraries/ /etc/prometheus/
mv prometheus.yml /etc/prometheus/prometheus.yml
groupadd --system prometheus
useradd -s /sbin/nologin --system -g prometheus prometheus
chown -R prometheus:prometheus /etc/prometheus/ /var/lib/prometheus/
chmod -R 775 /etc/prometheus/ /var/lib/prometheus/

touch /etc/systemd/system/prometheus.service
cd /etc/systemd/system/
tee -a prometheus.service << END
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Restart=always
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
END

systemctl start prometheus
systemctl enable prometheus


wget https://github.com/prometheus/snmp_exporter/releases/download/v0.19.0/snmp_exporter-0.19.0.linux-amd64.tar.gz
tar xzf snmp_exporter-*.linux-amd64.tar.gz
rm snmp_exporter-*.linux-amd64.tar.gz
cd snmp_exporter-*.linux-amd64
ls -lh
cp ./snmp_exporter /usr/local/bin/snmp_exporter

mkdir -p /etc/snmp_exporter
chown -R prometheus:prometheus /etc/snmp_exporter/

cd
wget https://raw.githubusercontent.com/mikejsoh/monitoring/main/snmp.yml
cp ./snmp.yml /etc/snmp_exporter/snmp.yml

touch /etc/systemd/system/snmp-exporter.service
cd /etc/systemd/system/
tee -a snmp-exporter.service << END
[Unit]
Description=Prometheus SNMP Exporter Service
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/snmp_exporter --config.file="/etc/snmp_exporter/snmp.yml"

[Install]
WantedBy=multi-user.target
END

systemctl start snmp-exporter
systemctl enable snmp-exporter

systemctl status prometheus
systemctl status snmp-exporter
