%TEST_VRS_STATIC 静态曲线、VRS 边界、开关和连接连续性检查。
% 为什么先做静态测试：若准定常曲线本身不连续或门控方向错误，接入
% Integrator 后只会让问题更难定位；因此本脚本先隔离验证代数算法。

%% 第 1 步：建立悬停参考点，确认最基本的输入和输出有效
P = vrs_params();
T = P.demo.T_ref;

% 悬停点既用于检查基本物理合理性，也用作无量纲化基准。
hover = vrs_johnson_qs(0, 0, T, P);
assert(hover.input_valid, 'Hover input should be valid.');
assert(isfinite(hover.v_i_qs) && hover.v_i_qs > 0, ...
    'Hover induced velocity must be finite and positive.');

%% 第 2 步：扫描垂直下降率，确认曲线确实穿过 VRS 区域
% 在纯垂直下降条件下扫描无量纲下降率 lambda_d = V_d/v_h。
lambda_d = linspace(0, 3, 401).';
V_d = lambda_d * hover.v_h;
v_base = zeros(size(lambda_d));
v_i_qs = zeros(size(lambda_d));
vrs_flag = false(size(lambda_d));

for k = 1:numel(lambda_d)
    out = vrs_johnson_qs(0, V_d(k), T, P);
    v_base(k) = out.v_base / out.v_h;
    v_i_qs(k) = out.v_i_qs / out.v_h;
    vrs_flag(k) = out.vrs_flag;
end

% 扫描结果必须保持有限，且至少有一个工况落入 VRS 区域。
assert(all(isfinite(v_base)), 'Baseline curve contains non-finite values.');
assert(all(isfinite(v_i_qs)), 'VRS curve contains non-finite values.');
assert(any(vrs_flag), 'The vertical-descent sweep did not enter VRS.');

%% 第 3 步：检查 D/N/X/E 处没有数值跳变
% 检查连接点处总轴向入流的连续性。
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

%% 第 4 步：检查 N、X 是否满足零斜率设计条件
% N、X 是零斜率控制点，使用中心差分验证连接处斜率。
for x0 = [P.boundary.VzN, P.boundary.VzX]
    left = vrs_johnson_qs(0, -(x0 - eps_nu)*hover.v_h, T, P);
    right = vrs_johnson_qs(0, -(x0 + eps_nu)*hover.v_h, T, P);
    q_left = (x0 - eps_nu) + left.v_i_qs / left.v_h;
    q_right = (x0 + eps_nu) + right.v_i_qs / right.v_h;
    slope = (q_right - q_left) / (2*eps_nu);
    assert(abs(slope) < 2e-3, ...
        'N/X total-inflow slope should be zero.');
end

%% 第 5 步：做总开关测试，排除“关不掉”的实现错误
% 将强度系数置零后，VRS 标志和修正增量都应关闭。
P_off = P;
P_off.model.f_vrs = 0;
P_off.vector(5) = 0;
off = vrs_johnson_qs(0, hover.v_h, T, P_off);
assert(~off.vrs_flag, 'VRS flag must be off when f_vrs is zero.');
assert(abs(off.dv_vrs) < 1e-10, 'VRS increment must vanish when disabled.');

% 图 1：垂直下降无量纲诱导速度，比较基线和 Johnson 修正结果。
fig_curve = figure('Name', '垂直下降无量纲诱导速度曲线', 'Color', 'w');
plot(lambda_d, v_base, '--', 'LineWidth', 1.5);
hold on;
plot(lambda_d, v_i_qs, 'LineWidth', 1.8);
grid on;
xlabel('V_d/v_h');
ylabel('v_i/v_h');
legend('v_{base}/v_h', 'v_{i,QS}/v_h', 'Location', 'best');
title('垂直下降：基线诱导速度与 Johnson 涡环修正');
exportgraphics(fig_curve, '01_vertical_descent_inflow_curve.png', ...
    'Resolution', 180);

% 图 2：在 mu-lambda_d 平面划分进入、发展和退出区域。
mu_grid = linspace(0, 1.1, 181);
lambda_grid = linspace(0, 2.4, 241);
[MU, LAMBDA_D] = meshgrid(mu_grid, lambda_grid);
region = zeros(size(MU));

for k = 1:numel(MU)
    mu_k = MU(k);
    nu_k = -LAMBDA_D(k);
    if mu_k >= P.boundary.muM || ...
            nu_k > P.boundary.VzD || nu_k < P.boundary.VzE
        continue;
    end

    % N、X 边界随水平速度增加向中点收拢。
    gate_arg = min(max(mu_k / P.boundary.muM, 0), 1);
    move_arg = max(0, 1 - gate_arg^2);
    midpoint = 0.5 * (P.boundary.VzN + P.boundary.VzX);
    halfspan = 0.5 * (P.boundary.VzN - P.boundary.VzX);
    VzN_star = midpoint + halfspan * move_arg^0.2;
    VzX_star = midpoint - halfspan * move_arg^1.5;

    if nu_k >= VzN_star
        region(k) = 1;  % D-N：进入区
    elseif nu_k >= VzX_star
        region(k) = 2;  % N-X：发展区
    else
        region(k) = 3;  % X-E：退出区
    end
end

fig_boundary = figure('Name', 'VRS 边界图', 'Color', 'w');
imagesc(mu_grid, lambda_grid, region);
set(gca, 'YDir', 'normal');
colormap([0.94 0.94 0.94; 1.00 0.78 0.35; ...
    0.86 0.25 0.20; 0.35 0.65 0.88]);
clim([-0.5 3.5]);
cb = colorbar('Ticks', 0:3, ...
    'TickLabels', {'非 VRS', '进入区', '发展区', '退出区'});
cb.Label.String = '涡环状态区域';
xlabel('V_H/v_h');
ylabel('V_d/v_h');
title('Johnson 涡环状态边界');
grid on;
exportgraphics(fig_boundary, '02_vrs_boundary_map.png', 'Resolution', 180);

fprintf(['Static VRS checks passed. Hover v_h = %.3f m/s, ' ...
    'vi0 = %.3f m/s.\n'], hover.v_h, hover.v_i_qs);
