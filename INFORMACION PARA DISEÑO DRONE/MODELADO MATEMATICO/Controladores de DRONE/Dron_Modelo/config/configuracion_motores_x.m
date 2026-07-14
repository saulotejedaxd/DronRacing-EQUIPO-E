function G = configuracion_motores_x(R, D, L, zMotor_B)
%CONFIGURACION_MOTORES_X Define la geometría de un cuadricóptero en X.
%
% Entradas:
%   R         - Reglas de competencia.
%   D         - Requisitos del proyecto.
%   L         - Distancia horizontal del centro de masa al eje
%               de cada motor, en metros.
%   zMotor_B  - Coordenada vertical de los motores respecto al
%               centro de masa, en el marco FRD, en metros.
%
% Convención corporal FRD:
%   +X_B: frente
%   +Y_B: derecha
%   +Z_B: abajo
%
% Numeración vista desde arriba:
%
%                 FRENTE +X_B
%
%              M1             M2
%         frontal izquierdo  frontal derecho
%              CCW             CW
%
%                    CENTRO
%
%              M4             M3
%         trasero izquierdo   trasero derecho
%              CW              CCW
%
% Nota:
%   Esta numeración es una convención interna del proyecto.
%   Posteriormente deberá mapearse correctamente a las salidas
%   físicas del controlador de vuelo y del ESC.

    if nargin < 3
        L = NaN;
    end

    if nargin < 4
        zMotor_B = NaN;
    end

    %% Información general

    G.meta.nombre = "Configuración X del cuadricóptero";
    G.meta.version = "0.1";

    G.numeroMotores = 4;
    G.distanciaCentroMotor = L;
    G.zMotor_B = zMotor_B;

    %% Identificación de motores

    G.nombreMotores = [
        "M1"
        "M2"
        "M3"
        "M4"
    ];

    G.ubicacionMotores = [
        "Frontal izquierdo"
        "Frontal derecho"
        "Trasero derecho"
        "Trasero izquierdo"
    ];

    %% Sentido de giro visto desde arriba

    G.sentidoGiroTexto = [
        "CCW"
        "CW"
        "CCW"
        "CW"
    ];

    % Convención numérica:
    % +1 = CCW visto desde arriba
    % -1 = CW visto desde arriba
    G.sentidoGiro = [
         1
        -1
         1
        -1
    ];

    % En el marco FRD, el eje +Z apunta hacia abajo.
    % El torque de reacción sobre el cuerpo es contrario al giro
    % del rotor.
    %
    % Un rotor CCW genera reacción CW sobre el cuerpo.
    % Vista desde arriba, CW corresponde a yaw positivo en FRD.
    G.signoTorqueYawCuerpo = [
         1
        -1
         1
        -1
    ];

    %% Posiciones de motores

    if isfinite(L)
        a = L / sqrt(2);
    else
        a = NaN;
    end

    G.componenteDiagonal = a;

    % Cada columna representa un motor:
    %
    % [x1 x2 x3 x4
    %  y1 y2 y3 y4
    %  z1 z2 z3 z4]

    G.posicionMotores_B = [
         a,  a, -a, -a
        -a,  a,  a, -a
         zMotor_B, zMotor_B, zMotor_B, zMotor_B
    ];

    %% Dimensiones derivadas

    G.diametroCirculoMotores = 2 * L;

    G.separacionMotoresAdyacentes = sqrt(2) * L;

    G.separacionMotoresOpuestos = 2 * L;

    G.holguraEntreDiscosHelices = ...
        G.separacionMotoresAdyacentes - D.helice.diametro;

    %% Límites disponibles

    G.limites.distanciaCentroMotorMinTeorica = ...
        D.geometria.distanciaCentroMotorMinTeorica;

    G.limites.distanciaCentroMotorMaxReglamentaria = ...
        R.geometria.distanciaCentroMotorMax;

    %% Tabla descriptiva

    G.tablaMotores = table( ...
        G.nombreMotores, ...
        G.ubicacionMotores, ...
        G.sentidoGiroTexto, ...
        G.sentidoGiro, ...
        G.signoTorqueYawCuerpo, ...
        G.posicionMotores_B(1, :).', ...
        G.posicionMotores_B(2, :).', ...
        G.posicionMotores_B(3, :).', ...
        'VariableNames', { ...
            'Motor', ...
            'Ubicacion', ...
            'GiroVistaSuperior', ...
            'SignoGiro', ...
            'SignoTorqueYaw', ...
            'x_B_m', ...
            'y_B_m', ...
            'z_B_m'} ...
    );

end