<template>
  <div class="confusion-matrix-wrapper">
    <!-- 调试信息面板（开发模式显示） -->
    <div v-if="showDebug" class="debug-panel">
      <div class="debug-header">
        <span>🔧 数据调试面板</span>
        <el-button size="small" @click="printDebugInfo">打印到控制台</el-button>
      </div>
      <el-collapse>
        <el-collapse-item title="1. 输入参数 (Props)" name="props">
          <pre>{{ debugInfo.props }}</pre>
        </el-collapse-item>
        <el-collapse-item title="2. 计算后的矩阵最大值" name="matrixMax">
          <pre>{{ debugInfo.matrixMax }}</pre>
        </el-collapse-item>
        <el-collapse-item title="3. 显示值列表 (displayValues)" name="displayValues">
          <pre>{{ debugInfo.displayValues }}</pre>
        </el-collapse-item>
        <el-collapse-item title="4. 过滤后的详情数据 (前5条)" name="filteredList">
          <pre>{{ debugInfo.filteredListSample }}</pre>
        </el-collapse-item>
        <el-collapse-item title="5. 矩阵数据 (matrix)" name="matrix">
          <pre>{{ debugInfo.matrix }}</pre>
        </el-collapse-item>
        <el-collapse-item title="6. 表格数据 (tableData)" name="tableData">
          <pre>{{ debugInfo.tableData }}</pre>
        </el-collapse-item>
      </el-collapse>
    </div>

    <!-- 策略说明标签 -->
    <div class="strategy-info">
      <el-tag :type="matrixStrategy === '2' ? 'success' : 'primary'" size="small">
        {{ matrixStrategy === '2' ? '稀疏矩阵模式（仅显示出现的值）' : '完整矩阵模式（正方形）' }}
      </el-tag>
      <span class="matrix-size">矩阵大小: {{ displayValues.length }} x {{ displayValues.length }}</span>
      <span class="matrix-max-info">最大值: {{ calculatedMatrixMax }}</span>
      <span v-if="minValueFilter > 0" class="filter-info">
        <el-tag type="warning" size="small">过滤值 ≤ {{ minValueFilter }}</el-tag>
      </span>
      <el-switch
        v-model="showDebug"
        active-text="调试"
        inactive-text=""
        size="small"
        style="margin-left: auto;"
      />
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
 * ============================================================================
 * 混淆矩阵组件 (ConfusionMatrix.vue)
 * ============================================================================
 * 
 * 【组件功能】
 * 1. 接收后端返回的详情数据列表，渲染成混淆矩阵表格
 * 2. 支持两种矩阵策略：完整矩阵(策略1)和稀疏矩阵(策略2)
 * 3. 自动计算矩阵最大值（从数据中取实际值和预测值的最大值）
 * 4. 显示召回率和精准率
 * 5. 单元格点击查看详情
 * 
 * 【数据流向】
 * 后端API → MatrixReport.vue → ConfusionMatrix.vue（本组件）
 * 
 * 【Props 参数说明】
 * @prop {Array}  detailList     - 详情数据列表，每条记录包含 acturalValue, predictedValue 等
 * @prop {Array}  markList       - 标记映射列表，用于将数值转换为显示名称
 * @prop {Object} statistics     - 统计信息（可选，用于传递预计算的统计值）
 * @prop {String} matrixStrategy - 矩阵策略 "1"=完整矩阵 "2"=稀疏矩阵
 * @prop {Number} minValueFilter - 最小值过滤阈值，只显示大于此值的分类
 * 
 * @author AI Assistant
 * @version 1.3.0
 * ============================================================================
 */

import { ref, computed, watch } from 'vue'

// ============================================================================
// Props 定义 - 【后端需要关注的数据格式】
// ============================================================================
const props = defineProps({
  /**
   * 【重要】详情数据列表 - 后端返回的核心数据
   * 
   * 数据格式示例:
   * [
   *   {
   *     "corpusId": "QA_12345",       // 语料ID（唯一标识）
   *     "acturalValue": "1",          // 实际值（字符串类型的数字）
   *     "predictedValue": "1",        // 预测值（字符串类型的数字）
   *     "descValue": "天气查询",      // 描述值（可选，用于显示说明）
   *     "createTime": "2025-12-06"    // 创建时间
   *   },
   *   ...
   * ]
   * 
   * 注意: acturalValue 和 predictedValue 必须是可以转换为整数的字符串
   */
  detailList: {
    type: Array,
    default: () => []
  },

  /**
   * 【可选】标记映射列表 - 用于将数值转换为可读的显示名称
   * 
   * 数据格式示例:
   * [
   *   { "id": "1", "value": "1", "desc": "天气查询" },
   *   { "id": "2", "value": "2", "desc": "知识问答" },
   *   ...
   * ]
   * 
   * 取值逻辑（优先级从高到低）:
   * 1. 从 markList 中匹配 value 或 id
   * 2. 从 detailList 中查找对应的 descValue
   * 3. 返回默认值 "值{数字}"
   */
  markList: {
    type: Array,
    default: () => []
  },

  /**
   * 【可选】统计信息 - 预计算的统计数据
   * 
   * 数据格式示例:
   * {
   *   "totalCount": 200,      // 总样本数
   *   "validCount": 190,      // 有效样本数
   *   "correctCount": 150,    // 预测正确数
   *   "accuracy": 78.95,      // 准确率
   *   "matrixMax": 5          // 【已废弃】现在从数据自动计算
   * }
   * 
   * 注意: matrixMax 现在会从 detailList 中自动计算，不再需要后端传递
   */
  statistics: {
    type: Object,
    default: () => ({})
  },

  /**
   * 矩阵策略
   * "1" - 完整正方形矩阵：显示从 minValueFilter+1 到 最大值 的所有分类
   * "2" - 稀疏矩阵：只显示数据中实际出现过的分类值
   */
  matrixStrategy: {
    type: String,
    default: '1'
  },

  /**
   * 最小值过滤阈值
   * 只显示大于此值的分类（用于过滤负数、0等无效数据）
   * 默认为0，即只显示 > 0 的值（1, 2, 3...）
   */
  minValueFilter: {
    type: Number,
    default: 0
  }
})

// ============================================================================
// Events 定义
// ============================================================================
const emit = defineEmits([
  'cell-click'  // 单元格点击事件，传递点击的单元格详情
])

// ============================================================================
// 响应式状态
// ============================================================================

/** 是否显示调试面板 */
const showDebug = ref(false)

// ============================================================================
// 核心计算属性
// ============================================================================

/**
 * 【核心】从数据中自动计算矩阵最大值
 * 
 * 计算逻辑:
 * 1. 遍历所有详情数据
 * 2. 解析每条记录的 acturalValue 和 predictedValue
 * 3. 找出所有有效数值中的最大值
 * 4. 这个最大值决定了完整矩阵的大小
 * 
 * 例如: 如果数据中最大的实际值是4，最大的预测值是5，则 matrixMax = 5
 */
const calculatedMatrixMax = computed(() => {
  let maxVal = 0
  
  props.detailList.forEach(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    
    if (!isNaN(actual) && actual > maxVal) {
      maxVal = actual
    }
    if (!isNaN(predicted) && predicted > maxVal) {
      maxVal = predicted
    }
  })
  
  // 如果统计信息中有 matrixMax 且更大，使用它（向后兼容）
  if (props.statistics.matrixMax && props.statistics.matrixMax > maxVal) {
    maxVal = props.statistics.matrixMax
  }
  
  return maxVal
})

/**
 * 过滤后的有效详情数据
 * 
 * 过滤条件:
 * 1. acturalValue 必须是有效数字
 * 2. predictedValue 必须是有效数字
 * 3. 两个值都必须 > minValueFilter
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
 * 【核心】根据策略确定要显示的值列表
 * 
 * 这个列表决定了矩阵的行和列标题
 * 
 * 策略1（完整矩阵）: [minValueFilter+1, minValueFilter+2, ..., calculatedMatrixMax]
 * 策略2（稀疏矩阵）: 只包含数据中实际出现过的值
 */
const displayValues = computed(() => {
  if (props.matrixStrategy === '2') {
    // 策略2: 只显示出现过的值
    return appearedValues.value
  } else {
    // 策略1: 完整正方形矩阵
    // 【修复】使用计算出的最大值，而不是 statistics 中的固定值
    const maxVal = calculatedMatrixMax.value
    const startVal = Math.max(1, props.minValueFilter + 1) // 至少从1开始
    if (maxVal < startVal) return []
    return Array.from({ length: maxVal - startVal + 1 }, (_, i) => i + startVal)
  }
})

/**
 * 值到索引的映射表
 */
const valueToIndex = computed(() => {
  const map = {}
  displayValues.value.forEach((val, idx) => {
    map[val] = idx
  })
  return map
})

/**
 * 【核心】构建矩阵数据和详情映射
 * 
 * 返回:
 * - matrix: 二维数组，matrix[行][列] = 计数
 * - cellDetails: 每个单元格对应的详细记录
 * - rowDetails: 每行对应的所有记录
 * - colDetails: 每列对应的所有记录
 */
const matrixResult = computed(() => {
  const values = displayValues.value
  const size = values.length
  
  // 初始化矩阵（全0）
  const mat = Array(size).fill(0).map(() => Array(size).fill(0))
  
  // 详情映射
  const cellDetails = {}  // key: "actual_predicted"
  const rowDetails = {}   // key: actualValue
  const colDetails = {}   // key: predictedValue

  filteredDetailList.value.forEach(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    
    if (!isNaN(actual) && !isNaN(predicted)) {
      const rowIdx = valueToIndex.value[actual]
      const colIdx = valueToIndex.value[predicted]
      
      if (rowIdx !== undefined && colIdx !== undefined) {
        // 矩阵计数 +1
        mat[rowIdx][colIdx]++
        
        // 存储单元格详情
        const cellKey = `${actual}_${predicted}`
        if (!cellDetails[cellKey]) cellDetails[cellKey] = []
        cellDetails[cellKey].push(detail)
        
        // 存储行详情
        if (!rowDetails[actual]) rowDetails[actual] = []
        rowDetails[actual].push(detail)
        
        // 存储列详情
        if (!colDetails[predicted]) colDetails[predicted] = []
        colDetails[predicted].push(detail)
      }
    }
  })

  return { matrix: mat, cellDetails, rowDetails, colDetails }
})

/**
 * 【标签取值逻辑】获取显示标签
 * 
 * 优先级:
 * 1. markList 中匹配 value 或 id → 返回 desc
 * 2. detailList 中找到对应 acturalValue → 返回 descValue
 * 3. 返回默认值 "值{数字}"
 */
const getLabel = (value) => {
  // 1. 从 markList 查找
  const mark = props.markList.find(m => 
    String(m.value) === String(value) || String(m.id) === String(value)
  )
  if (mark && mark.desc) return mark.desc
  
  // 2. 从 detailList 查找
  const detail = props.detailList.find(d => String(d.acturalValue) === String(value))
  if (detail && detail.descValue && detail.descValue !== '无效数据') return detail.descValue
  
  // 3. 返回默认值
  return `值${value}`
}

/**
 * 列合计数组
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
 * 精准率 = 对角线值 / 列合计 × 100%
 */
const precisions = computed(() => {
  const mat = matrixResult.value.matrix
  return colSums.value.map((colSum, colIdx) => {
    return colSum > 0 ? (mat[colIdx][colIdx] / colSum) * 100 : 0
  })
})

/**
 * 总数（有效样本数）
 */
const totalCount = computed(() => {
  return colSums.value.reduce((a, b) => a + b, 0)
})

/**
 * 总准确率 = 对角线之和 / 总数 × 100%
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
 * 【核心】表格数据（el-table 需要的格式）
 * 
 * 数据结构:
 * [
 *   { rowType: 'data', label: '天气查询', actualValue: 1, pred_1: 50, pred_2: 5, ..., rowSum: 60, recall: 83.33 },
 *   { rowType: 'data', label: '知识问答', actualValue: 2, pred_1: 3, pred_2: 40, ..., rowSum: 50, recall: 80.00 },
 *   ...
 *   { rowType: 'sum', label: '合计', pred_1: 55, pred_2: 48, ..., rowSum: 200 },
 *   { rowType: 'precision', label: '精准率', pred_1: 90.91, pred_2: 83.33, ... }
 * ]
 */
const tableData = computed(() => {
  const values = displayValues.value
  const mat = matrixResult.value.matrix
  const rows = []

  // 1. 数据行（每行对应一个实际值）
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

// ============================================================================
// 调试信息
// ============================================================================

/**
 * 调试信息对象（用于开发调试）
 */
const debugInfo = computed(() => ({
  props: {
    detailListCount: props.detailList.length,
    markListCount: props.markList.length,
    matrixStrategy: props.matrixStrategy,
    minValueFilter: props.minValueFilter,
    statisticsFromProps: props.statistics
  },
  matrixMax: {
    calculatedFromData: calculatedMatrixMax.value,
    fromStatistics: props.statistics.matrixMax,
    used: calculatedMatrixMax.value
  },
  displayValues: displayValues.value,
  filteredListSample: filteredDetailList.value.slice(0, 5),
  matrix: matrixResult.value.matrix,
  tableData: tableData.value.map(row => ({
    rowType: row.rowType,
    label: row.label,
    actualValue: row.actualValue,
    rowSum: row.rowSum,
    recall: row.recall
  }))
}))

/**
 * 打印调试信息到控制台
 */
const printDebugInfo = () => {
  console.group('🔧 ConfusionMatrix 调试信息')
  
  console.group('1. 输入参数 (Props)')
  console.log('detailList 数量:', props.detailList.length)
  console.log('detailList 示例 (前3条):', props.detailList.slice(0, 3))
  console.log('markList:', props.markList)
  console.log('statistics:', props.statistics)
  console.log('matrixStrategy:', props.matrixStrategy)
  console.log('minValueFilter:', props.minValueFilter)
  console.groupEnd()
  
  console.group('2. 矩阵最大值计算')
  console.log('从数据计算的最大值:', calculatedMatrixMax.value)
  console.log('从statistics传入的值:', props.statistics.matrixMax)
  console.log('实际使用的值:', calculatedMatrixMax.value)
  console.groupEnd()
  
  console.group('3. 显示值列表')
  console.log('displayValues:', displayValues.value)
  console.log('矩阵大小:', displayValues.value.length, 'x', displayValues.value.length)
  console.groupEnd()
  
  console.group('4. 过滤后的数据')
  console.log('过滤前数量:', props.detailList.length)
  console.log('过滤后数量:', filteredDetailList.value.length)
  console.log('被过滤掉的数量:', props.detailList.length - filteredDetailList.value.length)
  console.groupEnd()
  
  console.group('5. 矩阵数据')
  console.table(matrixResult.value.matrix)
  console.groupEnd()
  
  console.group('6. 表格数据')
  console.table(tableData.value)
  console.groupEnd()
  
  console.group('7. 标签映射示例')
  displayValues.value.slice(0, 5).forEach(val => {
    console.log(`值 ${val} → 标签: ${getLabel(val)}`)
  })
  console.groupEnd()
  
  console.groupEnd()
}

// 监听数据变化，自动打印日志（开发环境）
watch(() => props.detailList, (newVal) => {
  if (showDebug.value && newVal.length > 0) {
    console.log('📊 detailList 数据更新:', newVal.length, '条')
  }
}, { deep: true })

// ============================================================================
// 样式方法
// ============================================================================

const headerCellStyle = {
  background: '#409EFF',
  color: 'white',
  fontWeight: 'bold',
  textAlign: 'center'
}

const getCellStyle = ({ row }) => {
  if (row.rowType === 'sum') {
    return { background: '#e7f3ff', fontWeight: 'bold' }
  }
  if (row.rowType === 'precision') {
    return { background: '#e8f5e9', fontWeight: 'bold' }
  }
  return {}
}

const getRowClassName = ({ row }) => {
  if (row.rowType === 'sum') return 'row-sum'
  if (row.rowType === 'precision') return 'row-precision'
  return ''
}

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

const getMetricClass = (value) => {
  if (value >= 90) return 'metric-high'
  if (value >= 70) return 'metric-medium'
  return 'metric-low'
}

// ============================================================================
// 格式化方法
// ============================================================================

const formatPercent = (value) => {
  if (value === null || value === undefined) return '-'
  return (Math.round(value * 100) / 100).toFixed(2) + '%'
}

// ============================================================================
// 事件处理
// ============================================================================

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
/* ==================== 调试面板样式 ==================== */
.debug-panel {
  margin-bottom: 16px;
  padding: 12px;
  background: #fef0f0;
  border: 1px solid #fab6b6;
  border-radius: 4px;
  font-size: 12px;
}

.debug-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
  font-weight: bold;
  color: #f56c6c;
}

.debug-panel pre {
  background: #fff;
  padding: 8px;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 11px;
  max-height: 200px;
}

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

.matrix-size,
.matrix-max-info {
  font-size: 13px;
  color: #606266;
}

.filter-info {
  margin-left: 8px;
}

/* ==================== el-table 样式覆盖 ==================== */
.matrix-table {
  width: 100%;
  font-size: 13px;
}

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
