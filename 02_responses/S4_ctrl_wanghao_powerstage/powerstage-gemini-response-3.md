太好了，连线全部打通是底层物理建模最难的一步。为了让你交接给 A 同学时界面清晰、接口一目了然，请单击每个模块下方默认的英文名字，直接修改为以下规范名称：

---

# 一、核心物理元件改名

- **DC Voltage Source（直流电源）**  
  → `V_dc_Source_36V`

- **Permanent Magnet Synchronous Motor（电机）**  
  → `Motor_42BLF02`（架构方案中指定型号）

- **Ideal Torque Source（理想转矩源）**  
  → `Load_Torque`

- **6 个 N-Channel MOSFET（逆变器开关）**  
  按桥臂位置命名为：

  - A 相上下桥：  
    - `Q1_AH`（上桥）  
    - `Q2_AL`（下桥）

  - B 相上下桥：  
    - `Q3_BH`（上桥）  
    - `Q4_BL`（下桥）

  - C 相上下桥：  
    - `Q5_CH`（上桥）  
    - `Q6_CL`（下桥）

  > 注：H = 高边（High），L = 低边（Low），便于快速识别 PWM 对应关系

---

# 二、传感器与配置模块改名

- **Current Sensor（电流传感器）**  
  → `Sensor_I_a`

- **Ideal Rotational Motion Sensor（旋转传感器）**  
  → `Sensor_Mech`

- **Solver Configuration（求解器）**  
  → `Solver_Config`

- **Reference 类模块（接地等）**  
  → 保持默认名称（无需修改）

---

# 三、对外接口改名（极其重要）

你需要选中最外围的输入/输出端子（Inport / Outport）进行命名：

---

## 【输入端子 Inports】

- 转矩输入端（接转矩源 Converter）  
  → `T_load`

- PWM 信号输入端（接 Demux 总线）  
  → `Gate_Signals`

---

## 【输出端子 Outports】

- 电流输出（来自电流传感器）  
  → `I_a`

- 角速度输出（来自旋转传感器 W 口）  
  → `Omega`

- 角位置输出（来自旋转传感器 A 口）  
  → `Theta`

---

完成以上命名后：

- 整个 `power_stage` 子系统结构将 **清晰、规范、可读性极强**
- A 同学可以 **无需解释直接接入控制系统**
- 你可以直接打包并交付使用 🚀