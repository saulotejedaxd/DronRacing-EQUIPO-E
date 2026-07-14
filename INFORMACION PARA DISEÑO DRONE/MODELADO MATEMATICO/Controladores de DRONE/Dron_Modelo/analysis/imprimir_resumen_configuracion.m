function imprimir_resumen_configuracion( ...
    modelo, x0, P, R, D, C, G, B, ...
    reporteGeometria, reporteMasa, reporteParametros)
%IMPRIMIR_RESUMEN_CONFIGURACION Muestra el estado inicial del proyecto.
%
% Esta función solamente presenta información.
% No modifica parámetros ni ejecuta la dinámica del dron.

    fprintf("====================================================\n");
    fprintf("       SIMULADOR NUMÉRICO DEL DRON FPV\n");
    fprintf("====================================================\n");

    %% Definición matemática

    fprintf("\nDEFINICIÓN DEL MODELO\n");
    fprintf("---------------------\n");
    fprintf("Sistema de unidades: %s\n", modelo.sistemaUnidades);
    fprintf("Marco inercial:      %s\n", modelo.marcoInercial);
    fprintf("Marco corporal:      %s\n", modelo.marcoCuerpo);
    fprintf("Secuencia de Euler:  %s\n", modelo.secuenciaEuler);
    fprintf("Número de estados:   %d\n", modelo.numeroEstados);

    tablaEstados = table( ...
        (1:modelo.numeroEstados).', ...
        modelo.nombresEstados, ...
        modelo.descripcionEstados, ...
        modelo.unidadesEstados, ...
        x0, ...
        'VariableNames', { ...
            'Indice', ...
            'Estado', ...
            'Descripcion', ...
            'Unidad', ...
            'ValorInicial'} ...
    );

    fprintf("\nVECTOR INICIAL DE ESTADOS\n");
    fprintf("-------------------------\n");
    disp(tablaEstados);

    fprintf("Altura inicial: %.3f m\n", ...
        -x0(modelo.idx.zD));

    %% Restricciones reglamentarias

    fprintf("\nRESTRICCIONES DE COMPETENCIA\n");
    fprintf("----------------------------\n");
    fprintf("Masa máxima:                     %.3f kg\n", ...
        R.masa.maxima);
    fprintf("Círculo máximo de motores:       %.3f m\n", ...
        R.geometria.diametroCirculoMotoresMax);
    fprintf("Distancia centro-motor máxima:   %.3f m\n", ...
        R.geometria.distanciaCentroMotorMax);
    fprintf("Diámetro máximo de hélice:       %.4f m\n", ...
        R.helices.diametroMax);
    fprintf("Batería máxima:                  %dS\n", ...
        R.bateria.numeroCeldasSerieMax);
    fprintf("Voltaje máximo para 6S:          %.1f V\n", ...
        R.bateria.voltaje6SMax);
    fprintf("Inclinación máxima de motores:   %.1f grados\n", ...
        rad2deg(R.motores.inclinacionMax));

    %% Requisitos del proyecto

    fprintf("\nCONFIGURACIÓN DEL PROYECTO\n");
    fprintf("--------------------------\n");
    fprintf("Tipo:                 %s\n", D.tipo);
    fprintf("Configuración:        %s\n", D.configuracion);
    fprintf("Número de motores:    %d\n", D.numeroMotores);
    fprintf("Hélice objetivo:      %.1f pulgadas\n", ...
        D.helice.diametroPulgadas);
    fprintf("Diámetro de hélice:   %.4f m\n", ...
        D.helice.diametro);

    fprintf("Centro-motor mínimo teórico: %.5f m\n", ...
        D.geometria.distanciaCentroMotorMinTeorica);

    fprintf("Centro-motor máximo permitido: %.5f m\n", ...
        D.geometria.distanciaCentroMotorMax);

    fprintf("Hover por motor para 1 kg: %.5f N\n", ...
        D.empuje.hoverPorMotorCasoLimite);

    fprintf("Hélice dentro del reglamento: %s\n", ...
        convertir_logico(D.cumpleDiametroHelice));

    %% Parámetros geométricos del diseño

    fprintf("\nPARÁMETROS DE DISEÑO\n");
    fprintf("--------------------\n");
    fprintf("Nombre:  %s\n", C.meta.nombre);
    fprintf("Versión: %s\n", C.meta.version);
    fprintf("Estado:  %s\n", C.meta.estado);

    fprintf("Distancia centro-motor: ");
    imprimir_valor(C.geometria.distanciaCentroMotor, "m");

    fprintf("Plano vertical de motores: ");
    imprimir_valor(C.geometria.zMotor_B, "m");

    %% Configuración de motores

    fprintf("\nCONFIGURACIÓN DE MOTORES\n");
    fprintf("------------------------\n");
    disp(G.tablaMotores);

    imprimir_lista( ...
        "Datos geométricos pendientes", ...
        reporteGeometria.faltantes);

    imprimir_lista( ...
        "Errores geométricos", ...
        reporteGeometria.errores);

    imprimir_lista( ...
        "Advertencias geométricas", ...
        reporteGeometria.advertencias);

    %% Presupuesto de masa

    fprintf("\nPRESUPUESTO DE MASA\n");
    fprintf("--------------------\n");
    fprintf("Nombre:  %s\n", B.meta.nombre);
    fprintf("Versión: %s\n", B.meta.version);
    fprintf("Estado:  %s\n", B.meta.estado);

    fprintf("Masa conocida:       %.4f kg\n", ...
        reporteMasa.masaConocida_kg);

    fprintf("Margen provisional:  %.4f kg\n", ...
        reporteMasa.margenProvisional_kg);

    fprintf("Evaluación:           %s\n", ...
        reporteMasa.estadoMasa);

    if reporteMasa.masaCompleta
        fprintf("Masa total:           %.4f kg\n", ...
            reporteMasa.masaTotal_kg);
        fprintf("Margen final:         %.4f kg\n", ...
            reporteMasa.margenFinal_kg);
    end

    imprimir_lista( ...
        "Componentes pendientes de masa", ...
        reporteMasa.componentesPendientesMasa);

    if reporteMasa.centroMasaDisponible
        fprintf("\nCentro de masa en FRD:\n");
        fprintf("  x_CM = %.6f m\n", reporteMasa.centroMasa_B_m(1));
        fprintf("  y_CM = %.6f m\n", reporteMasa.centroMasa_B_m(2));
        fprintf("  z_CM = %.6f m\n", reporteMasa.centroMasa_B_m(3));
    else
        fprintf("\nCentro de masa: PENDIENTE\n");
    end

    imprimir_lista( ...
        "Errores del presupuesto de masa", ...
        reporteMasa.errores);

    %% Validación física

    fprintf("\nVALIDACIÓN DE PARÁMETROS FÍSICOS\n");
    fprintf("--------------------------------\n");
    fprintf("Conjunto: %s\n", P.meta.nombre);
    fprintf("Versión:  %s\n", P.meta.version);
    fprintf("Estado:   %s\n", P.meta.estado);

    imprimir_lista( ...
        "Parámetros físicos pendientes", ...
        reporteParametros.faltantes);

    imprimir_lista( ...
        "Errores de parámetros físicos", ...
        reporteParametros.errores);

    %% Estado general

    fprintf("\nESTADO GENERAL\n");
    fprintf("--------------\n");

    if reporteParametros.completo
        fprintf("Modelo físico completo y válido.\n");
        fprintf("La dinámica ya puede ejecutarse.\n");
    else
        fprintf("El modelo físico todavía no está listo para simularse.\n");
        fprintf("Esto es normal mientras existan datos NaN pendientes.\n");
    end

    fprintf("\n====================================================\n");
    fprintf("       FIN DE LA CONFIGURACIÓN INICIAL\n");
    fprintf("====================================================\n");

end


function imprimir_lista(titulo, elementos)
%IMPRIMIR_LISTA Imprime una lista únicamente cuando contiene elementos.

    if isempty(elementos)
        return;
    end

    fprintf("\n%s:\n", titulo);

    for i = 1:numel(elementos)
        fprintf("  - %s\n", elementos(i));
    end

end


function imprimir_valor(valor, unidad)
%IMPRIMIR_VALOR Distingue entre un valor definido y uno pendiente.

    if isfinite(valor)
        fprintf("%.6f %s\n", valor, unidad);
    else
        fprintf("PENDIENTE\n");
    end

end


function texto = convertir_logico(valor)
%CONVERTIR_LOGICO Convierte true/false a texto legible.

    if valor
        texto = "SÍ";
    else
        texto = "NO";
    end

end