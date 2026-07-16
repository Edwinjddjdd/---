function [vi_qs, v_base, dv_vrs, vrs_flag, tau, v_h, mu, nu, input_valid] = ...
    vrs_johnson_qs_numeric(V_H, V_d, T, p)
%VRS_JOHNSON_QS_NUMERIC Johnson 型准定常 VRS 平均诱导速度。
%   V_H : 桨盘面内速度，m/s，大小为正。
%   V_d : 下降率，m/s，向下为正。
%   T   : 主旋翼拉力，N。
%   p   : vrs_params 返回的数值参数向量。

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

input_valid = isfinite(V_H) && isfinite(V_d) && isfinite(T) && ...
    isfinite(rho) && isfinite(R) && isfinite(Omega) && ...
    rho > 0 && R > 0 && Omega > 0 && T > 0;

T_eff = max(T, T_min);
A = pi * R^2;
v_h = sqrt(T_eff / (2 * rho * A));
mu = abs(V_H) / v_h;
nu = -V_d / v_h;
tau = tau_rev * 2*pi / Omega;

v_base_bar = baseline_dimless(nu, mu, VzA, VzB, muC, tol);
q_base_final = nu + kappa * v_base_bar;

gate_arg = min(max(mu / max(muM, tol), 0), 1);
vrs_gate = 1 - smoothstep(gate_arg);

move_arg = max(0, 1 - gate_arg^2);
midpoint = 0.5 * (VzN + VzX);
halfspan = 0.5 * (VzN - VzX);
VzN_star = midpoint + halfspan * move_arg^0.2;
VzX_star = midpoint - halfspan * move_arg^1.5;

[qD, mD] = baseline_q_and_slope(VzD, mu, kappa, VzA, VzB, muC, tol);
[qE, mE] = baseline_q_and_slope(VzE, mu, kappa, VzA, VzB, muC, tol);

q_target = q_base_final;
inside_vrs = (nu <= VzD) && (nu >= VzE) && (mu < muM);

if inside_vrs
    if nu >= VzN_star
        q_target = cubic_hermite(nu, VzN_star, qN, 0, VzD, qD, mD);
    elseif nu >= VzX_star
        q_target = cubic_hermite(nu, VzX_star, qX, 0, VzN_star, qN, 0);
    else
        q_target = cubic_hermite(nu, VzE, qE, mE, VzX_star, qX, 0);
    end
end

% qN and qX define the final total-inflow curve. Convert its increment back
% inside the kappa-scaled induced-velocity expression.
desired_vi_bar = q_target - nu;
dv_vrs_bar = f_vrs * vrs_gate * ...
    (desired_vi_bar / max(kappa, tol) - v_base_bar);
v_base = v_base_bar * v_h;
dv_vrs = dv_vrs_bar * v_h;
vi_qs = kappa * (v_base + dv_vrs);
vrs_flag = inside_vrs && (f_vrs * vrs_gate > tol);

if ~input_valid
    vi_qs = 0;
    v_base = 0;
    dv_vrs = 0;
    vrs_flag = false;
end
end

function v = baseline_dimless(nu, mu, VzA, VzB, muC, tol)
[v_axial, ~] = axial_baseline(nu, VzA, VzB, tol);
v_momentum = oblique_momentum(mu, nu, max(v_axial, tol), tol);

blend_arg = min(max(mu / max(muC, tol), 0), 1);
blend = smoothstep(blend_arg);
v = (1 - blend) * v_axial + blend * v_momentum;
end

function [v, dvdnu] = axial_baseline(nu, VzA, VzB, tol)
if nu >= VzA
    root_term = sqrt((nu/2)^2 + 1);
    v = -nu/2 + root_term;
    dvdnu = -0.5 + nu / (4 * root_term);
elseif nu <= VzB
    root_term = sqrt(max((nu/2)^2 - 1, tol));
    v = -nu/2 - root_term;
    dvdnu = -0.5 - nu / (4 * root_term);
else
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
root_term = sqrt((nu/2)^2 + 1);
v = -nu/2 + root_term;
slope = -0.5 + nu / (4 * root_term);
end

function [v, slope] = windmill_branch(nu, tol)
root_term = sqrt(max((nu/2)^2 - 1, tol));
v = -nu/2 - root_term;
slope = -0.5 - nu / (4 * root_term);
end

function v = oblique_momentum(mu, nu, initial, tol)
v = max(initial, 0.05);
for k = 1:40
    s = sqrt(mu^2 + (nu + v)^2 + tol);
    residual = v * s - 1;
    derivative = s + v * (nu + v) / s;
    if abs(derivative) < tol
        break;
    end
    next = v - residual / derivative;
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
h = 1e-5;
v = baseline_dimless(nu, mu, VzA, VzB, muC, tol);
vp = baseline_dimless(nu + h, mu, VzA, VzB, muC, tol);
vm = baseline_dimless(nu - h, mu, VzA, VzB, muC, tol);
q = nu + kappa * v;
slope = 1 + kappa * (vp - vm) / (2*h);
end

function y = cubic_hermite(x, x0, y0, m0, x1, y1, m1)
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
y = x*x*(3 - 2*x);
end
