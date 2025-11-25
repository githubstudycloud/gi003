"""
分类预测数据模型
支持多维度筛选和混淆矩阵统计
"""
from dataclasses import dataclass
from typing import Optional, List
from enum import Enum


class ResultStatus(Enum):
    """结果状态枚举"""
    PASS = "pass"
    FAIL = "fail"


@dataclass
class ClassificationRecord:
    """单条分类预测记录"""
    # 基本分类信息
    primary_category: str      # 一级分类
    secondary_category: str    # 二级分类

    # 预测结果
    expected_value: int        # 预期值 (0-15)
    actual_value: int          # 实际值 (0-15)

    # 一致性判断
    status: ResultStatus       # pass/fail

    # 筛选维度
    use_case: str             # 用例
    scenario: str             # 场景
    vertical: str             # 垂类
    factor: str               # 因子
    factor_value: str         # 因子值

    # 可选扩展字段
    timestamp: Optional[str] = None
    test_id: Optional[str] = None
    notes: Optional[str] = None

    def __post_init__(self):
        """初始化后验证"""
        # 自动判断status
        if isinstance(self.status, str):
            self.status = ResultStatus(self.status)

        # 验证值范围
        if not (0 <= self.expected_value <= 15):
            raise ValueError(f"expected_value必须在0-15之间，当前值: {self.expected_value}")
        if not (0 <= self.actual_value <= 15):
            raise ValueError(f"actual_value必须在0-15之间，当前值: {self.actual_value}")

        # 自动判断是否一致
        if self.expected_value == self.actual_value:
            if self.status != ResultStatus.PASS:
                self.status = ResultStatus.PASS
        else:
            if self.status != ResultStatus.FAIL:
                self.status = ResultStatus.FAIL

    def to_dict(self) -> dict:
        """转换为字典"""
        return {
            "primary_category": self.primary_category,
            "secondary_category": self.secondary_category,
            "expected_value": self.expected_value,
            "actual_value": self.actual_value,
            "status": self.status.value,
            "use_case": self.use_case,
            "scenario": self.scenario,
            "vertical": self.vertical,
            "factor": self.factor,
            "factor_value": self.factor_value,
            "timestamp": self.timestamp,
            "test_id": self.test_id,
            "notes": self.notes
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'ClassificationRecord':
        """从字典创建"""
        return cls(
            primary_category=data["primary_category"],
            secondary_category=data["secondary_category"],
            expected_value=data["expected_value"],
            actual_value=data["actual_value"],
            status=data["status"],
            use_case=data["use_case"],
            scenario=data["scenario"],
            vertical=data["vertical"],
            factor=data["factor"],
            factor_value=data["factor_value"],
            timestamp=data.get("timestamp"),
            test_id=data.get("test_id"),
            notes=data.get("notes")
        )


@dataclass
class FilterCriteria:
    """筛选条件"""
    use_case: Optional[str] = None
    scenario: Optional[str] = None
    vertical: Optional[str] = None
    factor: Optional[str] = None
    factor_value: Optional[str] = None
    primary_category: Optional[str] = None
    secondary_category: Optional[str] = None
    status: Optional[ResultStatus] = None

    def matches(self, record: ClassificationRecord) -> bool:
        """判断记录是否匹配筛选条件"""
        if self.use_case and record.use_case != self.use_case:
            return False
        if self.scenario and record.scenario != self.scenario:
            return False
        if self.vertical and record.vertical != self.vertical:
            return False
        if self.factor and record.factor != self.factor:
            return False
        if self.factor_value and record.factor_value != self.factor_value:
            return False
        if self.primary_category and record.primary_category != self.primary_category:
            return False
        if self.secondary_category and record.secondary_category != self.secondary_category:
            return False
        if self.status and record.status != self.status:
            return False
        return True


class DataRepository:
    """数据仓库"""

    def __init__(self):
        self.records: List[ClassificationRecord] = []

    def add_record(self, record: ClassificationRecord):
        """添加记录"""
        self.records.append(record)

    def add_records(self, records: List[ClassificationRecord]):
        """批量添加记录"""
        self.records.extend(records)

    def filter_records(self, criteria: FilterCriteria) -> List[ClassificationRecord]:
        """根据条件筛选记录"""
        return [record for record in self.records if criteria.matches(record)]

    def get_all_records(self) -> List[ClassificationRecord]:
        """获取所有记录"""
        return self.records

    def clear(self):
        """清空所有记录"""
        self.records.clear()

    def get_unique_values(self, field: str) -> List[str]:
        """获取某个字段的所有唯一值"""
        values = set()
        for record in self.records:
            value = getattr(record, field, None)
            if value:
                values.add(str(value))
        return sorted(list(values))
