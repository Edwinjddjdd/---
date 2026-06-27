# 补充教材资料登记

## 1. 本次新增教材

| 编号 | 资料 | 作者 | 本地路径 | 页数 | 阶段一用途 |
|---|---|---|---|---:|---|
| B01 | *Principles of Helicopter Aerodynamics* | J. Gordon Leishman | `C:/Users/26534/Downloads/Principles of Helicopter Aerodynamics (Leishman, J. Gordon) (z-library.sk, 1lib.sk, z-lib.sk).pdf` | 864 | 旋翼动量理论、叶素理论、诱导速度、下降飞行与旋翼气动基础 |
| B02 | *Helicopter Flight Dynamics: The Theory and Application of Flying Qualities and Simulation Modelling* | G. D. Padfield | `C:/Users/26534/Downloads/Helicopter flight dynamics the theory and application of flying qualities and simulation modelling (G. D. Padfield) (z-library.sk, 1lib.sk, z-lib.sk).pdf` | 680 | 六自由度飞行动力学、仿真建模、飞行品质和验证框架 |
| B03 | *Helicopter Performance, Stability, and Control* | R. W. Prouty | `C:/Users/26534/Downloads/Helicopter Performance, Stability, and Control (Prouty R.W.) (z-library.sk, 1lib.sk, z-lib.sk).pdf` | 746 | 性能、配平、稳定性、操纵量和工程估算 |
| B04 | *Helicopter Theory* | Wayne Johnson | `C:/Users/26534/Downloads/Helicopter Theory (Wayne Johnson) (z-library.sk, 1lib.sk, z-lib.sk).pdf` | 1120 | 旋翼理论、入流模型、挥舞、载荷和高阶模型依据 |

## 2. 使用原则

- 这些书作为阶段一重做时的高优先级参考源，但不直接替代课程资料。
- 本项目采用中俄轴系作为建模基准；引用英美教材中的公式时，必须先做坐标轴、角度、速度分量、力矩方向和符号正方向转换。
- 阶段二输出的系统规格、架构规格、实现计划和测试计划，应统一使用项目冻结后的中俄轴系，不混用英美/NED 轴系。
- 涉及变量、矩阵、微分方程、传递函数和判据时，Markdown 中必须使用 LaTeX 公式格式。

## 3. 阶段一重读优先级

| 优先级 | 目标 | 资料 |
|---|---|---|
| P0 | 冻结坐标系、正方向、姿态角和速度分量定义 | 课程资料第 1、4 章；Padfield；Prouty |
| P1 | 建立六自由度刚体方程与外力外矩闭合方式 | 课程资料第 4 章；Padfield；Johnson |
| P1 | 建立旋翼诱导速度、动量理论和叶素理论底座 | 课程资料第 5 章；Leishman；Johnson |
| P2 | 建立配平、稳定性和操纵量验证依据 | 课程资料第 5、6 章；Prouty；Padfield |
| P2 | 补强 VRS 入口、修正和改出逻辑 | NASA VRS 报告；Leishman；Johnson |

