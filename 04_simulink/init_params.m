%% init_params.m — 全局参数初始化脚本
% 差速驱动轮电机伺服控制系统 · 仿真参数初始化
%
% 所有 Simulink 模型在运行前必须先执行此脚本
% 参数值与修改请对照 00_frozen/params.md（S1 冻结参数唯一真相源）
%
% 电机型号：57BLF01（24V/63W/3000rpm），配 48V 母线 + PWM 降压，减速比 12.5:1
% 参考模板：MathWorks Simscape Electrical 官方示例 "BLDC Speed Control"
%           openExample('simscapeelectrical/BLDCSpeedControlExample')
%
% 最后更新：2026-04-18  适配构架方案2（电机选型优化）

clear; clc;
fprintf('\n========== 电气传动仿真 · 初始化全局参数（方案2：57BLF01）==========\n\n');

%% ═══════════════════════════════════════════════════════════════
%  第一部分：题设给定参数（固定值，AB=00，CD=00 已代入）
%% ═══════════════════════════════════════════════════════════════

% 整机与机械（题目给定，禁止修改）
m           = 50;           % 整机质量 [kg]
r           = 0.08;         % 驱动轮半径 [m]
f_roll      = 0.04;         % 滚动阻力系数 [−]
alpha_max   = 5;            % 最大坡度 [°]
eta_m       = 0.90;         % 机械传动效率 [−]
g           = 9.81;         % 重力加速度 [m/s²]

% 轮速指令与母线参数
n_low       = 60;           % 低速靠站轮速 [rpm]  AB=00
n_high      = 240;          % 通道巡航轮速 [rpm]  CD=00
U_dc        = 48;           % 直流母线电压 [V]
P_wheel_max = 150;          % 单轮连续功率上限 [W]

fprintf('【一、题设给定参数】\n');
fprintf('  m=%d kg, r=%.2f m, f=%.2f, alpha_max=%d°, eta_m=%.2f\n', m, r, f_roll, alpha_max, eta_m);
fprintf('  n_low=%d rpm, n_high=%d rpm, U_dc=%d V\n\n', n_low, n_high, U_dc);

%% ═══════════════════════════════════════════════════════════════
%  第二部分：力学派生参数（轮侧 → 电机轴，完整推导链）
%% ═══════════════════════════════════════════════════════════════

%--- 2.1 轮速与线速度 ---
omega_w_low   = 2*pi*n_low  / 60;              % 低速轮侧角速度 [rad/s]  ≈ 6.283
omega_w_high  = 2*pi*n_high / 60;              % 高速轮侧角速度 [rad/s]  ≈ 25.133
v_low         = omega_w_low  * r;              % 低速线速度 [m/s]  ≈ 0.503
v_high        = omega_w_high * r;              % 高速线速度 [m/s]  ≈ 2.011

%--- 2.2 轮侧负载力矩 ---
N_1          = m*g/2;                          % 单轮法向压力（平路）[N]  = 245.25
F_r_1        = f_roll * N_1;                   % 滚动阻力（平路）[N]  = 9.81
T_L_flat_w   = F_r_1 * r;                      % 轮侧平路阻力矩 [N·m]  = 0.785

N_1_alpha    = (m*g/2) * cosd(alpha_max);      % 坡道法向压力 [N]  = 244.32
F_g_1        = (m*g/2) * sind(alpha_max);      % 坡道重力切向分量 [N]  = 21.38
F_r_1_alpha  = f_roll * N_1_alpha;             % 坡道滚动阻力 [N]  = 9.77
F_sum_1      = F_r_1_alpha + F_g_1;            % 坡道总切向力 [N]  = 31.15
T_L_slope_w  = F_sum_1 * r;                    % 轮侧坡道阻力矩 [N·m]  = 2.492

%--- 2.3 减速比与电机轴转速 ---
% 57BLF01 额定转速 3000 rpm → i = 3000/240 = 12.5
i_ratio      = 12.5;                           % 行星减速比（构架方案2 §3.2.2）
n_m_max      = n_high * i_ratio;               % 电机轴最高转速 [rpm]  = 3000
omega_m_max  = n_m_max * pi / 30;              % 电机轴最高角速度 [rad/s]  = 314.16

%--- 2.4 电机轴侧折算负载力矩 ---
T_L_m_flat   = T_L_flat_w  / (i_ratio * eta_m); % 平路稳态折算转矩 [N·m]  = 0.0698
T_L_m_slope  = T_L_slope_w / (i_ratio * eta_m); % 坡道稳态折算转矩 [N·m]  = 0.2215

%--- 2.5 转动惯量折算 ---
J_v_w        = (1/4) * m * r^2;                % 单轮承担平动等效惯量 [kg·m²]  = 0.08
m_w          = 1.5;                            % 车轮估算质量 [kg]
J_w          = 0.5 * m_w * r^2;               % 车轮自身惯量 [kg·m²]  = 4.8e-3
J_L_m        = (J_v_w + J_w) / (i_ratio^2);   % 折算到电机轴侧 [kg·m²]  = 5.43e-4

fprintf('【二、力学派生参数】\n');
fprintf('  轮侧角速度：低速 %.3f rad/s | 高速 %.3f rad/s\n', omega_w_low, omega_w_high);
fprintf('  轮侧阻力矩：平路 %.4f N·m | 坡道 %.4f N·m\n', T_L_flat_w, T_L_slope_w);
fprintf('  减速比 i=%.1f → 电机轴：%.0f rpm (%.3f rad/s)\n', i_ratio, n_m_max, omega_m_max);
fprintf('  电机轴折算：平路 %.4f N·m | 坡道 %.4f N·m\n', T_L_m_flat, T_L_m_slope);
fprintf('  J_v,w=%.4f  J_w=%.5f  J_L,m=%.4e  kg·m²\n\n', J_v_w, J_w, J_L_m);

%% ═══════════════════════════════════════════════════════════════
%  第三部分：电机铭牌参数（57BLF01，构架方案2 §3.2.1）
%% ═══════════════════════════════════════════════════════════════

U_N         = 24;           % 额定电压 [V]（24V型，配48V母线PWM降压）
P_N         = 63;           % 额定功率 [W]
n_N         = 3000;         % 额定转速 [rpm]
I_N         = 4.0;          % 额定电流 [A]
I_peak      = 12;           % 峰值/堵转电流 [A]
T_N         = 0.2;          % 额定转矩 [N·m]
T_peak      = 0.6;          % 峰值转矩 [N·m]
K_t         = 0.065;        % 力矩常数 [N·m/A]
K_e         = 6.23;         % 反电势常数（线-线）[V/krpm]
Rs          = 0.6;          % 相电阻（线-线）[Ω]
Ls          = 0.75e-3;      % 相电感（线-线）[H]  (0.75 mH)
p_poles     = 4;            % 极对数（8极）
J_m         = 1.2e-5;       % 转子惯量 [kg·m²]  (120 g·cm²)

J_eq        = J_m + J_L_m;  % 系统总折算惯量 [kg·m²]  ≈ 5.55e-4

fprintf('【三、57BLF01 电机铭牌参数】\n');
fprintf('  U_N=%d V (24V/48V母线PWM), P_N=%d W, n_N=%d rpm\n', U_N, P_N, n_N);
fprintf('  I_N=%.1f A, I_peak=%d A, T_N=%.2f N·m, T_peak=%.1f N·m\n', I_N, I_peak, T_N, T_peak);
fprintf('  K_t=%.3f N·m/A, K_e=%.2f V/krpm\n', K_t, K_e);
fprintf('  Rs=%.2f Ω, Ls=%.3f mH, p=%d, J_m=%.2e kg·m²\n', Rs, Ls*1e3, p_poles, J_m);
fprintf('  J_eq = %.3e kg·m²  (J_m:J_L,m ≈ 1:%.0f，大惯量系统)\n\n', J_eq, J_L_m/J_m);

%--- 选型裕量验证 ---
t_r          = 0.8;
dot_omega_m  = omega_m_max / t_r;              % 要求角加速度 [rad/s²]  = 392.7
T_accel      = J_eq * dot_omega_m;             % 动态加速转矩 [N·m]  = 0.218
T_m_peak_req = T_accel + T_L_m_slope;          % 峰值转矩需求 [N·m]  = 0.440
P_m_steady   = T_L_m_slope * omega_m_max;      % 坡道稳态功率 [W]  ≈ 69.6

fprintf('【选型裕量验证】\n');
fprintf('  峰值转矩需求 %.4f N·m  vs  电机峰值 %.1f N·m → 裕量 %.2f 倍\n', ...
        T_m_peak_req, T_peak, T_peak/T_m_peak_req);
fprintf('  坡道稳态功率 %.1f W  vs  单轮上限 %d W\n\n', P_m_steady, P_wheel_max);

%% ═══════════════════════════════════════════════════════════════
%  第四部分：主电路参数（构架方案2 §4）
%% ═══════════════════════════════════════════════════════════════

f_PWM       = 20000;        % PWM 开关频率 [Hz]
T_s         = 1/f_PWM;      % 采样/PWM 周期 [s]  = 50 μs
C_bus       = 470e-6;       % 母线电容 [F]  (470 μF / 63V)
V_brk_on    = 54;           % 制动斩波开启门限 [V]
V_brk_off   = 50;           % 制动斩波关闭门限 [V]
R_brake     = 10;           % 制动电阻 [Ω]  (50W 铝壳)
I_OC        = 12;           % 过流保护门限 [A]  = I_peak
V_OV        = 58;           % 过压保护门限 [V]
V_UV        = 40;           % 欠压保护门限 [V]
omega_stall = 5;            % 堵转检测阈值 [rad/s]

fprintf('【四、主电路参数】\n');
fprintf('  f_PWM=%d Hz, T_s=%.1f μs\n', f_PWM, T_s*1e6);
fprintf('  C_bus=%d μF | V_brk: %d↔%d V | R_brake=%d Ω\n', C_bus*1e6, V_brk_off, V_brk_on, R_brake);
fprintf('  I_OC=%d A, V_OV=%d V, V_UV=%d V, omega_stall=%d rad/s\n\n', I_OC, V_OV, V_UV, omega_stall);

%% ═══════════════════════════════════════════════════════════════
%  第五部分：PI 控制器参数（构架方案2 §5.3）
%% ═══════════════════════════════════════════════════════════════
%
%  重要说明：本方案使用 BLDCSpeedControlExample 模板（Simscape BLDC 块）
%  电流环被控对象用每相等效：G_i(s) = (1/Rs) / (tau_e·s + 1)
%  因此 K_p,i = omega_bi · tau_e · Rs  （非 2Rs）

%--- 5.1 电流环 PI（零极点对消法，§5.3.1）---
%   K_p,i = omega_bi · tau_e · Rs = 6283 × 1.25e-3 × 0.6 = 4.71
%   K_i,i = K_p,i / tau_e         = 4.71 / 1.25e-3       = 3770
tau_e       = Ls / Rs;                          % 电气时间常数 [s]  = 1.25 ms
omega_bi    = 2*pi*1000;                        % 目标电流环带宽 [rad/s]  ≈ 6283
K_p_i       = omega_bi * tau_e * Rs;            % 比例增益 [V/A]  → 4.71
K_i_i       = K_p_i / tau_e;                   % 积分增益 [V/(A·s)]  → 3770
K_p_i_norm  = K_p_i / U_dc;                    % 归一化比例增益  → 0.098
K_i_i_norm  = K_i_i / U_dc;                    % 归一化积分增益  → 78.5
I_max       = I_peak;                           % 电流环限幅 [A]  = 12

%--- 5.2 速度环 PI（带宽分离法，§5.3.2）---
%   K_p,w = omega_bw · J_eq / K_t = 628 × 5.55e-4 / 0.065 = 5.36
%   tau_w = 10 / omega_bw          = 10 / 628             = 15.9 ms
%   K_i,w = K_p,w / tau_w          = 5.36 / 0.01592       = 337
omega_b_omega = omega_bi / 10;                  % 目标速度环带宽 [rad/s]  = 628
K_p_omega   = omega_b_omega * J_eq / K_t;      % 比例增益 [−]  → 5.36
tau_omega   = 10 / omega_b_omega;              % 积分时间常数 [s]  → 15.9 ms
K_i_omega   = K_p_omega / tau_omega;           % 积分增益 [−]  → 337
i_ref_max   = I_peak;                          % 速度环输出限幅 [A]  = 12

fprintf('【五、PI 控制器参数（分析初值）】\n');
fprintf('  电流环：tau_e=%.3f ms, omega_bi=%.0f rad/s\n', tau_e*1e3, omega_bi);
fprintf('    K_p,i=%.4f V/A  K_i,i=%.1f V/(A·s)\n', K_p_i, K_i_i);
fprintf('    norm: K_p,i=%.4f  K_i,i=%.2f  I_max=%d A\n\n', K_p_i_norm, K_i_i_norm, I_max);
fprintf('  速度环：omega_bw=%.0f rad/s  tau_w=%.1f ms\n', omega_b_omega, tau_omega*1e3);
fprintf('    K_p,w=%.4f  K_i,w=%.1f  i_ref_max=%d A\n\n', K_p_omega, K_i_omega, i_ref_max);
fprintf('  ⚠ 以上为分析初值，S4 按构架方案2 §5.3.3 六步整定流程微调。\n\n');

%% ═══════════════════════════════════════════════════════════════
%  第六部分：工况指令参数（供 run_case_*.m 调用）
%% ═══════════════════════════════════════════════════════════════

omega_w_low_cmd   = n_low  * pi/30;             % 低速轮侧指令 [rad/s]  = 6.283
omega_w_high_cmd  = n_high * pi/30;             % 高速轮侧指令 [rad/s]  = 25.133
omega_m_low_cmd   = omega_w_low_cmd  * i_ratio; % 电机轴低速指令 [rad/s]  = 78.54
omega_m_high_cmd  = omega_w_high_cmd * i_ratio; % 电机轴高速指令 [rad/s]  = 314.16

fprintf('【六、工况指令参数】\n');
fprintf('  轮侧：低速 %.3f rad/s  高速 %.3f rad/s\n', omega_w_low_cmd, omega_w_high_cmd);
fprintf('  电机轴：低速 %.3f rad/s  高速 %.3f rad/s\n\n', omega_m_low_cmd, omega_m_high_cmd);

%% ═══════════════════════════════════════════════════════════════
%  第七部分：参数一致性自检（与 params.md 对照）
%% ═══════════════════════════════════════════════════════════════

fprintf('【七、参数自检（与 params.md 对照）】\n');
refs = {'J_m',1.2e-5,1e-10; 'J_L_m',5.43e-4,5e-6; 'J_eq',5.55e-4,5e-6;
        'T_L_m_flat',0.0698,5e-4; 'T_L_m_slope',0.2215,5e-4;
        'T_m_peak_req',0.4395,5e-4; 'omega_m_max',314.16,0.01;
        'K_p_i',4.71,0.01; 'K_i_i',3770,5.0;
        'K_p_i_norm',0.098,5e-4; 'K_i_i_norm',78.5,0.5;
        'K_p_omega',5.36,0.02; 'K_i_omega',337,1.0};
vals = {J_m; J_L_m; J_eq; T_L_m_flat; T_L_m_slope;
        T_m_peak_req; omega_m_max;
        K_p_i; K_i_i; K_p_i_norm; K_i_i_norm; K_p_omega; K_i_omega};
pass_all = true;
for k = 1:size(refs,1)
    nm  = refs{k,1}; ref = refs{k,2}; tol = refs{k,3};
    val = vals{k};
    if abs(val-ref) <= tol
        fprintf('  [OK]   %-18s = %12.5g\n', nm, val);
    else
        fprintf('  [WARN] %-18s = %12.5g  (ref=%g, 偏差=%+.4g)\n', nm, val, ref, val-ref);
        pass_all = false;
    end
end
if pass_all
    fprintf('\n  全部参数与 params.md 一致，仿真就绪。\n');
else
    fprintf('\n  存在偏差项，请检查！\n');
end
fprintf('\n========== init_params.m 加载完成 ==========\n\n');
