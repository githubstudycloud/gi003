-- ============================================================
-- 步骤5: 生成最终可执行的SQL文件
-- 用途: 将所有修复语句整合到一个可执行的脚本中
-- MySQL 5.7 兼容
-- ============================================================

-- ============================================================
-- 使用方法:
-- 1. 修改下面的变量为实际值
-- 2. 执行此脚本获取所有ALTER语句
-- 3. 将输出结果保存为 .sql 文件
-- 4. 检查语句无误后执行修复
-- ============================================================

-- 设置变量（根据实际情况修改）
SET @db_name = 'your_database_name';     -- 替换为你的数据库名
SET @reference_table = 'aa_example';      -- 替换为字段完整的参考表名
SET @table_prefix = 'aa';                 -- 替换为你要检查的表前缀

-- 设置输出格式
SET SESSION group_concat_max_len = 1000000;

-- ============================================================
-- 方法1: 按表分组生成ALTER语句（推荐）
-- 每个表一条ALTER语句，包含所有缺失字段
-- ============================================================
SELECT
    CONCAT(
        '-- 修复表: ', t.TABLE_NAME, ' (缺少 ', COUNT(*), ' 个字段)\n',
        'ALTER TABLE `', @db_name, '`.`', t.TABLE_NAME, '`\n',
        GROUP_CONCAT(
            CONCAT(
                '  ADD COLUMN `', ref.COLUMN_NAME, '` ',
                ref.COLUMN_TYPE,
                CASE WHEN ref.IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE '' END,
                CASE
                    WHEN ref.COLUMN_DEFAULT IS NULL AND ref.IS_NULLABLE = 'YES' THEN ' DEFAULT NULL'
                    WHEN ref.COLUMN_DEFAULT IS NOT NULL AND ref.DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'float', 'double')
                        THEN CONCAT(' DEFAULT ', ref.COLUMN_DEFAULT)
                    WHEN ref.COLUMN_DEFAULT IS NOT NULL
                        THEN CONCAT(' DEFAULT ''', ref.COLUMN_DEFAULT, '''')
                    ELSE ''
                END,
                CASE WHEN ref.COLUMN_COMMENT != '' THEN CONCAT(' COMMENT ''', REPLACE(ref.COLUMN_COMMENT, '''', ''''''), '''') ELSE '' END
            )
            ORDER BY ref.ORDINAL_POSITION
            SEPARATOR ',\n'
        ),
        ';\n'
    ) AS 'EXECUTABLE_SQL'
FROM
    information_schema.TABLES t
CROSS JOIN
    (
        SELECT
            COLUMN_NAME,
            COLUMN_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            COLUMN_COMMENT,
            ORDINAL_POSITION,
            DATA_TYPE
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table
    ) ref
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
    t.TABLE_NAME
ORDER BY
    t.TABLE_NAME;

-- ============================================================
-- 方法2: 生成单独的ALTER语句（每个字段一条）
-- 更安全，可以逐条执行
-- ============================================================
SELECT
    CONCAT(
        'ALTER TABLE `', @db_name, '`.`', t.TABLE_NAME, '` ',
        'ADD COLUMN `', ref.COLUMN_NAME, '` ',
        ref.COLUMN_TYPE,
        CASE WHEN ref.IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE '' END,
        CASE
            WHEN ref.COLUMN_DEFAULT IS NULL AND ref.IS_NULLABLE = 'YES' THEN ' DEFAULT NULL'
            WHEN ref.COLUMN_DEFAULT IS NOT NULL AND ref.DATA_TYPE IN ('int', 'bigint', 'smallint', 'tinyint', 'decimal', 'float', 'double')
                THEN CONCAT(' DEFAULT ', ref.COLUMN_DEFAULT)
            WHEN ref.COLUMN_DEFAULT IS NOT NULL
                THEN CONCAT(' DEFAULT ''', ref.COLUMN_DEFAULT, '''')
            ELSE ''
        END,
        CASE WHEN ref.COLUMN_COMMENT != '' THEN CONCAT(' COMMENT ''', REPLACE(ref.COLUMN_COMMENT, '''', ''''''), '''') ELSE '' END,
        ';'
    ) AS 'SINGLE_ALTER_STATEMENT'
FROM
    information_schema.TABLES t
CROSS JOIN
    (
        SELECT
            COLUMN_NAME,
            COLUMN_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            COLUMN_COMMENT,
            ORDINAL_POSITION,
            DATA_TYPE
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = @reference_table
    ) ref
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
    t.TABLE_NAME, ref.ORDINAL_POSITION;

-- ============================================================
-- 统计信息
-- ============================================================
SELECT
    '===== 修复统计 =====' AS '信息';

SELECT
    COUNT(DISTINCT t.TABLE_NAME) AS '需要修复的表数量',
    COUNT(*) AS '需要添加的字段总数'
FROM
    information_schema.TABLES t
CROSS JOIN
    (SELECT COLUMN_NAME FROM information_schema.COLUMNS
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
    AND c.COLUMN_NAME IS NULL;
