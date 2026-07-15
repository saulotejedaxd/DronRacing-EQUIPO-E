%---------------------------------------------------------
% CONTROL PID PARA LA ESTABILIZACIÓN DE ALTURA DE UN DRON
%---------------------------------------------------------

clc         % Limpia la ventana de comandos
clear       % Elimina todas las variables de la memoria
close all   % Cierra todas las ventanas de gráficas abiertas

%% Parámetros físicos del dron

m = 1.2;      % Masa del dron (kg)
g = 9.81;     % Aceleración de la gravedad (m/s^2)

%% Parámetros del controlador PID

Kp = 12;      % Ganancia proporcional
Ki = 2;       % Ganancia integral
Kd = 6;       % Ganancia derivativa

%% Configuración de la simulación

dt = 0.01;        % Paso de tiempo de la simulación (s)
t = 0:dt:40;      % Vector de tiempo (0 a 40 segundos)

%% Altura deseada

h_ref = 1;        % Altura objetivo (m)

%% Condiciones iniciales

h = 0;            % Altura inicial del dron (m)
v = 0;            % Velocidad vertical inicial (m/s)

%% Variables del controlador PID

integral = 0;     % Acumulador del término integral
error_ant = 0;    % Error de la iteración anterior

%% Vectores para almacenar resultados

altura = zeros(size(t));     % Guarda la altura en cada instante
empuje = zeros(size(t));     % Guarda el empuje aplicado

%% Inicio de la simulación

for i = 1:length(t)

    % Calcular el error entre la altura deseada y la altura actual
    error = h_ref - h;

    % Calcular el término integral del PID
    integral = integral + error*dt;

    % Calcular el término derivativo del PID
    derivada = (error - error_ant)/dt;

    % Calcular la señal de control del PID
    u = Kp*error + Ki*integral + Kd*derivada;

    % Calcular el empuje total necesario
    % mg mantiene el dron suspendido y u corrige el error
    T = m*g + u;

    % Evitar que el empuje sea negativo
    if T < 0
        T = 0;
    end

    % Modelo matemático del movimiento vertical
    % Segunda Ley de Newton:
    % m*a = T - mg
    a = (T - m*g)/m;

    % Actualizar la velocidad mediante integración numérica
    v = v + a*dt;

    % Actualizar la altura del dron
    h = h + v*dt;

    % Guardar resultados para las gráficas
    altura(i) = h;
    empuje(i) = T;

    % Guardar el error actual para la siguiente iteración
    error_ant = error;

end

%% Gráfica de la altura

figure
plot(t,altura,'b','LineWidth',2)
hold on

% Línea que representa la altura deseada
yline(h_ref,'r--')

xlabel('Tiempo (s)')
ylabel('Altura (m)')
title('Control de Altura del Dron')
grid on

%% Gráfica del empuje generado

figure
plot(t,empuje,'LineWidth',2)

xlabel('Tiempo (s)')
ylabel('Empuje (N)')
title('Empuje del Controlador')
grid on