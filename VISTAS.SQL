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
    (EXTRACT(YEAR FROM CURRENT_DATE) - año) AS antiguedad_anios
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

