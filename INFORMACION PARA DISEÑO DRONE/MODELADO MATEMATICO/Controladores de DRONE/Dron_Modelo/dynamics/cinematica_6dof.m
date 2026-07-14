function K = cinematica_6dof(x, modelo)
%CINEMATICA_6DOF Calcula la cinemática del dron.
%
% Convenciones:
%   Marco inercial: NED
%       +X_N: frente inicial / norte
%       +Y_E: derecha inicial / este
%       +Z_D: abajo
%
%   Marco corporal: FRD
%       +X_B: frente
%       +Y_B: derecha
%       +Z_B: abajo
%
%   Ángulos de Euler:
%       phi   = roll
%       theta = pitch
%       psi   = yaw
%
%   Secuencia de rotación:
%       ZYX, también denominada 3-2-1.
%
% Entrada:
%   x       - Vector de 12 estados.
%   modelo  - Estructura generada por definicion_modelo().
%
% Salida:
%   K - Estructura con:
%       K.posicionDot_N
%       K.eulerDot
%       K.R_BN
%       K.R_NB
%       K.TEuler
%       K.velocidad_B
%       K.velocidadAngular_B

    %% Validación de entrada

    if numel(x) ~= modelo.numeroEstados
        error( ...
            "cinematica_6dof:NumeroEstadosInvalido", ...
            "El vector x debe contener exactamente %d estados.", ...
            modelo.numeroEstados ...
        );
    end

    x = x(:);

    if any(~isfinite(x))
        error( ...
            "cinematica_6dof:EstadosNoFinitos", ...
            "El vector de estados contiene NaN o valores infinitos." ...
        );
    end

    %% Extraer velocidades lineales en el marco corporal

    velocidad_B = [
        x(modelo.idx.u)
        x(modelo.idx.v)
        x(modelo.idx.w)
    ];

    %% Extraer ángulos de Euler

    phi = x(modelo.idx.phi);
    theta = x(modelo.idx.theta);
    psi = x(modelo.idx.psi);

    %% Extraer velocidades angulares del cuerpo

    velocidadAngular_B = [
        x(modelo.idx.p)
        x(modelo.idx.q)
        x(modelo.idx.r)
    ];

    %% Funciones trigonométricas

    cPhi = cos(phi);
    sPhi = sin(phi);

    cTheta = cos(theta);
    sTheta = sin(theta);

    cPsi = cos(psi);
    sPsi = sin(psi);

    %% Comprobación de singularidad de Euler

    % La transformación presenta singularidad cuando:
    %
    % theta = +/- 90 grados
    %
    % En las primeras simulaciones de hover no debemos acercarnos
    % a esa condición. Posteriormente se emplearán cuaterniones para
    % simulaciones completas de volcamiento.

    toleranciaSingularidad = 1e-8;

    if abs(cTheta) < toleranciaSingularidad
        error( ...
            "cinematica_6dof:SingularidadEuler", ...
            [ ...
                "El ángulo pitch está demasiado cerca de +/-90 grados. " ...
                "La representación mediante ángulos de Euler es singular." ...
            ] ...
        );
    end

    %% Matriz de rotación cuerpo -> inercial

    % Convierte un vector expresado en FRD a coordenadas NED:
    %
    % vector_N = R_BN * vector_B

    R_BN = [
        cTheta*cPsi, ...
        sPhi*sTheta*cPsi - cPhi*sPsi, ...
        cPhi*sTheta*cPsi + sPhi*sPsi

        cTheta*sPsi, ...
        sPhi*sTheta*sPsi + cPhi*cPsi, ...
        cPhi*sTheta*sPsi - sPhi*cPsi

        -sTheta, ...
        sPhi*cTheta, ...
        cPhi*cTheta
    ];

    %% Matriz de rotación inercial -> cuerpo

    % Como una matriz de rotación es ortogonal:
    %
    % R_NB = inv(R_BN) = R_BN.'

    R_NB = R_BN.';

    %% Derivada de posición en el marco inercial

    posicionDot_N = R_BN * velocidad_B;

    %% Transformación p, q, r -> derivadas de Euler

    TEuler = [
        1, sPhi*tan(theta),  cPhi*tan(theta)
        0, cPhi,            -sPhi
        0, sPhi/cTheta,      cPhi/cTheta
    ];

    eulerDot = TEuler * velocidadAngular_B;

    %% Preparar salida

    K.posicionDot_N = posicionDot_N;
    K.eulerDot = eulerDot;

    K.R_BN = R_BN;
    K.R_NB = R_NB;
    K.TEuler = TEuler;

    K.velocidad_B = velocidad_B;
    K.velocidadAngular_B = velocidadAngular_B;

    %% Indicador preventivo

    % No es todavía una singularidad, pero advierte que el modelo se
    % aproxima a una región poco adecuada para ángulos de Euler.

    K.cercaSingularidadEuler = ...
        abs(theta) >= deg2rad(85);

end