"""
快速启动脚本
自动生成示例数据并启动Web服务
"""
import os
import sys
import subprocess
import time


def check_dependencies():
    """检查依赖是否安装"""
    try:
        import flask
        import numpy
        import pandas
        import openpyxl
        print("✅ 所有依赖已安装")
        return True
    except ImportError as e:
        print(f"❌ 缺少依赖: {e}")
        print("\n请运行以下命令安装依赖:")
        print("pip install -r requirements.txt")
        return False


def create_temp_directory():
    """创建临时目录"""
    if not os.path.exists("temp"):
        os.makedirs("temp")
        print("✅ 创建临时目录: temp/")


def generate_sample_data():
    """生成示例数据"""
    print("\n正在生成示例数据...")
    from data_model import DataRepository, ClassificationRecord
    from example_usage import create_sample_data
    import json

    repository = DataRepository()
    records = create_sample_data(500)  # 生成500条记录
    repository.add_records(records)

    # 保存到JSON
    data = [record.to_dict() for record in records]
    with open("sample_data.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"✅ 已生成 {len(records)} 条示例数据")
    print(f"✅ 数据已保存到: sample_data.json")

    return repository


def generate_sample_report(repository):
    """生成示例报表"""
    print("\n正在生成示例报表...")
    from confusion_matrix import generate_report_from_repository
    from excel_exporter import ExcelExporter

    # 生成控制台报表
    report = generate_report_from_repository(repository)
    with open("sample_report.txt", "w", encoding="utf-8") as f:
        f.write(report)
    print("✅ 控制台报表已保存到: sample_report.txt")

    # 生成Excel报表
    exporter = ExcelExporter(repository)
    excel_file = "sample_report.xlsx"
    exporter.export_full_report(excel_file)
    print(f"✅ Excel报表已保存到: {excel_file}")


def start_web_server():
    """启动Web服务"""
    print("\n" + "=" * 70)
    print("🚀 启动Web服务器...")
    print("=" * 70)
    print("\n访问地址: http://localhost:5000")
    print("按 Ctrl+C 停止服务\n")
    print("=" * 70 + "\n")

    # 启动Flask应用
    from web_app import app
    app.run(debug=True, host='0.0.0.0', port=5000)


def main():
    """主函数"""
    print("=" * 70)
    print("🎯 分类预测统计报表系统 - 快速启动")
    print("=" * 70)

    # 1. 检查依赖
    if not check_dependencies():
        sys.exit(1)

    # 2. 创建必要的目录
    create_temp_directory()

    # 3. 询问是否生成示例数据
    print("\n" + "=" * 70)
    choice = input("是否生成示例数据和报表? (y/n) [默认: y]: ").strip().lower()

    if choice in ["", "y", "yes"]:
        repository = generate_sample_data()
        generate_sample_report(repository)
        print("\n✅ 示例数据和报表生成完成!")
        print("  - sample_data.json: JSON格式数据")
        print("  - sample_report.txt: 控制台格式报表")
        print("  - sample_report.xlsx: Excel格式报表")

    # 4. 询问是否启动Web服务
    print("\n" + "=" * 70)
    choice = input("是否启动Web服务? (y/n) [默认: y]: ").strip().lower()

    if choice in ["", "y", "yes"]:
        start_web_server()
    else:
        print("\n✅ 快速启动完成!")
        print("\n如需启动Web服务，请运行:")
        print("  python web_app.py")
        print("\n如需查看使用示例，请运行:")
        print("  python example_usage.py")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 服务已停止")
    except Exception as e:
        print(f"\n❌ 错误: {e}")
        import traceback
        traceback.print_exc()
