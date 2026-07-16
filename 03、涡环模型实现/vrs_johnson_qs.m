function out = vrs_johnson_qs(V_H, V_d, T, P)
%VRS_JOHNSON_QS 易读的结构体接口，供 MATLAB 扫掠和调试使用。

[out.v_i_qs, out.v_base, out.dv_vrs, out.vrs_flag, ...
    out.tau, out.v_h, out.mu, out.nu, out.input_valid] = ...
    vrs_johnson_qs_numeric(V_H, V_d, T, P.vector);

out.V_z = -V_d;
end
