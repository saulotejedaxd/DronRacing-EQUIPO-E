function C = parametros_control_actitud(P)
%PARAMETROS_CONTROL_ACTITUD Genera ganancias provisionales del controlador.
%
% Las ganancias de roll y pitch se calculan usando:
%
%   Kp = I * wn^2
%   Kd = 2*zeta*I*wn
%
% Son valores provisionales para el caso base teórico.
% Posteriormente deberán ajustarse con el dron real.

    %% Validar parámetros físicos

    if ~isfield(P, 'cuerpo') || ...
            ~isfield(P.cuerpo, 'inercia_B') || ...
            ~isfield(P.cuerpo, 'masa')

        error( ...
            'parametros_control_actitud:ParametrosInvalidos', ...
            'P debe contener masa e inercia del cuerpo.' ...
        );

    end

    inercia = P.cuerpo.inercia_B;

    masa = P.cuerpo.masa;

    g = P.entorno.g;

    Ixx = inercia(1, 1);
    Iyy = inercia(2, 2);
    Izz = inercia(3, 3);

    if any(~isfinite([masa, g, Ixx, Iyy, Izz])) || ...
            any([masa, g, Ixx, Iyy, Izz] <= 0)

        error( ...
            'parametros_control_actitud:ValoresInvalidos', ...
            'La masa, gravedad e inercias deben ser positivas.' ...
        );

    end

    %% Información

    C.meta.nombre = ...
        'Controlador provisional de actitud';

    C.meta.version = ...
        '0.1';

    C.meta.estado = ...
        'PROVISIONAL';

    %% Límites de referencias

    C.limites.anguloRollMax_rad = ...
        deg2rad(25);

    C.limites.anguloPitchMax_rad = ...
        deg2rad(25);

    C.limites.velocidadYawMax_rad_s = ...
        deg2rad(90);

    %% Diseño de roll y pitch

    frecuenciaNaturalRollPitch = 4.5;
    amortiguamientoRollPitch = 0.90;

    C.roll.Kp = ...
        Ixx * frecuenciaNaturalRollPitch^2;

    C.roll.Kd = ...
        2 * amortiguamientoRollPitch * ...
        Ixx * frecuenciaNaturalRollPitch;

    C.roll.Ki = ...
        0.10 * C.roll.Kp;

    C.pitch.Kp = ...
        Iyy * frecuenciaNaturalRollPitch^2;

    C.pitch.Kd = ...
        2 * amortiguamientoRollPitch * ...
        Iyy * frecuenciaNaturalRollPitch;

    C.pitch.Ki = ...
        0.10 * C.pitch.Kp;

    %% Control de velocidad de yaw

    frecuenciaNaturalYaw = 3.5;
    amortiguamientoYaw = 1.0;

    C.yaw.Kp = ...
        2 * amortiguamientoYaw * ...
        Izz * frecuenciaNaturalYaw;

    C.yaw.Ki = ...
        Izz * frecuenciaNaturalYaw^2;

    C.yaw.Kd = 0;

    %% Límites de los integradores

    C.limites.integralRollMax = ...
        0.35;

    C.limites.integralPitchMax = ...
        0.35;

    C.limites.integralYawMax = ...
        0.50;

    %% Límites provisionales de momentos

    posiciones = P.motores.posicion_B;

    brazoRoll = ...
        max(abs(posiciones(2, :)));

    brazoPitch = ...
        max(abs(posiciones(1, :)));

    C.limites.momentoRollMax_Nm = max( ...
        0.05, ...
        0.35 * masa * g * brazoRoll ...
    );

    C.limites.momentoPitchMax_Nm = max( ...
        0.05, ...
        0.35 * masa * g * brazoPitch ...
    );

    % Provisional hasta conocer la curva real de torque de reacción.
    C.limites.momentoYawMax_Nm = 0.08;

end