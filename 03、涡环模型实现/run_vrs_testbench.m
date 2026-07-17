%RUN_VRS_TESTBENCH 运行悬停、垂直下降进入 VRS、水平速度改出场景。
% 这个脚本不定义物理模型，只负责：准备输入场景 -> 调用 Simulink ->
% 取出结果 -> 画图。模型计算本身位于 vrs_johnson_qs_numeric.m 和 slx 中。

%% 第 1 步：准备模型参数、参考拉力和积分器初值
init_vrs_model;
model = 'vrs_inflow_testbench';

%% 第 2 步：人为设计一条“悬停 -> 进入 VRS -> 水平改出”的输入时间线
t = (0:0.05:40).';

% 构造输入工况：0~5 s 悬停，5~15 s 加速下降进入 VRS；
% 25~35 s 增加水平速度，使旋翼逐步退出 VRS 修正区域。
V_H = zeros(size(t));
V_H(t >= 25 & t < 35) = 1.5 * (t(t >= 25 & t < 35) - 25);
V_H(t >= 35) = 15;

V_d = zeros(size(t));
V_d(t >= 5 & t < 15) = 1.1 * (t(t >= 5 & t < 15) - 5);
V_d(t >= 15) = 11;

T = T_ref * ones(size(t));

%% 第 3 步：把三条时间序列送入 Simulink 顶层输入端口
% 外部输入端口顺序必须与模型顶层的 V_H、V_d、T 三个端口一致。
ds = Simulink.SimulationData.Dataset;
ds{1} = timeseries(V_H, t);
ds{2} = timeseries(V_d, t);
ds{3} = timeseries(T, t);

in = Simulink.SimulationInput(model);
in = in.setExternalInput(ds);
in = in.setVariable('P_vrs', P_vrs);
in = in.setVariable('T_ref', T_ref);
in = in.setVariable('vi0', vi0);
in = in.setModelParameter('StopTime', '40', 'MaxStep', '0.05');
%% 第 4 步：运行模型；从这里开始才真正进行动态积分
out = sim(in);

%% 第 5 步：按顶层输出端口顺序提取结果
vi = out.yout.getElement(1).Values;
vi_qs = out.yout.getElement(2).Values;
flag = out.yout.getElement(3).Values;
vbase = out.yout.getElement(5).Values;

%% 第 6 步：画进入过程，比较基线、准定常目标和实际动态响应
% 图 3：仅显示水平改出前的进入和发展阶段。
fig_entry = figure('Name', '进入 VRS 的时间历程', 'Color', 'w');
plot(vi_qs.Time, vi_qs.Data, '--', 'LineWidth', 1.5);
hold on;
plot(vi.Time, vi.Data, 'LineWidth', 1.8);
plot(vbase.Time, vbase.Data, ':', 'LineWidth', 1.5);
grid on;
xlim([0 25]);
xlabel('时间 / s');
ylabel('诱导速度 / (m/s)');
legend('v_{i,QS}', 'v_i', 'v_{base}', 'Location', 'best');
title('垂直下降进入涡环状态');
exportgraphics(fig_entry, '03_vrs_entry_time_history.png', 'Resolution', 180);

%% 第 7 步：重建诊断用门控强度，并画水平改出过程
% 这里只为绘图计算强度，不再反馈到模型中，不会重复施加 VRS 修正。
mu = V_H / hover.v_h;
gate_arg = min(max(mu / P_vrs.boundary.muM, 0), 1);
horizontal_gate = 1 - gate_arg.^2 .* (3 - 2*gate_arg);
vrs_strength = P_vrs.model.f_vrs .* horizontal_gate .* double(flag.Data(:));

% 图 4：展示水平速度增加时 VRS 修正逐步退出。
fig_exit = figure('Name', 'VRS 状态变化', 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile;
plot(t, V_H / hover.v_h, 'LineWidth', 1.6);
grid on;
xlim([20 40]);
ylabel('V_H/v_h');
title('水平速度增加与涡环改出');

nexttile;
plot(t, vrs_strength, 'LineWidth', 1.8);
hold on;
stairs(flag.Time, double(flag.Data), '--', 'LineWidth', 1.5);
grid on;
xlim([20 40]);
ylim([-0.05 1.05]);
xlabel('时间 / s');
ylabel('状态量');
legend('vrs\_strength', 'vrs\_flag', 'Location', 'best');
exportgraphics(fig_exit, '04_vrs_state_change.png', 'Resolution', 180);
