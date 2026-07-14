%% TEST_DINAMICA_TRASLACIONAL
% Comprueba gravedad, hover, perturbaciones lineales y términos
% asociados al movimiento del marco corporal.

clearvars;
clc;

fprintf("================================================\n");
fprintf("       PRUEBAS DE DINÁMICA TRASLACIONAL\n");
fprintf("================================================\n\n");

modelo = definicion_modelo();

P = parametros_fisicos();
R = reglas_competencia();
C = parametros_diseno();

[P, C, casoBase] = caso_base_teorico(P, C, R);

tolerancia = 1e-10;

masa = P.cuerpo.masa;
g = P.entorno.g;

fuerzaExternaCero = zeros(3, 1);


%% PRUEBA 1
% Caída libre con el dron nivelado y sin empuje.
%
% Como +Z_B apunta hacia abajo:
%
% u_dot = 0
% v_dot = 0
% w_dot = +g

x = zeros(modelo.numeroEstados, 1);

empujeMotores = zeros(4, 1);

D = dinamica_traslacional( ...
    x, ...
    empujeMotores, ...
    fuerzaExternaCero, ...
    P, ...
    modelo ...
);

aceleracionEsperada = [
    0
    0
    g
];

assert( ...
    norm(D.velocidadDot_B - aceleracionEsperada) < tolerancia, ...
    "Prueba 1 falló: aceleración incorrecta en caída libre." ...
);

fprintf("Prueba 1 aprobada: caída libre nivelada.\n");


%% PRUEBA 2
% Hover ideal.
%
% El empuje total debe ser exactamente igual al peso.

x = zeros(modelo.numeroEstados, 1);

empujeHoverPorMotor = masa * g / 4;

empujeMotores = ...
    empujeHoverPorMotor * ones(4, 1);

D = dinamica_traslacional( ...
    x, ...
    empujeMotores, ...
    fuerzaExternaCero, ...
    P, ...
    modelo ...
);

aceleracionEsperada = zeros(3, 1);

assert( ...
    norm(D.velocidadDot_B - aceleracionEsperada) < tolerancia, ...
    "Prueba 2 falló: el dron no permanece en hover ideal." ...
);

fprintf("Prueba 2 aprobada: hover ideal.\n");


%% PRUEBA 3
% Fuerza horizontal externa en +X_B.
%
% Con una masa de 1 kg y una fuerza de 2 N:
%
% u_dot = 2 m/s^2

x = zeros(modelo.numeroEstados, 1);

empujeMotores = ...
    empujeHoverPorMotor * ones(4, 1);

fuerzaExterna_B = [
    2
    0
    0
];

D = dinamica_traslacional( ...
    x, ...
    empujeMotores, ...
    fuerzaExterna_B, ...
    P, ...
    modelo ...
);

aceleracionEsperada = [
    2 / masa
    0
    0
];

assert( ...
    norm(D.velocidadDot_B - aceleracionEsperada) < tolerancia, ...
    "Prueba 3 falló: respuesta incorrecta a la fuerza externa." ...
);

fprintf("Prueba 3 aprobada: fuerza externa horizontal.\n");


%% PRUEBA 4
% Acoplamiento debido al marco corporal giratorio.
%
% omega = [0; 0; 1] rad/s
% v_B   = [1; 0; 0] m/s
%
% omega x v = [0; 1; 0]
%
% Por tanto:
%
% v_dot = -omega x v = [0; -1; 0]

x = zeros(modelo.numeroEstados, 1);

x(modelo.idx.u) = 1;
x(modelo.idx.r) = 1;

empujeMotores = ...
    empujeHoverPorMotor * ones(4, 1);

D = dinamica_traslacional( ...
    x, ...
    empujeMotores, ...
    fuerzaExternaCero, ...
    P, ...
    modelo ...
);

aceleracionEsperada = [
     0
    -1
     0
];

assert( ...
    norm(D.velocidadDot_B - aceleracionEsperada) < tolerancia, ...
    "Prueba 4 falló: término del marco giratorio incorrecto." ...
);

fprintf("Prueba 4 aprobada: acoplamiento del marco corporal.\n");


%% PRUEBA 5
% Proyección de la gravedad con pitch positivo.
%
% Para phi = 0 y psi = 0:
%
% Fg_B / m = [-g*sin(theta); 0; g*cos(theta)]

x = zeros(modelo.numeroEstados, 1);

theta = deg2rad(30);

x(modelo.idx.theta) = theta;

empujeMotores = zeros(4, 1);

D = dinamica_traslacional( ...
    x, ...
    empujeMotores, ...
    fuerzaExternaCero, ...
    P, ...
    modelo ...
);

aceleracionEsperada = [
    -g * sin(theta)
     0
     g * cos(theta)
];

assert( ...
    norm(D.velocidadDot_B - aceleracionEsperada) < tolerancia, ...
    "Prueba 5 falló: proyección incorrecta de la gravedad." ...
);

fprintf("Prueba 5 aprobada: gravedad con pitch de +30 grados.\n");


%% PRUEBA 6
% Verificar que las fuerzas del hover se cancelen numéricamente.

x = zeros(modelo.numeroEstados, 1);

empujeMotores = ...
    empujeHoverPorMotor * ones(4, 1);

D = dinamica_traslacional( ...
    x, ...
    empujeMotores, ...
    fuerzaExternaCero, ...
    P, ...
    modelo ...
);

assert( ...
    abs(D.empujeTotal_N - masa*g) < tolerancia, ...
    "Prueba 6 falló: el empuje total no coincide con el peso." ...
);

assert( ...
    norm(D.fuerzaTotal_B_N) < tolerancia, ...
    "Prueba 6 falló: la fuerza total del hover no es cero." ...
);

fprintf("Prueba 6 aprobada: equilibrio de fuerzas en hover.\n");


%% RESULTADO FINAL

fprintf("\n================================================\n");
fprintf(" TODAS LAS PRUEBAS TRASLACIONALES APROBARON\n");
fprintf("================================================\n");