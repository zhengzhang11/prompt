遇到因为缺少高级工具箱而“元件连不上”的问题确实很让人抓狂，但这在团队协作中很常见。既然我们要用 Simscape / Foundation Library（基础物理库）“纯手工”捏一个功率层出来，精准识别每一个接口就是成功的关键。  

为了确保你这次能一次性连通，请对照以下清单严格清点元件，并按照步骤搭建逆变器。  

---

# 一、元件清点与接口确认（全部来自 Foundation Library）

请在库浏览器中搜索以下全名，确认你拖出来的模块具有以下特定字母/符号的接口：

## 1. DC Voltage Source（直流电源）
- 接口：  
  - `+`（正极，蓝线）  
  - `-`（负极，蓝线）

---

## 2. N-Channel MOSFET（N沟道MOS管 - 用作逆变器开关）
- 注：你需要拖出 **6 个此模块**
- 接口：  
  - `D`（漏极，蓝线）  
  - `S`（源极，蓝线）  
  - `G`（栅极控制口，蓝线 / 物理信号）

---

## 3. Permanent Magnet Synchronous Motor（PMSM / 永磁同步电机）
- 接口：  
  - `~`（三相复合电气口，蓝线）或 `a, b, c`（独立三相口）  
  - `R`（Rotor，转子机械口，绿线）  
  - `C`（Casing，机壳机械口，绿线）

---

## 4. Ideal Torque Source（理想转矩源）
- 接口：  
  - `S`（控制信号输入，蓝线）  
  - `R`（机械输出，绿线）  
  - `C`（机械参考，绿线）

---

## 5. 辅助必带元件（没有会报错）
- Electrical Reference（电学接地）：  
  - 只有 1 个蓝线接口  
- Mechanical Rotational Reference（机械接地）：  
  - 只有 1 个绿线接口  
- Solver Configuration（求解器配置）：  
  - 只有 1 个蓝线接口  

---

## 6. 跨界转换元件（突破黑蓝屏障的钥匙）
- Simulink-PS Converter：  
  - 输入端 `>`（接黑线）  
  - 输出端（无字，接蓝线）  
  - 需要 **7 个（6 个给 PWM，1 个给转矩）**

- Demux（信号分离器）：  
  - 属于基础 Simulink 库  
  - 一端单线，另一端可展开为多线  

---

# 二、三相逆变器“手工搭建”指南

这部分你需要用 **6 个 N-Channel MOSFET** 搭建一个三相桥。  
请在画板上将它们排列成上下两排，每排 3 个。

---

## 第一步：布置主供电网络（直流侧）

1. 将 DC Voltage Source 放好。  

2. 将 **上排 3 个 MOSFET 的 D 接口全部连在一起**，然后连到电源的 `+`。  

3. 将 **下排 3 个 MOSFET 的 S 接口全部连在一起**，然后连到电源的 `-`。  

4. 在电源的 `-` 处，接一个 **Electrical Reference**。  

5. 在任意一条电源线上，接出 **Solver Configuration 模块**。  

---

## 第二步：引出三相输出网络（交流侧）

1. **A 相桥臂**  
   - 上排第 1 个的 `S` → 下排第 1 个的 `D`  
   - 从该连接点引出：`Phase_A`

2. **B 相桥臂**  
   - 上排第 2 个的 `S` → 下排第 2 个的 `D`  
   - 引出：`Phase_B`

3. **C 相桥臂**  
   - 上排第 3 个的 `S` → 下排第 3 个的 `D`  
   - 引出：`Phase_C`

---

## 第三步：连接到电机

- 如果电机有 `a, b, c` 接口：  
  - 直接连接 `Phase_A / B / C`

- 如果电机只有 `~` 接口：  
  - 使用 **Phase Splitter（相分离器）**  
    - 左侧：`a, b, c` → 接逆变器输出  
    - 右侧：`~` → 接电机  

---

# 三、控制与机械接口连线（黑蓝打通）

## 1. PWM 控制信号连接

A 同学提供：一根包含 **6 路信号的黑线向量（Gate_Signals）**

步骤：

1. 接一个 **Demux 模块**  
   - 设置 `Number of outputs = 6`  
   - 输入黑线 → 输出 6 根独立黑线  

2. 将 6 根黑线分别接入 **6 个 Simulink-PS Converter**  

3. 将转换后的蓝线输出：  
   - 分别接到 **6 个 MOSFET 的 G（栅极）接口**  
   - 顺序建议：A上、A下、B上、B下、C上、C下  

---

## 2. 负载转矩连接

S2 小组提供：转矩信号（黑线）

步骤：

1. 黑线 → **Simulink-PS Converter**  

2. 输出 → **Ideal Torque Source 的 S 接口**  

3. Ideal Torque Source 连接：  
   - `R` → 电机 `R`  
   - `C` → Mechanical Rotational Reference  

4. 电机接口：  
   - `C` → Mechanical Rotational Reference（外壳接地）  

---

严格按照这个接口和连线逻辑，基础库也能完美搭建出符合架构方案要求的 `power_stage`。  

跑通后，你可以自豪地告诉 A 同学：  
**你是用纯底层逻辑把这块系统硬啃下来的。**