-- ============================================================
-- 步骤4: 生成可执行的 ALTER TABLE ADD COLUMN 语句
-- 用途: 生成修复缺失字段的SQL语句
-- MySQL 5.7 兼容
-- ============================================================

-- 设置变量（根据实际情况修改）
SET @db_name = 'your_database_name';     -- 替换为你的数据库名
SET @reference_table = 'aa_example';      -- 替换为字段完整的参考表名
SET @table_prefix = 'aa';                 -- 替换为你要检查的表前缀

-- ============================================================
-- 生成 ALTER TABLE ADD COLUMN 语句
-- 此查询将生成可直接执行的SQL语句
-- ============================================================

SELECT
    CONCAT(
        'ALTER TABLE `', @db_name, '`.`', t.TABLE_NAME, '` ADD COLUMN `', ref.COLUMN_NAME, '` ',
        ref.COLUMN_TYPE,
        CASE WHEN ref.IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE ' NULL' END,
        CASE
            WHEN ref.COLUMN_DEFAULT IS NULL AND ref.IS_NULLABLE = 'YES' THEN ' DEFAULT NULL'
            WHEN ref.COLUMN_DEFAULT IS NOT NULL THEN CONCAT(' DEFAULT ''', ref.COLUMN_DEFAULT, '''')
            ELSE ''
        END,
        CASE WHEN ref.COLUMN_COMMENT != '' THEN CONCAT(' COMMENT ''', REPLACE(ref.COLUMN_COMMENT, '''', ''''''), '''') ELSE '' END,
        CASE
            WHEN ref.AFTER_COLUMN IS NOT NULL THEN CONCAT(' AFTER `', ref.AFTER_COLUMN, '`')
            ELSE ''
        END,
        ';'
    ) AS 'ALTER_STATEMENT'
FROM
    information_schema.TABLES t
CROSS JOIN
    (
        SELECT
            c1.COLUMN_NAME,
            c1.COLUMN_TYPE,
            c1.IS_NULLABLE,
            c1.COLUMN_DEFAULT,
            c1.COLUMN_COMMENT,
            c1.ORDINAL_POSITION,
            (SELECT c2.COLUMN_NAME
             FROM information_schema.COLUMNS c2
             WHERE c2.TABLE_SCHEMA = c1.TABLE_SCHEMA
               AND c2.TABLE_NAME = c1.TABLE_NAME
               AND c2.ORDINAL_POSITION = c1.ORDINAL_POSITION - 1) AS AFTER_COLUMN
        FROM information_schema.COLUMNS c1
        WHERE c1.TABLE_SCHEMA = @db_name AND c1.TABLE_NAME = @reference_table
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
