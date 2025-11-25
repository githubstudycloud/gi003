# 使用指南

## 🎯 三种使用方式

### 方式1: 快速启动（推荐新手）

```bash
# 一键启动，自动生成示例数据和Web界面
python quick_start.py
```

然后访问: http://localhost:5000

### 方式2: 命令行使用

```bash
# 运行示例代码，查看控制台输出
python example_usage.py
```

### 方式3: 集成到你的项目

```python
from data_model import DataRepository, ClassificationRecord
from confusion_matrix import generate_report_from_repository
from excel_exporter import ExcelExporter

# 创建数据仓库
repo = DataRepository()

# 添加你的数据
record = ClassificationRecord(
    primary_category="你的一级分类",
    secondary_category="你的二级分类",
    expected_value=5,
    actual_value=4,
    status="fail",
    use_case="你的用例",
    scenario="你的场景",
    vertical="你的垂类",
    factor="你的因子",
    factor_value="你的因子值"
)
repo.add_record(record)

# 生成报表
report = generate_report_from_repository(repo)
print(report)

# 导出Excel
exporter = ExcelExporter(repo)
exporter.export_full_report("my_report.xlsx")
```

## 📊 混淆矩阵表格说明

### 样式示例

```
一级分类: 电商

实际\预测 | 预测0 | 预测1 | 预测2 | ... | 预测15 | SUM | 召回率(%)
----------|-------|-------|-------|-----|--------|-----|----------
实际0     |   45  |   3   |   1   | ... |   0    |  49 |  91.84
实际1     |   2   |   38  |   2   | ... |   0    |  42 |  90.48
实际2     |   1   |   1   |   40  | ... |   0    |  42 |  95.24
...       |  ...  |  ...  |  ...  | ... |  ...   | ... |  ...
实际15    |   0   |   0   |   0   | ... |   35   |  35 |  100.00
----------|-------|-------|-------|-----|--------|-----|----------
SUM       |   48  |   42  |   43  | ... |   35   | 500 |  -
精准率(%) | 93.75 | 90.48 | 93.02 | ... | 100.00 |  -  |  -
```

### 如何阅读

#### 1. 主体矩阵 (混淆矩阵)
- **行**: 实际值 (Actual Value)
- **列**: 预测值 (Expected/Predicted Value)
- **单元格数值**: 该组合出现的次数
- **对角线** (绿色高亮): 预测正确的数量

**例子**:
- `matrix[0][1] = 3` 表示: 实际值为0，但预测为1的有3条记录

#### 2. 右侧SUM列
- **含义**: 每个实际值的总样本数
- **公式**: `SUM[实际i] = Σ(matrix[i][所有j])`
- **例子**: `实际0的SUM=49` 表示实际值为0的记录总共有49条

#### 3. 右侧召回率列 (Recall %)
- **含义**: 对于实际值为X的样本，模型预测正确的比例
- **公式**: `Recall[i] = matrix[i][i] / SUM[实际i] × 100%`
- **例子**: `实际0的召回率=91.84%` 表示:
  - 实际值为0的有49条记录
  - 其中45条被正确预测为0
  - 召回率 = 45/49 ≈ 91.84%
- **意义**: 召回率高说明模型能有效识别出该类别

#### 4. 底部SUM行
- **含义**: 每个预测值的总次数
- **公式**: `SUM[预测j] = Σ(matrix[所有i][j])`
- **例子**: `预测0的SUM=48` 表示模型预测为0的记录总共有48条

#### 5. 底部精准率行 (Precision %)
- **含义**: 在预测为X的样本中，真正是X的比例
- **公式**: `Precision[j] = matrix[j][j] / SUM[预测j] × 100%`
- **例子**: `预测0的精准率=93.75%` 表示:
  - 模型预测为0的有48条记录
  - 其中45条实际值确实为0
  - 精准率 = 45/48 ≈ 93.75%
- **意义**: 精准率高说明模型预测该类别时很可靠

### 实际案例解读

假设你有一个电商推荐系统，预测用户兴趣等级(0-15)：

```
实际\预测 | 预测5 | 预测6 | 预测7
----------|-------|-------|-------
实际5     |   80  |   15  |   5      SUM=100  召回率=80%
实际6     |   10  |   70  |   20     SUM=100  召回率=70%
实际7     |   5   |   10  |   85     SUM=100  召回率=85%
----------|-------|-------|-------
SUM       |   95  |   95  |   110
精准率    | 84.2% | 73.7% | 77.3%
```

**分析**:

1. **实际5的召回率80%**:
   - 100个实际兴趣度为5的用户
   - 80个被正确预测为5 ✅
   - 15个被错误预测为6 ❌
   - 5个被错误预测为7 ❌
   - **结论**: 模型对兴趣度5的识别能力较好

2. **预测5的精准率84.2%**:
   - 95次预测为5
   - 80次是真正的5 ✅
   - 10次实际是6 ❌
   - 5次实际是7 ❌
   - **结论**: 当模型预测为5时，有84.2%的把握是准确的

3. **实际6的召回率70%** (最低):
   - 说明兴趣度6最容易被误判
   - 有30%被预测成其他值
   - **建议**: 需要优化模型对兴趣度6的特征提取

4. **预测7的精准率77.3%**:
   - 预测为7时有22.7%的误报率
   - **建议**: 可能需要提高判断阈值

### 召回率 vs 精准率

| 指标 | 关注点 | 公式 | 业务意义 |
|------|--------|------|----------|
| **召回率** (Recall) | 实际为X的样本 | 预测对了多少个X / 实际有多少个X | "别漏掉" - 覆盖率 |
| **精准率** (Precision) | 预测为X的样本 | 预测为X中真是X的 / 所有预测为X的 | "别弄错" - 准确性 |

**权衡取舍**:
- **医疗诊断**: 召回率更重要 (宁可误诊，不能漏诊)
- **垃圾邮件**: 精准率更重要 (宁可漏掉垃圾，不能误删正常邮件)
- **推荐系统**: 需要平衡两者

## 🔍 筛选功能示例

### 场景1: 分析移动端的表现

```python
from data_model import FilterCriteria

criteria = FilterCriteria(scenario="移动端")
report = generate_report_from_repository(repo, criteria)
```

### 场景2: 对比不同垂类

```python
# 分析零售垂类
criteria_retail = FilterCriteria(vertical="零售")
report_retail = generate_report_from_repository(repo, criteria_retail)

# 分析社交垂类
criteria_social = FilterCriteria(vertical="社交娱乐")
report_social = generate_report_from_repository(repo, criteria_social)
```

### 场景3: 多维度组合筛选

```python
# 分析电商分类下，移动端场景，VIP用户的表现
criteria = FilterCriteria(
    primary_category="电商",
    scenario="移动端",
    factor_value="VIP"
)
report = generate_report_from_repository(repo, criteria)
```

## 📥 Excel报表说明

导出的Excel文件包含以下Sheet:

1. **汇总统计**: 总体指标（总数、通过数、失败数、准确率等）
2. **总体混淆矩阵**: 所有数据的混淆矩阵
3. **分类-XXX**: 每个一级分类独立的混淆矩阵
4. **详细数据**: 原始数据列表，支持筛选和排序

**样式特性**:
- ✅ 表头蓝色背景
- ✅ 对角线绿色高亮（正确预测）
- ✅ Pass绿色、Fail红色
- ✅ 冻结首行便于浏览

## 🌐 Web界面操作

### 1. 生成示例数据
点击 "🎲 生成示例数据" → 输入数量 → 确认

### 2. 筛选数据
在下拉菜单中选择筛选条件（可多选）

### 3. 生成报表
点击 "📊 生成报表" → 查看混淆矩阵

### 4. 切换视图
点击标签页: "总体" / "电商" / "社交" 等

### 5. 导出Excel
点击 "📥 导出Excel" → 自动下载

### 6. 重置
点击 "🔄 重置筛选" → 清空所有筛选条件

## 💡 最佳实践

### 1. 数据准备
- 确保预期值和实际值在 0-15 范围内
- 填写完整的筛选维度字段
- 使用有意义的分类名称

### 2. 分析流程
1. 先看总体混淆矩阵，了解全局表现
2. 查看准确率最低的一级分类
3. 筛选特定场景，定位问题
4. 对比不同因子的影响

### 3. 报表解读
- 关注召回率低的类别（容易漏判）
- 关注精准率低的类别（容易误判）
- 查看混淆最严重的类别对（容易混淆）

### 4. 优化建议
- 召回率低 → 增强特征提取
- 精准率低 → 提高判断阈值
- 某对值互相混淆 → 增加区分特征

## 🚀 性能提示

- 数据量 < 10,000: 响应迅速
- 数据量 10,000 - 100,000: 可能需要几秒
- 数据量 > 100,000: 建议先筛选后生成报表

## ❓ 常见问题

### Q1: 如何添加自己的数据？
**A**: 三种方式:
1. 通过Web API上传JSON数据
2. 在代码中创建 `ClassificationRecord` 对象
3. 从CSV/Excel读取后转换为 `ClassificationRecord`

### Q2: 可以扩展到16以上的分类吗？
**A**: 可以！修改 `confusion_matrix.py` 中的 `value_range = range(0, 16)` 即可

### Q3: 如何自定义筛选维度？
**A**: 在 `data_model.py` 的 `ClassificationRecord` 和 `FilterCriteria` 中添加新字段

### Q4: 能否批量导入数据？
**A**: 可以！参考以下代码:

```python
import pandas as pd

# 从CSV读取
df = pd.read_csv("your_data.csv")

# 转换并添加
for _, row in df.iterrows():
    record = ClassificationRecord(
        primary_category=row["primary"],
        secondary_category=row["secondary"],
        expected_value=int(row["expected"]),
        actual_value=int(row["actual"]),
        # ... 其他字段
    )
    repository.add_record(record)
```

## 📞 技术支持

遇到问题？
1. 查看 `README.md`
2. 运行 `python example_usage.py` 查看示例
3. 检查 `requirements.txt` 依赖是否安装

---

**祝使用愉快！** 🎉
