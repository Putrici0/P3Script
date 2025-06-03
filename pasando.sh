#################################
# VERIFICACIÓN VOL2_p3 (TAREA 3)
#################################

# Comprobacion de nombre de vol2_p3
if virsh vol-dumpxml --vol /var/lib/libvirt/Pool_Particion/Vol2_p3.qcow2 | grep name | cut -c 9-21 | grep Vol2_p3.qcow2; then
    echo "✅ Éxito: El volumen Vol2_p3.qcow2 se llama Vol2_p3.qcow2"
else
    error "El volumen Vol2_p3 no se llama de la forma correcta."
fi
    
# Comprobacion de tipo de volumen de vol2_p3
if virsh vol-dumpxml --vol /var/lib/libvirt/Pool_Particion/Vol2_p3.qcow2 | grep format | cut -c 19-23 | grep qcow2; then
    echo "✅ Éxito: El volumen Vol2_p3.qcow2 es de tipo qcow2"
else
    error "El volumen tipo de volumen de Vol2_p3 es incorrecto."
fi
    
# Comprobacion del tamaño del volumen vol2_p3
if virsh vol-dumpxml --vol /var/lib/libvirt/Pool_Particion/Vol2_p3.qcow2 | grep capacity | cut -c 26-35 | grep 1073741824; then
    echo "✅ Éxito: El volumen Vol2_p3.qcow2 es de exactamente 1GB"
else
    error "El volumen tamaño de Vol2_p3 es incorrecto."
fi
    
#############################
# VERIFICACIÓN DEL SISTEMA DE FICHEROS EN MVP3
#############################
echo "== Comprobación del sistema de ficheros en mvp3 =="

VM_IP=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {split($4, a, "/"); print a[1]}')
[ -n "$VM_IP" ] || error "No se pudo obtener la IP de la máquina virtual $VM_NAME"
ssh ${VM_USER}@${VM_IP} << 'EOF'

# Función para mostrar errores
error() {
    echo "ERROR: $1"
    virsh shutdown mvp3
    exit 1
}

if lsblk -f | grep vdb | cut -c 17-19 | grep xfs; then
    echo "✅ Éxito: El sistema de ficheros de vdb es de tipo xfs"
else
    error "El sistema de ficheros de vdb no es de tipo xfs."
fi
    
if ls /mnt/VDB | grep test.txt; then
    echo "✅ Éxito: El sistema de ficheros contiene test.txt"
else
    error "El sistema de ficheros no contiene test.txt."
fi
    
if lsblk -f | grep vdb | cut -c 98-105 | grep /mnt/VDB; then
    echo "✅ Éxito: El sistema de ficheros está montado en /mnt/VDB"
else
    error "El sistema de ficheros no está montado en /mnt/VDB."
fi

echo "Fin de comprobaciones."
EOF
