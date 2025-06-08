#!/bin/bash

# Nombre de la VM y usuario SSH
VM_NAME="mvp3"
VM_USER="root"

xml="/etc/libvirt/qemu/mvp3.xml"

HOST_NUM=$(hostname | grep -o '[0-9]\+')
HOST_LETTER=$(hostname | sed -n 's/^lq-\([a-z]\)[0-9]\+.*/\1/p' | tr '[:lower:]' '[:upper:]')
GRADO=$2


# Validar grado
if [[ "$GRADO" != "1" && "$GRADO" != "2" ]]; then
    echo "Error: el grado debe ser 1 o 2 (1=GII o 2=GCID)"
    exit 1
fi

# Construir nombre del volumen de la tarea 5
VOLUMEN="pc${HOST_NUM}_LQ${HOST_LETTER}_ANFITRION${GRADO}_Vol3_p3"
# Función para mostrar errores
error() {
    echo "ERROR: $1"
    virsh shutdown mvp3
    virsh pool-destroy CONT_VOL_COMP
    exit 1
}

verificar_redes_y_vm() {

#################################
# INICIALIZACIÓN DE COMPONENETES
#################################

estado_pool=$(virsh pool-info CONT_VOL_COMP 2>/dev/null | grep -i Estado | awk '{print $2}')
if [[ "$estado_pool" != "ejecutando" ]]; then
    virsh pool-start CONT_VOL_COMP &> /dev/null || error "No se pudo iniciar el contenedor CONT_VOL_COMP"
    echo "✅ Contenedor CONT_VOL_COMP iniciado correctamente."
else
    echo "ERROR: El contenedor CONT_VOL_COMP ya estaba activo."
    exit 1
fi


echo "Iniciando la máquina virtual 'mvp3', por favor espere 20 segundos..."
estado_vm=$(virsh domstate mvp3 2>/dev/null)
if [[ "$estado_vm" != "encendido" ]]; then
    virsh start mvp3 &> /dev/null || error "No se pudo iniciar la máquina virtual mvp3"
    sleep 20
else
    echo "ERROR: La máquina virtual mvp3 ya estaba encendida."
fi


#################################
# VERIFICACIÓN VOL1_p3 (TAREA 1)
#################################

# Comprobación que existe el Volumen en default y el nombre
if virsh vol-list default | grep Vol1_p3 >/dev/null 2>&1; then
    VOLUMEN_REAL_VOL1=$(virsh vol-list --pool default | grep Vol1_p3 | tr -s ' ' | cut -d' ' -f2)
    echo "✅ Éxito: El volumen Vol1_p3 existe"
else
    error "No se encuentra el volumen Vol1_p3"
fi

# Comprobar el tipo de volumen
tipo_vol1_p3=$(virsh vol-dumpxml $VOLUMEN_REAL_VOL1 --pool default | grep "format type" | tr -s ' ' | cut -c 16-18)
[ "$tipo_vol1_p3" == "raw" ] || error "Tipo de volumen incorrecto: $tipo_vol1_p3 es distinto de raw"
echo "✅ Éxito: Tipo de Vol1_p3 correcto."

# Comprobación de tamaño del volumen
tamano_vol1_p3=$(virsh vol-dumpxml $VOLUMEN_REAL_VOL1 --pool default | grep "capacity unit" | tr -s ' ' | cut -c 25-34)
[ "$tamano_vol1_p3" == "1073741824" ] || error "Tamaño incorrecto de Vol1_p3: $tamano_vol1_p3 no es 1GB"
echo "✅ Éxito: Tamaño de Vol1_p3 correcto."

#################################
# VERIFICACIÓN VOL1_p3 (TAREA 1) PT.2
#################################

# Comprobación de Vol1_p3 a SATA
if virsh dumpxml mvp3 | grep -A 5 $VOLUMEN_REAL_VOL1 | grep sata >/dev/null 2>&1; then
    echo "✅ Éxito: El volumen  Vol1_p3 esta correctamente asociado al bus SATA."
else
    error "No se ha asociado el volumen Vol1_p3 al bus SATA."
fi

#################################
# VERIFICACIÓN PARTICION (TAREA 2) PT.1
#################################

particion_conectada=$(virsh dumpxml mvp3 | tr -s ' ' | grep sda | wc -l)

# Comprobación de conexión de la partición del anfitrión a la máquina
if [ $particion_conectada == "2" ]; then
    echo "✅ Éxito: La partición esta conectada a la máquina."
else
    error "La partición no se encuentra conectada a la máquina."
fi

#################################
# VERIFICACIÓN VOL2_p3 (TAREA 3)
#################################

VOLUMEN_REAL_VOL2=$(virsh vol-list --pool Contenedor_Particion | grep Vol2_p3 | tr -s ' ' | cut -d' ' -f2)

# Comprobación de nombre del volumen
if virsh vol-dumpxml --vol /var/lib/libvirt/Pool_Particion/$VOLUMEN_REAL_VOL2 --pool Contenedor_Particion | grep name | grep Vol2_p3 >/dev/null 2>&1; then
    echo "✅ Éxito: El volumen $VOLUMEN_REAL_VOL2 se llama de forma correcta."
else
    error "El volumen $VOLUMEN_REAL_VOL2 no tiene el nombre requerido."
fi
    
# Comprobación de tipo de volumen de vol2_p3
if virsh vol-dumpxml --vol /var/lib/libvirt/Pool_Particion/$VOLUMEN_REAL_VOL2 | grep format | grep qcow2 >/dev/null 2>&1; then
    echo "✅ Éxito: El volumen Vol2_p3 es de tipo qcow2"
else
    error "El tipo de volumen de Vol2_p3 es incorrecto."
fi
    
# Comprobación del tamaño del volumen vol2_p3
if virsh vol-dumpxml --vol /var/lib/libvirt/Pool_Particion/$VOLUMEN_REAL_VOL2 | grep capacity | grep 1073741824 >/dev/null 2>&1; then
    echo "✅ Éxito: El volumen Vol2_p3 es de exactamente 1GB"
else
    error "El tamaño de Vol2_p3 es incorrecto."
fi

#################################
# VERIFICACIÓN CONT_ISOS_COMP (TAREA 4)
#################################

# Comprobación de nombre de CONT_ISOS_COMP
if virsh pool-dumpxml CONT_ISOS_COMP | grep "<name>" | grep CONT_ISOS_COMP >/dev/null 2>&1; then
    echo "✅ Éxito: El contenedor CONT_ISOS_COMP se llama correctamente"
else
    error "El contenedor CONT_ISOS_COMP no se llama de la forma correcta."
fi

# Comprobación de la ruta de CONT_ISOS_COMP
if virsh pool-dumpxml CONT_ISOS_COMP | grep "<path>" | grep /var/lib/libvirt/images/ISOS >/dev/null 2>&1; then
    echo "✅ Éxito: La ruta del CONT_ISOS_COMP es var/lib/libvirt/images/ISOS"
else
    error "El contenedor CONT_ISOS_COMP no se encuentra en la ruta correcta."
fi

# Comprobación del servidor NFS
if virsh pool-dumpxml CONT_ISOS_COMP | grep "name=" | grep disnas2.dis.ulpgc.es >/dev/null 2>&1; then
    echo "✅ Éxito: El servidor NFS de CONT_ISOS_COMP es disnas2.dis.ulpgc.es"
else
    error "El servidor NFS de CONT_ISOS_COMP es incorrecto."
fi

# Comprobación de la ruta del servidor NFS
if virsh pool-dumpxml CONT_ISOS_COMP | grep dir | grep /imagenes/fedora/41/isos/x86_64 >/dev/null 2>&1; then
    echo "✅ Éxito: La ruta del servidor NFS de CONT_ISOS_COMP es imagenes/fedora/41/isos/x86_64"
else
    error "La ruta del servidor NFS de CONT_ISOS_COMP es incorrecta."
fi

# Comprobación del autoarranque de CONT_ISOS_COMP
if virsh pool-info CONT_ISOS_COMP | grep Autoinicio | grep no >/dev/null 2>&1; then
    echo "✅ Éxito: El autoinicio está desactivado para CONT_ISOS_COMP"
else
    error "El autoinicio está activado para CONT_ISOS_COMP."
fi

#################################
# VERIFICACIÓN CONT_VOL_COMP (TAREA 5)
#################################

# Comprobación de nombre de CONT_VOL_COMP
if virsh pool-dumpxml CONT_VOL_COMP | grep "<name>" | grep CONT_VOL_COMP >/dev/null 2>&1; then
    echo "✅ Éxito: El contenedor CONT_VOL_COMP se llama CONT_VOL_COMP"
else
    error "El contenedor CONT_VOL_COMP no se llama de la forma correcta."
fi

# Comprobación de la ruta de CONT_VOL_COMP
if virsh pool-dumpxml CONT_VOL_COMP | grep "<path>" | grep /var/lib/libvirt/images/COMPARTIDO >/dev/null 2>&1; then
    echo "✅ Éxito: La ruta del CONT_VOL_COMP es /var/lib/libvirt/images/COMPARTIDO"
else
    error "El contenedor CONT_VOL_COMP no se encuentra en la ruta correcta."
fi

# Comprobación del servidor NFS de CONT_VOL_COMP
if virsh pool-dumpxml CONT_VOL_COMP | grep "host" | grep disnas2.dis.ulpgc.es >/dev/null 2>&1; then
    echo "✅ Éxito: El servidor NFS de CONT_VOL_COMP es disnas2.dis.ulpgc.es"
else
    error "El servidor NFS de CONT_VOL_COMP es incorrecto."
fi

# Comprobación de la ruta exportada por el servidor NFS de CONT_VOL_COMP
if virsh pool-dumpxml CONT_VOL_COMP | grep "dir" | grep /disnas2-itsi >/dev/null 2>&1; then
    echo "✅ Éxito: La ruta del servidor NFS es imagenes/fedora/41/isos/x86_64"
else
    error "La ruta del servidor NFS es incorrecta."
fi

# Comprobación del autoarranque de CONT_VOL_COMP
if virsh pool-info CONT_VOL_COMP | grep Autoinicio | grep no >/dev/null 2>&1; then
    echo "✅ Éxito: El autoinicio está desactivado para CONT_VOL_COMP"
else
    error "El autoinicio está activado para CONT_VOL_COMP."
fi

VOLUMEN_REAL_PC=$(virsh vol-list --pool CONT_VOL_COMP | grep $VOLUMEN | tr -s ' ' | cut -d' ' -f2)

# Comprobación de tamaño del volumen
if virsh vol-dumpxml --vol /var/lib/libvirt/images/COMPARTIDO/$VOLUMEN_REAL_PC --pool CONT_VOL_COMP | grep 1073741824 >/dev/null 2>&1; then
    echo "✅ Éxito: El tamaño de $VOLUMEN_REAL_PC es correcto"
else
    error "El tamaño de $VOLUMEN_REAL_PC es incorrecto."
fi

# Comprobación de tipo del volumen
if virsh vol-dumpxml --vol /var/lib/libvirt/images/COMPARTIDO/$VOLUMEN_REAL_PC --pool CONT_VOL_COMP | grep format | grep qcow2 >/dev/null 2>&1; then
    echo "✅ Éxito: El volumen Vol2_p3.qcow2 es de tipo qcow2"
else
    error "El volumen tipo de volumen de Vol2_p3 es incorrecto."
fi
    
# Comprobación de nombre del volumen
if virsh vol-dumpxml --vol /var/lib/libvirt/images/COMPARTIDO/$VOLUMEN_REAL_PC --pool CONT_VOL_COMP | grep name | grep $VOLUMEN >/dev/null 2>&1; then
    echo "✅ Éxito: El volumen $VOLUMEN_REAL_PC se llama de forma correcta."
else
    error "El volumen $VOLUMEN_REAL_PC no tiene el nombre requerido."
fi

#############################
# CONEXIÓN CON LA MÁQUINA
#############################
VM_IP=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {split($4, a, "/"); print a[1]}')
[ -n "$VM_IP" ] || error "No se pudo obtener la IP de la máquina virtual $VM_NAME"

ssh ${VM_USER}@${VM_IP} << 'EOF'

error() {
    echo "ERROR: $1"
    shutdown now
}


#################################
# VERIFICACIÓN VOL1_p3 (TAREA 1) PT.3
#################################

# Comprobación de que se ha creado una partición en sda
if lsblk /dev/sda --noheadings | grep "512M" >/dev/null 2>&1; then
    echo "✅ Éxito: La partición de 512M en Vol1_p3 es correcta."
else
    error "No es correcta la partición de 512M en Vol1_p3."
fi


# Comprobación de que se ha creado una particion en sda
if lsblk -f /dev/sda | grep "xfs" >/dev/null 2>&1; then
    echo "✅ Éxito: La partición de 512M en Vol1_p3 tiene un sistema de ficheros XFS."
else
    error "La partición de 512M en Vol1_p3 no tiene un sistema de ficheros XFS."
fi


# Comprobación de que el fichero test.txt esta dentro del sistema de Vol1_p3
mount /dev/sda1 /mnt/
if ls /mnt | grep "test.txt" >/dev/null 2>&1; then
    echo "✅ Éxito: El fichero text.txt se encuentra dentro del sistema de ficheros."
    umount /mnt/
else
    umount /mnt/
    error "El fichero text.txt no se encuentra dentro del sistema de ficheros."
fi

#################################
# VERIFICACIÓN PARTICIÓN ANFITRIÓN (TAREA 2) PT.2
#################################

# Comprobación de que aparece como sdb en la máquina virtual
if lsblk /dev/sdb --noheadings | grep 1G >/dev/null 2>&1; then
    echo "✅ Éxito: La partición aparece en la máquina virtual con el tamaño adecuado y como sdb."
else
    error "La partición no aparece en la máquina virtual con el tamaño adecuado y como sdb."
fi

# Comprobación de sistema de ficheros de sdb XFS
if lsblk /dev/sdb -f --noheadings | grep xfs >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros del SDB es de tipo xfs"
else
    error "El sistema de ficheros de SDB no es de tipo xfs."
fi

# Comprobar que el fichero test.txt está dentro del sistema de sdb
mount /dev/sdb /mnt/
if ls /mnt | grep "test.txt" >/dev/null 2>&1; then
    echo "✅ Éxito: El fichero text.txt se encuentra dentro del sistema de ficheros."
    umount /mnt/
else
    umount /mnt/
    error "El fichero text.txt no se encuentra dentro del sistema de ficheros."
fi


#################################
# VERIFICACIÓN VOL2_p3 (TAREA 3) PT.2
#################################


# Comprobación de sistema de ficheros de vdb XFS
if lsblk -f | grep vdb  | grep xfs >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros del vdb es de tipo xfs"
else
    error "El sistema de ficheros de vdb no es de tipo xfs."
fi

# Comprobación de montaje del vdb
if lsblk -f | grep vdb | grep /mnt/VDB >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros está montado en /mnt/VDB, Vol2_p3"
else
    error "El sistema de ficheros no está montado en /mnt/VDB, Vol2_p3."
fi


# Comprobación del fichero test.txt en /mnt/VDB
if ls /mnt/VDB | grep test.txt >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros contiene test.txt, Vol2_p3"
else
    error "El sistema de ficheros no contiene test.txt, Vol2_p3."
fi

#################################
# VERIFICACIÓN pcHOST_LQX_ANFITRIONY_Vol3_p3 (TAREA 5) PT.2
#################################

# Comprobación de sistema de ficheros de vdc XFS
if lsblk -f | grep vdc | grep xfs >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros de vdc es de tipo xfs"
else
    error "El sistema de ficheros de vdc no es de tipo xfs."
fi

# Comprobación de montaje del vdb
if lsblk -f | grep vdc | grep /mnt/VDC >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros está montado en /mnt/VDC, $VOLUMEN"
else
    error "El sistema de ficheros no está montado en /mnt/VDC, $VOLUMEN."
fi


# Comprobación del fichero test.txt en /mnt/VDC
if ls /mnt/VDC | grep test.txt >/dev/null 2>&1; then
    echo "✅ Éxito: El sistema de ficheros contiene test.txt, &VOLUMEN."
else
    error "El sistema de ficheros de vdc no contiene test.txt, &VOLUMEN."
fi

echo "Fin de comprobaciones."
EOF


virsh shutdown mvp3
sleep 10
echo "Apagando la máquina 'mvp3'"
virsh pool-destroy CONT_VOL_COMP
exit 0
}

#############################
# CONEXIÓN AL ANFITRION
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
        echo "[ERROR] No se pudo copiar el script al anfitrión remoto" //TODO Creo que aqui habia que poner error en vez de echo
        exit 1
    fi

    # Ejecutar el script en el remoto con el flag "local"
    ssh "$remote_host" "bash /tmp/$(basename "$0") local $2"
    exit 0
fi

# Si el argumento no es válido
echo "[ERROR] Argumento no reconocido: '$1'" //TODO Lo mismo que el otro TODO
echo "Uso: $0 [IP_remota] | local"
exit 1
