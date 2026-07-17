%OPEN_VRS_MODEL 初始化并打开涡环测试台及其核心子系统。

% 先准备基础工作区变量，再打开顶层模型和 VRS 入流子系统。
init_vrs_model;
open_system('vrs_inflow_testbench.slx');
open_system('vrs_inflow_testbench/VRS_Inflow');
