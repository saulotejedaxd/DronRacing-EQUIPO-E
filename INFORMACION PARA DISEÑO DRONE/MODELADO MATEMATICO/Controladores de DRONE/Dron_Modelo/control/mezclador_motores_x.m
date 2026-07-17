function [U, D] = mezclador_motores_x( ...
    empujeTotal_N, momentoDeseado_B_Nm, P)
%MEZCLADOR_MOTORES_X Distribuye empuje y momentos entre cuatro motores.
%
% Entradas:
%
%   empujeTotal_N
%       Empuje colectivo total solicitado [N].
%
%   momentoDeseado_B_Nm
%       Vector de momentos solicitados:
%
%       [Mx
%        My
%        Mz]
%
%       Mx = momento de roll  alrededor de +X_B
%       My = momento de pitch alrededor de +Y_B
%       Mz = momento de yaw   alrededor de +Z_B
%
%   P
%       Estructura de parámetros físicos del dron.
%
% Salidas:
%
%   U
%       Entrada compatible con modelo_no_lineal_12_estados:
%       U.empujeMotores_N
%       U.torqueReaccionMotores_Nm
%
%   D
%       Información de diagnóstico del mezclador.
%
% Convención de motores:
%
%                 FRENTE +X_B
%
%              M1             M2
%       frontal izquierdo  frontal derecho
%
%              M4             M3
%        trasero izquierdo  trasero derecho

    %% Validaciones básicas

    if ~isscalar(empujeTotal_N) || ...
            ~isfinite(empujeTotal_N)

        error( ...
            'mezclador_motores_x:EmpujeInvalido', ...
            'El empuje total debe ser un escalar finito.' ...
        );

    end

    momentoDeseado_B_Nm = momentoDeseado_B_Nm(:);

    if numel(momentoDeseado_B_Nm) ~= 3 || ...
            any(~isfinite(momentoDeseado_B_Nm))

        error( ...
            'mezclador_motores_x:MomentoInvalido', ...
            ['El momento deseado debe ser un vector ' ...
             'finito de tres elementos.'] ...
        );

    end

    if ~isfield(P, 'motores') || ...
            ~isfield(P.motores, 'posicion_B')

        error( ...
            'mezclador_motores_x:FaltaGeometria', ...
            'P debe contener P.motores.posicion_B.' ...
        );

    end

    numeroMotores = P.motores.numero;

    posicionMotores_B = P.motores.posicion_B;

    if size(posicionMotores_B, 1) ~= 3 || ...
            size(posicionMotores_B, 2) ~= numeroMotores

        error( ...
            'mezclador_motores_x:GeometriaInvalida', ...
            'La matriz de posiciones de motores es inválida.' ...
        );

    end

    %% Extraer posiciones horizontales

    xMotores = posicionMotores_B(1, :);

    yMotores = posicionMotores_B(2, :);

    %% Matriz de asignación de empuje
    %
    % Cada motor produce:
    %
    %   F_i = [0; 0; -T_i]
    %
    % El momento debido al empuje es:
    %
    %   M_i = r_i x F_i
    %
    % Por tanto:
    %
    %   Mx_i = -y_i*T_i
    %   My_i =  x_i*T_i

    matrizAsignacion = [
        ones(1, numeroMotores)
        -yMotores
         xMotores
    ];

    vectorSolicitado = [
        empujeTotal_N
        momentoDeseado_B_Nm(1)
        momentoDeseado_B_Nm(2)
    ];

    %% Calcular empuje de cada motor

    empujeMotoresSinSaturar_N = ...
        pinv(matrizAsignacion) * vectorSolicitado;

    empujeMotores_N = empujeMotoresSinSaturar_N;

    %% Límites mínimos

    empujeMinimo_N = P.motores.empujeMinimo(:);

    if isscalar(empujeMinimo_N)

        empujeMinimo_N = ...
            repmat(empujeMinimo_N, numeroMotores, 1);

    end

    if numel(empujeMinimo_N) ~= numeroMotores

        error( ...
            'mezclador_motores_x:LimiteMinimoInvalido', ...
            'El límite mínimo de empuje es inválido.' ...
        );

    end

    for motor = 1:numeroMotores

        if isfinite(empujeMinimo_N(motor))

            empujeMotores_N(motor) = max( ...
                empujeMotores_N(motor), ...
                empujeMinimo_N(motor) ...
            );

        end

    end

    %% Límites máximos

    empujeMaximo_N = P.motores.empujeMaximo(:);

    if isscalar(empujeMaximo_N)

        empujeMaximo_N = ...
            repmat(empujeMaximo_N, numeroMotores, 1);

    end

    if numel(empujeMaximo_N) ~= numeroMotores

        error( ...
            'mezclador_motores_x:LimiteMaximoInvalido', ...
            'El límite máximo de empuje es inválido.' ...
        );

    end

    for motor = 1:numeroMotores

        if isfinite(empujeMaximo_N(motor))

            empujeMotores_N(motor) = min( ...
                empujeMotores_N(motor), ...
                empujeMaximo_N(motor) ...
            );

        end

    end

    %% Distribución provisional del momento de yaw

    signoYaw = ...
        P.motores.signoTorqueYawCuerpo(:);

    momentoYawDeseado_Nm = ...
        momentoDeseado_B_Nm(3);

    torqueReaccionMotores_Nm = ...
        zeros(numeroMotores, 1);

    if momentoYawDeseado_Nm > 0

        motoresActivos = signoYaw > 0;

        cantidadActivos = sum(motoresActivos);

        if cantidadActivos == 0

            error( ...
                'mezclador_motores_x:SinMotoresYawPositivo', ...
                'No existen motores para producir yaw positivo.' ...
            );

        end

        torqueReaccionMotores_Nm(motoresActivos) = ...
            momentoYawDeseado_Nm / cantidadActivos;

    elseif momentoYawDeseado_Nm < 0

        motoresActivos = signoYaw < 0;

        cantidadActivos = sum(motoresActivos);

        if cantidadActivos == 0

            error( ...
                'mezclador_motores_x:SinMotoresYawNegativo', ...
                'No existen motores para producir yaw negativo.' ...
            );

        end

        torqueReaccionMotores_Nm(motoresActivos) = ...
            abs(momentoYawDeseado_Nm) / cantidadActivos;

    end

    %% Construir entrada para el modelo

    U = crear_entrada_actuadores(P);

    U.empujeMotores_N = ...
        empujeMotores_N;

    U.torqueReaccionMotores_Nm = ...
        torqueReaccionMotores_Nm;

    %% Calcular lo que realmente produce la salida

    fuerzaTotalReal_N = ...
        sum(empujeMotores_N);

    momentoRollReal_Nm = ...
        sum(-yMotores(:) .* empujeMotores_N);

    momentoPitchReal_Nm = ...
        sum(xMotores(:) .* empujeMotores_N);

    momentoYawReal_Nm = ...
        sum(signoYaw .* torqueReaccionMotores_Nm);

    momentoReal_B_Nm = [
        momentoRollReal_Nm
        momentoPitchReal_Nm
        momentoYawReal_Nm
    ];

    %% Diagnóstico

    D.matrizAsignacion = matrizAsignacion;

    D.empujeSolicitado_N = empujeTotal_N;

    D.momentoSolicitado_B_Nm = ...
        momentoDeseado_B_Nm;

    D.empujeMotoresSinSaturar_N = ...
        empujeMotoresSinSaturar_N;

    D.empujeMotores_N = ...
        empujeMotores_N;

    D.torqueReaccionMotores_Nm = ...
        torqueReaccionMotores_Nm;

    D.empujeReal_N = ...
        fuerzaTotalReal_N;

    D.momentoReal_B_Nm = ...
        momentoReal_B_Nm;

    D.errorEmpuje_N = ...
        fuerzaTotalReal_N - empujeTotal_N;

    D.errorMomento_B_Nm = ...
        momentoReal_B_Nm - momentoDeseado_B_Nm;

    D.huboSaturacion = any( ...
        abs( ...
            empujeMotores_N - ...
            empujeMotoresSinSaturar_N ...
        ) > 1e-12 ...
    );

end