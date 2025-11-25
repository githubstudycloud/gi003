"""
Flask Web应用 - 分类统计报表展示
支持筛选、混淆矩阵展示、Excel导出
"""
from flask import Flask, render_template, request, jsonify, send_file
from flask_cors import CORS
from data_model import DataRepository, FilterCriteria, ClassificationRecord, ResultStatus
from confusion_matrix import ConfusionMatrixGenerator
from excel_exporter import ExcelExporter
import json
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# 全局数据仓库
repository = DataRepository()


@app.route('/')
def index():
    """主页 - 展示混淆矩阵和筛选器"""
    return render_template('index.html')


@app.route('/api/data/upload', methods=['POST'])
def upload_data():
    """上传测试数据"""
    try:
        data = request.get_json()

        if not data or 'records' not in data:
            return jsonify({"error": "Invalid data format"}), 400

        # 清空现有数据
        repository.clear()

        # 添加新数据
        for record_data in data['records']:
            record = ClassificationRecord.from_dict(record_data)
            repository.add_record(record)

        return jsonify({
            "success": True,
            "message": f"成功上传 {len(data['records'])} 条记录"
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/data/generate-sample', methods=['POST'])
def generate_sample_data():
    """生成示例数据"""
    import random

    repository.clear()

    categories = ["电商", "社交", "新闻", "游戏"]
    sub_categories = ["首页", "列表页", "详情页", "个人中心"]
    use_cases = ["用户登录", "商品浏览", "订单支付", "内容推荐"]
    scenarios = ["移动端", "PC端", "平板端"]
    verticals = ["零售", "社交娱乐", "资讯", "游戏"]
    factors = ["网络状态", "用户等级", "地域", "时间段"]
    factor_values = ["良好", "一般", "较差", "VIP", "普通", "北京", "上海", "白天", "夜晚"]

    num_records = request.json.get('count', 200)

    for i in range(num_records):
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
            test_id=f"TEST_{i:05d}"
        )
        repository.add_record(record)

    return jsonify({
        "success": True,
        "message": f"成功生成 {num_records} 条示例数据"
    })


@app.route('/api/filters/options', methods=['GET'])
def get_filter_options():
    """获取所有筛选项的可选值"""
    return jsonify({
        "use_cases": repository.get_unique_values("use_case"),
        "scenarios": repository.get_unique_values("scenario"),
        "verticals": repository.get_unique_values("vertical"),
        "factors": repository.get_unique_values("factor"),
        "factor_values": repository.get_unique_values("factor_value"),
        "primary_categories": repository.get_unique_values("primary_category"),
        "secondary_categories": repository.get_unique_values("secondary_category")
    })


@app.route('/api/report/generate', methods=['POST'])
def generate_report():
    """生成混淆矩阵报表"""
    try:
        filter_params = request.get_json() or {}

        # 构建筛选条件
        criteria = FilterCriteria(
            use_case=filter_params.get('use_case'),
            scenario=filter_params.get('scenario'),
            vertical=filter_params.get('vertical'),
            factor=filter_params.get('factor'),
            factor_value=filter_params.get('factor_value'),
            primary_category=filter_params.get('primary_category'),
            secondary_category=filter_params.get('secondary_category')
        )

        # 筛选记录
        records = repository.filter_records(criteria)

        if not records:
            return jsonify({"error": "没有找到匹配的记录"}), 404

        # 生成报表
        generator = ConfusionMatrixGenerator(records)
        report_data = generator.generate_detailed_report()

        return jsonify({
            "success": True,
            "data": {
                "overall": report_data["overall"],
                "by_primary_category": report_data["by_primary_category"],
                "summary": report_data["summary"]
            }
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/export/excel', methods=['POST'])
def export_excel():
    """导出Excel报表"""
    try:
        filter_params = request.get_json() or {}

        # 构建筛选条件
        criteria = FilterCriteria(
            use_case=filter_params.get('use_case'),
            scenario=filter_params.get('scenario'),
            vertical=filter_params.get('vertical'),
            factor=filter_params.get('factor'),
            factor_value=filter_params.get('factor_value'),
            primary_category=filter_params.get('primary_category'),
            secondary_category=filter_params.get('secondary_category')
        )

        # 生成Excel
        exporter = ExcelExporter(repository)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = f"temp/classification_report_{timestamp}.xlsx"

        # 确保temp目录存在
        os.makedirs("temp", exist_ok=True)

        exporter.export_full_report(output_path, criteria)

        return send_file(
            output_path,
            as_attachment=True,
            download_name=f"classification_report_{timestamp}.xlsx",
            mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/data/detail', methods=['POST'])
def get_detail_data():
    """获取详细数据列表"""
    try:
        filter_params = request.get_json() or {}
        page = filter_params.get('page', 1)
        page_size = filter_params.get('page_size', 50)

        # 构建筛选条件
        criteria = FilterCriteria(
            use_case=filter_params.get('use_case'),
            scenario=filter_params.get('scenario'),
            vertical=filter_params.get('vertical'),
            factor=filter_params.get('factor'),
            factor_value=filter_params.get('factor_value'),
            primary_category=filter_params.get('primary_category'),
            secondary_category=filter_params.get('secondary_category')
        )

        # 筛选记录
        records = repository.filter_records(criteria)

        # 分页
        total = len(records)
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        page_records = records[start_idx:end_idx]

        return jsonify({
            "success": True,
            "data": [record.to_dict() for record in page_records],
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
