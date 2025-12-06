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

    <!-- 主矩阵表格 -->
    <div class="matrix-table-container">
      <table class="matrix-table">
        <!-- 表头 -->
        <thead>
          <tr>
            <th class="header-label">显示说明</th>
            <th class="header-value">实际\预测</th>
            <th v-for="val in displayValues" :key="'h-' + val" class="header-predict">
              {{ val }}
            </th>
            <th class="header-sum">合计</th>
            <th class="header-recall">召回率</th>
          </tr>
        </thead>
        
        <!-- 数据行 -->
        <tbody>
          <tr v-for="(row, rowIdx) in tableData" :key="'r-' + rowIdx">
            <!-- 显示说明列 -->
            <td class="cell-label">{{ row.label }}</td>
            <!-- 实际值列 -->
            <td class="cell-value">{{ row.actualValue }}</td>
            <!-- 矩阵数据单元格 -->
            <td 
              v-for="(val, colIdx) in displayValues" 
              :key="'c-' + colIdx"
              :class="getCellClass(rowIdx, colIdx, row.cells[colIdx])"
              @click="handleCellClick(rowIdx, colIdx, row.cells[colIdx])"
            >
              {{ row.cells[colIdx] }}
            </td>
            <!-- 行合计（可点击） -->
            <td 
              class="cell-sum clickable"
              @click="handleRowSumClick(rowIdx, row.rowSum)"
            >
              {{ row.rowSum }}
            </td>
            <!-- 召回率 -->
            <td :class="['cell-recall', getMetricClass(row.recall)]">
              {{ formatPercent(row.recall) }}
            </td>
          </tr>
        </tbody>
        
        <!-- 底部统计行 -->
        <tfoot>
          <!-- 合计行 -->
          <tr class="row-sum">
            <td class="cell-label">合计</td>
            <td class="cell-value"></td>
            <td 
              v-for="(val, colIdx) in displayValues" 
              :key="'s-' + colIdx"
              class="cell-sum clickable"
              @click="handleColSumClick(colIdx, colSums[colIdx])"
            >
              {{ colSums[colIdx] }}
            </td>
            <td class="cell-sum">{{ totalCount }}</td>
            <td :class="['cell-recall', getMetricClass(totalAccuracy)]">
              {{ formatPercent(totalAccuracy) }}
            </td>
          </tr>
          <!-- 精准率行 -->
          <tr class="row-precision">
            <td class="cell-label">精准率</td>
            <td class="cell-value"></td>
            <td 
              v-for="(val, colIdx) in displayValues" 
              :key="'p-' + colIdx"
              :class="['cell-precision', getMetricClass(precisions[colIdx])]"
            >
              {{ formatPercent(precisions[colIdx]) }}
            </td>
            <td :class="['cell-precision', getMetricClass(totalAccuracy)]">
              {{ formatPercent(totalAccuracy) }}
            </td>
            <td class="cell-diagonal"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>

<script setup>
/**
 * 混淆矩阵组件
 * 
 * 功能：
 * 1. 支持两种矩阵策略：完整矩阵(策略1)和稀疏矩阵(策略2)
 * 2. 显示召回率和精准率
 * 3. 单元格点击查看详情
 * 4. 合计行/列点击查看汇总数据
 * 5. 支持最小值过滤（过滤掉小于等于指定值的数据）
 * 
 * @author AI Assistant
 * @version 1.1.0
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
  'cell-click',      // 单元格点击
  'row-sum-click',   // 行合计点击
  'col-sum-click'    // 列合计点击
])

// ==================== 计算属性 ====================

/**
 * 过滤后的有效详情数据
 * 过滤掉非数字和小于等于minValueFilter的值
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
 * 只包含大于minValueFilter的值
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
 */
const displayValues = computed(() => {
  if (props.matrixStrategy === '2') {
    // 策略2: 只显示出现过的值（已过滤负数和小值）
    return appearedValues.value
  } else {
    // 策略1: 完整正方形矩阵 (minValueFilter+1 到 最大值)
    const maxVal = props.statistics.matrixMax || 0
    const startVal = Math.max(0, props.minValueFilter + 1)
    return Array.from({ length: maxVal - startVal + 1 }, (_, i) => i + startVal)
  }
})

/**
 * 值到索引的映射
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
 */
const matrixResult = computed(() => {
  const values = displayValues.value
  const size = values.length
  // 初始化矩阵
  const mat = Array(size).fill(0).map(() => Array(size).fill(0))
  // 单元格详情映射 key: "actual_predicted"
  const cellDetails = {}
  // 行详情映射 key: rowIdx
  const rowDetails = {}
  // 列详情映射 key: colIdx
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
        
        // 存储行详情
        if (!rowDetails[rowIdx]) rowDetails[rowIdx] = []
        rowDetails[rowIdx].push(detail)
        
        // 存储列详情
        if (!colDetails[colIdx]) colDetails[colIdx] = []
        colDetails[colIdx].push(detail)
      }
    }
  })

  return { matrix: mat, cellDetails, rowDetails, colDetails }
})

/**
 * 获取显示标签
 * 优先使用markList中的desc，其次使用detailList中的descValue，最后使用默认值
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
 * 表格数据
 */
const tableData = computed(() => {
  const values = displayValues.value
  const mat = matrixResult.value.matrix
  
  return values.map((actualVal, rowIdx) => {
    const cells = mat[rowIdx]
    const rowSum = cells.reduce((a, b) => a + b, 0)
    // 召回率 = 对角线值 / 行总和
    const recall = rowSum > 0 ? (mat[rowIdx][rowIdx] / rowSum) * 100 : 0
    
    return {
      actualValue: actualVal,
      label: getLabel(actualVal),
      cells: cells,
      rowSum: rowSum,
      recall: recall,
      rowIdx: rowIdx
    }
  })
})

/**
 * 列合计
 */
const colSums = computed(() => {
  const values = displayValues.value
  const mat = matrixResult.value.matrix
  const size = values.length
  
  return values.map((_, colIdx) => {
    let sum = 0
    for (let i = 0; i < size; i++) {
      sum += mat[i][colIdx]
    }
    return sum
  })
})

/**
 * 精准率数组
 */
const precisions = computed(() => {
  const mat = matrixResult.value.matrix
  return colSums.value.map((colSum, colIdx) => {
    // 精准率 = 对角线值 / 列总和
    return colSum > 0 ? (mat[colIdx][colIdx] / colSum) * 100 : 0
  })
})

/**
 * 总数
 */
const totalCount = computed(() => {
  return colSums.value.reduce((a, b) => a + b, 0)
})

/**
 * 总准确率（=总精准率=总召回率，因为是整体对角线/总数）
 */
const totalAccuracy = computed(() => {
  const mat = matrixResult.value.matrix
  let correct = 0
  for (let i = 0; i < mat.length; i++) {
    correct += mat[i][i]
  }
  return totalCount.value > 0 ? (correct / totalCount.value) * 100 : 0
})

// ==================== 方法 ====================

/**
 * 格式化百分比
 */
const formatPercent = (value) => {
  return (Math.round(value * 100) / 100).toFixed(2) + '%'
}

/**
 * 获取单元格样式类
 */
const getCellClass = (rowIdx, colIdx, value) => {
  const classes = ['cell-data']
  if (value === 0) {
    classes.push('cell-zero')
  } else if (rowIdx === colIdx) {
    classes.push('cell-correct', 'clickable')
  } else {
    classes.push('cell-error', 'clickable')
  }
  return classes.join(' ')
}

/**
 * 获取指标颜色类
 */
const getMetricClass = (value) => {
  if (value >= 90) return 'metric-high'
  if (value >= 70) return 'metric-medium'
  return 'metric-low'
}

/**
 * 单元格点击处理
 */
const handleCellClick = (rowIdx, colIdx, value) => {
  if (value === 0) return
  
  const actualVal = displayValues.value[rowIdx]
  const predictedVal = displayValues.value[colIdx]
  const key = `${actualVal}_${predictedVal}`
  const records = matrixResult.value.cellDetails[key] || []

  emit('cell-click', {
    actual: actualVal,
    predicted: predictedVal,
    count: value,
    records: records,
    type: 'cell'
  })
}

/**
 * 行合计点击处理
 */
const handleRowSumClick = (rowIdx, count) => {
  if (count === 0) return
  
  const actualVal = displayValues.value[rowIdx]
  const records = matrixResult.value.rowDetails[rowIdx] || []

  emit('cell-click', {
    actual: actualVal,
    predicted: '全部',
    count: count,
    records: records,
    type: 'row-sum',
    title: `实际值=${actualVal} 的所有记录`
  })
}

/**
 * 列合计点击处理
 */
const handleColSumClick = (colIdx, count) => {
  if (count === 0) return
  
  const predictedVal = displayValues.value[colIdx]
  const records = matrixResult.value.colDetails[colIdx] || []

  emit('cell-click', {
    actual: '全部',
    predicted: predictedVal,
    count: count,
    records: records,
    type: 'col-sum',
    title: `预测值=${predictedVal} 的所有记录`
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

.matrix-table-container {
  overflow-x: auto;
}

/* ==================== 表格基础样式 ==================== */
.matrix-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 13px;
  min-width: 600px;
}

.matrix-table th,
.matrix-table td {
  border: 1px solid #dcdfe6;
  padding: 8px 10px;
  text-align: center;
  min-width: 60px;
}

/* ==================== 表头样式 ==================== */
.matrix-table thead th {
  background: #409EFF;
  color: white;
  font-weight: 600;
  position: sticky;
  top: 0;
  z-index: 10;
}

.header-label,
.header-value {
  background: #67C23A !important;
  position: sticky;
  left: 0;
  z-index: 15;
}

.header-label {
  min-width: 120px;
  text-align: left;
  padding-left: 12px;
}

.header-value {
  left: 120px;
  min-width: 80px;
}

.header-sum {
  background: #E6A23C !important;
}

.header-recall {
  background: #67C23A !important;
}

/* ==================== 数据行样式 ==================== */
.cell-label {
  background: #f0f9ff;
  font-weight: 600;
  text-align: left;
  padding-left: 12px;
  position: sticky;
  left: 0;
  z-index: 5;
  border-right: 2px solid #ddd;
}

.cell-value {
  background: #f0f9ff;
  font-weight: 600;
  position: sticky;
  left: 120px;
  z-index: 5;
}

/* ==================== 单元格样式 ==================== */
.cell-data {
  transition: all 0.2s;
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
  transform: scale(1.05);
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  z-index: 1;
  position: relative;
}

/* ==================== 统计列样式 ==================== */
.cell-sum {
  background: #e7f3ff;
  font-weight: bold;
}

.cell-recall,
.cell-precision {
  font-weight: bold;
}

/* ==================== 指标颜色 ==================== */
.metric-high {
  color: #2e7d32;
  background: #e8f5e9;
}

.metric-medium {
  color: #f57c00;
  background: #fff3e0;
}

.metric-low {
  color: #c62828;
  background: #ffebee;
}

/* ==================== 底部统计行 ==================== */
.row-sum td {
  background: #e7f3ff;
  font-weight: bold;
}

.row-precision td {
  background: #e8f5e9;
  font-weight: bold;
}

/* 斜线单元格 */
.cell-diagonal {
  background: #f5f5f5;
  position: relative;
  padding: 0;
  overflow: hidden;
}

.cell-diagonal::before {
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
</style>
