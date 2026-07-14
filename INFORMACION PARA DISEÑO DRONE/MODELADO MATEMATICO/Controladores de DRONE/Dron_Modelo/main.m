%% MAIN - Simulador numérico del dron
%
% Este archivo coordina la configuración general del proyecto.
% Las ecuaciones, validaciones y reportes permanecen separados
% en sus carpetas correspondientes.

clearvars;
clc;
close all;

%% 1. Definición matemática y estados iniciales

modelo = definicion_modelo();
x0 = condiciones_iniciales(modelo);

%% 2. Parámetros físicos iniciales

P = parametros_fisicos();

%% 3. Restricciones y requisitos del proyecto

R = reglas_competencia();
D = requisitos_proyecto(R);
C = parametros_diseno();

%% 4. Caso base numérico provisional

%% 4. Caso base numérico provisional

[P, C, casoBase] = caso_base_teorico(P, C, R);
%% 5. Configuración geométrica de motores

G = configuracion_motores_x( ...
    R, ...
    D, ...
    C.geometria.distanciaCentroMotor, ...
    C.geometria.zMotor_B ...
);

reporteGeometria = ...
    validar_configuracion_motores_x(G, R, D);

P = aplicar_configuracion_motores(P, G);

%% 6. Presupuesto de masa

B = presupuesto_masa();

reporteMasa = evaluar_presupuesto_masa(B, R);

P = aplicar_presupuesto_masa(P, reporteMasa);

%% 7. Validación física general

reporteParametros = validar_parametros_fisicos(P);

%% 8. Presentación del estado actual

imprimir_resumen_configuracion( ...
    modelo, ...
    x0, ...
    P, ...
    R, ...
    D, ...
    C, ...
    G, ...
    B, ...
    reporteGeometria, ...
    reporteMasa, ...
    reporteParametros ...
);

imprimir_caso_base(casoBase);