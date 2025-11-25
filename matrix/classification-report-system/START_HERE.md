# 🚀 快速开始指南

## 欢迎使用分类预测统计报表系统！

这是一个功能完整的分类预测分析系统，只需3步即可开始使用。

---

## ⚡ 快速上手 (3步)

### 第1步: 检查依赖

```bash
python install_check.py
```

如果提示缺少依赖，运行：
```bash
pip install -r requirements.txt
```

### 第2步: 验证系统

```bash
python test_system.py
```

应该看到所有测试通过 ✅

### 第3步: 选择使用方式

#### 方式A: Web界面 (推荐新手) 🌐

```bash
python quick_start.py
```

然后访问: http://localhost:5000

#### 方式B: 命令行 (适合开发者) 💻

```bash
python example_usage.py
```

查看6个示例的输出结果

#### 方式C: 集成到你的项目 🔧

```python
from data_model import DataRepository, ClassificationRecord
from confusion_matrix import generate_report_from_repository

# 创建数据
repo = DataRepository()
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
    factor_value="良好"
)
repo.add_record(record)

# 生成报表
report = generate_report_from_repository(repo)
print(report)
```

---

## 📚 文档导航

| 文档 | 说明 | 适合人群 |
|------|------|----------|
| [README.md](README.md) | 项目介绍、功能列表、API说明 | 所有人 |
| [USAGE_GUIDE.md](USAGE_GUIDE.md) | 详细使用教程、表格解读 | 新手 |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) | 项目总结、技术栈、设计思路 | 开发者 |
| [example_usage.py](example_usage.py) | 6个实际代码示例 | 开发者 |

---

## 🎯 核心功能一览

### ✅ 混淆矩阵分析
- 16x16完整矩阵 (0-15分类)
- 精准率 (Precision)
- 召回率 (Recall)
- 按分类分组统计

### ✅ 多维度筛选
- 用例 (Use Case)
- 场景 (Scenario)
- 垂类 (Vertical)
- 因子 (Factor)
- 因子值 (Factor Value)
- 一级/二级分类

### ✅ 多种输出格式
- 控制台报表 (ASCII表格)
- Excel报表 (多Sheet + 样式)
- Web可视化界面
- JSON数据导出

---

## 💡 典型应用场景

1. **机器学习模型评估**
   - 分类模型准确率分析
   - 多模型对比测试

2. **推荐系统测试**
   - 推荐效果评估
   - A/B测试对比

3. **质量检测报告**
   - 产品分类检测
   - 自动化测试报告

4. **用户行为分析**
   - 预测vs实际行为对比
   - 用户分群效果评估

---

## 🔧 系统要求

- **Python**: 3.8+
- **操作系统**: Windows / macOS / Linux
- **依赖**: Flask, NumPy, Pandas, openpyxl

---

## 📊 示例报表预览

### 控制台报表
```
================================================================================
混淆矩阵: 总体
================================================================================
实际\预测     |   0 |   1 |   2 | ... |  15 |   SUM | 召回率
实际 0        |  45 |   3 |   1 | ... |   0 |    49 |  91.84%
实际 1        |   2 |  38 |   2 | ... |   0 |    42 |  90.48%
...
SUM           |  48 |  42 |  43 | ... |  35 |   500 |    -
精准率        | 93.7| 90.5| 93.0| ... |100.0|     - |    -
```

### Excel报表
- Sheet1: 汇总统计
- Sheet2: 总体混淆矩阵
- Sheet3-N: 各分类矩阵
- 最后: 详细数据列表

### Web界面
- 筛选器 (下拉菜单)
- 汇总卡片 (总数/通过/失败/准确率)
- 混淆矩阵表格 (可切换分类)
- 导出按钮 (生成Excel)

---

## 🆘 遇到问题?

### 常见问题

**Q: 提示缺少模块?**
```bash
pip install -r requirements.txt
```

**Q: 如何添加自己的数据?**
查看 [USAGE_GUIDE.md](USAGE_GUIDE.md) 的"数据导入"章节

**Q: 如何自定义分类范围?**
修改 `confusion_matrix.py` 中的 `value_range`

**Q: Web服务无法启动?**
检查端口5000是否被占用，可在 `web_app.py` 中修改端口

### 获取帮助

1. 查看文档: [USAGE_GUIDE.md](USAGE_GUIDE.md)
2. 运行示例: `python example_usage.py`
3. 查看测试: `python test_system.py`

---

## 🎉 开始使用

现在就开始吧！运行：

```bash
python quick_start.py
```

享受数据分析的乐趣！ 📊✨

---

**Generated with Claude Code** 🤖
