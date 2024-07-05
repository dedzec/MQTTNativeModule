#!/bin/bash

# Interface de rede Wi-Fi específica
interface="wlp0s20f3"

# Obtém o endereço IP da interface Wi-Fi
ip=$(ip addr show dev "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo "Endereço IP do Wi-Fi ($interface): $ip"
