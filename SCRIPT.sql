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

-- =============================================================================
-- 1. Vista: V_VehiculosDisponibles
-- Propósito: Muestra marca, modelo, año, precio de lista y antigüedad calculada
--            únicamente para vehículos cuyo estado sea 'Disponible'.
-- =============================================================================
CREATE OR REPLACE VIEW v_vehiculosdisponibles AS
SELECT 
    id_vehiculo,
    vin,
    marca,
    modelo,
    año,
    precio_lista,
    (EXTRACT(YEAR FROM CURRENT_DATE) - año) AS antiguedad_años
FROM 
    vehiculo
WHERE 
    estado = 'Disponible';


-- =============================================================================
-- 2. Vista: V_RendimientoVendedores
-- Propósito: Resume por cada vendedor el total de vehículos vendidos, el monto
--            acumulado de ventas y la comisión neta ganada en el mes en curso.
-- =============================================================================
CREATE OR REPLACE VIEW v_rendimientovendedores AS
SELECT 
    e.id_empleado,
    e.codigo_empleado,
    e.nombre AS vendedor,
    COUNT(dv.id_detalle) AS total_vehiculos_vendidos,
    COALESCE(SUM(v.monto_total), 0) AS monto_total_transaccionado,
    COALESCE(SUM(v.monto_total * (e.comision_pct / 100.0)), 0) AS comision_neta_acumulada
FROM 
    empleado e
JOIN 
    venta v ON e.id_empleado = v.id_empleado
JOIN 
    detalle_venta dv ON v.id_venta = dv.id_venta
WHERE 
    e.rol = 'Vendedor'
    AND DATE_TRUNC('month', v.fecha_venta) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY 
    e.id_empleado, e.codigo_empleado, e.nombre;


-- =============================================================================
-- 3. Vista: V_HojaDeVidaVehiculo
-- Propósito: Consolida el historial de cada vehículo: cliente/propietario actual,
--            fecha de compra y el historial de mantenimientos postventa con su
--            respectivo mecánico responsable.
-- =============================================================================
CREATE OR REPLACE VIEW v_hojadevidavehiculo AS
SELECT 
    v.id_vehiculo,
    v.vin,
    v.marca,
    v.modelo,
    v.año,
    -- Datos del propietario y la compra
    c.id_cliente,
    CONCAT(c.nombres, ' ', c.apellidos) AS propietario_actual,
    vt.fecha_venta AS fecha_compra,
    -- Datos del servicio posventa y mecánico
    sp.id_servicio,
    sp.fecha AS fecha_servicio,
    sp.descripcion AS detalle_servicio,
    (sp.costo_repuestos + sp.costo_mano_obra) AS costo_total_servicio,
    sp.estado AS estado_servicio,
    e_mecanico.nombre AS mecanico_responsable
FROM 
    vehiculo v
LEFT JOIN 
    detalle_venta dv ON v.id_vehiculo = dv.id_vehiculo
LEFT JOIN 
    venta vt ON dv.id_venta = vt.id_venta
LEFT JOIN 
    cliente c ON vt.id_cliente = c.id_cliente
LEFT JOIN 
    servicio_postventa sp ON v.id_vehiculo = sp.id_vehiculo
LEFT JOIN 
    empleado e_mecanico ON sp.id_empleado = e_mecanico.id_empleado AND e_mecanico.rol = 'Mecánico'
ORDER BY 
    v.id_vehiculo, sp.fecha DESC;


-- Función del Trigger 1
CREATE OR REPLACE FUNCTION fn_actualizar_estado_vehiculo()
RETURNS TRIGGER AS $$
DECLARE
    v_estado VARCHAR(20);
BEGIN
    -- Obtener el estado actual del vehículo
    SELECT estado INTO v_estado
    FROM vehiculo
    WHERE id_vehiculo = NEW.id_vehiculo;

    -- Validar si el vehículo está disponible
    IF v_estado <> 'Disponible' OR v_estado IS NULL THEN
        RAISE EXCEPTION 'No se puede procesar la venta: El vehículo con ID % no se encuentra en estado "Disponible" (Estado actual: %).', 
                        NEW.id_vehiculo, COALESCE(v_estado, 'No encontrado');
    END IF;

    -- Actualizar el estado a 'Vendido'
    UPDATE vehiculo
    SET estado = 'Vendido'
    WHERE id_vehiculo = NEW.id_vehiculo;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Definición del Trigger 1
CREATE OR REPLACE TRIGGER tr_actualizarestadovehiculo
AFTER INSERT ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_estado_vehiculo();

-- Función del Trigger 2
CREATE OR REPLACE FUNCTION fn_actualizar_total_venta()
RETURNS TRIGGER AS $$
DECLARE
    v_id_venta INT;
    v_nuevo_subtotal NUMERIC(12, 2);
BEGIN
    -- Identificar el id_venta según la operación realizada
    IF (TG_OP = 'DELETE') THEN
        v_id_venta := OLD.id_venta;
    ELSE
        v_id_venta := NEW.id_venta;
    END IF;

    -- Calcular la suma de todos los detalles asociados a la venta
    SELECT COALESCE(SUM(precio_final_pactado), 0)
    INTO v_nuevo_subtotal
    FROM detalle_venta
    WHERE id_venta = v_id_venta;

    -- Actualizar subtotal y monto_total (subtotal - descuento) en la tabla VENTA
    UPDATE venta
    SET subtotal = v_nuevo_subtotal,
        monto_total = v_nuevo_subtotal - descuento
    WHERE id_venta = v_id_venta;

    RETURN NULL; -- Al ser un trigger AFTER por fila, retornar NULL es lo adecuado
END;
$$ LANGUAGE plpgsql;

-- Definición del Trigger 2
CREATE OR REPLACE TRIGGER tr_actualizartotalventa
AFTER INSERT OR UPDATE OR DELETE ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_total_venta();

-- Función del Trigger 3
CREATE OR REPLACE FUNCTION fn_validar_precio_minimo()
RETURNS TRIGGER AS $$
DECLARE
    v_precio_lista NUMERIC(12, 2);
    v_precio_minimo NUMERIC(12, 2);
BEGIN
    -- Obtener el precio de lista del vehículo
    SELECT precio_lista INTO v_precio_lista
    FROM vehiculo
    WHERE id_vehiculo = NEW.id_vehiculo;

    IF v_precio_lista IS NULL THEN
        RAISE EXCEPTION 'El vehículo con ID % no existe.', NEW.id_vehiculo;
    END IF;

    -- Calcular el 85% del precio de lista
    v_precio_minimo := v_precio_lista * 0.85;

    -- Validar si el precio pactado es inferior al mínimo permitido
    IF NEW.precio_final_pactado < v_precio_minimo THEN
        RAISE EXCEPTION 'Precio no permitido: El precio final pactado ($%) es inferior al 85%% del precio de lista ($%). El mínimo permitido es $%.', 
                        NEW.precio_final_pactado, v_precio_lista, v_precio_minimo;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Definición del Trigger 3
CREATE OR REPLACE TRIGGER tr_validarpreciominimo
BEFORE INSERT ON detalle_venta
FOR EACH ROW
EXECUTE FUNCTION fn_validar_precio_minimo();

-- =============================================================================
-- 1. POBLAR TABLA: VEHICULO (10 registros)
-- Precios de lista entre $15,000 y $45,000
-- =============================================================================
INSERT INTO vehiculo (vin, marca, modelo, año, precio_lista, estado) VALUES
('VIN10000000000001', 'Toyota', 'Corolla', 2024, 22000.00, 'Disponible'),
('VIN10000000000002', 'Mazda', 'CX-5', 2023, 31000.00, 'Disponible'),
('VIN10000000000003', 'Honda', 'Civic', 2024, 25000.00, 'Disponible'),
('VIN10000000000004', 'Chevrolet', 'Onix', 2022, 16000.00, 'Disponible'),
('VIN10000000000005', 'Ford', 'Ranger', 2023, 42000.00, 'Disponible'),
('VIN10000000000006', 'Nissan', 'Sentra', 2024, 23000.00, 'Disponible'),
('VIN10000000000007', 'Volkswagen', 'Jetta', 2023, 27000.00, 'Disponible'),
('VIN10000000000008', 'Kia', 'Sportage', 2024, 34000.00, 'Disponible'),
('VIN10000000000009', 'Hyundai', 'Tucson', 2023, 33000.00, 'Disponible'),
('VIN10000000000010', 'Subaru', 'Forester', 2024, 36000.00, 'Disponible'); -- Uno pre-vendido para pruebas


-- =============================================================================
-- 2. POBLAR TABLA: CLIENTE (10 registros)
-- =============================================================================
INSERT INTO cliente (documento_identidad, nombres, apellidos, telefono, email, ciudad) VALUES
('CC101001', 'Carlos', 'Mendoza', '3001112233', 'carlos.mendoza@email.com', 'Bogotá'),
('CC101002', 'Ana', 'Gómez', '3112223344', 'ana.gomez@email.com', 'Medellín'),
('CC101003', 'Luis', 'Rodríguez', '3203334455', 'luis.rodriguez@email.com', 'Cali'),
('CC101004', 'Sofía', 'Martínez', '3004445566', 'sofia.martinez@email.com', 'Barranquilla'),
('CC101005', 'Diego', 'Hernández', '3155556677', 'diego.hernandez@email.com', 'Bucaramanga'),
('CC101006', 'María', 'López', '3186667788', 'maria.lopez@email.com', 'Bogotá'),
('CC101007', 'Jorge', 'Ramírez', '3177778899', 'jorge.ramirez@email.com', 'Pereira'),
('CC101008', 'Valeria', 'Torres', '3018889900', 'valeria.torres@email.com', 'Manizales'),
('CC101009', 'Andrés', 'Castro', '3199990011', 'andres.castro@email.com', 'Cartagena'),
('CC101010', 'Camila', 'Vargas', '3120001122', 'camila.vargas@email.com', 'Santa Marta');


-- =============================================================================
-- 3. POBLAR TABLA: EMPLEADO (10 registros: 6 Vendedores, 4 Mecánicos)
-- =============================================================================
INSERT INTO empleado (codigo_empleado, nombre, rol, comision_pct, fecha_ingreso) VALUES
('EMP-V01', 'Laura Gómez', 'Vendedor', 3.50, '2023-01-15'),
('EMP-V02', 'Ricardo Silva', 'Vendedor', 4.00, '2022-05-10'),
('EMP-V03', 'Patricia Ortiz', 'Vendedor', 3.00, '2024-02-01'),
('EMP-V04', 'Gabriel Ríos', 'Vendedor', 3.50, '2023-08-20'),
('EMP-V05', 'Elena Morales', 'Vendedor', 4.50, '2021-11-12'),
('EMP-V06', 'Fernando Peña', 'Vendedor', 3.00, '2024-06-01'),
('EMP-M01', 'Mario Benítez', 'Mecánico', NULL, '2020-03-15'),
('EMP-M02', 'Oscar Gutiérrez', 'Mecánico', NULL, '2021-07-01'),
('EMP-M03', 'Javier Navarro', 'Mecánico', NULL, '2022-09-18'),
('EMP-M04', 'Santiago Roldán', 'Mecánico', NULL, '2023-04-10');


-- =============================================================================
-- 4. POBLAR TABLA: VENTA (10 registros cabecera)
-- Subtotal y monto_total inician en 0 y serán recalculados por los triggers al detallar
-- =============================================================================
INSERT INTO venta (numero_factura, fecha_venta, subtotal, descuento, monto_total, metodo_pago, id_cliente, id_empleado) VALUES
('F-2026-001', '2026-11-01 10:00:00', 0.00, 500.00, 0.00, 'Tarjeta de Crédito', 1, 1),
('F-2026-002', '2026-11-02 11:30:00', 0.00, 0.00,   0.00, 'Transferencia',      2, 2),
('F-2026-003', '2026-11-03 14:15:00', 0.00, 1000.00, 0.00, 'Financiamiento',   3, 3),
('F-2026-004', '2026-11-04 16:45:00', 0.00, 300.00,  0.00, 'Efectivo',          4, 4),
('F-2026-005', '2026-11-05 09:20:00', 0.00, 0.00,   0.00, 'Tarjeta de Crédito', 5, 5),
('F-2026-006', '2026-11-06 12:00:00', 0.00, 800.00,  0.00, 'Transferencia',      6, 1),
('F-2026-007', '2026-11-07 15:30:00', 0.00, 0.00,   0.00, 'Financiamiento',   7, 2),
('F-2026-008', '2026-11-08 11:10:00', 0.00, 400.00,  0.00, 'Efectivo',          8, 3),
('F-2026-009', '2026-11-09 13:50:00', 0.00, 1200.00, 0.00, 'Transferencia',      9, 4),
('F-2026-010', '2026-11-09 17:00:00', 0.00, 0.00,   0.00, 'Tarjeta de Crédito', 10, 5);


-- =============================================================================
-- 5. POBLAR TABLA: DETALLE_VENTA (10 registros)
-- Al insertar aquí, TR_ValidarPrecioMinimo valida el 85%, TR_ActualizarEstadoVehiculo 
-- cambia el vehículo a 'Vendido' y TR_ActualizarTotalVenta calcula subtotal y total.
-- =============================================================================
INSERT INTO detalle_venta (id_venta, id_vehiculo, precio_final_pactado, garantia_meses) VALUES
(1, 1, 20500.00, 12), -- Toyota Corolla ($22,000 list) -> Min $18,700
(2, 2, 29000.00, 24), -- Mazda CX-5 ($31,000 list) -> Min $26,350
(3, 3, 23500.00, 12), -- Honda Civic ($25,000 list) -> Min $21,250
(4, 4, 15000.00, 12), -- Chevrolet Onix ($16,000 list) -> Min $13,600
(5, 5, 39500.00, 36), -- Ford Ranger ($42,000 list) -> Min $35,700
(6, 6, 21500.00, 12), -- Nissan Sentra ($23,000 list) -> Min $19,550
(7, 7, 25000.00, 24), -- VW Jetta ($27,000 list) -> Min $22,950
(8, 8, 31500.00, 12), -- Kia Sportage ($34,000 list) -> Min $28,900
(9, 9, 30000.00, 24), -- Hyundai Tucson ($33,000 list) -> Min $28,050
(10, 10, 34000.00, 36);-- Subaru Forester ($36,000 list) -> Min $30,600


-- =============================================================================
-- 6. POBLAR TABLA: SERVICIO_POSTVENTA (10 registros)
-- Asociados a vehículos vendidos y mecánicos (id_empleado 7 a 10)
-- =============================================================================
INSERT INTO servicio_postventa (fecha, descripcion, costo_repuestos, costo_mano_obra, estado, id_vehiculo, id_empleado) VALUES
('2026-11-02 08:00:00', 'Mantenimiento de los 5,000 KM', 50.00, 80.00, 'Completado', 1, 7),
('2026-11-03 09:30:00', 'Cambio de aceite y filtros', 40.00, 60.00, 'Completado', 2, 8),
('2026-11-04 10:15:00', 'Alineación y balanceo', 0.00, 90.00, 'Completado', 3, 9),
('2026-11-05 14:00:00', 'Revisión sistema de frenos', 120.00, 100.00, 'Completado', 4, 10),
('2026-11-06 11:45:00', 'Instalación de película de seguridad', 150.00, 80.00, 'Completado', 5, 7),
('2026-11-07 15:10:00', 'Diagnóstico escáner motor', 0.00, 70.00, 'Completado', 6, 8),
('2026-11-08 08:30:00', 'Cambio de pastillas delanteras', 110.00, 75.00, 'Pendiente',  7, 9),
('2026-11-08 13:20:00', 'Mantenimiento preventivo 10K', 95.00, 110.00, 'Pendiente',  8, 10),
('2026-11-09 10:00:00', 'Reemplazo de batería', 180.00, 40.00, 'Completado', 9, 7),
('2026-11-09 16:30:00', 'Revisión suspensión trasera', 85.00, 130.00, 'Pendiente',  10, 8);

--CASO DE PRUEBA 1: ÉXITO en OPERACIÓN VÁLIDA

-- Crear Venta #11 de prueba
INSERT INTO venta (numero_factura, subtotal, descuento, monto_total, metodo_pago, id_cliente, id_empleado)
VALUES ('F-TEST-2026', 0.00, 500.00, 0.00, 'Tarjeta de Crédito', 1, 1);

-- 1. Insertar Vehículo #11 'Disponible'
INSERT INTO vehiculo (vin, marca, modelo, año, precio_lista, estado)
VALUES ('VIN-TEST-SUCCESS', 'BMW', 'Series 3', 2024, 30000.00, 'Disponible');

-- 2. Ejecutar inserción válida en DETALLE_VENTA
--    Precio pactado ($27,000.00) es mayor al 85% ($25,500.00) y el auto está 'Disponible'.
INSERT INTO detalle_venta (id_venta, id_vehiculo, precio_final_pactado, garantia_meses)
VALUES (11, 11, 27000.00, 24);

-- 3. Verificación de los Triggers:
-- a) El vehículo 11 pasó a 'Vendido' (TR_ActualizarEstadoVehiculo)
SELECT id_vehiculo, vin, marca, estado 
FROM vehiculo 
WHERE id_vehiculo = 11;

-- b) La cabecera Venta #11 actualizó Subtotal ($27,000) y Total ($26,500 tras descuento de $500) (TR_ActualizarTotalVenta)
SELECT id_venta, numero_factura, subtotal, descuento, monto_total 
FROM venta 
WHERE id_venta = 11;

--CASO DE PRUEBA 2: RECHAZO POR VIOLACIÓN DE PRECIO MÍNIMO
--> Se crea el id_vehiculo=12 en estado ''disponible  con precio de 40.000.00. El precio mínimo permitido es 34.000.00 (85% de 40.000.00). Se intenta registrar la venta con precio pactado de 33.000.00, lo que debe generar un error y no permitir la inserción.

-- 1. Crear Vehículo #12 'Disponible'
INSERT INTO vehiculo (vin, marca, modelo, anio, precio_lista, estado)
VALUES ('VIN-TEST-FAIL-PRICE', 'Audi', 'A4', 2024, 40000.00, 'Disponible');

-- 2. Inserción infractora (Intentar vender por debajo del 85%)
INSERT INTO detalle_venta (id_venta, id_vehiculo, precio_final_pactado, garantia_meses)
VALUES (11, 12, 30000.00, 12);
-- #SALIDA ESPERADA 
--ERROR:  Precio no permitido: El precio final pactado ($30000.00) es inferior al 85% del precio de lista ($40000.00). El mínimo permitido es $34000.00.
--CONTEXT:  PL/pgSQL function fn_validar_precio_minimo() line 19 at RAISE

--CASO DE PRUEBA 3: RECHAZO POR VEHICULO NO DISPONIBLE PARA VENTA ("RESERVADO")

-- 1. Insertar un vehículo nuevo en estado 'Reservado' (para que no exista aún en detalle_venta)
INSERT INTO vehiculo (vin, marca, modelo, año, precio_lista, estado)
VALUES ('VIN-TEST-RESERVADO', 'Mazda', 'CX-30', 2024, 28000.00, 'Reservado');

-- 2. Intentar vender el vehículo recién creado (Debe fallar activando el TRIGGER)
INSERT INTO detalle_venta (id_venta, id_vehiculo, precio_final_pactado, garantia_meses)
VALUES (11, (SELECT id_vehiculo FROM vehiculo WHERE vin = 'VIN-TEST-RESERVADO'), 26000.00, 12);

-- #SALIDA ESPERADA
--ERROR:  No se puede procesar la venta: El vehículo con ID 2 no se encuentra en estado "Disponible" (Estado actual: Vendido).
--CONTEXT:  PL/pgSQL function fn_actualizar_estado_vehiculo() line 13 at RAISE


