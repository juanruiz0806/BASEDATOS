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
('VIN10000000000010', 'Subaru', 'Forester', 2024, 36000.00, 'Disponible'); 


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

