function C = parametros_control_traslacional(P, Cactitud)
%PARAMETROS_CONTROL_TRASLACIONAL
% Define los parametros del control de posicion, velocidad y altura.
%
% Este controlador funcionara como lazo exterior del controlador
% de actitud:
%
%   Posicion / velocidad deseada
%               ↓
%   Controlador traslacional
%               ↓
%   Roll, pitch y empuje deseados
%               ↓
%   Controlador de actitud
%               ↓
%   Mezclador y motores
%
% El archivo concentra todos los valores que posteriormente
% pueden ajustarse para otro dron sin modificar las funciones
% internas del controlador.
%
% Entradas:
%
%   P
%       Parametros fisicos del dron.
%
%   Cactitud
%       Parametros del controlador de actitud.
%       Es opcional, pero se recomienda proporcionarlo para que
%       los limites de inclinacion sean coherentes.
%
% Salida:
%
%   C
%       Estructura con parametros del control traslacional.

    %% ============================================================
    % VALIDAR ENTRADAS
    % =============================================================

    if nargin < 1

        error( ...
            'parametros_control_traslacional:FaltaP', ...
            'Debes proporcionar los parametros fisicos P.' ...
        );

    end

    if nargin < 2

        Cactitud = [];

    end

    if ~isfield(P, 'cuerpo') || ...
            ~isfield(P.cuerpo, 'masa')

        error( ...
            'parametros_control_traslacional:FaltaMasa', ...
            'P debe contener P.cuerpo.masa.' ...
        );

    end

    if ~isfield(P, 'entorno') || ...
            ~isfield(P.entorno, 'g')

        error( ...
            'parametros_control_traslacional:FaltaGravedad', ...
            'P debe contener P.entorno.g.' ...
        );

    end

    if ~isfield(P, 'motores') || ...
            ~isfield(P.motores, 'numero') || ...
            ~isfield(P.motores, 'empujeMinimo') || ...
            ~isfield(P.motores, 'empujeMaximo')

        error( ...
            'parametros_control_traslacional:FaltanMotores', ...
            ['P debe contener numero de motores y limites ' ...
             'de empuje.'] ...
        );

    end

    masa_kg = ...
        P.cuerpo.masa;

    gravedad_m_s2 = ...
        P.entorno.g;

    numeroMotores = ...
        P.motores.numero;

    if ~isscalar(masa_kg) || ...
            ~isfinite(masa_kg) || ...
            masa_kg <= 0

        error( ...
            'parametros_control_traslacional:MasaInvalida', ...
            'La masa debe ser positiva y finita.' ...
        );

    end

    if ~isscalar(gravedad_m_s2) || ...
            ~isfinite(gravedad_m_s2) || ...
            gravedad_m_s2 <= 0

        error( ...
            'parametros_control_traslacional:GravedadInvalida', ...
            'La gravedad debe ser positiva y finita.' ...
        );

    end

    empujeMinimoMotores_N = expandir_vector_motor( ...
        P.motores.empujeMinimo, ...
        numeroMotores ...
    );

    empujeMaximoMotores_N = expandir_vector_motor( ...
        P.motores.empujeMaximo, ...
        numeroMotores ...
    );

    if any(~isfinite(empujeMinimoMotores_N)) || ...
            any(~isfinite(empujeMaximoMotores_N))

        error( ...
            'parametros_control_traslacional:EmpujeNoFinito', ...
            'Los limites de empuje deben ser finitos.' ...
        );

    end

    if any(empujeMinimoMotores_N < 0) || ...
            any(empujeMaximoMotores_N <= ...
                empujeMinimoMotores_N)

        error( ...
            'parametros_control_traslacional:EmpujeInvalido', ...
            'Los limites de empuje de los motores son invalidos.' ...
        );

    end

    %% ============================================================
    % INFORMACION GENERAL
    % =============================================================

    C.meta.nombre = ...
        "Control traslacional y de altura";

    C.meta.version = ...
        "1.0";

    C.meta.estado = ...
        "PARAMETROS INICIALES";

    C.meta.descripcion = ...
        "Lazos exteriores de posicion, velocidad y altura";

    %% ============================================================
    % PERIODO DE CONTROL
    % =============================================================

    % La simulacion actual trabaja a 100 Hz.
    %
    % Este mismo periodo puede utilizarse inicialmente al portar
    % el controlador a un microcontrolador.

    C.temporal.frecuenciaControl_Hz = ...
        100;

    C.temporal.dtNominal_s = ...
        1 / C.temporal.frecuenciaControl_Hz;

    %% ============================================================
    % LIMITES DE INCLINACION
    % =============================================================

    % Aunque el controlador de actitud admite hasta 25 grados,
    % el control de posicion utilizara como maximo 20 grados.
    %
    % Se conserva margen para responder a perturbaciones.

    anguloHorizontalDeseadoMax_rad = ...
        deg2rad(20);

    if ~isempty(Cactitud) && ...
            isfield(Cactitud, 'limites') && ...
            isfield( ...
                Cactitud.limites, ...
                'anguloRollMax_rad' ...
            ) && ...
            isfield( ...
                Cactitud.limites, ...
                'anguloPitchMax_rad' ...
            )

        limiteActitudDisponible_rad = min( ...
            Cactitud.limites.anguloRollMax_rad, ...
            Cactitud.limites.anguloPitchMax_rad ...
        );

        anguloHorizontalMax_rad = min( ...
            anguloHorizontalDeseadoMax_rad, ...
            0.90 * limiteActitudDisponible_rad ...
        );

    else

        anguloHorizontalMax_rad = ...
            anguloHorizontalDeseadoMax_rad;

    end

    C.limites.anguloHorizontalMax_rad = ...
        anguloHorizontalMax_rad;

    C.limites.anguloHorizontalMax_deg = ...
        rad2deg(anguloHorizontalMax_rad);

    %% ============================================================
    % CONTROL HORIZONTAL DE POSICION
    % =============================================================

    % El lazo de posicion convierte error de posicion en una
    % referencia de velocidad:
    %
    %   velocidadReferencia =
    %       KpPosicion * errorPosicion
    %
    % Las ganancias se aplican sobre los ejes Norte y Este.

    C.horizontal.posicion.Kp_N = ...
        1.00;

    C.horizontal.posicion.Kp_E = ...
        1.00;

    % No se utiliza integral en el lazo de posicion.
    %
    % La integral se coloca en el lazo interior de velocidad.

    C.horizontal.posicion.Ki_N = ...
        0;

    C.horizontal.posicion.Ki_E = ...
        0;

    %% ============================================================
    % CONTROL HORIZONTAL DE VELOCIDAD
    % =============================================================

    % El lazo de velocidad convierte error de velocidad en una
    % aceleracion horizontal deseada:
    %
    %   aceleracionDeseada =
    %       KpVelocidad * errorVelocidad
    %       + KiVelocidad * integralError

    C.horizontal.velocidad.Kp_N = ...
        2.20;

    C.horizontal.velocidad.Kp_E = ...
        2.20;

    C.horizontal.velocidad.Ki_N = ...
        0.35;

    C.horizontal.velocidad.Ki_E = ...
        0.35;

    C.horizontal.velocidad.Kd_N = ...
        0;

    C.horizontal.velocidad.Kd_E = ...
        0;

    %% ============================================================
    % LIMITES HORIZONTALES
    % =============================================================

    % Velocidad máxima ordenada con el teclado.

    C.horizontal.limites.velocidadManualMax_m_s = ...
        1.20;

    % Velocidad máxima permitida al corregir una perturbación.

    C.horizontal.limites.velocidadCorreccionMax_m_s = ...
        1.50;

    % Aceleración máxima obtenible por inclinación.
    %
    % Para ángulos pequeños:
    %
    %   a_horizontal ≈ g * tan(angulo)

    aceleracionPorInclinacion_m_s2 = ...
        gravedad_m_s2 * ...
        tan(anguloHorizontalMax_rad);

    C.horizontal.limites.aceleracionMax_m_s2 = min( ...
        2.50, ...
        0.85 * aceleracionPorInclinacion_m_s2 ...
    );

    % Limitar acumulación integral horizontal.

    C.horizontal.limites.integralVelocidad_N_max = ...
        1.50;

    C.horizontal.limites.integralVelocidad_E_max = ...
        1.50;

    %% ============================================================
    % MANTENIMIENTO DE POSICION
    % =============================================================

    % Mientras se presiona una tecla:
    %
    %   Se controla velocidad.
    %
    % Al soltar todas las teclas horizontales:
    %
    %   Se captura una posición objetivo.
    %   El dron frena y mantiene esa posición.

    C.horizontal.mantenimiento.activado = ...
        true;

    C.horizontal.mantenimiento.modoAlSoltar = ...
        "CAPTURAR_POSICION";

    % Tiempo neutro antes de capturar la posición.
    %
    % Evita cambios de modo por rebotes muy cortos del teclado.

    C.horizontal.mantenimiento.retardoCaptura_s = ...
        0.10;

    C.horizontal.mantenimiento.toleranciaPosicion_m = ...
        0.05;

    C.horizontal.mantenimiento.toleranciaVelocidad_m_s = ...
        0.08;

    % Zona muerta para evitar correcciones diminutas y temblor.

    C.horizontal.mantenimiento.zonaMuertaPosicion_m = ...
        0.015;

    C.horizontal.mantenimiento.zonaMuertaVelocidad_m_s = ...
        0.025;

    %% ============================================================
    % CONTROL DE ALTURA
    % =============================================================

    % La altura se expresa positiva hacia arriba:
    %
    %   altura = -zD
    %
    % El lazo exterior convierte error de altura en velocidad
    % vertical deseada.

    C.altura.posicion.Kp = ...
        1.30;

    C.altura.posicion.Ki = ...
        0;

    C.altura.posicion.Kd = ...
        0;

    % El lazo interior convierte error de velocidad vertical en
    % aceleración vertical deseada.

    C.altura.velocidad.Kp = ...
        2.80;

    C.altura.velocidad.Ki = ...
        1.00;

    C.altura.velocidad.Kd = ...
        0;

    %% ============================================================
    % LIMITES DE ALTURA
    % =============================================================

    C.altura.limites.alturaMinima_m = ...
        0.10;

    C.altura.limites.alturaMaxima_m = ...
        5.00;

    C.altura.limites.velocidadSubidaMax_m_s = ...
        1.00;

    C.altura.limites.velocidadBajadaMax_m_s = ...
        0.80;

    %% Autoridad vertical disponible

    empujeHoverTotal_N = ...
        masa_kg * gravedad_m_s2;

    empujeMinimoTotal_N = ...
        sum(empujeMinimoMotores_N);

    empujeMaximoTotal_N = ...
        sum(empujeMaximoMotores_N);

    if empujeHoverTotal_N <= empujeMinimoTotal_N || ...
            empujeHoverTotal_N >= empujeMaximoTotal_N

        error( ...
            'parametros_control_traslacional:HoverImposible', ...
            ['El empuje de hover no queda dentro de los ' ...
             'limites físicos de los motores.'] ...
        );

    end

    aceleracionSubidaFisicaMax_m_s2 = ...
        empujeMaximoTotal_N / masa_kg - ...
        gravedad_m_s2;

    aceleracionBajadaFisicaMax_m_s2 = ...
        gravedad_m_s2 - ...
        empujeMinimoTotal_N / masa_kg;

    C.altura.limites.aceleracionSubidaMax_m_s2 = min( ...
        3.00, ...
        0.80 * aceleracionSubidaFisicaMax_m_s2 ...
    );

    C.altura.limites.aceleracionBajadaMax_m_s2 = min( ...
        2.50, ...
        0.80 * aceleracionBajadaFisicaMax_m_s2 ...
    );

    C.altura.limites.integralVelocidadMax = ...
        2.00;

    C.altura.limites.toleranciaAltura_m = ...
        0.03;

    C.altura.limites.toleranciaVelocidad_m_s = ...
        0.05;

    %% ============================================================
    % MODIFICACION MANUAL DE ALTURA
    % =============================================================

    % W y S no controlarán directamente el empuje.
    %
    % Modificarán progresivamente la referencia de altura:
    %
    %   W -> aumenta altura deseada.
    %   S -> disminuye altura deseada.

    C.altura.mando.velocidadCambioReferencia_m_s = ...
        0.80;

    % Valor predeterminado para botones como:
    %
    %   "Subir 1 metro"
    %   "Bajar 1 metro"

    C.altura.mando.incrementoPredeterminado_m = ...
        1.00;

    C.altura.mando.alturaInicialPredeterminada_m = ...
        1.00;

    %% ============================================================
    % EMPUJE COLECTIVO
    % =============================================================

    C.empuje.hoverTotal_N = ...
        empujeHoverTotal_N;

    C.empuje.hoverPorMotor_N = ...
        empujeHoverTotal_N / numeroMotores;

    C.empuje.minimoTotal_N = ...
        empujeMinimoTotal_N;

    C.empuje.maximoTotal_N = ...
        empujeMaximoTotal_N;

    % Margen adicional para evitar trabajar permanentemente
    % pegado al límite físico.

    C.empuje.factorSeguridad = ...
        0.95;

    C.empuje.maximoControl_N = ...
        C.empuje.factorSeguridad * ...
        empujeMaximoTotal_N;

    %% ============================================================
    % DETECCION DE PÉRDIDA DE CONTROL
    % =============================================================

    C.seguridad.inclinacionMaxima_rad = ...
        deg2rad(70);

    C.seguridad.inclinacionMaxima_deg = ...
        rad2deg(C.seguridad.inclinacionMaxima_rad);

    C.seguridad.velocidadHorizontalMax_m_s = ...
        6.00;

    C.seguridad.velocidadVerticalMax_m_s = ...
        4.00;

    C.seguridad.radioOperacionMax_m = ...
        20.00;

    C.seguridad.alturaOperacionMax_m = ...
        C.altura.limites.alturaMaxima_m + 1.00;

    C.seguridad.tiempoSaturacionMax_s = ...
        1.00;

    C.seguridad.tiempoRecuperacionMax_s = ...
        6.00;

    C.seguridad.errorPosicionCritico_m = ...
        5.00;

    C.seguridad.errorAlturaCritico_m = ...
        2.00;

    %% ============================================================
    % INFORMACION DERIVADA
    % =============================================================

    C.diagnostico.masa_kg = ...
        masa_kg;

    C.diagnostico.gravedad_m_s2 = ...
        gravedad_m_s2;

    C.diagnostico.empujeHoverTotal_N = ...
        empujeHoverTotal_N;

    C.diagnostico.empujeMaximoTotal_N = ...
        empujeMaximoTotal_N;

    C.diagnostico.relacionEmpujePeso = ...
        empujeMaximoTotal_N / ...
        empujeHoverTotal_N;

    C.diagnostico.aceleracionSubidaFisicaMax_m_s2 = ...
        aceleracionSubidaFisicaMax_m_s2;

    C.diagnostico.aceleracionBajadaFisicaMax_m_s2 = ...
        aceleracionBajadaFisicaMax_m_s2;

    C.diagnostico.aceleracionHorizontalPorInclinacion_m_s2 = ...
        aceleracionPorInclinacion_m_s2;

end


function vectorExpandido = expandir_vector_motor( ...
    valor, ...
    numeroMotores ...
)
%EXPANDIR_VECTOR_MOTOR
% Convierte un escalar o vector en una columna con un valor por motor.

    valor = ...
        valor(:);

    if isscalar(valor)

        vectorExpandido = repmat( ...
            valor, ...
            numeroMotores, ...
            1 ...
        );

    elseif numel(valor) == numeroMotores

        vectorExpandido = ...
            valor;

    else

        error( ...
            'parametros_control_traslacional:DimensionMotorInvalida', ...
            ['El limite debe ser escalar o contener un valor ' ...
             'por cada motor.'] ...
        );

    end

end