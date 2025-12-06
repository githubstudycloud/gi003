/**
 * 矩阵报告API模块
 * 
 * 功能：
 * 1. 提供与后端API通信的接口
 * 2. 支持Mock模式进行前端独立调试
 * 3. 统一的错误处理和响应格式
 * 
 * 使用方法：
 * import { getMatrixReport, isMockMode } from './api/matrix.js'
 * const data = await getMatrixReport(reportId, taskId)
 * 
 * @author AI Assistant
 * @version 1.0.0
 */

import { MOCK_ENABLED, getMockData } from '../mock/index.js'

// ==================== 配置常量 ====================

/**
 * 后端API基础地址
 * 
 * 开发环境：通过Vite代理转发到后端
 * 生产环境：需要配置为实际后端地址
 */
const API_BASE_URL = '/api'

// ==================== 工具函数 ====================

/**
 * 检查是否处于Mock模式
 * 
 * @returns {boolean} 是否启用Mock
 */
export const isMockMode = () => {
  return MOCK_ENABLED
}

/**
 * 通用请求封装
 * 
 * @param {string} url - 请求URL
 * @param {Object} options - fetch选项
 * @returns {Promise<Object>} 响应数据
 * @throws {Error} 请求失败时抛出错误
 */
const request = async (url, options = {}) => {
  try {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      },
      ...options
    })

    if (!response.ok) {
      throw new Error(`HTTP Error: ${response.status} ${response.statusText}`)
    }

    return await response.json()
  } catch (error) {
    console.error('[API Error]', error)
    throw error
  }
}

// ==================== API接口 ====================

/**
 * 获取矩阵报告数据
 * 
 * 根据报告ID和任务ID查询混淆矩阵报告数据。
 * Mock模式下使用模拟数据，否则调用真实后端API。
 * 
 * @param {string} reportId - 报告ID
 * @param {string} taskId - 任务ID
 * @returns {Promise<Object>} 报告数据
 * 
 * @example
 * const result = await getMatrixReport('RPT001', 'TASK001')
 * // result: {
 * //   code: 200,
 * //   message: 'success',
 * //   data: [
 * //     {
 * //       caseConfig: { ... },
 * //       detailList: [ ... ],
 * //       markList: [ ... ],
 * //       statistics: { ... }
 * //     }
 * //   ]
 * // }
 */
export const getMatrixReport = async (reportId, taskId) => {
  // Mock模式
  if (MOCK_ENABLED) {
    console.log('[Mock Mode] 获取报告数据:', { reportId, taskId })
    return getMockData(reportId, taskId)
  }

  // 真实API调用
  console.log('[API] 请求报告数据:', { reportId, taskId })
  return request(`${API_BASE_URL}/matrix/report`, {
    method: 'POST',
    body: JSON.stringify({ reportId, taskId })
  })
}

/**
 * 获取用例列表（预留接口）
 * 
 * V2版本功能：获取报告下所有用例的列表
 * 
 * @param {string} reportId - 报告ID
 * @param {string} taskId - 任务ID
 * @returns {Promise<Object>} 用例列表数据
 */
export const getCaseList = async (reportId, taskId) => {
  if (MOCK_ENABLED) {
    // TODO: 实现Mock数据
    return { code: 200, data: [] }
  }

  return request(`${API_BASE_URL}/matrix/cases`, {
    method: 'POST',
    body: JSON.stringify({ reportId, taskId })
  })
}

/**
 * 获取用例详情列表（预留接口）
 * 
 * V2版本功能：获取指定用例的详细记录，支持筛选
 * 
 * @param {Object} params - 查询参数
 * @param {string} params.reportId - 报告ID
 * @param {string} params.taskId - 任务ID
 * @param {string} params.caseId - 用例ID
 * @param {number} [params.actualValue] - 实际值筛选
 * @param {number} [params.predictedValue] - 预测值筛选
 * @param {number} [params.page] - 页码
 * @param {number} [params.pageSize] - 每页数量
 * @returns {Promise<Object>} 详情列表数据
 */
export const getCaseDetailList = async (params) => {
  if (MOCK_ENABLED) {
    // TODO: 实现Mock数据
    return { code: 200, data: [], total: 0 }
  }

  return request(`${API_BASE_URL}/matrix/details`, {
    method: 'POST',
    body: JSON.stringify(params)
  })
}

/**
 * 导出报告（预留接口）
 * 
 * V2版本功能：导出报告为Excel或PDF格式
 * 
 * @param {string} reportId - 报告ID
 * @param {string} taskId - 任务ID
 * @param {string} format - 导出格式 ('excel' | 'pdf')
 * @returns {Promise<Blob>} 文件数据
 */
export const exportReport = async (reportId, taskId, format = 'excel') => {
  if (MOCK_ENABLED) {
    console.warn('[Mock Mode] 导出功能在Mock模式下不可用')
    return null
  }

  const response = await fetch(`${API_BASE_URL}/matrix/export`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reportId, taskId, format })
  })

  if (!response.ok) {
    throw new Error('导出失败')
  }

  return response.blob()
}
