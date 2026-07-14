function x0 = condiciones_iniciales(modelo)
%CONDICIONES_INICIALES Genera el vector inicial de estados.
%
% Entrada:
%   modelo - Definición general del modelo.
%
% Salida:
%   x0 - Vector columna de estados iniciales.

    x0 = zeros(modelo.numeroEstados, 1);

    %% Posición inicial respecto al punto de despegue

    x0(modelo.idx.xN) = 0;       % m
    x0(modelo.idx.yE) = 0;       % m
    x0(modelo.idx.zD) = 0;       % m

    %% Velocidades lineales iniciales

    x0(modelo.idx.u) = 0;        % m/s
    x0(modelo.idx.v) = 0;        % m/s
    x0(modelo.idx.w) = 0;        % m/s

    %% Orientación inicial

    x0(modelo.idx.phi)   = deg2rad(0);
    x0(modelo.idx.theta) = deg2rad(0);
    x0(modelo.idx.psi)   = deg2rad(0);

    %% Velocidades angulares iniciales

    x0(modelo.idx.p) = 0;        % rad/s
    x0(modelo.idx.q) = 0;        % rad/s
    x0(modelo.idx.r) = 0;        % rad/s

end