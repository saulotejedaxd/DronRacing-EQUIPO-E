function B = presupuesto_masa()
%PRESUPUESTO_MASA Plantilla de masas y posiciones de los componentes.
%
% Cada componente se registra individualmente para poder calcular:
%   - Masa total.
%   - Margen reglamentario.
%   - Centro de masa.
%
% Convención de posición:
%   Marco corporal FRD:
%       +X_B: hacia delante.
%       +Y_B: hacia la derecha.
%       +Z_B: hacia abajo.
%
% Unidades:
%   Masa: kg.
%   Posición: m.

    %% Información del presupuesto

    B.meta.nombre  = "Presupuesto inicial de masa";
    B.meta.version = "0.1";
    B.meta.estado  = "INCOMPLETO";

    %% Lista de componentes

    nombres = [
        "Chasis"
        "Motor 1"
        "Motor 2"
        "Motor 3"
        "Motor 4"
        "Hélice 1"
        "Hélice 2"
        "Hélice 3"
        "Hélice 4"
        "Controladora de vuelo"
        "ESC 4 en 1"
        "Batería"
        "Receptor de radio"
        "Cámara FPV"
        "Transmisor de video"
        "Antena de video"
        "Antena de radio"
        "Sistema de LEDs"
        "Cableado y conectores"
        "Tornillería y separadores"
        "Soportes y protecciones"
    ];

    categorias = [
        "Estructura"
        "Propulsión"
        "Propulsión"
        "Propulsión"
        "Propulsión"
        "Propulsión"
        "Propulsión"
        "Propulsión"
        "Propulsión"
        "Electrónica"
        "Electrónica"
        "Energía"
        "Comunicaciones"
        "Video"
        "Video"
        "Video"
        "Comunicaciones"
        "Iluminación"
        "Integración"
        "Integración"
        "Estructura"
    ];

    numeroComponentes = numel(nombres);

    %% Datos todavía no definidos

    masa_kg = NaN(numeroComponentes, 1);

    x_B_m = NaN(numeroComponentes, 1);
    y_B_m = NaN(numeroComponentes, 1);
    z_B_m = NaN(numeroComponentes, 1);

    % Valores permitidos posteriormente:
    % "PENDIENTE", "ESTIMADO", "CATALOGO", "MEDIDO"
    calidadDato = repmat("PENDIENTE", numeroComponentes, 1);

    % Aquí se podrá escribir modelo, fabricante, enlace, documento,
    % ensayo o cualquier origen verificable del dato.
    fuenteDato = repmat("", numeroComponentes, 1);

    %% Tabla principal

    B.componentes = table( ...
        nombres, ...
        categorias, ...
        masa_kg, ...
        x_B_m, ...
        y_B_m, ...
        z_B_m, ...
        calidadDato, ...
        fuenteDato, ...
        'VariableNames', {
            'Nombre'
            'Categoria'
            'Masa_kg'
            'x_B_m'
            'y_B_m'
            'z_B_m'
            'CalidadDato'
            'FuenteDato'
        } ...
    );

    %% Reserva de diseño

    % La reserva no se suma como componente físico.
    % Representa el margen de masa que deseamos conservar para cambios,
    % tolerancias, soldadura, adhesivos o piezas todavía no contempladas.
    B.reservaDiseno_kg = NaN;

end