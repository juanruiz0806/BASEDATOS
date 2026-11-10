--CASO DE PRUEBA 1: ÉXITO en OPERACIÓN VÁLIDA

-- Crear Venta #11 de prueba
INSERT INTO venta (numero_factura, subtotal, descuento, monto_total, metodo_pago, id_cliente, id_empleado)
VALUES ('F-TEST-2026', 0.00, 500.00, 0.00, 'Tarjeta de Crédito', 1, 1);

-- 1. Insertar Vehículo #11 'Disponible'
INSERT INTO vehiculo (vin, marca, modelo, anio, precio_lista, estado)
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

--CASO DE PRUEBA 3|: RECHAZO POR VEHÍCULO NO DISPONIBLE
--Se utiliza el registro ya existente con id_vehiculo=2 , que ya fue vendido en el paso anterior. Se intenta registrar una venta con este vehículo, lo que debe generar un error y no permitir la inserción.

-- Inserción infractora (Intentar vender un vehículo que ya fue vendido en los 10 registros iniciales)
INSERT INTO detalle_venta (id_venta, id_vehiculo, precio_final_pactado, garantia_meses)
VALUES (11, 2, 28000.00, 12);

-- #SALIDA ESPERADA
--ERROR:  No se puede procesar la venta: El vehículo con ID 2 no se encuentra en estado "Disponible" (Estado actual: Vendido).
--CONTEXT:  PL/pgSQL function fn_actualizar_estado_vehiculo() line 13 at RAISE


