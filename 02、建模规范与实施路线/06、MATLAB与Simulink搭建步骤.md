# MATLAB 与 Simulink 搭建步骤

## 1. 搭建目标

先做一个完全独立的涡环测试台，不接六自由度模型。等静态曲线和动态响应都正确，再把同一个 `VRS_Inflow` 子系统复制或引用到已有基础模型中。

最终建议的实现目录为：

```text
03、涡环模型实现/
  vrs_params.m
  vrs_normal_baseline.m
  vrs_johnson_qs.m
  vrs_inflow_rhs.m
  test_vrs_static.m
  plot_vrs_results.m
  vrs_inflow_testbench.slx
```

第一版不使用 S-Function。普通 MATLAB 函数、`MATLAB Function` 块和 `Integrator` 块更容易理解和排错。

## 2. 第一步：确认 MATLAB 环境

1. 打开 MATLAB。
2. 把“直升机涡环状态建模仿真”设为当前文件夹。
3. 确认已安装 Simulink。
4. 在命令行运行：

```matlab
ver
which simulink
```

5. 新建实现文件夹 `03、涡环模型实现`，再进入该文件夹工作。

## 3. 第二步：建立参数文件

新建 `vrs_params.m`，只负责返回参数结构体 `P_vrs`。推荐字段为：

```matlab
P_vrs.rho
P_vrs.R
P_vrs.Omega
P_vrs.kappa
P_vrs.f_vrs
P_vrs.tau_rev
P_vrs.boundary.VzD
P_vrs.boundary.VzN
P_vrs.boundary.QN
P_vrs.boundary.VzX
P_vrs.boundary.QX
P_vrs.boundary.VzE
P_vrs.boundary.VxM
P_vrs.numeric.T_min
P_vrs.numeric.tol
```

参数要求：

- `rho`、`R` 和 `Omega` 使用国际单位制。
- `Omega` 必须为 $mathrm{rad/s}$。
- D、N、X、E、M 参数存无量纲值。
- 每个经验参数旁边写文献来源和表号。
- 目标机参数没有确定时使用 `NaN` 并主动报错，不随便填一个看起来能运行的数。

转速换算为：

$$
\Omega=\frac{2\pi n}{60},
$$

其中 $n$ 的单位为 $\mathrm{r/min}$。

## 4. 第三步：先写 MATLAB 算法函数

写函数前先记住：$v_{\mathrm{base}}$ 和 $v_{i,\mathrm{QS}}$ 都是当前输入对应的瞬时计算结果，只有 $v_i$ 是需要通过积分得到的动态状态。实现链路为：

```text
v_base + Δv_VRS
  -> v_i_QS
  -> 计算 v_i_dot
  -> Integrator
  -> v_i
```

不要把 $v_{\mathrm{base}}$ 接到 `Integrator`，也不要把 $v_{i,\mathrm{QS}}$ 直接当成过渡过程中的实际诱导速度。

搭每一个模块前，先回答它对应的物理问题：

| 模块 | 它在回答什么物理问题 |
|---|---|
| `Normal_Baseline` | 如果尾流正常离开桨盘，没有回卷，诱导速度本来应该是多少？ |
| `Johnson_VRS_QS` | 当前下降率和水平速度会不会让尾流卷回桨盘？如果会，目标诱导速度要改变多少？ |
| `Inflow_Dynamics` | 目标已经变化了，但真实空气需要多长时间才能跟上？ |
| `Integrator` | 根据诱导速度变化率，当前实际诱导速度已经变化到哪里？ |
| `VRS_Diagnostics` | 当前是在正常区、进入区、核心区还是退出区？ |

后面的程序和方块只是把这五个物理问题写成可计算形式。

### 4.1 基线诱导速度函数

新建：

```matlab
function out = vrs_normal_baseline(V_H, V_d, T, P_vrs)
```

建议输出结构体字段：

```matlab
out.v_h
out.mu
out.nu
out.v_base
out.input_valid
```

函数内部按以下顺序：

1. 检查输入是否有限。
2. 检查 $T>0$、$R>0$、$\rho>0$。
3. 计算 $A=\pi R^2$。
4. 计算 $v_h$。
5. 换算 $V_z=-V_d$。
6. 计算 $\mu$ 和 $\nu$。
7. 求正常动量理论或 Johnson 基线对应的基线诱导速度 $v_{\mathrm{base}}$。

### 4.2 Johnson 准定常函数

新建：

```matlab
function out = vrs_johnson_qs(V_H, V_d, T, P_vrs)
```

建议输出：

```matlab
out.v_i_qs
out.v_base
out.dv_vrs
out.vrs_strength
out.vrs_flag
out.v_h
out.mu
out.nu
```

函数内部顺序：

1. 调用 `vrs_normal_baseline`。
2. 根据 $\mu$ 移动 N、X 边界点。
3. 判断当前 $\nu$ 位于 D-N、N-X、X-E 哪一段。
4. 用 Hermite 型三次多项式求 $\Delta v_{\mathrm{VRS}}$。
5. 计算水平速度门控后的 $f_{\mathrm{eff}}$。
6. 计算 $v_{i,\mathrm{QS}}$。
7. 输出状态和全部诊断量。

不要一开始把三段多项式系数手工展开成一长串常数。应使用“端点值 + 端点斜率”的三次 Hermite 形式，方便自动检查连续性。

### 4.3 动态右端项函数

新建：

```matlab
function v_i_dot = vrs_inflow_rhs(v_i, v_i_qs, P_vrs)
```

内部只计算：

$$
\tau=\tau_{\mathrm{rev}}\frac{2\pi}{\Omega},
$$

$$
\dot v_i=\frac{v_{i,\mathrm{QS}}-v_i}{\tau}.
$$

这个函数保持简单，便于将来替换动态入流模型。

当 $v_{i,\mathrm{QS}}$ 在一个仿真步内已知时，`vrs_inflow_rhs` 输出的是变化率 $\dot v_i$，不是新的 $v_i$。新的 $v_i$ 必须由 Simulink 的 `Integrator` 根据初值和 $\dot v_i$ 计算。

## 5. 第四步：先跑 MATLAB 静态测试

新建 `test_vrs_static.m`，不要马上打开 Simulink。

### 5.1 垂直下降扫掠

固定：

$$
V_H=0.
$$

让无量纲轴向速度覆盖正常区、VRS 区和风车制动区，例如扫掠：

$$
-3\le\frac{V_z}{v_h}\le1.
$$

每个点调用 `vrs_johnson_qs`，画出：

$$
\frac{v_{i,\mathrm{QS}}}{v_h}
\quad\text{和}\quad
\frac{V_z+v_{i,\mathrm{QS}}}{v_h}.
$$

### 5.2 自动检查连接点

分别在 D、N、X、E 左右取很小的扰动 $\varepsilon$，检查函数值差：

$$
\left|f(x_0-\varepsilon)-f(x_0+\varepsilon)\right|<\epsilon_f.
$$

再用中心差分检查需要连续的一阶导数：

$$
f'(x_0)\approx
\frac{f(x_0+\varepsilon)-f(x_0-\varepsilon)}{2\varepsilon}.
$$

### 5.3 开关测试

- 令 $f=0$，确认 VRS 增量关闭。
- 令 $f=1$，确认恢复 Johnson 标称曲线。
- 增大 $V_H/v_h$，确认 VRS 区域收缩。
- 令 $V_H/v_h\ge0.95$，确认标称 VRS 增量关闭。

只有这些测试通过后，才进入 Simulink。

## 6. 第五步：新建 Simulink 独立测试台

新建模型 `vrs_inflow_testbench.slx`。

顶层建议只放五组模块：

```text
Test_Inputs
  -> VRS_Inflow
  -> Scope
  -> To_Workspace
  -> Assertions
```

### 6.1 `Test_Inputs`

第一版可用 `Constant`、`Step`、`Ramp` 或 `Signal Editor` 产生：

- `V_H_mps`
- `V_d_mps`
- `T_N`

建议先用三个 `Constant` 跑悬停，再逐个换成 `Step` 或 `Ramp`。

### 6.2 `VRS_Inflow` 子系统端口

输入端口严格按下列顺序：

1. `V_H_mps`
2. `V_d_mps`
3. `T_N`

输出端口建议为：

1. `v_i_mps`
2. `v_i_QS_mps`
3. `vrs_flag`
4. `diag_bus`

端口名中写单位，能明显减少接错线。

## 7. 第六步：搭 `VRS_Inflow` 内部

### 7.1 放置 `MATLAB Function` 块

放一个名为 `Johnson_VRS_QS` 的 `MATLAB Function` 块，用于调用或实现 `vrs_johnson_qs` 的准定常部分。

输入：

```text
V_H_mps
V_d_mps
T_N
```

输出：

```text
v_i_QS_mps
v_h_mps
mu
nu
v_base_mps
dv_vrs_mps
vrs_strength
vrs_flag
input_valid
```

参数 `P_vrs` 可先放在模型工作区或数据字典中，不要使用散落的 `Constant` 块保存经验参数。

### 7.2 放置动态入流块

使用普通块搭建：

```text
v_i_QS_mps ----> (+) Sum ----> Gain: 1/tau ----> Integrator ----> v_i_mps
                    ^  -                                      |
                    |__________________________________________|
```

即：

$$
v_{i,\mathrm{QS}}-v_i
\longrightarrow
\frac{1}{\tau}
\longrightarrow
\int
\longrightarrow
v_i.
$$

`Integrator` 初值建议使用当前悬停或初始工况的准定常诱导速度，而不是固定写成 $0$。否则仿真一开始会出现与涡环无关的大过渡过程。

### 7.3 计算诊断量

用 `Sum` 块计算：

$$
q=-V_d+v_i.
$$

把 $q$、$v_h$、$\mu$、$\nu$、$v_{\mathrm{base}}$、$\Delta v_{\mathrm{VRS}}$、`vrs_strength` 和 `input_valid` 组成 `diag_bus`。

## 8. 第七步：设置求解器

独立测试台第一版建议：

- 求解器类型：连续、变步长。
- 求解器：`ode45`。
- 仿真停止时间：先用 $20\ \mathrm{s}$ 到 $60\ \mathrm{s}$。
- 最大步长：不大于 $\tau/20$，以便看清动态入流过程。

接入已有模型后，应服从已有模型的求解器设置。如果改成固定步长，应保证步长远小于最小入流时间常数。

## 9. 第八步：建立五个测试场景

### 场景 A：悬停

$$
V_H=0,
\qquad
V_d=0.
$$

预期：`vrs_flag=0`，$v_i$ 稳定在悬停量级。

### 场景 B：正常小下降率

缓慢增加 $V_d$，但不进入 Johnson VRS 区域。

预期：不错误触发 VRS，输出连续。

### 场景 C：垂直进入 VRS

保持 $V_H=0$，让 $V_d$ 从悬停逐步增加到 VRS 区。

预期：$v_{i,\mathrm{QS}}$ 先变化，$v_i$ 滞后跟随，`vrs_flag` 进入有效状态。

### 场景 D：深度下降后接回基线

继续增加 $V_d$，跨过 VRS 修正区。

预期：分段曲线没有跳变，模型平滑接入风车制动侧基线。

### 场景 E：增加水平速度改出

保持较大 $V_d$，逐步增加 $V_H$。

预期：`vrs_strength` 减小，最终 `vrs_flag=0`。

## 10. 第九步：记录与绘图

使用 `To Workspace` 或信号日志记录：

```text
V_H_mps
V_d_mps
T_N
v_i_mps
v_i_QS_mps
v_h_mps
mu
nu
q_mps
vrs_strength
vrs_flag
```

建议使用 `Dataset` 或 `timeseries`，不要把不同长度的信号手工拼成矩阵。

`plot_vrs_results.m` 至少生成：

1. $v_{i,\mathrm{QS}}$ 与 $v_i$ 时间历程。
2. $V_d$ 与 $V_H$ 时间历程。
3. `vrs_strength` 和 `vrs_flag`。
4. 无量纲入流曲线。
5. 水平速度—下降率 VRS 边界图。

## 11. 第十步：接入已有基础模型

独立测试通过后再做以下连接：

1. 从已有模型取得旋翼轮毂相对空气速度。
2. 在 `VRS_Interface_Adapter` 中得到 $V_H$ 和 $V_d$。
3. 从已有主旋翼模块取得当前拉力 $T$。
4. 把 $V_H$、$V_d$ 和 $T$ 接入 `VRS_Inflow`。
5. 把 $v_i$ 接回已有主旋翼模型的诱导速度入口。
6. 暂时关闭原模型中可能重复的 VRS、经验拉力损失或异常入流修正。
7. 先令 $f=0$ 跑一次，确认接入前后正常区结果基本一致。
8. 再令 $f=1$，运行进入与改出场景。

如果已有模型没有诱导速度入口，不要硬接。应先与基础模型负责人确认允许修改的接口，再决定是否采用有文献依据的拉力修正系数接口。

## 12. 如何判断接线正确

- 悬停时 $V_d=0$，不是负数。
- 向下运动时 $V_d>0$，内部 $V_z=-V_d<0$。
- 增大 $V_H$ 后，VRS 修正应减弱而不是增强。
- `Integrator` 输出必须是 $v_i$，输入必须是 $\dot v_i$。
- $T$ 的单位必须为 $mathrm{N}$，不是拉力系数 $C_T$。
- $\Omega$ 的单位必须为 $\mathrm{rad/s}$。
- 正常区关闭 VRS 后，接入前后结果不应发生大幅变化。

## 13. 常见报错处理

| 现象 | 优先检查 |
|---|---|
| 输出出现复数 | $T$、$\rho$、$R$ 是否为正；平方根是否做保护 |
| 一开始出现巨大尖峰 | `Integrator` 初值是否设为初始准定常值 |
| 模型提示代数环 | 反馈路径是否绕过了 `Integrator`；是否直接用当前 $v_i$ 即时计算并输出当前 $T$ |
| VRS 永远不触发 | $V_d$ 与 $V_z$ 是否符号写反；是否错误使用机体轴速度 |
| 有水平速度反而更危险 | $V_H$ 门控方向是否写反 |
| 分段点出现尖角 | Hermite 端点斜率条件是否一致 |
| 时间响应太慢或太快 | $\tau_{\mathrm{rev}}$、$\Omega$ 和单位换算是否正确 |

## 14. 完成顺序检查表

- [ ] 参数文件可运行且单位完整。
- [ ] 正常基线函数通过悬停与正常区测试。
- [ ] Johnson 静态曲线能正确绘制。
- [ ] D、N、X、E 连续性自动检查通过。
- [ ] $f=0$ 与 $f=1$ 开关测试通过。
- [ ] 水平速度门控测试通过。
- [ ] 动态滞后阶跃测试通过。
- [ ] Simulink 独立测试台五个场景通过。
- [ ] 关闭 VRS 后接入已有模型的基线一致。
- [ ] 开启 VRS 后能生成进入、发展和改出趋势。
