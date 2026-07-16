%RUN_VRS_TESTBENCH 运行悬停、垂直下降进入 VRS、水平速度改出场景。

init_vrs_model;
model = 'vrs_inflow_testbench';

if ~isfile(model + ".slx")
    build_vrs_model;
end

t = (0:0.05:40).';

% 0-5 s hover; 5-15 s descend into VRS; 25-35 s add horizontal speed.
V_H = zeros(size(t));
V_H(t >= 25 & t < 35) = 1.5 * (t(t >= 25 & t < 35) - 25);
V_H(t >= 35) = 15;

V_d = zeros(size(t));
V_d(t >= 5 & t < 15) = 1.1 * (t(t >= 5 & t < 15) - 5);
V_d(t >= 15) = 11;

T = T_ref * ones(size(t));

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
out = sim(in);

vi = out.yout.getElement(1).Values;
vi_qs = out.yout.getElement(2).Values;
flag = out.yout.getElement(3).Values;
q = out.yout.getElement(4).Values;
vbase = out.yout.getElement(5).Values;
dvvrs = out.yout.getElement(6).Values;

assert(all(isfinite(vi.Data)), 'Dynamic induced velocity contains non-finite values.');
assert(all(isfinite(vi_qs.Data)), 'Target induced velocity contains non-finite values.');
assert(any(flag.Data(t >= 10 & t <= 25) > 0), ...
    'The descent scenario did not enter VRS.');
assert(all(flag.Data(t >= 38) == 0), ...
    'The horizontal-speed recovery did not leave the VRS correction region.');

fig = figure('Name', 'VRS inflow testbench', 'Color', 'w');
tiledlayout(3, 1);

nexttile;
plot(vi_qs.Time, vi_qs.Data, '--', 'LineWidth', 1.3);
hold on;
plot(vi.Time, vi.Data, 'LineWidth', 1.7);
plot(vbase.Time, vbase.Data, ':', 'LineWidth', 1.2);
grid on;
ylabel('m/s');
legend('v_{i,QS}', 'v_i', 'v_{base}', 'Location', 'best');

nexttile;
plot(t, V_d, 'LineWidth', 1.5);
hold on;
plot(t, V_H, 'LineWidth', 1.5);
grid on;
ylabel('m/s');
legend('V_d', 'V_H', 'Location', 'best');

nexttile;
stairs(flag.Time, double(flag.Data), 'LineWidth', 1.5);
hold on;
plot(q.Time, q.Data, 'LineWidth', 1.3);
plot(dvvrs.Time, dvvrs.Data, ':', 'LineWidth', 1.2);
grid on;
xlabel('Time / s');
legend('vrs flag', 'q', '\Deltav_{VRS}', 'Location', 'best');

exportgraphics(fig, 'vrs_testbench_results.png', 'Resolution', 160);

fprintf('Dynamic simulation passed. vi range: %.3f to %.3f m/s.\n', ...
    min(vi.Data), max(vi.Data));
fprintf('VRS entered: %d; final VRS flag: %d.\n', ...
    any(flag.Data > 0), flag.Data(end));
