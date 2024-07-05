import cv2
import pytesseract
import argparse
import numpy as np

# Configurar o caminho para o executável do Tesseract, se necessário
pytesseract.pytesseract.tesseract_cmd = r'/usr/bin/tesseract'  # Atualize com o caminho correto

def find_text_in_image(image_path, search_text):
    # Carregar a imagem da captura de tela
    image = cv2.imread(image_path)

    # Verificar se a imagem foi carregada corretamente
    if image is None:
        print("Erro ao carregar a imagem. Verifique o caminho do arquivo.")
        return

    # Usar pytesseract para fazer OCR na imagem
    try:
        text_data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
        
        # Iterar através dos resultados para encontrar o texto especificado
        for i in range(len(text_data['text'])):
            if search_text in text_data['text'][i]:
                x = text_data['left'][i]
                y = text_data['top'][i]
                w = text_data['width'][i]
                h = text_data['height'][i]
                print(f'Text "{search_text}" found at (x={x}, y={y}), width: {w}, height: {h}')
                return (x, y, w, h)
        else:
            print(f'Text "{search_text}" not found')
            return None
    except pytesseract.pytesseract.TesseractError as e:
        print(f'Erro ao executar o Tesseract: {e}')
    except Exception as e:
        print(f'Erro inesperado: {e}')

def find_image_in_image(image_path, template_path):
    # Carregar a imagem da captura de tela e a imagem template
    image = cv2.imread(image_path)
    template = cv2.imread(template_path, 0)
    
    # Verificar se as imagens foram carregadas corretamente
    if image is None:
        print("Erro ao carregar a imagem. Verifique o caminho do arquivo.")
        return None
    if template is None:
        print("Erro ao carregar a imagem template. Verifique o caminho do arquivo.")
        return None

    # Converter a imagem para escala de cinza
    gray_image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    # Usar correspondência de template
    result = cv2.matchTemplate(gray_image, template, cv2.TM_CCOEFF_NORMED)
    
    # Obter o valor máximo de correspondência e a localização
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)
    
    # Definir um limiar para a correspondência (ajuste conforme necessário)
    threshold = 0.7

    if max_val >= threshold:
        print(f'Template found at (x={max_loc[0]}, y={max_loc[1]}) with confidence {max_val}')
        return max_loc
    else:
        print('Template not found')
        return None

# Configurar o analisador de argumentos
parser = argparse.ArgumentParser(description='Procurar texto ou imagem em uma captura de tela usando OCR e correspondência de template.')

# Argumento opcional para procurar texto
parser.add_argument('--search_text', type=str, help='Texto a ser procurado na imagem')

# Argumento opcional para procurar imagem template
parser.add_argument('--template_path', type=str, help='Caminho para a imagem template a ser procurada')

# Argumento opcional para especificar o caminho da imagem (padrão: screenshot.png)
parser.add_argument('--image_path', type=str, default='screenshot.png', help='Caminho para a imagem (padrão: screenshot.png)')

# Parse dos argumentos
args = parser.parse_args()

# Verificar se foi fornecido algum argumento
if not (args.search_text or args.template_path):
    parser.print_help()
else:
    # Verificar se o argumento search_text foi fornecido
    if args.search_text:
        find_text_in_image(args.image_path, args.search_text)
    
    # Verificar se o argumento template_path foi fornecido
    if args.template_path:
        find_image_in_image(args.image_path, args.template_path)
