-- ============================================================
-- 步骤2: 获取参考表（完整的example表）的所有字段信息
-- 用途: 获取作为基准的表的完整字段定义
-- MySQL 5.7 兼容
-- ============================================================

-- 设置变量（根据实际情况修改）
SET @db_name = 'your_database_name';     -- 替换为你的数据库名
SET @reference_table = 'aa_example';      -- 替换为字段完整的参考表名

-- 查询参考表的所有字段详细信息
SELECT
    COLUMN_NAME AS '字段名',
    ORDINAL_POSITION AS '字段顺序',
    COLUMN_DEFAULT AS '默认值',
    IS_NULLABLE AS '是否允许NULL',
    DATA_TYPE AS '数据类型',
    CHARACTER_MAXIMUM_LENGTH AS '字符最大长度',
    NUMERIC_PRECISION AS '数值精度',
    NUMERIC_SCALE AS '数值小数位',
    COLUMN_TYPE AS '完整列类型',
    COLUMN_KEY AS '索引类型',
    EXTRA AS '额外属性',
    COLUMN_COMMENT AS '字段注释'
FROM
    information_schema.COLUMNS
WHERE
    TABLE_SCHEMA = @db_name
    AND TABLE_NAME = @reference_table
ORDER BY
    ORDINAL_POSITION;

-- 查询参考表的字段数量
SELECT
    COUNT(*) AS '参考表字段总数'
FROM
    information_schema.COLUMNS
WHERE
    TABLE_SCHEMA = @db_name
    AND TABLE_NAME = @reference_table;

-- 查询参考表的建表语句（用于查看完整定义）
-- 注意：需要有SELECT权限
SHOW CREATE TABLE your_database_name.aa_example;
