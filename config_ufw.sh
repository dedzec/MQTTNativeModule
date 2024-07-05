#!/bin/bash

# Verifica se o UFW está habilitado
ufw_status=$(sudo ufw status | grep -i 'Status: active')
if [[ -z $ufw_status ]]; then
    echo "UFW não está habilitado. Habilitando..."
    sudo ufw enable
fi

# Verifica se a porta 8088 está permitida
port_status=$(sudo ufw status numbered | grep '8088')
if [[ -z $port_status ]]; then
    echo "Porta 8088 não está permitida. Permitindo..."
    sudo ufw allow 8088/tcp comment 'React-Native'
else
    echo "Porta 8088 já está permitida."
fi
