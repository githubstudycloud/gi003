<template>
  <div class="matrix-report">
    <!-- 头部 -->
    <header class="report-header">
      <h1>📊 混淆矩阵评估报告</h1>
      <p class="subtitle">分类预测混淆矩阵统计分析系统 v1.1</p>
      <el-tag v-if="isMock" type="warning" class="mock-tag">Mock模式</el-tag>
    </header>

    <!-- 查询表单 -->
    <el-card class="query-card">
      <template #header>
        <div class="card-header">
          <span>🔍 查询条件</span>
          <el-tag v-if="isMock" type="info" size="small">前端独立调试模式</el-tag>
        </div>
      </template>
      
      <el-form :model="queryForm" inline>
        <el-form-item label="报告ID">
          <el-select 
            v-if="isMock" 
            v-model="queryForm.reportId" 
            placeholder="选择Mock场景"
            style="width: 280px"
            @change="handleScenarioChange"
          >
            <el-option
              v-for="scenario in mockScenarios"
              :key="scenario.id"
              :label="`${scenario.id} - ${scenario.name}`"
              :value="scenario.id"
            >
              <div class="scenario-option">
                <span class="scenario-name">{{ scenario.id }} - {{ scenario.name }}</span>
                <span class="scenario-desc">{{ scenario.desc }}</span>
              </div>
            </el-option>
          </el-select>
          <el-input v-else v-model="queryForm.reportId" placeholder="请输入报告ID" style="width: 200px" />
        </el-form-item>
        <el-form-item label="任务ID">
          <el-input v-model="queryForm.taskId" placeholder="请输入任务ID" style="width: 200px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery" :loading="loading">
            <el-icon><Search /></el-icon>
            查询
          </el-button>
          <el-button @click="handleReset">
            <el-icon><Refresh /></el-icon>
            重置
          </el-button>
        </el-form-item>
      </el-form>

      <!-- Mock场景说明 -->
      <div v-if="isMock && selectedScenario" class="scenario-info">
        <el-alert
          :title="`当前场景: ${selectedScenario.name}`"
          :description="selectedScenario.desc"
          type="info"
          show-icon
          :closable="false"
        />
      </div>
    </el-card>

    <!-- 数据展示 -->
    <template v-if="reportData.length > 0">
      <!-- Tab页 - 多个Case -->
      <el-tabs v-model="activeTab" type="card" class="case-tabs">
        <el-tab-pane
          v-for="(caseData, index) in reportData"
          :key="caseData.caseConfig.caseId"
          :label="getCaseLabel(caseData, index)"
          :name="caseData.caseConfig.caseId"
        >
          <!-- 统计卡片 -->
          <StatisticsCards :statistics="caseData.statistics" />

          <!-- 无效数据提示 -->
          <el-alert
            v-if="caseData.statistics.invalidCount > 0"
            :title="`检测到 ${caseData.statistics.invalidCount} 条无效数据（非数字或值≤${caseData.statistics.minValueFilter || 0}），已从统计中排除`"
            type="warning"
            show-icon
            :closable="false"
            style="margin-bottom: 20px"
          />

          <!-- 详细指标 -->
          <MetricsCard :case-data="caseData" />

          <!-- 混淆矩阵表格 -->
          <el-card class="matrix-card">
            <template #header>
              <div class="matrix-header">
                <span>📊 混淆矩阵</span>
                <div class="header-actions">
                  <el-radio-group 
                    v-model="matrixStrategyMap[caseData.caseConfig.caseId]" 
                    size="small"
                    @change="(val) => handleStrategyChange(caseData.caseConfig.caseId, val)"
                  >
                    <el-radio-button label="1">完整矩阵</el-radio-button>
                    <el-radio-button label="2">稀疏矩阵</el-radio-button>
                  </el-radio-group>
                </div>
              </div>
            </template>
            <ConfusionMatrix
              :detail-list="caseData.detailList"
              :mark-list="caseData.markList"
              :statistics="caseData.statistics"
              :matrix-strategy="matrixStrategyMap[caseData.caseConfig.caseId] || caseData.caseConfig.matrixStrategy || '1'"
              :min-value-filter="caseData.caseConfig.minValueFilter || 0"
              @cell-click="handleCellClick"
            />
          </el-card>
        </el-tab-pane>
      </el-tabs>
    </template>

    <!-- 空状态 -->
    <el-empty v-else description="暂无数据，请选择场景并点击查询" />

    <!-- 详情弹窗 -->
    <el-dialog
      v-model="detailDialogVisible"
      :title="cellDetail.dialogTitle"
      width="80%"
      :close-on-click-modal="false"
    >
      <div class="detail-info">
        <el-descriptions :column="4" border>
          <el-descriptions-item label="实际值">{{ cellDetail.actual }}</el-descriptions-item>
          <el-descriptions-item label="预测值">{{ cellDetail.predicted }}</el-descriptions-item>
          <el-descriptions-item label="记录数">{{ cellDetail.count }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag v-if="cellDetail.type === 'cell'" :type="cellDetail.actual === cellDetail.predicted ? 'success' : 'danger'">
              {{ cellDetail.actual === cellDetail.predicted ? '预测正确' : '预测错误' }}
            </el-tag>
            <el-tag v-else type="info">汇总数据</el-tag>
          </el-descriptions-item>
        </el-descriptions>
      </div>
      <el-table :data="cellDetail.records" stripe border style="margin-top: 20px" max-height="400">
        <el-table-column prop="corpusId" label="语料ID" width="150" />
        <el-table-column prop="acturalValue" label="实际值" width="100" />
        <el-table-column prop="predictedValue" label="预测值" width="100" />
        <el-table-column prop="descValue" label="描述" min-width="120" />
        <el-table-column prop="createTime" label="创建时间" width="180" />
      </el-table>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
/**
 * 混淆矩阵报告页面
 * 
 * 功能：
 * 1. 支持多用例Tab页切换
 * 2. 统计卡片展示
 * 3. 混淆矩阵表格（支持策略切换）
 * 4. 单元格/合计行列点击查看详情
 * 5. 支持最小值过滤
 * 
 * @author AI Assistant
 * @version 1.1.0
 */

import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getMatrixReport, isMockMode } from '../api/matrix'
import { getMockScenarioList } from '../mock/index.js'
import ConfusionMatrix from '../components/ConfusionMatrix.vue'
import StatisticsCards from '../components/StatisticsCards.vue'
import MetricsCard from '../components/MetricsCard.vue'

// ==================== 状态定义 ====================

/** Mock模式检测 */
const isMock = ref(isMockMode())
const mockScenarios = ref([])

/** 查询表单 */
const queryForm = reactive({
  reportId: 'RPT001',
  taskId: 'TASK001'
})

/** 选中的场景 */
const selectedScenario = computed(() => {
  return mockScenarios.value.find(s => s.id === queryForm.reportId)
})

/** 加载状态 */
const loading = ref(false)
/** 报告数据 */
const reportData = ref([])
/** 当前激活的Tab */
const activeTab = ref('')
/** 矩阵策略映射 (caseId -> strategy) */
const matrixStrategyMap = reactive({})

/** 详情弹窗状态 */
const detailDialogVisible = ref(false)
const cellDetail = reactive({
  actual: 0,
  predicted: 0,
  count: 0,
  records: [],
  type: 'cell',
  dialogTitle: '🔍 单元格详细数据'
})

// ==================== 生命周期 ====================

onMounted(() => {
  if (isMock.value) {
    mockScenarios.value = getMockScenarioList()
    // 自动加载默认场景
    handleQuery()
  }
})

// ==================== 方法 ====================

/**
 * 场景变化处理
 */
const handleScenarioChange = () => {
  handleQuery()
}

/**
 * 策略变化处理
 */
const handleStrategyChange = (caseId, strategy) => {
  matrixStrategyMap[caseId] = strategy
}

/**
 * 查询数据
 */
const handleQuery = async () => {
  if (!queryForm.reportId || !queryForm.taskId) {
    ElMessage.warning('请输入报告ID和任务ID')
    return
  }

  loading.value = true
  try {
    const res = await getMatrixReport(queryForm.reportId, queryForm.taskId)
    reportData.value = res.data || []
    if (reportData.value.length > 0) {
      activeTab.value = reportData.value[0].caseConfig.caseId
      // 初始化每个case的矩阵策略
      reportData.value.forEach(caseData => {
        matrixStrategyMap[caseData.caseConfig.caseId] = caseData.caseConfig.matrixStrategy || '1'
      })
      ElMessage.success(`加载成功，共 ${reportData.value.length} 个用例`)
    } else {
      ElMessage.warning('未找到数据')
    }
  } catch (error) {
    ElMessage.error('查询失败: ' + error.message)
  } finally {
    loading.value = false
  }
}

/**
 * 重置表单
 */
const handleReset = () => {
  queryForm.reportId = 'RPT001'
  queryForm.taskId = 'TASK001'
  reportData.value = []
  activeTab.value = ''
}

/**
 * 获取Case标签
 */
const getCaseLabel = (caseData, index) => {
  return `用例${index + 1}: ${caseData.caseConfig.caseId}`
}

/**
 * 单元格/合计点击处理
 */
const handleCellClick = (data) => {
  cellDetail.actual = data.actual
  cellDetail.predicted = data.predicted
  cellDetail.count = data.count
  cellDetail.records = data.records
  cellDetail.type = data.type || 'cell'
  
  // 设置弹窗标题
  if (data.title) {
    cellDetail.dialogTitle = `🔍 ${data.title}`
  } else if (data.type === 'row-sum') {
    cellDetail.dialogTitle = `🔍 实际值=${data.actual} 的所有记录`
  } else if (data.type === 'col-sum') {
    cellDetail.dialogTitle = `🔍 预测值=${data.predicted} 的所有记录`
  } else {
    cellDetail.dialogTitle = '🔍 单元格详细数据'
  }
  
  detailDialogVisible.value = true
}
</script>

<style scoped>
/* ==================== 头部样式 ==================== */
.report-header {
  text-align: center;
  padding: 30px 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 8px;
  margin-bottom: 20px;
  position: relative;
}

.report-header h1 {
  font-size: 28px;
  margin-bottom: 8px;
}

.report-header .subtitle {
  font-size: 14px;
  opacity: 0.9;
}

.mock-tag {
  position: absolute;
  top: 10px;
  right: 10px;
}

/* ==================== 查询卡片样式 ==================== */
.query-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.scenario-option {
  display: flex;
  flex-direction: column;
}

.scenario-name {
  font-weight: 500;
}

.scenario-desc {
  font-size: 12px;
  color: #909399;
}

.scenario-info {
  margin-top: 16px;
}

/* ==================== Tab页样式 ==================== */
.case-tabs {
  margin-bottom: 20px;
}

/* ==================== 矩阵卡片样式 ==================== */
.matrix-card {
  margin-bottom: 20px;
}

.matrix-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* ==================== 弹窗样式 ==================== */
.detail-info {
  margin-bottom: 16px;
}
</style>
