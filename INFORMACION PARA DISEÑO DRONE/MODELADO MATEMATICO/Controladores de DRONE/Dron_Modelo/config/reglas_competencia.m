function R = reglas_competencia()
%REGLAS_COMPETENCIA Restricciones del reglamento FAI proporcionado.
%
% Todas las magnitudes se expresan en unidades SI.

    %% Identificación

    R.meta.documento = ...
        "2025 World Games Drone Racing Sporting Rules";

    R.meta.fechaDocumento = datetime(2025, 6, 1);
    R.meta.claseBase = "FAI F9U";

    %% Masa

    % Incluye batería y todos los dispositivos necesarios para vuelo.
    R.masa.maxima = 1.000;                         % kg

    %% Geometría

    % Todos los ejes de los motores deben encontrarse dentro
    % de un círculo con este diámetro.
    R.geometria.diametroCirculoMotoresMax = 0.330; % m

    % Para una configuración X simétrica centrada.
    R.geometria.distanciaCentroMotorMax = ...
        R.geometria.diametroCirculoMotoresMax / 2; % m

    %% Motores

    R.motores.numeroProyecto = 4;
    R.motores.soloElectricos = true;
    R.motores.inclinacionMax = deg2rad(15);         % rad

    %% Batería

    R.bateria.numeroCeldasSerieMax = 6;
    R.bateria.voltajeCeldaMax = 4.25;               % V
    R.bateria.voltaje4SMax = 17.0;                  % V
    R.bateria.voltaje6SMax = 25.5;                  % V

    %% Hélices

    R.helices.diametroMax = 6 * 0.0254;             % m
    R.helices.metalCompletoPermitido = false;

    %% Operación

    R.operacion.duracionCarreraMax = 3 * 60;        % s

    % Este valor determina la interrupción de la competencia;
    % no representa por sí mismo la fuerza aplicada al dron.
    R.operacion.velocidadVientoInterrupcion = 9;    % m/s
    R.operacion.tiempoVientoInterrupcion = 60;      % s

    %% Seguridad

    R.seguridad.failSafeObligatorio = true;
    R.seguridad.failSafeDetieneMotores = true;

    %% Automatización permitida durante competencia

    R.control.maniobrasPreprogramadasPermitidas = false;
    R.control.posicionAutomaticaPermitida = false;
    R.control.alturaAutomaticaPermitida = false;

    %% Elementos que afectan masa y consumo

    R.led.numeroRGBMin = 32;
    R.led.longitudTiraMin = 0.280;                  % m

    R.radio.potenciaMax = 0.100;                    % W
    R.video.potenciaTransmisorMax = 0.025;          % W

end