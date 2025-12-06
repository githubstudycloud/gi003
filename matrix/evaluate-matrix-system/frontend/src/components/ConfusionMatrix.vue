<template>
  <div class="confusion-matrix-wrapper">
    <!-- 策略说明标签 -->
    <div class="strategy-info">
      <el-tag :type="matrixStrategy === '2' ? 'success' : 'primary'" size="small">
        {{ matrixStrategy === '2' ? '稀疏矩阵模式（仅显示出现的值）' : '完整矩阵模式（正方形）' }}
      </el-tag>
      <span class="matrix-size">矩阵大小: {{ displayValues.length }} x {{ displayValues.length }}</span>
      <span v-if="minValueFilter > 0" class="filter-info">
        <el-tag type="warning" size="small">过滤值 ≤ {{ minValueFilter }}</el-tag>
      </span>
    </div>

    <!-- 主矩阵表格 - 使用 el-table -->
    <el-table
      :data="tableData"
      border
      stripe
      class="matrix-table"
      :header-cell-style="headerCellStyle"
      :cell-style="getCellStyle"
      :row-class-name="getRowClassName"
      size="small"
    >
      <!-- 固定列：显示说明 -->
      <el-table-column
        prop="label"
        label="显示说明"
        width="130"
        fixed="left"
        class-name="col-label"
        :header-cell-style="{ background: '#67C23A', color: 'white' }"
      />

      <!-- 固定列：实际值 -->
      <el-table-column
        prop="actualValue"
        label="实际\预测"
        width="90"
        fixed="left"
        align="center"
        class-name="col-actual"
        :header-cell-style="{ background: '#67C23A', color: 'white' }"
      />

      <!-- 动态列：预测值列 -->
      <el-table-column
        v-for="predictVal in displayValues"
        :key="'pred-' + predictVal"
        :prop="'pred_' + predictVal"
        :label="String(predictVal)"
        width="80"
        align="center"
        class-name="col-predict"
      >
        <template #default="{ row }">
          <div
            v-if="row.rowType === 'data'"
            :class="getDataCellClass(row.actualValue, predictVal, row['pred_' + predictVal])"
            @click="handleCellClick(row.actualValue, predictVal, row['pred_' + predictVal])"
          >
            {{ row['pred_' + predictVal] }}
          </div>
          <div
            v-else-if="row.rowType === 'sum'"
            class="sum-cell clickable"
            @click="handleColSumClick(predictVal)"
          >
            {{ row['pred_' + predictVal] }}
          </div>
          <div
            v-else-if="row.rowType === 'precision'"
            :class="getMetricClass(row['pred_' + predictVal])"
          >
            {{ formatPercent(row['pred_' + predictVal]) }}
          </div>
        </template>
      </el-table-column>

      <!-- 合计列 -->
      <el-table-column
        prop="rowSum"
        label="合计"
        width="90"
        align="center"
        class-name="col-sum"
        :header-cell-style="{ background: '#E6A23C', color: 'white' }"
      >
        <template #default="{ row }">
          <div
            v-if="row.rowType === 'data'"
            class="sum-cell clickable"
            @click="handleRowSumClick(row.actualValue)"
          >
            {{ row.rowSum }}
          </div>
          <div v-else-if="row.rowType === 'sum'" class="sum-cell total">
            {{ row.rowSum }}
          </div>
          <div
            v-else-if="row.rowType === 'precision'"
            :class="getMetricClass(totalAccuracy)"
          >
            {{ formatPercent(totalAccuracy) }}
          </div>
        </template>
      </el-table-column>

      <!-- 召回率列 -->
      <el-table-column
        prop="recall"
        label="召回率"
        width="100"
        align="center"
        class-name="col-recall"
        :header-cell-style="{ background: '#67C23A', color: 'white' }"
      >
        <template #default="{ row }">
          <div v-if="row.rowType === 'data'" :class="getMetricClass(row.recall)">
            {{ formatPercent(row.recall) }}
          </div>
          <div v-else-if="row.rowType === 'sum'" :class="getMetricClass(totalAccuracy)">
            {{ formatPercent(totalAccuracy) }}
          </div>
          <div v-else-if="row.rowType === 'precision'" class="diagonal-cell">
            <!-- 精准率行的召回率列：斜线 -->
          </div>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
/**
 * 混淆矩阵组件 - 使用 el-table 实现
 * 
 * 功能：
 * 1. 支持两种矩阵策略：完整矩阵(策略1)和稀疏矩阵(策略2)
 * 2. 显示召回率和精准率
 * 3. 单元格点击查看详情
 * 4. 合计行/列点击查看汇总数据
 * 5. 支持最小值过滤（过滤掉小于等于指定值的数据）
 * 
 * @author AI Assistant
 * @version 1.2.0
 */

import { computed } from 'vue'

// ==================== Props 定义 ====================
const props = defineProps({
  /** 详情数据列表 */
  detailList: {
    type: Array,
    default: () => []
  },
  /** 标记映射列表，用于显示说明 */
  markList: {
    type: Array,
    default: () => []
  },
  /** 统计信息 */
  statistics: {
    type: Object,
    default: () => ({})
  },
  /** 
   * 矩阵策略
   * "1" - 完整正方形矩阵（0到最大值）
   * "2" - 稀疏矩阵（只显示出现过的值）
   */
  matrixStrategy: {
    type: String,
    default: '1'
  },
  /**
   * 最小值过滤阈值
   * 只显示大于此值的分类（用于过滤负数等无效数据）
   * 默认为0，即只显示大于0的值
   */
  minValueFilter: {
    type: Number,
    default: 0
  }
})

// ==================== Events 定义 ====================
const emit = defineEmits([
  'cell-click'  // 统一的点击事件
])

// ==================== 计算属性 ====================

/**
 * 过滤后的有效详情数据
 * 
 * 计算逻辑：
 * 1. 遍历所有详情数据
 * 2. 解析 acturalValue 和 predictedValue 为整数
 * 3. 过滤条件：
 *    - 两个值都必须是有效数字（非NaN）
 *    - 两个值都必须大于 minValueFilter
 * 4. 返回满足条件的数据数组
 */
const filteredDetailList = computed(() => {
  return props.detailList.filter(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    return !isNaN(actual) && !isNaN(predicted) && 
           actual > props.minValueFilter && predicted > props.minValueFilter
  })
})

/**
 * 获取所有出现过的值（用于策略2-稀疏矩阵）
 * 
 * 计算逻辑：
 * 1. 创建一个 Set 用于存储唯一值
 * 2. 遍历过滤后的详情数据
 * 3. 提取每条记录的 acturalValue 和 predictedValue
 * 4. 只添加大于 minValueFilter 的有效数字
 * 5. 转换为数组并升序排序
 */
const appearedValues = computed(() => {
  const values = new Set()
  filteredDetailList.value.forEach(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    if (!isNaN(actual) && actual > props.minValueFilter) values.add(actual)
    if (!isNaN(predicted) && predicted > props.minValueFilter) values.add(predicted)
  })
  return Array.from(values).sort((a, b) => a - b)
})

/**
 * 根据策略确定要显示的值列表
 * 
 * 计算逻辑：
 * - 策略1（完整矩阵）：
 *   1. 获取统计信息中的最大值 matrixMax
 *   2. 起始值 = max(0, minValueFilter + 1)
 *   3. 生成从起始值到最大值的连续整数数组
 * 
 * - 策略2（稀疏矩阵）：
 *   直接使用 appearedValues，只包含实际出现过的值
 */
const displayValues = computed(() => {
  if (props.matrixStrategy === '2') {
    // 策略2: 只显示出现过的值（已过滤负数和小值）
    return appearedValues.value
  } else {
    // 策略1: 完整正方形矩阵 (minValueFilter+1 到 最大值)
    const maxVal = props.statistics.matrixMax || 0
    const startVal = Math.max(0, props.minValueFilter + 1)
    if (maxVal < startVal) return []
    return Array.from({ length: maxVal - startVal + 1 }, (_, i) => i + startVal)
  }
})

/**
 * 值到索引的映射表
 * 
 * 计算逻辑：
 * 创建一个对象，key为显示值，value为该值在displayValues中的索引
 * 用于快速查找某个值对应的矩阵位置
 */
const valueToIndex = computed(() => {
  const map = {}
  displayValues.value.forEach((val, idx) => {
    map[val] = idx
  })
  return map
})

/**
 * 构建矩阵数据和详情映射
 * 
 * 计算逻辑：
 * 1. 初始化一个 size x size 的二维数组（全0）
 * 2. 初始化三个详情映射对象：
 *    - cellDetails: 存储每个单元格的详细记录
 *    - rowDetails: 存储每行的所有记录
 *    - colDetails: 存储每列的所有记录
 * 3. 遍历过滤后的详情数据：
 *    a. 解析实际值和预测值
 *    b. 查找对应的行列索引
 *    c. 矩阵计数 +1
 *    d. 将记录添加到对应的详情映射中
 * 4. 返回矩阵数据和详情映射
 */
const matrixResult = computed(() => {
  const values = displayValues.value
  const size = values.length
  // 初始化矩阵
  const mat = Array(size).fill(0).map(() => Array(size).fill(0))
  // 单元格详情映射 key: "actual_predicted"
  const cellDetails = {}
  // 行详情映射 key: actualValue
  const rowDetails = {}
  // 列详情映射 key: predictedValue
  const colDetails = {}

  filteredDetailList.value.forEach(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    
    if (!isNaN(actual) && !isNaN(predicted)) {
      const rowIdx = valueToIndex.value[actual]
      const colIdx = valueToIndex.value[predicted]
      
      if (rowIdx !== undefined && colIdx !== undefined) {
        mat[rowIdx][colIdx]++
        
        // 存储单元格详情
        const cellKey = `${actual}_${predicted}`
        if (!cellDetails[cellKey]) cellDetails[cellKey] = []
        cellDetails[cellKey].push(detail)
        
        // 存储行详情（按实际值）
        if (!rowDetails[actual]) rowDetails[actual] = []
        rowDetails[actual].push(detail)
        
        // 存储列详情（按预测值）
        if (!colDetails[predicted]) colDetails[predicted] = []
        colDetails[predicted].push(detail)
      }
    }
  })

  return { matrix: mat, cellDetails, rowDetails, colDetails }
})

/**
 * 获取显示标签
 * 
 * 查找顺序：
 * 1. 从 markList 中查找匹配的 value 或 id
 * 2. 从 detailList 中查找该实际值对应的 descValue
 * 3. 返回默认值 "值{value}"
 */
const getLabel = (value) => {
  // 1. 先从markList查找
  const mark = props.markList.find(m => String(m.value) === String(value) || String(m.id) === String(value))
  if (mark && mark.desc) return mark.desc
  
  // 2. 从detailList中查找该值对应的descValue
  const detail = props.detailList.find(d => String(d.acturalValue) === String(value))
  if (detail && detail.descValue && detail.descValue !== '无效数据') return detail.descValue
  
  // 3. 返回默认值
  return `值${value}`
}

/**
 * 列合计数组
 * 
 * 计算逻辑：
 * 对每一列，求该列所有行的数值之和
 * colSums[colIdx] = sum(matrix[0][colIdx], matrix[1][colIdx], ..., matrix[n][colIdx])
 */
const colSums = computed(() => {
  const mat = matrixResult.value.matrix
  const size = displayValues.value.length
  
  return displayValues.value.map((_, colIdx) => {
    let sum = 0
    for (let i = 0; i < size; i++) {
      sum += mat[i][colIdx]
    }
    return sum
  })
})

/**
 * 精准率数组
 * 
 * 计算公式：精准率[i] = 对角线值[i] / 列合计[i] * 100
 * - 对角线值：matrix[i][i]，即实际值=预测值的数量
 * - 列合计：该预测值的总预测次数
 * - 如果列合计为0，精准率为0（避免除零错误）
 */
const precisions = computed(() => {
  const mat = matrixResult.value.matrix
  return colSums.value.map((colSum, colIdx) => {
    return colSum > 0 ? (mat[colIdx][colIdx] / colSum) * 100 : 0
  })
})

/**
 * 总数（有效样本数）
 * 
 * 计算逻辑：所有列合计之和
 */
const totalCount = computed(() => {
  return colSums.value.reduce((a, b) => a + b, 0)
})

/**
 * 总准确率
 * 
 * 计算公式：准确率 = 对角线元素之和 / 总数 * 100
 * - 对角线元素：所有 matrix[i][i] 的和，即预测正确的总数
 * - 总数：所有样本数
 */
const totalAccuracy = computed(() => {
  const mat = matrixResult.value.matrix
  let correct = 0
  for (let i = 0; i < mat.length; i++) {
    correct += mat[i][i]
  }
  return totalCount.value > 0 ? (correct / totalCount.value) * 100 : 0
})

/**
 * 表格数据（el-table 需要的格式）
 * 
 * 构建逻辑：
 * 1. 数据行：每行对应一个实际值
 *    - rowType: 'data'
 *    - label: 显示说明
 *    - actualValue: 实际值
 *    - pred_X: 预测值为X时的计数
 *    - rowSum: 行合计 = 该实际值的总数
 *    - recall: 召回率 = 对角线值 / 行合计 * 100
 * 
 * 2. 合计行：
 *    - rowType: 'sum'
 *    - label: '合计'
 *    - pred_X: 列合计
 *    - rowSum: 总数
 * 
 * 3. 精准率行：
 *    - rowType: 'precision'
 *    - label: '精准率'
 *    - pred_X: 该列的精准率
 */
const tableData = computed(() => {
  const values = displayValues.value
  const mat = matrixResult.value.matrix
  const rows = []

  // 1. 数据行
  values.forEach((actualVal, rowIdx) => {
    const row = {
      rowType: 'data',
      label: getLabel(actualVal),
      actualValue: actualVal,
      rowSum: 0,
      recall: 0,
      rowIdx: rowIdx
    }
    
    // 添加每个预测值列的数据
    let rowSum = 0
    values.forEach((predictVal, colIdx) => {
      const count = mat[rowIdx][colIdx]
      row['pred_' + predictVal] = count
      rowSum += count
    })
    
    row.rowSum = rowSum
    // 召回率 = 对角线值 / 行总和
    row.recall = rowSum > 0 ? (mat[rowIdx][rowIdx] / rowSum) * 100 : 0
    
    rows.push(row)
  })

  // 2. 合计行
  const sumRow = {
    rowType: 'sum',
    label: '合计',
    actualValue: '',
    rowSum: totalCount.value,
    recall: totalAccuracy.value
  }
  values.forEach((predictVal, colIdx) => {
    sumRow['pred_' + predictVal] = colSums.value[colIdx]
  })
  rows.push(sumRow)

  // 3. 精准率行
  const precisionRow = {
    rowType: 'precision',
    label: '精准率',
    actualValue: '',
    rowSum: totalAccuracy.value,
    recall: null
  }
  values.forEach((predictVal, colIdx) => {
    precisionRow['pred_' + predictVal] = precisions.value[colIdx]
  })
  rows.push(precisionRow)

  return rows
})

// ==================== 样式方法 ====================

/** 表头单元格样式 */
const headerCellStyle = {
  background: '#409EFF',
  color: 'white',
  fontWeight: 'bold',
  textAlign: 'center'
}

/**
 * 获取单元格样式
 */
const getCellStyle = ({ row, column }) => {
  // 合计行背景
  if (row.rowType === 'sum') {
    return { background: '#e7f3ff', fontWeight: 'bold' }
  }
  // 精准率行背景
  if (row.rowType === 'precision') {
    return { background: '#e8f5e9', fontWeight: 'bold' }
  }
  return {}
}

/**
 * 获取行类名
 */
const getRowClassName = ({ row }) => {
  if (row.rowType === 'sum') return 'row-sum'
  if (row.rowType === 'precision') return 'row-precision'
  return ''
}

/**
 * 获取数据单元格类名
 * 
 * 逻辑：
 * - 值为0：灰色背景
 * - 对角线（实际=预测）：绿色背景，可点击
 * - 非对角线：黄色背景，可点击
 */
const getDataCellClass = (actualVal, predictVal, value) => {
  const classes = ['data-cell']
  if (value === 0) {
    classes.push('cell-zero')
  } else if (actualVal === predictVal) {
    classes.push('cell-correct', 'clickable')
  } else {
    classes.push('cell-error', 'clickable')
  }
  return classes.join(' ')
}

/**
 * 获取指标颜色类
 * 
 * 逻辑：
 * - >= 90%：绿色（高）
 * - >= 70%：橙色（中）
 * - < 70%：红色（低）
 */
const getMetricClass = (value) => {
  if (value >= 90) return 'metric-high'
  if (value >= 70) return 'metric-medium'
  return 'metric-low'
}

// ==================== 格式化方法 ====================

/**
 * 格式化百分比
 * @param {number} value - 百分比值
 * @returns {string} 格式化后的字符串，如 "85.50%"
 */
const formatPercent = (value) => {
  if (value === null || value === undefined) return '-'
  return (Math.round(value * 100) / 100).toFixed(2) + '%'
}

// ==================== 事件处理 ====================

/**
 * 单元格点击处理
 */
const handleCellClick = (actualVal, predictVal, value) => {
  if (value === 0) return
  
  const key = `${actualVal}_${predictVal}`
  const records = matrixResult.value.cellDetails[key] || []

  emit('cell-click', {
    actual: actualVal,
    predicted: predictVal,
    count: value,
    records: records,
    type: 'cell'
  })
}

/**
 * 行合计点击处理
 */
const handleRowSumClick = (actualVal) => {
  const records = matrixResult.value.rowDetails[actualVal] || []
  if (records.length === 0) return

  emit('cell-click', {
    actual: actualVal,
    predicted: '全部',
    count: records.length,
    records: records,
    type: 'row-sum',
    title: `实际值=${actualVal} 的所有记录`
  })
}

/**
 * 列合计点击处理
 */
const handleColSumClick = (predictVal) => {
  const records = matrixResult.value.colDetails[predictVal] || []
  if (records.length === 0) return

  emit('cell-click', {
    actual: '全部',
    predicted: predictVal,
    count: records.length,
    records: records,
    type: 'col-sum',
    title: `预测值=${predictVal} 的所有记录`
  })
}
</script>

<style scoped>
/* ==================== 容器样式 ==================== */
.confusion-matrix-wrapper {
  overflow-x: auto;
}

.strategy-info {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
  padding: 8px 12px;
  background: #f5f7fa;
  border-radius: 4px;
}

.matrix-size {
  font-size: 13px;
  color: #606266;
}

.filter-info {
  margin-left: auto;
}

/* ==================== el-table 样式覆盖 ==================== */
.matrix-table {
  width: 100%;
  font-size: 13px;
}

/* 固定列样式 */
:deep(.col-label) {
  background: #f0f9ff !important;
  font-weight: 600;
}

:deep(.col-actual) {
  background: #f0f9ff !important;
  font-weight: 600;
}

:deep(.col-sum) {
  background: #e7f3ff !important;
}

:deep(.col-recall) {
  background: #e8f5e9 !important;
}

/* ==================== 数据单元格样式 ==================== */
.data-cell {
  padding: 4px 8px;
  border-radius: 3px;
  transition: all 0.2s;
  display: inline-block;
  min-width: 40px;
}

.cell-zero {
  background: #f8f9fa;
  color: #aaa;
}

.cell-correct {
  background: #d4edda;
  color: #155724;
  font-weight: bold;
}

.cell-error {
  background: #fff3cd;
  color: #856404;
}

.clickable {
  cursor: pointer;
}

.clickable:hover {
  transform: scale(1.1);
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  z-index: 1;
  position: relative;
}

/* ==================== 合计单元格样式 ==================== */
.sum-cell {
  font-weight: bold;
  color: #409EFF;
  padding: 4px 8px;
  border-radius: 3px;
}

.sum-cell.clickable:hover {
  background: #409EFF;
  color: white;
  cursor: pointer;
}

.sum-cell.total {
  color: #E6A23C;
  font-size: 14px;
}

/* ==================== 指标颜色样式 ==================== */
.metric-high {
  color: #2e7d32;
  background: #e8f5e9;
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
}

.metric-medium {
  color: #f57c00;
  background: #fff3e0;
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
}

.metric-low {
  color: #c62828;
  background: #ffebee;
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
}

/* ==================== 斜线单元格 ==================== */
.diagonal-cell {
  position: relative;
  min-width: 60px;
  min-height: 30px;
  background: #f5f5f5;
}

.diagonal-cell::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(
    to top right,
    transparent 0%,
    transparent calc(50% - 0.5px),
    #999 50%,
    transparent calc(50% + 0.5px),
    transparent 100%
  );
}

/* ==================== 行样式 ==================== */
:deep(.row-sum) {
  background: #e7f3ff !important;
}

:deep(.row-sum td) {
  background: #e7f3ff !important;
  font-weight: bold;
}

:deep(.row-precision) {
  background: #e8f5e9 !important;
}

:deep(.row-precision td) {
  background: #e8f5e9 !important;
  font-weight: bold;
}
</style>
