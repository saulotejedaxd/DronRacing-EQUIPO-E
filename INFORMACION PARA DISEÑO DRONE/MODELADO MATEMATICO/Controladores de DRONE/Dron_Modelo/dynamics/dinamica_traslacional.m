function D = dinamica_traslacional( ...
    x, empujeMotores_N, fuerzaExterna_B_N, P, modelo)
%DINAMICA_TRASLACIONAL Calcula las aceleraciones lineales del dron.
%
% Convenciones:
%   Marco inercial NED:
%       +X_N: frente inicial
%       +Y_E: derecha inicial
%       +Z_D: abajo
%
%   Marco corporal FRD:
%       +X_B: frente
%       +Y_B: derecha
%       +Z_B: abajo
%
% Entradas:
%   x                  - Vector de 12 estados.
%   empujeMotores_N    - Empuje individual de los motores [N].
%                        Debe contener cuatro elementos no negativos.
%   fuerzaExterna_B_N  - Fuerza externa expresada en el marco corporal
%                        [Fx; Fy; Fz], en newtons.
%   P                  - Parámetros físicos del dron.
%   modelo             - Definición del vector de estados.
%
% Salida:
%   D - Estructura con fuerzas y aceleración lineal:
%       D.velocidadDot_B
%       D.fuerzaTotal_B_N
%       D.fuerzaGravedad_B_N
%       D.fuerzaEmpuje_B_N
%       D.fuerzaArrastre_B_N
%       D.fuerzaExterna_B_N
%       D.empujeTotal_N
%       D.terminoCoriolis_B

    %% Validación del vector de estados

    if numel(x) ~= modelo.numeroEstados
        error( ...
            "dinamica_traslacional:NumeroEstadosInvalido", ...
            "El vector x debe contener exactamente %d estados.", ...
            modelo.numeroEstados ...
        );
    end

    x = x(:);

    if any(~isfinite(x))
        error( ...
            "dinamica_traslacional:EstadosNoFinitos", ...
            "El vector de estados contiene NaN o valores infinitos." ...
        );
    end

    %% Validación de masa

    masa = P.cuerpo.masa;

    if ~isscalar(masa) || ~isfinite(masa) || masa <= 0
        error( ...
            "dinamica_traslacional:MasaInvalida", ...
            "La masa del dron debe ser un escalar finito mayor que cero." ...
        );
    end

    %% Validación del empuje

    empujeMotores_N = empujeMotores_N(:);

    if numel(empujeMotores_N) ~= P.motores.numero
        error( ...
            "dinamica_traslacional:NumeroEmpujesInvalido", ...
            "Se esperaban %d valores de empuje.", ...
            P.motores.numero ...
        );
    end

    if any(~isfinite(empujeMotores_N))
        error( ...
            "dinamica_traslacional:EmpujesNoFinitos", ...
            "Los empujes contienen NaN o valores infinitos." ...
        );
    end

    if any(empujeMotores_N < 0)
        error( ...
            "dinamica_traslacional:EmpujeNegativo", ...
            "Los empujes individuales no pueden ser negativos." ...
        );
    end

    %% Validación de fuerza externa

    fuerzaExterna_B_N = fuerzaExterna_B_N(:);

    if numel(fuerzaExterna_B_N) ~= 3 || ...
            any(~isfinite(fuerzaExterna_B_N))

        error( ...
            "dinamica_traslacional:FuerzaExternaInvalida", ...
            [ ...
                "La fuerza externa debe ser un vector finito " ...
                "de tres elementos." ...
            ] ...
        );
    end

    %% Velocidades corporales

    velocidad_B = [
        x(modelo.idx.u)
        x(modelo.idx.v)
        x(modelo.idx.w)
    ];

    velocidadAngular_B = [
        x(modelo.idx.p)
        x(modelo.idx.q)
        x(modelo.idx.r)
    ];

    %% Cinemática y matrices de rotación

    K = cinematica_6dof(x, modelo);

    %% Fuerza de gravedad

    % En el marco NED la gravedad apunta en la dirección +Z_D.

    fuerzaGravedad_N = [
        0
        0
        masa * P.entorno.g
    ];

    % Convertir gravedad del marco inercial al marco corporal.

    fuerzaGravedad_B_N = ...
        K.R_NB * fuerzaGravedad_N;

    %% Fuerza de empuje

    empujeTotal_N = sum(empujeMotores_N);

    % Las hélices producen una fuerza hacia arriba.
    % Como +Z_B apunta hacia abajo, el empuje tiene signo negativo.

    fuerzaEmpuje_B_N = [
        0
        0
        -empujeTotal_N
    ];

    %% Fuerza de arrastre lineal

    coefArrastre = P.aerodinamica.arrastreLineal_B(:);

    if numel(coefArrastre) ~= 3 || ...
            any(~isfinite(coefArrastre)) || ...
            any(coefArrastre < 0)

        error( ...
            "dinamica_traslacional:ArrastreInvalido", ...
            [ ...
                "Los coeficientes de arrastre lineal deben ser " ...
                "tres valores finitos y no negativos." ...
            ] ...
        );
    end

    % Modelo lineal simplificado:
    %
    % F_drag = -C_v .* v_B

    fuerzaArrastre_B_N = ...
        -coefArrastre .* velocidad_B;

    %% Fuerza total

    fuerzaTotal_B_N = ...
        fuerzaGravedad_B_N + ...
        fuerzaEmpuje_B_N + ...
        fuerzaArrastre_B_N + ...
        fuerzaExterna_B_N;

    %% Término debido al marco corporal giratorio

    terminoCoriolis_B = ...
        cross(velocidadAngular_B, velocidad_B);

    %% Derivada de velocidades corporales

    velocidadDot_B = ...
        fuerzaTotal_B_N / masa - terminoCoriolis_B;

    %% Salidas

    D.velocidadDot_B = velocidadDot_B;

    D.fuerzaTotal_B_N = fuerzaTotal_B_N;
    D.fuerzaGravedad_B_N = fuerzaGravedad_B_N;
    D.fuerzaEmpuje_B_N = fuerzaEmpuje_B_N;
    D.fuerzaArrastre_B_N = fuerzaArrastre_B_N;
    D.fuerzaExterna_B_N = fuerzaExterna_B_N;

    D.empujeMotores_N = empujeMotores_N;
    D.empujeTotal_N = empujeTotal_N;

    D.velocidad_B = velocidad_B;
    D.velocidadAngular_B = velocidadAngular_B;

    D.terminoCoriolis_B = terminoCoriolis_B;

end