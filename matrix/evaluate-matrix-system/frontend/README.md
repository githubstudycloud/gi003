# 混淆矩阵评估系统 - 前端文档 V1.1

## 目录

1. [系统概述](#系统概述)
2. [v1.1更新内容](#v11更新内容)
3. [技术架构](#技术架构)
4. [目录结构](#目录结构)
5. [核心功能](#核心功能)
6. [组件说明](#组件说明)
7. [Mock模式](#mock模式)
8. [API接口](#api接口)
9. [安装与运行](#安装与运行)
10. [配置说明](#配置说明)
11. [开发指南](#开发指南)
12. [版本计划](#版本计划)

---

## 系统概述

混淆矩阵评估系统是一个用于展示和分析分类预测结果的可视化工具。系统支持：

- **多用例管理**：一个报告可包含多个测试用例，通过Tab页切换
- **双矩阵策略**：完整矩阵(正方形)和稀疏矩阵(仅显示出现的值)
- **核心指标统计**：准确率、精准率、召回率自动计算
- **详细指标展示**：最高/最低精准率、召回率 (v1.1新增)
- **交互式查看**：点击单元格/合计行查看详细数据
- **无效数据过滤**：支持过滤负数和小于指定值的数据 (v1.1新增)
- **前端独立调试**：完整的Mock数据支持

### 核心概念

| 术语 | 定义 |
|------|------|
| **准确率 (Accuracy)** | 预测正确数 / 有效样本数 |
| **精准率 (Precision)** | 各类预测正确数 / 该类预测总数 |
| **召回率 (Recall)** | 各类预测正确数 / 该类实际总数 |
| **完整矩阵** | 显示minValueFilter+1到最大值的所有分类（策略1） |
| **稀疏矩阵** | 只显示数据中实际出现且大于minValueFilter的分类值（策略2） |

---

## v1.1更新内容

### 新增功能

#### 1. 详细指标卡片

在用例详情区域新增4个指标展示：

| 指标 | 说明 | 等级 |
|------|------|------|
| 最高召回率 | 各分类中最高的召回率 | 优秀/良好/中等/较低/极低 |
| 最低召回率 | 各分类中最低的召回率 | 优秀/良好/中等/较低/极低 |
| 最高精准率 | 各分类中最高的精准率 | 优秀/良好/中等/较低/极低 |
| 最低精准率 | 各分类中最低的精准率 | 优秀/良好/中等/较低/极低 |

等级判定标准：
- 优秀: ≥90%
- 良好: 70-89%
- 中等: 50-69%
- 较低: 30-49%
- 极低: <30%

#### 2. 最小值过滤

新增 `minValueFilter` 参数：
- 默认值：0
- 作用：过滤小于等于此值的分类数据
- 场景：过滤负数、0值等无效分类

```javascript
// 配置示例
{
  caseId: 'CASE_1',
  minValueFilter: 0,  // 只显示大于0的值
  matrixStrategy: '2'
}
```

### Bug修复

- ✅ 修复精准率行不显示的问题
- ✅ 修复合计行/列无法点击的问题
- ✅ 修复显示说明列默认值不友好的问题
- ✅ 修复稀疏矩阵显示负数的问题

---

## 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                       前端架构                               │
├─────────────────────────────────────────────────────────────┤
│  Vue 3 (Composition API) + Element Plus + Vite              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │ 视图层    │    │ 组件层    │    │ 数据层   │              │
│  │          │    │          │    │          │              │
│  │ Views/   │───>│Components│───>│  API/    │              │
│  │          │    │          │    │  Mock/   │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| Vue | 3.x | 前端框架 |
| Element Plus | 2.x | UI组件库 |
| Vite | 5.x | 构建工具 |
| ES Module | - | 模块化方案 |

---

## 目录结构

```
frontend/
├── index.html              # 入口HTML
├── package.json            # 依赖配置
├── vite.config.js          # Vite配置
├── README.md               # 本文档
│
├── docs/                   # 文档目录 (v1.1新增)
│   ├── CHANGELOG.md        # 需求变更记录
│   └── IMPLEMENTATION.md   # 实现文档
│
└── src/
    ├── main.js             # 应用入口
    ├── App.vue             # 根组件
    │
    ├── api/                # API接口层
    │   └── matrix.js       # 矩阵报告API
    │
    ├── views/              # 页面视图
    │   └── MatrixReport.vue    # 主报告页面
    │
    ├── components/         # 可复用组件
    │   ├── ConfusionMatrix.vue     # 混淆矩阵组件
    │   ├── StatisticsCards.vue     # 统计卡片组件
    │   └── MetricsCard.vue         # 指标详情组件 (v1.1增强)
    │
    └── mock/               # Mock数据层
        ├── index.js        # Mock入口与场景配置
        └── mockData.js     # 数据生成器
```

---

## 核心功能

### 1. 多用例Tab页

支持一个报告包含多个测试用例，每个用例独立展示：
- 独立的统计数据
- 独立的混淆矩阵
- 可切换的矩阵策略

### 2. 统计卡片

展示5个核心统计指标：

| 指标 | 说明 |
|------|------|
| 总样本数 | 所有数据记录数量 |
| 有效样本数 | 实际值和预测值都是有效数字且大于minValueFilter的记录数 |
| 预测正确数 | 实际值=预测值的记录数 |
| 预测错误数 | 有效样本数 - 预测正确数 |
| 准确率 | 预测正确数 / 有效样本数 × 100% |

### 3. 详细指标卡片 (v1.1新增)

展示4个极值指标：
- 最高/最低召回率
- 最高/最低精准率
- 带等级标识（优秀/良好/中等/较低/极低）

### 4. 混淆矩阵表格

二维表格展示分类预测结果：

- **行**：实际分类值
- **列**：预测分类值
- **对角线**：预测正确的数量
- **非对角线**：预测错误的数量
- **合计行**：每列的总和（可点击）
- **合计列**：每行的总和（可点击）
- **精准率行**：每列的精准率
- **召回率列**：每行的召回率

### 5. 矩阵策略

| 策略 | 说明 | 适用场景 |
|------|------|----------|
| 完整矩阵(1) | 显示minValueFilter+1到最大值的所有分类 | 分类连续、数量较少 |
| 稀疏矩阵(2) | 只显示实际出现的分类值(>minValueFilter) | 分类不连续、数量较多 |

### 6. 最小值过滤 (v1.1新增)

- 默认过滤小于等于0的值
- 可配置 `minValueFilter` 参数
- 适用于过滤负数、无效分类等

### 7. 交互功能

- **单元格点击**：查看该单元格对应的详细记录
- **行合计点击**：查看该实际值的所有记录
- **列合计点击**：查看该预测值的所有记录

---

## 组件说明

### ConfusionMatrix.vue

混淆矩阵核心组件，负责矩阵的渲染和交互。

#### Props

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| detailList | Array | [] | 详情数据列表 |
| markList | Array | [] | 标记映射列表 |
| statistics | Object | {} | 统计信息 |
| matrixStrategy | String | '1' | 矩阵策略 |
| minValueFilter | Number | 0 | 最小值过滤阈值 (v1.1新增) |

#### Events

| 事件 | 参数 | 说明 |
|------|------|------|
| cell-click | { actual, predicted, count, records, type } | 单元格/合计点击 |

#### 使用示例

```vue
<ConfusionMatrix
  :detail-list="detailList"
  :mark-list="markList"
  :statistics="statistics"
  :matrix-strategy="'1'"
  :min-value-filter="0"
  @cell-click="handleCellClick"
/>
```

### StatisticsCards.vue

统计卡片组件，展示核心统计指标。

#### Props

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| statistics | Object | {} | 统计数据对象 |

### MetricsCard.vue (v1.1增强)

指标详情卡片组件，展示用例配置和详细指标。

#### Props

| 属性 | 类型 | 必填 | 说明 |
|------|------|------|------|
| caseData | Object | 是 | 用例完整数据 |

#### 新增展示内容 (v1.1)

- 最高召回率 + 等级
- 最低召回率 + 等级
- 最高精准率 + 等级
- 最低精准率 + 等级

---

## Mock模式

### 启用/禁用

在 `src/mock/index.js` 中设置：

```javascript
// 启用Mock模式（前端独立调试）
export const MOCK_ENABLED = true

// 禁用Mock模式（连接真实后端）
export const MOCK_ENABLED = false
```

### 预设场景

系统预设了10个测试场景：

| 场景ID | 名称 | 说明 |
|--------|------|------|
| RPT001 | 基础场景 | 单用例，5分类，200条数据 |
| RPT002 | 多用例场景 | 3个用例，不同配置 |
| RPT003 | 高准确率 | 约95%准确率 |
| RPT004 | 低准确率 | 约40%准确率 |
| RPT005 | 大规模数据 | 1000条数据，10分类 |
| RPT006 | 小规模数据 | 50条数据，3分类 |
| RPT007 | 边界值测试 | 二分类、单分类 |
| RPT008 | 无效数据测试 | 包含较多无效数据 |
| RPT009 | 稀疏矩阵测试 | 策略2测试（>0的值） |
| RPT010 | 混合策略测试 | 完整+稀疏矩阵 |

### 自定义场景

在 `src/mock/index.js` 的 `mockScenarios` 数组中添加：

```javascript
{
  id: 'RPT_CUSTOM',
  name: '自定义场景',
  desc: '场景描述',
  config: {
    reportId: 'RPT_CUSTOM',
    taskId: 'TASK_CUSTOM',
    caseConfigs: [
      { 
        caseId: 'CASE_1', 
        detailCount: 100,     // 数据量
        maxValue: 5,          // 最大分类值
        correctRate: 75,      // 正确率(%)
        matrixStrategy: '1',  // 策略
        minValueFilter: 0     // 最小值过滤 (v1.1新增)
      }
    ]
  }
}
```

---

## API接口

### 数据格式

#### 请求参数

```javascript
{
  reportId: 'RPT001',   // 报告ID
  taskId: 'TASK001'     // 任务ID
}
```

#### 响应格式

```javascript
{
  code: 200,
  message: 'success',
  data: [
    {
      // 用例配置
      caseConfig: {
        reportId: 'RPT001',
        taskId: 'TASK001',
        caseId: 'CASE_001',
        acturalValueField: 'intent_actual',
        predictedValueField: 'intent_predicted',
        descValueField: 'intent_label',
        matrixStrategy: '1',
        minValueFilter: 0,    // v1.1新增
        createTime: '2025-12-06 10:00:00',
        updateTime: '2025-12-06 10:00:00'
      },
      
      // 详情列表
      detailList: [
        {
          corpusId: 'QA_12345',
          acturalValue: '1',
          predictedValue: '1',
          descValue: '天气查询',
          createTime: '2025-12-06 10:00:00'
        }
        // ...
      ],
      
      // 标记列表
      markList: [
        { id: '1', value: '1', desc: '天气查询' }
        // ...
      ],
      
      // 统计信息
      statistics: {
        totalCount: 200,
        validCount: 190,
        invalidCount: 10,
        correctCount: 140,
        accuracy: 73.68,
        avgPrecision: 72.5,
        avgRecall: 71.8,
        maxPrecision: 85.5,   // v1.1新增
        minPrecision: 60.2,   // v1.1新增
        maxRecall: 88.3,      // v1.1新增
        minRecall: 55.1,      // v1.1新增
        matrixMax: 5,
        minValueFilter: 0     // v1.1新增
      }
    }
  ]
}
```

---

## 安装与运行

### 环境要求

- Node.js >= 16.0
- npm >= 7.0

### 安装依赖

```bash
cd frontend
npm install
```

### 开发模式

```bash
npm run dev
```

访问 http://localhost:3000

### 生产构建

```bash
npm run build
```

构建产物在 `dist/` 目录

---

## 配置说明

### Vite配置 (vite.config.js)

```javascript
export default defineConfig({
  plugins: [vue()],
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

### 全局配置参数

| 参数 | 位置 | 默认值 | 说明 |
|------|------|--------|------|
| MOCK_ENABLED | mock/index.js | true | Mock模式开关 |
| DEFAULT_MIN_VALUE_FILTER | mockData.js | 0 | 默认最小值过滤 |
| API_BASE_URL | api/matrix.js | '/api' | 后端API地址 |

---

## 开发指南

### 添加新组件

1. 在 `src/components/` 创建组件文件
2. 使用 `<script setup>` 语法
3. 添加完整的JSDoc注释
4. 导出并在视图中使用

### 添加新API

1. 在 `src/api/matrix.js` 添加接口函数
2. 支持Mock模式和真实API两种情况
3. 添加对应的Mock数据生成逻辑

### 代码规范

- 使用 Vue 3 Composition API
- 组件命名使用 PascalCase
- Props 和 Events 需完整声明
- 函数和组件需添加JSDoc注释

---

## 版本计划

### V1.0 ✅

- [x] 混淆矩阵渲染
- [x] 双矩阵策略支持
- [x] 统计指标计算与展示
- [x] 单元格点击查看详情
- [x] 多用例Tab页支持
- [x] Mock数据调试支持

### V1.1 (当前版本) ✅

- [x] 详细指标卡片（最高/最低精准率、召回率）
- [x] 最小值过滤功能
- [x] 合计行/列点击功能
- [x] 修复精准率行显示
- [x] 需求变更文档
- [x] 实现文档

### V1.2 (规划中)

- [ ] 用例列表页面
- [ ] 用例详情列表页面（带筛选）
- [ ] 单元格点击跳转到详情页

### V2.0 (远期规划)

- [ ] 报告导出功能
- [ ] 实时数据更新
- [ ] 多维度分析
- [ ] 可视化图表

---

## 相关文档

- [需求变更记录](./docs/CHANGELOG.md)
- [实现文档](./docs/IMPLEMENTATION.md)

---

## 更新日志

### 2025-12-06 V1.1.0

- 新增详细指标卡片（最高/最低精准率、召回率）
- 新增最小值过滤功能（minValueFilter参数）
- 修复精准率行不显示问题
- 修复合计行/列无法点击问题
- 添加需求变更文档和实现文档

### 2025-12-06 V1.0.0

- 初始版本发布
- 实现核心混淆矩阵功能
- 支持完整矩阵和稀疏矩阵两种策略
- 添加Mock数据支持

---

## 联系与支持

如有问题或建议，请提交Issue或联系开发团队。
