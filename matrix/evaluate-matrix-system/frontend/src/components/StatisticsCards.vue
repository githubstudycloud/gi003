<template>
  <div class="stats-cards">
    <!-- 总样本数 -->
    <div class="stat-card total">
      <div class="stat-value">{{ statistics.totalCount || 0 }}</div>
      <div class="stat-label">总样本数</div>
      <div class="stat-icon">📋</div>
    </div>
    
    <!-- 有效样本数 -->
    <div class="stat-card valid">
      <div class="stat-value">{{ statistics.validCount || 0 }}</div>
      <div class="stat-label">有效样本数</div>
      <div class="stat-icon">✅</div>
    </div>
    
    <!-- 预测正确数 -->
    <div class="stat-card correct">
      <div class="stat-value">{{ statistics.correctCount || 0 }}</div>
      <div class="stat-label">预测正确数</div>
      <div class="stat-icon">🎯</div>
    </div>
    
    <!-- 预测错误数 -->
    <div class="stat-card error">
      <div class="stat-value">{{ errorCount }}</div>
      <div class="stat-label">预测错误数</div>
      <div class="stat-icon">❌</div>
    </div>
    
    <!-- 准确率 -->
    <div class="stat-card accuracy">
      <div class="stat-value">{{ formatPercent(statistics.accuracy) }}</div>
      <div class="stat-label">准确率</div>
      <div class="stat-icon">📊</div>
    </div>
  </div>
</template>

<script setup>
/**
 * 统计卡片组件
 * 
 * 功能：
 * 展示混淆矩阵的核心统计指标：
 * - 总样本数
 * - 有效样本数（排除非数字数据）
 * - 预测正确数
 * - 预测错误数
 * - 准确率
 * 
 * @author AI Assistant
 * @version 1.0.0
 */

import { computed } from 'vue'

// ==================== Props 定义 ====================
const props = defineProps({
  /** 统计数据对象 */
  statistics: {
    type: Object,
    default: () => ({
      totalCount: 0,
      validCount: 0,
      correctCount: 0,
      accuracy: 0,
      invalidCount: 0
    })
  }
})

// ==================== 计算属性 ====================

/**
 * 预测错误数 = 有效样本数 - 预测正确数
 */
const errorCount = computed(() => {
  const valid = props.statistics.validCount || 0
  const correct = props.statistics.correctCount || 0
  return valid - correct
})

// ==================== 方法 ====================

/**
 * 格式化百分比
 * @param {number} value - 百分比值
 * @returns {string} 格式化后的百分比字符串
 */
const formatPercent = (value) => {
  if (value === undefined || value === null) return '0.00%'
  return (Math.round(value * 100) / 100).toFixed(2) + '%'
}
</script>

<style scoped>
/* ==================== 卡片容器 ==================== */
.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

/* ==================== 单个卡片基础样式 ==================== */
.stat-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  position: relative;
  overflow: hidden;
  transition: transform 0.2s, box-shadow 0.2s;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.12);
}

/* ==================== 卡片内容样式 ==================== */
.stat-value {
  font-size: 32px;
  font-weight: bold;
  line-height: 1.2;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #606266;
}

.stat-icon {
  position: absolute;
  top: 10px;
  right: 10px;
  font-size: 24px;
  opacity: 0.8;
}

/* ==================== 卡片颜色主题 ==================== */

/* 总样本数 - 蓝色 */
.stat-card.total {
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
  border-left: 4px solid #2196F3;
}
.stat-card.total .stat-value {
  color: #1565C0;
}

/* 有效样本数 - 青色 */
.stat-card.valid {
  background: linear-gradient(135deg, #e0f7fa 0%, #b2ebf2 100%);
  border-left: 4px solid #00BCD4;
}
.stat-card.valid .stat-value {
  color: #00838F;
}

/* 预测正确数 - 绿色 */
.stat-card.correct {
  background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
  border-left: 4px solid #4CAF50;
}
.stat-card.correct .stat-value {
  color: #2E7D32;
}

/* 预测错误数 - 红色 */
.stat-card.error {
  background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
  border-left: 4px solid #F44336;
}
.stat-card.error .stat-value {
  color: #C62828;
}

/* 准确率 - 紫色 */
.stat-card.accuracy {
  background: linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%);
  border-left: 4px solid #9C27B0;
}
.stat-card.accuracy .stat-value {
  color: #6A1B9A;
}

/* ==================== 响应式适配 ==================== */
@media (max-width: 768px) {
  .stats-cards {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .stat-value {
    font-size: 24px;
  }
}

@media (max-width: 480px) {
  .stats-cards {
    grid-template-columns: 1fr;
  }
}
</style>

