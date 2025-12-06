# 混淆矩阵数据计算逻辑文档

## 目录

1. [概述](#1-概述)
2. [核心概念](#2-核心概念)
3. [数据流程](#3-数据流程)
4. [计算公式详解](#4-计算公式详解)
5. [矩阵策略说明](#5-矩阵策略说明)
6. [代码实现对照](#6-代码实现对照)
7. [示例计算](#7-示例计算)

---

## 1. 概述

混淆矩阵（Confusion Matrix）是评估分类模型性能的重要工具。本系统实现了以下功能：

- **完整矩阵**（策略1）：显示从最小值到最大值的所有分类
- **稀疏矩阵**（策略2）：只显示数据中实际出现的分类值
- **最小值过滤**：过滤掉小于等于指定阈值的数据

---

## 2. 核心概念

### 2.1 基本术语

| 术语 | 英文 | 说明 |
|------|------|------|
| 实际值 | Actual Value | 真实的分类标签 |
| 预测值 | Predicted Value | 模型预测的分类标签 |
| 准确率 | Accuracy | 预测正确的样本占总样本的比例 |
| 精准率 | Precision | 对于某一类，预测正确的数量占该类所有预测数量的比例 |
| 召回率 | Recall | 对于某一类，预测正确的数量占该类实际数量的比例 |

### 2.2 矩阵结构

```
              预测值
              0    1    2    合计  召回率
实际值  0   [ TP0  FP01 FP02 ] Row0  R0
        1   [ FP10 TP1  FP12 ] Row1  R1
        2   [ FP20 FP21 TP2  ] Row2  R2
      合计   Col0 Col1 Col2  Total Acc
     精准率   P0   P1   P2   Acc   -
```

其中：
- **TPi**：第 i 类的真阳性（True Positive），即实际值=预测值=i 的数量
- **FPij**：实际值=i 但预测值=j 的数量（预测错误）

---

## 3. 数据流程

### 3.1 数据输入

```javascript
// 详情数据列表 (detailList)
[
  {
    corpusId: "CORPUS_001",      // 语料ID
    acturalValue: "1",           // 实际值（字符串）
    predictedValue: "1",         // 预测值（字符串）
    descValue: "意图分类A",      // 描述值
    createTime: "2025-12-06..."  // 创建时间
  },
  // ... 更多记录
]
```

### 3.2 数据处理流程图

```
┌─────────────────┐
│   原始数据      │
│  detailList     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   数据过滤      │  过滤非数字和 <= minValueFilter 的值
│ filteredList    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  确定显示值     │  根据策略确定行列标题
│ displayValues   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  构建矩阵       │  统计每个单元格的计数
│    matrix       │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   计算行合计    │ │   计算列合计    │ │   计算对角线    │
│    rowSums      │ │    colSums      │ │    diagonal     │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   计算召回率    │ │   计算精准率    │ │   计算准确率    │
│    recalls      │ │   precisions    │ │    accuracy     │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## 4. 计算公式详解

### 4.1 数据过滤

**过滤条件**：
```javascript
// 保留满足以下条件的数据：
// 1. acturalValue 能解析为有效整数
// 2. predictedValue 能解析为有效整数
// 3. 两个值都 > minValueFilter

filteredDetailList = detailList.filter(detail => {
  const actual = parseInt(detail.acturalValue)
  const predicted = parseInt(detail.predictedValue)
  return !isNaN(actual) && !isNaN(predicted) && 
         actual > minValueFilter && predicted > minValueFilter
})
```

**示例**：
- `minValueFilter = 0`
- 原始数据：`[{actual: "1", predicted: "2"}, {actual: "abc", predicted: "1"}, {actual: "0", predicted: "1"}]`
- 过滤后：`[{actual: "1", predicted: "2"}]`
  - 第2条：actual 不是数字，排除
  - 第3条：actual=0，不大于 minValueFilter=0，排除

### 4.2 显示值列表

#### 策略1：完整矩阵

```javascript
// 生成从 (minValueFilter + 1) 到 matrixMax 的连续整数
const startVal = Math.max(0, minValueFilter + 1)
displayValues = Array.from(
  { length: matrixMax - startVal + 1 }, 
  (_, i) => i + startVal
)
```

**示例**：
- `minValueFilter = 0`, `matrixMax = 4`
- `startVal = 1`
- `displayValues = [1, 2, 3, 4]`

#### 策略2：稀疏矩阵

```javascript
// 收集所有出现过的值
const values = new Set()
filteredDetailList.forEach(detail => {
  const actual = parseInt(detail.acturalValue)
  const predicted = parseInt(detail.predictedValue)
  if (!isNaN(actual) && actual > minValueFilter) values.add(actual)
  if (!isNaN(predicted) && predicted > minValueFilter) values.add(predicted)
})
displayValues = Array.from(values).sort((a, b) => a - b)
```

**示例**：
- 数据中出现的值：`actual=[1,2,5]`, `predicted=[1,3,5]`
- `displayValues = [1, 2, 3, 5]`（只包含实际出现的值）

### 4.3 矩阵构建

```javascript
// 初始化 n x n 矩阵（n = displayValues.length）
const matrix = Array(n).fill(0).map(() => Array(n).fill(0))

// 构建值到索引的映射
const valueToIndex = {}
displayValues.forEach((val, idx) => {
  valueToIndex[val] = idx
})

// 统计每个单元格
filteredDetailList.forEach(detail => {
  const actual = parseInt(detail.acturalValue)
  const predicted = parseInt(detail.predictedValue)
  const rowIdx = valueToIndex[actual]
  const colIdx = valueToIndex[predicted]
  
  if (rowIdx !== undefined && colIdx !== undefined) {
    matrix[rowIdx][colIdx]++
  }
})
```

### 4.4 行合计（Row Sum）

**公式**：
```
rowSum[i] = Σ matrix[i][j] for all j
```

**代码**：
```javascript
const rowSum = matrix[i].reduce((a, b) => a + b, 0)
```

**含义**：第 i 行的合计 = 实际值为 displayValues[i] 的所有样本数

### 4.5 列合计（Column Sum）

**公式**：
```
colSum[j] = Σ matrix[i][j] for all i
```

**代码**：
```javascript
const colSum = displayValues.map((_, colIdx) => {
  let sum = 0
  for (let i = 0; i < n; i++) {
    sum += matrix[i][colIdx]
  }
  return sum
})
```

**含义**：第 j 列的合计 = 预测值为 displayValues[j] 的所有样本数

### 4.6 召回率（Recall）

**公式**：
```
recall[i] = matrix[i][i] / rowSum[i] × 100%
          = TP[i] / (TP[i] + FN[i]) × 100%
```

**代码**：
```javascript
const recall = rowSum > 0 ? (matrix[i][i] / rowSum) * 100 : 0
```

**含义**：
- 分子：对角线值 `matrix[i][i]`，即第 i 类预测正确的数量
- 分母：行合计 `rowSum[i]`，即第 i 类的实际总数量
- 解释：在所有实际为第 i 类的样本中，有多少比例被正确预测

### 4.7 精准率（Precision）

**公式**：
```
precision[j] = matrix[j][j] / colSum[j] × 100%
             = TP[j] / (TP[j] + FP[j]) × 100%
```

**代码**：
```javascript
const precision = colSum[j] > 0 ? (matrix[j][j] / colSum[j]) * 100 : 0
```

**含义**：
- 分子：对角线值 `matrix[j][j]`，即预测为第 j 类且预测正确的数量
- 分母：列合计 `colSum[j]`，即所有预测为第 j 类的数量
- 解释：在所有预测为第 j 类的样本中，有多少比例是正确的

### 4.8 准确率（Accuracy）

**公式**：
```
accuracy = Σ matrix[i][i] / totalCount × 100%
         = (TP0 + TP1 + ... + TPn) / total × 100%
```

**代码**：
```javascript
let correct = 0
for (let i = 0; i < n; i++) {
  correct += matrix[i][i]
}
const accuracy = totalCount > 0 ? (correct / totalCount) * 100 : 0
```

**含义**：
- 分子：对角线元素之和，即所有预测正确的样本数
- 分母：总样本数
- 解释：在所有样本中，有多少比例被正确预测

### 4.9 统计指标汇总

| 指标 | 公式 | 位置 | 含义 |
|------|------|------|------|
| 行合计 | `Σ row` | 每行末尾 | 该实际类别的总样本数 |
| 列合计 | `Σ col` | 底部行 | 该预测类别的总预测数 |
| 召回率 | `对角线/行合计` | 每行末尾 | 该类别的召回能力 |
| 精准率 | `对角线/列合计` | 底部行 | 该类别的精准能力 |
| 准确率 | `对角线和/总数` | 右下角 | 整体预测准确度 |

---

## 5. 矩阵策略说明

### 5.1 策略对比

| 特性 | 策略1（完整矩阵） | 策略2（稀疏矩阵） |
|------|------------------|------------------|
| 行列范围 | minValueFilter+1 ~ maxValue | 只包含出现的值 |
| 矩阵大小 | maxValue - minValueFilter | 实际出现的不同值数量 |
| 空值处理 | 显示为 0 | 不显示 |
| 适用场景 | 分类数较少，需要完整视图 | 分类数多但实际使用少 |

### 5.2 示例对比

假设数据中实际值=[1,3,5]，预测值=[1,2,5]，maxValue=5，minValueFilter=0

**策略1（完整矩阵）**：
```
      预测值
      1  2  3  4  5
实际值
1    [x  x  0  0  x]
2    [0  0  0  0  0]
3    [x  x  0  0  x]
4    [0  0  0  0  0]
5    [x  x  0  0  x]
```

**策略2（稀疏矩阵）**：
```
      预测值
      1  2  3  5
实际值
1    [x  x  0  x]
3    [x  x  0  x]
5    [x  x  0  x]
```

---

## 6. 代码实现对照

### 6.1 核心计算属性

| 计算属性 | 说明 | 依赖 |
|----------|------|------|
| `filteredDetailList` | 过滤后的有效数据 | detailList, minValueFilter |
| `appearedValues` | 出现过的值集合 | filteredDetailList |
| `displayValues` | 最终显示的值列表 | matrixStrategy, appearedValues, statistics.matrixMax |
| `valueToIndex` | 值到索引的映射 | displayValues |
| `matrixResult` | 矩阵数据和详情映射 | displayValues, valueToIndex, filteredDetailList |
| `colSums` | 列合计数组 | matrixResult.matrix |
| `precisions` | 精准率数组 | matrixResult.matrix, colSums |
| `totalCount` | 总样本数 | colSums |
| `totalAccuracy` | 总准确率 | matrixResult.matrix, totalCount |
| `tableData` | el-table 数据 | 以上所有 |

### 6.2 计算依赖图

```
detailList + minValueFilter
         │
         ▼
  filteredDetailList
         │
    ┌────┴────┐
    ▼         ▼
appearedValues    (策略1直接用 statistics.matrixMax)
    │              │
    └──────┬───────┘
           ▼
     displayValues
           │
           ▼
     valueToIndex
           │
           ▼
     matrixResult
           │
    ┌──────┼──────┐
    ▼      ▼      ▼
 colSums  rowSums  diagonal
    │      │         │
    ▼      ▼         ▼
precisions recalls accuracy
    │      │         │
    └──────┼─────────┘
           ▼
       tableData
```

---

## 7. 示例计算

### 7.1 输入数据

```javascript
detailList = [
  { acturalValue: "1", predictedValue: "1" },  // 正确
  { acturalValue: "1", predictedValue: "2" },  // 错误
  { acturalValue: "1", predictedValue: "1" },  // 正确
  { acturalValue: "2", predictedValue: "2" },  // 正确
  { acturalValue: "2", predictedValue: "1" },  // 错误
  { acturalValue: "3", predictedValue: "3" },  // 正确
  { acturalValue: "3", predictedValue: "3" },  // 正确
  { acturalValue: "3", predictedValue: "2" },  // 错误
  { acturalValue: "abc", predictedValue: "1" }, // 无效，排除
  { acturalValue: "0", predictedValue: "1" },   // 排除（值不大于0）
]

minValueFilter = 0
matrixStrategy = "1"
```

### 7.2 数据过滤

过滤后剩余 8 条有效数据（排除最后2条）。

### 7.3 显示值

- 策略1：`displayValues = [1, 2, 3]`（假设 matrixMax = 3）
- 策略2：`displayValues = [1, 2, 3]`（出现的值）

### 7.4 矩阵构建

```
值到索引映射：{1: 0, 2: 1, 3: 2}

矩阵：
      预测
      1  2  3
实际
1   [ 2  1  0 ]  → 实际=1：预测=1有2次，预测=2有1次
2   [ 1  1  0 ]  → 实际=2：预测=1有1次，预测=2有1次
3   [ 0  1  2 ]  → 实际=3：预测=2有1次，预测=3有2次
```

### 7.5 统计计算

**行合计**：
- rowSum[0] = 2 + 1 + 0 = 3
- rowSum[1] = 1 + 1 + 0 = 2
- rowSum[2] = 0 + 1 + 2 = 3

**列合计**：
- colSum[0] = 2 + 1 + 0 = 3
- colSum[1] = 1 + 1 + 1 = 3
- colSum[2] = 0 + 0 + 2 = 2

**召回率**：
- recall[0] = 2 / 3 × 100 = 66.67%
- recall[1] = 1 / 2 × 100 = 50.00%
- recall[2] = 2 / 3 × 100 = 66.67%

**精准率**：
- precision[0] = 2 / 3 × 100 = 66.67%
- precision[1] = 1 / 3 × 100 = 33.33%
- precision[2] = 2 / 2 × 100 = 100.00%

**准确率**：
- 对角线和 = 2 + 1 + 2 = 5
- 总数 = 8
- accuracy = 5 / 8 × 100 = 62.50%

### 7.6 最终表格

```
              预测值
              1     2     3     合计   召回率
实际值
  值1         2     1     0      3    66.67%
  值2         1     1     0      2    50.00%
  值3         0     1     2      3    66.67%
合计          3     3     2      8    62.50%
精准率     66.67% 33.33% 100%  62.50%   -
```

---

## 附录

### A. 相关文件

| 文件 | 说明 |
|------|------|
| `src/components/ConfusionMatrix.vue` | 矩阵组件，包含所有计算逻辑 |
| `src/components/StatisticsCards.vue` | 统计卡片组件 |
| `src/components/MetricsCard.vue` | 指标卡片组件 |
| `src/views/MatrixReport.vue` | 报告页面 |
| `src/mock/mockData.js` | Mock数据生成逻辑 |

### B. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0 | 2025-12-06 | 初始版本 |
| 1.1 | 2025-12-06 | 添加稀疏矩阵、最小值过滤 |
| 1.2 | 2025-12-06 | 改用 el-table 渲染 |

