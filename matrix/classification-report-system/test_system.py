"""
系统测试脚本
验证各个模块的功能是否正常
"""
import sys
from data_model import DataRepository, ClassificationRecord, FilterCriteria, ResultStatus
from confusion_matrix import ConfusionMatrixGenerator, generate_report_from_repository
from excel_exporter import ExcelExporter


def test_data_model():
    """测试数据模型"""
    print("=" * 60)
    print("测试1: 数据模型")
    print("=" * 60)

    try:
        # 创建记录
        record = ClassificationRecord(
            primary_category="测试分类",
            secondary_category="子分类",
            expected_value=5,
            actual_value=5,
            status="pass",
            use_case="测试用例",
            scenario="测试场景",
            vertical="测试垂类",
            factor="测试因子",
            factor_value="测试值"
        )

        assert record.status == ResultStatus.PASS, "状态应为PASS"
        assert record.expected_value == 5, "预期值应为5"
        assert record.actual_value == 5, "实际值应为5"

        # 测试自动判断fail
        record2 = ClassificationRecord(
            primary_category="测试分类",
            secondary_category="子分类",
            expected_value=3,
            actual_value=7,
            status="fail",
            use_case="测试用例",
            scenario="测试场景",
            vertical="测试垂类",
            factor="测试因子",
            factor_value="测试值"
        )

        assert record2.status == ResultStatus.FAIL, "状态应为FAIL"

        # 测试to_dict和from_dict
        data = record.to_dict()
        record3 = ClassificationRecord.from_dict(data)
        assert record3.primary_category == record.primary_category

        print("✅ 数据模型测试通过!")
        return True

    except Exception as e:
        print(f"❌ 数据模型测试失败: {e}")
        return False


def test_repository():
    """测试数据仓库"""
    print("\n" + "=" * 60)
    print("测试2: 数据仓库")
    print("=" * 60)

    try:
        repo = DataRepository()

        # 添加记录
        for i in range(10):
            record = ClassificationRecord(
                primary_category="分类A" if i < 5 else "分类B",
                secondary_category="子分类",
                expected_value=i % 5,
                actual_value=i % 5,
                status="pass",
                use_case=f"用例{i % 3}",
                scenario="场景A",
                vertical="垂类A",
                factor="因子A",
                factor_value="值A"
            )
            repo.add_record(record)

        # 测试获取所有记录
        all_records = repo.get_all_records()
        assert len(all_records) == 10, "应有10条记录"

        # 测试筛选
        criteria = FilterCriteria(primary_category="分类A")
        filtered = repo.filter_records(criteria)
        assert len(filtered) == 5, "分类A应有5条记录"

        # 测试获取唯一值
        categories = repo.get_unique_values("primary_category")
        assert len(categories) == 2, "应有2个不同的一级分类"

        print("✅ 数据仓库测试通过!")
        return True

    except Exception as e:
        print(f"❌ 数据仓库测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_confusion_matrix():
    """测试混淆矩阵生成"""
    print("\n" + "=" * 60)
    print("测试3: 混淆矩阵生成")
    print("=" * 60)

    try:
        # 创建测试数据
        records = []
        for i in range(100):
            # 80%正确率
            expected = i % 10
            actual = expected if i % 5 != 0 else (expected + 1) % 10

            record = ClassificationRecord(
                primary_category="测试",
                secondary_category="子类",
                expected_value=expected,
                actual_value=actual,
                status="pass" if expected == actual else "fail",
                use_case="测试",
                scenario="测试",
                vertical="测试",
                factor="测试",
                factor_value="测试"
            )
            records.append(record)

        # 生成混淆矩阵
        generator = ConfusionMatrixGenerator(records)
        report = generator.generate_detailed_report()

        # 验证
        assert "overall" in report
        assert "by_primary_category" in report
        assert "summary" in report

        overall = report["overall"]
        assert len(overall["matrix"]) == 16, "矩阵应为16x16"
        assert len(overall["precision"]) == 16, "应有16个精准率值"
        assert len(overall["recall"]) == 16, "应有16个召回率值"

        summary = report["summary"]
        assert summary["total_records"] == 100, "总记录数应为100"
        assert summary["accuracy"] == 80.0, "准确率应为80%"

        print("✅ 混淆矩阵生成测试通过!")
        return True

    except Exception as e:
        print(f"❌ 混淆矩阵生成测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_report_generation():
    """测试报表生成"""
    print("\n" + "=" * 60)
    print("测试4: 报表生成")
    print("=" * 60)

    try:
        repo = DataRepository()

        # 添加测试数据
        for i in range(50):
            record = ClassificationRecord(
                primary_category="电商" if i < 25 else "社交",
                secondary_category="首页",
                expected_value=i % 8,
                actual_value=i % 8 if i % 4 != 0 else (i + 1) % 8,
                status="pass",
                use_case="测试",
                scenario="移动端",
                vertical="零售",
                factor="网络",
                factor_value="良好"
            )
            repo.add_record(record)

        # 生成报表
        report = generate_report_from_repository(repo)
        assert isinstance(report, str), "报表应为字符串"
        assert "混淆矩阵" in report, "报表应包含混淆矩阵标题"
        assert "召回率" in report, "报表应包含召回率"
        assert "精准率" in report, "报表应包含精准率"

        # 测试筛选报表
        criteria = FilterCriteria(primary_category="电商")
        filtered_report = generate_report_from_repository(repo, criteria)
        assert isinstance(filtered_report, str), "筛选报表应为字符串"

        print("✅ 报表生成测试通过!")
        return True

    except Exception as e:
        print(f"❌ 报表生成测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_excel_export():
    """测试Excel导出"""
    print("\n" + "=" * 60)
    print("测试5: Excel导出")
    print("=" * 60)

    try:
        repo = DataRepository()

        # 添加测试数据
        for i in range(30):
            record = ClassificationRecord(
                primary_category="测试",
                secondary_category="子类",
                expected_value=i % 5,
                actual_value=i % 5,
                status="pass",
                use_case="测试",
                scenario="测试",
                vertical="测试",
                factor="测试",
                factor_value="测试",
                test_id=f"TEST_{i:03d}"
            )
            repo.add_record(record)

        # 测试简单导出
        exporter = ExcelExporter(repo)
        simple_file = "temp/test_simple.xlsx"

        import os
        os.makedirs("temp", exist_ok=True)

        exporter.export_simple_excel(simple_file)
        assert os.path.exists(simple_file), "简单Excel文件应已创建"

        # 测试完整导出
        full_file = "temp/test_full.xlsx"
        exporter.export_full_report(full_file)
        assert os.path.exists(full_file), "完整Excel文件应已创建"

        # 清理
        os.remove(simple_file)
        os.remove(full_file)

        print("✅ Excel导出测试通过!")
        return True

    except Exception as e:
        print(f"❌ Excel导出测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_filter_criteria():
    """测试筛选条件"""
    print("\n" + "=" * 60)
    print("测试6: 筛选条件")
    print("=" * 60)

    try:
        # 创建测试记录
        record = ClassificationRecord(
            primary_category="电商",
            secondary_category="首页",
            expected_value=5,
            actual_value=5,
            status="pass",
            use_case="用户登录",
            scenario="移动端",
            vertical="零售",
            factor="网络状态",
            factor_value="良好"
        )

        # 测试单个条件匹配
        criteria1 = FilterCriteria(primary_category="电商")
        assert criteria1.matches(record), "应匹配一级分类"

        criteria2 = FilterCriteria(primary_category="社交")
        assert not criteria2.matches(record), "不应匹配错误的一级分类"

        # 测试多个条件组合
        criteria3 = FilterCriteria(
            primary_category="电商",
            scenario="移动端",
            factor_value="良好"
        )
        assert criteria3.matches(record), "应匹配多个条件"

        criteria4 = FilterCriteria(
            primary_category="电商",
            scenario="PC端"  # 不匹配
        )
        assert not criteria4.matches(record), "不应匹配部分错误的条件"

        print("✅ 筛选条件测试通过!")
        return True

    except Exception as e:
        print(f"❌ 筛选条件测试失败: {e}")
        import traceback
        traceback.print_exc()
        return False


def run_all_tests():
    """运行所有测试"""
    print("\n" + "🧪 开始运行系统测试...\n")

    tests = [
        test_data_model,
        test_repository,
        test_confusion_matrix,
        test_report_generation,
        test_excel_export,
        test_filter_criteria
    ]

    results = []
    for test_func in tests:
        result = test_func()
        results.append(result)

    # 汇总结果
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)

    passed = sum(results)
    total = len(results)

    print(f"\n总测试数: {total}")
    print(f"通过: {passed} ✅")
    print(f"失败: {total - passed} ❌")
    print(f"通过率: {passed / total * 100:.1f}%")

    if passed == total:
        print("\n🎉 所有测试通过! 系统功能正常!")
        return 0
    else:
        print("\n⚠️  部分测试失败，请检查错误信息")
        return 1


if __name__ == "__main__":
    exit_code = run_all_tests()
    sys.exit(exit_code)
