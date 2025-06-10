# Verificador de Práctica 3: Gestión de Volúmenes en Libvirt

Este script Bash permite verificar de forma automática la configuración de volúmenes y almacenamiento en entornos que utilizan **libvirt** y **máquinas virtuales (KVM/QEMU)**, desarrollado específicamente para la *Práctica 3: Recursos de almacenamiento virtual* de la asignatura **Virtualización y Procesamiento Distribuido** de la **Universidad de Las Palmas de Gran Canaria**. 

El trabajo se ha realizado para la *Práctica 8: Desarrollo de scripts de validación de las prácticas de la asignatura*.

El script puede ejecutarse tanto en el anfitrión local como de forma remota sobre otro host con conexión SSH.

---

##  Requisitos

- Linux con `bash`, `virsh`, `ssh`, `scp`
- Una máquina virtual llamada `mvp3` definida en `libvirt`
- Acceso root o con permisos suficientes para gestionar volúmenes y pools
- Configuración SSH sin contraseña para conexiones remotas

---

## Estructura esperada

El script verifica los siguientes componentes:

1. Volúmenes en el pool `default`:
   - `Vol1_p3` (formato raw, 1GB)

2. Pools de almacenamiento:
   - `CONT_VOL_COMP` (NFS)
   - `CONT_ISOS_COMP` (NFS)
   - `Contenedor_Particion`

3. Configuración de la máquina virtual `mvp3`

---

## ¿Qué verifica este script?

### En el anfitrión

1. **Vol1_p3 (Tarea 1)**:
   - Existencia del volumen
   - Formato RAW correcto
   - Tamaño de 1GB
   - Conexión correcta al bus SATA de la VM

2. **Partición del anfitrión (Tarea 2)**:
   - Conexión correcta a la máquina virtual
   - Configuración adecuada

3. **Vol2_p3 (Tarea 3)**:
   - Nombre correcto
   - Formato qcow2
   - Tamaño de 1GB
   - Ubicación en el pool Contenedor_Particion

4. **CONT_ISOS_COMP (Tarea 4)**:
   - Nombre correcto
   - Ruta adecuada
   - Configuración NFS correcta (servidor y ruta)
   - Autoarranque desactivado

5. **CONT_VOL_COMP (Tarea 5)**:
   - Nombre correcto
   - Ruta adecuada
   - Configuración NFS correcta
   - Volumen compartido con nombre específico según host
   - Autoarranque desactivado

### Dentro de la máquina virtual (via SSH)

1. **Vol1_p3**:
   - Partición de 512MB
   - Sistema de ficheros XFS
   - Presencia de archivo test.txt

2. **Partición del anfitrión**:
   - Identificación como /dev/sdb
   - Sistema XFS
   - Archivo test.txt presente

3. **Vol2_p3**:
   - Sistema XFS
   - Montaje en /mnt/VDB
   - Archivo test.txt presente

4. **Volumen compartido (Tarea 5)**:
   - Sistema XFS
   - Montaje en /mnt/VDC
   - Archivo test.txt presente

---

## Uso

### 1. En el anfitrión local

```bash
./verificar_p3.sh local [grado]
```
Donde `[grado]` debe ser:
- `1` para GII
- `2` para GCID

---

### 2. En un anfitrión remoto

```bash
./verificar_p3.sh [IP] [grado]
```
Ejemplo:
```bash
./verificar_p3.sh 192.168.1.100 1
```

> Requiere acceso SSH sin contraseña (configuración previa con claves públicas, tanto el anfitrión como su máquina).

---

## Manejo de errores

El script detecta y reporta automáticamente:
- Volúmenes faltantes o mal configurados
- Pools de almacenamiento incorrectos
- Problemas de montaje en la VM
- Archivos faltantes en los sistemas de ficheros
- Problemas de conectividad SSH
- Configuraciones de tamaño o formato incorrectas

---

## Limpieza automática

Al finalizar, el script:
1. Apaga la máquina virtual `mvp3`
2. Desactiva el pool `CONT_VOL_COMP`
3. Sale con código 0 si todo es correcto, 1 si hay errores

---

## Autores

- **[@002avid](https://github.com/002avid)** – Desarrollo y verificación del script  
- **[@Putrici0](https://github.com/Putrici0)** – Desarrollo y verificación del script  
- **ULPGC/VPD** – Práctica de Virtualización y Procesamiento Distribuido
