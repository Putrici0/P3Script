
#!/bin/bash

# Nombre de la VM y usuario SSH
VM_NAME="mvp3"
VM_USER="root"  # <-- Cambia esto si el usuario SSH no es root

xml="/etc/libvirt/qemu/mvp3.xml"


# Función para mostrar errores
error() {
    echo "ERROR: $1"
    virsh shutdown mvp3
    exit 1
}


#######################
# VERIFICACIÓN CLUSTER
#######################

verificar_redes_y_vm() {
virsh start mvp5
echo "Iniciando la máquina virtual 'mvp3', por favor espere 30 segundos..."
sleep 40

#############################
# VERIFICACIÓN DE CONECTIVIDAD
#############################
echo "== Comprobación de conectividad =="

check_ping() {
    destino=$1
    interfaz=$2
    descripcion=$3

    if [ -n "$interfaz" ]; then
        salida_ping=$(ping -c 1 -W 1 -I "$interfaz" "$destino" 2>/dev/null)
    else
        salida_ping=$(ping -c 1 -W 1 "$destino" 2>/dev/null)
    fi

    echo "$salida_ping" | grep "1 received" > /dev/null
    if [ $? -ne 0 ]; then
        error "No se ha recibido respuesta de $descripcion"
    else
        echo "✅ Éxito: Respuesta de $descripcion"
    fi
}

#############################
# CONEXION CON LA MÁQUINA
#############################
VM_IP=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {split($4, a, "/"); print a[1]}')
[ -n "$VM_IP" ] || error "No se pudo obtener la IP de la máquina virtual $VM_NAME"
ssh ${VM_USER}@${VM_IP} << 'EOF'

echo "Fin de comprobaciones."
EOF

#############################
# COMPROBACIÓN XML DE VM
#############################

virsh shutdown mvp3
exit 0
}

#############################
# CONEXION AL ANFITRION
#############################

# Si el primer argumento es "local", ejecutar directamente
if [ "$1" == "local" ]; then
    shift
    echo "✅ Ejecutando comprobaciones en anfitrión local (modo remoto 'local')..."
    verificar_redes_y_vm
    exit 0
fi

# Si se pasa una IP, ejecutar en remoto
if [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    remote_host="$1"
    echo "📡 Ejecutando comprobaciones en anfitrión remoto $remote_host..."

    # Copiar el script al remoto
    scp "$0" "$remote_host:/tmp/"
    if [ $? -ne 0 ]; then
        echo "[ERROR] No se pudo copiar el script al anfitrión remoto"
        exit 1
    fi

    # Ejecutar el script en el remoto con el flag "local"
    ssh "$remote_host" "bash /tmp/$(basename "$0") local"
    exit 0
fi

# Si el argumento no es válido
echo "[ERROR] Argumento no reconocido: '$1'"
echo "Uso: $0 [IP_remota] | local"
exit 1
