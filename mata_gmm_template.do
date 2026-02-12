// 面向 Stata 用户的 Mata GMM 模板
// - 假设你先用 Stata 进行数据处理，再调用 Mata 做估计。
// - 请将矩条件函数替换为你自己的模型矩条件。

version 17.0
clear all
set more off

// ----------------------------------------------------------------------
// 1) 在 Stata 中加载或准备数据
// ----------------------------------------------------------------------
// 示例：使用已经在内存中的数据集
// use "your_panel_data.dta", clear

// 示例占位符（请替换为你的变量）
// y：因变量，x1 x2：回归变量，z1 z2：工具变量
// 运行 Mata 代码块前请确保变量已存在。

// ----------------------------------------------------------------------
// 2) Mata GMM 实现
// ----------------------------------------------------------------------
mata:

// --- 工具函数：堆叠矩条件 g(theta) ---
// 返回 N×q 的矩条件矩阵，每行对应一个观测。
real matrix gmm_moments(real rowvector theta, real matrix Y, real matrix X, real matrix Z)
{
    // 示例：线性模型 y = X*beta + e
    // theta = beta（1×k）
    // 矩条件：Z * e，其中 e = y - X*beta
    real matrix e
    e = Y :- X * theta'  // N×1

    return(Z :* e)       // N×q（每个工具变量与 e 按元素相乘）
}

// --- 目标函数：GMM 准则 J(theta) = gbar' W gbar ---
real scalar gmm_obj(real rowvector theta, real matrix Y, real matrix X, real matrix Z, real matrix W)
{
    real matrix g
    real rowvector gbar

    g = gmm_moments(theta, Y, X, Z)
    gbar = colsum(g) / rows(g)   // 1×q

    return( gbar * W * gbar' )
}

// --- 两步 GMM 的权重矩阵更新 ---
real matrix gmm_weight(real rowvector theta, real matrix Y, real matrix X, real matrix Z)
{
    real matrix g, S
    g = gmm_moments(theta, Y, X, Z)
    S = (g' * g) / rows(g)       // q×q

    return(invsym(S))
}

// --- 主估计流程 ---
void gmm_estimate()
{
    real matrix Y, X, Z
    real rowvector theta0, theta1
    real matrix W0, W1
    real scalar k, q

    // 从 Stata 读取数据到 Mata
    Y = st_data(., "y")          // N×1
    X = st_data(., "x1 x2")      // N×k
    Z = st_data(., "z1 z2")      // N×q

    k = cols(X)
    q = cols(Z)

    // 初始值（全零）
    theta0 = J(1, k, 0)

    // 初始权重矩阵：单位矩阵
    W0 = I(q)

    // 第一步优化
    theta1 = optimize_init()
    optimize_init_evaluator(theta1, &gmm_obj())
    optimize_init_argument(theta1, 1, Y)
    optimize_init_argument(theta1, 2, X)
    optimize_init_argument(theta1, 3, Z)
    optimize_init_argument(theta1, 4, W0)
    optimize_init_params(theta1, theta0)
    optimize_init_technique(theta1, "nr")

    theta0 = optimize(theta1)

    // 第二步权重矩阵
    W1 = gmm_weight(theta0, Y, X, Z)

    // 第二步优化
    theta1 = optimize_init()
    optimize_init_evaluator(theta1, &gmm_obj())
    optimize_init_argument(theta1, 1, Y)
    optimize_init_argument(theta1, 2, X)
    optimize_init_argument(theta1, 3, Z)
    optimize_init_argument(theta1, 4, W1)
    optimize_init_params(theta1, theta0)
    optimize_init_technique(theta1, "nr")

    theta0 = optimize(theta1)

    // 将估计结果返回到 Stata
    st_matrix("b_gmm", theta0)
    st_numscalar("gmm_obj", gmm_obj(theta0, Y, X, Z, W1))
}

// 运行估计
 gmm_estimate()

end

// ----------------------------------------------------------------------
// 3) 在 Stata 中查看结果
// ----------------------------------------------------------------------
mat list b_gmm
scalar list gmm_obj
