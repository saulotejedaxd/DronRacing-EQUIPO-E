function reporte = validar_configuracion_motores_x(G, R, D)
%VALIDAR_CONFIGURACION_MOTORES_X Revisa la geometría del dron en X.

    reporte.faltantes = strings(0, 1);
    reporte.errores = strings(0, 1);
    reporte.advertencias = strings(0, 1);

    %% Distancia centro-motor

    L = G.distanciaCentroMotor;

    if ~isfinite(L)

        reporte.faltantes(end + 1) = ...
            "Distancia horizontal del centro de masa a los motores";

    elseif L <= 0

        reporte.errores(end + 1) = ...
            "La distancia centro-motor debe ser mayor que cero.";

    else

        if L > R.geometria.distanciaCentroMotorMax

            reporte.errores(end + 1) = ...
                "Los ejes de los motores exceden el círculo reglamentario.";

        end

        if G.separacionMotoresAdyacentes < D.helice.diametro

            reporte.errores(end + 1) = ...
                "Los discos de las hélices adyacentes se traslapan.";

        elseif G.holguraEntreDiscosHelices == 0

            reporte.advertencias(end + 1) = ...
                "Las hélices no se traslapan, pero la holgura es cero.";

        end

    end

    %% Posición vertical de motores

    if ~isfinite(G.zMotor_B)

        reporte.faltantes(end + 1) = ...
            "Altura del plano de motores respecto al centro de masa";

    end

    %% Sentidos de giro

    if any(~ismember(G.sentidoGiro, [-1, 1]))

        reporte.errores(end + 1) = ...
            "Los sentidos de giro deben ser exclusivamente +1 o -1.";

    end

    if sum(G.sentidoGiro) ~= 0

        reporte.errores(end + 1) = ...
            "Debe existir el mismo número de motores CW y CCW.";

    end

    if G.sentidoGiro(1) ~= G.sentidoGiro(3) || ...
            G.sentidoGiro(2) ~= G.sentidoGiro(4)

        reporte.errores(end + 1) = ...
            "Los motores opuestos deben girar en el mismo sentido.";

    end

    %% Resultado general

    reporte.completa = ...
        isempty(reporte.faltantes) && ...
        isempty(reporte.errores);

end