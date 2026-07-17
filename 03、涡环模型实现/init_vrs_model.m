%INIT_VRS_MODEL 将模型参数和悬停初值写入当前工作区。
% 为什么需要：Simulink 在编译前必须找到 P_vrs、T_ref 和积分器初值 vi0；
% 统一由此脚本准备，避免每次手动在工作区输入且数值不一致。

% 读取演示参数，并以参考拉力计算悬停诱导速度。
P_vrs = vrs_params();
T_ref = P_vrs.demo.T_ref;
hover = vrs_johnson_qs(0, 0, T_ref, P_vrs);
% 为什么不用 vi0 = 0：从悬停稳态开始时，真实诱导速度已经存在；若置零，
% 仿真开头会人为产生一个与 VRS 无关的大过渡过程。
vi0 = hover.v_i_qs;
