# 一、元件清点与接口确认（Foundation Library）

## 1. DC Voltage Source（直流电源）
- 接口：
  - `+`（正极，蓝线）
  - `-`（负极，蓝线）

## 2. N-Channel MOSFET（N沟道MOS管，共6个）
- 接口：
  - `D`（漏极，蓝线）
  - `S`（源极，蓝线）
  - `G`（栅极控制口，蓝线/物理信号）

## 3. Permanent Magnet Synchronous Motor（PMSM）
- 接口：
  - `a, b, c`（三相电气接口）或 `~`（复合接口）
  - `R`（转子机械口，绿线）
  - `C`（机壳机械口，绿线）
  - `n`（中性点，悬空）

## 4. Ideal Torque Source（理想转矩源）
- 接口：
  - `S`（控制信号输入，蓝线）
  - `R`（机械输出，绿线）
  - `C`（机械参考，绿线）

## 5. 辅助元件
- Electrical Reference：1个蓝线接口  
- Mechanical Rotational Reference：1个绿线接口  
- Solver Configuration：1个蓝线接口  

## 6. 跨域转换元件
- Simulink-PS Converter：
  - 输入：`>`（黑线）
  - 输出：蓝线
- Demux：
  - 单输入 → 多输出黑线

---

# 二、三相逆变器搭建步骤

## 1. 直流侧连接
1. 放置 DC Voltage Source  
2. 上排 MOSFET 的 `D` 全部并联 → 接电源 `+`  
3. 下排 MOSFET 的 `S` 全部并联 → 接电源 `-`  
4. 电源 `-` → 接 Electrical Reference  
5. 任意电源节点 → 接 Solver Configuration  

## 2. 三相桥臂连接
- A相：
  - 上MOS `S` → 下MOS `D`
  - 中点引出 → `Phase_A`
- B相：
  - 上MOS `S` → 下MOS `D`
  - 中点引出 → `Phase_B`
- C相：
  - 上MOS `S` → 下MOS `D`
  - 中点引出 → `Phase_C`

## 3. 电机连接
- 若有 `a,b,c`：
  - Phase_A → a
  - Phase_B → b
  - Phase_C → c
- 若只有 `~`：
  - 使用 Phase Splitter 转换

---

# 三、控制与机械连接

## 1. PWM信号连接
1. Gate_Signals → Demux（6路）
2. 每一路 → Simulink-PS Converter
3. 输出 → 对应 MOSFET 的 `G`

## 2. 转矩输入
1. Inport 命名：`T_load`
2. → Simulink-PS Converter
3. → Ideal Torque Source 的 `S`
4. Torque Source `R` → Motor `R`
5. Torque Source `C` → Mechanical Reference
6. Motor `C` → Mechanical Reference

---

# 四、输出信号构建

## 1. 转速与角度
- Ideal Rotational Motion Sensor：
  - `R` → Motor `R`
  - `C` → Mechanical Reference
- 输出：
  - `W` → PS-Simulink → Outport `Omega`
  - `A` → PS-Simulink → Outport `Theta`

## 2. 相电流
- Current Sensor 串联在 A相
- `I` → PS-Simulink → Outport `I_a`

---

# 五、Solver Configuration
- 可接在电源正极或负极
- 任意电气节点均可（推荐电源端）

---

# 六、模块命名规范

## 1. 核心元件
- DC Voltage Source → `V_dc_Source_36V`
- PMSM → `Motor_42BLF02`
- Ideal Torque Source → `Load_Torque`

### MOSFET命名
- A相：
  - 上桥：`Q1_AH`
  - 下桥：`Q2_AL`
- B相：
  - 上桥：`Q3_BH`
  - 下桥：`Q4_BL`
- C相：
  - 上桥：`Q5_CH`
  - 下桥：`Q6_CL`

## 2. 传感器与配置
- Current Sensor → `Sensor_I_a`
- Rotational Sensor → `Sensor_Mech`
- Solver Configuration → `Solver_Config`

## 3. 接口命名（关键）

### 输入（Inport）
- PWM总线 → `Gate_Signals`
- 转矩输入 → `T_load`

### 输出（Outport）
- 电流 → `I_a`
- 转速 → `Omega`
- 角度 → `Theta`