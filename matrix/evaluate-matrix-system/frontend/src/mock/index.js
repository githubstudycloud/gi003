/**
 * Mock模块入口
 * 
 * 功能：
 * 1. 控制Mock模式的启用/禁用
 * 2. 定义预设的测试场景
 * 3. 提供场景数据生成接口
 * 
 * 使用方法：
 * import { MOCK_ENABLED, getMockData, getMockScenarioList } from './mock/index.js'
 * 
 * @author AI Assistant
 * @version 1.1.0
 */

import { generateMockReport, DEFAULT_MIN_VALUE_FILTER } from './mockData.js'

// ==================== Mock开关配置 ====================

/**
 * Mock模式开关
 * 
 * true  - 使用模拟数据（前端独立调试模式）
 * false - 调用真实后端API
 * 
 * 注意：生产环境部署前请确保设置为 false
 */
export const MOCK_ENABLED = true

// ==================== 测试场景定义 ====================

/**
 * 预定义的测试场景配置
 * 
 * 每个场景包含：
 * - id: 场景ID（用于查询）
 * - name: 场景名称
 * - desc: 场景描述
 * - config: 数据生成配置
 * 
 * minValueFilter: 最小值过滤阈值
 * - 默认为0，只显示大于0的值
 * - 用于过滤负数和无效数据
 */
export const mockScenarios = [
  // ==================== 基础场景 ====================
  {
    id: 'RPT001',
    name: '基础场景 - 单用例',
    desc: '单个用例，5分类，200条数据，约70%准确率，过滤值≤0',
    config: {
      reportId: 'RPT001',
      taskId: 'TASK001',
      caseConfigs: [
        { 
          caseId: 'CASE_BASIC', 
          detailCount: 200, 
          maxValue: 5, 
          correctRate: 70,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 多用例场景 ====================
  {
    id: 'RPT002',
    name: '多用例场景',
    desc: '3个用例，不同分类数量和准确率',
    config: {
      reportId: 'RPT002',
      taskId: 'TASK002',
      caseConfigs: [
        { 
          caseId: 'CASE_A', 
          detailCount: 150, 
          maxValue: 3, 
          correctRate: 85,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        },
        { 
          caseId: 'CASE_B', 
          detailCount: 200, 
          maxValue: 5, 
          correctRate: 65,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        },
        { 
          caseId: 'CASE_C', 
          detailCount: 300, 
          maxValue: 8, 
          correctRate: 75,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 高准确率场景 ====================
  {
    id: 'RPT003',
    name: '高准确率场景',
    desc: '约95%准确率，用于测试高性能显示',
    config: {
      reportId: 'RPT003',
      taskId: 'TASK003',
      caseConfigs: [
        { 
          caseId: 'CASE_HIGH_ACC', 
          detailCount: 500, 
          maxValue: 6, 
          correctRate: 95,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 低准确率场景 ====================
  {
    id: 'RPT004',
    name: '低准确率场景',
    desc: '约40%准确率，用于测试警告显示',
    config: {
      reportId: 'RPT004',
      taskId: 'TASK004',
      caseConfigs: [
        { 
          caseId: 'CASE_LOW_ACC', 
          detailCount: 300, 
          maxValue: 4, 
          correctRate: 40,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 大规模数据场景 ====================
  {
    id: 'RPT005',
    name: '大规模数据',
    desc: '1000条数据，10分类，测试性能和渲染',
    config: {
      reportId: 'RPT005',
      taskId: 'TASK005',
      caseConfigs: [
        { 
          caseId: 'CASE_LARGE', 
          detailCount: 1000, 
          maxValue: 10, 
          correctRate: 72,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 小规模数据场景 ====================
  {
    id: 'RPT006',
    name: '小规模数据',
    desc: '50条数据，3分类，简单场景测试',
    config: {
      reportId: 'RPT006',
      taskId: 'TASK006',
      caseConfigs: [
        { 
          caseId: 'CASE_SMALL', 
          detailCount: 50, 
          maxValue: 3, 
          correctRate: 80,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 边界值场景 ====================
  {
    id: 'RPT007',
    name: '边界值测试',
    desc: '包含空数据、单分类等边界情况',
    config: {
      reportId: 'RPT007',
      taskId: 'TASK007',
      caseConfigs: [
        { 
          caseId: 'CASE_BINARY', 
          detailCount: 100, 
          maxValue: 2, 
          correctRate: 60,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        },
        { 
          caseId: 'CASE_SINGLE', 
          detailCount: 30, 
          maxValue: 1, 
          correctRate: 100,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 无效数据场景 ====================
  {
    id: 'RPT008',
    name: '无效数据测试',
    desc: '包含较多无效数据，测试过滤功能',
    config: {
      reportId: 'RPT008',
      taskId: 'TASK008',
      caseConfigs: [
        { 
          caseId: 'CASE_INVALID', 
          detailCount: 200, 
          maxValue: 4, 
          correctRate: 70,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        }
      ]
    }
  },
  
  // ==================== 稀疏矩阵场景 ====================
  {
    id: 'RPT009',
    name: '稀疏矩阵测试',
    desc: '使用策略2，只显示出现的分类值(>0)',
    config: {
      reportId: 'RPT009',
      taskId: 'TASK009',
      caseConfigs: [
        { 
          caseId: 'CASE_SPARSE_1', 
          detailCount: 200, 
          maxValue: 10, 
          correctRate: 75,
          matrixStrategy: '2',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER,
          validValues: [1, 3, 5, 7, 9]  // 只使用这些不连续的值（都>0）
        },
        { 
          caseId: 'CASE_SPARSE_2', 
          detailCount: 150, 
          maxValue: 8, 
          correctRate: 80,
          matrixStrategy: '2',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER,
          validValues: [1, 2, 4, 6, 8]  // 另一组不连续的值（都>0）
        }
      ]
    }
  },
  
  // ==================== 混合策略场景 ====================
  {
    id: 'RPT010',
    name: '混合策略测试',
    desc: '同一报告中包含完整矩阵和稀疏矩阵',
    config: {
      reportId: 'RPT010',
      taskId: 'TASK010',
      caseConfigs: [
        {
          caseId: 'CASE_FULL',
          detailCount: 180,
          maxValue: 5,
          correctRate: 72,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER
        },
        {
          caseId: 'CASE_SPARSE',
          detailCount: 150,
          maxValue: 10,
          correctRate: 78,
          matrixStrategy: '2',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER,
          validValues: [1, 3, 5, 8, 10]  // 都>0
        }
      ]
    }
  },

  // ==================== 包含0值场景（新增） ====================
  {
    id: 'RPT011',
    name: '包含0值场景',
    desc: '包含值为0的分类，测试总召回率和总精准率排除逻辑',
    config: {
      reportId: 'RPT011',
      taskId: 'TASK011',
      caseConfigs: [
        {
          caseId: 'CASE_WITH_ZERO',
          detailCount: 250,
          maxValue: 5,
          correctRate: 75,
          matrixStrategy: '1',
          minValueFilter: -1,  // 设为-1以包含0值
          validValues: [0, 1, 2, 3, 4, 5]  // 包含0
        }
      ]
    }
  },

  // ==================== 自定义标签场景（新增） ====================
  {
    id: 'RPT012',
    name: '自定义坐标轴标签',
    desc: '测试自定义"实际\\预测"标签功能',
    config: {
      reportId: 'RPT012',
      taskId: 'TASK012',
      caseConfigs: [
        {
          caseId: 'CASE_CUSTOM_LABEL',
          detailCount: 200,
          maxValue: 5,
          correctRate: 70,
          matrixStrategy: '1',
          minValueFilter: DEFAULT_MIN_VALUE_FILTER,
          axisLabel: '真实\\预测'  // 自定义标签
        }
      ]
    }
  }
]

// ==================== 导出函数 ====================

/**
 * 根据报告ID和任务ID获取Mock数据
 * 
 * @param {string} reportId - 报告ID（用于匹配场景）
 * @param {string} taskId - 任务ID
 * @returns {Promise<Object>} 模拟的API响应数据
 * 
 * @example
 * const data = await getMockData('RPT001', 'TASK001')
 */
export const getMockData = async (reportId, taskId) => {
  // 模拟网络延迟
  await new Promise(resolve => setTimeout(resolve, 300 + Math.random() * 500))
  
  // 查找匹配的场景
  const scenario = mockScenarios.find(s => s.id === reportId)
  
  if (scenario) {
    // 使用场景配置生成数据
    return generateMockReport({
      ...scenario.config,
      taskId: taskId || scenario.config.taskId
    })
  }
  
  // 默认场景：使用基础配置
  return generateMockReport({
    reportId,
    taskId,
    caseConfigs: [
      { 
        caseId: 'DEFAULT_CASE', 
        detailCount: 100, 
        maxValue: 5, 
        correctRate: 70,
        matrixStrategy: '1',
        minValueFilter: DEFAULT_MIN_VALUE_FILTER
      }
    ]
  })
}

/**
 * 获取所有可用的Mock场景列表
 * 
 * @returns {Object[]} 场景列表（id, name, desc）
 * 
 * @example
 * const scenarios = getMockScenarioList()
 * // [{ id: 'RPT001', name: '基础场景', desc: '...' }, ...]
 */
export const getMockScenarioList = () => {
  return mockScenarios.map(s => ({
    id: s.id,
    name: s.name,
    desc: s.desc
  }))
}

/**
 * 根据场景ID获取场景详情
 * 
 * @param {string} scenarioId - 场景ID
 * @returns {Object|null} 场景详情或null
 */
export const getScenarioById = (scenarioId) => {
  return mockScenarios.find(s => s.id === scenarioId) || null
}
