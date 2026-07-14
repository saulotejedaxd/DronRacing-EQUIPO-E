function imprimir_caso_base(caso)
%IMPRIMIR_CASO_BASE Presenta los datos del caso numérico provisional.

    fprintf("\nCASO BASE NUMÉRICO\n");
    fprintf("------------------\n");

    fprintf("Nombre:       %s\n", caso.meta.nombre);
    fprintf("Versión:      %s\n", caso.meta.version);
    fprintf("Tipo:         %s\n", caso.meta.tipo);

    fprintf("Representa el dron real: %s\n", ...
        convertir_logico(caso.meta.representaDronReal));

    fprintf("\nHipótesis utilizada:\n");
    fprintf("  %s\n", caso.meta.descripcion);

    fprintf("\nMasa total:                 %.6f kg\n", ...
        caso.masaTotal_kg);

    fprintf("Masa puntual equivalente:   %.6f kg\n", ...
        caso.masaPuntual_kg);

    fprintf("Distancia centro-motor:     %.6f m\n", ...
        caso.distanciaCentroMotor_m);

    fprintf("Componente diagonal a:      %.6f m\n", ...
        caso.componenteDiagonal_m);

    fprintf("\nTensor de inercia [kg·m²]:\n");
    disp(caso.inercia_B_kgm2);

    fprintf("Ixx = %.9f kg·m²\n", ...
        caso.inercia_B_kgm2(1,1));

    fprintf("Iyy = %.9f kg·m²\n", ...
        caso.inercia_B_kgm2(2,2));

    fprintf("Izz = %.9f kg·m²\n", ...
        caso.inercia_B_kgm2(3,3));

    fprintf("\nEmpuje total para hover:    %.6f N\n", ...
        caso.empujeHoverTotal_N);

    fprintf("Empuje por motor en hover:  %.6f N\n", ...
        caso.empujeHoverPorMotor_N);

    fprintf("\nADVERTENCIA:\n");
    fprintf("Este conjunto sirve para desarrollar las ecuaciones.\n");
    fprintf("No debe interpretarse como predicción del dron real.\n");

end


function texto = convertir_logico(valor)

    if valor
        texto = "SÍ";
    else
        texto = "NO";
    end

end