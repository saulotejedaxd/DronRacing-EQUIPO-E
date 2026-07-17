function [momentoDeseado_B_Nm, estadoControl, D] = ...
    controlador_actitud( ...
        comando, x, dt, C, estadoControl, modelo)
%CONTROLADOR_ACTITUD Controla roll, pitch y velocidad de yaw.
%
% Mapeo de comandos:
%
%   comando.roll
%       -1 a +1
%       Genera una referencia de ángulo phi.
%
%   comando.pitch
%       -1 a +1
%       Positivo significa avanzar.
%       Avanzar requiere theta negativa.
%
%   comando.yaw
%       -1 a +1
%       Genera una referencia de velocidad angular r.
%
% Salida:
%
%   momentoDeseado_B_Nm = [Mx; My; Mz]

    %% Validaciones

    if ~isscalar(dt) || ~isfinite(dt) || dt <= 0

        error( ...
            'controlador_actitud:PasoInvalido', ...
            'dt debe ser positivo y finito.' ...
        );

    end

    x = x(:);

    if numel(x) ~= modelo.numeroEstados

        error( ...
            'controlador_actitud:EstadoInvalido', ...
            'El vector de estados debe contener 12 elementos.' ...
        );

    end

    camposRequeridos = { ...
        'roll', ...
        'pitch', ...
        'yaw', ...
        'armado' ...
    };

    for k = 1:numel(camposRequeridos)

        if ~isfield(comando, camposRequeridos{k})

            error( ...
                'controlador_actitud:ComandoIncompleto', ...
                'Falta el campo comando.%s.', ...
                camposRequeridos{k} ...
            );

        end

    end

    %% Inicializar memoria del controlador

    if isempty(estadoControl) || ~isstruct(estadoControl)

        estadoControl.integralRoll = 0;
        estadoControl.integralPitch = 0;
        estadoControl.integralYaw = 0;

    end

    %% Si está desarmado

    if ~comando.armado

        estadoControl.integralRoll = 0;
        estadoControl.integralPitch = 0;
        estadoControl.integralYaw = 0;

        momentoDeseado_B_Nm = zeros(3, 1);

        D.referencia.phi_rad = 0;
        D.referencia.theta_rad = 0;
        D.referencia.r_rad_s = 0;

        D.error.roll_rad = 0;
        D.error.pitch_rad = 0;
        D.error.yawRate_rad_s = 0;

        D.momentoSinSaturar_B_Nm = zeros(3, 1);
        D.momentoSaturado_B_Nm = zeros(3, 1);

        return;

    end

    %% Estados actuales

    phi = x(modelo.idx.phi);
    theta = x(modelo.idx.theta);

    p = x(modelo.idx.p);
    q = x(modelo.idx.q);
    r = x(modelo.idx.r);

    %% Referencias

    phiReferencia = ...
        comando.roll * ...
        C.limites.anguloRollMax_rad;

    % Pitch positivo en el teclado significa avanzar.
    % Para avanzar, la nariz debe bajar:
    thetaReferencia = ...
        -comando.pitch * ...
        C.limites.anguloPitchMax_rad;

    rReferencia = ...
        comando.yaw * ...
        C.limites.velocidadYawMax_rad_s;

    %% Errores

    errorRoll = ...
        phiReferencia - phi;

    errorPitch = ...
        thetaReferencia - theta;

    errorYawRate = ...
        rReferencia - r;

    %% Control de roll

    [momentoRoll, integralRoll, momentoRollSinSaturar] = ...
        calcular_pid_saturado( ...
            errorRoll, ...
            p, ...
            estadoControl.integralRoll, ...
            dt, ...
            C.roll, ...
            C.limites.integralRollMax, ...
            C.limites.momentoRollMax_Nm ...
        );

    %% Control de pitch

    [momentoPitch, integralPitch, momentoPitchSinSaturar] = ...
        calcular_pid_saturado( ...
            errorPitch, ...
            q, ...
            estadoControl.integralPitch, ...
            dt, ...
            C.pitch, ...
            C.limites.integralPitchMax, ...
            C.limites.momentoPitchMax_Nm ...
        );

    %% Control de velocidad de yaw

    [momentoYaw, integralYaw, momentoYawSinSaturar] = ...
        calcular_pid_saturado( ...
            errorYawRate, ...
            0, ...
            estadoControl.integralYaw, ...
            dt, ...
            C.yaw, ...
            C.limites.integralYawMax, ...
            C.limites.momentoYawMax_Nm ...
        );

    %% Guardar memoria

    estadoControl.integralRoll = integralRoll;
    estadoControl.integralPitch = integralPitch;
    estadoControl.integralYaw = integralYaw;

    %% Salida

    momentoDeseado_B_Nm = [
        momentoRoll
        momentoPitch
        momentoYaw
    ];

    %% Diagnóstico

    D.referencia.phi_rad = phiReferencia;
    D.referencia.theta_rad = thetaReferencia;
    D.referencia.r_rad_s = rReferencia;

    D.error.roll_rad = errorRoll;
    D.error.pitch_rad = errorPitch;
    D.error.yawRate_rad_s = errorYawRate;

    D.momentoSinSaturar_B_Nm = [
        momentoRollSinSaturar
        momentoPitchSinSaturar
        momentoYawSinSaturar
    ];

    D.momentoSaturado_B_Nm = ...
        momentoDeseado_B_Nm;

    D.integrales = [
        integralRoll
        integralPitch
        integralYaw
    ];

end


function [salida, integralNueva, salidaSinSaturar] = ...
    calcular_pid_saturado( ...
        error, velocidadMedida, integralAnterior, ...
        dt, ganancias, limiteIntegral, limiteSalida)
%CALCULAR_PID_SATURADO PID con saturación y anti-windup sencillo.

    %% Integral candidata

    integralCandidata = ...
        integralAnterior + error * dt;

    integralCandidata = max( ...
        -limiteIntegral, ...
        min(limiteIntegral, integralCandidata) ...
    );

    %% Salida candidata

    salidaSinSaturar = ...
        ganancias.Kp * error + ...
        ganancias.Ki * integralCandidata - ...
        ganancias.Kd * velocidadMedida;

    salida = max( ...
        -limiteSalida, ...
        min(limiteSalida, salidaSinSaturar) ...
    );

    %% Anti-windup

    huboSaturacion = ...
        abs(salida - salidaSinSaturar) > 1e-12;

    empujaContraLimite = ...
        sign(error) == sign(salidaSinSaturar);

    if huboSaturacion && empujaContraLimite

        integralNueva = integralAnterior;

        salidaSinSaturar = ...
            ganancias.Kp * error + ...
            ganancias.Ki * integralNueva - ...
            ganancias.Kd * velocidadMedida;

        salida = max( ...
            -limiteSalida, ...
            min(limiteSalida, salidaSinSaturar) ...
        );

    else

        integralNueva = integralCandidata;

    end

end