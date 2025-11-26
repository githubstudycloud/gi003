-- ========================================
-- MySQL 5.7 表结构检查和修复工具
-- ========================================
-- 使用方法：只需修改下方的 3 个配置变量，然后执行全部 SQL

-- ========================================
-- 【配置区】只需修改这里
-- ========================================
SET @db_name = 'your_database_name';  -- 数据库名
SET @table_prefix = 'aa';              -- 表前缀（不含%）
SET @standard_table = 'aa_example';    -- 标准表名（字段完整的表）

-- 切换数据库（如果变量方式不生效，手动修改这行）
-- USE your_database_name;

-- ========================================
-- 步骤 1: 查看所有匹配前缀的表
-- ========================================
SELECT '===== 步骤1: 所有匹配的表 =====' AS '';

SET @sql = CONCAT('
SELECT
    TABLE_NAME AS 表名,
    ENGINE AS 引擎,
    TABLE_ROWS AS 行数,
    CREATE_TIME AS 创建时间
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = ''', @db_name, '''
    AND TABLE_NAME LIKE ''', @table_prefix, '%''
ORDER BY TABLE_NAME');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================
-- 步骤 2: 查看标准表的字段结构
-- ========================================
SELECT '===== 步骤2: 标准表字段结构 =====' AS '';

SET @sql = CONCAT('
SELECT
    COLUMN_NAME AS 字段名,
    COLUMN_TYPE AS 类型,
    IS_NULLABLE AS 可空,
    COLUMN_DEFAULT AS 默认值,
    COLUMN_COMMENT AS 注释
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = ''', @db_name, '''
    AND TABLE_NAME = ''', @standard_table, '''
ORDER BY ORDINAL_POSITION');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================
-- 步骤 3: 统计每个表缺少的字段数量
-- ========================================
SELECT '===== 步骤3: 缺失字段统计 =====' AS '';

SET @sql = CONCAT('
SELECT
    t.TABLE_NAME AS 表名,
    COUNT(*) AS 缺少字段数
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = ''', @db_name, '''
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = ''', @db_name, '''
    AND t.TABLE_NAME LIKE ''', @table_prefix, '%''
    AND t.TABLE_NAME != ''', @standard_table, '''
    AND ref.TABLE_SCHEMA = ''', @db_name, '''
    AND ref.TABLE_NAME = ''', @standard_table, '''
    AND exist.COLUMN_NAME IS NULL
GROUP BY t.TABLE_NAME
HAVING COUNT(*) > 0
ORDER BY COUNT(*) DESC');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================
-- 步骤 4: 查看缺失字段详情
-- ========================================
SELECT '===== 步骤4: 缺失字段详情 =====' AS '';

SET @sql = CONCAT('
SELECT
    t.TABLE_NAME AS 表名,
    ref.COLUMN_NAME AS 缺少字段,
    ref.COLUMN_TYPE AS 类型,
    ref.IS_NULLABLE AS 可空,
    ref.COLUMN_DEFAULT AS 默认值
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = ''', @db_name, '''
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = ''', @db_name, '''
    AND t.TABLE_NAME LIKE ''', @table_prefix, '%''
    AND t.TABLE_NAME != ''', @standard_table, '''
    AND ref.TABLE_SCHEMA = ''', @db_name, '''
    AND ref.TABLE_NAME = ''', @standard_table, '''
    AND exist.COLUMN_NAME IS NULL
ORDER BY t.TABLE_NAME, ref.ORDINAL_POSITION');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================
-- 步骤 5: 生成修复 SQL（直接可执行）
-- ========================================
SELECT '===== 步骤5: 修复SQL语句 =====' AS '';

SET @sql = CONCAT('
SELECT CONCAT(
    ''ALTER TABLE `'', t.TABLE_NAME, ''` ADD COLUMN `'', ref.COLUMN_NAME, ''` '',
    ref.COLUMN_TYPE,
    IF(ref.IS_NULLABLE = ''NO'', '' NOT NULL'', ''''),
    CASE
        WHEN ref.COLUMN_DEFAULT IS NULL THEN ''''
        WHEN ref.DATA_TYPE IN (''int'', ''bigint'', ''tinyint'', ''smallint'', ''decimal'', ''float'', ''double'')
            THEN CONCAT('' DEFAULT '', ref.COLUMN_DEFAULT)
        ELSE CONCAT('' DEFAULT \\'''', ref.COLUMN_DEFAULT, ''\\'''')
    END,
    IF(ref.COLUMN_COMMENT != '''', CONCAT('' COMMENT \\'''', ref.COLUMN_COMMENT, ''\\''''), ''''),
    '';''
) AS repair_sql
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = ''', @db_name, '''
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = ''', @db_name, '''
    AND t.TABLE_NAME LIKE ''', @table_prefix, '%''
    AND t.TABLE_NAME != ''', @standard_table, '''
    AND ref.TABLE_SCHEMA = ''', @db_name, '''
    AND ref.TABLE_NAME = ''', @standard_table, '''
    AND exist.COLUMN_NAME IS NULL
ORDER BY t.TABLE_NAME, ref.ORDINAL_POSITION');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT '===== 完成：复制上方SQL执行修复 =====' AS '';
