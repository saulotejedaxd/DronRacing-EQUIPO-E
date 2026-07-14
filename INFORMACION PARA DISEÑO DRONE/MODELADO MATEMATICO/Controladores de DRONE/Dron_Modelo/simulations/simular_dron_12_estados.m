function R = simular_dron_12_estados( ...
    tiemposSalida, ...
    x0, ...
    entradaFcn, ...
    perturbacionFcn, ...
    P, ...
    modelo, ...
    opcionesODE)
%SIMULAR_DRON_12_ESTADOS Integra el modelo no lineal del dron.
%
% Entradas:
%   tiemposSalida
%       Vector de tiempos en segundos. Debe ser creciente.
%
%   x0
%       Vector inicial de 12 estados.
%
%   entradaFcn
%       Función de la forma:
%
%           U = entradaFcn(t, x)
%
%       Esto permitirá posteriormente conectar el PID.
%
%   perturbacionFcn
%       Función de la forma:
%
%           E = perturbacionFcn(t, x)
%
%       Esto permitirá generar ráfagas, golpes o momentos variables.
%
%   P
%       Parámetros físicos.
%
%   modelo
%       Definición del vector de estados.
%
%   opcionesODE
%       Opciones de integración creadas con odeset().
%       Es opcional.
%
% Salida:
%   R
%       Estructura con tiempos, estados y variables derivadas.

    %% Opciones predeterminadas

    if nargin < 7 || isempty(opcionesODE)

        opcionesODE = odeset( ...
            "RelTol", 1e-8, ...
            "AbsTol", 1e-10, ...
            "MaxStep", 0.01 ...
        );

    end

    %% Validación de tiempos

    tiemposSalida = tiemposSalida(:);

    if numel(tiemposSalida) < 2

        error( ...
            "simular_dron_12_estados:TiemposInsuficientes", ...
            "Se requieren por lo menos dos valores de tiempo." ...
        );

    end

    if any(~isfinite(tiemposSalida))

        error( ...
            "simular_dron_12_estados:TiemposNoFinitos", ...
            "El vector de tiempos contiene NaN o valores infinitos." ...
        );

    end

    if any(diff(tiemposSalida) <= 0)

        error( ...
            "simular_dron_12_estados:TiemposNoCrecientes", ...
            "Los tiempos deben estar ordenados de forma creciente." ...
        );

    end

    %% Validación del estado inicial

    x0 = x0(:);

    if numel(x0) ~= modelo.numeroEstados

        error( ...
            "simular_dron_12_estados:EstadoInicialInvalido", ...
            "x0 debe contener exactamente %d estados.", ...
            modelo.numeroEstados ...
        );

    end

    if any(~isfinite(x0))

        error( ...
            "simular_dron_12_estados:EstadoInicialNoFinito", ...
            "El estado inicial contiene NaN o valores infinitos." ...
        );

    end

    %% Validación de funciones de entrada

    if ~isa(entradaFcn, "function_handle")

        error( ...
            "simular_dron_12_estados:EntradaFcnInvalida", ...
            "entradaFcn debe ser una función anónima o function handle." ...
        );

    end

    if ~isa(perturbacionFcn, "function_handle")

        error( ...
            "simular_dron_12_estados:PerturbacionFcnInvalida", ...
            "perturbacionFcn debe ser una función anónima o function handle." ...
        );

    end

    %% Función diferencial para ode45

    funcionODE = @(t, x) modelo_no_lineal_12_estados( ...
        t, ...
        x, ...
        entradaFcn(t, x), ...
        perturbacionFcn(t, x), ...
        P, ...
        modelo ...
    );

    %% Integración temporal

    [t, x] = ode45( ...
        funcionODE, ...
        tiemposSalida, ...
        x0, ...
        opcionesODE ...
    );

    %% Resultados generales

    R.t_s = t;
    R.x = x;

    R.estadoInicial = x(1, :).';
    R.estadoFinal = x(end, :).';

    R.numeroMuestras = numel(t);
    R.tiempoInicial_s = t(1);
    R.tiempoFinal_s = t(end);

    %% Variables físicas útiles

    R.posicion_N_m = x(:, [
        modelo.idx.xN
        modelo.idx.yE
        modelo.idx.zD
    ]);

    R.velocidad_B_mps = x(:, [
        modelo.idx.u
        modelo.idx.v
        modelo.idx.w
    ]);

    R.euler_rad = x(:, [
        modelo.idx.phi
        modelo.idx.theta
        modelo.idx.psi
    ]);

    R.euler_deg = rad2deg(R.euler_rad);

    R.velocidadAngular_B_radps = x(:, [
        modelo.idx.p
        modelo.idx.q
        modelo.idx.r
    ]);

    % Debido a la convención NED:
    %
    % altura = -z_D

    R.altura_m = -x(:, modelo.idx.zD);

    %% Máximos absolutos

    R.maximos.desplazamientoX_m = ...
        max(abs(x(:, modelo.idx.xN)));

    R.maximos.desplazamientoY_m = ...
        max(abs(x(:, modelo.idx.yE)));

    R.maximos.alturaAbsoluta_m = ...
        max(abs(R.altura_m));

    R.maximos.roll_deg = ...
        max(abs(R.euler_deg(:, 1)));

    R.maximos.pitch_deg = ...
        max(abs(R.euler_deg(:, 2)));

    R.maximos.yaw_deg = ...
        max(abs(R.euler_deg(:, 3)));

end