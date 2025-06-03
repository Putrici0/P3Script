
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

verificar_redes_y_vm() {
virsh start mvp3
echo "Iniciando la máquina virtual 'mvp3', por favor espere 30 segundos..."
sleep 10


#################################
# VERIFICACIÓN VOL1_p3 (TAREA 1)
#################################

# Comprobacion que existe el Volumen en default y el nombre
if virsh vol-list default | grep -q Vol1_p3; then
    echo "Exito: El volumen Vol1_p3 existe"
elif virsh vol-list default | grep -q Vol1_p3.img; then
    echo "Exito: El volumen Vol1_p3 existe"
else
    error "No se encuentra el volumen Vol1_p3"
fi

# Comprobar el tipo de volumen
tipo_vol1_p3=$(virsh vol-dumpxml Vol1_p3 --pool default | grep "format type" | tr -s ' ' | cut -c 16-18)
[ "$nombre_cluster" == "raw" ] || error "Tipo de volumen incorrecto: $tipo_vol1_p3"
echo "✅ Éxito: Tipo de Vol1_p3 correcto."

# Comprobacion de tamaño del volumen
tamano_vol1_p3=$(virsh vol-dumpxml Vol1_p3 --pool default | grep "capacity unit" | tr -s ' ' | cut -c 25-34)
[ "$tamano_vol1_p3" == "1073741824" ] || error "Tamaño incorrecto de Vol1_p3: $tamano_vol1_p3"
echo "✅ Éxito: Tamaño de Vol1_p3 correcto."

#################################
# VERIFICACIÓN VOL1_p3 (TAREA 2)
#################################

# Comprobacion de Vol1_p3 a SATA
if virsh dumpxml mvp3 | grep -A 5 "Vol1_p3" | grep sata; then
    echo "✅ Éxito: El volumen  Vol1_p3 esta correctamente asociado al bus SATA."
else
    error "No se ha asociado el volumen Vol1_p3 al bus SATA."

# Comprobacion de que se ha creado una particion en sda
if lsblk /dev/sda --noheadings | grep "512M"; then
    echo "✅ Éxito: La particion de 512M en Vol1_p3 es correcta."
else
    error "No es correcta la particion de 512M en Vol1_p3."

# Comprobacion de que se ha creado una particion en sda
if lsblk -f /dev/sda | grep "xfs"; then
    echo "✅ Éxito: La particion de 512M en Vol1_p3 tiene un sistema de ficheros XFS."
else
    error "La particion de 512M en Vol1_p3 no tiene un sistema de ficheros XFS."




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
