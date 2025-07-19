#!/bin/bash

# Script de construcción y despliegue para API Rails con Tesseract OCR
# Uso: ./docker-deploy.sh [build|run|stop|restart|logs|clean]

set -e

# Configuración
IMAGE_NAME="api-bymedellin-imageocr"
CONTAINER_NAME="api-ocr"
PORT="3000"
VERSION="latest"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si Docker está instalado
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado o no está en el PATH"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker no está ejecutándose"
        exit 1
    fi
}

# Verificar archivo master.key
check_master_key() {
    if [ ! -f "config/master.key" ]; then
        log_warning "Archivo config/master.key no encontrado"
        log_info "Para producción, asegúrate de tener la clave maestra configurada"
    fi
}

# Construir imagen Docker
build_image() {
    log_info "Construyendo imagen Docker..."
    
    # Verificar si hay cambios en Dockerfile
    if [ -f ".docker-build-cache" ]; then
        DOCKERFILE_HASH=$(md5sum Dockerfile | cut -d' ' -f1)
        CACHED_HASH=$(cat .docker-build-cache 2>/dev/null || echo "")
        
        if [ "$DOCKERFILE_HASH" = "$CACHED_HASH" ]; then
            log_info "No hay cambios en Dockerfile, usando cache..."
            docker build -t $IMAGE_NAME:$VERSION .
        else
            log_info "Detectados cambios en Dockerfile, construyendo sin cache..."
            docker build --no-cache -t $IMAGE_NAME:$VERSION .
            echo $DOCKERFILE_HASH > .docker-build-cache
        fi
    else
        docker build -t $IMAGE_NAME:$VERSION .
        md5sum Dockerfile | cut -d' ' -f1 > .docker-build-cache
    fi
    
    log_success "Imagen construida exitosamente: $IMAGE_NAME:$VERSION"
}

# Ejecutar contenedor
run_container() {
    log_info "Iniciando contenedor..."
    
    # Detener contenedor existente si está ejecutándose
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        log_warning "Deteniendo contenedor existente..."
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    
    # Crear directorio para volúmenes si no existe
    mkdir -p docker-volumes/logs docker-volumes/storage
    
    # Obtener master key si existe
    MASTER_KEY=""
    if [ -f "config/master.key" ]; then
        MASTER_KEY=$(cat config/master.key)
    fi
    
    # Ejecutar contenedor
    docker run -d \
        --name $CONTAINER_NAME \
        -p $PORT:3000 \
        -e RAILS_ENV=production \
        -e RAILS_MASTER_KEY="$MASTER_KEY" \
        -e RAILS_LOG_TO_STDOUT=true \
        -v "$(pwd)/docker-volumes/logs:/rails/log" \
        -v "$(pwd)/docker-volumes/storage:/rails/storage" \
        --restart unless-stopped \
        $IMAGE_NAME:$VERSION
    
    log_success "Contenedor iniciado: $CONTAINER_NAME"
    log_info "API disponible en: http://localhost:$PORT"
    log_info "Health check: http://localhost:$PORT/api/v1/health"
}

# Detener contenedor
stop_container() {
    log_info "Deteniendo contenedor..."
    
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
        log_success "Contenedor detenido y eliminado"
    else
        log_warning "No hay contenedor ejecutándose con nombre: $CONTAINER_NAME"
    fi
}

# Reiniciar contenedor
restart_container() {
    log_info "Reiniciando contenedor..."
    stop_container
    run_container
}

# Ver logs
show_logs() {
    log_info "Mostrando logs del contenedor..."
    
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker logs -f $CONTAINER_NAME
    else
        log_error "Contenedor no está ejecutándose"
        exit 1
    fi
}

# Limpiar recursos Docker
clean_docker() {
    log_info "Limpiando recursos Docker..."
    
    # Detener contenedor si está ejecutándose
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        docker stop $CONTAINER_NAME
        docker rm $CONTAINER_NAME
    fi
    
    # Eliminar imagen
    if docker images -q $IMAGE_NAME | grep -q .; then
        docker rmi $IMAGE_NAME:$VERSION
        log_success "Imagen eliminada"
    fi
    
    # Limpiar cache de construcción
    rm -f .docker-build-cache
    
    # Limpiar volúmenes (opcional)
    read -p "¿Eliminar volúmenes de datos? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf docker-volumes/
        log_success "Volúmenes eliminados"
    fi
    
    log_success "Limpieza completada"
}

# Verificar estado del contenedor
status_container() {
    log_info "Estado del contenedor:"
    
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo -e "${GREEN}✓${NC} Contenedor ejecutándose"
        docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        # Verificar health check
        log_info "Verificando health check..."
        sleep 2
        if curl -s http://localhost:$PORT/api/v1/health > /dev/null; then
            echo -e "${GREEN}✓${NC} API respondiendo correctamente"
        else
            echo -e "${RED}✗${NC} API no responde"
        fi
    else
        echo -e "${RED}✗${NC} Contenedor no está ejecutándose"
    fi
}

# Función de ayuda
show_help() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  build     - Construir imagen Docker"
    echo "  run       - Ejecutar contenedor"
    echo "  stop      - Detener contenedor"
    echo "  restart   - Reiniciar contenedor"
    echo "  logs      - Ver logs del contenedor"
    echo "  status    - Ver estado del contenedor"
    echo "  clean     - Limpiar recursos Docker"
    echo "  help      - Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 build && $0 run    # Construir y ejecutar"
    echo "  $0 restart            # Reiniciar servicio"
    echo "  $0 logs               # Ver logs en tiempo real"
}

# Función principal
main() {
    check_docker
    
    case "${1:-help}" in
        build)
            check_master_key
            build_image
            ;;
        run)
            check_master_key
            run_container
            sleep 3
            status_container
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            sleep 3
            status_container
            ;;
        logs)
            show_logs
            ;;
        status)
            status_container
            ;;
        clean)
            clean_docker
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Comando no reconocido: $1"
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal con todos los argumentos
main "$@"