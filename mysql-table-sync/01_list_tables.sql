-- ============================================================
-- 步骤1: 查询所有以指定前缀开头的表
-- 用途: 列出数据库中所有以 'aa' 或其他前缀开头的表
-- MySQL 5.7 兼容
-- ============================================================

-- 设置变量（根据实际情况修改）
SET @db_name = 'your_database_name';  -- 替换为你的数据库名
SET @table_prefix = 'aa';              -- 替换为你要检查的表前缀

-- 查询所有以指定前缀开头的表
SELECT
    TABLE_NAME AS '表名',
    TABLE_ROWS AS '预估行数',
    CREATE_TIME AS '创建时间',
    UPDATE_TIME AS '更新时间',
    TABLE_COMMENT AS '表注释'
FROM
    information_schema.TABLES
WHERE
    TABLE_SCHEMA = @db_name
    AND TABLE_NAME LIKE CONCAT(@table_prefix, '%')
ORDER BY
    TABLE_NAME;

-- 统计表数量
SELECT
    COUNT(*) AS '符合条件的表总数'
FROM
    information_schema.TABLES
WHERE
    TABLE_SCHEMA = @db_name
    AND TABLE_NAME LIKE CONCAT(@table_prefix, '%');
