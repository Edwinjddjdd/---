# 阶段二模型规格草案

> 状态：第一版规格草案。坐标轴方向、符号正方向已按 [轴系与符号冻结约定](axis-conventions.md) 冻结；第 4 章六自由度方程和第 5 章悬停例题参数已补入，目标机型参数仍用公开估计集做第一版量级检查。

阶段二缺口数据补齐记录见 [阶段二缺口数据补齐记录](../一、理论基础与文献调研/十、公开数据说明/阶段二缺口数据补齐记录.md)。

## 1. 建模目标

阶段二目标是建立一个能描述直升机进入、维持和改出涡环状态（VRS）的低阶飞行动力学模型。第一版应优先跑通模型链路：

```text
操纵输入
  -> 旋翼/尾桨/机身/尾翼外力外矩
  -> VRS 判别与修正
  -> 六自由度刚体动力学
  -> 场景响应与验证
```

初始状态方程写成：

$$
\dot{x}=f(x,u,t)
$$

其中，$x$ 为状态向量，$u$ 为操纵输入，$t$ 为时间。

## 2. 坐标系冻结项

阶段二正式实现采用 [轴系与符号冻结约定](axis-conventions.md)。核心约定如下：

| 项目 | 冻结内容 | 用途 |
|---|---|---|
| 地轴系 $O_DX_DY_DZ_D$ | $X_D$ 为初始航向或预设方向，$Y_D$ 向上，$Z_D$ 按右手系确定 | 位置、高度和航迹 |
| 体轴系 $OXYZ$ | $X$ 指向机头，$Y$ 向上，$Z$ 按右手系确定并指向驾驶员右手侧 | 六自由度动力学主坐标系 |
| 风轴系 $O_VX_VY_VZ_V$ | $X_V$ 沿空速方向，$Y_V$ 向上，$Z_V$ 按右手系确定 | 迎角、侧滑角、气动力 |
| 桨轴系 $O_SX_SY_SZ_S$ | $X_S$ 指向机头，$Y_S$ 沿旋翼轴向上，$Z_S$ 按右手系确定 | 旋翼力、入流、挥舞和桨盘倾斜 |

任何英文教材公式进入正式规格前，都必须写明源轴系到项目轴系的转换。旋翼力应先在旋翼/桨轴系计算，再转换到机体系。

## 3. 状态向量草案

冻结后的第一版状态向量为：

$$
x=
\begin{bmatrix}
V_x & V_y & V_z & \omega_x & \omega_y & \omega_z & \gamma & \vartheta & \psi & X_D & H & Z_D & v_i & s_\mathrm{VRS}
\end{bmatrix}^{T}
$$

| 分量 | 含义 | 状态 |
|---|---|---|
| $V_x,V_y,V_z$ | 机体系速度分量 | 分别沿体轴 $X,Y,Z$ 正向 |
| $\omega_x,\omega_y,\omega_z$ | 机体系角速度分量 | 分别绕体轴 $X,Y,Z$ 正向 |
| $\gamma,\vartheta,\psi$ | 滚转、俯仰、偏航姿态角 | 先偏航、再俯仰、最后滚转；抬头为正、左偏航为正、右侧倾为正 |
| $X_D,H,Z_D$ | 地轴系位置和高度 | $H=Y_D$，向上为正 |
| $v_i$ | 主旋翼平均诱导速度 | 初版使用均匀入流 |
| $s_\mathrm{VRS}$ | VRS 状态标志或连续强度 | 草案接口 |

如果后续采用动态入流，可将 $v_i$ 扩展为低阶入流状态；如果采用 Pitt-Peters，可引入平均项和一阶谐波项。

## 4. 输入向量草案

操纵输入先按课程资料中的直升机基本操纵量组织：

$$
u=
\begin{bmatrix}
\theta_0 & \theta_{1c} & \theta_{1s} & \theta_{0t}
\end{bmatrix}^{T}
$$

| 输入 | 含义 | 用途 |
|---|---|---|
| $\theta_0$ | 主旋翼总距 | 控制主旋翼拉力和功率输入 |
| $\theta_{1c}$ | 纵向周期变距 | 控制桨盘纵向倾斜和俯仰力矩 |
| $\theta_{1s}$ | 横向周期变距 | 控制桨盘横向倾斜和滚转力矩 |
| $\theta_{0t}$ | 尾桨总距 | 控制尾桨侧向力和反扭矩平衡 |

输入正方向必须与中俄轴系、课程操纵定义和旋翼力矩方向一起冻结。

## 5. 六自由度刚体方程

阶段二第一版采用课程第 4 章的非线性刚体方程。状态导数分成四块：

$$
\dot{x}=
\begin{bmatrix}
\dot{V}_x & \dot{V}_y & \dot{V}_z &
\dot{\omega}_x & \dot{\omega}_y & \dot{\omega}_z &
\dot{\gamma} & \dot{\vartheta} & \dot{\psi} &
\dot{X}_D & \dot{H} & \dot{Z}_D &
\dot{v}_i & \dot{s}_\mathrm{VRS}
\end{bmatrix}^{T}
$$

### 5.1 平动方程

在冻结后的中俄体轴系下，课程第 4 章给出的平动方程整理为：

$$
m\left(\dot{V}_x+V_z\omega_y-V_y\omega_z\right)+mg\sin\vartheta=F_x
$$

$$
m\left(\dot{V}_y+V_x\omega_z-V_z\omega_x\right)+mg\cos\vartheta\cos\gamma=F_y
$$

$$
m\left(\dot{V}_z+V_y\omega_x-V_x\omega_y\right)-mg\cos\vartheta\sin\gamma=F_z
$$

实现时写成显式一阶形式：

$$
\dot{V}_x=\frac{F_x}{m}-V_z\omega_y+V_y\omega_z-g\sin\vartheta
$$

$$
\dot{V}_y=\frac{F_y}{m}-V_x\omega_z+V_z\omega_x-g\cos\vartheta\cos\gamma
$$

$$
\dot{V}_z=\frac{F_z}{m}-V_y\omega_x+V_x\omega_y+g\cos\vartheta\sin\gamma
$$

其中 $F_x,F_y,F_z$ 为除重力以外的气动/推进合力在体轴系下的分量。

### 5.2 转动方程

课程第 4 章保留惯性积 $I_{xy}$，第一版转动方程采用：

$$
I_x\dot{\omega}_x
+\omega_y\omega_z(I_z-I_y)
+(\omega_x\omega_z-\dot{\omega}_y)I_{xy}
=\sum M_x
$$

$$
I_y\dot{\omega}_y
+\omega_x\omega_z(I_x-I_z)
-(\omega_y\omega_z+\dot{\omega}_x)I_{xy}
=\sum M_y
$$

$$
I_z\dot{\omega}_z
+\omega_x\omega_y(I_y-I_x)
+(\omega_y^2-\omega_x^2)I_{xy}
=\sum M_z
$$

为避免实现时重复处理 $\dot{\omega}_x,\dot{\omega}_y$ 的耦合，代码中建议写成矩阵形式：

$$
\mathbf{I}_{xz}
\begin{bmatrix}
\dot{\omega}_x\\
\dot{\omega}_y\\
\dot{\omega}_z
\end{bmatrix}
=
\begin{bmatrix}
\sum M_x-\omega_y\omega_z(I_z-I_y)-\omega_x\omega_z I_{xy}\\
\sum M_y-\omega_x\omega_z(I_x-I_z)+\omega_y\omega_z I_{xy}\\
\sum M_z-\omega_x\omega_y(I_y-I_x)-(\omega_y^2-\omega_x^2)I_{xy}
\end{bmatrix}
$$

其中第一版惯性矩阵写为：

$$
\mathbf{I}_{xz}=
\begin{bmatrix}
I_x & -I_{xy} & 0\\
-I_{xy} & I_y & 0\\
0 & 0 & I_z
\end{bmatrix}
$$

如果第一版参数缺少惯性积，可先设 $I_{xy}=0$，并在参数表中明确这是临时简化。

### 5.3 姿态运动学

课程第 4 章给出的姿态运动学关系为：

$$
\dot{\gamma}=\omega_x-\tan\vartheta\left(\omega_y\cos\gamma-\omega_z\sin\gamma\right)
$$

$$
\dot{\psi}=\frac{1}{\cos\vartheta}\left(\omega_y\cos\gamma-\omega_z\sin\gamma\right)
$$

$$
\dot{\vartheta}=\omega_y\sin\gamma+\omega_z\cos\gamma
$$

实现约束：

- 当 $\cos\vartheta$ 接近零时，欧拉角描述会出现奇异性；第一版 VRS 场景不应靠近该姿态。
- 如果后续需要大姿态机动，应改用四元数或方向余弦矩阵积分。

### 5.4 位置运动学

位置运动学由体轴速度转换到地轴系：

$$
\begin{bmatrix}
\dot{X}_D\\
\dot{H}\\
\dot{Z}_D
\end{bmatrix}
=
\mathbf{C}_{D\leftarrow B}(\psi,\vartheta,\gamma)
\begin{bmatrix}
V_x\\
V_y\\
V_z
\end{bmatrix}
$$

其中 $\mathbf{C}_{D\leftarrow B}$ 必须按 [轴系与符号冻结约定](axis-conventions.md) 中“先偏航 $\psi$、再俯仰 $\vartheta$、最后滚转 $\gamma$”的旋转顺序构造。第一版实现前需要用三个单位姿态算例验证矩阵方向：

- $\psi=\vartheta=\gamma=0$ 时，体轴速度应直接映射到地轴同向分量。
- 纯抬头 $\vartheta>0$ 时，前向速度 $V_x>0$ 应产生正高度变化 $\dot{H}>0$。
- 纯右侧倾 $\gamma>0$ 时，向上体轴分量和侧向分量的投影方向应与轴系约定一致。

下降率统一使用：

$$
V_d=-\dot{H}
$$

## 6. 模块边界

| 模块 | 输入 | 输出 | 第一版策略 |
|---|---|---|---|
| `RigidBody6DOF` | 合力、合力矩、当前状态 | $\dot{x}$ 的刚体部分 | 非线性刚体方程，按冻结轴系展开 |
| `MainRotor` | 操纵量、飞行状态、诱导速度 | 主旋翼力、力矩、功率量级 | 叶素框架 + 均匀入流 |
| `TailRotor` | 尾桨总距、机体状态 | 侧向力、偏航力矩 | 简化尾桨力模型 |
| `FuselageTailAero` | 速度、姿态、角速度 | 机身/平尾/垂尾气动力 | 简化气动导数或经验项 |
| `InflowModel` | 旋翼载荷、飞行状态 | $v_i$ | 均匀入流起步 |
| `VRS_Detection` | 水平速度、下降率、功率/总距、$v_i$ | $s_\mathrm{VRS}$ | 工程判据，第一版使用布尔触发 |
| `VRS_Correction` | $s_\mathrm{VRS}$、$v_i$、主旋翼载荷 | 修正后的入流或有效拉力 | 连续修正系数，第一版可先用分段线性 |
| `Trim` | 目标飞行状态 | 配平操纵量和姿态 | 先做悬停和定常下降 |

## 7. VRS 判别接口

第一版 VRS 判别不直接追求完整涡结构预测，而是建立工程触发条件：

$$
s_\mathrm{VRS}=g(V_h,V_d,\theta_0,v_i)
$$

其中：

- $V_h$ 为水平速度量级。
- $V_d$ 为下降率，定义为 $V_d=-\dot{H}$，向下为正。
- $\theta_0$ 或功率输入用于区分有功率下降和自转。
- $v_i$ 为主旋翼平均诱导速度。

初始触发逻辑来自 FAA 判据和 Johnson VRS 模型笔记：

- 低水平速度。
- 有明显下降率。
- 仍有功率或总距输入。
- 旋翼处于自身下洗影响区域。

第一版临时触发函数采用：

$$
s_\mathrm{VRS}=
\begin{cases}
1,& V_h<12\,\mathrm{m/s},\ V_d>1.52\,\mathrm{m/s},\ \theta_0>0\\
0,& \text{otherwise}
\end{cases}
$$

其中 $1.52\,\mathrm{m/s}$ 约等于 $300\,\mathrm{ft/min}$。该阈值来自 FAA 风险条件的工程化初值，后续应由 Johnson 边界模型或试验数据替换。

## 8. VRS 修正接口

VRS 修正先作为连续系数作用于诱导速度或有效拉力：

$$
T_\mathrm{eff}=k_T(s_\mathrm{VRS})T_\mathrm{nom}
$$

$$
v_{i,\mathrm{eff}}=k_v(s_\mathrm{VRS})v_i
$$

其中，$T_\mathrm{nom}$ 为正常入流模型下的名义拉力，$T_\mathrm{eff}$ 为进入 VRS 修正后的有效拉力。$k_T$ 和 $k_v$ 的具体形式待依据 Johnson 模型、课程配平数据和验证需求确定。

第一版“先跑起来”可采用保守的分段线性形式：

$$
k_T=
\begin{cases}
1,& s_\mathrm{VRS}=0\\
k_{T,\min},& s_\mathrm{VRS}=1
\end{cases}
$$

其中 $k_{T,\min}$ 可先取 $0.75$ 到 $0.9$ 做参数扫掠，不作为物理定值。若需要避免突跳，应把 $s_\mathrm{VRS}$ 从布尔值改为一阶滞后连续状态：

$$
\tau_\mathrm{VRS}\dot{s}_\mathrm{VRS}=s_\mathrm{cmd}-s_\mathrm{VRS}
$$

其中 $s_\mathrm{cmd}$ 为判据输出，$\tau_\mathrm{VRS}$ 为进入/退出时间常数。

## 9. 第一版参数与数据

第一版参数入口：

- 课程 Z-11 悬停例题：`course_z11_hover_example`
- 课程 Z-11 悬停配平结果：`course_z11_hover_trim_result`
- Z-10 公开低估计：`z10_public_low_estimate`
- Z-10 公开高估计：`z10_public_high_estimate`
- D6075 VRS 参考旋翼：`d6075_vrs_reference_model`
- NACA 0012 临时代用翼型：`airfoil_seed`
- VRS 第一版触发阈值：`vrs_seed_thresholds`

参数文件：

`data/derived/stage2_seed_parameters.json`

Sanity check 脚本：

`scripts/stage2_sanity_check.py`

Sanity check 输出：

- `data/derived/stage2_sanity_summary.csv`
- `data/derived/stage2_vrs_trigger_grid.csv`

第一版建议先以课程 Z-11 例题做悬停配平闭环，再用 Z-10 公开低/高估计做量级敏感性检查。

## 10. 第一版交付边界

第一版模型只需要证明以下链路可运行：

1. 悬停配平能够给出合理拉力和功率量级。
2. 正常下降不触发 VRS。
3. 低速大下降率触发 `VRS_Detection`。
4. `VRS_Correction` 能导致有效拉力下降或垂向速度增大。
5. 改出输入能让 VRS 标志退出并恢复垂向响应。

## 11. 已补齐资料与剩余风险

### 11.1 已补齐并落地的资料

| 资料项 | 已补内容 | 落地位置 | 第一版用途 |
|---|---|---|---|
| 课程第 4 章运动方程 | 已从微信 PDF 抽取平动、转动和姿态运动学方程，并整理成本文件第 5 节的六自由度刚体方程 | `tmp/pdfs/course4-motion.txt`、本文件第 5 节 | `RigidBody6DOF` 的方程依据 |
| 位置运动学 | 已补入 $\mathbf{C}_{D\leftarrow B}(\psi,\vartheta,\gamma)$ 接口和 $V_d=-\dot{H}$ 约定 | 本文件第 5.4 节 | 实现前用单位姿态算例验证方向 |
| 课程第 5 章例题参数 | 已抽取 Z-11 悬停例题参数和配平结果 | `data/derived/stage2_seed_parameters.json` 的 `course_z11_hover_example`、`course_z11_hover_trim_result` | 悬停配平、功率量级和操纵量数量级校验 |
| 目标机型公开参数 | 已建立 Z-10 公开低/高估计两个参数集；低估计以 Deagel 明示的 $12\,\mathrm{m}$ 主旋翼直径、$7000\,\mathrm{kg}$ 最大起飞重量为主 | `data/derived/stage2_seed_parameters.json` 的 `z10_public_low_estimate`、`z10_public_high_estimate` | 第一版量级敏感性检查 |
| 翼型气动表 | 已下载 UIUC NACA 0012 坐标和 AirfoilTools $Re=10^6$ 极曲线 | `data/public/naca0012-uiuc.dat`、`data/public/naca0012-airfoiltools-Re1e6.csv` | 叶素模型临时代用 |
| VRS 判据资料 | 已采用 FAA VRS 进入条件和 Johnson 平均入流/稳定边界建模思路 | `data/derived/stage2_seed_parameters.json` 的 `vrs_seed_thresholds`、`d6075_vrs_reference_model` | `VRS_Detection` 初始阈值与后续边界模型参考 |

### 11.2 来源索引

- Deagel Z-10：<https://www.deagel.com/aerospace%20forces/z-10/a001837>
- Army Technology Z-10：<https://www.army-technology.com/projects/z-10-attack-helicopter/>
- Military Today Z-10：<https://www.militarytoday.com/helicopters/z10.htm>
- UIUC NACA 0012 坐标：<https://m-selig.ae.illinois.edu/ads/coord/n0012.dat>
- AirfoilTools NACA 0012 $Re=10^6$ 极曲线：<http://airfoiltools.com/polar/csv?polar=xf-n0012-il-1000000>
- FAA Helicopter Flying Handbook Chapter 11：<https://www.faa.gov/sites/faa.gov/files/regulations_policies/handbooks_manuals/aviation/helicopter_flying_handbook/hfh_ch11.pdf>
- Wayne Johnson, NASA TP-2005-213477：<https://rotorcraft.arc.nasa.gov/Publications/files/Johnson_TP-2005-213477.pdf>

### 11.3 仍需保留的风险标注

- Z-10 公开参数不是完整工程数据，当前只用于第一版量级检查；论文或报告中不能把它写成权威设计参数。
- NACA 0012 只是公开对称翼型临时代用；找到目标旋翼翼型或更接近的 OA209、VR-7、SC1095 等数据后应替换。
- 真实 VRS 试飞时序或风洞曲线暂未找到；第一版只能做 FAA 阈值触发和 Johnson 趋势验证，不能做精确边界标定。
- 位置转换矩阵虽已写入接口，但实现前必须用单位姿态算例验证 $\mathbf{C}_{D\leftarrow B}$ 的方向和 $V_d=-\dot{H}$ 的符号。
