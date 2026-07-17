function P = vrs_params()
%VRS_PARAMS Johnson VRS 第一版演示参数。
% 参数来源：NASA/TP-2005-213477 中的 D6075 算例和表 4 标称边界。
% 这些参数只用于跑通结构，不代表本课题最终目标机参数。
% 为什么单独放一个参数文件：换旋翼、换大气条件或重新标定 VRS 边界时，
% 只改这里，不改算法函数和 Simulink 连线。

P.source = "NASA/TP-2005-213477 D6075 demonstration";

% 环境与旋翼几何/运动参数。
P.environment.rho = 1.225;              % kg/m^3
P.rotor.R = 5.97;                       % m
P.rotor.Omega = 360 * 2*pi / 60;       % rad/s
P.rotor.mass_demo = 3500;               % kg
P.rotor.g = 9.80665;                    % m/s^2

% 模型修正参数：非理想诱导损失、VRS 增量强度和动态响应圈数。
P.model.kappa = 1.10;                   % 非理想诱导损失系数
P.model.f_vrs = 1.00;                   % VRS 诱导速度增量强度
P.model.tau_rev = 14;                   % 动态入流时间常数对应的旋翼转数

% 无量纲轴向速度边界及对应的总入流控制点。
P.boundary.VzA = -1.50;                 % 基线曲线连接点 A
P.boundary.VzB = -2.10;                 % 基线曲线连接点 B
P.boundary.VzD = -0.20;                 % VRS 修正起点 D
P.boundary.VzN = -0.45;                 % 上侧零斜率点 N
P.boundary.qN = 0.85;                   % N 点无量纲总入流
P.boundary.VzX = -1.50;                 % 下侧零斜率点 X
P.boundary.qX = 1.25;                   % X 点无量纲总入流
P.boundary.VzE = -2.00;                 % VRS 修正终点 E
P.boundary.muC = 0.75;                  % 基线完全过渡至斜流动量理论的横向速度比
P.boundary.muM = 0.95;                  % VRS 修正完全关闭的横向速度比

% 数值保护参数，避免零拉力或除零导致计算发散。
P.numeric.T_min = 1.0;                  % N, numerical protection only
P.numeric.tol = 1e-10;

% 演示工况以整机重量作为悬停参考拉力。
P.demo.T_ref = P.rotor.mass_demo * P.rotor.g;

% 为什么还要打包 P.vector：MATLAB 脚本中用 P.xxx 更易读，但 Simulink
% MATLAB Function 块使用固定长度纯数值向量更稳定。此顺序必须与
% vrs_johnson_qs_numeric.m 的第 1 步解包顺序逐项一致。
P.vector = [ ...
    P.environment.rho; ...
    P.rotor.R; ...
    P.rotor.Omega; ...
    P.model.kappa; ...
    P.model.f_vrs; ...
    P.model.tau_rev; ...
    P.boundary.VzA; ...
    P.boundary.VzB; ...
    P.boundary.VzD; ...
    P.boundary.VzN; ...
    P.boundary.qN; ...
    P.boundary.VzX; ...
    P.boundary.qX; ...
    P.boundary.VzE; ...
    P.boundary.muC; ...
    P.boundary.muM; ...
    P.numeric.T_min; ...
    P.numeric.tol];
end
