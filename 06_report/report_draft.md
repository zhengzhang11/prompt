# 课程设计报告草稿

> 电气传动课程设计 · robot-servo-sim  
> 最后更新：待填

---

## 一、设计任务与给定参数

（引用 00_frozen/params.md 中的参数表）

---

## 二、顶层架构设计（S1）

### 2.1 系统总体方案

### 2.2 AI 协作过程记录
- Prompt 文件：`01_prompts/S1_arch/`
- 校验笔记：`03_checks/S1_arch/`

---

## 三、机械子系统设计（S2）

### 3.1 力学折算

### 3.2 电机选型

### 3.3 AI 协作过程记录
- Prompt 文件：`01_prompts/S2_mech/`
- 校验笔记：`03_checks/S2_mech/`

---

## 四、主电路设计（S3）

### 4.1 变流器拓扑选择

### 4.2 器件参数计算

### 4.3 AI 协作过程记录
- Prompt 文件：`01_prompts/S3_power/`
- 校验笔记：`03_checks/S3_power/`

---

## 五、控制系统设计（S4）

### 5.1 控制策略

### 5.2 PI 参数整定

### 5.3 AI 协作过程记录
- Prompt 文件：`01_prompts/S4_ctrl/`
- 校验笔记：`03_checks/S4_ctrl/`

---

## 六、Simulink 建模与仿真（S5）

### 6.1 模型结构

### 6.2 仿真工况与结果

| 工况 | 描述 | 结果目录 |
|------|------|---------|
| 工况 1 | 空载启动 | `05_results/case1_empty_start/` |
| 工况 2 | 额定负载启动 | `05_results/case2_rated_start/` |
| 工况 3 | 速度切换 | `05_results/case3_speed_switch/` |
| 工况 4 | 反转 | `05_results/case4_reverse/` |
| 工况 5 | 制动 | `05_results/case5_brake/` |
| 工况 6 | 突加扰动 | `05_results/case6_disturbance/` |

### 6.3 AI 协作过程记录
- Prompt 文件：`01_prompts/S5_integ/`
- 校验笔记：`03_checks/S5_integ/`

---

## 七、总结与反思

### 7.1 设计结论

### 7.2 AI 辅助效果评估

### 7.3 人工校验修正汇总

---

## 附录

### A. 参数汇总表

（引用 00_frozen/params.md）

### B. 主要 Prompt 摘录

### C. 仿真图
