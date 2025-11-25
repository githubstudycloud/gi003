"""
混淆矩阵统计报表生成器
支持召回率、精准率计算
"""
from typing import List, Dict, Tuple
from collections import defaultdict
import numpy as np
from data_model import ClassificationRecord, FilterCriteria, DataRepository


class ConfusionMatrixGenerator:
    """混淆矩阵生成器"""

    def __init__(self, records: List[ClassificationRecord]):
        self.records = records
        self.value_range = range(0, 16)  # 0-15

    def generate_matrix_by_primary_category(self) -> Dict[str, Dict]:
        """
        按一级分类生成混淆矩阵
        返回: {
            "category_name": {
                "matrix": [[count]],
                "recall": [recall_rates],
                "precision": [precision_rates],
                "total_expected": [counts],
                "total_actual": [counts]
            }
        }
        """
        # 按一级分类分组
        category_groups = defaultdict(list)
        for record in self.records:
            category_groups[record.primary_category].append(record)

        results = {}
        for category, records in category_groups.items():
            results[category] = self._calculate_matrix_metrics(records)

        return results

    def generate_overall_matrix(self) -> Dict:
        """生成总体混淆矩阵"""
        return self._calculate_matrix_metrics(self.records)

    def _calculate_matrix_metrics(self, records: List[ClassificationRecord]) -> Dict:
        """
        计算混淆矩阵及相关指标
        矩阵格式: matrix[actual][predicted]
        """
        # 初始化16x16矩阵
        matrix = np.zeros((16, 16), dtype=int)

        # 填充矩阵
        for record in records:
            actual = record.actual_value
            expected = record.expected_value
            matrix[actual][expected] += 1

        # 计算每个预测值的统计
        total_expected = matrix.sum(axis=0)  # 每列求和 - 预测为X的总数
        total_actual = matrix.sum(axis=1)    # 每行求和 - 实际为X的总数

        # 计算精准率 (Precision): 预测为X且实际为X / 预测为X的总数
        precision = []
        for i in range(16):
            if total_expected[i] > 0:
                precision.append(round(matrix[i][i] / total_expected[i] * 100, 2))
            else:
                precision.append(0.0)

        # 计算召回率 (Recall): 实际为X且预测为X / 实际为X的总数
        recall = []
        for i in range(16):
            if total_actual[i] > 0:
                recall.append(round(matrix[i][i] / total_actual[i] * 100, 2))
            else:
                recall.append(0.0)

        return {
            "matrix": matrix.tolist(),
            "precision": precision,
            "recall": recall,
            "total_expected": total_expected.tolist(),
            "total_actual": total_actual.tolist(),
            "total_records": len(records)
        }

    def generate_detailed_report(self) -> Dict:
        """生成详细报告（包含所有分类和总体）"""
        report = {
            "overall": self.generate_overall_matrix(),
            "by_primary_category": self.generate_matrix_by_primary_category(),
            "summary": self._generate_summary()
        }
        return report

    def _generate_summary(self) -> Dict:
        """生成汇总统计"""
        total = len(self.records)
        passed = sum(1 for r in self.records if r.status.value == "pass")
        failed = total - passed

        # 统计各维度
        primary_categories = set(r.primary_category for r in self.records)
        secondary_categories = set(r.secondary_category for r in self.records)
        use_cases = set(r.use_case for r in self.records)
        scenarios = set(r.scenario for r in self.records)
        verticals = set(r.vertical for r in self.records)
        factors = set(r.factor for r in self.records)

        return {
            "total_records": total,
            "passed": passed,
            "failed": failed,
            "accuracy": round(passed / total * 100, 2) if total > 0 else 0,
            "unique_counts": {
                "primary_categories": len(primary_categories),
                "secondary_categories": len(secondary_categories),
                "use_cases": len(use_cases),
                "scenarios": len(scenarios),
                "verticals": len(verticals),
                "factors": len(factors)
            }
        }


class ReportFormatter:
    """报表格式化器"""

    @staticmethod
    def format_matrix_table(matrix_data: Dict, category_name: str = "总体") -> str:
        """
        格式化混淆矩阵为表格字符串
        表格样式:
        一级分类 | 预测0 | 预测1 | ... | 预测15 | SUM | 召回率
        实际0    |   10  |   2   | ... |   0    | 12  | 83.33%
        ...
        SUM      |   15  |   20  | ... |   10   | 500 | -
        精准率   | 66.67%| 90.00%| ... | 100.00%| -   | -
        """
        matrix = np.array(matrix_data["matrix"])
        precision = matrix_data["precision"]
        recall = matrix_data["recall"]
        total_expected = matrix_data["total_expected"]
        total_actual = matrix_data["total_actual"]

        lines = []
        lines.append(f"\n{'='*80}")
        lines.append(f"混淆矩阵: {category_name}")
        lines.append(f"{'='*80}")

        # 表头
        header = f"{'实际\\预测':<12} |"
        for i in range(16):
            header += f" {i:>3} |"
        header += f" {'SUM':>5} | {'召回率':>7}"
        lines.append(header)
        lines.append("-" * len(header))

        # 数据行
        for i in range(16):
            row = f"实际 {i:<7} |"
            for j in range(16):
                row += f" {matrix[i][j]:>3} |"
            row += f" {total_actual[i]:>5} | {recall[i]:>6.2f}%"
            lines.append(row)

        lines.append("-" * len(header))

        # SUM行
        sum_row = f"{'SUM':<12} |"
        for count in total_expected:
            sum_row += f" {count:>3} |"
        sum_row += f" {sum(total_expected):>5} | {'-':>7}"
        lines.append(sum_row)

        # 精准率行
        precision_row = f"{'精准率':<12} |"
        for p in precision:
            precision_row += f" {p:>3.0f}%|"
        precision_row += f" {'-':>5} | {'-':>7}"
        lines.append(precision_row)

        lines.append("=" * 80)

        return "\n".join(lines)

    @staticmethod
    def format_summary(summary: Dict) -> str:
        """格式化汇总信息"""
        lines = []
        lines.append(f"\n{'='*60}")
        lines.append(f"{'汇总统计':^58}")
        lines.append(f"{'='*60}")
        lines.append(f"总记录数: {summary['total_records']}")
        lines.append(f"通过数: {summary['passed']} (PASS)")
        lines.append(f"失败数: {summary['failed']} (FAIL)")
        lines.append(f"准确率: {summary['accuracy']:.2f}%")
        lines.append(f"\n{'维度统计':-^60}")
        for key, value in summary['unique_counts'].items():
            lines.append(f"{key}: {value}")
        lines.append("=" * 60)
        return "\n".join(lines)


def generate_report_from_repository(
    repository: DataRepository,
    filter_criteria: FilterCriteria = None
) -> str:
    """
    从数据仓库生成完整报告

    Args:
        repository: 数据仓库
        filter_criteria: 筛选条件（可选）

    Returns:
        格式化的报告字符串
    """
    # 获取记录
    if filter_criteria:
        records = repository.filter_records(filter_criteria)
    else:
        records = repository.get_all_records()

    if not records:
        return "没有找到匹配的记录"

    # 生成矩阵
    generator = ConfusionMatrixGenerator(records)
    report_data = generator.generate_detailed_report()

    # 格式化输出
    formatter = ReportFormatter()
    output_lines = []

    # 汇总信息
    output_lines.append(formatter.format_summary(report_data["summary"]))

    # 总体混淆矩阵
    output_lines.append(formatter.format_matrix_table(
        report_data["overall"],
        "总体"
    ))

    # 各一级分类的混淆矩阵
    for category, matrix_data in report_data["by_primary_category"].items():
        output_lines.append(formatter.format_matrix_table(
            matrix_data,
            f"一级分类: {category}"
        ))

    return "\n".join(output_lines)
