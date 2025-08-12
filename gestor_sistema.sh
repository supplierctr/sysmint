#!/bin/bash



# Salir inmediatamente si un comando falla.
set -e

# --- Definición de Colores y Estilos ---
VERDE='\033[1;32m'
AMARILLO='\033[1;33m'
AZUL='\033[1;34m'
ROJO='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m' # Sin color

# --- Funciones de Utilidad ---

# Imprime un banner profesional para el script
print_banner() {
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${CYAN}#                                                    #${NC}"
    echo -e "${CYAN}#        ${VERDE}SysMint: Gestor Avanzado de Sistema${NC}       ${CYAN}#${NC}"
    echo -e "${CYAN}#                                                    #${NC}"
    echo -e "${CYAN}======================================================${NC}"
}

# Función para verificar si un comando está disponible
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Funciones Principales del Sistema ---

verificar_actualizaciones() {
    echo -e "${AZUL}--- Verificando Actualizaciones del Sistema ---${NC}"

    # 1. Actualizar la lista de paquetes (requiere sudo)
    echo -e "${CYAN}Actualizando lista de paquetes APT...${NC}"
    sudo apt-get update -qq

    # 2. Contar los paquetes actualizables de forma robusta
    # Se redirige stderr a /dev/null para ignorar advertencias.
    # Se usa `grep -c /` para contar solo las líneas que contienen nombres de paquetes (ej: firefox/stable...).
    # `|| true` asegura que el script no se detenga si no hay actualizaciones (grep devuelve 1 si no encuentra nada).
    APT_TOTAL=$(apt list --upgradable 2>/dev/null | grep -c / || true)

    if [ "$APT_TOTAL" -gt 0 ]; then
        echo -e "${AMARILLO}APT: Hay $APT_TOTAL actualizaciones disponibles.${NC}"
        echo -e "${AMARILLO}Puedes ver los paquetes con: apt list --upgradable${NC}"
    else
        echo -e "${VERDE}APT: El sistema está actualizado.${NC}"
    fi

    if command_exists flatpak; then
        echo -e "${CYAN}Verificando actualizaciones de Flatpak...${NC}"
        FLATPAK_UPDATES=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
        if [ "$FLATPAK_UPDATES" -gt 0 ]; then
            echo -e "${AMARILLO}Flatpak: Hay $FLATPAK_UPDATES actualizaciones disponibles.${NC}"
        else
            echo -e "${VERDE}Flatpak: No hay paquetes para actualizar.${NC}"
        fi
    fi
}

aplicar_actualizaciones() {
    echo -e "${AZUL}--- Aplicando Actualizaciones ---${NC}"
    if command_exists aptitude; then
        echo -e "${CYAN}Usando aptitude para actualizar...${NC}"
        sudo aptitude upgrade -y
    else
        echo -e "${CYAN}Usando apt para actualizar...${NC}"
        sudo apt upgrade -y
        sudo apt autoremove -y
    fi

    if command_exists flatpak; then
        echo -e "${CYAN}Aplicando actualizaciones de Flatpak...${NC}"
        flatpak update -y
    fi
    echo -e "${VERDE}¡Sistema actualizado con éxito!${NC}"
}

# --- Funciones de GitHub ---

github_menu() {
    if ! command_exists gh; then
        echo -e "${ROJO}Error: El CLI de GitHub ('gh') no está instalado.${NC}"
        echo -e "${AMARILLO}Es la forma recomendada y segura de interactuar con GitHub.${NC}"
        read -p "¿Deseas instalarlo ahora? (s/n): " install_gh
        if [[ "$install_gh" == "s" || "$install_gh" == "S" ]]; then
            sudo apt update && sudo apt install gh -y
            echo -e "${VERDE}¡'gh' instalado! Por favor, ejecútalo de nuevo.${NC}"
        fi
        return
    fi

    # Verificar autenticación
    if ! gh auth status >/dev/null 2>&1; then
        echo -e "${AMARILLO}No has iniciado sesión en GitHub.${NC}"
        read -p "¿Deseas iniciar sesión ahora? (s/n): " login_gh
        if [[ "$login_gh" == "s" || "$login_gh" == "S" ]]; then
            # El usuario seguirá las instrucciones interactivas de 'gh'
            gh auth login
        fi
        return
    fi
    
    echo -e "${AZUL}--- Menú de GitHub ---${NC}"
    echo "1) Listar mis repositorios"
    echo "2) Crear un nuevo repositorio"
    echo "3) Clonar un repositorio"
    echo "4) Volver al menú principal"
    read -p "Elige una opción: " gh_choice

    case "$gh_choice" in
        1)
            echo -e "${CYAN}Listando tus repositorios...${NC}"
            gh repo list
            ;;
        2)
            read -p "Nombre para el nuevo repositorio: " repo_name
            if [ -n "$repo_name" ]; then
                gh repo create "$repo_name" --public --confirm
                echo -e "${VERDE}¡Repositorio '$repo_name' creado!${NC}"
            fi
            ;;
        3)
            clonar_repo_github
            ;;
        4) return ;; 
        *)
            echo -e "${ROJO}Opción inválida.${NC}"
            ;; 
    esac
}

clonar_repo_github() {
    if ! command_exists git; then
        echo -e "${ROJO}Error: 'git' no está instalado. Por favor, instálalo con 'sudo apt install git'.${NC}"
        return
    fi
    echo -e "${AZUL}--- Clonar Repositorio de GitHub ---${NC}"
    read -p "Pega la URL del repositorio (HTTPS o SSH): " repo_url
    if [ -n "$repo_url" ]; then
        git clone "$repo_url"
        echo -e "${VERDE}¡Repositorio clonado con éxito!${NC}"
    fi
}

# --- Otras Funciones ---

gemini_menu() {
    echo -e "${AZUL}--- Menú de Gemini ---${NC}"
    echo "1) Montar carpeta"
    echo "2) Correr Gemini (debug)"
    echo "3) Correr servidor con Python"
    echo "4) Volver al menú principal"
    read -p "Elige una opción: " gemini_choice

    case "$gemini_choice" in
        1)
            echo -e "${CYAN}Listando carpetas...${NC}"
            select dir in */; do
                if [ -n "$dir" ]; then
                    cd "$dir"
                    echo -e "${VERDE}Montado en $(pwd)${NC}"
                    break
                else
                    echo -e "${ROJO}Selección inválida.${NC}"
                fi
            done
            ;;
        2)
            echo -e "${CYAN}Corriendo Gemini en modo debug...${NC}"
            gemini --debug
            ;;
        3)
            echo -e "${CYAN}Corriendo servidor Python...${NC}"
            echo -e "${AMARILLO}Accede a http://localhost:8000 en tu navegador.${NC}"
            python3 -m http.server
            ;;
        4) return ;; 
        *)
            echo -e "${ROJO}Opción inválida.${NC}"
            ;; 
    esac
}

# --- Menú Principal ---
while true; do
    print_banner
    printf " %-45s\n" "Selecciona una tarea:"
    echo "------------------------------------------------------"
    printf " ${VERDE}1)${NC} Verificar actualizaciones
"
    printf " ${VERDE}2)${NC} Aplicar actualizaciones
"
    printf " ${CYAN}3)${NC} Clonar repositorio de GitHub
"
    printf " ${CYAN}4)${NC} Menú de GitHub (con 'gh')
"
    printf " ${AZUL}5)${NC} Ejecutar Gemini
"
    printf " ${ROJO}6)${NC} Salir
"
    echo "------------------------------------------------------"
    read -p "Ingresa tu elección [1-6]: " choice

    case "$choice" in
        1)
            verificar_actualizaciones
            ;; 
        2)
            verificar_actualizaciones
            read -p "¿Deseas aplicar las actualizaciones encontradas? (s/n): " apply
            if [[ "$apply" == "s" || "$apply" == "S" ]]; then
                aplicar_actualizaciones
            else
                echo -e "${AMARILLO}Operación cancelada.${NC}"
            fi
            ;; 
        3)
            clonar_repo_github
            ;; 
        4)
            github_menu
            ;; 
        5)
            gemini_menu
            ;; 
        6)
            echo -e "${AMARILLO}Saliendo... ¡Hasta pronto!${NC}"
            exit 0
            ;; 
        *)
            echo -e "${ROJO}Elección inválida. Por favor, selecciona una opción del 1 al 6.${NC}"
            ;; 
    esac

    read -p $'
Presiona Enter para continuar...'
done
