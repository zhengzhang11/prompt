# controller_dual-ChatGPT 5.4-response

好的，我不会给你提供冗余内容，接下来的回答都将是你必须了解的核心信息。

先直接说结论：

这次建模里没有用 PID Controller 块，而是用 Sum + Gain + Unit Delay + Saturation 搭了一个等效的离散 PI + anti-windup。
这不是偏离要求，反而是为了满足你“优先兼容 R2023a、避免版本敏感实现”的要求。

一、人工建模指导

下面这份是你可以手工照着搭的指导。

第 0 步：先建一个空白模型

在 MATLAB 命令行输入：

```matlab
simulink
```

新建一个 Blank Model。

把模型保存为：

controller_dual.slx

第 1 步：设置求解器

打开：

Model Settings → Solver

设置为：

Type: Fixed-step

Solver: discrete (no continuous states) 或 FixedStepDiscrete

Fixed-step size: 5e-5

也就是：

Ts = 50 us

第 2 步：准备要填的最终参数

为了和A提供的参数完全一致，你填参数时就按这些值：

速度外环

K_p_omega = 1.602534588

K_i_omega = 100.6872482

Kaw_w = 0.009931744268

电流参考限幅：[-10, 10]

电流内环

K_p_i_norm = 0.19634375

K_i_i_norm = 157.075

Kaw_i = 0.006366385485

占空比限幅：[-1, 1]

离散积分

Ts = 5e-5

Unit Delay 初值：0

注意：

内环这里用的是归一化增益，不是 9.4245 和 7539.6 直接上块。
因为最后模型输出的是占空比 duty_cmd，不是电压 u。

二、人工建模：逐块搭建

下面我按“从哪个库拖什么块、改什么名、怎么连”给你。

A. 输入与输出部分

1）放 3 个输入块

从：

Simulink Library Browser → Simulink → Sources → In1

拖 3 个到模型里。

分别改名为：

omega_ref

omega_fb

i_fb

作用：

omega_ref：速度给定

omega_fb：速度反馈

i_fb：电流反馈

2）放 4 个输出块

从：

Simulink Library Browser → Simulink → Sinks → Out1

拖 4 个到模型里。

分别改名为：

duty_cmd

i_ref_dbg

e_w_dbg

e_i_dbg

作用：

duty_cmd：最终占空比输出

i_ref_dbg：速度环输出的电流参考

e_w_dbg：速度误差调试口

e_i_dbg：电流误差调试口

B. 速度外环搭建

3）放速度误差求和块

从：

Simulink → Math Operations → Sum

拖 1 个，改名：

sum_w_err

双击设置：

List of signs = '+-'

意思是：

第一个输入加

第二个输入减

连接：

omega_ref 连到 sum_w_err 第 1 输入

omega_fb 连到 sum_w_err 第 2 输入

这一步实现：

```
e_w = omega_ref - omega_fb
```

再把 sum_w_err 的输出另外分一根线到：

e_w_dbg

4）放速度比例增益

从：

Simulink → Math Operations → Gain

拖 1 个，改名：

Kp_w

参数填：

Gain = 1.602534588

连接：

sum_w_err 输出连到 Kp_w

作用：

速度误差的比例项

5）放速度积分前增益

再拖 1 个 Gain，改名：

Ki_w

参数填：

Gain = 100.6872482

连接：

sum_w_err 输出再分一根线到 Ki_w

作用：

速度误差先乘积分增益

6）放 anti-windup 误差求和块

再拖 1 个 Sum，改名：

sum_w_awerr

参数：

List of signs = '+-'

它的输入应该是：

第 1 输入：sat_i_ref

第 2 输入：sum_w_u

也就是：

```
aw_err_w = sat_i_ref - sum_w_u
```

7）放速度回算增益

拖 1 个 Gain，改名：

Kaw_w

参数填：

Gain = 0.009931744268

连接：

sum_w_awerr 输出连到 Kaw_w

8）放速度积分输入求和块

拖 1 个 Sum，改名：

sum_w_intin

参数：

List of signs = '++'

连接：

Ki_w 输出连到 sum_w_intin 第 1 输入

Kaw_w 输出连到 sum_w_intin 第 2 输入

作用：

把积分主输入和 anti-windup 回算量相加

9）放采样周期增益

拖 1 个 Gain，改名：

Ts_w

参数填：

Gain = 5e-5

连接：

sum_w_intin 输出连到 Ts_w

作用：

实现离散积分里的 Ts

10）放积分状态求和块

拖 1 个 Sum，改名：

sum_w_state

参数：

List of signs = '++'

连接：

z_w 输出连到 sum_w_state 第 1 输入

Ts_w 输出连到 sum_w_state 第 2 输入

作用：

计算新的积分状态

11）放速度环状态存储块

从：

Simulink → Discrete → Unit Delay

拖 1 个，改名：

z_w

参数填：

Sample time = 5e-5

Initial condition = 0

连接：

sum_w_state 输出连到 z_w

z_w 输出一方面回到 sum_w_state

另一方面送到 sum_w_u

这就是离散积分器的状态记忆。

12）放速度 PI 输出求和块

拖 1 个 Sum，改名：

sum_w_u

参数：

List of signs = '++'

连接：

Kp_w 输出连到 sum_w_u 第 1 输入

z_w 输出连到 sum_w_u 第 2 输入

作用：

比例项 + 积分项

13）放速度环输出限幅

从：

Simulink → Discontinuities → Saturation

拖 1 个，改名：

sat_i_ref

参数填：

Upper limit = 10

Lower limit = -10

连接：

sum_w_u 输出连到 sat_i_ref

再从 sat_i_ref 输出分两根线：

一根连到 i_ref_dbg

一根连到 sum_i_err 第 1 输入

同时再分一根到：

sum_w_awerr 第 1 输入

另外：

sum_w_u 输出还要分一根到 sum_w_awerr 第 2 输入

这样速度外环就闭合了。

C. 电流内环搭建

14）放电流误差求和块

拖 1 个 Sum，改名：

sum_i_err

参数：

List of signs = '+-'

连接：

sat_i_ref 输出连到 sum_i_err 第 1 输入

i_fb 连到 sum_i_err 第 2 输入

实现：

```
e_i = i_ref - i_fb
```

再把 sum_i_err 输出分一根线到：

e_i_dbg

15）放电流比例增益

拖 1 个 Gain，改名：

Kp_i

参数填：

Gain = 0.19634375

连接：

sum_i_err 输出连到 Kp_i

16）放电流积分前增益

拖 1 个 Gain，改名：

Ki_i

参数填：

Gain = 157.075

连接：

sum_i_err 输出再分一根线到 Ki_i

17）放 anti-windup 误差求和块

拖 1 个 Sum，改名：

sum_i_awerr

参数：

List of signs = '+-'

连接关系：

第 1 输入接 sat_duty

第 2 输入接 sum_i_u

作用：

```
aw_err_i = sat_duty - sum_i_u
```

18）放电流回算增益

拖 1 个 Gain，改名：

Kaw_i

参数填：

Gain = 0.006366385485

连接：

sum_i_awerr 输出连到 Kaw_i

19）放电流积分输入求和块

拖 1 个 Sum，改名：

sum_i_intin

参数：

List of signs = '++'

连接：

Ki_i 输出连到第 1 输入

Kaw_i 输出连到第 2 输入

20）放采样周期增益

拖 1 个 Gain，改名：

Ts_i

参数填：

Gain = 5e-5

连接：

sum_i_intin 输出连到 Ts_i

21）放电流积分状态求和块

拖 1 个 Sum，改名：

sum_i_state

参数：

List of signs = '++'

连接：

z_i 输出连到第 1 输入

Ts_i 输出连到第 2 输入

22）放电流环状态存储块

从：

Simulink → Discrete → Unit Delay

拖 1 个，改名：

z_i

参数填：

Sample time = 5e-5

Initial condition = 0

连接：

sum_i_state 输出连到 z_i

z_i 输出一根回到 sum_i_state

一根去 sum_i_u

23）放电流 PI 输出求和块

拖 1 个 Sum，改名：

sum_i_u

参数：

List of signs = '++'

连接：

Kp_i 输出连到第 1 输入

z_i 输出连到第 2 输入

作用：

电流比例项 + 电流积分项

24）放占空比限幅

从：

Simulink → Discontinuities → Saturation

拖 1 个，改名：

sat_duty

参数填：

Upper limit = 1

Lower limit = -1

连接：

sum_i_u 输出连到 sat_duty

然后：

sat_duty 输出连到 duty_cmd

sat_duty 输出再分一根线到 sum_i_awerr 第 1 输入

sum_i_u 输出再分一根线到 sum_i_awerr 第 2 输入

至此电流内环完成。

三、逐元件说明

下面我把每个元件的“名称—来源—参数—作用”再压缩整理一遍。

输入输出块

omega_ref / omega_fb / i_fb

来源：Simulink > Sources > In1

作用：控制器输入端口

duty_cmd / i_ref_dbg / e_w_dbg / e_i_dbg

来源：Simulink > Sinks > Out1

作用：控制器输出和调试输出

速度环元件

sum_w_err

来源：Math Operations > Sum

参数：+-

作用：计算速度误差

Kp_w

来源：Math Operations > Gain

参数：1.602534588

作用：速度比例项

Ki_w

来源：Math Operations > Gain

参数：100.6872482

作用：速度积分增益

sum_w_awerr

来源：Math Operations > Sum

参数：+-

作用：计算速度环 anti-windup 误差

Kaw_w

来源：Math Operations > Gain

参数：0.009931744268

作用：速度环回算增益

sum_w_intin

来源：Math Operations > Sum

参数：++

作用：合成速度积分输入

Ts_w

来源：Math Operations > Gain

参数：5e-5

作用：乘采样周期

sum_w_state

来源：Math Operations > Sum

参数：++

作用：计算下一拍积分状态

z_w

来源：Discrete > Unit Delay

参数：Ts=5e-5, X0=0

作用：保存速度积分状态

sum_w_u

来源：Math Operations > Sum

参数：++

作用：比例项 + 积分项

sat_i_ref

来源：Discontinuities > Saturation

参数：[-10, 10]

作用：把速度环输出限制成电流参考

电流环元件

sum_i_err

来源：Math Operations > Sum

参数：+-

作用：计算电流误差

Kp_i

来源：Math Operations > Gain

参数：0.19634375

作用：电流比例项，已归一化

Ki_i

来源：Math Operations > Gain

参数：157.075

作用：电流积分增益，已归一化

sum_i_awerr

来源：Math Operations > Sum

参数：+-

作用：计算电流环 anti-windup 误差

Kaw_i

来源：Math Operations > Gain

参数：0.006366385485

作用：电流环回算增益

sum_i_intin

来源：Math Operations > Sum

参数：++

作用：合成电流积分输入

Ts_i

来源：Math Operations > Gain

参数：5e-5

作用：乘采样周期

sum_i_state

来源：Math Operations > Sum

参数：++

作用：计算下一拍积分状态

z_i

来源：Discrete > Unit Delay

参数：Ts=5e-5, X0=0

作用：保存电流积分状态

sum_i_u

来源：Math Operations > Sum

参数：++

作用：电流 PI 未限幅输出

sat_duty

来源：Discontinuities > Saturation

参数：[-1, 1]

作用：输出最终占空比命令

四、你连线时最容易错的地方

这里我直接提醒几个最容易出错的点。

1）sum_w_awerr 和 sum_i_awerr 的正负号不要接反

都必须是：

第 1 输入接“饱和后”

第 2 输入接“饱和前”

也就是：

```
aw_err = sat_output - unsat_output
```

不是反过来。

2）Unit Delay 一定要闭合成状态回路

z_w 和 z_i 都不是普通延时块摆着好看的。
它们要形成：

```
sum_state -> Unit Delay -> 回到 sum_state
```

否则积分器根本没建起来。

3）电流环增益用的是归一化值

这里最容易错。

你最后这版模型输出的是：

duty_cmd

所以内环要填的是：

Kp_i = 0.19634375

Ki_i = 157.075

不是：

9.4245

7539.6

后两个是未归一化电压型 PI的增益。

4）两个 Saturation 的限幅不一样

不要填混：

sat_i_ref：[-10, 10]

sat_duty：[-1, 1]

5）sum_w_err、sum_i_err 都是 +-

不是 ++

因为它们都在做：

参考值 - 反馈值

如果你愿意，我下一条可以继续给你一份“按从左到右布局的摆放坐标式人工搭建顺序”，就是更像“先放哪个，再放哪个，屏幕上摆在哪一列”那种。
