function v_i_dot = vrs_inflow_rhs(v_i, v_i_qs, tau)
%VRS_INFLOW_RHS 一阶平均入流动态方程右端项。

arguments
    v_i (1,1) double {mustBeFinite}
    v_i_qs (1,1) double {mustBeFinite}
    tau (1,1) double {mustBeFinite, mustBePositive}
end

v_i_dot = (v_i_qs - v_i) / tau;
end
