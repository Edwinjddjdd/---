function out = vrs_johnson_qs(V_H, V_d, T, P)
%VRS_JOHNSON_QS 易读的结构体接口，供 MATLAB 扫掠和调试使用。
%   V_H - 桨盘面内速度，m/s，取速度大小。
%   V_d - 下降率，m/s，向下为正。
%   T   - 主旋翼拉力，N。
%   P   - vrs_params 返回的参数结构体。
%   out - 汇总准定常诱导速度、基线速度、VRS 修正量及状态量。
% 为什么需要这个包装层：数值核心为 Simulink 使用位置固定的多个输出；
% 人工调试和测试更适合 out.xxx 形式，因此本函数只负责组织输出和诊断量。

%% 第 1 步：调用唯一的数值核心，避免 MATLAB 与 Simulink 各写一套算法
[out.v_i_qs, out.v_base, out.dv_vrs, out.vrs_flag, ...
    out.tau, out.v_h, out.mu, out.nu, out.input_valid] = ...
    vrs_johnson_qs_numeric(V_H, V_d, T, P.vector);

%% 第 2 步：补充只用于观察和绘图的 VRS 有效强度
% 数值核心已用同一门函数修正 dv_vrs；这里重复计算只为了输出诊断量，
% 不会再次修改 v_i_qs。vrs_flag 为 false 时强制显示为零。
gate_arg = min(max(out.mu / max(P.boundary.muM, P.numeric.tol), 0), 1);
horizontal_gate = 1 - gate_arg^2 * (3 - 2*gate_arg);
out.vrs_strength = double(out.vrs_flag) * P.model.f_vrs * horizontal_gate;

%% 第 3 步：输出 Johnson 约定下的轴向速度，便于对照文献
% 轴向速度约定：向上为正，因此与向下为正的下降率符号相反。
out.V_z = -V_d;
end
