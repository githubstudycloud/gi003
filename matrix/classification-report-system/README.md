# 分类预测统计报表系统

一个功能完善的**分类预测统计报表系统**，支持混淆矩阵分析、召回率/精准率计算、多维度数据筛选、Excel导出和Web可视化展示。

## ✨ 核心功能

### 📊 数据模型
- **一级分类** & **二级分类** 双层分类体系
- **预期值** & **实际值** (范围: 0-15)
- **状态判断**: 自动识别 Pass/Fail
- **多维度标签**: 用例、场景、垂类、因子、因子值

### 🔍 数据筛选
支持以下维度的灵活筛选：
- 用例 (Use Case)
- 场景 (Scenario)
- 垂类 (Vertical)
- 因子 (Factor)
- 因子值 (Factor Value)
- 一级分类 / 二级分类

### 📈 混淆矩阵报表
生成专业的16x16混淆矩阵（0-15分类值），包含：
- **精准率 (Precision)**: 预测为X且实际为X / 预测为X的总数
- **召回率 (Recall)**: 实际为X且预测为X / 实际为X的总数
- **按一级分类分组**: 每个一级分类独立生成混淆矩阵
- **总体统计**: 全局混淆矩阵和准确率

### 📥 Excel导出
- **多Sheet导出**:
  - 汇总统计
  - 总体混淆矩阵
  - 各一级分类混淆矩阵
  - 详细数据列表
- **样式优化**: 表头着色、对角线高亮、条件格式
- **简化导出**: 快速导出数据列表

### 🌐 Web界面
- **响应式设计**: 适配PC和移动端
- **交互式筛选**: 下拉菜单动态筛选
- **标签页切换**: 总体/分类矩阵快速切换
- **实时统计**: 自动计算汇总指标
- **一键导出**: 在线生成并下载Excel

## 📁 项目结构

```
classification-report-system/
│
├── data_model.py              # 数据模型定义
│   ├── ClassificationRecord   # 分类记录类
│   ├── FilterCriteria         # 筛选条件类
│   └── DataRepository         # 数据仓库类
│
├── confusion_matrix.py        # 混淆矩阵生成器
│   ├── ConfusionMatrixGenerator  # 矩阵计算
│   ├── ReportFormatter           # 报表格式化
│   └── generate_report_from_repository  # 快捷函数
│
├── excel_exporter.py          # Excel导出器
│   └── ExcelExporter          # 多Sheet导出
│
├── web_app.py                 # Flask Web应用
│   ├── /api/data/upload              # 上传数据
│   ├── /api/data/generate-sample     # 生成示例
│   ├── /api/filters/options          # 筛选选项
│   ├── /api/report/generate          # 生成报表
│   ├── /api/export/excel             # 导出Excel
│   └── /api/data/detail              # 详细数据
│
├── templates/
│   └── index.html             # Web界面
│
├── example_usage.py           # 使用示例
├── requirements.txt           # 依赖列表
└── README.md                  # 说明文档
```

## 🚀 快速开始

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

### 2. 运行示例代码

```bash
python example_usage.py
```

这将运行6个示例，展示系统的各种功能：
- 示例1: 基本使用 - 生成控制台报表
- 示例2: 筛选特定用例和场景的报表
- 示例3: 导出Excel报表
- 示例4: 自定义分析 - 直接使用混淆矩阵数据
- 示例5: 数据探索 - 各维度统计
- 示例6: 手动创建测试记录

### 3. 启动Web服务

```bash
python web_app.py
```

然后访问: http://localhost:5000

## 💻 代码示例

### 基本使用

```python
from data_model import DataRepository, ClassificationRecord
from confusion_matrix import generate_report_from_repository

# 创建数据仓库
repository = DataRepository()

# 添加测试记录
record = ClassificationRecord(
    primary_category="电商",
    secondary_category="首页",
    expected_value=5,
    actual_value=5,
    status="pass",
    use_case="商品推荐",
    scenario="移动端",
    vertical="零售",
    factor="网络状态",
    factor_value="良好",
    test_id="TEST_001"
)
repository.add_record(record)

# 生成报表
report = generate_report_from_repository(repository)
print(report)
```

### 数据筛选

```python
from data_model import FilterCriteria

# 设置筛选条件
criteria = FilterCriteria(
    primary_category="电商",
    scenario="移动端",
    use_case="商品推荐"
)

# 生成筛选后的报表
report = generate_report_from_repository(repository, criteria)
print(report)
```

### 导出Excel

```python
from excel_exporter import ExcelExporter

# 创建导出器
exporter = ExcelExporter(repository)

# 导出完整报表（多Sheet）
exporter.export_full_report("report.xlsx")

# 导出筛选后的报表
criteria = FilterCriteria(vertical="零售")
exporter.export_full_report("report_filtered.xlsx", criteria)

# 导出简单数据列表
exporter.export_simple_excel("data.xlsx")
```

### Web API使用

```bash
# 生成示例数据
curl -X POST http://localhost:5000/api/data/generate-sample \
  -H "Content-Type: application/json" \
  -d '{"count": 200}'

# 生成报表
curl -X POST http://localhost:5000/api/report/generate \
  -H "Content-Type: application/json" \
  -d '{
    "use_case": "用户登录",
    "scenario": "移动端"
  }'

# 导出Excel
curl -X POST http://localhost:5000/api/export/excel \
  -H "Content-Type: application/json" \
  -d '{"primary_category": "电商"}' \
  --output report.xlsx
```

## 📊 混淆矩阵说明

### 表格结构

```
实际\预测 | 预测0 | 预测1 | ... | 预测15 | SUM | 召回率
----------|-------|-------|-----|--------|-----|--------
实际0     |   10  |   2   | ... |   0    | 12  | 83.33%
实际1     |   1   |   15  | ... |   0    | 16  | 93.75%
...       |  ...  |  ...  | ... |  ...   | ... | ...
实际15    |   0   |   0   | ... |   8    | 8   | 100.00%
----------|-------|-------|-----|--------|-----|--------
SUM       |   15  |   20  | ... |   10   | 500 | -
精准率    | 66.67%| 75.00%| ... | 80.00% | -   | -
```

### 指标说明

- **精准率 (Precision)**:
  ```
  预测为X且实际为X的数量 / 预测为X的总数
  ```
  衡量预测的准确性

- **召回率 (Recall)**:
  ```
  实际为X且预测为X的数量 / 实际为X的总数
  ```
  衡量预测的完整性

- **准确率 (Accuracy)**:
  ```
  预测正确的总数 / 总记录数
  ```
  整体预测准确度

## 🎨 Web界面特性

### 筛选功能
- 7个维度的下拉筛选器
- 实时筛选条件组合
- 一键重置筛选

### 报表展示
- 汇总卡片: 总记录数、通过数、失败数、准确率
- 标签页切换: 总体 / 各一级分类
- 混淆矩阵: 对角线高亮显示正确预测
- 自适应布局: 16x16矩阵自动适配屏幕

### 数据操作
- 生成示例数据 (可自定义数量)
- 在线生成报表
- 导出Excel文件
- 响应式设计

## 📝 数据字段说明

| 字段 | 类型 | 说明 | 必填 |
|------|------|------|------|
| primary_category | string | 一级分类 | ✅ |
| secondary_category | string | 二级分类 | ✅ |
| expected_value | int | 预期值 (0-15) | ✅ |
| actual_value | int | 实际值 (0-15) | ✅ |
| status | string | pass/fail (自动计算) | ✅ |
| use_case | string | 用例 | ✅ |
| scenario | string | 场景 | ✅ |
| vertical | string | 垂类 | ✅ |
| factor | string | 因子 | ✅ |
| factor_value | string | 因子值 | ✅ |
| timestamp | string | 时间戳 | ❌ |
| test_id | string | 测试ID | ❌ |
| notes | string | 备注 | ❌ |

## 🔧 高级用法

### 自定义混淆矩阵分析

```python
from confusion_matrix import ConfusionMatrixGenerator

# 获取筛选后的记录
criteria = FilterCriteria(use_case="用户登录")
records = repository.filter_records(criteria)

# 生成混淆矩阵
generator = ConfusionMatrixGenerator(records)
report_data = generator.generate_detailed_report()

# 访问原始数据
overall = report_data["overall"]
matrix = overall["matrix"]  # 16x16 numpy数组
precision = overall["precision"]  # 精准率列表
recall = overall["recall"]  # 召回率列表

# 按一级分类查看
by_category = report_data["by_primary_category"]
for category, data in by_category.items():
    print(f"{category}: 准确率 = {data['accuracy']}%")
```

### 数据导入/导出JSON

```python
import json

# 导出到JSON
records = repository.get_all_records()
data = [record.to_dict() for record in records]
with open("data.json", "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

# 从JSON导入
with open("data.json", "r", encoding="utf-8") as f:
    data = json.load(f)

for record_data in data:
    record = ClassificationRecord.from_dict(record_data)
    repository.add_record(record)
```

## 🎯 应用场景

1. **机器学习模型评估**: 评估分类模型的预测效果
2. **A/B测试分析**: 对比不同策略的分类准确性
3. **推荐系统评测**: 分析推荐结果的分类分布
4. **质量检测报告**: 生成产品质量分类检测报告
5. **用户行为分析**: 预测vs实际用户行为分类对比

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📧 联系方式

如有问题或建议，请联系项目维护者。

---

**Generated with Claude Code** 🤖
