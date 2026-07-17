%% TEST_RK4_MODELO_12_ESTADOS
% Verifica que el integrador RK4 funcione correctamente con el
% modelo no lineal completo de 12 estados.
%
% Casos:
%   1. Caída libre durante 1 segundo.
%   2. Hover ideal durante 1 segundo.

clearvars;
clc;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf(' PRUEBA RK4 CON MODELO NO LINEAL DE 12 ESTADOS\n');
fprintf('============================================================\n\n');

%% ================================================================
%  PREPARACIÓN DEL CASO BASE
% ================================================================

modelo = definicion_modelo();

P = parametros_fisicos();

R = reglas_competencia();

Dproyecto = requisitos_proyecto(R);

C = parametros_diseno();

% Completar parámetros físicos y geométricos provisionales
% mediante el caso base teórico.
[P, C, ~] = caso_base_teorico( ...
    P, ...
    C, ...
    R ...
);

% Crear la geometría de los motores en configuración X.
G = configuracion_motores_x( ...
    R, ...
    Dproyecto, ...
    C.geometria.distanciaCentroMotor, ...
    C.geometria.zMotor_B ...
);

% Aplicar posiciones y sentidos de los motores.
P = aplicar_configuracion_motores( ...
    P, ...
    G ...
);

%% Parámetros principales

masa = P.cuerpo.masa;

g = P.entorno.g;

numeroMotores = P.motores.numero;

empujeHoverPorMotor = ...
    masa * g / numeroMotores;

%% ================================================================
%  CONFIGURACIÓN DE INTEGRACIÓN
% ================================================================

dt = 0.01;

tiempoFinal = 1.0;

numeroPasos = round( ...
    tiempoFinal / dt ...
);

vectorTiempo = ...
    (0:numeroPasos).' * dt;

%% Estado inicial común

estadoInicial = zeros( ...
    modelo.numeroEstados, ...
    1 ...
);

%% ================================================================
%  CASO 1: CAÍDA LIBRE
% ================================================================

fprintf('Ejecutando caso 1: caída libre...\n');

U_caida = crear_entrada_actuadores(P);

E_caida = perturbacion_nula();

% Motores completamente apagados.
U_caida.empujeMotores_N = ...
    zeros(numeroMotores, 1);

U_caida.torqueReaccionMotores_Nm = ...
    zeros(numeroMotores, 1);

estadoCaida = estadoInicial;

historialCaida = zeros( ...
    numeroPasos + 1, ...
    modelo.numeroEstados ...
);

historialCaida(1, :) = estadoCaida.';

tiempo = 0.0;

for paso = 1:numeroPasos

    estadoCaida = paso_rk4( ...
        @modelo_no_lineal_12_estados, ...
        tiempo, ...
        estadoCaida, ...
        dt, ...
        U_caida, ...
        E_caida, ...
        P, ...
        modelo ...
    );

    tiempo = tiempo + dt;

    historialCaida(paso + 1, :) = ...
        estadoCaida.';

end

%% Resultados numéricos

zD_RK4 = ...
    estadoCaida(modelo.idx.zD);

w_RK4 = ...
    estadoCaida(modelo.idx.w);

%% Resultados analíticos

zD_Analitico = ...
    0.5 * g * tiempoFinal^2;

w_Analitico = ...
    g * tiempoFinal;

%% Errores

errorCaidaPosicion = abs( ...
    zD_RK4 - zD_Analitico ...
);

errorCaidaVelocidad = abs( ...
    w_RK4 - w_Analitico ...
);

%% ================================================================
%  CASO 2: HOVER IDEAL
% ================================================================

fprintf('Ejecutando caso 2: hover ideal...\n\n');

U_hover = crear_entrada_actuadores(P);

E_hover = perturbacion_nula();

U_hover.empujeMotores_N = ...
    empujeHoverPorMotor * ...
    ones(numeroMotores, 1);

U_hover.torqueReaccionMotores_Nm = ...
    zeros(numeroMotores, 1);

estadoHover = estadoInicial;

historialHover = zeros( ...
    numeroPasos + 1, ...
    modelo.numeroEstados ...
);

historialHover(1, :) = estadoHover.';

tiempo = 0.0;

for paso = 1:numeroPasos

    estadoHover = paso_rk4( ...
        @modelo_no_lineal_12_estados, ...
        tiempo, ...
        estadoHover, ...
        dt, ...
        U_hover, ...
        E_hover, ...
        P, ...
        modelo ...
    );

    tiempo = tiempo + dt;

    historialHover(paso + 1, :) = ...
        estadoHover.';

end

errorHover = norm(estadoHover);

%% ================================================================
%  MOSTRAR RESULTADOS
% ================================================================

fprintf('------------------------------------------------------------\n');
fprintf(' PARÁMETROS DEL CASO BASE\n');
fprintf('------------------------------------------------------------\n\n');

fprintf('Masa:                   %.9f kg\n', masa);
fprintf('Gravedad:               %.9f m/s^2\n', g);
fprintf('Número de motores:      %d\n', numeroMotores);
fprintf('Paso RK4:               %.4f s\n', dt);
fprintf('Tiempo simulado:        %.2f s\n\n', tiempoFinal);

fprintf('------------------------------------------------------------\n');
fprintf(' CASO 1: CAÍDA LIBRE\n');
fprintf('------------------------------------------------------------\n\n');

fprintf('Resultado RK4:\n');
fprintf('  zD = %.9f m\n', zD_RK4);
fprintf('  w  = %.9f m/s\n\n', w_RK4);

fprintf('Resultado analítico:\n');
fprintf('  zD = %.9f m\n', zD_Analitico);
fprintf('  w  = %.9f m/s\n\n', w_Analitico);

fprintf('Errores:\n');
fprintf('  Posición:             %.3e\n', ...
    errorCaidaPosicion);

fprintf('  Velocidad:            %.3e\n\n', ...
    errorCaidaVelocidad);

fprintf('------------------------------------------------------------\n');
fprintf(' CASO 2: HOVER IDEAL\n');
fprintf('------------------------------------------------------------\n\n');

fprintf('Empuje total:           %.9f N\n', ...
    masa * g);

fprintf('Empuje por motor:       %.9f N\n\n', ...
    empujeHoverPorMotor);

fprintf('Estado final del hover:\n\n');

fprintf('  xN:                   % .3e m\n', ...
    estadoHover(modelo.idx.xN));

fprintf('  yE:                   % .3e m\n', ...
    estadoHover(modelo.idx.yE));

fprintf('  zD:                   % .3e m\n', ...
    estadoHover(modelo.idx.zD));

fprintf('  u:                    % .3e m/s\n', ...
    estadoHover(modelo.idx.u));

fprintf('  v:                    % .3e m/s\n', ...
    estadoHover(modelo.idx.v));

fprintf('  w:                    % .3e m/s\n', ...
    estadoHover(modelo.idx.w));

fprintf('  phi:                  % .3e rad\n', ...
    estadoHover(modelo.idx.phi));

fprintf('  theta:                % .3e rad\n', ...
    estadoHover(modelo.idx.theta));

fprintf('  psi:                  % .3e rad\n', ...
    estadoHover(modelo.idx.psi));

fprintf('  p:                    % .3e rad/s\n', ...
    estadoHover(modelo.idx.p));

fprintf('  q:                    % .3e rad/s\n', ...
    estadoHover(modelo.idx.q));

fprintf('  r:                    % .3e rad/s\n\n', ...
    estadoHover(modelo.idx.r));

fprintf('Norma del estado final: %.3e\n\n', ...
    errorHover);

%% ================================================================
%  VERIFICACIONES AUTOMÁTICAS
% ================================================================

toleranciaCaida = 1e-6;

toleranciaHover = 1e-8;

assert( ...
    errorCaidaPosicion < toleranciaCaida, ...
    ['RK4 no reproduce correctamente la posición ' ...
     'durante la caída libre.'] ...
);

assert( ...
    errorCaidaVelocidad < toleranciaCaida, ...
    ['RK4 no reproduce correctamente la velocidad ' ...
     'durante la caída libre.'] ...
);

assert( ...
    errorHover < toleranciaHover, ...
    ['El dron no permaneció en hover durante ' ...
     'la integración RK4.'] ...
);

fprintf('============================================================\n');
fprintf(' PRUEBA APROBADA\n');
fprintf(' RK4 FUNCIONA CON EL MODELO COMPLETO DE 12 ESTADOS\n');
fprintf('============================================================\n\n');

%% ================================================================
%  GRÁFICAS
% ================================================================

alturaCaida = ...
    -historialCaida(:, modelo.idx.zD);

alturaHover = ...
    -historialHover(:, modelo.idx.zD);

velocidadVerticalCaida = ...
    historialCaida(:, modelo.idx.w);

velocidadVerticalHover = ...
    historialHover(:, modelo.idx.w);

figure( ...
    'Name', 'RK4 con modelo completo de 12 estados', ...
    'NumberTitle', 'off', ...
    'Color', 'white' ...
);

tiledlayout(2, 1);

%% Altura

nexttile;

plot( ...
    vectorTiempo, ...
    alturaCaida, ...
    'LineWidth', 2 ...
);

hold on;

plot( ...
    vectorTiempo, ...
    alturaHover, ...
    '--', ...
    'LineWidth', 2 ...
);

grid on;

xlabel('Tiempo [s]');

ylabel('Altura [m]');

title('Movimiento vertical del modelo de 12 estados');

legend( ...
    'Caída libre', ...
    'Hover ideal', ...
    'Location', ...
    'southwest' ...
);

%% Velocidad vertical

nexttile;

plot( ...
    vectorTiempo, ...
    velocidadVerticalCaida, ...
    'LineWidth', 2 ...
);

hold on;

plot( ...
    vectorTiempo, ...
    velocidadVerticalHover, ...
    '--', ...
    'LineWidth', 2 ...
);

grid on;

xlabel('Tiempo [s]');

ylabel('w [m/s]');

title('Velocidad vertical en el marco Body-FRD');

legend( ...
    'Caída libre', ...
    'Hover ideal', ...
    'Location', ...
    'northwest' ...
);