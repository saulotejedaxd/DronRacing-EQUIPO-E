function [P, C, caso] = caso_real_dron(P, C, R)
%CASO_REAL_DRON Construye la primera version del modelo fisico real.
%
% Dron:
%   KIWO E88
%
% Esta version utiliza:
%
% DATOS MEDIDOS:
%   - Masa total con bateria:       0.081 kg
%   - Masa sin bateria:             0.064 kg
%   - Masa de bateria:              0.017 kg
%   - Separacion frente-atras:      0.170 m
%   - Separacion izquierda-derecha: 0.140 m
%   - Diametro de helice:           0.100 m
%
% DATOS ESTIMADOS:
%   - Posicion de la bateria.
%   - Tensor de inercia.
%   - Altura de motores traseros.
%   - Empuje maximo.
%   - Constante de tiempo.
%   - Coeficientes kT y kQ.
%
% El origen del marco corporal se coloca en el centro de masa.
%
% Convencion FRD:
%   +X_B: frente
%   +Y_B: derecha
%   +Z_B: abajo
%
% Numeracion:
%
%                 FRENTE +X_B
%
%              M1             M2
%       frontal izquierdo  frontal derecho
%
%              M4             M3
%        trasero izquierdo  trasero derecho
%
% Entradas:
%   P - Estructura generada por parametros_fisicos.
%   C - Estructura generada por parametros_diseno.
%   R - Reglas de competencia.
%
% Salidas:
%   P    - Parametros fisicos del KIWO E88.
%   C    - Parametros geometricos actualizados.
%   caso - Informacion, supuestos y resultados derivados.

    %% ============================================================
    % VALIDAR ENTRADAS
    % =============================================================

    if nargin < 2

        error( ...
            'caso_real_dron:FaltanEntradas', ...
            ['Debes proporcionar P y C. Ejemplo: ' ...
             '[P,C,caso] = caso_real_dron(P,C,R);'] ...
        );

    end

    if nargin < 3

        R = [];

    end

    %% ============================================================
    % METADATOS
    % =============================================================

    caso.meta.nombre = ...
        "KIWO E88 - modelo fisico real V1";

    caso.meta.version = ...
        "1.0";

    caso.meta.tipo = ...
        "REAL CON PARAMETROS ESTIMADOS";

    caso.meta.descripcion = ...
        "Modelo basado en masas y geometria medidas del dron";

    caso.meta.representaDronReal = true;

    caso.meta.estado = ...
        "PRIMERA APROXIMACION";

    P.meta.nombre = ...
        "Parametros fisicos KIWO E88";

    P.meta.version = ...
        "1.0";

    P.meta.estado = ...
        "REAL V1";

    C.meta.nombre = ...
        "Geometria medida KIWO E88";

    C.meta.version = ...
        "1.0";

    C.meta.estado = ...
        "REAL V1";

    %% ============================================================
    % MASAS MEDIDAS
    % =============================================================

    masaTotal_kg = 0.081;

    masaBateria_kg = 0.017;

    masaSinBateria_kg = 0.064;

    errorMasa_kg = ...
        masaTotal_kg - ...
        (masaSinBateria_kg + masaBateria_kg);

    if abs(errorMasa_kg) > 1e-6

        error( ...
            'caso_real_dron:InconsistenciaMasa', ...
            ['La masa total no coincide con la suma de la ' ...
             'masa sin bateria y la masa de la bateria.'] ...
        );

    end

    P.cuerpo.masa = ...
        masaTotal_kg;

    %% ============================================================
    % GEOMETRIA MEDIDA ENTRE MOTORES
    % =============================================================

    separacionFrenteAtras_m = 0.170;

    separacionIzquierdaDerecha_m = 0.140;

    semidistanciaX_m = ...
        separacionFrenteAtras_m / 2;

    semidistanciaY_m = ...
        separacionIzquierdaDerecha_m / 2;

    distanciaCentroMotorGeometrica_m = sqrt( ...
        semidistanciaX_m^2 + ...
        semidistanciaY_m^2 ...
    );

    diagonalMotores_m = ...
        2 * distanciaCentroMotorGeometrica_m;

    diametroHelice_m = 0.100;

    %% ============================================================
    % POSICION ESTIMADA DE LA BATERIA
    % =============================================================

    % Se supone que el centro de la bateria se encuentra
    % aproximadamente 3 cm detras del centro geometrico.
    %
    % Esta posicion debera refinarse posteriormente mediante
    % una medicion o una prueba de balanceo.

    posicionBateriaRespectoCentroGeometrico_m = [
        -0.030
         0
         0
    ];

    % Se supone inicialmente que el centro de masa del dron sin
    % bateria coincide con el centro geometrico.

    posicionMasaSinBateriaCentroGeometrico_m = [
        0
        0
        0
    ];

    %% ============================================================
    % CALCULAR CENTRO DE MASA TOTAL
    % =============================================================

    centroMasaRespectoCentroGeometrico_m = ...
        ( ...
            masaSinBateria_kg * ...
            posicionMasaSinBateriaCentroGeometrico_m + ...
            masaBateria_kg * ...
            posicionBateriaRespectoCentroGeometrico_m ...
        ) / masaTotal_kg;

    % El marco corporal se define directamente en el centro de masa.
    %
    % Por esa razon, dentro del marco B el centro de masa siempre
    % se encuentra en el origen.

    P.cuerpo.centroMasa_B = [
        0
        0
        0
    ];

    %% ============================================================
    % POSICIONES DE LOS MOTORES RESPECTO AL CENTRO DE MASA
    % =============================================================

    % Posicion vertical estimada:
    %
    % Motores delanteros:
    %   inicialmente en el mismo nivel del centro de masa.
    %
    % Motores traseros:
    %   aproximadamente 1.25 cm arriba del centro de masa.
    %
    % En FRD, arriba corresponde a Z negativa.

    zMotoresDelanteros_B_m = 0;

    zMotoresTraseros_B_m = -0.0125;

    % Coordenadas respecto al centro geometrico.

    posicionesMotoresCentroGeometrico_m = [
         semidistanciaX_m,  semidistanciaX_m, ...
        -semidistanciaX_m, -semidistanciaX_m

        -semidistanciaY_m,  semidistanciaY_m, ...
         semidistanciaY_m, -semidistanciaY_m

         zMotoresDelanteros_B_m, ...
         zMotoresDelanteros_B_m, ...
         zMotoresTraseros_B_m, ...
         zMotoresTraseros_B_m
    ];

    % Convertir las posiciones para expresarlas respecto al centro
    % de masa real y no respecto al centro geometrico.

    P.motores.posicion_B = ...
        posicionesMotoresCentroGeometrico_m - ...
        centroMasaRespectoCentroGeometrico_m;

    %% ============================================================
    % NUMERACION Y SENTIDO DE GIRO
    % =============================================================

    P.motores.numero = 4;

    % +1 = CCW visto desde arriba.
    % -1 = CW visto desde arriba.

    P.motores.sentidoGiro = [
         1
        -1
         1
        -1
    ];

    % Signo del torque de reaccion sobre el cuerpo en el eje Z_B.

    P.motores.signoTorqueYawCuerpo = [
         1
        -1
         1
        -1
    ];

    %% ============================================================
    % ESTIMACION DEL TENSOR DE INERCIA
    % =============================================================

    % La inercia del dron sin bateria se obtuvo como una primera
    % aproximacion a partir del STL cerrado, suponiendo densidad
    % uniforme y escalando el resultado a una masa de 64 gramos.
    %
    % Se utiliza un tensor diagonal para esta primera version.

    inerciaSinBateriaCentroPropio_kgm2 = diag([
        1.2107e-4
        1.0444e-4
        2.0295e-4
    ]);

    % Dimensiones provisionales de la bateria:
    %
    %   largo:   60 mm
    %   ancho:   35 mm
    %   espesor: 12 mm

    dimensionesBateria_m = [
        0.060
        0.035
        0.012
    ];

    largoBateria_m = ...
        dimensionesBateria_m(1);

    anchoBateria_m = ...
        dimensionesBateria_m(2);

    altoBateria_m = ...
        dimensionesBateria_m(3);

    % Tensor de inercia de un prisma rectangular respecto a su
    % propio centro de masa.

    IxxBateria = ...
        masaBateria_kg / 12 * ...
        (anchoBateria_m^2 + altoBateria_m^2);

    IyyBateria = ...
        masaBateria_kg / 12 * ...
        (largoBateria_m^2 + altoBateria_m^2);

    IzzBateria = ...
        masaBateria_kg / 12 * ...
        (largoBateria_m^2 + anchoBateria_m^2);

    inerciaBateriaCentroPropio_kgm2 = diag([
        IxxBateria
        IyyBateria
        IzzBateria
    ]);

    %% Aplicar teorema de ejes paralelos

    posicionSinBateriaRespectoCM_m = ...
        posicionMasaSinBateriaCentroGeometrico_m - ...
        centroMasaRespectoCentroGeometrico_m;

    posicionBateriaRespectoCM_m = ...
        posicionBateriaRespectoCentroGeometrico_m - ...
        centroMasaRespectoCentroGeometrico_m;

    desplazamientoSinBateria = ...
        masaSinBateria_kg * ...
        ( ...
            dot( ...
                posicionSinBateriaRespectoCM_m, ...
                posicionSinBateriaRespectoCM_m ...
            ) * eye(3) - ...
            posicionSinBateriaRespectoCM_m * ...
            posicionSinBateriaRespectoCM_m.' ...
        );

    desplazamientoBateria = ...
        masaBateria_kg * ...
        ( ...
            dot( ...
                posicionBateriaRespectoCM_m, ...
                posicionBateriaRespectoCM_m ...
            ) * eye(3) - ...
            posicionBateriaRespectoCM_m * ...
            posicionBateriaRespectoCM_m.' ...
        );

    inerciaTotal_B_kgm2 = ...
        inerciaSinBateriaCentroPropio_kgm2 + ...
        desplazamientoSinBateria + ...
        inerciaBateriaCentroPropio_kgm2 + ...
        desplazamientoBateria;

    % Eliminar errores numericos diminutos y asegurar simetria.

    inerciaTotal_B_kgm2 = ...
        0.5 * ...
        ( ...
            inerciaTotal_B_kgm2 + ...
            inerciaTotal_B_kgm2.' ...
        );

    P.cuerpo.inercia_B = ...
        inerciaTotal_B_kgm2;

    %% ============================================================
    % LIMITES PROVISIONALES DE LOS MOTORES
    % =============================================================

    % Cada motor necesita aproximadamente 0.199 N para hover.
    %
    % Se asigna provisionalmente un maximo de 0.300 N por motor.
    % Este valor NO es una medicion del fabricante y debera ser
    % sustituido mediante una prueba de empuje.

    empujeMaximoPorMotor_N = 0.300;

    P.motores.empujeMinimo = ...
        zeros(P.motores.numero, 1);

    P.motores.empujeMaximo = ...
        empujeMaximoPorMotor_N * ...
        ones(P.motores.numero, 1);

    % Constante de tiempo provisional para un motor pequeno con
    % escobillas, helice y transmision por engranajes.

    constanteTiempoMotor_s = 0.050;

    P.motores.constanteTiempo = ...
        constanteTiempoMotor_s * ...
        ones(P.motores.numero, 1);

    %% ============================================================
    % COEFICIENTES PROVISIONALES DE HELICES
    % =============================================================

    % Estos coeficientes todavia no intervienen directamente en el
    % mezclador actual, pero se dejan definidos para evitar campos
    % pendientes dentro del conjunto de parametros.
    %
    % Se supone provisionalmente una velocidad maxima de helice
    % de 15000 rpm.

    velocidadHeliceMax_rpm = 15000;

    velocidadHeliceMax_rad_s = ...
        velocidadHeliceMax_rpm * ...
        2 * pi / 60;

    kT_estimado = ...
        empujeMaximoPorMotor_N / ...
        velocidadHeliceMax_rad_s^2;

    % Se estima un torque maximo de reaccion por rotor de
    % aproximadamente 0.0015 N*m.

    torqueReaccionMaximoRotor_Nm = 0.0015;

    kQ_estimado = ...
        torqueReaccionMaximoRotor_Nm / ...
        velocidadHeliceMax_rad_s^2;

    P.helices.kT = ...
        kT_estimado * ...
        ones(P.motores.numero, 1);

    P.helices.kQ = ...
        kQ_estimado * ...
        ones(P.motores.numero, 1);

    %% ============================================================
    % AERODINAMICA
    % =============================================================

    % En esta primera version se desprecia el arrastre.
    %
    % Cero significa que se omite conscientemente, no que el
    % parametro este pendiente.

    P.aerodinamica.arrastreLineal_B = ...
        zeros(3, 1);

    P.aerodinamica.arrastreAngular_B = ...
        zeros(3, 1);

    %% ============================================================
    % ACTUALIZAR PARAMETROS DE DISEÑO
    % =============================================================

    C.geometria.separacionFrenteAtras = ...
        separacionFrenteAtras_m;

    C.geometria.separacionIzquierdaDerecha = ...
        separacionIzquierdaDerecha_m;

    C.geometria.distanciaCentroMotor = ...
        distanciaCentroMotorGeometrica_m;

    % Se conserva este campo por compatibilidad con archivos
    % anteriores, aunque el dron real no utiliza una sola altura
    % comun para todos los motores.

    C.geometria.zMotor_B = ...
        mean( ...
            P.motores.posicion_B(3, :) ...
        );

    C.geometria.zMotoresDelanteros_B = ...
        P.motores.posicion_B(3, 1);

    C.geometria.zMotoresTraseros_B = ...
        P.motores.posicion_B(3, 3);

    C.geometria.diametroHelice = ...
        diametroHelice_m;

    %% ============================================================
    % RESULTADOS DERIVADOS
    % =============================================================

    empujeHoverTotal_N = ...
        masaTotal_kg * P.entorno.g;

    empujeHoverPorMotor_N = ...
        empujeHoverTotal_N / P.motores.numero;

    relacionEmpujePesoMaxima = ...
        sum(P.motores.empujeMaximo) / ...
        empujeHoverTotal_N;

    caso.masaTotal_kg = ...
        masaTotal_kg;

    caso.masaSinBateria_kg = ...
        masaSinBateria_kg;

    caso.masaBateria_kg = ...
        masaBateria_kg;

    caso.fraccionMasaBateria = ...
        masaBateria_kg / masaTotal_kg;

    caso.separacionFrenteAtras_m = ...
        separacionFrenteAtras_m;

    caso.separacionIzquierdaDerecha_m = ...
        separacionIzquierdaDerecha_m;

    caso.distanciaCentroMotorGeometrica_m = ...
        distanciaCentroMotorGeometrica_m;

    caso.diagonalMotores_m = ...
        diagonalMotores_m;

    caso.diametroHelice_m = ...
        diametroHelice_m;

    caso.centroMasaRespectoCentroGeometrico_B_m = ...
        centroMasaRespectoCentroGeometrico_m;

    caso.posicionBateriaRespectoCentroGeometrico_B_m = ...
        posicionBateriaRespectoCentroGeometrico_m;

    caso.posicionBateriaRespectoCM_B_m = ...
        posicionBateriaRespectoCM_m;

    caso.posicionMotores_B_m = ...
        P.motores.posicion_B;

    caso.inercia_B_kgm2 = ...
        P.cuerpo.inercia_B;

    caso.empujeHoverTotal_N = ...
        empujeHoverTotal_N;

    caso.empujeHoverPorMotor_N = ...
        empujeHoverPorMotor_N;

    caso.empujeMaximoPorMotor_N = ...
        empujeMaximoPorMotor_N;

    caso.relacionEmpujePesoMaxima = ...
        relacionEmpujePesoMaxima;

    caso.motor.tipo = ...
        "816 coreless brushed con engranajes";

    caso.motor.voltajeNominal_V = ...
        3.7;

    caso.motor.constanteTiempoEstimada_s = ...
        constanteTiempoMotor_s;

    caso.helice.velocidadMaximaEstimada_rpm = ...
        velocidadHeliceMax_rpm;

    caso.helice.kT_estimado = ...
        kT_estimado;

    caso.helice.kQ_estimado = ...
        kQ_estimado;

    caso.helice.torqueReaccionMaximoRotorEstimado_Nm = ...
        torqueReaccionMaximoRotor_Nm;

    %% ============================================================
    % SUPUESTOS PENDIENTES DE VALIDAR
    % =============================================================

    caso.supuestos = [
        "Centro del dron sin bateria en el centro geometrico"
        "Centro de bateria 3 cm detras del centro geometrico"
        "Bateria centrada lateral y verticalmente"
        "Motores traseros 1.25 cm arriba del centro de masa"
        "Inercia estimada mediante STL y modelo de bateria"
        "Empuje maximo de 0.300 N por motor"
        "Velocidad maxima de helice de 15000 rpm"
        "Constante de tiempo del motor de 0.050 s"
        "Arrastre aerodinamico despreciado"
    ];

    %% ============================================================
    % VERIFICAR MASA REGLAMENTARIA
    % =============================================================

    if ~isempty(R) && ...
            isfield(R, 'masa') && ...
            isfield(R.masa, 'maxima')

        caso.cumpleMasaReglamentaria = ...
            masaTotal_kg <= R.masa.maxima;

    else

        caso.cumpleMasaReglamentaria = ...
            NaN;

    end

end