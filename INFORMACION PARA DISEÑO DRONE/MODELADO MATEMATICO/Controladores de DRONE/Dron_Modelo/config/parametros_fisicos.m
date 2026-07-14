function P = parametros_fisicos()
%PARAMETROS_FISICOS Parámetros físicos del dron.
%
% Todos los parámetros utilizan unidades del Sistema Internacional.
% Los valores NaN indican que el parámetro todavía no ha sido definido.
%
% Salida:
%   P - Estructura con los parámetros físicos del dron.

    %% Información del conjunto de parámetros

    P.meta.nombre  = "Modelo inicial del dron";
    P.meta.version = "0.1";
    P.meta.estado  = "INCOMPLETO";

    %% Entorno

    % Gravedad estándar convencional. Posteriormente puede sustituirse
    % por la gravedad local si se requiere mayor precisión.
    P.entorno.g = 9.80665;                   % m/s^2

    %% Cuerpo rígido

    P.cuerpo.masa = NaN;                     % kg

    % Centro de masa expresado en el marco del cuerpo FRD.
    P.cuerpo.centroMasa_B = [
        NaN
        NaN
        NaN
    ];                                      % m

    % Tensor de inercia respecto al centro de masa y expresado
    % en el marco del cuerpo.
    P.cuerpo.inercia_B = [
        NaN, NaN, NaN
        NaN, NaN, NaN
        NaN, NaN, NaN
    ];                                      % kg*m^2

    %% Motores

    P.motores.numero = 4;

    % Cada columna representa la posición de un motor respecto
    % al centro de masa:
    %
    % [x1 x2 x3 x4
    %  y1 y2 y3 y4
    %  z1 z2 z3 z4]
    %
    % Marco del cuerpo: X hacia delante, Y hacia la derecha,
    % Z hacia abajo.
    P.motores.posicion_B = NaN(3, P.motores.numero);   % m

    % Sentido de giro:
    % +1 = sentido positivo definido para el modelo
    % -1 = sentido contrario
    %
    % Todavía no lo asignamos hasta definir la numeración
    % física de los motores.
    P.motores.sentidoGiro = NaN(P.motores.numero, 1);
    
    % Signo del momento de reacción de yaw sobre el cuerpo:
    % +1 = momento positivo alrededor de +Z_B
    % -1 = momento negativo alrededor de +Z_B
    P.motores.signoTorqueYawCuerpo = ...
        NaN(P.motores.numero, 1);

    % Límites individuales de empuje.
    P.motores.empujeMinimo = zeros(P.motores.numero, 1); % N
    P.motores.empujeMaximo = NaN(P.motores.numero, 1);   % N

    % Constante de tiempo aproximada de cada conjunto
    % ESC-motor-hélice.
    P.motores.constanteTiempo = NaN(P.motores.numero, 1); % s

    %% Hélices y generación de fuerzas

    % Coeficiente de empuje:
    % T_i = kT_i * omega_i^2
    P.helices.kT = NaN(P.motores.numero, 1);            % N/(rad/s)^2

    % Coeficiente de torque aerodinámico:
    % Q_i = kQ_i * omega_i^2
    P.helices.kQ = NaN(P.motores.numero, 1);            % N*m/(rad/s)^2

    %% Aerodinámica simplificada

    % Estos coeficientes se utilizarán posteriormente para representar
    % resistencia al movimiento. Por ahora permanecen sin definir.
    P.aerodinamica.arrastreLineal_B = [
        NaN
        NaN
        NaN
    ];                                                  % N/(m/s)

    P.aerodinamica.arrastreAngular_B = [
        NaN
        NaN
        NaN
    ];                                                  % N*m/(rad/s)

end