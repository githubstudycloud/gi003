# 实现文档

> 本文档详细描述混淆矩阵评估系统前端的技术实现细节

---

## 目录

1. [架构设计](#架构设计)
2. [核心组件实现](#核心组件实现)
3. [数据流设计](#数据流设计)
4. [Mock系统实现](#mock系统实现)
5. [算法说明](#算法说明)
6. [配置参数](#配置参数)

---

## 架构设计

### 技术栈

```
Vue 3 (Composition API)
├── Element Plus (UI组件库)
├── Vite (构建工具)
└── ES Module (模块化)
```

### 目录结构

```
src/
├── api/              # API接口层
│   └── matrix.js     # 矩阵报告API
├── components/       # 可复用组件
│   ├── ConfusionMatrix.vue    # 核心矩阵组件
│   ├── StatisticsCards.vue    # 统计卡片
│   └── MetricsCard.vue        # 指标详情卡片
├── views/            # 页面视图
│   └── MatrixReport.vue       # 主报告页
├── mock/             # Mock数据层
│   ├── index.js      # Mock入口
│   └── mockData.js   # 数据生成器
└── docs/             # 文档目录
    ├── CHANGELOG.md  # 变更记录
    └── IMPLEMENTATION.md  # 本文档
```

### 组件关系

```
MatrixReport.vue (页面)
├── StatisticsCards.vue (统计卡片)
├── MetricsCard.vue (指标详情)
│   └── 详细指标卡片 (4个)
└── ConfusionMatrix.vue (核心矩阵)
    ├── 矩阵表格
    ├── 精准率行
    └── 召回率列
```

---

## 核心组件实现

### 1. ConfusionMatrix.vue

#### 功能

- 渲染混淆矩阵表格
- 支持两种矩阵策略
- 计算精准率和召回率
- 处理单元格点击事件

#### Props

```javascript
{
  detailList: Array,      // 详情数据
  markList: Array,        // 标记映射
  statistics: Object,     // 统计信息
  matrixStrategy: String, // "1"完整 / "2"稀疏
  minValueFilter: Number  // 最小值过滤阈值（默认0）
}
```

#### 核心算法

**矩阵构建**:

```javascript
// 1. 过滤有效数据
const filteredDetailList = detailList.filter(d => {
  const actual = parseInt(d.acturalValue)
  const predicted = parseInt(d.predictedValue)
  return !isNaN(actual) && !isNaN(predicted) && 
         actual > minValueFilter && predicted > minValueFilter
})

// 2. 确定显示值
if (matrixStrategy === '2') {
  // 稀疏矩阵：只取出现过的值
  displayValues = [...new Set(filteredDetailList.flatMap(d => 
    [parseInt(d.acturalValue), parseInt(d.predictedValue)]
  ))].sort((a, b) => a - b)
} else {
  // 完整矩阵：minValueFilter+1 到 maxValue
  displayValues = Array.from({length: maxValue - minValueFilter}, 
    (_, i) => i + minValueFilter + 1)
}

// 3. 构建矩阵
const matrix = Array(size).fill(0).map(() => Array(size).fill(0))
filteredDetailList.forEach(d => {
  const rowIdx = valueToIndex[d.acturalValue]
  const colIdx = valueToIndex[d.predictedValue]
  matrix[rowIdx][colIdx]++
})
```

**精准率计算**:

```javascript
// 精准率 = 对角线值 / 列总和
precisions[colIdx] = colSum > 0 
  ? (matrix[colIdx][colIdx] / colSum) * 100 
  : 0
```

**召回率计算**:

```javascript
// 召回率 = 对角线值 / 行总和
recall = rowSum > 0 
  ? (matrix[rowIdx][rowIdx] / rowSum) * 100 
  : 0
```

---

### 2. MetricsCard.vue

#### 功能

- 展示用例配置信息
- 展示核心统计指标
- 展示详细指标（最高/最低精准率、召回率）

#### 详细指标计算

```javascript
// 从classStats中提取有数据的类别
const classesWithData = classStats.filter(s => 
  s.actualCount > 0 || s.predictedCount > 0
)

// 计算极值
const precisions = classesWithData.map(s => s.precision).filter(p => p > 0)
const recalls = classesWithData.map(s => s.recall).filter(r => r > 0)

maxPrecision = Math.max(...precisions)
minPrecision = Math.min(...precisions)
maxRecall = Math.max(...recalls)
minRecall = Math.min(...recalls)
```

#### 等级判定

```javascript
const getMetricLevel = (value) => {
  if (value >= 90) return '优秀'
  if (value >= 70) return '良好'
  if (value >= 50) return '中等'
  if (value >= 30) return '较低'
  return '极低'
}
```

---

### 3. StatisticsCards.vue

#### 功能

展示5个核心统计指标卡片：
- 总样本数
- 有效样本数
- 预测正确数
- 预测错误数
- 准确率

#### 计算逻辑

```javascript
// 预测错误数
errorCount = validCount - correctCount

// 准确率
accuracy = validCount > 0 ? (correctCount / validCount) * 100 : 0
```

---

## 数据流设计

### 请求流程

```
用户选择场景
    ↓
点击查询按钮
    ↓
MatrixReport.handleQuery()
    ↓
api/matrix.js → getMatrixReport()
    ↓
判断 MOCK_ENABLED
    ├─ true  → mock/index.js → getMockData()
    │           └─ mockData.js → generateMockReport()
    └─ false → fetch('/api/matrix/report')
    ↓
返回数据格式:
{
  code: 200,
  data: [
    {
      caseConfig: { ... },
      detailList: [ ... ],
      markList: [ ... ],
      statistics: { ... }
    }
  ]
}
    ↓
更新 reportData
    ↓
子组件响应式更新
```

### 数据结构

```typescript
interface CaseData {
  caseConfig: {
    reportId: string
    taskId: string
    caseId: string
    matrixStrategy: '1' | '2'
    minValueFilter: number
    // ...
  }
  detailList: Array<{
    corpusId: string
    acturalValue: string
    predictedValue: string
    descValue: string
    createTime: string
  }>
  markList: Array<{
    id: string
    value: string
    desc: string
  }>
  statistics: {
    totalCount: number
    validCount: number
    invalidCount: number
    correctCount: number
    accuracy: number
    avgPrecision: number
    avgRecall: number
    maxPrecision: number
    minPrecision: number
    maxRecall: number
    minRecall: number
    matrixMax: number
    minValueFilter: number
  }
}
```

---

## Mock系统实现

### 启用/禁用

```javascript
// src/mock/index.js
export const MOCK_ENABLED = true  // 启用Mock
export const MOCK_ENABLED = false // 禁用Mock
```

### 场景配置

```javascript
const mockScenarios = [
  {
    id: 'RPT001',
    name: '基础场景',
    desc: '场景描述',
    config: {
      reportId: 'RPT001',
      taskId: 'TASK001',
      caseConfigs: [
        {
          caseId: 'CASE_1',
          detailCount: 200,      // 数据量
          maxValue: 5,           // 最大分类值
          correctRate: 70,       // 正确率(%)
          matrixStrategy: '1',   // 矩阵策略
          minValueFilter: 0,     // 最小值过滤
          validValues: [1,2,3]   // 有效值（稀疏矩阵用）
        }
      ]
    }
  }
]
```

### 数据生成流程

```
generateMockReport(options)
    ↓
遍历 caseConfigs
    ↓
generateCaseData(caseConfig)
    ├─ generateDetail() × detailCount 次
    ├─ generateMarkList()
    └─ calculateStatistics()
    ↓
返回完整报告数据
```

---

## 算法说明

### 无效数据过滤

数据被视为无效的条件：
1. `acturalValue` 不是有效数字
2. `predictedValue` 不是有效数字
3. `acturalValue <= minValueFilter`
4. `predictedValue <= minValueFilter`

```javascript
const isValid = (detail) => {
  const actual = parseInt(detail.acturalValue)
  const predicted = parseInt(detail.predictedValue)
  return !isNaN(actual) && 
         !isNaN(predicted) && 
         actual > minValueFilter && 
         predicted > minValueFilter
}
```

### 矩阵策略

| 策略 | 描述 | 显示范围 |
|------|------|----------|
| 1 | 完整矩阵 | `[minValueFilter+1, maxValue]` |
| 2 | 稀疏矩阵 | 数据中实际出现的值（且 > minValueFilter） |

### 指标公式

| 指标 | 公式 |
|------|------|
| 准确率 | `correctCount / validCount × 100%` |
| 精准率(类别i) | `TP_i / (TP_i + FP_i) × 100%` |
| 召回率(类别i) | `TP_i / (TP_i + FN_i) × 100%` |
| 平均精准率 | `Σ(precision_i) / n` |
| 平均召回率 | `Σ(recall_i) / n` |

其中：
- `TP_i`: 实际为i且预测为i的数量（对角线值）
- `FP_i`: 实际非i但预测为i的数量（列总和-对角线）
- `FN_i`: 实际为i但预测非i的数量（行总和-对角线）

---

## 配置参数

### 全局配置

| 参数 | 位置 | 默认值 | 说明 |
|------|------|--------|------|
| MOCK_ENABLED | mock/index.js | true | Mock模式开关 |
| DEFAULT_MIN_VALUE_FILTER | mockData.js | 0 | 默认最小值过滤阈值 |
| API_BASE_URL | api/matrix.js | '/api' | 后端API基础地址 |

### 组件配置

| 组件 | 参数 | 类型 | 默认值 | 说明 |
|------|------|------|--------|------|
| ConfusionMatrix | matrixStrategy | String | '1' | 矩阵策略 |
| ConfusionMatrix | minValueFilter | Number | 0 | 最小值过滤 |

### Vite配置

```javascript
// vite.config.js
export default defineConfig({
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
})
```

---

## 性能优化

### 大数据量处理

1. **虚拟滚动**: 弹窗表格使用 `max-height` 限制
2. **计算缓存**: 使用 `computed` 缓存矩阵计算结果
3. **按需渲染**: 只渲染当前激活Tab的内容

### 渲染优化

1. **CSS层面**: 使用 `position: sticky` 固定表头
2. **交互层面**: 使用 `transition` 提供视觉反馈
3. **数据层面**: 过滤无效数据减少渲染量

---

## 扩展指南

### 添加新指标

1. 在 `mockData.js` 的 `calculateStatistics` 中计算
2. 在 `MetricsCard.vue` 中添加展示
3. 更新类型定义和文档

### 添加新场景

1. 在 `mock/index.js` 的 `mockScenarios` 中添加配置
2. 场景ID需唯一
3. 配置参数参考已有场景

### 添加新组件

1. 在 `components/` 目录创建 `.vue` 文件
2. 添加完整的 JSDoc 注释
3. 在需要的页面中导入使用
4. 更新文档

---

## 版本信息

- **当前版本**: 1.1.0
- **最后更新**: 2025-12-06
- **维护者**: AI Assistant

