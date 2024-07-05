#!/bin/bash

# Saia do script se qualquer comando falhar
set -e

# Função para mostrar loading
function show_loading() {
    local delay=0.5
    local spin='-\|/'
    while kill -0 $1 2>/dev/null; do
        local temp=${spin#?}
        printf " [%c]  " "$spin"
        local spin=$temp${spin%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Função para encontrar e tocar no botão OK
function buttonOK() {
    adb pull $(adb shell uiautomator dump | grep -oP '[^ ]+.xml') /tmp/view.xml

    coords=$(perl -ne 'printf "%d %d\n", ($1+$3)/2, ($2+$4)/2 if /text="OK"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"/' /tmp/view.xml)

    adb shell input tap $coords
}

# Função para executar o script Python e capturar as coordenadas x e y
function execute_python_script() {
    local params=$1

    # Navegar até o diretório localize
    cd localize

    # Verificar se o ambiente virtual está configurado corretamente
    if [ ! -d "venv" ]; then
        echo "Ambiente virtual 'venv' não encontrado em localize/. Configure o ambiente virtual primeiro."
        
        # Configura venv
        chmod +x ./setup.sh
        source ./setup.sh
    fi

    # Executar o script Python com os parâmetros e capturar a saída
    echo "Executando o script Python..."
    output=$(./venv/bin/python3 main.py $params)

    # Extrair as coordenadas x e y da saída do script Python
    x=$(echo $output | grep -oP '(?<=x=)\d+')
    y=$(echo $output | grep -oP '(?<=y=)\d+')

    echo "Coordenadas recebidas: x=$x, y=$y"

    # Voltar para o diretório raiz do projeto
    cd ..
}

# Interface de rede Wi-Fi específica
interface="wlp0s20f3"

# Obtém o endereço IP da interface Wi-Fi
port=8088
ip=$(ip addr show dev "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Endereço IP do Wi-Fi ($interface): $ip"

# Navegar até o diretório android
cd android

# Limpar a pasta de build
echo "Limpando a pasta de build..."
./gradlew clean

# Compilar o APK em modo debug
echo "Compilando o APK em modo debug..."
./gradlew assembleDebug

# Encontrar o arquivo MainActivity.java ou MainActivity.kt
echo "Procurando por MainActivity.java ou MainActivity.kt..."
main_activity_file=$(find . -type f \( -name "MainActivity.java" -o -name "MainActivity.kt" \))

if [ -z "$main_activity_file" ]; then
    echo "Arquivo MainActivity.java ou MainActivity.kt não encontrado."
    exit 1
fi

# Encontrar o texto 'package' no arquivo MainActivity.java ou MainActivity.kt
echo "Localizando o texto 'package' no arquivo $main_activity_file..."
package_name=$(grep -m 1 '^package' "$main_activity_file" | awk '{print $2}' | tr -d ';')

# Voltar para o diretório raiz do projeto
cd ..

# Verificar se o adb está disponível
if ! command -v adb &> /dev/null
then
    echo "adb não encontrado, por favor instale o Android SDK e adicione o adb ao PATH."
    exit 1
fi

# Configurar a reversão de porta
echo "Configurando a reversão de porta..."
adb reverse tcp:$port tcp:$port

# Instalar o APK no dispositivo conectado
echo "Instalando o APK no dispositivo..."
adb install -r ./android/app/build/outputs/apk/debug/app-debug.apk

# Abrir o aplicativo instalado no dispositivo
echo "Abrindo o aplicativo instalado..."
adb shell am start -n "${package_name}/.MainActivity" &

# Obter o PID do processo do adb shell am start
PID=$!

# Mostrar loading até que o aplicativo seja iniciado
echo "Aguardando o aplicativo iniciar..."
show_loading $PID
sleep 2

# Simular pressionamento do botão de menu (keyevent 82)
echo "Simulando pressionamento do botão de menu..."
adb shell input keyevent 82

#--------------------------------
# Touch: Settings
#--------------------------------
# Capturar screenshot e salvar em localize/screenshot.png
echo "Capturando screenshot..."
adb exec-out screencap -p > localize/screenshot.png
sleep 2

# Executar o script Python com o parâmetro 'Settings' e capturar as coordenadas x e y
execute_python_script "--search_text Settings"

# Tocar na tela nas coordenadas especificadas
echo "Tocando na tela nas coordenadas: x=$x, y=$y"
adb shell input tap $x $y
sleep 2

#--------------------------------
# Touch: Debug server host
#--------------------------------
# Capturar screenshot e salvar em localize/screenshot.png
echo "Capturando screenshot..."
adb exec-out screencap -p > localize/screenshot.png
sleep 2

# Executar o script Python com o parâmetro 'host' e capturar as coordenadas x e y
execute_python_script "--search_text host"

# Tocar na tela nas coordenadas especificadas
echo "Tocando na tela nas coordenadas: x=$x, y=$y"
adb shell input tap $x $y
sleep 2

#--------------------------------
# Touch: Textfield
#--------------------------------
# Capturar screenshot e salvar em localize/screenshot.png
echo "Capturando screenshot..."
adb exec-out screencap -p > localize/screenshot.png
sleep 2

# Executar o script Python com o parâmetro do template e capturar as coordenadas x e y
# execute_python_script "--template_path ./images/textfield.png"

# Tocar na tela nas coordenadas especificadas
# echo "Tocando na tela nas coordenadas: x=$x, y=$y"
adb shell input text "$ip:$port"
sleep 2

echo "Confirmando alterações..."
buttonOK
sleep 1

echo "Retornando para a tela inicial..."
adb shell input keyevent KEYCODE_BACK
sleep 1

# Simular pressionamento do botão de menu (keyevent 82)
echo "Simulando pressionamento do botão de menu..."
adb shell input keyevent 82

#--------------------------------
# Touch: Reload
#--------------------------------
# Capturar screenshot e salvar em localize/screenshot.png
echo "Capturando screenshot..."
adb exec-out screencap -p > localize/screenshot.png
sleep 2

# Executar o script Python com o parâmetro 'Reload' e capturar as coordenadas x e y
execute_python_script "--search_text Reload"

# Tocar na tela nas coordenadas especificadas
echo "Tocando na tela nas coordenadas: x=$x, y=$y"
adb shell input tap $x $y
sleep 2

echo "Instalação, abertura, captura de tela, execução do script Python, localização e toque na tela completados com sucesso!"
