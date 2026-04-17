%% init_params.m — 全局参数初始化脚本
% robot-servo-sim · 电气传动课程设计
% 所有 Simulink 子系统在仿真前必须先运行此脚本
% 参数值以 00_frozen/params.md 为唯一真相源，修改前请先更新 params.md

clear; clc;
fprintf('=== 加载全局参数 ===\n');

%% ── 机械参数 ────────────────────────────────────────────
F       = NaN;      % 负载力 [N]，待填
r       = NaN;      % 传动半径 [m]，待填
i_ratio = NaN;      % 传动比，待填
eta     = NaN;      % 传动效率，待填（题目给定值）

T_load  = F * r / (i_ratio * eta);   % 负载折算转矩 [N·m]
fprintf('负载折算转矩 T_load = %.4f N·m\n', T_load);

%% ── 电机参数（S2 选型后填入）───────────────────────────
T_N     = NaN;      % 额定转矩 [N·m]
T_peak  = NaN;      % 峰值转矩 [N·m]
P_N     = NaN;      % 额定功率 [W]
n_N     = NaN;      % 额定转速 [r/min]
n_max   = NaN;      % 最高转速 [r/min]
omega_N = n_N * pi / 30;   % 额定角速度 [rad/s]

Rs      = NaN;      % 定子电阻 [Ω]
Ls      = NaN;      % 定子电感 [H]（注意单位：mH → H）
Ke      = NaN;      % 反电动势系数 [V·s/rad]
J_m     = NaN;      % 转动惯量 [kg·m²]
p_poles = NaN;      % 极对数

%% ── 主电路参数（S3 设计后填入）──────────────────────────
U_dc    = NaN;      % 直流母线电压 [V]
f_sw    = NaN;      % 开关频率 [Hz]
C_dc    = NaN;      % 直流母线电容 [F]

%% ── 控制器参数（S4 整定后填入）──────────────────────────
% 速度环 PI
Kp_spd  = NaN;
Ki_spd  = NaN;

% 电流环 PI（d 轴）
Kp_id   = NaN;
Ki_id   = NaN;

% 电流环 PI（q 轴）
Kp_iq   = NaN;
Ki_iq   = NaN;

% 仿真步长
Ts      = 1e-5;     % 仿真固定步长 [s]，根据开关频率调整

fprintf('=== 参数加载完成 ===\n');
fprintf('⚠ 含 NaN 的参数尚未填入，请对照 00_frozen/params.md 补充。\n');
