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
