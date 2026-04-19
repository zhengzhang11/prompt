%% init_params.m — 全局参数初始化脚本
% 差速驱动轮电机伺服控制系统 · 仿真参数初始化
%
% 所有 Simulink 模型在运行前必须先执行此脚本
% 参数值与修改请对照 00_frozen/params.md（S1 冻结参数唯一真相源）
%
% 电机型号：57BLF02（24V/125W/3000rpm），配 48V 母线 + PWM 降压，减速比 12.5:1
% 参考模板：MathWorks Simscape Electrical 官方示例 "BLDC Speed Control"
%           openExample('simscapeelectrical/BLDCSpeedControlExample')
%
% 最后更新：2026-04-18  v1.5 电机升级57BLF02 + MO+SO PI整定，补全单闭环参数

clear; clc;
fprintf('\n========== 电气传动仿真 · 初始化全局参数（方案 3：57BLF02 + MO/SO）==========\n\n');

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
% 57BLF02 额定转速 3000 rpm → i = 3000/240 = 12.5
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
%  第三部分：电机铭牌参数（57BLF02，构架方案2 §3.2.1）
%% ═══════════════════════════════════════════════════════════════

U_N         = 24;           % 额定电压 [V]（24V型，配48V母线PWM降压，巡航占空比约40%）
P_N         = 125;          % 额定功率 [W]  坡道稳态69.6W仅占55.6%，裕量充足
n_N         = 3000;         % 额定转速 [rpm]
I_N         = 7.8;          % 额定电流 [A]
I_peak      = 23.5;         % 峰值/堵转电流（电机） [A]  控制器限幅仍用12A
T_N         = 0.4;          % 额定转矩 [N·m]  坡道稳态0.2215 N·m仅占55.4%
T_peak      = 1.2;          % 峰值转矩 [N·m]  裕量2.72×
K_t         = 0.066;        % 力矩常数 [N·m/A]
K_e         = 6.3;          % 反电势常数（线-线）[V/krpm]
K_e_krpm    = K_e;          % 保留 V/krpm 值用于显示
K_e         = K_e_krpm / 1000 * 60 / (2*pi); % 转换为 V·s/rad ≈ 0.06016
Rs          = 0.30;         % 相电阻（线-线）[Ω]  工程估算，S2须实测校准
Ls          = 0.75e-3;      % 相电感（线-线）[H]  (0.75 mH)  与BLF01相同，Ke近似不变
p_poles     = 4;            % 极对数（8极）
J_m         = 1.7e-5;       % 转子惯量 [kg·m²]  (170 g·cm²，ACT Motor datasheet)

J_eq        = J_m + J_L_m;  % 系统总折算惯量 [kg·m²]  ≈ 5.60e-4

fprintf('【三、57BLF02 电机铭牌参数（ACT Motor/Longs Motor datasheet）】\n');
fprintf('  U_N=%d V (24V/48V母线PWM), P_N=%d W, n_N=%d rpm\n', U_N, P_N, n_N);
fprintf('  I_N=%.1f A, I_peak=%.0f A, T_N=%.1f N·m, T_peak=%.1f N·m\n', I_N, I_peak, T_N, T_peak);
fprintf('  K_t=%.3f N·m/A, K_e=%.4f V·s/rad (= %.2f V/krpm)\n', K_t, K_e, K_e_krpm);
fprintf('  Rs=%.1f Ω, Ls=%.3f mH, p=%d, J_m=%.2e kg·m²\n', Rs, Ls*1e3, p_poles, J_m);
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
%  第五部分：PI 控制器参数（构架方案3 §5.3 · 工业MO+SO法）
%% ═══════════════════════════════════════════════════════════════
%
%  设计方法：工业标准"模最优法（MO）+ 对称最优法（SO）"
%  被控对象完整串联：G_PWM(s) × G_RL(s) × G_mech(s)
%  参考：构架方案3（被控对象修正）.md §5.2~5.4

%--- 5.1 被控对象参数 ---
tau_e       = Ls / Rs;                          % 电气时间常数 [s]  = 2.50 ms
T_PWM_eq    = 1.5 / f_PWM;                     % PWM等效延时 [s]  = 75 μs
K_PWM       = U_dc;                             % PWM稳态增益 [V]  = 48
% G_i(s) = K_PWM/Rs / [(tau_e·s+1)(T_PWM_eq·s+1)] = 160/[(2.50ms·s+1)(75μs·s+1)]

%--- 5.2 双闭环：内电流环 PI（模最优法 MO, §5.3.1）---
%   零极点对消：tau_i = tau_e = 2.50 ms
%   MO条件：Kp_i·U_dc/(Rs·tau_i) = 1/(2·T_PWM_eq)
%   => Kp_i = Rs·tau_e / (2·U_dc·T_PWM_eq) = 0.30×2.50e-3/(2×48×75e-6) = 0.1042
tau_i       = tau_e;                            % PI积分时间 = tau_e（零极点对消）
K_p_i       = (Rs * tau_e) / (2 * U_dc * T_PWM_eq); % 比例增益 [D*/A]  → 0.1042
K_i_i       = K_p_i / tau_i;                   % 积分增益 [D*/(A·s)] → 41.67
I_max       = 12;                               % 电流限幅 [A]（= I_peak）
T_i_cl      = 2 * T_PWM_eq;                    % 电流环闭环等效时间常数 [s] = 150 μs

%--- 5.3 双闭环：外速度环 PI（对称最优法 SO, a=4, §5.3.2）---
%   tau_w = a^2·T_i_cl = 16×150μs = 2.40 ms
%   Kp_w  = J_eq / (Kt·a·T_i_cl) = 5.60e-4/(0.066×4×150e-6) = 14.14
%   Ki_w  = Kp_w / tau_w = 5892
a_SO        = 4;                                % 对称度参数（a=4: PM≈53°，超调~8%+滤波）
tau_omega   = a_SO^2 * T_i_cl;                 % PI积分时间 [s]  = 2.40 ms
K_p_omega   = J_eq / (K_t * a_SO * T_i_cl);   % 比例增益 [A·s/rad]  → 14.14
K_i_omega   = K_p_omega / tau_omega;           % 积分增益 [A/rad]    → 5892
i_ref_max   = I_max;                           % 速度环输出限幅 [A]
tau_F       = tau_omega;                        % 前置滤波器时间常数 [s]=2.40ms（必须！降超调至~8%）

%--- 5.4 单闭环：速度 PI（MO法 + 极点对消, §5.4.3）---
%   被控对象：G_total = 798.0/[(42.3ms·s+1)(2.50ms·s+1)(75μs·s+1)]
%   PI零点对消机械极点 T_m，MO法整定Kp
%   Kp_w_s = T_m/(2·T_small·K0) = 0.0423/(2×2.575e-3×798.0) = 0.01030
T_m_mech    = Rs * J_eq / (K_t * K_e);         % 机械时间常数 [s]  = 42.3 ms
K_0         = U_dc / K_e;                       % 空载最大角速度 [rad/s]  = 798.0
T_small_s   = tau_e + T_PWM_eq;                % 剩余小惯性之和 [s]  = 2.575 ms
tau_PI_s    = T_m_mech;                         % 单闭环PI积分时间（对消T_m）
K_p_omega_s = tau_PI_s / (2 * T_small_s * K_0);% 比例增益 [D*/(rad/s)]  → 0.01030
K_i_omega_s = K_p_omega_s / tau_PI_s;          % 积分增益 [D*/rad]      → 0.2436
I_cutoff    = I_max;                            % 单闭环电流截止 [A]（必须！）

fprintf('【五、PI 控制器参数（MO+SO严谨推导初值）】\n');
fprintf('  tau_e=%.3f ms, T_PWM_eq=%.1f μs\n', tau_e*1e3, T_PWM_eq*1e6);
fprintf('  [双闭环-电流环 MO] K_p_i=%.4f D*/A  K_i_i=%.2f D*/(A·s)  T_i_cl=%.0f μs\n', K_p_i, K_i_i, T_i_cl*1e6);
fprintf('  [双闭环-速度环 SO, a=%d] K_p_w=%.4f A·s/rad  K_i_w=%.1f A/rad  tau_F=%.2f ms\n', a_SO, K_p_omega, K_i_omega, tau_F*1e3);
fprintf('  [单闭环 MO] T_m=%.1f ms  K0=%.1f rad/s  K_p_w_s=%.5f  K_i_w_s=%.4f\n', T_m_mech*1e3, K_0, K_p_omega_s, K_i_omega_s);
fprintf('  ⚠ 以上为分析初值，S4 按构架方案3 §5.3.4 六步整定流程微调。\n\n');

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
refs = {'J_m',1.7e-5,1e-10; 'J_L_m',5.43e-4,5e-6; 'J_eq',5.60e-4,5e-6;
        'T_L_m_flat',0.0698,5e-4; 'T_L_m_slope',0.2215,5e-4;
        'T_m_peak_req',0.4414,5e-4; 'omega_m_max',314.16,0.01;
        'K_p_i',0.1042,1e-4; 'K_i_i',41.67,0.1;
        'K_p_omega',14.14,0.05; 'K_i_omega',5892,10.0;
        'K_p_omega_s',0.01030,1e-4; 'K_i_omega_s',0.2436,1e-3;
        'T_m_mech',0.0423,5e-4};
vals = {J_m; J_L_m; J_eq; T_L_m_flat; T_L_m_slope;
        T_m_peak_req; omega_m_max;
        K_p_i; K_i_i; K_p_omega; K_i_omega;
        K_p_omega_s; K_i_omega_s; T_m_mech};
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

%% ═══════════════════════════════════════════════════════════════
%  第八部分：求解器刚性修复参数（供 set_param 调用）
%  问题背景：PWM 20kHz 开关 + Simscape BLDC DAE → 步长压至机器精度
%  根本修复：Simscape 局部求解器 + 主求解器换刚性 ode23t
%% ═══════════════════════════════════════════════════════════════
%
%  === GUI 操作路径（每次建新模型后执行一次）===
%
%  [1] Simscape 局部求解器（最关键）
%      双击 "电机模型" 子系统 → 双击 Solver Configuration 块
%      ✓ Use local solver: 勾选
%        Solver:      后向欧拉 (Backward Euler)
%        Sample time: 5e-6   (5 μs = T_s/10，速度精度折中)
%
%  [2] 主 Simulink 求解器
%      Simulation → Model Configuration Parameters → Solver 标签
%        Type:        Variable-step
%        Solver:      ode23t   （刚性首选；更高刚性用 ode15s）
%        Max step:    2.5e-5   (= T_s/2 = 25 μs，速度优先)
%        Rel tol:     1e-3
%        Abs tol:     1e-5
%        Min step:    auto     （不填）
%
%  [3] 开关缓冲器（消除理想跳变奇点）
%      IGBT/MOSFET 参数对话框 → Snubber
%        Rs_snubber:  1e4   Ω
%        Cs_snubber:  1e-9  F
%
%  === 脚本方式（自动配置，需先用 open_system 打开模型）===
%  mdl = 'powerstage';  % ← 改成实际模型名（不含 .slx）
%  set_param(mdl, 'SolverType',         'Variable-step');
%  set_param(mdl, 'Solver',             'ode23t');
%  set_param(mdl, 'MaxStep',            num2str(T_s/2));   % 2.5e-5
%  set_param(mdl, 'RelTol',             '1e-3');
%  set_param(mdl, 'AbsTol',             '1e-5');
%  set_param(mdl, 'MinStep',            'auto');
%  save_system(mdl);
%  fprintf('求解器配置已写入 %s.slx\n', mdl);

% 供脚本引用的求解器关键参数
solver_MaxStep      = T_s / 2;      % 主求解器最大步长 [s]  = 2.5e-5 (T_s/2，速度优先)
solver_AbsTol       = 1e-5;         % 绝对误差容限
solver_RelTol       = 1e-3;         % 相对误差容限
simscape_Ts_local   = 5e-6;         % Simscape 局部求解器采样步长 [s]  = 5 μs (T_s/10)

fprintf('【八、求解器刚性修复参数（已导出至工作空间）】\n');
fprintf('  主求解器：ode23t，MaxStep=%.2e s (T_s/2)，AbsTol=%.0e，RelTol=%.0e\n', ...
        solver_MaxStep, solver_AbsTol, solver_RelTol);
fprintf('  Simscape 局部步长：%.0e s (5 μs = T_s/10，速度精度折中)\n', simscape_Ts_local);
fprintf('  ⚠ GUI 操作：见本文件第八部分注释\n\n');
