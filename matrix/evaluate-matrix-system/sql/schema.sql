-- ============================================
-- 混淆矩阵评估系统数据库表结构
-- MySQL 5.7+
-- ============================================

-- 创建数据库（如果需要）
-- CREATE DATABASE IF NOT EXISTS evaluate_matrix DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE evaluate_matrix;

-- ============================================
-- 1. 矩阵参数配置表
-- 每个报告+任务+用例对应一条配置
-- ============================================
DROP TABLE IF EXISTS `task_evaluate_matrix_param`;
CREATE TABLE `task_evaluate_matrix_param` (
    `report_id` VARCHAR(64) NOT NULL COMMENT '报告ID',
    `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
    `case_id` VARCHAR(64) NOT NULL COMMENT '用例ID',
    `actural_value_field` VARCHAR(128) DEFAULT NULL COMMENT '实际值字段名',
    `actural_id_field` VARCHAR(128) DEFAULT NULL COMMENT '实际值ID字段名',
    `predicted_value_field` VARCHAR(128) DEFAULT NULL COMMENT '预测值字段名',
    `predicted_id_field` VARCHAR(128) DEFAULT NULL COMMENT '预测值ID字段名',
    `desc_value_field` VARCHAR(128) DEFAULT NULL COMMENT '描述值字段名',
    `matrix_strategy` VARCHAR(64) DEFAULT 'auto' COMMENT '矩阵策略: auto-自动计算, manual-手动设置',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`report_id`, `task_id`, `case_id`),
    KEY `idx_report_task` (`report_id`, `task_id`),
    KEY `idx_task` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='矩阵参数配置表';

-- ============================================
-- 2. 矩阵详情数据表
-- 存储每条评估记录的实际值、预测值等
-- ============================================
DROP TABLE IF EXISTS `task_evaluate_matrix_detail`;
CREATE TABLE `task_evaluate_matrix_detail` (
    `report_id` VARCHAR(64) NOT NULL COMMENT '报告ID',
    `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
    `case_id` VARCHAR(64) NOT NULL COMMENT '用例ID',
    `corpus_id` VARCHAR(128) NOT NULL COMMENT '语料ID/数据ID',
    `actural_value` VARCHAR(64) DEFAULT NULL COMMENT '实际值',
    `predicted_value` VARCHAR(64) DEFAULT NULL COMMENT '预测值',
    `desc_value` VARCHAR(255) DEFAULT NULL COMMENT '描述值/显示说明',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`report_id`, `task_id`, `case_id`, `corpus_id`),
    KEY `idx_report_task` (`report_id`, `task_id`),
    KEY `idx_report_task_case` (`report_id`, `task_id`, `case_id`),
    KEY `idx_actural_predicted` (`actural_value`, `predicted_value`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='矩阵详情数据表';

-- ============================================
-- 3. 标记映射表（未来扩展）
-- 用于将actural_value转换为desc_value
-- ============================================
DROP TABLE IF EXISTS `task_evaluate_matrix_mark`;
CREATE TABLE `task_evaluate_matrix_mark` (
    `id` BIGINT AUTO_INCREMENT COMMENT '自增主键',
    `case_id` VARCHAR(64) NOT NULL COMMENT '用例ID',
    `indicate_id` VARCHAR(64) NOT NULL COMMENT '指标ID/值ID',
    `value` VARCHAR(64) DEFAULT NULL COMMENT '值',
    `desc_value` VARCHAR(255) DEFAULT NULL COMMENT '描述值',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_case_indicate` (`case_id`, `indicate_id`),
    KEY `idx_case` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='标记映射表';

-- ============================================
-- 测试数据
-- ============================================

-- 插入参数配置测试数据
INSERT INTO `task_evaluate_matrix_param` 
(`report_id`, `task_id`, `case_id`, `actural_value_field`, `actural_id_field`, `predicted_value_field`, `predicted_id_field`, `desc_value_field`, `matrix_strategy`)
VALUES 
('RPT001', 'TASK001', 'CASE001', 'actual_level', 'actual_id', 'predict_level', 'predict_id', 'level_name', 'auto'),
('RPT001', 'TASK001', 'CASE002', 'actual_level', 'actual_id', 'predict_level', 'predict_id', 'level_name', 'auto'),
('RPT001', 'TASK001', 'CASE003', 'actual_level', 'actual_id', 'predict_level', 'predict_id', 'level_name', 'auto');

-- 插入详情测试数据 - CASE001 (10维矩阵，100条数据)
INSERT INTO `task_evaluate_matrix_detail` 
(`report_id`, `task_id`, `case_id`, `corpus_id`, `actural_value`, `predicted_value`, `desc_value`)
VALUES 
-- 预测正确的数据 (约80%)
('RPT001', 'TASK001', 'CASE001', 'C001', '0', '0', '极低'),
('RPT001', 'TASK001', 'CASE001', 'C002', '0', '0', '极低'),
('RPT001', 'TASK001', 'CASE001', 'C003', '1', '1', '很低'),
('RPT001', 'TASK001', 'CASE001', 'C004', '1', '1', '很低'),
('RPT001', 'TASK001', 'CASE001', 'C005', '2', '2', '低'),
('RPT001', 'TASK001', 'CASE001', 'C006', '2', '2', '低'),
('RPT001', 'TASK001', 'CASE001', 'C007', '3', '3', '较低'),
('RPT001', 'TASK001', 'CASE001', 'C008', '3', '3', '较低'),
('RPT001', 'TASK001', 'CASE001', 'C009', '4', '4', '中等'),
('RPT001', 'TASK001', 'CASE001', 'C010', '4', '4', '中等'),
('RPT001', 'TASK001', 'CASE001', 'C011', '5', '5', '较高'),
('RPT001', 'TASK001', 'CASE001', 'C012', '5', '5', '较高'),
('RPT001', 'TASK001', 'CASE001', 'C013', '6', '6', '高'),
('RPT001', 'TASK001', 'CASE001', 'C014', '6', '6', '高'),
('RPT001', 'TASK001', 'CASE001', 'C015', '7', '7', '很高'),
('RPT001', 'TASK001', 'CASE001', 'C016', '7', '7', '很高'),
('RPT001', 'TASK001', 'CASE001', 'C017', '8', '8', '极高'),
('RPT001', 'TASK001', 'CASE001', 'C018', '8', '8', '极高'),
('RPT001', 'TASK001', 'CASE001', 'C019', '9', '9', '完美'),
('RPT001', 'TASK001', 'CASE001', 'C020', '9', '9', '完美'),
-- 预测错误的数据 (约20%)
('RPT001', 'TASK001', 'CASE001', 'C021', '0', '1', '极低'),
('RPT001', 'TASK001', 'CASE001', 'C022', '1', '0', '很低'),
('RPT001', 'TASK001', 'CASE001', 'C023', '2', '3', '低'),
('RPT001', 'TASK001', 'CASE001', 'C024', '3', '2', '较低'),
('RPT001', 'TASK001', 'CASE001', 'C025', '4', '5', '中等'),
('RPT001', 'TASK001', 'CASE001', 'C026', '5', '4', '较高'),
('RPT001', 'TASK001', 'CASE001', 'C027', '6', '7', '高'),
('RPT001', 'TASK001', 'CASE001', 'C028', '7', '6', '很高'),
('RPT001', 'TASK001', 'CASE001', 'C029', '8', '9', '极高'),
('RPT001', 'TASK001', 'CASE001', 'C030', '9', '8', '完美'),
-- 无效数据（非数字，用于测试有效样本过滤）
('RPT001', 'TASK001', 'CASE001', 'C031', 'N/A', '5', '无效'),
('RPT001', 'TASK001', 'CASE001', 'C032', '5', 'NULL', '无效'),
('RPT001', 'TASK001', 'CASE001', 'C033', '', '3', '空值'),
('RPT001', 'TASK001', 'CASE001', 'C034', '3', '', '空值');

-- 插入详情测试数据 - CASE002 (15维矩阵)
INSERT INTO `task_evaluate_matrix_detail` 
(`report_id`, `task_id`, `case_id`, `corpus_id`, `actural_value`, `predicted_value`, `desc_value`)
VALUES 
('RPT001', 'TASK001', 'CASE002', 'C001', '0', '0', '等级0'),
('RPT001', 'TASK001', 'CASE002', 'C002', '1', '1', '等级1'),
('RPT001', 'TASK001', 'CASE002', 'C003', '2', '2', '等级2'),
('RPT001', 'TASK001', 'CASE002', 'C004', '3', '3', '等级3'),
('RPT001', 'TASK001', 'CASE002', 'C005', '4', '4', '等级4'),
('RPT001', 'TASK001', 'CASE002', 'C006', '5', '5', '等级5'),
('RPT001', 'TASK001', 'CASE002', 'C007', '6', '6', '等级6'),
('RPT001', 'TASK001', 'CASE002', 'C008', '7', '7', '等级7'),
('RPT001', 'TASK001', 'CASE002', 'C009', '8', '8', '等级8'),
('RPT001', 'TASK001', 'CASE002', 'C010', '9', '9', '等级9'),
('RPT001', 'TASK001', 'CASE002', 'C011', '10', '10', '等级10'),
('RPT001', 'TASK001', 'CASE002', 'C012', '11', '11', '等级11'),
('RPT001', 'TASK001', 'CASE002', 'C013', '12', '12', '等级12'),
('RPT001', 'TASK001', 'CASE002', 'C014', '13', '13', '等级13'),
('RPT001', 'TASK001', 'CASE002', 'C015', '14', '14', '等级14'),
('RPT001', 'TASK001', 'CASE002', 'C016', '0', '1', '等级0'),
('RPT001', 'TASK001', 'CASE002', 'C017', '5', '6', '等级5'),
('RPT001', 'TASK001', 'CASE002', 'C018', '10', '9', '等级10');

-- 插入详情测试数据 - CASE003 (5维矩阵)
INSERT INTO `task_evaluate_matrix_detail` 
(`report_id`, `task_id`, `case_id`, `corpus_id`, `actural_value`, `predicted_value`, `desc_value`)
VALUES 
('RPT001', 'TASK001', 'CASE003', 'C001', '0', '0', '差'),
('RPT001', 'TASK001', 'CASE003', 'C002', '1', '1', '较差'),
('RPT001', 'TASK001', 'CASE003', 'C003', '2', '2', '中'),
('RPT001', 'TASK001', 'CASE003', 'C004', '3', '3', '良'),
('RPT001', 'TASK001', 'CASE003', 'C005', '4', '4', '优'),
('RPT001', 'TASK001', 'CASE003', 'C006', '0', '1', '差'),
('RPT001', 'TASK001', 'CASE003', 'C007', '2', '1', '中'),
('RPT001', 'TASK001', 'CASE003', 'C008', '4', '3', '优');

-- 插入标记映射测试数据
INSERT INTO `task_evaluate_matrix_mark` 
(`case_id`, `indicate_id`, `value`, `desc_value`)
VALUES 
('CASE001', '0', '0', '极低'),
('CASE001', '1', '1', '很低'),
('CASE001', '2', '2', '低'),
('CASE001', '3', '3', '较低'),
('CASE001', '4', '4', '中等'),
('CASE001', '5', '5', '较高'),
('CASE001', '6', '6', '高'),
('CASE001', '7', '7', '很高'),
('CASE001', '8', '8', '极高'),
('CASE001', '9', '9', '完美');

