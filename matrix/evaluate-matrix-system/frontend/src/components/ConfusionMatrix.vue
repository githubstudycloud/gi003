<template>
  <div class="confusion-matrix-wrapper">
    <!-- ================================================================
         调试信息面板
         开启后显示所有计算过程和中间数据，便于排查问题
         ================================================================ -->
    <div v-if="showDebug" class="debug-panel">
      <div class="debug-header">
        <span>🔧 数据调试面板（开发模式）</span>
        <div>
          <el-button size="small" type="primary" @click="printDebugInfo">打印到控制台</el-button>
          <el-button size="small" @click="showDebug = false">关闭</el-button>
        </div>
      </div>
      <el-collapse accordion>
        <el-collapse-item title="📥 1. 输入参数 (Props)" name="props">
          <div class="debug-item">
            <div class="debug-label">detailList 数量:</div>
            <div class="debug-value">{{ detailList.length }} 条</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">markList 数量:</div>
            <div class="debug-value">{{ markList.length }} 条</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">matrixStrategy:</div>
            <div class="debug-value">{{ matrixStrategy }} ({{ matrixStrategy === '2' ? '稀疏' : '完整' }})</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">minValueFilter:</div>
            <div class="debug-value">{{ minValueFilter }}</div>
          </div>
        </el-collapse-item>
        
        <el-collapse-item title="📊 2. 矩阵大小计算" name="matrixSize">
          <div class="debug-item">
            <div class="debug-label">从数据计算的最大值:</div>
            <div class="debug-value highlight">{{ calculatedMatrixMax }}</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">显示值列表:</div>
            <div class="debug-value">{{ displayValues.join(', ') }}</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">矩阵大小:</div>
            <div class="debug-value highlight">{{ displayValues.length }} × {{ displayValues.length }}</div>
          </div>
        </el-collapse-item>
        
        <el-collapse-item title="🔍 3. 数据过滤" name="filter">
          <div class="debug-item">
            <div class="debug-label">过滤前:</div>
            <div class="debug-value">{{ detailList.length }} 条</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">过滤后:</div>
            <div class="debug-value">{{ filteredDetailList.length }} 条</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">被过滤:</div>
            <div class="debug-value warn">{{ detailList.length - filteredDetailList.length }} 条</div>
          </div>
        </el-collapse-item>
        
        <el-collapse-item title="🏷️ 4. 标签映射" name="labels">
          <div v-for="val in displayValues.slice(0, 10)" :key="val" class="debug-item">
            <div class="debug-label">值 {{ val }}:</div>
            <div class="debug-value">{{ getLabel(val) }}</div>
          </div>
          <div v-if="displayValues.length > 10" class="debug-more">
            ... 还有 {{ displayValues.length - 10 }} 个
          </div>
        </el-collapse-item>
        
        <el-collapse-item title="📈 5. 统计指标" name="stats">
          <div class="debug-item">
            <div class="debug-label">总样本数:</div>
            <div class="debug-value">{{ totalCount }}</div>
          </div>
          <div class="debug-item">
            <div class="debug-label">准确率:</div>
            <div class="debug-value highlight">{{ formatPercent(totalAccuracy) }}</div>
          </div>
        </el-collapse-item>
      </el-collapse>
    </div>

    <!-- ================================================================
         策略说明标签栏
         显示当前矩阵的策略、大小等基本信息
         ================================================================ -->
    <div class="strategy-info">
      <el-tag :type="matrixStrategy === '2' ? 'success' : 'primary'" size="small">
        {{ matrixStrategy === '2' ? '稀疏矩阵' : '完整矩阵' }}
      </el-tag>
      <span class="info-text">
        大小: <b>{{ displayValues.length }} × {{ displayValues.length }}</b>
      </span>
      <span class="info-text">
        最大值: <b>{{ calculatedMatrixMax }}</b>
      </span>
      <span v-if="minValueFilter > 0" class="info-text">
        <el-tag type="warning" size="small">过滤 ≤ {{ minValueFilter }}</el-tag>
      </span>
      <!-- 调试开关 -->
      <el-switch
        v-model="showDebug"
        active-text="调试"
        size="small"
        style="margin-left: auto;"
      />
    </div>

    <!-- ================================================================
         混淆矩阵表格
         使用 el-table 渲染，支持固定列、动态列
         ================================================================ -->
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
      <!-- 列1: 显示说明（固定列） -->
      <el-table-column
        prop="label"
        label="显示说明"
        width="130"
        fixed="left"
        class-name="col-label"
        :header-cell-style="{ background: '#67C23A', color: 'white' }"
      />

      <!-- 列2: 实际值（固定列） -->
      <el-table-column
        prop="actualValue"
        :label="displayAxisLabel"
        width="90"
        fixed="left"
        align="center"
        class-name="col-actual"
        :header-cell-style="{ background: '#67C23A', color: 'white' }"
      />

      <!-- 动态列: 预测值列（根据 displayValues 动态生成） -->
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
          <!-- 数据行: 显示计数，可点击 -->
          <div
            v-if="row.rowType === 'data'"
            :class="getDataCellClass(row.actualValue, predictVal, row['pred_' + predictVal])"
            @click="handleCellClick(row.actualValue, predictVal, row['pred_' + predictVal])"
          >
            {{ row['pred_' + predictVal] }}
          </div>
          <!-- 合计行: 显示列合计，可点击 -->
          <div
            v-else-if="row.rowType === 'sum'"
            class="sum-cell clickable"
            @click="handleColSumClick(predictVal)"
          >
            {{ row['pred_' + predictVal] }}
          </div>
          <!-- 精准率行: 显示百分比 -->
          <div
            v-else-if="row.rowType === 'precision'"
            :class="getMetricClass(row['pred_' + predictVal])"
          >
            {{ formatPercent(row['pred_' + predictVal]) }}
          </div>
        </template>
      </el-table-column>

      <!-- 列: 行合计 -->
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
          <!-- 精准率行的合计列显示总精准率 -->
          <div
            v-else-if="row.rowType === 'precision'"
            :class="getMetricClass(totalPrecisionRate)"
          >
            {{ formatPercent(totalPrecisionRate) }}
          </div>
        </template>
      </el-table-column>

      <!-- 列: 召回率 -->
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
          <!-- 合计行的召回率列显示总召回率 -->
          <div v-else-if="row.rowType === 'sum'" :class="getMetricClass(totalRecallRate)">
            {{ formatPercent(totalRecallRate) }}
          </div>
          <!-- 精准率行的召回率列（右下角）显示准确率 -->
          <div v-else-if="row.rowType === 'precision'" class="accuracy-cell">
            <span class="accuracy-value" :class="getMetricClass(totalAccuracy)">
              {{ formatPercent(totalAccuracy) }}
            </span>
          </div>
        </template>
      </el-table-column>
    </el-table>

    <!-- ================================================================
         计算逻辑说明区域（新增）
         ================================================================ -->
    <div class="calculation-info">
      <el-collapse>
        <el-collapse-item title="📊 指标计算说明" name="info">
          <div class="info-content">
            <div class="info-section">
              <h4>📈 基础指标</h4>
              <ul>
                <li><b>准确率 (Accuracy)</b>：对角线总数 ÷ 总样本数 × 100%</li>
                <li><b>召回率 (Recall)</b>：该行对角线值 ÷ 该行合计 × 100%（衡量实际为某类的样本中，有多少被正确预测）</li>
                <li><b>精准率 (Precision)</b>：该列对角线值 ÷ 该列合计 × 100%（衡量预测为某类的样本中，有多少是正确的）</li>
              </ul>
            </div>
            <div class="info-section">
              <h4>📊 汇总指标</h4>
              <ul>
                <li v-if="matrixStats.hasZeroValue">
                  <b>总召回率</b>：(对角线总和 - 0-0位置值) ÷ (行合计总和 - 0行合计) × 100%
                  <span class="info-note">（排除值为0的分类）</span>
                </li>
                <li v-else>
                  <b>总召回率</b>：对角线总和 ÷ 行合计总和 × 100%
                </li>
                <li v-if="matrixStats.hasZeroValue">
                  <b>总精准率</b>：(对角线总和 - 0-0位置值) ÷ (列合计总和 - 0列合计) × 100%
                  <span class="info-note">（排除值为0的分类）</span>
                </li>
                <li v-else>
                  <b>总精准率</b>：对角线总和 ÷ 列合计总和 × 100%
                </li>
              </ul>
            </div>
            <div class="info-section" v-if="matrixStats.hasZeroValue">
              <h4>⚠️ 排除说明</h4>
              <p>当前矩阵包含值为0的分类（索引位置：{{ matrixStats.zeroIndex }}），在计算总召回率和总精准率时已排除该分类的数据：</p>
              <ul>
                <li>总召回率：分子排除了 0-0 位置的 {{ matrixStats.diagonal[matrixStats.zeroIndex] }} 个样本，分母排除了 0 行的 {{ matrixStats.rowSums[matrixStats.zeroIndex] }} 个样本</li>
                <li>总精准率：分子排除了 0-0 位置的 {{ matrixStats.diagonal[matrixStats.zeroIndex] }} 个样本，分母排除了 0 列的 {{ matrixStats.colSums[matrixStats.zeroIndex] }} 个样本</li>
              </ul>
            </div>
          </div>
        </el-collapse-item>
      </el-collapse>
    </div>
  </div>
</template>

<script setup>
/**
 * ============================================================================
 * 混淆矩阵组件 (ConfusionMatrix.vue)
 * ============================================================================
 * 
 * 【组件功能】
 * 接收后端数据，渲染成可交互的混淆矩阵表格
 * 
 * 【移植说明】
 * 核心计算逻辑已抽取到 utils/matrixCalculator.js，可独立使用
 * 
 * 【Props 参数】
 * - detailList: 详情数据列表（核心数据）
 * - markList: 标记映射列表（用于显示说明）
 * - statistics: 统计信息（可选）
 * - matrixStrategy: 矩阵策略 "1"=完整 "2"=稀疏
 * - minValueFilter: 最小值过滤阈值
 * 
 * @version 1.4.0
 * ============================================================================
 */

import { ref, computed, watch } from 'vue'

// 导入矩阵计算工具模块
import {
  calculateMatrixMax as calcMatrixMax,
  filterDetailList as filterList,
  getDisplayValues as getDispValues,
  buildMatrix,
  calculateStatistics as calcStats,
  getLabel as getLabelFromUtils,
  setDebugMode,
  formatPercent as formatPct
} from '../utils/matrixCalculator'

// ============================================================================
// Props 定义
// ============================================================================

const props = defineProps({
  /**
   * 详情数据列表 - 核心数据
   * 格式: [{ acturalValue: "1", predictedValue: "2", descValue: "xxx" }, ...]
   */
  detailList: {
    type: Array,
    default: () => []
  },

  /**
   * 标记映射列表 - 用于显示说明
   * 格式: [{ id: "1", value: "1", desc: "天气查询" }, ...]
   */
  markList: {
    type: Array,
    default: () => []
  },

  /**
   * 统计信息 - 可选的预计算数据
   */
  statistics: {
    type: Object,
    default: () => ({})
  },

  /**
   * 矩阵策略
   * "1" = 完整矩阵（显示所有值）
   * "2" = 稀疏矩阵（只显示出现的值）
   */
  matrixStrategy: {
    type: String,
    default: '1'
  },

  /**
   * 最小值过滤阈值
   * 默认-1，包含0值
   * 只显示大于此值的分类
   */
  minValueFilter: {
    type: Number,
    default: -1
  },

  /**
   * 自定义坐标轴标签（新增）
   * 用于替换默认的 "实际\预测" 标签
   * 如果接口返回此值，则使用接口返回的值
   */
  axisLabel: {
    type: String,
    default: ''
  }
})

// ============================================================================
// Events 定义
// ============================================================================

const emit = defineEmits(['cell-click'])

// ============================================================================
// 响应式状态
// ============================================================================

/** 是否显示调试面板 */
const showDebug = ref(false)

// 监听调试模式变化，同步到工具模块
watch(showDebug, (val) => {
  setDebugMode(val)
  if (val) {
    console.log('📊 混淆矩阵调试模式已开启，查看控制台获取详细日志')
  }
})

// ============================================================================
// 核心计算属性
// ============================================================================

/**
 * 【计算】矩阵最大值
 * 从 detailList 中自动计算，取所有值的最大值
 */
const calculatedMatrixMax = computed(() => {
  console.log('[Matrix] 计算矩阵最大值...')
  const max = calcMatrixMax(props.detailList)
  console.log('[Matrix] 矩阵最大值 =', max)
  return max
})

/**
 * 【计算】过滤后的有效数据
 * 过滤掉非数字和小于等于 minValueFilter 的数据
 */
const filteredDetailList = computed(() => {
  console.log('[Matrix] 过滤数据...', `原始: ${props.detailList.length} 条`)
  const filtered = filterList(props.detailList, props.minValueFilter)
  console.log('[Matrix] 过滤后:', filtered.length, '条')
  return filtered
})

/**
 * 【计算】显示值列表
 * 决定矩阵的行/列标题
 */
const displayValues = computed(() => {
  console.log('[Matrix] 计算显示值列表...', `策略: ${props.matrixStrategy}`)
  const values = getDispValues(
    filteredDetailList.value,
    calculatedMatrixMax.value,
    props.matrixStrategy,
    props.minValueFilter
  )
  console.log('[Matrix] 显示值列表:', values)
  console.log('[Matrix] 矩阵大小:', values.length, '×', values.length)
  return values
})

/**
 * 【计算】矩阵数据和详情映射
 */
const matrixResult = computed(() => {
  console.log('[Matrix] 构建矩阵数据...')
  const result = buildMatrix(filteredDetailList.value, displayValues.value)
  console.log('[Matrix] 矩阵构建完成')
  return result
})

/**
 * 【计算】统计指标
 */
const matrixStats = computed(() => {
  console.log('[Matrix] 计算统计指标...')
  const stats = calcStats(matrixResult.value.matrix, displayValues.value)
  console.log('[Matrix] 准确率:', stats.accuracy.toFixed(2) + '%')
  return stats
})

// 解构统计数据
const colSums = computed(() => matrixStats.value.colSums)
const precisions = computed(() => matrixStats.value.precisions)
const totalCount = computed(() => matrixStats.value.totalCount)
const totalAccuracy = computed(() => matrixStats.value.accuracy)
const totalRecallRate = computed(() => matrixStats.value.totalRecall)
const totalPrecisionRate = computed(() => matrixStats.value.totalPrecision)

/**
 * 【计算】显示坐标轴标签（新增）
 * 优先使用接口返回的 axisLabel，否则使用默认值
 */
const displayAxisLabel = computed(() => {
  return props.axisLabel || '实际\\预测'
})

/**
 * 【计算】获取标签（显示说明）
 * 优先级: markList > detailList.descValue > 默认值
 */
const getLabel = (value) => {
  return getLabelFromUtils(value, props.markList, props.detailList)
}

/**
 * 【计算】表格数据（el-table 格式）
 */
const tableData = computed(() => {
  const values = displayValues.value
  const mat = matrixResult.value.matrix
  const rows = []

  // 数据行
  values.forEach((actualVal, rowIdx) => {
    const row = {
      rowType: 'data',
      label: getLabel(actualVal),
      actualValue: actualVal,
      rowSum: 0,
      recall: 0,
      rowIdx: rowIdx
    }
    
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

  // 合计行
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

  // 精准率行
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
// 调试函数
// ============================================================================

/**
 * 打印详细调试信息到控制台
 */
const printDebugInfo = () => {
  console.group('🔧 混淆矩阵详细调试信息')
  
  console.group('📥 1. 输入参数')
  console.log('detailList:', props.detailList.length, '条')
  console.log('detailList 示例:', props.detailList.slice(0, 3))
  console.log('markList:', props.markList)
  console.log('matrixStrategy:', props.matrixStrategy)
  console.log('minValueFilter:', props.minValueFilter)
  console.groupEnd()
  
  console.group('📊 2. 矩阵大小计算')
  console.log('计算出的最大值:', calculatedMatrixMax.value)
  console.log('显示值列表:', displayValues.value)
  console.log('矩阵大小:', displayValues.value.length, '×', displayValues.value.length)
  console.groupEnd()
  
  console.group('🔍 3. 数据过滤')
  console.log('过滤前:', props.detailList.length, '条')
  console.log('过滤后:', filteredDetailList.value.length, '条')
  console.log('被过滤:', props.detailList.length - filteredDetailList.value.length, '条')
  console.groupEnd()
  
  console.group('📈 4. 矩阵数据')
  console.table(matrixResult.value.matrix)
  console.groupEnd()
  
  console.group('🏷️ 5. 标签映射')
  displayValues.value.slice(0, 10).forEach(val => {
    console.log(`值 ${val} → "${getLabel(val)}"`)
  })
  console.groupEnd()
  
  console.group('📉 6. 统计指标')
  console.log('总样本数:', totalCount.value)
  console.log('准确率:', totalAccuracy.value.toFixed(2) + '%')
  console.log('行合计:', matrixStats.value.rowSums)
  console.log('列合计:', colSums.value)
  console.log('召回率:', matrixStats.value.recalls.map(r => r.toFixed(2) + '%'))
  console.log('精准率:', precisions.value.map(p => p.toFixed(2) + '%'))
  console.groupEnd()
  
  console.groupEnd()
}

// ============================================================================
// 样式和格式化函数
// ============================================================================

const headerCellStyle = {
  background: '#409EFF',
  color: 'white',
  fontWeight: 'bold',
  textAlign: 'center'
}

const getCellStyle = ({ row }) => {
  if (row.rowType === 'sum') return { background: '#e7f3ff', fontWeight: 'bold' }
  if (row.rowType === 'precision') return { background: '#e8f5e9', fontWeight: 'bold' }
  return {}
}

const getRowClassName = ({ row }) => {
  if (row.rowType === 'sum') return 'row-sum'
  if (row.rowType === 'precision') return 'row-precision'
  return ''
}

const getDataCellClass = (actualVal, predictVal, value) => {
  const classes = ['data-cell']
  if (value === 0) classes.push('cell-zero')
  else if (actualVal === predictVal) classes.push('cell-correct', 'clickable')
  else classes.push('cell-error', 'clickable')
  return classes.join(' ')
}

const getMetricClass = (value) => {
  if (value >= 90) return 'metric-high'
  if (value >= 70) return 'metric-medium'
  return 'metric-low'
}

const formatPercent = (value) => formatPct(value, 2)

// ============================================================================
// 事件处理
// ============================================================================

const handleCellClick = (actualVal, predictVal, value) => {
  if (value === 0) return
  const key = `${actualVal}_${predictVal}`
  const records = matrixResult.value.cellDetails[key] || []
  emit('cell-click', { actual: actualVal, predicted: predictVal, count: value, records, type: 'cell' })
}

const handleRowSumClick = (actualVal) => {
  const records = matrixResult.value.rowDetails[actualVal] || []
  if (records.length === 0) return
  emit('cell-click', { actual: actualVal, predicted: '全部', count: records.length, records, type: 'row-sum', title: `实际值=${actualVal} 的所有记录` })
}

const handleColSumClick = (predictVal) => {
  const records = matrixResult.value.colDetails[predictVal] || []
  if (records.length === 0) return
  emit('cell-click', { actual: '全部', predicted: predictVal, count: records.length, records, type: 'col-sum', title: `预测值=${predictVal} 的所有记录` })
}
</script>

<style scoped>
/* 调试面板样式 */
.debug-panel {
  margin-bottom: 16px;
  padding: 12px;
  background: linear-gradient(135deg, #fef0f0, #fef5e7);
  border: 1px solid #f5c6cb;
  border-radius: 8px;
  font-size: 12px;
}

.debug-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px dashed #ddd;
  font-weight: bold;
  color: #e74c3c;
}

.debug-item {
  display: flex;
  padding: 4px 0;
  border-bottom: 1px dotted #eee;
}

.debug-label {
  width: 140px;
  color: #666;
}

.debug-value {
  flex: 1;
  font-family: monospace;
}

.debug-value.highlight {
  color: #409EFF;
  font-weight: bold;
}

.debug-value.warn {
  color: #E6A23C;
}

.debug-more {
  color: #999;
  font-style: italic;
  padding: 4px 0;
}

/* 策略信息栏 */
.strategy-info {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 12px;
  padding: 10px 14px;
  background: linear-gradient(90deg, #f5f7fa, #ecf5ff);
  border-radius: 6px;
  border-left: 3px solid #409EFF;
}

.info-text {
  font-size: 13px;
  color: #606266;
}

.info-text b {
  color: #303133;
}

/* 表格样式 */
.matrix-table { width: 100%; font-size: 13px; }

:deep(.col-label), :deep(.col-actual) {
  background: #f0f9ff !important;
  font-weight: 600;
}

:deep(.col-sum) { background: #e7f3ff !important; }
:deep(.col-recall) { background: #e8f5e9 !important; }

/* 单元格样式 */
.data-cell {
  padding: 4px 8px;
  border-radius: 3px;
  transition: all 0.2s;
  display: inline-block;
  min-width: 40px;
}

.cell-zero { background: #f8f9fa; color: #aaa; }
.cell-correct { background: #d4edda; color: #155724; font-weight: bold; }
.cell-error { background: #fff3cd; color: #856404; }

.clickable { cursor: pointer; }
.clickable:hover {
  transform: scale(1.1);
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  z-index: 1;
  position: relative;
}

.sum-cell {
  font-weight: bold;
  color: #409EFF;
  padding: 4px 8px;
  border-radius: 3px;
}

.sum-cell.clickable:hover { background: #409EFF; color: white; }
.sum-cell.total { color: #E6A23C; font-size: 14px; }

/* 指标颜色 */
.metric-high { color: #2e7d32; background: #e8f5e9; padding: 4px 8px; border-radius: 3px; font-weight: bold; }
.metric-medium { color: #f57c00; background: #fff3e0; padding: 4px 8px; border-radius: 3px; font-weight: bold; }
.metric-low { color: #c62828; background: #ffebee; padding: 4px 8px; border-radius: 3px; font-weight: bold; }

/* 斜线单元格 */
.diagonal-cell {
  position: relative;
  min-width: 60px;
  min-height: 30px;
  background: #f5f5f5;
}

.diagonal-cell::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: linear-gradient(to top right, transparent 0%, transparent calc(50% - 0.5px), #999 50%, transparent calc(50% + 0.5px), transparent 100%);
}

/* 行样式 */
:deep(.row-sum), :deep(.row-sum td) { background: #e7f3ff !important; font-weight: bold; }
:deep(.row-precision), :deep(.row-precision td) { background: #e8f5e9 !important; font-weight: bold; }

/* 准确率单元格样式（右下角） */
.accuracy-cell {
  position: relative;
  min-width: 60px;
  min-height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.accuracy-value {
  padding: 4px 8px;
  border-radius: 3px;
  font-weight: bold;
  font-size: 12px;
}

/* 计算说明区域样式 */
.calculation-info {
  margin-top: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  background: #fafafa;
}

.calculation-info :deep(.el-collapse-item__header) {
  background: #f5f7fa;
  padding: 0 16px;
  font-weight: 600;
  color: #409EFF;
}

.calculation-info :deep(.el-collapse-item__content) {
  padding: 0;
}

.info-content {
  padding: 16px;
  font-size: 13px;
  line-height: 1.8;
}

.info-section {
  margin-bottom: 16px;
}

.info-section:last-child {
  margin-bottom: 0;
}

.info-section h4 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 14px;
}

.info-section ul {
  margin: 0;
  padding-left: 20px;
}

.info-section li {
  margin-bottom: 4px;
  color: #606266;
}

.info-section li b {
  color: #303133;
}

.info-note {
  color: #E6A23C;
  font-size: 12px;
}

.info-section p {
  margin: 0 0 8px 0;
  color: #606266;
}
</style>
