function v_i_dot = vrs_inflow_rhs(v_i, v_i_qs, tau)
%VRS_INFLOW_RHS 一阶平均入流动态方程右端项。
%   v_i    - 当前动态诱导速度，m/s。
%   v_i_qs - Johnson 模型给出的准定常目标诱导速度，m/s。
%   tau    - 入流响应时间常数，s。
%   v_i_dot 为诱导速度对时间的导数，m/s^2。
% 为什么单独写成函数：前面的 Johnson 函数只给“当前工况最终应达到的
% 目标值”，本函数把目标值变成变化率；Simulink Integrator 再对其积分。

% 一阶惯性环节使实际诱导速度以时间常数 tau 跟随准定常目标值。
v_i_dot = (v_i_qs - v_i) / tau;
end
