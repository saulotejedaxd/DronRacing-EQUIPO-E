function E = perturbacion_nula()
%PERTURBACION_NULA Genera una perturbación externa igual a cero.
%
% Salida:
%   E - Estructura con fuerzas y momentos externos:
%       E.fuerzaExterna_B_N
%       E.momentoExterno_B_Nm

    E.fuerzaExterna_B_N = zeros(3, 1);

    E.momentoExterno_B_Nm = zeros(3, 1);

end