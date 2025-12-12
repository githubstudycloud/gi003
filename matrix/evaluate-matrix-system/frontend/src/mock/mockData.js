/**
 * Mock数据生成模块
 * 
 * 功能：
 * 1. 生成符合后端API格式的模拟数据
 * 2. 支持配置不同的测试场景
 * 3. 支持完整矩阵(策略1)和稀疏矩阵(策略2)
 * 4. 支持最小值过滤（用于稀疏矩阵）
 * 
 * 使用方法：
 * import { generateMockReport } from './mockData.js'
 * const reportData = generateMockReport(options)
 * 
 * @author AI Assistant
 * @version 1.1.0
 */

// ==================== 常量配置 ====================

/**
 * 分类标签映射表
 * key: 数值分类ID
 * value: 对应的显示标签名称
 */
const LABEL_MAP = {
  0: '问候语',
  1: '天气查询',
  2: '知识问答',
  3: '音乐播放',
  4: '新闻资讯',
  5: '闲聊对话',
  6: '翻译服务',
  7: '日程提醒',
  8: '导航服务',
  9: '购物推荐',
  10: '其他意图'
}

/**
 * 语料前缀示例
 */
const CORPUS_PREFIXES = ['QA', 'NLU', 'INT', 'TXT', 'USR']

/**
 * 默认最小值过滤阈值
 * 稀疏矩阵模式下，只显示大于此值的分类
 */
export const DEFAULT_MIN_VALUE_FILTER = 0

// ==================== 工具函数 ====================

/**
 * 生成随机ID
 * @param {string} prefix - ID前缀
 * @returns {string} 随机ID
 */
const generateId = (prefix = 'ID') => {
  return `${prefix}${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`
}

/**
 * 生成随机整数
 * @param {number} min - 最小值（包含）
 * @param {number} max - 最大值（包含）
 * @returns {number} 随机整数
 */
const randomInt = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1)) + min
}

/**
 * 获取标签名称
 * @param {number} value - 分类值
 * @returns {string} 标签名称
 */
const getLabel = (value) => {
  return LABEL_MAP[value] || `类别${value}`
}

/**
 * 格式化日期时间
 * @param {Date} date - 日期对象
 * @returns {string} 格式化的时间字符串
 */
const formatDateTime = (date) => {
  return date.toISOString().slice(0, 19).replace('T', ' ')
}

// ==================== 核心生成函数 ====================

/**
 * 生成单条详情记录
 * 
 * @param {Object} options - 配置选项
 * @param {string} options.reportId - 报告ID
 * @param {string} options.taskId - 任务ID
 * @param {string} options.caseId - 用例ID
 * @param {number} options.maxValue - 最大分类值
 * @param {number[]} [options.validValues] - 有效的分类值列表（用于稀疏矩阵）
 * @param {number} options.correctRate - 正确率 (0-100)
 * @param {boolean} options.includeInvalid - 是否包含无效数据
 * @param {number} options.minValueFilter - 最小值过滤阈值
 * @returns {Object} 详情记录对象
 */
const generateDetail = (options) => {
  const { reportId, taskId, caseId, maxValue, validValues, correctRate, includeInvalid, minValueFilter = DEFAULT_MIN_VALUE_FILTER } = options
  
  // 语料ID
  const prefix = CORPUS_PREFIXES[randomInt(0, CORPUS_PREFIXES.length - 1)]
  const corpusId = `${prefix}_${randomInt(10000, 99999)}`
  
  // 决定是否生成无效数据
  if (includeInvalid && Math.random() < 0.05) {
    // 5% 概率生成无效数据
    return {
      reportId,
      taskId,
      caseId,
      corpusId,
      acturalValue: Math.random() < 0.5 ? 'N/A' : '',
      predictedValue: Math.random() < 0.5 ? 'invalid' : '-1',
      descValue: '无效数据',
      createTime: formatDateTime(new Date()),
      updateTime: formatDateTime(new Date())
    }
  }
  
  // 生成有效的分类值
  let actualValue, predictedValue
  
  if (validValues && validValues.length > 0) {
    // 稀疏矩阵：只使用指定的有效值（已经过滤掉负数和小于minValueFilter的值）
    actualValue = validValues[randomInt(0, validValues.length - 1)]
    
    // 根据正确率决定预测值
    if (Math.random() * 100 < correctRate) {
      predictedValue = actualValue // 预测正确
    } else {
      // 预测错误：随机选择另一个值
      const otherValues = validValues.filter(v => v !== actualValue)
      predictedValue = otherValues.length > 0 
        ? otherValues[randomInt(0, otherValues.length - 1)]
        : actualValue
    }
  } else {
    // 完整矩阵：minValueFilter 到 maxValue（默认从0开始）
    const startValue = Math.max(0, minValueFilter)
    actualValue = randomInt(startValue, maxValue)
    
    if (Math.random() * 100 < correctRate) {
      predictedValue = actualValue
    } else {
      predictedValue = randomInt(startValue, maxValue)
      // 确保预测错误
      if (predictedValue === actualValue) {
        predictedValue = (actualValue + 1) > maxValue ? startValue : (actualValue + 1)
      }
    }
  }
  
  return {
    reportId,
    taskId,
    caseId,
    corpusId,
    acturalValue: String(actualValue),
    predictedValue: String(predictedValue),
    descValue: getLabel(actualValue),
    createTime: formatDateTime(new Date()),
    updateTime: formatDateTime(new Date())
  }
}

/**
 * 生成标记列表
 * 
 * @param {number} maxValue - 最大分类值
 * @param {number[]} [validValues] - 有效的分类值列表（用于稀疏矩阵）
 * @returns {Object[]} 标记列表
 */
const generateMarkList = (maxValue, validValues) => {
  const values = validValues || Array.from({ length: maxValue + 1 }, (_, i) => i)
  
  return values.map(value => ({
    id: String(value),
    value: String(value),
    desc: getLabel(value)
  }))
}

/**
 * 计算统计信息
 * 
 * @param {Object[]} detailList - 详情列表
 * @param {number} maxValue - 最大分类值
 * @param {number[]} [validValues] - 有效分类值（用于稀疏矩阵）
 * @param {number} minValueFilter - 最小值过滤阈值
 * @returns {Object} 统计信息对象
 */
const calculateStatistics = (detailList, maxValue, validValues, minValueFilter = DEFAULT_MIN_VALUE_FILTER) => {
  const totalCount = detailList.length
  
  // 筛选有效数据（数值类型且大于最小值过滤阈值）
  const validDetails = detailList.filter(d => {
    const actual = parseInt(d.acturalValue)
    const predicted = parseInt(d.predictedValue)
    return !isNaN(actual) && !isNaN(predicted) && actual > minValueFilter && predicted > minValueFilter
  })
  
  const validCount = validDetails.length
  const invalidCount = totalCount - validCount
  
  // 计算预测正确数
  const correctCount = validDetails.filter(d => d.acturalValue === d.predictedValue).length
  
  // 计算准确率
  const accuracy = validCount > 0 ? (correctCount / validCount) * 100 : 0
  
  // 计算精准率和召回率
  const values = validValues || Array.from({ length: maxValue + 1 }, (_, i) => i).filter(v => v > minValueFilter)
  
  // 每个类别的统计
  const classStats = values.map(value => {
    const strValue = String(value)
    // 实际为该类别的数量
    const actualCount = validDetails.filter(d => d.acturalValue === strValue).length
    // 预测为该类别的数量
    const predictedCount = validDetails.filter(d => d.predictedValue === strValue).length
    // 预测正确的数量
    const correct = validDetails.filter(d => 
      d.acturalValue === strValue && d.predictedValue === strValue
    ).length
    
    return {
      value,
      actualCount,
      predictedCount,
      correctCount: correct,
      precision: predictedCount > 0 ? (correct / predictedCount) * 100 : 0,
      recall: actualCount > 0 ? (correct / actualCount) * 100 : 0
    }
  })
  
  // 过滤有数据的类别
  const classesWithData = classStats.filter(s => s.actualCount > 0 || s.predictedCount > 0)
  
  // 平均精准率和召回率
  const avgPrecision = classesWithData.length > 0
    ? classesWithData.reduce((sum, s) => sum + s.precision, 0) / classesWithData.length
    : 0
  const avgRecall = classesWithData.length > 0
    ? classesWithData.reduce((sum, s) => sum + s.recall, 0) / classesWithData.length
    : 0
  
  // 最高/最低精准率和召回率
  const precisions = classesWithData.map(s => s.precision).filter(p => p > 0)
  const recalls = classesWithData.map(s => s.recall).filter(r => r > 0)
  
  const maxPrecision = precisions.length > 0 ? Math.max(...precisions) : 0
  const minPrecision = precisions.length > 0 ? Math.min(...precisions) : 0
  const maxRecall = recalls.length > 0 ? Math.max(...recalls) : 0
  const minRecall = recalls.length > 0 ? Math.min(...recalls) : 0
  
  // 获取唯一值数量（用于稀疏矩阵显示）
  const uniqueActual = new Set(validDetails.map(d => d.acturalValue))
  const uniquePredicted = new Set(validDetails.map(d => d.predictedValue))
  const allUniqueValues = new Set([...uniqueActual, ...uniquePredicted])
  
  return {
    totalCount,
    validCount,
    invalidCount,
    correctCount,
    accuracy,
    avgPrecision,
    avgRecall,
    maxPrecision,
    minPrecision,
    maxRecall,
    minRecall,
    matrixMax: maxValue,
    uniqueValueCount: allUniqueValues.size,
    minValueFilter,
    classStats
  }
}

/**
 * 生成单个用例的完整数据
 *
 * @param {Object} caseConfig - 用例配置
 * @param {string} caseConfig.reportId - 报告ID
 * @param {string} caseConfig.taskId - 任务ID
 * @param {string} caseConfig.caseId - 用例ID
 * @param {number} caseConfig.detailCount - 详情数量
 * @param {number} caseConfig.maxValue - 最大分类值
 * @param {string} caseConfig.matrixStrategy - 矩阵策略 ("1"完整 / "2"稀疏)
 * @param {number} caseConfig.correctRate - 正确率
 * @param {number[]} [caseConfig.validValues] - 有效分类值（稀疏矩阵用）
 * @param {number} [caseConfig.minValueFilter] - 最小值过滤阈值（默认0）
 * @param {string} [caseConfig.axisLabel] - 自定义坐标轴标签（如"真实\预测"）
 * @returns {Object} 用例完整数据
 */
const generateCaseData = (caseConfig) => {
  const {
    reportId,
    taskId,
    caseId,
    detailCount = 200,
    maxValue = 5,
    matrixStrategy = '1',
    correctRate = 70,
    validValues = null,
    minValueFilter = DEFAULT_MIN_VALUE_FILTER,
    axisLabel = ''
  } = caseConfig

  // 对于稀疏矩阵，如果没有指定validValues，则随机生成（过滤掉小于等于minValueFilter的值）
  let effectiveValidValues = validValues
  if (matrixStrategy === '2' && !effectiveValidValues) {
    // 随机选择3-6个大于minValueFilter的不连续的值
    const count = randomInt(3, 6)
    const allValues = Array.from({ length: maxValue + 1 }, (_, i) => i).filter(v => v > minValueFilter)
    effectiveValidValues = []
    const availableValues = [...allValues]
    while (effectiveValidValues.length < count && availableValues.length > 0) {
      const idx = randomInt(0, availableValues.length - 1)
      effectiveValidValues.push(availableValues.splice(idx, 1)[0])
    }
    effectiveValidValues.sort((a, b) => a - b)
  } else if (effectiveValidValues) {
    // 如果提供了validValues，过滤掉小于等于minValueFilter的值
    effectiveValidValues = effectiveValidValues.filter(v => v > minValueFilter)
  }

  // 生成详情列表
  const detailList = []
  for (let i = 0; i < detailCount; i++) {
    detailList.push(generateDetail({
      reportId,
      taskId,
      caseId,
      maxValue,
      validValues: effectiveValidValues,
      correctRate,
      includeInvalid: true,
      minValueFilter
    }))
  }

  // 生成标记列表
  const markList = generateMarkList(maxValue, effectiveValidValues)

  // 计算统计信息
  const statistics = calculateStatistics(detailList, maxValue, effectiveValidValues, minValueFilter)

  // 构建用例配置对象
  const caseConfigObj = {
    reportId,
    taskId,
    caseId,
    acturalValueField: 'intent_actual',
    acturalIdField: 'id_actual',
    predictedValueField: 'intent_predicted',
    predictedIdField: 'id_predicted',
    descValueField: 'intent_label',
    matrixStrategy,
    minValueFilter,
    axisLabel, // 自定义坐标轴标签
    createTime: formatDateTime(new Date()),
    updateTime: formatDateTime(new Date())
  }

  return {
    caseConfig: caseConfigObj,
    detailList,
    markList,
    statistics
  }
}

// ==================== 主导出函数 ====================

/**
 * 生成完整的模拟报告数据
 * 
 * @param {Object} options - 生成选项
 * @param {string} options.reportId - 报告ID
 * @param {string} options.taskId - 任务ID
 * @param {Object[]} options.caseConfigs - 用例配置数组
 * @returns {Object} API响应格式的报告数据
 * 
 * @example
 * const report = generateMockReport({
 *   reportId: 'RPT001',
 *   taskId: 'TASK001',
 *   caseConfigs: [
 *     { caseId: 'CASE1', detailCount: 300, maxValue: 5, correctRate: 75 },
 *     { caseId: 'CASE2', detailCount: 200, maxValue: 8, correctRate: 80, matrixStrategy: '2', minValueFilter: 0 }
 *   ]
 * })
 */
export const generateMockReport = (options) => {
  const { reportId, taskId, caseConfigs } = options

  // 生成每个用例的数据
  const data = caseConfigs.map(config => {
    return generateCaseData({
      reportId,
      taskId,
      ...config
    })
  })

  return {
    code: 200,
    message: 'success',
    data
  }
}

/**
 * 导出工具函数（供其他模块使用）
 */
export const mockUtils = {
  generateId,
  randomInt,
  getLabel,
  formatDateTime,
  generateMarkList,
  calculateStatistics,
  LABEL_MAP,
  DEFAULT_MIN_VALUE_FILTER
}
