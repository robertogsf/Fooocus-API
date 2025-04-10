#!/bin/bash

INACTIVE_TIMEOUT=300  # 5 minutos en segundos
LAST_ACTIVITY_FILE="/tmp/last_activity"
HAD_REQUEST_FILE="/tmp/had_request"
PORT=8888  # Puerto para FastAPI

# Función para limpiar y matar procesos
cleanup() {
    if [ ! -z "$SERVER_PID" ]; then
        echo "Matando proceso anterior: $SERVER_PID"
        kill -9 $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null
    fi
    
    # Buscar y matar cualquier proceso usando el puerto
    echo "Liberando puerto $PORT..."
    fuser -k ${PORT}/tcp 2>/dev/null || true
    
    # Esperar a que el puerto se libere completamente
    sleep 2
    
    # Verificar si el puerto está realmente libre
    if fuser ${PORT}/tcp 2>/dev/null; then
        echo "ERROR: El puerto ${PORT} sigue en uso"
        exit 1
    else
        echo "Puerto ${PORT} liberado correctamente"
    fi
}

# Manejar señales de terminación
trap cleanup SIGINT SIGTERM

# Asegurarse de que el puerto esté libre antes de empezar
cleanup

# Inicializar archivos
echo "0" > "$LAST_ACTIVITY_FILE"
echo "false" > "$HAD_REQUEST_FILE"

# Función para iniciar el servidor
start_server() {
    cleanup
    echo "Iniciando nuevo servidor FastAPI..."
    python main.py --host 0.0.0.0 --port $PORT --skip-pip &
    SERVER_PID=$!
    echo "Nuevo servidor iniciado con PID: $SERVER_PID"
}

# Iniciar el servidor por primera vez
start_server

while true; do
    sleep 10
    
    LAST_ACTIVITY=$(cat "$LAST_ACTIVITY_FILE")
    HAD_REQUEST=$(cat "$HAD_REQUEST_FILE")
    CURRENT_TIME=$(date +%s)
    
    if [ "$HAD_REQUEST" = "true" ] && [ "$LAST_ACTIVITY" != "0" ]; then
        ELAPSED=$((CURRENT_TIME - LAST_ACTIVITY))
        
        if [ $ELAPSED -gt $INACTIVE_TIMEOUT ]; then
            echo "Reiniciando servidor después de 5 minutos de inactividad post-solicitud..."
            
            # Usar la función de inicio del servidor que incluye la limpieza
            start_server
            
            # Resetear los estados
            echo "0" > "$LAST_ACTIVITY_FILE"
            echo "false" > "$HAD_REQUEST_FILE"
        fi
    fi
done