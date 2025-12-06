# 🎯 混淆矩阵评估系统

基于 Spring Boot 2.7 + MyBatis Plus + Vue 3 + Element Plus 的分类预测混淆矩阵评估报表系统。

## 📋 功能特性

### V1 版本（当前）
- ✅ 混淆矩阵报表展示
- ✅ 多用例（Case）Tab页支持
- ✅ 统计卡片：总样本数、**有效样本数**、预测正确/错误数、准确率、召回率
- ✅ 详细指标：最高/最低召回率、最高/最低精准率
- ✅ 使用 el-table 实现二维矩阵表格
- ✅ 单元格点击弹窗查看详细数据
- ✅ 非数字值过滤（有效样本统计）
- ✅ 示例数据加载

### V2 版本（规划中）
- 📋 用例列表页面
- 📋 用例详情列表页面
- 📋 单元格点击跳转详情页（带参数筛选）
- 📋 mark表数据转换

## 📁 项目结构

```
evaluate-matrix-system/
├── sql/                              # 数据库脚本
│   └── schema.sql                    # 建表语句和测试数据
│
├── backend/                          # Spring Boot 后端
│   ├── pom.xml                       # Maven配置
│   └── src/main/
│       ├── java/com/example/matrix/
│       │   ├── MatrixApplication.java    # 启动类
│       │   ├── controller/               # 控制器
│       │   │   └── MatrixReportController.java
│       │   ├── service/                  # 服务层
│       │   │   └── MatrixReportService.java
│       │   ├── mapper/                   # MyBatis Mapper
│       │   │   ├── MatrixParamMapper.java
│       │   │   ├── MatrixDetailMapper.java
│       │   │   └── MatrixMarkMapper.java
│       │   ├── entity/                   # 实体类
│       │   │   ├── MatrixParam.java
│       │   │   ├── MatrixDetail.java
│       │   │   └── MatrixMark.java
│       │   └── vo/                       # 视图对象
│       │       ├── Result.java
│       │       ├── MatrixReportVO.java
│       │       └── MatrixQueryRequest.java
│       └── resources/
│           └── application.yml           # 配置文件
│
├── frontend/                         # Vue 3 前端
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   └── src/
│       ├── main.js
│       ├── App.vue
│       ├── api/
│       │   └── matrix.js             # API封装
│       ├── components/
│       │   └── ConfusionMatrix.vue   # 混淆矩阵组件
│       └── views/
│           └── MatrixReport.vue      # 报告页面
│
└── README.md
```

## 🗄️ 数据库设计

### MySQL 5.7

#### 1. task_evaluate_matrix_param（参数配置表）
| 字段 | 类型 | 说明 |
|------|------|------|
| report_id | VARCHAR(64) | 报告ID（主键） |
| task_id | VARCHAR(64) | 任务ID（主键） |
| case_id | VARCHAR(64) | 用例ID（主键） |
| actural_value_field | VARCHAR(128) | 实际值字段名 |
| predicted_value_field | VARCHAR(128) | 预测值字段名 |
| desc_value_field | VARCHAR(128) | 描述值字段名 |
| matrix_strategy | VARCHAR(64) | 矩阵策略 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

#### 2. task_evaluate_matrix_detail（详情数据表）
| 字段 | 类型 | 说明 |
|------|------|------|
| report_id | VARCHAR(64) | 报告ID（主键） |
| task_id | VARCHAR(64) | 任务ID（主键） |
| case_id | VARCHAR(64) | 用例ID（主键） |
| corpus_id | VARCHAR(128) | 语料ID（主键） |
| actural_value | VARCHAR(64) | 实际值 |
| predicted_value | VARCHAR(64) | 预测值 |
| desc_value | VARCHAR(255) | 描述值 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

#### 3. task_evaluate_matrix_mark（标记映射表，V2使用）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 自增主键 |
| case_id | VARCHAR(64) | 用例ID |
| indicate_id | VARCHAR(64) | 指标ID |
| value | VARCHAR(64) | 值 |
| desc_value | VARCHAR(255) | 描述值 |

## 🔌 API 接口

### 获取矩阵报告

**GET** `/api/matrix/report`

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| reportId | String | 是 | 报告ID |
| taskId | String | 是 | 任务ID |

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "caseConfig": {
        "reportId": "RPT001",
        "taskId": "TASK001",
        "caseId": "CASE001",
        "acturalValueField": "actual_level",
        "predictedValueField": "predict_level",
        "descValueField": "level_name",
        "matrixStrategy": "auto"
      },
      "detailList": [
        {
          "reportId": "RPT001",
          "taskId": "TASK001",
          "caseId": "CASE001",
          "corpusId": "C001",
          "acturalValue": "0",
          "predictedValue": "0",
          "descValue": "极低"
        }
      ],
      "markList": [
        { "id": "0", "value": "0", "desc": "极低" }
      ],
      "statistics": {
        "totalCount": 34,
        "validCount": 30,
        "invalidCount": 4,
        "correctCount": 24,
        "wrongCount": 6,
        "accuracy": 80.0,
        "recall": 80.0,
        "matrixMax": 9
      }
    }
  ]
}
```

## 🚀 快速开始

### 1. 数据库初始化

```bash
# 创建数据库
mysql -u root -p
CREATE DATABASE evaluate_matrix DEFAULT CHARACTER SET utf8mb4;
USE evaluate_matrix;

# 执行建表脚本
source sql/schema.sql;
```

### 2. 启动后端

```bash
cd backend

# 修改数据库配置
# vim src/main/resources/application.yml

# 启动
mvn spring-boot:run
```

### 3. 启动前端

```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

### 4. 访问系统

打开浏览器访问：http://localhost:3000

## 📊 有效样本说明

系统会自动过滤无效数据：
- `actural_value` 为空、NULL、非数字 → **无效**
- `predicted_value` 为空、NULL、非数字 → **无效**

只有 **两个值都是有效数字** 的记录才会参与矩阵统计。

## 🎨 界面预览

### 统计卡片
| 总样本数 | 有效样本数 | 预测正确数 | 预测错误数 | 准确率 | 召回率 |
|---------|-----------|-----------|-----------|-------|-------|
| 34 | 30 | 24 | 6 | 80% | 80% |

### 混淆矩阵
- 🟢 绿色对角线 = 预测正确
- 🟡 黄色单元格 = 预测错误
- ⚪ 灰色单元格 = 无数据

### 召回率/精准率颜色
- 🟢 绿色 ≥ 90%
- 🟠 橙色 70-90%
- 🔴 红色 < 70%

## 🔧 配置说明

### 后端配置 (application.yml)

```yaml
server:
  port: 8080
  servlet:
    context-path: /api

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/evaluate_matrix
    username: root
    password: root
```

### 前端配置 (vite.config.js)

```javascript
export default defineConfig({
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
})
```

## 📝 开发计划

### V2 功能规划
1. **用例列表页面** - 展示所有用例
2. **用例详情列表页面** - 展示用例的详细数据
3. **单元格点击增强**
   - 选项1：弹出列表框（当前已实现）
   - 选项2：跳转详情页并带参数筛选
4. **Mark表数据转换** - 将 actural_value 转换为 desc_value

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

