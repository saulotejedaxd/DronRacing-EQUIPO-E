function E = perturbacion_pulso_actitud( ...
    t, eje, amplitud_Nm, tiempoInicio_s, duracion_s)
%PERTURBACION_PULSO_ACTITUD Genera un pulso de momento externo.
%
% La perturbación se aplica sobre uno de los ejes de actitud:
%
%   roll  -> momento alrededor del eje X_B
%   pitch -> momento alrededor del eje Y_B
%   yaw   -> momento alrededor del eje Z_B
%
% Entradas:
%
%   t
%       Tiempo actual de simulación [s].
%
%   eje
%       Eje donde se aplicará la perturbación:
%       "roll", "pitch" o "yaw".
%
%   amplitud_Nm
%       Magnitud del momento externo [N*m].
%       Puede ser positiva o negativa.
%
%   tiempoInicio_s
%       Instante en el que comienza la perturbación [s].
%
%   duracion_s
%       Duración del pulso [s].
%
% Salida:
%
%   E
%       Estructura compatible con
%       modelo_no_lineal_12_estados:
%
%       E.fuerzaExterna_B_N
%       E.momentoExterno_B_Nm
%
% Ejemplo:
%
%   E = perturbacion_pulso_actitud( ...
%       t, "roll", 0.08, 2.0, 0.2);
%
% En ese ejemplo se aplica un momento externo de 0.08 N*m
% en roll desde t = 2.0 s hasta t = 2.2 s.

    %% Validar tiempo actual

    if ~isscalar(t) || ~isfinite(t)

        error( ...
            "perturbacion_pulso_actitud:TiempoInvalido", ...
            "El tiempo t debe ser un escalar finito." ...
        );

    end

    %% Validar amplitud

    if ~isscalar(amplitud_Nm) || ~isfinite(amplitud_Nm)

        error( ...
            "perturbacion_pulso_actitud:AmplitudInvalida", ...
            "La amplitud debe ser un escalar finito." ...
        );

    end

    %% Validar tiempo de inicio

    if ~isscalar(tiempoInicio_s) || ...
            ~isfinite(tiempoInicio_s) || ...
            tiempoInicio_s < 0

        error( ...
            "perturbacion_pulso_actitud:InicioInvalido", ...
            "El tiempo de inicio debe ser finito y mayor o igual que cero." ...
        );

    end

    %% Validar duración

    if ~isscalar(duracion_s) || ...
            ~isfinite(duracion_s) || ...
            duracion_s <= 0

        error( ...
            "perturbacion_pulso_actitud:DuracionInvalida", ...
            "La duración debe ser positiva y finita." ...
        );

    end

    %% Validar eje solicitado

    eje = lower(string(eje));

    if ~isscalar(eje)

        error( ...
            "perturbacion_pulso_actitud:EjeInvalido", ...
            "El eje debe ser roll, pitch o yaw." ...
        );

    end

    ejesValidos = [
        "roll"
        "pitch"
        "yaw"
    ];

    if ~any(eje == ejesValidos)

        error( ...
            "perturbacion_pulso_actitud:EjeDesconocido", ...
            "El eje debe ser roll, pitch o yaw." ...
        );

    end

    %% Inicializar perturbación en cero

    E = perturbacion_nula();

    %% Determinar si el pulso está activo

    tiempoFinal_s = ...
        tiempoInicio_s + duracion_s;

    pulsoActivo = ...
        t >= tiempoInicio_s && ...
        t < tiempoFinal_s;

    if ~pulsoActivo

        return;

    end

    %% Aplicar el momento al eje solicitado

    switch eje

        case "roll"

            E.momentoExterno_B_Nm(1) = ...
                amplitud_Nm;

        case "pitch"

            E.momentoExterno_B_Nm(2) = ...
                amplitud_Nm;

        case "yaw"

            E.momentoExterno_B_Nm(3) = ...
                amplitud_Nm;

    end

end