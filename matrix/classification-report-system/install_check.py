"""
依赖检查和安装脚本
"""
import sys
import subprocess


def check_package(package_name):
    """检查包是否已安装"""
    try:
        __import__(package_name)
        return True
    except ImportError:
        return False


def main():
    """主函数"""
    print("=" * 70)
    print("📦 分类预测统计报表系统 - 依赖检查")
    print("=" * 70)

    # 需要检查的包
    packages = {
        "flask": "Flask",
        "flask_cors": "Flask-CORS",
        "numpy": "NumPy",
        "pandas": "Pandas",
        "openpyxl": "openpyxl",
    }

    missing = []
    installed = []

    print("\n检查依赖...")
    for module_name, package_name in packages.items():
        if check_package(module_name):
            print(f"  ✅ {package_name:<15} 已安装")
            installed.append(package_name)
        else:
            print(f"  ❌ {package_name:<15} 未安装")
            missing.append(package_name)

    print("\n" + "=" * 70)
    print(f"已安装: {len(installed)}/{len(packages)}")

    if missing:
        print(f"\n缺少以下依赖:")
        for pkg in missing:
            print(f"  - {pkg}")

        print("\n" + "=" * 70)
        print("安装方法:")
        print("=" * 70)
        print("\n方法1: 安装所有依赖 (推荐)")
        print("  pip install -r requirements.txt")
        print("\n方法2: 手动安装缺失的包")
        print(f"  pip install {' '.join(missing)}")
        print("\n" + "=" * 70)

        choice = input("\n是否现在自动安装缺失的依赖? (y/n) [默认: n]: ").strip().lower()

        if choice == "y":
            print("\n开始安装依赖...")
            try:
                subprocess.check_call([
                    sys.executable,
                    "-m",
                    "pip",
                    "install",
                    "-r",
                    "requirements.txt"
                ])
                print("\n✅ 依赖安装完成!")
                return 0
            except subprocess.CalledProcessError as e:
                print(f"\n❌ 安装失败: {e}")
                return 1
        else:
            print("\n请手动安装依赖后再运行系统")
            return 1
    else:
        print("\n✅ 所有依赖已安装，可以正常使用系统!")
        print("\n" + "=" * 70)
        print("快速开始:")
        print("=" * 70)
        print("\n1. 运行测试验证系统:")
        print("   python test_system.py")
        print("\n2. 查看使用示例:")
        print("   python example_usage.py")
        print("\n3. 启动Web服务:")
        print("   python web_app.py")
        print("\n4. 一键启动 (推荐):")
        print("   python quick_start.py")
        print("\n" + "=" * 70)
        return 0


if __name__ == "__main__":
    sys.exit(main())
