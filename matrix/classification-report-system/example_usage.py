"""
使用示例 - 分类预测统计报表系统
演示如何使用各个模块
"""
from data_model import DataRepository, FilterCriteria, ClassificationRecord
from confusion_matrix import generate_report_from_repository, ConfusionMatrixGenerator
from excel_exporter import ExcelExporter
import random
from datetime import datetime


def create_sample_data(count=100):
    """创建示例数据"""
    categories = ["电商", "社交", "新闻", "游戏"]
    sub_categories = ["首页", "列表页", "详情页", "个人中心"]
    use_cases = ["用户登录", "商品浏览", "订单支付", "内容推荐"]
    scenarios = ["移动端", "PC端", "平板端"]
    verticals = ["零售", "社交娱乐", "资讯", "游戏"]
    factors = ["网络状态", "用户等级", "地域", "时间段"]
    factor_values = ["良好", "一般", "较差", "VIP", "普通", "北京", "上海", "白天", "夜晚"]

    records = []
    for i in range(count):
        # 80%概率预测正确
        expected = random.randint(0, 15)
        if random.random() < 0.8:
            actual = expected
        else:
            actual = random.randint(0, 15)

        record = ClassificationRecord(
            primary_category=random.choice(categories),
            secondary_category=random.choice(sub_categories),
            expected_value=expected,
            actual_value=actual,
            status="pass" if expected == actual else "fail",
            use_case=random.choice(use_cases),
            scenario=random.choice(scenarios),
            vertical=random.choice(verticals),
            factor=random.choice(factors),
            factor_value=random.choice(factor_values),
            timestamp=datetime.now().isoformat(),
            test_id=f"TEST_{i:05d}",
            notes=f"自动生成的测试记录 #{i}"
        )
        records.append(record)

    return records


def example_1_basic_usage():
    """示例1: 基本使用 - 生成报表并打印"""
    print("=" * 80)
    print("示例1: 基本使用 - 生成控制台报表")
    print("=" * 80)

    # 创建数据仓库
    repository = DataRepository()

    # 添加示例数据
    records = create_sample_data(200)
    repository.add_records(records)

    # 生成并打印报表
    report = generate_report_from_repository(repository)
    print(report)


def example_2_filtered_report():
    """示例2: 使用筛选条件生成报表"""
    print("\n" + "=" * 80)
    print("示例2: 筛选特定用例和场景的报表")
    print("=" * 80)

    # 创建数据仓库
    repository = DataRepository()
    records = create_sample_data(300)
    repository.add_records(records)

    # 设置筛选条件 - 只看"电商"分类，"移动端"场景
    criteria = FilterCriteria(
        primary_category="电商",
        scenario="移动端"
    )

    # 生成筛选后的报表
    report = generate_report_from_repository(repository, criteria)
    print(report)


def example_3_export_excel():
    """示例3: 导出Excel报表"""
    print("\n" + "=" * 80)
    print("示例3: 导出Excel报表")
    print("=" * 80)

    # 创建数据仓库
    repository = DataRepository()
    records = create_sample_data(500)
    repository.add_records(records)

    # 创建导出器
    exporter = ExcelExporter(repository)

    # 导出完整报表
    output_file = "classification_report_full.xlsx"
    exporter.export_full_report(output_file)
    print(f"✅ 完整报表已导出到: {output_file}")

    # 导出筛选后的报表
    criteria = FilterCriteria(vertical="零售", factor="网络状态")
    filtered_file = "classification_report_filtered.xlsx"
    exporter.export_full_report(filtered_file, criteria)
    print(f"✅ 筛选报表已导出到: {filtered_file}")

    # 导出简单数据列表
    simple_file = "classification_data_simple.xlsx"
    exporter.export_simple_excel(simple_file)
    print(f"✅ 简单数据列表已导出到: {simple_file}")


def example_4_custom_analysis():
    """示例4: 自定义分析 - 获取原始数据"""
    print("\n" + "=" * 80)
    print("示例4: 自定义分析 - 直接使用混淆矩阵数据")
    print("=" * 80)

    # 创建数据仓库
    repository = DataRepository()
    records = create_sample_data(200)
    repository.add_records(records)

    # 筛选特定条件的记录
    criteria = FilterCriteria(use_case="用户登录")
    filtered_records = repository.filter_records(criteria)

    # 生成混淆矩阵
    generator = ConfusionMatrixGenerator(filtered_records)
    report_data = generator.generate_detailed_report()

    # 获取数据进行自定义分析
    overall = report_data["overall"]
    summary = report_data["summary"]

    print(f"\n用例: 用户登录")
    print(f"总记录数: {summary['total_records']}")
    print(f"准确率: {summary['accuracy']:.2f}%")
    print(f"\n各预测值的精准率:")
    for i, precision in enumerate(overall["precision"]):
        if overall["total_expected"][i] > 0:
            print(f"  预测值{i}: {precision:.2f}% (样本数: {overall['total_expected'][i]})")

    print(f"\n各实际值的召回率:")
    for i, recall in enumerate(overall["recall"]):
        if overall["total_actual"][i] > 0:
            print(f"  实际值{i}: {recall:.2f}% (样本数: {overall['total_actual'][i]})")


def example_5_data_exploration():
    """示例5: 数据探索 - 查看各维度的分布"""
    print("\n" + "=" * 80)
    print("示例5: 数据探索 - 各维度统计")
    print("=" * 80)

    # 创建数据仓库
    repository = DataRepository()
    records = create_sample_data(400)
    repository.add_records(records)

    # 查看各维度的唯一值
    dimensions = [
        "primary_category",
        "secondary_category",
        "use_case",
        "scenario",
        "vertical",
        "factor",
        "factor_value"
    ]

    print("\n各维度的唯一值分布:")
    for dim in dimensions:
        values = repository.get_unique_values(dim)
        print(f"\n{dim}:")
        for value in values:
            # 统计该值的记录数
            criteria = FilterCriteria(**{dim: value})
            count = len(repository.filter_records(criteria))
            print(f"  - {value}: {count} 条记录")


def example_6_manual_records():
    """示例6: 手动创建特定测试记录"""
    print("\n" + "=" * 80)
    print("示例6: 手动创建测试记录")
    print("=" * 80)

    repository = DataRepository()

    # 手动创建一些测试记录
    test_cases = [
        # 电商场景 - 首页推荐
        {"primary": "电商", "secondary": "首页", "expected": 3, "actual": 3, "use_case": "商品推荐"},
        {"primary": "电商", "secondary": "首页", "expected": 5, "actual": 5, "use_case": "商品推荐"},
        {"primary": "电商", "secondary": "首页", "expected": 7, "actual": 6, "use_case": "商品推荐"},  # 预测错误

        # 社交场景 - 内容推荐
        {"primary": "社交", "secondary": "信息流", "expected": 2, "actual": 2, "use_case": "内容推荐"},
        {"primary": "社交", "secondary": "信息流", "expected": 4, "actual": 3, "use_case": "内容推荐"},  # 预测错误
        {"primary": "社交", "secondary": "信息流", "expected": 8, "actual": 8, "use_case": "内容推荐"},
    ]

    for i, case in enumerate(test_cases):
        record = ClassificationRecord(
            primary_category=case["primary"],
            secondary_category=case["secondary"],
            expected_value=case["expected"],
            actual_value=case["actual"],
            status="pass" if case["expected"] == case["actual"] else "fail",
            use_case=case["use_case"],
            scenario="移动端",
            vertical="互联网",
            factor="算法版本",
            factor_value="v2.0",
            test_id=f"MANUAL_TEST_{i:03d}",
            timestamp=datetime.now().isoformat(),
            notes="手动创建的测试用例"
        )
        repository.add_record(record)

    # 生成报表
    report = generate_report_from_repository(repository)
    print(report)


if __name__ == "__main__":
    # 运行所有示例
    print("\n🚀 分类预测统计报表系统 - 使用示例\n")

    # 示例1: 基本使用
    example_1_basic_usage()

    # 示例2: 筛选报表
    example_2_filtered_report()

    # 示例3: 导出Excel
    example_3_export_excel()

    # 示例4: 自定义分析
    example_4_custom_analysis()

    # 示例5: 数据探索
    example_5_data_exploration()

    # 示例6: 手动测试记录
    example_6_manual_records()

    print("\n" + "=" * 80)
    print("✅ 所有示例运行完成！")
    print("=" * 80)
