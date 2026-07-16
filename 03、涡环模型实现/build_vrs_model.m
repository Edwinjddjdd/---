%BUILD_VRS_MODEL 创建独立的 VRS 动态入流 Simulink 测试台。

init_vrs_model;

model = 'vrs_inflow_testbench';
modelFile = fullfile(pwd, model + ".slx");

if bdIsLoaded(model)
    close_system(model, 0);
end
if isfile(modelFile)
    delete(modelFile);
end

new_system(model);
open_system(model);

% Top-level external inputs.
add_block('simulink/Sources/In1', model + "/V_H_mps", ...
    'Port', '1', 'Position', [30 70 60 90]);
add_block('simulink/Sources/In1', model + "/V_d_mps", ...
    'Port', '2', 'Position', [30 125 60 145]);
add_block('simulink/Sources/In1', model + "/T_N", ...
    'Port', '3', 'Position', [30 180 60 200]);

subsystem = model + "/VRS_Inflow";
add_block('simulink/Ports & Subsystems/Subsystem', subsystem, ...
    'Position', [150 55 360 220]);
Simulink.SubSystem.deleteContents(subsystem);

% Top-level outputs.
outputNames = ["v_i_mps", "v_i_QS_mps", "vrs_flag", ...
    "q_mps", "v_base_mps", "dv_vrs_mps"];
for k = 1:numel(outputNames)
    y = 45 + 42*k;
    add_block('simulink/Sinks/Out1', model + "/" + outputNames(k), ...
        'Port', string(k), 'Position', [455 y 485 y+20]);
end

% Subsystem inputs.
add_block('simulink/Sources/In1', subsystem + "/V_H_mps", ...
    'Port', '1', 'Position', [30 55 60 75]);
add_block('simulink/Sources/In1', subsystem + "/V_d_mps", ...
    'Port', '2', 'Position', [30 105 60 125]);
add_block('simulink/Sources/In1', subsystem + "/T_N", ...
    'Port', '3', 'Position', [30 155 60 175]);
add_block('simulink/Sources/Constant', subsystem + "/Parameters", ...
    'Value', 'P_vrs.vector', 'Position', [30 215 105 245]);

% Quasi-steady Johnson algorithm.
chartPath = subsystem + "/Johnson_VRS_QS";
add_block('simulink/User-Defined Functions/MATLAB Function', chartPath, ...
    'Position', [165 55 335 245]);

chart = sfroot().find('-isa', 'Stateflow.EMChart', 'Path', chartPath);
assert(~isempty(chart), 'Could not locate the MATLAB Function chart.');
chart.Script = sprintf([ ...
    'function [vi_qs,v_base,dv_vrs,vrs_flag,tau,v_h,mu,nu,input_valid] = fcn(V_H,V_d,T,p)\n' ...
    '%%#codegen\n' ...
    '[vi_qs,v_base,dv_vrs,vrs_flag,tau,v_h,mu,nu,input_valid] = ...\n' ...
    '    vrs_johnson_qs_numeric(V_H,V_d,T,p);\n' ...
    'end\n']);

% Dynamic state: vi_dot = (vi_qs - vi) / tau.
add_block('simulink/Math Operations/Sum', subsystem + "/Target_Minus_Actual", ...
    'Inputs', '+-', 'Position', [395 45 425 85]);
add_block('simulink/Math Operations/Product', subsystem + "/Divide_By_Tau", ...
    'Inputs', '*/', 'Position', [470 45 505 90]);
add_block('simulink/Continuous/Integrator', subsystem + "/Actual_Induced_Velocity", ...
    'InitialCondition', 'vi0', 'Position', [555 50 590 85]);

% Total axial inflow q = vi - Vd.
add_block('simulink/Math Operations/Sum', subsystem + "/Total_Axial_Inflow", ...
    'Inputs', '+-', 'Position', [640 115 675 155]);

% Subsystem outputs.
for k = 1:numel(outputNames)
    y = 25 + 38*k;
    add_block('simulink/Sinks/Out1', subsystem + "/" + outputNames(k), ...
        'Port', string(k), 'Position', [760 y 790 y+20]);
end

add_line(subsystem, 'V_H_mps/1', 'Johnson_VRS_QS/1');
add_line(subsystem, 'V_d_mps/1', 'Johnson_VRS_QS/2');
add_line(subsystem, 'T_N/1', 'Johnson_VRS_QS/3');
add_line(subsystem, 'Parameters/1', 'Johnson_VRS_QS/4');

add_line(subsystem, 'Johnson_VRS_QS/1', 'Target_Minus_Actual/1');
add_line(subsystem, 'Actual_Induced_Velocity/1', 'Target_Minus_Actual/2');
add_line(subsystem, 'Target_Minus_Actual/1', 'Divide_By_Tau/1');
add_line(subsystem, 'Johnson_VRS_QS/5', 'Divide_By_Tau/2');
add_line(subsystem, 'Divide_By_Tau/1', 'Actual_Induced_Velocity/1');

add_line(subsystem, 'Actual_Induced_Velocity/1', 'v_i_mps/1');
add_line(subsystem, 'Johnson_VRS_QS/1', 'v_i_QS_mps/1');
add_line(subsystem, 'Johnson_VRS_QS/4', 'vrs_flag/1');
add_line(subsystem, 'Actual_Induced_Velocity/1', 'Total_Axial_Inflow/1');
add_line(subsystem, 'V_d_mps/1', 'Total_Axial_Inflow/2');
add_line(subsystem, 'Total_Axial_Inflow/1', 'q_mps/1');
add_line(subsystem, 'Johnson_VRS_QS/2', 'v_base_mps/1');
add_line(subsystem, 'Johnson_VRS_QS/3', 'dv_vrs_mps/1');

% Connect the populated subsystem at model root.
add_line(model, 'V_H_mps/1', 'VRS_Inflow/1');
add_line(model, 'V_d_mps/1', 'VRS_Inflow/2');
add_line(model, 'T_N/1', 'VRS_Inflow/3');
for k = 1:numel(outputNames)
    add_line(model, "VRS_Inflow/" + k, outputNames(k) + "/1");
end

set_param(model, ...
    'SolverType', 'Variable-step', ...
    'Solver', 'ode45', ...
    'StopTime', '40', ...
    'MaxStep', '0.05', ...
    'SaveTime', 'on', ...
    'TimeSaveName', 'tout', ...
    'SaveOutput', 'on', ...
    'OutputSaveName', 'yout', ...
    'SaveFormat', 'Dataset', ...
    'InitFcn', 'init_vrs_model');

set_param(model, 'SimulationCommand', 'update');
save_system(model, modelFile);
open_system(subsystem);

fprintf('Built and opened %s\n', modelFile);
