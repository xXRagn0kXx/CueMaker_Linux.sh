#!/bin/bash
# Generador de archivos .cue para PC
# .cue file generator for PC
# Autor: Davisito
# Author: Davisito
# Este script crea un archivo .cue a partir de un archivo .bin
# This script creates a .cue file from a .bin file
# seleccionado por el usuario, utilizando la herramienta 'dialog'
# selected by the user, using the 'dialog' tool
# para la interfaz de usuario.
# for the user interface.

# --- Configuracion inicial para PC ---
# --- Initial setup for PC ---
# Limpiar la terminal
# Clear the terminal
clear

# Ocultar el cursor
# Hide the cursor
tput civis
# Limpiar dialogo
# Clear dialog
dialog --clear
# Variables de configuracion para los cuadros de dialogo
# Configuration variables for dialog boxes
height="15"
width="55"

# Texto empiece de ejecucion
# Execution start text
echo "Iniciando el generador de CUE. Por favor, espere..."

# ------------------- Variables globales ------------------
# ------------------- Global variables ------------------
# Solo se asigna cuando el usuario ACEPTA explícitamente ('.' o archivo).
# It's only assigned when the user explicitly ACCEPTS ('.' or a file).
# En cancelación debe quedar vacío.
# On cancellation, it must be empty.
Ruta_Final=""

# Funcion para salir del menu y restablecer la terminal
# Function to exit the menu and reset the terminal
Salir_Menu() {
    clear
    # Mostrar el cursor de nuevo
    # Show the cursor again
    tput cnorm
    exit 0
}

Menu_Principal() {
    while true; do
        opcion=$(dialog --backtitle "Generador de CUE" \
                --title "Menu principal" \
                --menu "Selecciona el modo necesario para el .bin" \
                $height $width 5 \
                1 "MODE2/2352 (ps1 Default)" \
                2 "MODE1/2352 (ps1 Alternative)" \
                3 "MODE1/2048(Sega CD, PC Engine, Neo Geo)" \
                4 "MODE2/2336(Saturn,ps1,3DO)" \
                5 "AUDIO" \
                2>&1 >/dev/tty)

        case $opcion in
            1)
                Modo="MODE2/2352"
                echo "Seleccionaste MODE2/2352" >/dev/tty
                if Seleccionar_Archivo "/roms"; then
                    Cue_Maker "$Modo" "$Ruta_Final"
                fi
                ;;
            2)
                Modo="MODE1/2352"
                echo "Seleccionaste MODE1/2352" >/dev/tty
                if Seleccionar_Archivo "/roms"; then
                    Cue_Maker "$Modo" "$Ruta_Final"
                fi
                ;;
            3)
                Modo="MODE1/2048"
                echo "Seleccionaste MODE1/2048" >/dev/tty
                if Seleccionar_Archivo "/roms"; then
                    Cue_Maker "$Modo" "$Ruta_Final"
                fi
                ;; 
            4)
                Modo="MODE2/2336"
                echo "Seleccionaste MODE2/2336" >/dev/tty
                if Seleccionar_Archivo "/roms"; then
                    Cue_Maker "$Modo" "$Ruta_Final"
                fi
                ;;
            5)
                Modo="AUDIO"
                echo "Seleccionaste AUDIO" >/dev/tty
                if Seleccionar_Archivo "/roms"; then
                    Cue_Maker "$Modo" "$Ruta_Final"
                fi
                ;;
            *)
                # Si el usuario cancela o sale, se cierra el script.
                # If the user cancels or exits, the script closes.
                echo "Saliendo del script. ¡Adios!" >/dev/tty
                break
                ;;
        esac

        # Comprobacion de salida si el usuario cancelo la operacion
        # Check for exit if the user canceled the operation
        if [[ -z "$Ruta_Final" ]]; then
            break
        fi
    done
}

# Funcion para seleccionar un archivo o directorio
# Function to select a file or directory
Seleccionar_Archivo() {
    # Guardar el directorio de inicio
    # Save the starting directory
    local start_dir="$1"

    # Restablecer la pantalla y el cursor
    # Reset the screen and the cursor
    tput civis
    dialog --clear

    local current_dir="$start_dir"
    local selected_path=""

    # Asegurar que los globs vacios no devuelvan el patron literal
    # Ensure that empty globs don't return the literal pattern
    shopt -s nullglob

    while true; do
        # Construir items del menu desde cero en cada iteracion
        # Build menu items from scratch in each iteration
        local menu_items=()
        menu_items+=("." "Seleccionar este directorio")
        menu_items+=(".." "Subir un nivel")

        # Listamos los contenidos del directorio actual
        # List the contents of the current directory
        for entry in "$current_dir"/*; do
            local name
            name=$(basename "$entry")
            if [ -d "$entry" ]; then
                menu_items+=("$name/" "Directorio")
            elif [ -f "$entry" ]; then
                menu_items+=("$name" "Archivo")
            fi
        done

        # Mostrar el menu con dialog
        # Show the menu with dialog
        # Usamos --output-fd 1 para que SOLO la seleccion vaya por stdout (que capturamos),
        # We use --output-fd 1 so that ONLY the selection goes to stdout (which we capture),
        # y mandamos la interfaz (stderr) al TTY para evitar "residuos" en la variable.
        # and we send the interface (stderr) to TTY to avoid "residue" in the variable.
        local selection
        # Mostrar el menu con dialog y capturar codigo de salida
        # Show the menu with dialog and capture the exit code
        selection=$(dialog \
            --clear \
            --backtitle "Generador de CUE" \
            --title "Selecciona un archivo .bin" \
            --menu "Directorio actual: $current_dir" 20 70 15 \
            "${menu_items[@]}" \
            --output-fd 1 \
            2>/dev/tty)
        rc=$?

        case $rc in
            0)
                # OK procesar seleccion
                # OK process selection
                ;;
            1)
                # Cancelar no guardar nada y volver al menu principal
                # Cancel do not save anything and return to the main menu
                Ruta_Final=""
                dialog --msgbox "No se ha seleccionado ninguna ruta/archivo" 8 60 2>/dev/tty
                return 1
                ;;
            255)
                # ESC o Select+Start salir del script inmediatamente
                # ESC or Select+Start exit the script immediately
                Salir_Menu
                ;;
        esac

        case "$selection" in
            ".")
                # Usar este directorio para todos los .bin
                # Use this directory for all .bin files
                selected_path="$current_dir"
                Ruta_Final="$selected_path"
                return 0
                ;;
            "..")
                # Subir un nivel de directorio
                # Go up one directory level
                local parent
                parent=$(dirname "$current_dir")

                # Evitar quedarse en bucle si ya estamos en /
                # Avoid getting stuck in a loop if we are already at /
                if [ "$parent" != "$current_dir" ]; then
                    current_dir="$parent"
                fi
                ;;
            */)
                # Entrar a un subdirectorio
                # Enter a subdirectory
                current_dir="${current_dir%/}/$selection"
                # Quitar barra final si se duplico
                # Remove trailing slash if it was duplicated
                current_dir="${current_dir%/}"
                ;;
            *)
                # Se ha seleccionado un archivo
                # A file has been selected
                selected_path="${current_dir%/}/$selection"
                Ruta_Final="$selected_path"
                return 0
                ;;
        esac
    done
}

# ------------------- Logica principal del script ------------------
# ------------------- Main script logic ------------------

# Funcion para generar el archivo .cue
# Function to generate the .cue file

Cue_Maker() {
    local Modo="$1"
    local Ruta_Final="$2"

    # Si la ruta es un directorio
    # If the path is a directory
    if [[ -d "$Ruta_Final" ]]; then
        dialog --clear
        dialog --title "Advertencia" --yesno "Se van a reemplazar todos los .cue existentes en el directorio: $Ruta_Final \n\nNOTA: Esto llevara un tiempo dependiendo los ficheros a generar. No tocar nada hasta que esta pantalla se actualice sola.\n\n¿Desea continuar?" 13 60 2>/dev/tty
        local rc=$?

        case $rc in
            0)
                # El usuario aceptó, procesar todos los .bin
                # The user accepted, process all .bin files
                local bin_files=("$Ruta_Final"/*.bin)
                local cue_count=0
                if [[ ${#bin_files[@]} -gt 0 ]]; then
                    for bin_file in "${bin_files[@]}"; do
                        local bin_name=$(basename "$bin_file")
                        local cue_name="${bin_name%.bin}.cue"
                        local cue_path="$Ruta_Final/$cue_name"

                        # Definimos el contenido del archivo .cue en una variable
                        # We define the content of the .cue file in a variable
                        local cue_content="FILE \"$bin_name\" BINARY\n  TRACK 01 $Modo\n    INDEX 01 00:00:00"
                        
                        # Escribimos el contenido en el archivo
                        # We write the content to the file
                        echo -e "$cue_content" > "$cue_path"
                        ((cue_count++))
                    done
                    dialog --clear
                    dialog --msgbox "Se han generado $cue_count archivos .cue en formato $Modo en el directorio: $Ruta_Final" 10 60 2>/dev/tty
                else
                    dialog --clear
                    dialog --msgbox "No se encontraron archivos .bin en el directorio: $Ruta_Final" 10 60 2>/dev/tty
                fi
                ;;
            1)
                # Cancelar → volver al mismo directorio
                # Cancel → return to the same directory
                Seleccionar_Archivo "$Ruta_Final"
                return
                ;;
            255)
                # ESC → salir del script
                # ESC → exit the script
                Salir_Menu
                ;;
        esac
        
    # Si la ruta es un fichero
    # If the path is a file
    elif [[ -f "$Ruta_Final" ]]; then
        if [[ "$Ruta_Final" == *.bin ]]; then
            local bin_name=$(basename "$Ruta_Final")
            local cue_path="${Ruta_Final%.bin}.cue"
            
            # Definimos el contenido del archivo .cue en una variable
            # We define the content of the .cue file in a variable
            local cue_content="FILE \"$bin_name\" BINARY\n  TRACK 01 $Modo\n    INDEX 01 00:00:00"
            
            # Escribimos el contenido en el archivo
            # We write the content to the file
            echo -e "$cue_content" > "$cue_path"
            
            dialog --clear
            dialog --msgbox "Se ha generado el fichero: $cue_path" 10 60 2>/dev/tty
        else
            dialog --clear
            dialog --msgbox "El archivo seleccionado no es un .bin." 10 60 2>/dev/tty
            # Regresar al menu de seleccion de archivo
            # Return to the file selection menu
            Seleccionar_Archivo "/roms"
            return
        fi
    fi
 
    # Volver al menu principal despues de la operacion
    # Return to the main menu after the operation
    Ruta_Final=""
    Menu_Principal
}

# ------------------- Logica de inicio ----------------------------

clear
dialog --clear
trap Salir_Menu EXIT
# Mostrar el menu de seleccion de Modo
# Show the Mode selection menu
Menu_Principal