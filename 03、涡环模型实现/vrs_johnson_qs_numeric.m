function [vi_qs, v_base, dv_vrs, vrs_flag, tau, v_h, mu, nu, input_valid] = ...
    vrs_johnson_qs_numeric(V_H, V_d, T, p)
%VRS_JOHNSON_QS_NUMERIC Johnson 型准定常 VRS 平均诱导速度。
%   V_H : 桨盘面内速度，m/s，大小为正。
%   V_d : 下降率，m/s，向下为正。
%   T   : 主旋翼拉力，N。
%   p   : vrs_params 返回的数值参数向量。
% 输出包括准定常诱导速度、基线速度、VRS 修正量、区域标志、
% 动态时间常数、悬停诱导速度以及无量纲速度 mu 和 nu。
%
% 为什么需要这个函数：
%   Simulink 的 MATLAB Function 块更适合固定长度数值输入/输出，因此把
%   真正的准定常算法集中在这里；vrs_johnson_qs.m 只是易读的结构体包装。
%
% 主计算链：
%   1) 解包参数并检查输入；
%   2) 用当前拉力计算 v_h，再得到无量纲速度 mu、nu；
%   3) 计算“不考虑涡环回卷”的基线诱导速度；
%   4) 根据水平速度计算 VRS 门控和 N/X 控制点收拢；
%   5) 在 D-N-X-E 区间构造目标总入流曲线；
%   6) 把目标总入流反算成 VRS 诱导速度修正；
%   7) 输出准定常目标，交给动态入流积分环节继续计算。

%% 第 1 步：解包参数，并确认当前输入能否代表有效物理工况
% p 必须与 vrs_params.m 中 P.vector 的排列完全一致。
rho = p(1);
R = p(2);
Omega = p(3);
kappa = p(4);
f_vrs = p(5);
tau_rev = p(6);
VzA = p(7);
VzB = p(8);
VzD = p(9);
VzN = p(10);
qN = p(11);
VzX = p(12);
qX = p(13);
VzE = p(14);
muC = p(15);
muM = p(16);
T_min = p(17);
tol = p(18);

% input_valid 是诊断结果，不直接中断运算。后面先用保护值完成计算，
% 最后再把无效工况的物理输出归零，这样 Simulink 不会因 NaN 立即发散。
input_valid = isfinite(V_H) && isfinite(V_d) && isfinite(T) && ...
    isfinite(rho) && isfinite(R) && isfinite(Omega) && ...
    rho > 0 && R > 0 && Omega > 0 && T > 0;

%% 第 2 步：建立当前工况的速度标尺，并进行无量纲化
% T_eff 只用于数值保护；有效物理工况仍要求原始 T > 0。
% v_h 是当前拉力下的理想悬停诱导速度，也是后续所有速度的标尺。
T_eff = max(T, T_min);
A = pi * R^2;
v_h = sqrt(T_eff / (2 * rho * A));
mu = abs(V_H) / v_h;
nu = -V_d / v_h;
% tau_rev 给的是“多少转后基本建立入流”，这里换算成秒。
tau = tau_rev * 2*pi / Omega;

%% 第 3 步：计算没有 VRS 特殊回卷修正时的基线
% baseline_dimless 先计算轴向基线，再随 mu 增大平滑混合到斜流动量理论。
% q = nu + kappa*v，因此 q_base_final 是无量纲基线总轴向入流。
v_base_bar = baseline_dimless(nu, mu, VzA, VzB, muC, tol);
q_base_final = nu + kappa * v_base_bar;

%% 第 4 步：计算水平速度门控，并收拢 VRS 内部控制点
% gate_arg 不是 VRS 强度，而是“从零水平速度走到关断阈值 muM 的进度”：
%   gate_arg = 0  -> 尚未因水平速度削弱 VRS；
%   gate_arg = 1  -> 已达到/超过 muM，应完全关闭 VRS 修正。
% 内层 max(muM,tol) 防止除零；外层 min/max 把进度限制在 [0,1]。
gate_arg = min(max(mu / max(muM, tol), 0), 1);
% smoothstep 从 0 平滑升到 1；取 1-smoothstep 后，门值从 1 平滑降到 0。
vrs_gate = 1 - smoothstep(gate_arg);

% 仅减小修正幅值还不够：N、X 也要向中点收拢，使三段曲线的形状和
% 轴向作用范围随水平速度一起缩小，避免到 muM 时突然换段。
move_arg = max(0, 1 - gate_arg^2);
midpoint = 0.5 * (VzN + VzX);
halfspan = 0.5 * (VzN - VzX);
VzN_star = midpoint + halfspan * move_arg^0.2;
VzX_star = midpoint - halfspan * move_arg^1.5;

% D、E 是 VRS 曲线接回正常基线的端点，所以需要基线在两点的值和斜率。
[qD, mD] = baseline_q_and_slope(VzD, mu, kappa, VzA, VzB, muC, tol);
[qE, mE] = baseline_q_and_slope(VzE, mu, kappa, VzA, VzB, muC, tol);

%% 第 5 步：判断区域，并构造 D-N-X-E 目标总入流曲线
% 默认先令目标等于基线。这样 VRS 区域外不需要额外的 else 分支。
q_target = q_base_final;
% 只有轴向速度落在 D~E 内、且水平速度尚未达到 muM，才应用 VRS 曲线。
inside_vrs = (nu <= VzD) && (nu >= VzE) && (mu < muM);

if inside_vrs
    % 三段 Hermite 曲线依次连接 D-N、N-X、X-E：
    %   D/E 的斜率取自基线，保证接回基线时平滑；
    %   N/X 的斜率设为 0，形成 Johnson 模型需要的转折控制点。
    if nu >= VzN_star
        q_target = cubic_hermite(nu, VzN_star, qN, 0, VzD, qD, mD);
    elseif nu >= VzX_star
        q_target = cubic_hermite(nu, VzX_star, qX, 0, VzN_star, qN, 0);
    else
        q_target = cubic_hermite(nu, VzE, qE, mE, VzX_star, qX, 0);
    end
end

%% 第 6 步：从目标总入流反算诱导速度修正，并恢复量纲
% q_target 包含轴向来流 nu，先减去 nu 才得到目标诱导速度。
desired_vi_bar = q_target - nu;
% qN、qX 描述的是最终总入流，而主公式外面还有 kappa，因此这里先除以
% kappa 再减去基线，得到主公式括号内部应增加的量。f_vrs 控制标称强度，
% vrs_gate 负责随水平速度把该增量平滑关掉。
dv_vrs_bar = f_vrs * vrs_gate * ...
    (desired_vi_bar / max(kappa, tol) - v_base_bar);
% 前两项恢复成 m/s，最后按主公式施加非理想系数 kappa。
v_base = v_base_bar * v_h;
dv_vrs = dv_vrs_bar * v_h;
vi_qs = kappa * (v_base + dv_vrs);
% 只有“在几何区域内”且“有效修正仍大于容差”时才报告 VRS 有效。
vrs_flag = inside_vrs && (f_vrs * vrs_gate > tol);

%% 第 7 步：处理无效输入并返回准定常结果
% 无效输入返回安全零值，并通过 input_valid 告知调用方。
if ~input_valid
    vi_qs = 0;
    v_base = 0;
    dv_vrs = 0;
    vrs_flag = false;
end
end

function v = baseline_dimless(nu, mu, VzA, VzB, muC, tol)
%BASELINE_DIMLESS 混合轴向基线与斜流动量理论的无量纲诱导速度。
% 为什么需要：纯轴向动量理论适合小 mu，斜流动量理论适合明显水平来流；
% 用 smoothstep 在两者间平滑过渡，避免切换产生折角。
[v_axial, ~] = axial_baseline(nu, VzA, VzB, tol);
v_momentum = oblique_momentum(mu, nu, max(v_axial, tol), tol);

blend_arg = min(max(mu / max(muC, tol), 0), 1);
blend = smoothstep(blend_arg);
v = (1 - blend) * v_axial + blend * v_momentum;
end

function [v, dvdnu] = axial_baseline(nu, VzA, VzB, tol)
%AXIAL_BASELINE 计算轴向飞行基线及其对 nu 的导数。
% 为什么需要：正常工作态和风车制动态都有解析分支，但两者之间的普通
% 动量理论不可直接使用，因此 A~B 区间用 Hermite 曲线连接。
if nu >= VzA
    % 正常工作状态的动量理论分支。
    root_term = sqrt((nu/2)^2 + 1);
    v = -nu/2 + root_term;
    dvdnu = -0.5 + nu / (4 * root_term);
elseif nu <= VzB
    % 风车制动状态的动量理论分支。
    root_term = sqrt(max((nu/2)^2 - 1, tol));
    v = -nu/2 - root_term;
    dvdnu = -0.5 - nu / (4 * root_term);
else
    % 动量理论失效区使用 Hermite 曲线连接两侧分支。
    [vA, mA] = normal_branch(VzA);
    [vB, mB] = windmill_branch(VzB, tol);
    v = cubic_hermite(nu, VzB, vB, mB, VzA, vA, mA);
    h = 1e-5;
    vp = cubic_hermite(nu + h, VzB, vB, mB, VzA, vA, mA);
    vm = cubic_hermite(nu - h, VzB, vB, mB, VzA, vA, mA);
    dvdnu = (vp - vm) / (2*h);
end
end

function [v, slope] = normal_branch(nu)
%NORMAL_BRANCH 正常工作状态分支及解析斜率。
root_term = sqrt((nu/2)^2 + 1);
v = -nu/2 + root_term;
slope = -0.5 + nu / (4 * root_term);
end

function [v, slope] = windmill_branch(nu, tol)
%WINDMILL_BRANCH 风车制动状态分支及解析斜率。
root_term = sqrt(max((nu/2)^2 - 1, tol));
v = -nu/2 - root_term;
slope = -0.5 - nu / (4 * root_term);
end

function v = oblique_momentum(mu, nu, initial, tol)
%OBLIQUE_MOMENTUM 用牛顿迭代求解斜流动量理论隐式方程。
% 为什么需要迭代：诱导速度同时出现在方程两边，不能直接显式求出。
v = max(initial, 0.05);
for k = 1:40
    s = sqrt(mu^2 + (nu + v)^2 + tol);
    residual = v * s - 1;
    derivative = s + v * (nu + v) / s;
    % 导数过小会使牛顿步失稳，此时保留当前迭代值。
    if abs(derivative) < tol
        break;
    end
    next = v - residual / derivative;
    % 非法或非正牛顿步采用折半回退，保持诱导速度为正。
    if ~isfinite(next) || next <= 0
        next = 0.5 * v;
    end
    if abs(next - v) < tol
        v = next;
        break;
    end
    v = next;
end
end

function [q, slope] = baseline_q_and_slope(nu, mu, kappa, VzA, VzB, muC, tol)
%BASELINE_Q_AND_SLOPE 用中心差分计算总入流基线及局部斜率。
% 为什么需要：D、E 处的 VRS 曲线必须以相同函数值和斜率接回基线。
h = 1e-5;
v = baseline_dimless(nu, mu, VzA, VzB, muC, tol);
vp = baseline_dimless(nu + h, mu, VzA, VzB, muC, tol);
vm = baseline_dimless(nu - h, mu, VzA, VzB, muC, tol);
q = nu + kappa * v;
slope = 1 + kappa * (vp - vm) / (2*h);
end

function y = cubic_hermite(x, x0, y0, m0, x1, y1, m1)
%CUBIC_HERMITE 按两端函数值和斜率进行三次 Hermite 插值。
dx = x1 - x0;
if abs(dx) < 1e-12
    y = 0.5 * (y0 + y1);
    return;
end
s = (x - x0) / dx;
h00 = 2*s^3 - 3*s^2 + 1;
h10 = s^3 - 2*s^2 + s;
h01 = -2*s^3 + 3*s^2;
h11 = s^3 - s^2;
y = h00*y0 + h10*dx*m0 + h01*y1 + h11*dx*m1;
end

function y = smoothstep(x)
%SMOOTHSTEP 在 [0,1] 上提供端点斜率为零的平滑门函数。
y = x*x*(3 - 2*x);
end
