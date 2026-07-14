%% TEST_CINEMATICA_6DOF
% Verifica la matriz de rotación y la transformación angular.

clearvars;
clc;

fprintf("============================================\n");
fprintf("       PRUEBAS DE CINEMÁTICA 6DOF\n");
fprintf("============================================\n\n");

modelo = definicion_modelo();

tolerancia = 1e-10;


%% PRUEBA 1
% Con orientación nula, los marcos corporal e inercial coinciden.

x = zeros(modelo.numeroEstados, 1);

x(modelo.idx.u) = 1.0;
x(modelo.idx.v) = 2.0;
x(modelo.idx.w) = 3.0;

K = cinematica_6dof(x, modelo);

velocidadEsperada = [
    1
    2
    3
];

assert( ...
    norm(K.posicionDot_N - velocidadEsperada) < tolerancia, ...
    "Prueba 1 falló: la velocidad no coincide con orientación nula." ...
);

assert( ...
    norm(K.R_BN - eye(3), "fro") < tolerancia, ...
    "Prueba 1 falló: R_BN debería ser la matriz identidad." ...
);

fprintf("Prueba 1 aprobada: orientación nula.\n");


%% PRUEBA 2
% Con yaw de +90 grados, avanzar en +X_B debe producir movimiento
% en +Y_E del marco NED.

x = zeros(modelo.numeroEstados, 1);

x(modelo.idx.u) = 1.0;
x(modelo.idx.psi) = deg2rad(90);

K = cinematica_6dof(x, modelo);

velocidadEsperada = [
    0
    1
    0
];

assert( ...
    norm(K.posicionDot_N - velocidadEsperada) < tolerancia, ...
    "Prueba 2 falló: transformación incorrecta para yaw de 90 grados." ...
);

fprintf("Prueba 2 aprobada: yaw de +90 grados.\n");


%% PRUEBA 3
% Con orientación nula, p, q y r deben coincidir directamente con
% phi_dot, theta_dot y psi_dot.

x = zeros(modelo.numeroEstados, 1);

x(modelo.idx.p) = 0.5;
x(modelo.idx.q) = -0.3;
x(modelo.idx.r) = 0.2;

K = cinematica_6dof(x, modelo);

eulerDotEsperado = [
     0.5
    -0.3
     0.2
];

assert( ...
    norm(K.eulerDot - eulerDotEsperado) < tolerancia, ...
    "Prueba 3 falló: conversión angular incorrecta." ...
);

fprintf("Prueba 3 aprobada: velocidades angulares con actitud nula.\n");


%% PRUEBA 4
% La matriz de rotación debe ser ortogonal:
%
% R * R' = I

x = zeros(modelo.numeroEstados, 1);

x(modelo.idx.phi) = deg2rad(20);
x(modelo.idx.theta) = deg2rad(-15);
x(modelo.idx.psi) = deg2rad(40);

K = cinematica_6dof(x, modelo);

errorOrtogonalidad = ...
    norm(K.R_BN * K.R_BN.' - eye(3), "fro");

assert( ...
    errorOrtogonalidad < tolerancia, ...
    "Prueba 4 falló: la matriz de rotación no es ortogonal." ...
);

fprintf("Prueba 4 aprobada: ortogonalidad de R_BN.\n");


%% PRUEBA 5
% El determinante de una matriz de rotación propia debe ser +1.

determinante = det(K.R_BN);

assert( ...
    abs(determinante - 1) < tolerancia, ...
    "Prueba 5 falló: el determinante de R_BN no es igual a +1." ...
);

fprintf("Prueba 5 aprobada: determinante de R_BN igual a +1.\n");


%% RESULTADO FINAL

fprintf("\n============================================\n");
fprintf(" TODAS LAS PRUEBAS DE CINEMÁTICA APROBARON\n");
fprintf("============================================\n");