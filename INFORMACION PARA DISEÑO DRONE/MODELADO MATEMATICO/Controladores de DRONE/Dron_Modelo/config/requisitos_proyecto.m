function D = requisitos_proyecto(R)
%REQUISITOS_PROYECTO Decisiones iniciales propias del proyecto.
%
% Entrada:
%   R - Restricciones generadas por reglas_competencia().
%
% Salida:
%   D - Requisitos y valores derivados del diseño propuesto.

    %% Configuración general

    D.tipo = "Cuadricóptero";
    D.configuracion = "X";
    D.numeroMotores = 4;

    %% Hélice seleccionada como objetivo inicial

    D.helice.diametroPulgadas = 5;
    D.helice.diametro = ...
        D.helice.diametroPulgadas * 0.0254;         % m

    D.helice.radio = D.helice.diametro / 2;         % m

    %% Geometría derivada para una X simétrica

    % Distancia máxima impuesta por el círculo reglamentario.
    D.geometria.distanciaCentroMotorMax = ...
        R.geometria.distanciaCentroMotorMax;        % m

    % Distancia mínima teórica para que los discos de hélices
    % adyacentes no se traslapen. No incluye holgura.
    D.geometria.distanciaCentroMotorMinTeorica = ...
        D.helice.diametro / sqrt(2);                % m

    D.geometria.separacionMotoresAdyacentesMin = ...
        D.helice.diametro;                          % m

    %% Caso límite de masa reglamentaria

    D.masa.casoLimite = R.masa.maxima;              % kg
    D.gravedadReferencia = 9.80665;                 % m/s^2

    D.empuje.hoverTotalCasoLimite = ...
        D.masa.casoLimite * D.gravedadReferencia;   % N

    D.empuje.hoverPorMotorCasoLimite = ...
        D.empuje.hoverTotalCasoLimite / ...
        D.numeroMotores;                            % N

    %% Verificación básica

    D.cumpleDiametroHelice = ...
        D.helice.diametro <= R.helices.diametroMax;

end