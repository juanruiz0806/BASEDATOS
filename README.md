# 🚗 AutoPremierMotos — Sistema de Gestión de Concesionario

[![Database](https://img.shields.io/badge/Database-PostgreSQL%2014%2B-blue)](https://www.postgresql.org/)
[![GUI](https://img.shields.io/badge/GUI-pgAdmin%204-orange)](https://www.pgadmin.org/)
[![Status](https://img.shields.io/badge/Status-Completed-brightgreen)]()

**AutoPremierMotos** es un sistema de base de datos relacional desarrollado en PostgreSQL para gestionar la operativa comercial y el servicio posventa de un concesionario vehicular. El modelo cubre desde el control de inventario y personal hasta la emisión de ventas con validación de reglas de negocio en tiempo real mediante *triggers*.

---

## 📌 Tabla de Contenidos
- [Arquitectura de la Base de Datos](#-arquitectura-de-la-base-de-datos)
- [Reglas de Negocio e Integridad](#-reglas-de-negocio-e-integridad)
- [Estructura del Esquema (Tablas)](#-estructura-del-esquema-tablas)
- [Vistas de Negocio (Views)](#-vistas-de-negocio-views)
- [Lógica Activa (Triggers)](#-lógica-activa-triggers)
- [Instalación y Uso](#-instalación-y-uso)

---

## 📐 Arquitectura de la Base de Datos

El diseño cumple con la **Tercera Forma Normal (3FN)** para garantizar la consistencia de la información, eliminar redundancias y prevenir anomalías de inserción, actualización y borrado.

### Modelo Entidad-Relación (E-R)
```text
+------------------+       +------------------+       +-----------------------+
|     CLIENTE      |       |      VENTA       |       |     DETALLE_VENTA     |
+------------------+       +------------------+       +-----------------------+
| PK  id_cliente   |<------| PK  id_venta     |<------| PK  id_detalle        |
|     doc_identid. |       |     fecha_venta  |       | FK1 id_venta          |
|     nombres      |       |     subtotal     |       | FK2 id_vehiculo (UQ)  |
|     apellidos    |       |     descuento    |       |     precio_pactado    |
|     telefono     |       |     monto_total  |       |     garantia_meses    |
|     email        |       | FK1 id_cliente   |       +-----------------------+
|     ciudad       |       | FK2 id_empleado  |                   |
+------------------+       +------------------+                   |
                                    ^                             |
+------------------+                |                             |
|     EMPLEADO     |----------------+                             |
+------------------+                |                             |
| PK  id_empleado  |<---------------+                             v
|     codigo_emp   |                |                 +-----------------------+
|     nombre       |                |                 |       VEHICULO        |
|     rol          |                |                 +-----------------------+
|     comision_pct |                +-----------------| PK  id_vehiculo       |
|     fecha_ingres |                                  |     vin (UQ)          |
+------------------+                                  |     marca / modelo    |
         ^                                            |     anio / precio_list|
         |                                            |     estado            |
+------------------------+                            +-----------------------+
|   SERVICIO_POSTVENTA   |                                        ^
+------------------------+                                        |
| PK  id_servicio        |                                        |
|     fecha / descrip.   |                                        |
|     costo_rep/mano_ob  |                                        |
|     estado             |                                        |
| FK1 id_vehiculo        |----------------------------------------+
| FK2 id_empleado (Mec.) |
+------------------------+

