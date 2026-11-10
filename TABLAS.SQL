-- 1. Tabla VEHICULO
CREATE TABLE vehiculo (
    id_vehiculo SERIAL PRIMARY KEY,
    vin VARCHAR(50) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    año INT NOT NULL,
    precio_lista NUMERIC(12, 2) NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('Disponible', 'Reservado', 'Vendido'))
);

-- 2. Tabla CLIENTE
CREATE TABLE cliente (
    id_cliente SERIAL PRIMARY KEY,
    documento_identidad VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    ciudad VARCHAR(50)
);

-- 3. Tabla EMPLEADO
CREATE TABLE empleado (
    id_empleado SERIAL PRIMARY KEY,
    codigo_empleado VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('Vendedor', 'Mecánico')),
    comision_pct NUMERIC(5, 2),
    fecha_ingreso DATE NOT NULL
);

-- 4. Tabla VENTA
CREATE TABLE venta (
    id_venta SERIAL PRIMARY KEY,
    numero_factura VARCHAR(50) NOT NULL UNIQUE,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal NUMERIC(12, 2) NOT NULL,
    descuento NUMERIC(12, 2) DEFAULT 0,
    monto_total NUMERIC(12, 2) NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    id_cliente INT NOT NULL,
    id_empleado INT NOT NULL,
    CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_venta_empleado FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);

-- 5. Tabla DETALLE_VENTA
CREATE TABLE detalle_venta (
    id_detalle SERIAL PRIMARY KEY,
    id_venta INT NOT NULL,
    id_vehiculo INT NOT NULL UNIQUE, -- Restricción UNIQUE para asegurar que cada vehículo solo figure en una venta activa
    precio_final_pactado NUMERIC(12, 2) NOT NULL,
    garantia_meses INT DEFAULT 0,
    CONSTRAINT fk_detalle_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
);

-- 6. Tabla SERVICIO_POSTVENTA
CREATE TABLE servicio_postventa (
    id_servicio SERIAL PRIMARY KEY,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descripcion TEXT NOT NULL,
    costo_repuestos NUMERIC(12, 2) DEFAULT 0,
    costo_mano_obra NUMERIC(12, 2) DEFAULT 0,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('Completado', 'Pendiente')),
    id_vehiculo INT NOT NULL,
    id_empleado INT NOT NULL,
    CONSTRAINT fk_servicio_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo),
    CONSTRAINT fk_servicio_empleado FOREIGN KEY (id_empleado) REFERENCES empleado(id_empleado)
);
