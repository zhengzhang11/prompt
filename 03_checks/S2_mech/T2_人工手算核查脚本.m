%% T2_人工手算核查脚本.m
% S2 任务二：按当前冻结参数对 57BLF02 方案做人工手算核查
% 用途：
% 1. 输出关键中间量与最终量，供人工逐项核对
% 2. 与 00_frozen/params.md 中的冻结值做偏差比较
% 3. 为 03_checks/S2_mech 正式校验笔记提供可复现计算依据

clear; clc;

fprintf('\n========== S2 T2 人工手算核查：57BLF02 冻结方案 ==========\n\n');

%% 一、题设与冻结参数
m = 50;                % kg
r = 0.08;              % m
f = 0.04;              % -
alpha_deg = 5;         % deg
eta_m = 0.90;          % -
g = 9.81;              % m/s^2
n_low = 60;            % rpm
n_high = 240;          % rpm
i_ratio = 12.5;        % -
m_w = 1.5;             % kg
J_m = 1.7e-5;          % kg*m^2
t_r = 0.8;             % s

%% 二、手算过程
omega_w_low = 2*pi*n_low/60;
omega_w_high = 2*pi*n_high/60;

N_1 = m*g/2;
F_r_1 = f * N_1;
T_L_flat_w = F_r_1 * r;

N_1_alpha = (m*g/2) * cosd(alpha_deg);
F_g_1 = (m*g/2) * sind(alpha_deg);
F_r_1_alpha = f * N_1_alpha;
F_sum_1 = F_r_1_alpha + F_g_1;
T_L_slope_w = F_sum_1 * r;

n_m_max = n_high * i_ratio;
omega_m = n_m_max * pi / 30;

T_L_m_flat = T_L_flat_w / (i_ratio * eta_m);
T_L_m_slope = T_L_slope_w / (i_ratio * eta_m);

J_v_w = m * r^2 / 4;
J_w = m_w * r^2 / 2;
J_L_m = (J_v_w + J_w) / i_ratio^2;
J_eq = J_m + J_L_m;

dot_omega_m = omega_m / t_r;
T_accel = J_eq * dot_omega_m;
T_m_peak = T_accel + T_L_m_slope;
P_m_steady = T_L_m_slope * omega_m;

%% 三、冻结参考值
refs = struct(...
    'omega_w_low', 6.283, ...
    'omega_w_high', 25.133, ...
    'T_L_flat_w', 0.785, ...
    'T_L_slope_w', 2.492, ...
    'n_m_max', 3000, ...
    'omega_m', 314.16, ...
    'T_L_m_flat', 0.0698, ...
    'T_L_m_slope', 0.2215, ...
    'J_v_w', 0.08, ...
    'J_w', 4.8e-3, ...
    'J_L_m', 5.43e-4, ...
    'J_eq', 5.60e-4, ...
    'T_accel', 0.2199, ...
    'T_m_peak', 0.4414, ...
    'P_m_steady', 69.6);

%% 四、打印结果
fprintf('【基础量】\n');
fprintf('omega_w_low   = %.6f rad/s\n', omega_w_low);
fprintf('omega_w_high  = %.6f rad/s\n', omega_w_high);
fprintf('N_1           = %.6f N\n', N_1);
fprintf('F_r_1         = %.6f N\n\n', F_r_1);

fprintf('【坡道受力】\n');
fprintf('N_1_alpha     = %.6f N\n', N_1_alpha);
fprintf('F_g_1         = %.6f N\n', F_g_1);
fprintf('F_r_1_alpha   = %.6f N\n', F_r_1_alpha);
fprintf('F_sum_1       = %.6f N\n', F_sum_1);
fprintf('T_L_flat_w    = %.6f N*m\n', T_L_flat_w);
fprintf('T_L_slope_w   = %.6f N*m\n\n', T_L_slope_w);

fprintf('【折算到电机轴】\n');
fprintf('n_m_max       = %.6f rpm\n', n_m_max);
fprintf('omega_m       = %.6f rad/s\n', omega_m);
fprintf('T_L_m_flat    = %.6f N*m\n', T_L_m_flat);
fprintf('T_L_m_slope   = %.6f N*m\n\n', T_L_m_slope);

fprintf('【惯量与动态】\n');
fprintf('J_v_w         = %.6e kg*m^2\n', J_v_w);
fprintf('J_w           = %.6e kg*m^2\n', J_w);
fprintf('J_L_m         = %.6e kg*m^2\n', J_L_m);
fprintf('J_m           = %.6e kg*m^2\n', J_m);
fprintf('J_eq          = %.6e kg*m^2\n', J_eq);
fprintf('dot_omega_m   = %.6f rad/s^2\n', dot_omega_m);
fprintf('T_accel       = %.6f N*m\n', T_accel);
fprintf('T_m_peak      = %.6f N*m\n', T_m_peak);
fprintf('P_m_steady    = %.6f W\n\n', P_m_steady);

%% 五、与冻结值对比
fprintf('【与冻结值对比】\n');

items = {
    'omega_w_low',  omega_w_low;
    'omega_w_high', omega_w_high;
    'T_L_flat_w',   T_L_flat_w;
    'T_L_slope_w',  T_L_slope_w;
    'n_m_max',      n_m_max;
    'omega_m',      omega_m;
    'T_L_m_flat',   T_L_m_flat;
    'T_L_m_slope',  T_L_m_slope;
    'J_v_w',        J_v_w;
    'J_w',          J_w;
    'J_L_m',        J_L_m;
    'J_eq',         J_eq;
    'T_accel',      T_accel;
    'T_m_peak',     T_m_peak;
    'P_m_steady',   P_m_steady;
};

pass_all = true;
for k = 1:size(items, 1)
    name = items{k, 1};
    value = items{k, 2};
    ref = refs.(name);

    if ref == 0
        err_pct = 0;
    else
        err_pct = abs((value - ref) / ref) * 100;
    end

    status = 'OK';
    if err_pct >= 1
        status = 'WARN';
        pass_all = false;
    end

    fprintf('[%s] %-12s value=%12.6g  ref=%12.6g  err=%8.4f%%%%\n', ...
        status, name, value, ref, err_pct);
end

fprintf('\n【人工核查建议】\n');
fprintf('1. 优先手算 T_L_m_slope、J_eq、T_m_peak 三个量。\n');
fprintf('2. 若脚本与手算偏差 < 1%%%%，可在校验笔记中判定 T2 通过。\n');
fprintf('3. 若偏差 >= 1%%%%，先检查单位换算，再检查减速比是否仍误用旧值 20。\n');

if pass_all
    fprintf('\n结论：全部关键量与冻结值一致，T2 可判定通过。\n');
else
    fprintf('\n结论：存在偏差项，请先人工复核后再写入正式校验笔记。\n');
end

fprintf('\n========== T2 核查脚本运行结束 ==========\n\n');