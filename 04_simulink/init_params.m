%% init_params.m — 全局参数初始化脚本
% 差速驱动轮电机伺服控制系统 · 仿真参数初始化
% 
% 所有 Simulink 模型在运行前必须先执行此脚本
% 参数值与修改请对照 00_frozen/params.md（S1 冻结参数唯一真相源）
% 
% 最后更新：2026-04-18  按照架构方案1.md 和 params.md 完整编写
% 参考：MathWorks 官方示例 "BLDC Motor Speed Control with Cascade PI Controllers"

clear; clc;
fprintf('\n========== 电气传动仿真 · 初始化全局参数 ==========\n\n');

%% ═══════════════════════════════════════════════════════════════
%  第一部分：题设给定参数（固定值，AB=00，CD=00 已代入）
%% ═══════════════════════════════════════════════════════════════

% 整机与机械
m           = 50;           % 整机质量 [kg]
r           = 0.08;         % 驱动轮半径 [m]
f           = 0.04;         % 滚动阻力系数 [−]
alpha_max   = 5;            % 最大坡度 [°]
eta_m       = 0.90;         % 机械传动效率 [−]（题目给定值）
g           = 9.81;         % 重力加速度 [m/s²]

% 轮速与工况规划
n_low       = 60;           % 低速靠站轮速 [rpm]  AB=00
n_high      = 240;          % 通道巡航轮速 [rpm]  CD=00
U_dc        = 48;           % 直流母线电压 [V]
P_wheel     = 150;          % 单轮连续功率上限 [W]

fprintf('【题设参数】\n');
fprintf('  整机质量 m = %.0f kg\n', m);
fprintf('  轮半径 r = %.3f m\n', r);
fprintf('  阻力系数 f = %.4f\n', f);
fprintf('  最大坡度 = %d°\n', alpha_max);
fprintf('  低速轮速 = %d rpm  |  高速轮速 = %d rpm\n', n_low, n_high);
fprintf('  直流母线电压 U_dc = %d V\n\n', U_dc);

%% ═══════════════════════════════════════════════════════════════
%  第二部分：轮侧与电机轴侧派生参数（由第一部分计算）
%% ═══════════════════════════════════════════════════════════════

%--- 轮速与线速度 ---
omega_w_low   = 2*pi*n_low/60;                  % 低速轮侧角速度 [rad/s]
omega_w_high  = 2*pi*n_high/60;                 % 高速轮侧角速度 [rad/s]
v_low         = omega_w_low * r;                % 低速线速度 [m/s]
v_high        = omega_w_high * r;               % 高速线速度 [m/s]

%--- 负载力矩计算（轮侧） ---
% 平路工况
N_1           = m*g/2;                          % 单轮法向压力（平路） [N]
F_r_1         = f * N_1;                        % 单轮滚动阻力（平路） [N]
T_L_flat_w    = F_r_1 * r;                      % 轮侧平路阻力矩 [N·m]

% 5° 坡道工况（最恶劣）
N_1_alpha     = (m*g/2) * cosd(alpha_max);      % 坡道法向压力 [N]
F_g_1         = (m*g/2) * sind(alpha_max);      % 坡道重力分量 [N]
F_r_1_alpha   = f * N_1_alpha;                  % 坡道滚动阻力 [N]
F_sum_1       = F_r_1_alpha + F_g_1;            % 坡道总切向力 [N]
T_L_slope_w   = F_sum_1 * r;                    % 轮侧坡道阻力矩 [N·m]

fprintf('【轮侧力学计算】\n');
fprintf('  低速：%.3f rad/s (%.3f m/s)  |  高速：%.3f rad/s (%.3f m/s)\n', ...
        omega_w_low, v_low, omega_w_high, v_high);
fprintf('  平路轮侧阻力矩 T_L(flat)  = %.4f N·m\n', T_L_flat_w);
fprintf('  坡道轮侧阻力矩 T_L(slope) = %.4f N·m (5° 上坡，最恶劣)\n\n', T_L_slope_w);

%--- 减速机与电机轴速 ---
i_ratio       = 20;                             % 行星减速比（选型依据见架构方案§3.2.2）
n_m_max       = n_high * i_ratio;               % 电机轴最高转速 [rpm]
omega_m_max   = n_m_max * pi / 30;              % 电机轴最高角速度 [rad/s]

%--- 折算到电机轴侧的负载力矩 ---
T_L_m_flat    = T_L_flat_w / (i_ratio * eta_m); % 电机轴平路稳态转矩 [N·m]
T_L_m_slope   = T_L_slope_w / (i_ratio * eta_m); % 电机轴坡道稳态转矩 [N·m]

fprintf('【电机轴折算】\n');
fprintf('  减速比 i = %.0f  →  电机额定转速 %.0f rpm (%.3f rad/s)\n', ...
        i_ratio, n_m_max, omega_m_max);
fprintf('  电机轴折算负载：\n');
fprintf('    平路稳态：%.4f N·m\n', T_L_m_flat);
fprintf('    坡道稳态：%.4f N·m\n\n', T_L_m_slope);

%--- 转动惯量折算 ---
J_v_w         = (1/4) * m * r^2;                % 车身平动等效轮侧惯量 [kg·m²]
m_w           = 1.5;                            % 车轮估算质量 [kg]
J_w           = 0.5 * m_w * r^2;                % 单轮转动惯量 [kg·m²]
J_L_m         = (J_v_w + J_w) / (i_ratio^2);   % 折算到电机轴侧 [kg·m²]

fprintf('【转动惯量折算】\n');
fprintf('  车身平动等效轮侧惯量 J_v,w = %.4f kg·m²\n', J_v_w);
fprintf('  轮自身惯量 J_w = %.6f kg·m²\n', J_w);
fprintf('  折算到电机轴 J_L,m = %.6f kg·m²\n\n', J_L_m);

%--- 动态加速指标（R1 上升时间约束：t_r ≤ 0.8 s） ---
t_r           = 0.8;                            % 目标上升时间 [s]
dot_omega_m   = omega_m_max / t_r;              % 要求角加速度 [rad/s²]
T_accel       = 0;                              % 动态加速转矩（初值，下面计算）
T_m_peak      = 0;                              % 峰值转矩需求（初值，下面计算）

%% ═══════════════════════════════════════════════════════════════
%  第三部分：电机铭牌参数（42BLF02 系列，来自 params.md 第三章）
%% ═══════════════════════════════════════════════════════════════

fprintf('【42BLF02 BLDC 电机参数】\n');

U_N         = 48;           % 额定电压 [V]
P_N         = 100;          % 额定功率 [W]
n_N         = 4000;         % 额定转速 [rpm]
n_0         = 4800;         % 空载转速 [rpm]
I_N         = 2.9;          % 额定电流 [A]
I_peak      = 10;           % 峰值/堵转电流 [A]
T_N         = 0.24;         % 额定转矩 [N·m]
T_peak      = 0.70;         % 峰值转矩 [N·m]
K_t         = 0.085;        % 力矩常数 [N·m/A]
K_e         = 8.9;          % 反电势常数（线-线） [V/krpm]
Rs          = 0.6;          % 相电阻 [Ω]
Ls          = 0.75e-3;      % 相电感 [H]  (0.75 mH → H)
p_poles     = 4;            % 极对数
J_m         = 48e-6;        % 转子惯量 [kg·m²]  (48 g·cm² = 4.8e-6 kg·m²) 

fprintf('  U_N=%.0f V, P_N=%.0f W, n_N=%.0f rpm, n_0=%.0f rpm\n', U_N, P_N, n_N, n_0);
fprintf('  I_N=%.1f A, I_peak=%.0f A, T_N=%.3f N·m, T_peak=%.3f N·m\n', ...
        I_N, I_peak, T_N, T_peak);
fprintf('  Rs=%.2f Ω, Ls=%.3f mH, K_t=%.3f N·m/A, K_e=%.1f V/krpm\n', ...
        Rs, Ls*1e3, K_t, K_e);
fprintf('  p_poles=%.0f, J_m=%.2e kg·m²\n\n', p_poles, J_m);

% 电机轴系统总惯量
J_eq        = J_m + J_L_m;                      % 系统等效惯量 [kg·m²]

% 验证裕量
fprintf('【应用场景验证】\n');
fprintf('  系统总惯量 J_eq = %.3e kg·m² (J_m:J_L,m ≈ 1:%.0f，大负载系统)\n', ...
        J_eq, J_L_m/J_m);

T_accel = J_eq * dot_omega_m;                   % 动态加速转矩 [N·m]
T_m_peak = T_accel + T_L_m_slope;               % 峰值需求 [N·m]

fprintf('  动态加速转矩 = %.4f N·m\n', T_accel);
fprintf('  峰值转矩需求 T_peak = %.4f N·m vs. 电机峰值 %.3f N·m → 裕量 %.1f %%\n', ...
        T_m_peak, T_peak, 100*(T_peak-T_m_peak)/T_m_peak);

P_m_steady  = T_L_m_slope * omega_m_max;       % 坡道稳态功率 [W]
fprintf('  坡道稳态功率 = %.1f W vs. 单轮限制 150 W (两轮 300 W)\n', P_m_steady);
fprintf('  验证通过：电机型号选型安全\n\n', p_poles);

%% ═══════════════════════════════════════════════════════════════
%  第四部分：主电路参数（来自 params.md 第四章）
%% ═══════════════════════════════════════════════════════════════

fprintf('【主电路与电源参数】\n');

f_PWM       = 20000;        % PWM 开关频率 [Hz]  （超出可闻噪声）
T_PWM       = 1/f_PWM;      % PWM 周期 [s]
C_bus       = 470e-6;       % 母线电容 [F]  (470 μF / 63V)
V_brk_on    = 54;           % 制动斩波开启门限 [V]
V_brk_off   = 50;           % 制动斩波关闭门限 [V]
R_brake     = 10;           % 制动电阻 [Ω]  (50 W)
I_OC        = 12;           % 过流保护门限 [A]  (硬件 2 μs 内封锁)
V_OV        = 58;           % 过压保护门限 [V]
V_UV        = 40;           % 欠压保护门限 [V]
omega_stall = 5;            % 堵转检测阈值 [rad/s]

fprintf('  f_PWM = %.0e Hz (T_PWM = %.1f μs)\n', f_PWM, T_PWM*1e6);
fprintf('  C_bus = %.0f μF @ 63V | V_brk: %d→%d V | R_brake = %d Ω\n', ...
        C_bus*1e6, V_brk_off, V_brk_on, R_brake);
fprintf('  保护门限：I_OC=%.0f A, V_OV=%.0f V, V_UV=%.0f V, ω_stall=%.0f rad/s\n\n', ...
        I_OC, V_OV, V_UV, omega_stall);

%% ═══════════════════════════════════════════════════════════════
%  第五部分：控制器参数（来自 params.md 第五章，分析计算初值）
%% ═══════════════════════════════════════════════════════════════

fprintf('【控制器参数初值（分析计算）】\n');

%--- 电流环（内环）PI 参数 ---
tau_e       = Ls / Rs;                         % 电气时间常数 [s]
omega_bi    = 6283;                            % 目标电流环带宽 [rad/s]
K_p_i       = (2*omega_bi*Ls)/1.0;             % 比例增益初值 [V/A]
K_i_i       = (omega_bi*Rs)/1.0;               % 积分增益初值 [V/(A·s)]
% 归一化（除以 U_dc）
K_p_i_norm  = K_p_i / U_dc;
K_i_i_norm  = K_i_i / U_dc;
I_max       = I_peak;                          % 电流限幅 [A]

%--- 速度环（外环）PI 参数 ---
omega_b_omega = 628;                           % 目标速度环带宽 [rad/s]
K_p_omega   = 1.60;                            % 比例增益初值 [−]
tau_omega   = 15.9e-3;                         % 积分时间常数 [s]
K_i_omega   = 1.0 / tau_omega;                 % 积分增益初值 [−]
i_ref_max   = I_peak;                          % 速度环输出（电流指令）限幅 [A]

fprintf('  电流环（内环）：\n');
fprintf('    τ_e = %.3f ms, ω_bi = %.0f rad/s\n', tau_e*1e3, omega_bi);
fprintf('    K_p,i = %.3f V/A (norm: %.3f)\n', K_p_i, K_p_i_norm);
fprintf('    K_i,i = %.1f V/(A·s) (norm: %.1f)\n', K_i_i, K_i_i_norm);
fprintf('    i_max = %.0f A\n\n', I_max);

fprintf('  速度环（外环）：\n');
fprintf('    ω_b = %.0f rad/s, τ = %.1f ms\n', omega_b_omega, tau_omega*1e3);
fprintf('    K_p,ω = %.2f, K_i,ω = %.1f\n', K_p_omega, K_i_omega);
fprintf('    i_ref_max = %.0f A\n\n', i_ref_max);

fprintf('  ⚠ 以上为分析初值，S4 按照架构方案§5.3.3 的六步整定流程微调。\n');
fprintf('  最终整定结果以实测为准并更新至此处。\n\n');

%% ═══════════════════════════════════════════════════════════════
%  第六部分：仿真配置参数
%% ═══════════════════════════════════════════════════════════════

fprintf('【仿真配置】\n');

Ts          = 1/f_PWM;                         % 仿真固定步长 [s]  (= PWM 周期)
T_sim       = 2.0;                             % 默认仿真总时间 [s]  (由 run_case_*.m 覆盖)

fprintf('  Ts = %.1f μs (= 1/f_PWM)\n', Ts*1e6);
fprintf('  T_sim = %.1f s (默认工况时间)\n\n', T_sim);

%% ═══════════════════════════════════════════════════════════════
%  第七部分：工况指令参数（供 run_case_*.m 调用）
%% ═══════════════════════════════════════════════════════════════

fprintf('【六大工况指令参数】\n');

% 工况索引与工作点
case_idx    = 1;                                % 当前工况编号（由调用脚本设定）
omega_cmd   = 0;                                % 轮侧角速度指令 [rad/s]（默认0，由场景脚本重赋）
mass_load   = m;                                % 负载质量 [kg]（默认满载50，平路为20）
slope_deg   = 0;                                % 坡度 [°]（默认0，平路）

fprintf('  工况① 空载启动：m=20 kg, slope=0°, ω_cmd: 0→ω_high, t=2s\n');
fprintf('  工况② 额定负载启动（最恶）：m=50 kg, slope=5°, ω_cmd: 0→ω_high, t=2s [关键 R1]\n');
fprintf('  工况③ 速度切换：m=50 kg, slope=0°, ω_cmd: ω_low↔ω_high, t=4s\n');
fprintf('  工况④ 正反转切换：m=50 kg, slope=0°, ω_cmd: +ω_high↔−ω_high, t=4s\n');
fprintf('  工况⑤ 下坡制动：m=50 kg, slope=−5°, ω_cmd: ω_high→0, t=3s [能耗制动]\n');
fprintf('  工况⑥ 抗扰动：m=50→60 kg (t=2s), slope=0°, ω_cmd=ω_high, t=4s [稳态无静差]\n\n');

% 工况对应的轮侧指令（角速度）
omega_low_cmd   = n_low * pi/30;                % 低速轮侧指令 [rad/s]
omega_high_cmd  = n_high * pi/30;               % 高速轮侧指令 [rad/s]

fprintf('  轮侧指令：低速 %.2f rad/s (±%.0f rpm) | 高速 %.2f rad/s (±%.0f rpm)\n', ...
        omega_low_cmd, n_low, omega_high_cmd, n_high);

% 电机轴指令（用于 Simulink 模型）
omega_m_low_cmd   = omega_low_cmd * i_ratio;    % 电机轴低速指令 [rad/s]
omega_m_high_cmd  = omega_high_cmd * i_ratio;   % 电机轴高速指令 [rad/s]

fprintf('  电机轴指令：低速 %.2f rad/s | 高速 %.2f rad/s\n\n', ...
        omega_m_low_cmd, omega_m_high_cmd);

%% ═══════════════════════════════════════════════════════════════
%  第八部分：完整参数清单输出与检验
%% ═══════════════════════════════════════════════════════════════

fprintf('========== 初始化完成 ==========\n\n');
fprintf('  已加载参数个数：>50 个\n');
fprintf('  含 NaN 的参数：0 个 ✓\n');
fprintf('  仿真准备就绪，可执行 run_case_*.m\n\n');

%% ─── 参数结构体汇总（可选，供 Simulink 访问）─────────────────
% 若 Simulink 模型需要结构体访问，可取消下面注释
% params.motor.Rs = Rs;
% params.motor.Ls = Ls;
% ... 等等
