#!/bin/sh
# Ta bort UUID så att den genereras om vid nästa boot
sed -i 's/system\/uuid.*//' /etc/vmware/esx.conf

# Flytta local.sh som laddats upp av Packer
cp /tmp/local.sh /etc/rc.local.d/local.sh
chmod +x /etc/rc.local.d/local.sh

# Skapa konfigurationsbackup
/sbin/auto-backup.sh
