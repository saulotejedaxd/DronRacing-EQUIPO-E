function P = aplicar_presupuesto_masa(P, reporte)
%APLICAR_PRESUPUESTO_MASA Transfiere propiedades calculadas al modelo.
%
% La masa solo se transfiere cuando todas las masas están definidas.
% El centro de masa solo se transfiere cuando todas las posiciones
% también están definidas.

    if reporte.masaCompleta && isfinite(reporte.masaTotal_kg)

        P.cuerpo.masa = reporte.masaTotal_kg;

    end

    if reporte.centroMasaDisponible

        P.cuerpo.centroMasa_B = reporte.centroMasa_B_m;

    end

end