%% TEST_PASO_RK4_CAIDA_LIBRE
% Verifica el integrador RK4 mediante una caída libre.
%
% Estados:
%   estado(1) = zD, posición positiva hacia abajo [m]
%   estado(2) = w, velocidad positiva hacia abajo [m/s]

clearvars;
clc;
close all;

%% Parámetros

g = 9.80665;

dt = 0.01;

tiempoFinal = 1.0;

numeroPasos = round(tiempoFinal / dt);

%% Estado inicial

% Parte desde reposo en zD = 0.
estado = [ ...
    0.0;
    0.0 ...
];

tiempo = 0.0;

%% Historial

historialTiempo = zeros(numeroPasos + 1, 1);

historialEstado = zeros(numeroPasos + 1, 2);

historialTiempo(1) = tiempo;

historialEstado(1, :) = estado.';

%% Integración

for paso = 1:numeroPasos

    estado = paso_rk4( ...
        @dinamica_caida_libre, ...
        tiempo, ...
        estado, ...
        dt, ...
        g ...
    );

    tiempo = tiempo + dt;

    historialTiempo(paso + 1) = tiempo;

    historialEstado(paso + 1, :) = estado.';

end

%% Resultados numéricos

zD_RK4 = estado(1);

w_RK4 = estado(2);

%% Resultados analíticos

zD_Analitico = 0.5 * g * tiempoFinal^2;

w_Analitico = g * tiempoFinal;

%% Errores

errorPosicion = abs(zD_RK4 - zD_Analitico);

errorVelocidad = abs(w_RK4 - w_Analitico);

%% Mostrar resultados

fprintf('\n========================================\n');
fprintf(' PRUEBA RK4: CAIDA LIBRE\n');
fprintf('========================================\n\n');

fprintf('Tiempo final: %.3f s\n\n', tiempoFinal);

fprintf('Resultado RK4:\n');
fprintf('  zD = %.9f m\n', zD_RK4);
fprintf('  w  = %.9f m/s\n\n', w_RK4);

fprintf('Resultado analitico:\n');
fprintf('  zD = %.9f m\n', zD_Analitico);
fprintf('  w  = %.9f m/s\n\n', w_Analitico);

fprintf('Errores:\n');
fprintf('  posicion  = %.3e\n', errorPosicion);
fprintf('  velocidad = %.3e\n\n', errorVelocidad);

%% Verificación automática

tolerancia = 1e-9;

assert( ...
    errorPosicion < tolerancia, ...
    'La posición calculada por RK4 es incorrecta.' ...
);

assert( ...
    errorVelocidad < tolerancia, ...
    'La velocidad calculada por RK4 es incorrecta.' ...
);

fprintf('PRUEBA APROBADA\n');
fprintf('El integrador RK4 funciona correctamente.\n');
fprintf('========================================\n\n');

%% Gráfica

figure( ...
    'Name', 'Validación RK4 - Caída libre', ...
    'NumberTitle', 'off', ...
    'Color', 'white' ...
);

plot( ...
    historialTiempo, ...
    historialEstado(:, 1), ...
    'LineWidth', 2 ...
);

hold on;

plot( ...
    historialTiempo, ...
    0.5 * g * historialTiempo.^2, ...
    '--', ...
    'LineWidth', 1.5 ...
);

grid on;

xlabel('Tiempo [s]');
ylabel('z_D [m]');

title('Caída libre integrada mediante RK4');

legend( ...
    'Resultado RK4', ...
    'Solución analítica', ...
    'Location', 'northwest' ...
);

%% Función dinámica local

function derivada = dinamica_caida_libre(~, estado, g)
%DINAMICA_CAIDA_LIBRE Ecuaciones de movimiento en caída libre.

    w = estado(2);

    derivada = [ ...
        w;
        g ...
    ];

end