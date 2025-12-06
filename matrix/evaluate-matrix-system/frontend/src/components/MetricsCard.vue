<template>
  <el-card class="metrics-card" shadow="hover">
    <template #header>
      <div class="card-header">
        <span>📈 用例详情与指标</span>
        <el-tag size="small" :type="caseData.caseConfig.matrixStrategy === '2' ? 'success' : 'primary'">
          {{ caseData.caseConfig.matrixStrategy === '2' ? '稀疏矩阵' : '完整矩阵' }}
        </el-tag>
      </div>
    </template>
    
    <el-descriptions :column="3" border>
      <!-- 用例基本信息 -->
      <el-descriptions-item label="用例ID">
        {{ caseData.caseConfig.caseId }}
      </el-descriptions-item>
      <el-descriptions-item label="报告ID">
        {{ caseData.caseConfig.reportId }}
      </el-descriptions-item>
      <el-descriptions-item label="任务ID">
        {{ caseData.caseConfig.taskId }}
      </el-descriptions-item>
      
      <!-- 字段配置信息 -->
      <el-descriptions-item label="实际值字段">
        {{ caseData.caseConfig.acturalValueField || '-' }}
      </el-descriptions-item>
      <el-descriptions-item label="预测值字段">
        {{ caseData.caseConfig.predictedValueField || '-' }}
      </el-descriptions-item>
      <el-descriptions-item label="描述值字段">
        {{ caseData.caseConfig.descValueField || '-' }}
      </el-descriptions-item>
      
      <!-- 核心统计指标 -->
      <el-descriptions-item label="总样本数">
        <span class="metric-value">{{ statistics.totalCount || 0 }}</span>
      </el-descriptions-item>
      <el-descriptions-item label="有效样本数">
        <span class="metric-value valid">{{ statistics.validCount || 0 }}</span>
        <span class="metric-hint" v-if="statistics.invalidCount > 0">
          (无效: {{ statistics.invalidCount }})
        </span>
      </el-descriptions-item>
      <el-descriptions-item label="预测正确数">
        <span class="metric-value correct">{{ statistics.correctCount || 0 }}</span>
      </el-descriptions-item>
      
      <!-- 准确率指标（统一术语） -->
      <el-descriptions-item label="准确率">
        <el-progress 
          :percentage="Math.round(statistics.accuracy || 0)" 
          :color="getProgressColor(statistics.accuracy)"
          :stroke-width="16"
          style="width: 150px"
        />
      </el-descriptions-item>
      <el-descriptions-item label="平均精准率">
        <el-progress 
          :percentage="Math.round(statistics.avgPrecision || 0)" 
          :color="getProgressColor(statistics.avgPrecision)"
          :stroke-width="16"
          style="width: 150px"
        />
      </el-descriptions-item>
      <el-descriptions-item label="平均召回率">
        <el-progress 
          :percentage="Math.round(statistics.avgRecall || 0)" 
          :color="getProgressColor(statistics.avgRecall)"
          :stroke-width="16"
          style="width: 150px"
        />
      </el-descriptions-item>
      
      <!-- 矩阵信息 -->
      <el-descriptions-item label="矩阵大小">
        {{ matrixSize }}
      </el-descriptions-item>
      <el-descriptions-item label="矩阵策略">
        {{ caseData.caseConfig.matrixStrategy === '2' ? '稀疏矩阵(仅显示出现的值)' : '完整矩阵(正方形)' }}
      </el-descriptions-item>
      <el-descriptions-item label="创建时间">
        {{ formatTime(caseData.caseConfig.createTime) }}
      </el-descriptions-item>
    </el-descriptions>
    
    <!-- 详细指标卡片 -->
    <div class="detail-metrics">
      <div class="detail-metrics-title">📊 详细指标</div>
      <div class="detail-metrics-cards">
        <!-- 最高召回率 -->
        <div class="detail-card" :class="getMetricCardClass(statistics.maxRecall)">
          <div class="detail-label">最高召回率</div>
          <div class="detail-value">{{ formatPercent(statistics.maxRecall) }}</div>
          <div class="detail-desc">{{ getMetricLevel(statistics.maxRecall) }}</div>
        </div>
        <!-- 最低召回率 -->
        <div class="detail-card" :class="getMetricCardClass(statistics.minRecall)">
          <div class="detail-label">最低召回率</div>
          <div class="detail-value">{{ formatPercent(statistics.minRecall) }}</div>
          <div class="detail-desc">{{ getMetricLevel(statistics.minRecall) }}</div>
        </div>
        <!-- 最高精准率 -->
        <div class="detail-card" :class="getMetricCardClass(statistics.maxPrecision)">
          <div class="detail-label">最高精准率</div>
          <div class="detail-value">{{ formatPercent(statistics.maxPrecision) }}</div>
          <div class="detail-desc">{{ getMetricLevel(statistics.maxPrecision) }}</div>
        </div>
        <!-- 最低精准率 -->
        <div class="detail-card" :class="getMetricCardClass(statistics.minPrecision)">
          <div class="detail-label">最低精准率</div>
          <div class="detail-value">{{ formatPercent(statistics.minPrecision) }}</div>
          <div class="detail-desc">{{ getMetricLevel(statistics.minPrecision) }}</div>
        </div>
      </div>
    </div>
    
    <!-- 指标说明 -->
    <div class="metrics-hint">
      <el-icon><InfoFilled /></el-icon>
      <span>
        <strong>准确率</strong> = 预测正确数 / 有效样本数；
        <strong>精准率</strong> = 每类预测正确数 / 该类预测总数；
        <strong>召回率</strong> = 每类预测正确数 / 该类实际总数
      </span>
    </div>
  </el-card>
</template>

<script setup>
/**
 * 指标详情卡片组件
 * 
 * 功能：
 * 展示用例的详细配置信息和统计指标：
 * - 用例基本信息（ID、字段配置等）
 * - 核心统计指标（样本数、正确数等）
 * - 比例指标（准确率、精准率、召回率）
 * - 详细指标（最高/最低精准率、召回率）
 * - 矩阵信息（大小、策略等）
 * 
 * @author AI Assistant
 * @version 1.1.0
 */

import { computed } from 'vue'
import { InfoFilled } from '@element-plus/icons-vue'

// ==================== Props 定义 ====================
const props = defineProps({
  /** 用例数据对象 */
  caseData: {
    type: Object,
    required: true
  }
})

// ==================== 计算属性 ====================

/**
 * 统计数据快捷访问
 */
const statistics = computed(() => props.caseData.statistics || {})

/**
 * 矩阵大小描述
 */
const matrixSize = computed(() => {
  const max = statistics.value.matrixMax || 0
  if (props.caseData.caseConfig.matrixStrategy === '2') {
    // 稀疏矩阵：实际显示的唯一值数量
    return `动态 (唯一值数量: ${statistics.value.uniqueValueCount || 'N/A'})`
  }
  return `${max + 1} x ${max + 1}`
})

// ==================== 方法 ====================

/**
 * 获取进度条颜色
 * @param {number} value - 百分比值
 * @returns {string} 颜色代码
 */
const getProgressColor = (value) => {
  if (value >= 90) return '#67C23A'  // 绿色
  if (value >= 70) return '#E6A23C'  // 橙色
  return '#F56C6C'  // 红色
}

/**
 * 获取指标卡片样式类
 * @param {number} value - 百分比值
 * @returns {string} 样式类名
 */
const getMetricCardClass = (value) => {
  if (value >= 90) return 'level-high'
  if (value >= 70) return 'level-medium'
  if (value >= 50) return 'level-low'
  return 'level-danger'
}

/**
 * 获取指标等级描述
 * @param {number} value - 百分比值
 * @returns {string} 等级描述
 */
const getMetricLevel = (value) => {
  if (value >= 90) return '优秀'
  if (value >= 70) return '良好'
  if (value >= 50) return '中等'
  if (value >= 30) return '较低'
  return '极低'
}

/**
 * 格式化百分比
 * @param {number} value - 百分比值
 * @returns {string} 格式化后的百分比
 */
const formatPercent = (value) => {
  if (value === undefined || value === null) return '0.00%'
  return (Math.round(value * 100) / 100).toFixed(2) + '%'
}

/**
 * 格式化时间
 * @param {string} time - 时间字符串
 * @returns {string} 格式化后的时间
 */
const formatTime = (time) => {
  if (!time) return '-'
  return time.replace('T', ' ').slice(0, 19)
}
</script>

<style scoped>
/* ==================== 卡片样式 ==================== */
.metrics-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* ==================== 指标值样式 ==================== */
.metric-value {
  font-weight: bold;
  font-size: 16px;
}

.metric-value.valid {
  color: #00838F;
}

.metric-value.correct {
  color: #2E7D32;
}

.metric-hint {
  font-size: 12px;
  color: #909399;
  margin-left: 8px;
}

/* ==================== 详细指标卡片 ==================== */
.detail-metrics {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid #ebeef5;
}

.detail-metrics-title {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 12px;
}

.detail-metrics-cards {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.detail-card {
  padding: 16px;
  border-radius: 8px;
  text-align: center;
  transition: transform 0.2s;
}

.detail-card:hover {
  transform: translateY(-2px);
}

.detail-label {
  font-size: 12px;
  color: #909399;
  margin-bottom: 8px;
}

.detail-value {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 4px;
}

.detail-desc {
  font-size: 12px;
}

/* 等级样式 */
.level-high {
  background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
  border: 1px solid #a5d6a7;
}
.level-high .detail-value { color: #2E7D32; }
.level-high .detail-desc { color: #4CAF50; }

.level-medium {
  background: linear-gradient(135deg, #fff3e0 0%, #ffe0b2 100%);
  border: 1px solid #ffcc80;
}
.level-medium .detail-value { color: #E65100; }
.level-medium .detail-desc { color: #FF9800; }

.level-low {
  background: linear-gradient(135deg, #fff8e1 0%, #ffecb3 100%);
  border: 1px solid #ffe082;
}
.level-low .detail-value { color: #F57F17; }
.level-low .detail-desc { color: #FFC107; }

.level-danger {
  background: linear-gradient(135deg, #ffebee 0%, #ffcdd2 100%);
  border: 1px solid #ef9a9a;
}
.level-danger .detail-value { color: #C62828; }
.level-danger .detail-desc { color: #F44336; }

/* ==================== 指标说明样式 ==================== */
.metrics-hint {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-top: 16px;
  padding: 12px;
  background: #f5f7fa;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
  line-height: 1.6;
}

.metrics-hint .el-icon {
  flex-shrink: 0;
  margin-top: 2px;
  color: #409EFF;
}

/* ==================== 响应式适配 ==================== */
@media (max-width: 992px) {
  .detail-metrics-cards {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 576px) {
  .detail-metrics-cards {
    grid-template-columns: 1fr;
  }
  
  :deep(.el-descriptions__label) {
    width: 80px !important;
  }
}
</style>
