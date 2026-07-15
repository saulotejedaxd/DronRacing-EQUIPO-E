%---------------------------------------------------------
% SIMULACIÓN DEL MODELO LINEAL DEL DRON
% Respuesta ante una entrada constante
%---------------------------------------------------------

clc         % Limpia la consola
clear       % Borra variables
close all   % Cierra figuras

%% Parámetros físicos

m = 1.2;        % Masa del dron (kg)

%% Matriz de estados

A = [0 1;
     0 0];

%% Matriz de entrada

B = [0;
     1/m];

%% Matriz de salida

C = [1 0];

%% Matriz de transmisión directa

D = 0;

%% Crear el sistema lineal

sys = ss(A,B,C,D);

%% Tiempo de simulación

t = 0:0.01:10;

%% Entrada del sistema

% Se aplica una entrada tipo escalón de amplitud 1

u = ones(size(t));

%% Simulación del comportamiento del sistema

figure

lsim(sys,u,t)

%% Personalización de la gráfica

grid on

title('Respuesta del Modelo Lineal del Dron')

xlabel('Tiempo (s)')

ylabel('Altura (m)')