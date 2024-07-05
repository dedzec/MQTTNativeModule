#!/bin/bash

ENV_DIR=venv
REQUIREMENTS=requirements.txt

# Verifica se a pasta venv existe
if [ ! -d "$ENV_DIR" ]; then
    echo "A pasta $ENV_DIR não foi encontrada."
    echo "Criando um novo ambiente virtual..."
    python3 -m venv $ENV_DIR || {
        echo "Falha ao criar o ambiente virtual. Verifique se o Python está instalado corretamente."
        exit 1
    }
    echo "Ambiente virtual criado com sucesso."
fi

# Ativa o ambiente virtual
echo "Ativando ambiente virtual..."
source $ENV_DIR/bin/activate

# Instala os pacotes Python se necessário
echo "Verificando e instalando pacotes Python..."
pip_installed_packages=$(pip3 list --format=freeze | cut -d'=' -f1)
requirements_installed=true

while IFS= read -r package; do
    if ! echo "$pip_installed_packages" | grep -q "^$package\$"; then
        requirements_installed=false
        echo "O pacote $package não está instalado."
    fi
done < "$REQUIREMENTS"

if [ "$requirements_installed" = false ]; then
    pip3 install -r $REQUIREMENTS || {
        echo "Falha ao instalar os pacotes. Verifique se o arquivo requirements.txt está presente e correto."
        exit 1
    }
fi

# Remove o arquivo de saída do pip list
rm -f pip_list_output.txt

echo "Configuração concluída."
