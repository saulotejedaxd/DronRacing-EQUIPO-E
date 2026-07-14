function C = parametros_diseno()
%PARAMETROS_DISENO Variables geométricas propias del diseño.
%
% Los valores NaN indican que todavía no se dispone del dato.
% Aquí se sustituirán posteriormente los datos entregados por el
% encargado del diseño mecánico.

    C.meta.nombre  = "Configuración geométrica inicial";
    C.meta.version = "0.1";
    C.meta.estado  = "INCOMPLETO";

    %% Geometría principal

    % Distancia horizontal desde el centro de masa hasta el eje
    % de cualquiera de los cuatro motores.
    C.geometria.distanciaCentroMotor = NaN;  % m

    % Posición vertical del plano de motores respecto al centro
    % de masa, usando el marco corporal FRD:
    %   positivo = motores debajo del centro de masa;
    %   negativo = motores encima del centro de masa.
    C.geometria.zMotor_B = NaN;              % m

end