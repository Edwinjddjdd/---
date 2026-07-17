function fig = plot_vrs_6dof_comparison(t, V_d, T, v_i, output_file)
%PLOT_VRS_6DOF_COMPARISON 绘制六自由度模型接入 VRS 后的综合时间历程。
%   t           - 时间，s。
%   V_d         - 下降率，m/s，向下为正。
%   T           - 主旋翼拉力，N。
%   v_i         - 实际诱导速度，m/s。
%   output_file - 可选图片路径；省略时保存为默认 PNG 文件。
%
% 示例：
%   fig = plot_vrs_6dof_comparison(tout, V_d, T, v_i);

if nargin < 5
    output_file = '05_vrs_6dof_comparison.png';
end

fig = figure('Name', '六自由度模型 VRS 综合对比', 'Color', 'w');
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
plot(t, V_d, 'LineWidth', 1.6);
grid on;
ylabel('V_d / (m/s)');
title('接入六自由度模型后的综合时间历程');

nexttile;
plot(t, T, 'LineWidth', 1.6);
grid on;
ylabel('T / N');

nexttile;
plot(t, v_i, 'LineWidth', 1.8);
grid on;
xlabel('时间 / s');
ylabel('v_i / (m/s)');

linkaxes(findall(fig, 'Type', 'axes'), 'x');
exportgraphics(fig, output_file, 'Resolution', 180);
end
