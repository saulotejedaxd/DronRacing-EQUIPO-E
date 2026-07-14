function reporte = validar_parametros_fisicos(P)
%VALIDAR_PARAMETROS_FISICOS Revisa los parámetros físicos disponibles.
%
% Entrada:
%   P - Estructura generada por parametros_fisicos().
%
% Salida:
%   reporte - Estructura con el resultado de la validación.

    faltantes = strings(0, 1);
    errores   = strings(0, 1);

    %% Masa

    if ~isfinite(P.cuerpo.masa)
        faltantes(end + 1) = "Masa total del dron";
    elseif P.cuerpo.masa <= 0
        errores(end + 1) = "La masa debe ser mayor que cero.";
    end

    %% Centro de masa

    if any(~isfinite(P.cuerpo.centroMasa_B))
        faltantes(end + 1) = "Centro de masa";
    end

    %% Tensor de inercia

    if any(~isfinite(P.cuerpo.inercia_B), "all")
        faltantes(end + 1) = "Tensor de inercia";
    else
        if ~isequal(P.cuerpo.inercia_B, P.cuerpo.inercia_B.')
            errores(end + 1) = ...
                "El tensor de inercia debe ser simétrico.";
        end

        if any(eig(P.cuerpo.inercia_B) <= 0)
            errores(end + 1) = ...
                "El tensor de inercia debe ser definido positivo.";
        end
    end

    %% Posiciones de motores

    if any(~isfinite(P.motores.posicion_B), "all")
        faltantes(end + 1) = "Posiciones de los cuatro motores";
    end

    %% Sentidos de giro

    if any(~isfinite(P.motores.sentidoGiro))
        faltantes(end + 1) = "Sentidos de giro de los motores";
    elseif any(~ismember(P.motores.sentidoGiro, [-1, 1]))
        errores(end + 1) = ...
            "Los sentidos de giro deben ser exclusivamente +1 o -1.";
    end
    %% Signos del torque de yaw

    if any(~isfinite(P.motores.signoTorqueYawCuerpo))
    
        faltantes(end + 1) = ...
            "Signos del torque de reacción de yaw";
    
    elseif any(~ismember( ...
            P.motores.signoTorqueYawCuerpo, [-1, 1]))
    
        errores(end + 1) = ...
            [ ...
                "Los signos del torque de yaw deben ser " ...
                "exclusivamente +1 o -1." ...
            ];
    
    end

    %% Empuje máximo

    if any(~isfinite(P.motores.empujeMaximo))
        faltantes(end + 1) = "Empuje máximo de cada motor";
    elseif any(P.motores.empujeMaximo <= 0)
        errores(end + 1) = ...
            "Todos los empujes máximos deben ser mayores que cero.";
    end

    %% Dinámica de motores

    if any(~isfinite(P.motores.constanteTiempo))
        faltantes(end + 1) = ...
            "Constante de tiempo de los motores";
    elseif any(P.motores.constanteTiempo <= 0)
        errores(end + 1) = ...
            "Las constantes de tiempo deben ser mayores que cero.";
    end

    %% Coeficientes de hélices

    if any(~isfinite(P.helices.kT))
        faltantes(end + 1) = "Coeficientes de empuje kT";
    elseif any(P.helices.kT <= 0)
        errores(end + 1) = ...
            "Los coeficientes kT deben ser mayores que cero.";
    end

    if any(~isfinite(P.helices.kQ))
        faltantes(end + 1) = "Coeficientes de torque kQ";
    elseif any(P.helices.kQ <= 0)
        errores(end + 1) = ...
            "Los coeficientes kQ deben ser mayores que cero.";
    end

    %% Resultado

    reporte.faltantes = faltantes;
    reporte.errores   = errores;

    reporte.completo = ...
        isempty(reporte.faltantes) && isempty(reporte.errores);

end