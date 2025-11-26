-- ============================================================
-- 步骤3: 对比所有同前缀表与参考表的字段差异
-- 用途: 找出哪些表缺少哪些字段
-- MySQL 5.7 兼容
-- ============================================================

-- 设置变量（根据实际情况修改）
SET @db_name = 'your_database_name';     -- 替换为你的数据库名
SET @reference_table = 'aa_example';      -- 替换为字段完整的参考表名
SET @table_prefix = 'aa';                 -- 替换为你要检查的表前缀

-- ============================================================
-- 3.1 查询各表的字段数量对比
-- ============================================================
SELECT
    t.TABLE_NAME AS '表名',
    COUNT(c.COLUMN_NAME) AS '当前字段数',
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table) AS '参考表字段数',
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table) - COUNT(c.COLUMN_NAME) AS '缺少字段数'
FROM
    information_schema.TABLES t
LEFT JOIN
    information_schema.COLUMNS c ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE
    t.TABLE_SCHEMA = @db_name
    AND t.TABLE_NAME LIKE CONCAT(@table_prefix, '%')
    AND t.TABLE_NAME != @reference_table
GROUP BY
    t.TABLE_NAME
HAVING
    COUNT(c.COLUMN_NAME) < (SELECT COUNT(*) FROM information_schema.COLUMNS
                             WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table)
ORDER BY
    '缺少字段数' DESC;

-- ============================================================
-- 3.2 查询每个表缺少的具体字段
-- ============================================================
SELECT
    t.TABLE_NAME AS '表名',
    ref.COLUMN_NAME AS '缺少的字段',
    ref.COLUMN_TYPE AS '字段类型',
    ref.IS_NULLABLE AS '是否允许NULL',
    ref.COLUMN_DEFAULT AS '默认值',
    ref.COLUMN_COMMENT AS '字段注释'
FROM
    information_schema.TABLES t
CROSS JOIN
    (SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, COLUMN_COMMENT
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table) ref
LEFT JOIN
    information_schema.COLUMNS c
    ON c.TABLE_SCHEMA = @db_name
    AND c.TABLE_NAME = t.TABLE_NAME
    AND c.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    t.TABLE_SCHEMA = @db_name
    AND t.TABLE_NAME LIKE CONCAT(@table_prefix, '%')
    AND t.TABLE_NAME != @reference_table
    AND c.COLUMN_NAME IS NULL
ORDER BY
    t.TABLE_NAME, ref.COLUMN_NAME;

-- ============================================================
-- 3.3 汇总统计：每个缺失字段影响了多少张表
-- ============================================================
SELECT
    ref.COLUMN_NAME AS '缺失的字段名',
    ref.COLUMN_TYPE AS '字段类型',
    COUNT(DISTINCT t.TABLE_NAME) AS '受影响的表数量'
FROM
    information_schema.TABLES t
CROSS JOIN
    (SELECT COLUMN_NAME, COLUMN_TYPE
     FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table) ref
LEFT JOIN
    information_schema.COLUMNS c
    ON c.TABLE_SCHEMA = @db_name
    AND c.TABLE_NAME = t.TABLE_NAME
    AND c.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    t.TABLE_SCHEMA = @db_name
    AND t.TABLE_NAME LIKE CONCAT(@table_prefix, '%')
    AND t.TABLE_NAME != @reference_table
    AND c.COLUMN_NAME IS NULL
GROUP BY
    ref.COLUMN_NAME, ref.COLUMN_TYPE
ORDER BY
    COUNT(DISTINCT t.TABLE_NAME) DESC;
