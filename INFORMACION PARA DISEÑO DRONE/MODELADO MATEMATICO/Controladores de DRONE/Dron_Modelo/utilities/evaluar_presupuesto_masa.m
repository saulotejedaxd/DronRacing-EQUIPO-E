function reporte = evaluar_presupuesto_masa(B, R)
%EVALUAR_PRESUPUESTO_MASA Evalúa masas y posiciones de componentes.
%
% Entradas:
%   B - Presupuesto generado por presupuesto_masa().
%   R - Restricciones generadas por reglas_competencia().
%
% Salida:
%   reporte - Estructura con masa, margen y centro de masa.

    T = B.componentes;

    reporte.errores = strings(0, 1);

    %% Validación de masas

    masasFinitas = isfinite(T.Masa_kg);
    masasNoNegativas = T.Masa_kg >= 0;

    masasValidas = masasFinitas & masasNoNegativas;

    if any(masasFinitas & ~masasNoNegativas)
        reporte.errores(end + 1) = ...
            "Existen componentes con masa negativa.";
    end

    reporte.componentesPendientesMasa = ...
        T.Nombre(~masasValidas);

    reporte.masaCompleta = all(masasValidas);

    %% Masa conocida

    reporte.masaConocida_kg = ...
        sum(T.Masa_kg(masasValidas));

    reporte.margenProvisional_kg = ...
        R.masa.maxima - reporte.masaConocida_kg;

    %% Evaluación de masa total

    if reporte.masaCompleta

        reporte.masaTotal_kg = sum(T.Masa_kg);

        if reporte.masaTotal_kg <= 0

            reporte.errores(end + 1) = ...
                "La masa total debe ser mayor que cero.";

            reporte.estadoMasa = "ERROR";

        elseif reporte.masaTotal_kg <= R.masa.maxima

            reporte.estadoMasa = "CUMPLE";

        else

            reporte.estadoMasa = "NO CUMPLE";

        end

        reporte.margenFinal_kg = ...
            R.masa.maxima - reporte.masaTotal_kg;

    else

        reporte.masaTotal_kg = NaN;
        reporte.margenFinal_kg = NaN;
        reporte.estadoMasa = "NO EVALUABLE";

    end

    %% Validación de posiciones

    posiciones = T{:, {'x_B_m', 'y_B_m', 'z_B_m'}};

    posicionesValidas = all(isfinite(posiciones), 2);

    reporte.componentesPendientesPosicion = ...
        T.Nombre(~posicionesValidas);

    reporte.posicionesCompletas = all(posicionesValidas);

    %% Centro de masa

    if reporte.masaCompleta && ...
            reporte.posicionesCompletas && ...
            reporte.masaTotal_kg > 0

        masas = T.Masa_kg;

        centroMasaFila = ...
            sum(masas .* posiciones, 1) / reporte.masaTotal_kg;

        reporte.centroMasa_B_m = centroMasaFila.';

        reporte.centroMasaDisponible = true;

    else

        reporte.centroMasa_B_m = NaN(3, 1);
        reporte.centroMasaDisponible = false;

    end

    %% Reserva de diseño

    if isfinite(B.reservaDiseno_kg)

        if B.reservaDiseno_kg < 0

            reporte.errores(end + 1) = ...
                "La reserva de diseño no puede ser negativa.";

        end

        reporte.reservaDefinida = true;

    else

        reporte.reservaDefinida = false;

    end

    if reporte.masaCompleta && reporte.reservaDefinida

        reporte.masaConReserva_kg = ...
            reporte.masaTotal_kg + B.reservaDiseno_kg;

        reporte.cumpleIncluyendoReserva = ...
            reporte.masaConReserva_kg <= R.masa.maxima;

    else

        reporte.masaConReserva_kg = NaN;
        reporte.cumpleIncluyendoReserva = false;

    end

end