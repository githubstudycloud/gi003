/**
 * ============================================================================
 * 混淆矩阵计算工具模块 (matrixCalculator.js)
 * ============================================================================
 * 
 * 【模块功能】
 * 提供混淆矩阵相关的所有计算逻辑，可独立使用，便于移植到其他项目。
 * 
 * 【使用方法】
 * import { 
 *   calculateMatrixMax, 
 *   filterDetailList, 
 *   buildMatrix,
 *   calculateStatistics,
 *   getDisplayValues,
 *   getLabel 
 * } from '@/utils/matrixCalculator'
 * 
 * 【移植说明】
 * 本模块是纯 JavaScript，不依赖 Vue，可直接复制到任何项目使用。
 * 只需确保输入数据格式符合要求即可。
 * 
 * @author AI Assistant
 * @version 1.0.0
 * ============================================================================
 */

// ============================================================================
// 调试配置
// ============================================================================

/**
 * 是否开启调试日志
 * 设置为 true 时，会在控制台输出详细的计算过程
 */
let DEBUG_MODE = false

/**
 * 设置调试模式
 * @param {boolean} enabled - 是否开启调试
 */
export const setDebugMode = (enabled) => {
  DEBUG_MODE = enabled
  log('调试模式已' + (enabled ? '开启' : '关闭'))
}

/**
 * 调试日志输出
 * @param {string} message - 日志消息
 * @param {any} data - 可选的附加数据
 */
const log = (message, data = null) => {
  if (DEBUG_MODE) {
    if (data !== null) {
      console.log(`[MatrixCalc] ${message}`, data)
    } else {
      console.log(`[MatrixCalc] ${message}`)
    }
  }
}

// ============================================================================
// 核心计算函数
// ============================================================================

/**
 * 【核心函数1】计算矩阵最大值
 * 
 * 从详情数据中自动计算矩阵的最大值（决定完整矩阵的大小）
 * 
 * 【计算逻辑】
 * 1. 遍历所有详情数据
 * 2. 解析每条记录的 acturalValue（实际值）
 * 3. 解析每条记录的 predictedValue（预测值）
 * 4. 找出所有有效数值中的最大值
 * 
 * 【示例】
 * 输入: [
 *   { acturalValue: "1", predictedValue: "2" },
 *   { acturalValue: "3", predictedValue: "5" },
 *   { acturalValue: "2", predictedValue: "3" }
 * ]
 * 输出: 5 (所有值中的最大值)
 * 
 * @param {Array} detailList - 详情数据列表
 * @returns {number} 矩阵最大值
 */
export const calculateMatrixMax = (detailList) => {
  log('开始计算矩阵最大值...')
  log('输入数据条数:', detailList.length)
  
  let maxVal = 0
  
  detailList.forEach((detail, index) => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    
    if (!isNaN(actual) && actual > maxVal) {
      maxVal = actual
      log(`第${index}条: acturalValue=${actual} 更新最大值为 ${maxVal}`)
    }
    if (!isNaN(predicted) && predicted > maxVal) {
      maxVal = predicted
      log(`第${index}条: predictedValue=${predicted} 更新最大值为 ${maxVal}`)
    }
  })
  
  log('计算完成，矩阵最大值:', maxVal)
  return maxVal
}

/**
 * 【核心函数2】过滤详情数据
 * 
 * 过滤掉无效数据，只保留有效的记录
 * 
 * 【过滤条件】
 * 1. acturalValue 必须能转换为有效整数
 * 2. predictedValue 必须能转换为有效整数
 * 3. 两个值都必须大于 minValueFilter
 * 
 * 【示例】
 * 输入: [
 *   { acturalValue: "1", predictedValue: "2" },  // 有效
 *   { acturalValue: "abc", predictedValue: "1" }, // 无效：acturalValue不是数字
 *   { acturalValue: "0", predictedValue: "1" },   // 无效：acturalValue=0 不大于 minValueFilter=0
 * ]
 * minValueFilter: 0
 * 输出: [{ acturalValue: "1", predictedValue: "2" }]
 * 
 * @param {Array} detailList - 详情数据列表
 * @param {number} minValueFilter - 最小值过滤阈值（默认0）
 * @returns {Array} 过滤后的有效数据列表
 */
export const filterDetailList = (detailList, minValueFilter = 0) => {
  log('开始过滤数据...')
  log('过滤前数量:', detailList.length)
  log('最小值过滤阈值:', minValueFilter)
  
  const filtered = detailList.filter(detail => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    
    // 检查是否为有效数字
    if (isNaN(actual)) {
      log(`过滤: acturalValue="${detail.acturalValue}" 不是有效数字`)
      return false
    }
    if (isNaN(predicted)) {
      log(`过滤: predictedValue="${detail.predictedValue}" 不是有效数字`)
      return false
    }
    
    // 检查是否大于最小值过滤阈值
    // 使用 <= 表示过滤掉小于等于阈值的数据
    // 例如：minValueFilter=0 时，过滤掉0和负数；minValueFilter=-1 时，只过滤负数（保留0）
    if (actual <= minValueFilter) {
      log(`过滤: acturalValue=${actual} <= ${minValueFilter}`)
      return false
    }
    if (predicted <= minValueFilter) {
      log(`过滤: predictedValue=${predicted} <= ${minValueFilter}`)
      return false
    }
    
    return true
  })
  
  log('过滤后数量:', filtered.length)
  log('被过滤掉的数量:', detailList.length - filtered.length)
  
  return filtered
}

/**
 * 【核心函数3】获取显示值列表
 * 
 * 根据策略确定矩阵的行/列标题值列表
 * 
 * 【策略说明】
 * - 策略1（完整矩阵）：生成从 minValueFilter+1 到 matrixMax 的连续整数
 *   例如：minValueFilter=0, matrixMax=5 → [1, 2, 3, 4, 5]
 * 
 * - 策略2（稀疏矩阵）：只包含数据中实际出现过的值
 *   例如：数据中出现 1, 3, 5 → [1, 3, 5]（跳过 2, 4）
 * 
 * @param {Array} filteredList - 过滤后的数据列表
 * @param {number} matrixMax - 矩阵最大值
 * @param {string} matrixStrategy - 矩阵策略 "1"=完整 "2"=稀疏
 * @param {number} minValueFilter - 最小值过滤阈值
 * @returns {Array} 显示值列表
 */
export const getDisplayValues = (filteredList, matrixMax, matrixStrategy, minValueFilter = 0) => {
  log('开始计算显示值列表...')
  log('策略:', matrixStrategy === '2' ? '稀疏矩阵' : '完整矩阵')
  log('最大值:', matrixMax)
  log('最小值过滤:', minValueFilter)
  
  let values = []
  
  if (matrixStrategy === '2') {
    // 策略2：稀疏矩阵 - 只显示出现过的值
    const valueSet = new Set()
    
    filteredList.forEach(detail => {
      const actual = parseInt(detail.acturalValue)
      const predicted = parseInt(detail.predictedValue)
      
      if (!isNaN(actual) && actual > minValueFilter) {
        valueSet.add(actual)
      }
      if (!isNaN(predicted) && predicted > minValueFilter) {
        valueSet.add(predicted)
      }
    })
    
    values = Array.from(valueSet).sort((a, b) => a - b)
    log('稀疏矩阵 - 出现的唯一值:', values)
    
  } else {
    // 策略1：完整矩阵 - 连续整数
    // 使用 Math.max(0, ...) 允许当 minValueFilter < 0 时从0开始
    // 例如：minValueFilter=-1 时，startVal=0；minValueFilter=0 时，startVal=1
    const startVal = Math.max(0, minValueFilter + 1)

    if (matrixMax >= startVal) {
      for (let i = startVal; i <= matrixMax; i++) {
        values.push(i)
      }
    }
    log('完整矩阵 - 连续值范围:', `${startVal} ~ ${matrixMax}`)
  }
  
  log('最终显示值列表:', values)
  log('矩阵大小:', values.length, 'x', values.length)
  
  return values
}

/**
 * 【核心函数4】构建矩阵数据
 * 
 * 根据详情数据构建混淆矩阵
 * 
 * 【矩阵结构】
 * - 行：实际值（acturalValue）
 * - 列：预测值（predictedValue）
 * - 单元格值：该组合出现的次数
 * 
 * 【示例】
 * displayValues = [1, 2, 3]
 * 数据: acturalValue=1, predictedValue=1 出现 50 次
 *       acturalValue=1, predictedValue=2 出现 5 次
 * 
 * 矩阵:
 *        预测1  预测2  预测3
 * 实际1  [ 50,   5,    0  ]
 * 实际2  [  0,  40,    3  ]
 * 实际3  [  0,   2,   30  ]
 * 
 * @param {Array} filteredList - 过滤后的数据列表
 * @param {Array} displayValues - 显示值列表
 * @returns {Object} { matrix, cellDetails, rowDetails, colDetails }
 */
export const buildMatrix = (filteredList, displayValues) => {
  log('开始构建矩阵...')
  log('显示值列表:', displayValues)
  
  const size = displayValues.length
  log('矩阵大小:', size, 'x', size)
  
  // 1. 构建值到索引的映射
  const valueToIndex = {}
  displayValues.forEach((val, idx) => {
    valueToIndex[val] = idx
  })
  log('值到索引映射:', valueToIndex)
  
  // 2. 初始化矩阵（全0）
  const matrix = Array(size).fill(0).map(() => Array(size).fill(0))
  
  // 3. 初始化详情映射
  const cellDetails = {}  // key: "actual_predicted" → 详细记录数组
  const rowDetails = {}   // key: actualValue → 详细记录数组
  const colDetails = {}   // key: predictedValue → 详细记录数组
  
  // 4. 遍历数据，填充矩阵
  filteredList.forEach((detail, index) => {
    const actual = parseInt(detail.acturalValue)
    const predicted = parseInt(detail.predictedValue)
    
    const rowIdx = valueToIndex[actual]
    const colIdx = valueToIndex[predicted]
    
    if (rowIdx !== undefined && colIdx !== undefined) {
      // 矩阵计数 +1
      matrix[rowIdx][colIdx]++
      
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
      
      if (index < 5) {
        log(`第${index}条: (${actual}, ${predicted}) → 矩阵[${rowIdx}][${colIdx}]++`)
      }
    }
  })
  
  log('矩阵构建完成')
  log('矩阵数据:', matrix)
  
  return { matrix, cellDetails, rowDetails, colDetails, valueToIndex }
}

/**
 * 【核心函数5】计算统计指标
 *
 * 根据矩阵数据计算各项统计指标
 *
 * 【计算公式】
 * - 行合计(rowSum): 该行所有单元格之和 = 该实际值的总样本数
 * - 列合计(colSum): 该列所有单元格之和 = 该预测值的总预测数
 * - 召回率(recall): 对角线值 / 行合计 × 100%
 * - 精准率(precision): 对角线值 / 列合计 × 100%
 * - 准确率(accuracy): 对角线之和 / 总数 × 100%
 *
 * 【总召回率计算】（新增）
 * - 分母：所有行合计之和 - 值为0的行合计（如果存在）
 * - 分子：对角线之和 - 值为0的对角线元素（如果存在）
 * - 公式：(对角线总和 - 0-0位置值) / (行总和 - 0行总和) × 100%
 *
 * 【总精准率计算】（新增）
 * - 分母：所有列合计之和 - 值为0的列合计（如果存在）
 * - 分子：对角线之和 - 值为0的对角线元素（如果存在）
 * - 公式：(对角线总和 - 0-0位置值) / (列总和 - 0列总和) × 100%
 *
 * @param {Array} matrix - 矩阵数据
 * @param {Array} displayValues - 显示值列表
 * @param {string} matrixStrategy - 矩阵策略 "1"=完整 "2"=稀疏（可选）
 * @returns {Object} 统计信息
 */
export const calculateStatistics = (matrix, displayValues, matrixStrategy = '1') => {
  log('开始计算统计指标...')

  const size = displayValues.length

  // 查找值为0的索引位置（如果存在）
  const zeroIndex = displayValues.indexOf(0)
  const hasZeroValue = zeroIndex !== -1
  log(`值为0的索引位置: ${hasZeroValue ? zeroIndex : '不存在'}`)

  // 1. 计算行合计
  const rowSums = matrix.map((row, i) => {
    const sum = row.reduce((a, b) => a + b, 0)
    log(`行${i}合计 (实际值=${displayValues[i]}): ${sum}`)
    return sum
  })

  // 2. 计算列合计
  const colSums = displayValues.map((_, colIdx) => {
    let sum = 0
    for (let i = 0; i < size; i++) {
      sum += matrix[i][colIdx]
    }
    log(`列${colIdx}合计 (预测值=${displayValues[colIdx]}): ${sum}`)
    return sum
  })

  // 3. 计算对角线（预测正确数）
  let correctCount = 0
  const diagonal = matrix.map((row, i) => {
    correctCount += row[i]
    return row[i]
  })
  log('对角线值:', diagonal)
  log('预测正确总数:', correctCount)

  // 4. 计算总数
  const totalCount = rowSums.reduce((a, b) => a + b, 0)
  log('总样本数:', totalCount)

  // 5. 计算召回率（每行）
  const recalls = rowSums.map((rowSum, i) => {
    const recall = rowSum > 0 ? (matrix[i][i] / rowSum) * 100 : 0
    log(`召回率[${i}] = ${matrix[i][i]} / ${rowSum} × 100% = ${recall.toFixed(2)}%`)
    return recall
  })

  // 6. 计算精准率（每列）
  const precisions = colSums.map((colSum, i) => {
    const precision = colSum > 0 ? (matrix[i][i] / colSum) * 100 : 0
    log(`精准率[${i}] = ${matrix[i][i]} / ${colSum} × 100% = ${precision.toFixed(2)}%`)
    return precision
  })

  // 7. 计算总准确率
  const accuracy = totalCount > 0 ? (correctCount / totalCount) * 100 : 0
  log(`准确率 = ${correctCount} / ${totalCount} × 100% = ${accuracy.toFixed(2)}%`)

  // 8. 计算总召回率（排除值为0的行和0-0位置）
  // 分母：所有行合计之和 - 值为0的行合计
  // 分子：对角线之和 - 值为0的对角线元素
  let totalRecallDenominator = totalCount
  let totalRecallNumerator = correctCount

  if (hasZeroValue) {
    // 排除值为0的行
    totalRecallDenominator -= rowSums[zeroIndex]
    // 排除0-0位置的对角线值
    totalRecallNumerator -= diagonal[zeroIndex]
    log(`总召回率排除: 0行合计=${rowSums[zeroIndex]}, 0-0对角线=${diagonal[zeroIndex]}`)
  }

  const totalRecall = totalRecallDenominator > 0
    ? (totalRecallNumerator / totalRecallDenominator) * 100
    : 0
  log(`总召回率 = ${totalRecallNumerator} / ${totalRecallDenominator} × 100% = ${totalRecall.toFixed(2)}%`)

  // 9. 计算总精准率（排除值为0的列和0-0位置）
  // 分母：所有列合计之和 - 值为0的列合计
  // 分子：对角线之和 - 值为0的对角线元素
  let totalPrecisionDenominator = totalCount
  let totalPrecisionNumerator = correctCount

  if (hasZeroValue) {
    // 排除值为0的列
    totalPrecisionDenominator -= colSums[zeroIndex]
    // 排除0-0位置的对角线值
    totalPrecisionNumerator -= diagonal[zeroIndex]
    log(`总精准率排除: 0列合计=${colSums[zeroIndex]}, 0-0对角线=${diagonal[zeroIndex]}`)
  }

  const totalPrecision = totalPrecisionDenominator > 0
    ? (totalPrecisionNumerator / totalPrecisionDenominator) * 100
    : 0
  log(`总精准率 = ${totalPrecisionNumerator} / ${totalPrecisionDenominator} × 100% = ${totalPrecision.toFixed(2)}%`)

  return {
    rowSums,
    colSums,
    diagonal,
    recalls,
    precisions,
    totalCount,
    correctCount,
    accuracy,
    // 新增总召回率和总精准率
    totalRecall,
    totalPrecision,
    // 用于调试的中间值
    hasZeroValue,
    zeroIndex,
    totalRecallDenominator,
    totalRecallNumerator,
    totalPrecisionDenominator,
    totalPrecisionNumerator
  }
}

/**
 * 【核心函数6】获取显示标签
 * 
 * 将数值转换为可读的显示名称
 * 
 * 【取值优先级】（从高到低）
 * 1. 从 markList 中查找匹配的 value 或 id → 返回 desc
 * 2. 从 detailList 中查找对应的 descValue
 * 3. 返回默认值 "值{数字}"
 * 
 * 【示例】
 * markList = [{ id: "1", value: "1", desc: "天气查询" }]
 * getLabel(1, markList, []) → "天气查询"
 * getLabel(999, [], []) → "值999"
 * 
 * @param {number|string} value - 要转换的数值
 * @param {Array} markList - 标记映射列表
 * @param {Array} detailList - 详情数据列表（用于备选查找）
 * @returns {string} 显示标签
 */
export const getLabel = (value, markList = [], detailList = []) => {
  const strValue = String(value)
  
  // 1. 从 markList 查找
  if (markList && markList.length > 0) {
    const mark = markList.find(m => 
      String(m.value) === strValue || String(m.id) === strValue
    )
    if (mark && mark.desc) {
      log(`标签查找: 值${value} → markList匹配 → "${mark.desc}"`)
      return mark.desc
    }
  }
  
  // 2. 从 detailList 查找
  if (detailList && detailList.length > 0) {
    const detail = detailList.find(d => String(d.acturalValue) === strValue)
    if (detail && detail.descValue && detail.descValue !== '无效数据') {
      log(`标签查找: 值${value} → detailList匹配 → "${detail.descValue}"`)
      return detail.descValue
    }
  }
  
  // 3. 返回默认值
  const defaultLabel = `值${value}`
  log(`标签查找: 值${value} → 未匹配 → "${defaultLabel}"`)
  return defaultLabel
}

// ============================================================================
// 便捷函数（一次性计算所有结果）
// ============================================================================

/**
 * 【便捷函数】一次性计算所有矩阵数据
 * 
 * 这是一个封装函数，调用上面的所有核心函数，返回完整的计算结果。
 * 适合直接使用，无需单独调用每个函数。
 * 
 * @param {Object} options - 配置选项
 * @param {Array} options.detailList - 详情数据列表
 * @param {Array} options.markList - 标记映射列表（可选）
 * @param {string} options.matrixStrategy - 矩阵策略 "1"/"2"（默认"1"）
 * @param {number} options.minValueFilter - 最小值过滤阈值（默认0）
 * @param {boolean} options.debug - 是否开启调试日志（默认false）
 * @returns {Object} 完整的计算结果
 */
export const computeMatrix = (options) => {
  const {
    detailList = [],
    markList = [],
    matrixStrategy = '1',
    minValueFilter = 0,
    debug = false
  } = options
  
  // 设置调试模式
  setDebugMode(debug)
  
  console.group('🔢 混淆矩阵计算开始')
  console.log('输入参数:', { 
    detailListCount: detailList.length, 
    markListCount: markList.length,
    matrixStrategy,
    minValueFilter 
  })
  
  // 1. 计算矩阵最大值
  const matrixMax = calculateMatrixMax(detailList)
  
  // 2. 过滤数据
  const filteredList = filterDetailList(detailList, minValueFilter)
  
  // 3. 获取显示值列表
  const displayValues = getDisplayValues(filteredList, matrixMax, matrixStrategy, minValueFilter)
  
  // 4. 构建矩阵
  const { matrix, cellDetails, rowDetails, colDetails, valueToIndex } = buildMatrix(filteredList, displayValues)
  
  // 5. 计算统计指标
  const statistics = calculateStatistics(matrix, displayValues)
  
  // 6. 构建标签映射
  const labels = {}
  displayValues.forEach(val => {
    labels[val] = getLabel(val, markList, detailList)
  })
  
  console.log('计算完成:', {
    matrixSize: displayValues.length,
    totalCount: statistics.totalCount,
    accuracy: statistics.accuracy.toFixed(2) + '%'
  })
  console.groupEnd()
  
  return {
    // 基础信息
    matrixMax,
    matrixSize: displayValues.length,
    displayValues,
    
    // 过滤信息
    originalCount: detailList.length,
    filteredCount: filteredList.length,
    invalidCount: detailList.length - filteredList.length,
    
    // 矩阵数据
    matrix,
    valueToIndex,
    
    // 详情映射（用于点击查看）
    cellDetails,
    rowDetails,
    colDetails,
    
    // 统计指标
    ...statistics,
    
    // 标签映射
    labels
  }
}

// ============================================================================
// 格式化函数
// ============================================================================

/**
 * 格式化百分比
 * @param {number} value - 百分比值
 * @param {number} decimals - 小数位数（默认2）
 * @returns {string} 格式化后的字符串
 */
export const formatPercent = (value, decimals = 2) => {
  if (value === null || value === undefined || isNaN(value)) return '-'
  return value.toFixed(decimals) + '%'
}

/**
 * 格式化数字
 * @param {number} value - 数值
 * @returns {string} 格式化后的字符串
 */
export const formatNumber = (value) => {
  if (value === null || value === undefined || isNaN(value)) return '-'
  return value.toLocaleString()
}

// ============================================================================
// 导出
// ============================================================================

export default {
  // 配置
  setDebugMode,
  
  // 核心函数
  calculateMatrixMax,
  filterDetailList,
  getDisplayValues,
  buildMatrix,
  calculateStatistics,
  getLabel,
  
  // 便捷函数
  computeMatrix,
  
  // 格式化
  formatPercent,
  formatNumber
}

