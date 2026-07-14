function U = crear_entrada_actuadores(P)
%CREAR_ENTRADA_ACTUADORES Genera una entrada válida para los motores.
%
% Entrada:
%   P - Parámetros físicos del dron.
%
% Salida:
%   U - Estructura con:
%       U.empujeMotores_N
%       U.torqueReaccionMotores_Nm

    numeroMotores = P.motores.numero;

    if ~isscalar(numeroMotores) || ...
            ~isfinite(numeroMotores) || ...
            numeroMotores < 1 || ...
            fix(numeroMotores) ~= numeroMotores

        error( ...
            "crear_entrada_actuadores:NumeroMotoresInvalido", ...
            "El número de motores debe ser un entero positivo." ...
        );

    end

    U.empujeMotores_N = zeros(numeroMotores, 1);

    U.torqueReaccionMotores_Nm = zeros(numeroMotores, 1);

end