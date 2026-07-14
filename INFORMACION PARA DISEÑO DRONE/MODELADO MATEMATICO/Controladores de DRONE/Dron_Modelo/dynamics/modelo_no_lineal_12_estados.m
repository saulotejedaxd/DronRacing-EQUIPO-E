function [dx, S] = modelo_no_lineal_12_estados( ...
    t, x, U, E, P, modelo)
%MODELO_NO_LINEAL_12_ESTADOS Modelo dinámico completo del dron.
%
% Calcula:
%
%   dx = f(t, x, U, E, P)
%
% Vector de estados:
%
%   x = [
%       x_N
%       y_E
%       z_D
%       u
%       v
%       w
%       phi
%       theta
%       psi
%       p
%       q
%       r
%   ]
%
% Entradas:
%
%   t
%       Tiempo actual de simulación [s].
%
%   x
%       Vector de 12 estados.
%
%   U
%       Entrada de actuadores:
%       U.empujeMotores_N
%       U.torqueReaccionMotores_Nm
%
%   E
%       Perturbaciones externas:
%       E.fuerzaExterna_B_N
%       E.momentoExterno_B_Nm
%
%   P
%       Parámetros físicos del dron.
%
%   modelo
%       Definición e índices del vector de estados.
%
% Salidas:
%
%   dx
%       Derivada del vector de 12 estados.
%
%   S
%       Información interna de diagnóstico. Es opcional.

    %% Validación del tiempo

    if ~isscalar(t) || ~isfinite(t)

        error( ...
            "modelo_no_lineal_12_estados:TiempoInvalido", ...
            "El tiempo debe ser un escalar finito." ...
        );

    end

    %% Validación del vector de estados

    if numel(x) ~= modelo.numeroEstados

        error( ...
            "modelo_no_lineal_12_estados:NumeroEstadosInvalido", ...
            "El vector x debe contener exactamente %d estados.", ...
            modelo.numeroEstados ...
        );

    end

    x = x(:);

    if any(~isfinite(x))

        error( ...
            "modelo_no_lineal_12_estados:EstadosNoFinitos", ...
            "El vector de estados contiene NaN o valores infinitos." ...
        );

    end

    %% Validación básica de la entrada de actuadores

    if ~isstruct(U)

        error( ...
            "modelo_no_lineal_12_estados:EntradaInvalida", ...
            "La entrada U debe ser una estructura." ...
        );

    end

    if ~isfield(U, "empujeMotores_N")

        error( ...
            "modelo_no_lineal_12_estados:FaltaEmpuje", ...
            "U debe contener el campo empujeMotores_N." ...
        );

    end

    if ~isfield(U, "torqueReaccionMotores_Nm")

        error( ...
            "modelo_no_lineal_12_estados:FaltaTorque", ...
            "U debe contener torqueReaccionMotores_Nm." ...
        );

    end

    %% Validación básica de perturbaciones

    if ~isstruct(E)

        error( ...
            "modelo_no_lineal_12_estados:PerturbacionInvalida", ...
            "La perturbación E debe ser una estructura." ...
        );

    end

    if ~isfield(E, "fuerzaExterna_B_N")

        error( ...
            "modelo_no_lineal_12_estados:FaltaFuerzaExterna", ...
            "E debe contener fuerzaExterna_B_N." ...
        );

    end

    if ~isfield(E, "momentoExterno_B_Nm")

        error( ...
            "modelo_no_lineal_12_estados:FaltaMomentoExterno", ...
            "E debe contener momentoExterno_B_Nm." ...
        );

    end

    %% Cinemática

    K = cinematica_6dof(x, modelo);

    %% Dinámica traslacional

    DT = dinamica_traslacional( ...
        x, ...
        U.empujeMotores_N, ...
        E.fuerzaExterna_B_N, ...
        P, ...
        modelo ...
    );

    %% Dinámica rotacional

    DR = dinamica_rotacional( ...
        x, ...
        U.empujeMotores_N, ...
        U.torqueReaccionMotores_Nm, ...
        E.momentoExterno_B_Nm, ...
        P, ...
        modelo ...
    );

    %% Ensamble del vector de derivadas

    dx = zeros(modelo.numeroEstados, 1);

    % Derivadas de posición en el marco inercial NED.

    dx([
        modelo.idx.xN
        modelo.idx.yE
        modelo.idx.zD
    ]) = K.posicionDot_N;

    % Derivadas de velocidades lineales en el marco corporal.

    dx([
        modelo.idx.u
        modelo.idx.v
        modelo.idx.w
    ]) = DT.velocidadDot_B;

    % Derivadas de los ángulos de Euler.

    dx([
        modelo.idx.phi
        modelo.idx.theta
        modelo.idx.psi
    ]) = K.eulerDot;

    % Derivadas de las velocidades angulares corporales.

    dx([
        modelo.idx.p
        modelo.idx.q
        modelo.idx.r
    ]) = DR.velocidadAngularDot_B;

    %% Diagnóstico opcional

    if nargout > 1

        S.tiempo_s = t;
        S.estado = x;
        S.derivadaEstado = dx;

        S.cinematica = K;
        S.dinamicaTraslacional = DT;
        S.dinamicaRotacional = DR;

        S.entradaActuadores = U;
        S.perturbacion = E;

    end

end