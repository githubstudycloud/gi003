# 矩阵最大值限制功能说明 (maxDisplayValue)

## 功能概述

为防止矩阵过大导致页面渲染性能问题，系统引入了 `maxDisplayValue` 参数，用于限制混淆矩阵的最大显示范围。

**默认值**: `50`

## 限制规则

### 完整矩阵 (策略1)

| 项目 | 说明 |
|-----|------|
| 值范围 | `0 ~ min(maxValue, maxDisplayValue)` |
| 矩阵大小 | 最大 `51 × 51` (包含0-50共51个值) |
| 超限处理 | 实际值或预测值 > 50 的数据被视为**无效数据** |

**示例**：
- 数据最大值为 100 → 矩阵显示 0-50，共 51×51
- 值为 51-100 的记录被过滤，计入无效数据

### 稀疏矩阵 (策略2)

| 项目 | 说明 |
|-----|------|
| 值范围 | 数据中出现的值，按从小到大排序后取前 50 个 |
| 矩阵大小 | 最大 `50 × 50` |
| 超限处理 | 第 51 个及之后的分类值被**截断**，相关数据被过滤 |

**示例**：
- 数据中出现 80 个不同的分类值 [1, 3, 5, 7, ..., 159]
- 矩阵只显示前 50 个值 [1, 3, 5, ..., 99]
- 包含值 101-159 的记录被过滤

## 代码实现

### 1. 核心常量 (matrixCalculator.js)

```javascript
/**
 * 默认最大显示值限制
 * 完整矩阵模式下，值范围为 0 ~ maxDisplayValue
 * 稀疏矩阵模式下，取前 maxDisplayValue 个有值的分类
 */
export const DEFAULT_MAX_DISPLAY_VALUE = 50
```

### 2. 数据过滤函数

```javascript
/**
 * 过滤详情数据
 * @returns {Object} { filtered: 过滤后的数据, exceedCount: 超出最大值被过滤的数量 }
 */
export const filterDetailList = (detailList, minValueFilter = -1, maxDisplayValue = 50) => {
  let exceedCount = 0

  const filtered = detailList.filter(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)

    // 检查是否超出最大显示值限制
    if (actual > maxDisplayValue || predicted > maxDisplayValue) {
      exceedCount++
      return false
    }

    return true
  })

  return { filtered, exceedCount }
}
```

### 3. 显示值列表生成

```javascript
/**
 * 获取显示值列表
 * @returns {Object} { values: 显示值列表, truncatedCount: 被截断的值数量 }
 */
export const getDisplayValues = (filteredList, matrixMax, matrixStrategy, minValueFilter, maxDisplayValue) => {
  let values = []
  let truncatedCount = 0

  if (matrixStrategy === '2') {
    // 稀疏矩阵：取前 maxDisplayValue 个值
    const allValues = [...uniqueValues].sort((a, b) => a - b)
    if (allValues.length > maxDisplayValue) {
      values = allValues.slice(0, maxDisplayValue)
      truncatedCount = allValues.length - maxDisplayValue
    }
  } else {
    // 完整矩阵：限制最大值
    const endVal = Math.min(matrixMax, maxDisplayValue)
    // 生成 0 ~ endVal 的连续值
  }

  return { values, truncatedCount }
}
```

### 4. 组件属性 (ConfusionMatrix.vue)

```javascript
const props = defineProps({
  /**
   * 最大显示值限制
   * 完整矩阵：值范围为 0 ~ maxDisplayValue
   * 稀疏矩阵：取前 maxDisplayValue 个有值的分类
   * 默认值50，超出的数据将被视为无效数据
   */
  maxDisplayValue: {
    type: Number,
    default: DEFAULT_MAX_DISPLAY_VALUE
  }
})
```

## UI 显示

### 策略信息栏

正常情况：
```
[完整矩阵] 大小: 6 × 6  最大值: 5  限制: ≤ 50
```

超限情况：
```
[完整矩阵] 大小: 51 × 51  最大值: 100  限制: ≤ 50  [1000条超限]
```

截断情况（稀疏矩阵）：
```
[稀疏矩阵] 大小: 50 × 50  最大值: 200  限制: ≤ 50  [30类截断]
```

### 计算说明折叠面板

在"📊 指标计算说明"折叠面板中，新增"🔢 矩阵大小限制"章节：

```
🔢 矩阵大小限制

• 最大显示值：50（数据中超出此值的记录将被视为无效数据）
• 完整矩阵：显示 0 ~ 50 的连续分类（原始最大值 100，已截断）
• ⚠️ 共有 1000 条数据因超出最大值限制被过滤
```

## 测试场景

### RPT013 - 超大规模数据（测试最大值限制）

```javascript
{
  id: 'RPT013',
  name: '超大规模数据（测试最大值限制）',
  desc: '100个分类，测试完整矩阵截断为50的效果',
  config: {
    caseConfigs: [{
      caseId: 'CASE_LARGE_FULL',
      detailCount: 2000,
      maxValue: 100,  // 超过50的最大值
      matrixStrategy: '1'
    }]
  }
}
```

**预期结果**：
- 矩阵大小: 51 × 51 (0-50)
- 显示警告: "XX条超限"

### RPT014 - 稀疏矩阵超大规模（测试前50截断）

```javascript
{
  id: 'RPT014',
  name: '稀疏矩阵超大规模（测试前50截断）',
  desc: '80个不连续分类，测试稀疏矩阵取前50个的效果',
  config: {
    caseConfigs: [{
      caseId: 'CASE_LARGE_SPARSE',
      detailCount: 1500,
      maxValue: 200,
      matrixStrategy: '2',
      validValues: Array.from({ length: 80 }, (_, i) => i * 2 + 1)  // 1, 3, 5, ..., 159
    }]
  }
}
```

**预期结果**：
- 矩阵大小: 50 × 50 (前50个奇数: 1, 3, 5, ..., 99)
- 显示警告: "30类截断"

## 自定义配置

如需修改默认最大值，可在调用组件时传入 `maxDisplayValue` 属性：

```vue
<ConfusionMatrix
  :detail-list="detailList"
  :max-display-value="100"
/>
```

或修改常量默认值：

```javascript
// src/utils/matrixCalculator.js
export const DEFAULT_MAX_DISPLAY_VALUE = 100  // 改为100
```

## 版本历史

| 版本 | 日期 | 说明 |
|-----|------|------|
| 1.5.0 | 2025-12-12 | 新增 maxDisplayValue 功能 |

---

*文档生成日期: 2025-12-12*
