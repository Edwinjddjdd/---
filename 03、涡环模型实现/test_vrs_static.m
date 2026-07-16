%TEST_VRS_STATIC 静态曲线、开关和连接连续性检查。

P = vrs_params();
T = P.demo.T_ref;
hover = vrs_johnson_qs(0, 0, T, P);
assert(hover.input_valid, 'Hover input should be valid.');
assert(isfinite(hover.v_i_qs) && hover.v_i_qs > 0, ...
    'Hover induced velocity must be finite and positive.');

nu = linspace(-3, 1, 401).';
V_d = -nu * hover.v_h;
v_base = zeros(size(nu));
v_i_qs = zeros(size(nu));
vrs_flag = false(size(nu));

for k = 1:numel(nu)
    out = vrs_johnson_qs(0, V_d(k), T, P);
    v_base(k) = out.v_base / out.v_h;
    v_i_qs(k) = out.v_i_qs / out.v_h;
    vrs_flag(k) = out.vrs_flag;
end

assert(all(isfinite(v_base)), 'Baseline curve contains non-finite values.');
assert(all(isfinite(v_i_qs)), 'VRS curve contains non-finite values.');
assert(any(vrs_flag), 'The vertical-descent sweep did not enter VRS.');

% D/N/X/E continuity and N/X neutral-slope checks on total axial inflow.
eps_nu = 1e-5;
joins = [P.boundary.VzD, P.boundary.VzN, ...
    P.boundary.VzX, P.boundary.VzE];
for x0 = joins
    left = vrs_johnson_qs(0, -(x0 - eps_nu)*hover.v_h, T, P);
    right = vrs_johnson_qs(0, -(x0 + eps_nu)*hover.v_h, T, P);
    q_left = (x0 - eps_nu) + left.v_i_qs / left.v_h;
    q_right = (x0 + eps_nu) + right.v_i_qs / right.v_h;
    assert(abs(q_left - q_right) < 2e-3, ...
        'Total inflow is discontinuous at a Johnson join point.');
end

for x0 = [P.boundary.VzN, P.boundary.VzX]
    left = vrs_johnson_qs(0, -(x0 - eps_nu)*hover.v_h, T, P);
    right = vrs_johnson_qs(0, -(x0 + eps_nu)*hover.v_h, T, P);
    q_left = (x0 - eps_nu) + left.v_i_qs / left.v_h;
    q_right = (x0 + eps_nu) + right.v_i_qs / right.v_h;
    slope = (q_right - q_left) / (2*eps_nu);
    assert(abs(slope) < 2e-3, ...
        'N/X total-inflow slope should be zero.');
end

P_off = P;
P_off.model.f_vrs = 0;
P_off.vector(5) = 0;
off = vrs_johnson_qs(0, hover.v_h, T, P_off);
assert(~off.vrs_flag, 'VRS flag must be off when f_vrs is zero.');
assert(abs(off.dv_vrs) < 1e-10, 'VRS increment must vanish when disabled.');

fig = figure('Name', 'Johnson VRS static curve', 'Color', 'w');
plot(nu, v_base, '--', 'LineWidth', 1.3);
hold on;
plot(nu, v_i_qs, 'LineWidth', 1.8);
grid on;
xlabel('V_z / v_h');
ylabel('v / v_h');
legend('v_{base}', 'v_{i,QS}', 'Location', 'best');
title('Johnson 型准定常诱导速度');
exportgraphics(fig, 'vrs_static_curve.png', 'Resolution', 160);

fprintf('Static VRS checks passed. Hover v_h = %.3f m/s, vi0 = %.3f m/s.\n', ...
    hover.v_h, hover.v_i_qs);
