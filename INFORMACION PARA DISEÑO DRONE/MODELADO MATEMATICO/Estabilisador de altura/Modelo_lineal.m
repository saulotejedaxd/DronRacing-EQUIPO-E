%---------------------------------------------------------
% MODELO LINEAL DEL DRON EN ESPACIO DE ESTADOS
% Estabilización de altura
%---------------------------------------------------------

clc         % Limpia la ventana de comandos
clear       % Borra todas las variables
close all   % Cierra todas las figuras

%% Parámetros físicos

m = 1.2;        % Masa del dron (kg)
g = 9.81;       % Aceleración de la gravedad (m/s²)

%% Matriz de estados (A)

% x1 = altura
% x2 = velocidad vertical

A = [0 1;
     0 0];

%% Matriz de entrada (B)

% La entrada del sistema es la variación del empuje

B = [0;
     1/m];

%% Matriz de salida (C)

% Se toma como salida únicamente la altura

C = [1 0];

%% Matriz de transmisión directa (D)

D = 0;

%% Creación del modelo en espacio de estados

sistema = ss(A,B,C,D);

%% Mostrar el modelo

disp('Modelo en espacio de estados:')

sistema

%% Obtener la función de transferencia

disp('Función de transferencia:')

tf(sistema)