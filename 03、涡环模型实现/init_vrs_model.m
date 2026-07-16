%INIT_VRS_MODEL 将模型参数和悬停初值写入当前工作区。

P_vrs = vrs_params();
T_ref = P_vrs.demo.T_ref;
hover = vrs_johnson_qs(0, 0, T_ref, P_vrs);
vi0 = hover.v_i_qs;

fprintf('VRS demo source: %s\n', P_vrs.source);
fprintf('Reference thrust: %.1f N\n', T_ref);
fprintf('Hover induced-speed initial condition: %.3f m/s\n', vi0);
