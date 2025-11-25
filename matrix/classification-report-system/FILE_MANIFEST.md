# 📁 项目文件清单

## 完整文件列表

```
classification-report-system/
│
├── 📘 核心模块 (4个)
│   ├── data_model.py               5.4 KB  - 数据模型定义
│   ├── confusion_matrix.py         8.4 KB  - 混淆矩阵生成器
│   ├── excel_exporter.py          10.0 KB  - Excel导出器
│   └── web_app.py                  7.8 KB  - Flask Web应用
│
├── 🌐 前端界面 (1个目录)
│   └── templates/
│       └── index.html             14.3 KB  - Web可视化界面
│
├── 📝 示例和工具 (3个)
│   ├── example_usage.py            8.7 KB  - 6个使用示例
│   ├── quick_start.py              3.9 KB  - 快速启动脚本
│   └── test_system.py             10.9 KB  - 系统测试脚本
│
├── 📚 文档 (6个)
│   ├── START_HERE.md               4.3 KB  - 快速开始指南 ⭐
│   ├── README.md                   9.2 KB  - 项目说明
│   ├── USAGE_GUIDE.md             13.5 KB  - 使用指南
│   ├── PROJECT_SUMMARY.md          7.7 KB  - 项目总结
│   ├── FILE_MANIFEST.md            本文件   - 文件清单
│   └── requirements.txt            0.2 KB  - 依赖列表
│
├── 🔧 配置文件 (2个)
│   ├── .gitignore                  0.5 KB  - Git忽略配置
│   └── install_check.py            2.8 KB  - 依赖检查脚本
│
└── �� 运行时目录
    └── temp/                                - 临时文件目录
        ├── *.xlsx                           - 生成的Excel文件
        └── sample_*.json                    - 示例数据文件
```

---

## 📊 统计信息

| 类型 | 数量 | 总大小 |
|------|------|--------|
| Python模块 | 7个 | ~56 KB |
| HTML文件 | 1个 | ~14 KB |
| Markdown文档 | 6个 | ~38 KB |
| 配置文件 | 3个 | ~3.5 KB |
| **总计** | **17个** | **~111 KB** |

---

## 🎯 文件用途说明

### 核心模块

#### data_model.py
**用途**: 数据结构定义
- `ClassificationRecord`: 单条分类记录类
- `FilterCriteria`: 筛选条件类
- `DataRepository`: 数据仓库类
- `ResultStatus`: 状态枚举

**依赖**: 标准库 (dataclasses, typing, enum)

#### confusion_matrix.py
**用途**: 混淆矩阵计算和报表生成
- `ConfusionMatrixGenerator`: 矩阵生成器
- `ReportFormatter`: 报表格式化器
- `generate_report_from_repository()`: 快捷函数

**依赖**: numpy, data_model

#### excel_exporter.py
**用途**: Excel报表导出
- `ExcelExporter`: 导出器类
- `export_full_report()`: 完整报表导出
- `export_simple_excel()`: 简单数据导出

**依赖**: pandas, openpyxl, data_model, confusion_matrix

#### web_app.py
**用途**: Flask Web应用和API服务
- Web界面渲染
- RESTful API接口
- 数据上传和下载

**依赖**: flask, flask_cors, data_model, confusion_matrix, excel_exporter

**API端点**:
- `GET /`: 主页
- `POST /api/data/upload`: 上传数据
- `POST /api/data/generate-sample`: 生成示例
- `GET /api/filters/options`: 筛选选项
- `POST /api/report/generate`: 生成报表
- `POST /api/export/excel`: 导出Excel
- `POST /api/data/detail`: 详细数据

---

### 前端界面

#### templates/index.html
**用途**: Web可视化界面
- 响应式设计 (适配PC/移动端)
- 7个维度筛选器
- 混淆矩阵表格展示
- 汇总统计卡片
- Excel导出功能

**技术**: HTML5 + CSS3 + Vanilla JavaScript

---

### 示例和工具

#### example_usage.py
**用途**: 6个使用示例
1. 基本使用 - 生成控制台报表
2. 筛选报表 - 特定条件筛选
3. 导出Excel - 3种导出方式
4. 自定义分析 - 访问原始数据
5. 数据探索 - 维度统计
6. 手动记录 - 创建测试用例

**如何运行**: `python example_usage.py`

#### quick_start.py
**用途**: 快速启动脚本
- 检查依赖
- 生成示例数据 (可选)
- 生成示例报表 (可选)
- 启动Web服务

**如何运行**: `python quick_start.py`

#### test_system.py
**用途**: 系统测试脚本
- 6个单元测试
- 自动验证功能
- 生成测试报告

**如何运行**: `python test_system.py`

---

### 文档

#### START_HERE.md ⭐
**用途**: 快速开始指南
**适合**: 所有新用户
**内容**: 3步上手、文档导航、典型场景

#### README.md
**用途**: 项目完整说明
**适合**: 所有用户
**内容**: 功能介绍、安装指南、API文档、代码示例

#### USAGE_GUIDE.md
**用途**: 详细使用教程
**适合**: 新手用户
**内容**: 混淆矩阵解读、筛选示例、最佳实践、常见问题

#### PROJECT_SUMMARY.md
**用途**: 项目总结文档
**适合**: 开发者、技术评审
**内容**: 技术栈、设计思路、性能指标、扩展建议

#### FILE_MANIFEST.md
**用途**: 文件清单 (本文件)
**适合**: 开发者
**内容**: 完整文件列表、用途说明

#### requirements.txt
**用途**: Python依赖列表
**内容**:
- flask==3.0.0
- flask-cors==4.0.0
- numpy==1.26.2
- pandas==2.1.4
- openpyxl==3.1.2
- pytest==7.4.3
- pytest-cov==4.1.0

---

### 配置文件

#### .gitignore
**用途**: Git版本控制忽略配置
**忽略内容**:
- Python缓存 (__pycache__, *.pyc)
- 虚拟环境 (venv/, env/)
- IDE配置 (.vscode/, .idea/)
- 临时文件 (temp/, *.log)
- 生成的Excel (*.xlsx)

#### install_check.py
**用途**: 依赖检查和安装脚本
**功能**:
- 检查依赖是否安装
- 提示安装方法
- 可选自动安装

**如何运行**: `python install_check.py`

---

## 🚀 快速访问路径

### 新手入门
```
1. START_HERE.md      (开始这里)
2. install_check.py   (检查依赖)
3. quick_start.py     (快速启动)
4. USAGE_GUIDE.md     (使用指南)
```

### 开发者集成
```
1. README.md          (了解API)
2. example_usage.py   (查看示例)
3. data_model.py      (数据结构)
4. confusion_matrix.py (核心逻辑)
```

### 系统维护
```
1. test_system.py     (运行测试)
2. PROJECT_SUMMARY.md (技术文档)
3. FILE_MANIFEST.md   (文件说明)
```

---

## 📦 部署清单

**最小部署包** (生产环境):
```
classification-report-system/
├── data_model.py
├── confusion_matrix.py
├── excel_exporter.py
├── web_app.py
├── templates/
│   └── index.html
└── requirements.txt
```

**完整部署包** (包含文档):
```
所有文件 (如上文件树)
```

---

## 🔄 版本历史

| 版本 | 日期 | 文件数 | 代码行数 | 说明 |
|------|------|--------|----------|------|
| v1.0 | 2025-01 | 17个 | ~1500行 | 初始发布版本 |

---

## 📧 文件维护

- **创建日期**: 2025年1月
- **最后更新**: 2025年1月
- **维护者**: Claude Code
- **许可证**: MIT

---

**Generated with Claude Code** 🤖
