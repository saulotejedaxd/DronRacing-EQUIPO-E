function modelo = definicion_modelo()
%DEFINICION_MODELO Define las convenciones generales del modelo del dron.
%
% Salida:
%   modelo - Estructura con marcos de referencia, unidades, nombres
%            e índices del vector de estados.

    %% Convenciones generales

    modelo.sistemaUnidades = "SI";
    modelo.marcoInercial   = "NED";
    modelo.marcoCuerpo     = "FRD";
    modelo.secuenciaEuler  = "ZYX";

    %% Vector de estados

    modelo.numeroEstados = 12;

    modelo.nombresEstados = [
        "x_N"
        "y_E"
        "z_D"
        "u"
        "v"
        "w"
        "phi"
        "theta"
        "psi"
        "p"
        "q"
        "r"
    ];

    modelo.descripcionEstados = [
        "Posición frontal respecto al origen"
        "Posición lateral derecha respecto al origen"
        "Posición vertical positiva hacia abajo"
        "Velocidad longitudinal en el cuerpo"
        "Velocidad lateral en el cuerpo"
        "Velocidad vertical positiva hacia abajo"
        "Ángulo de roll"
        "Ángulo de pitch"
        "Ángulo de yaw"
        "Velocidad angular de roll"
        "Velocidad angular de pitch"
        "Velocidad angular de yaw"
    ];

    modelo.unidadesEstados = [
        "m"
        "m"
        "m"
        "m/s"
        "m/s"
        "m/s"
        "rad"
        "rad"
        "rad"
        "rad/s"
        "rad/s"
        "rad/s"
    ];

    %% Índices para acceder a los estados sin usar números sueltos

    modelo.idx.xN    = 1;
    modelo.idx.yE    = 2;
    modelo.idx.zD    = 3;

    modelo.idx.u     = 4;
    modelo.idx.v     = 5;
    modelo.idx.w     = 6;

    modelo.idx.phi   = 7;
    modelo.idx.theta = 8;
    modelo.idx.psi   = 9;

    modelo.idx.p     = 10;
    modelo.idx.q     = 11;
    modelo.idx.r     = 12;

end