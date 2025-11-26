-- ========================================
-- MySQL 5.7 表结构检查和修复工具 v2.0
-- 支持任意前缀的表结构一致性检查
-- ========================================
-- 使用方法：只需修改下方的 3 个配置变量，然后执行全部 SQL
-- 
-- 功能特性：
-- 1. 查询所有匹配前缀的表
-- 2. 展示标准表的完整字段结构
-- 3. 统计每个表缺少的字段数量
-- 4. 显示缺失字段的详细信息
-- 5. 生成可直接执行的 ALTER TABLE 语句

-- ========================================
-- 【配置区】只需修改这里
-- ========================================
SET @db_name = 'your_database_name';  -- 数据库名（必须修改）
SET @table_prefix = 'aa';              -- 表前缀（不含%，如 aa、order、user 等任意前缀）
SET @standard_table = 'aa_example';    -- 标准表名（字段完整的参考表）

-- ========================================
-- 步骤 1: 查看所有匹配前缀的表
-- 功能：列出数据库中所有以指定前缀开头的表
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤1: 查询所有以指定前缀开头的表' AS '操作说明';
SELECT '============================================' AS '';

SET @sql1 = CONCAT('
SELECT
    TABLE_NAME AS `表名`,
    ENGINE AS `存储引擎`,
    TABLE_ROWS AS `估计行数`,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS `数据大小(MB)`,
    CREATE_TIME AS `创建时间`,
    UPDATE_TIME AS `最后更新时间`
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = ''', @db_name, '''
    AND TABLE_NAME LIKE ''', @table_prefix, '%''
ORDER BY TABLE_NAME');

PREPARE stmt1 FROM @sql1;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

-- ========================================
-- 步骤 2: 查看标准表的完整字段结构
-- 功能：展示参考表的所有字段信息，作为对比基准
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤2: 标准表（参考表）的字段结构' AS '操作说明';
SELECT CONCAT('参考表: ', @standard_table) AS '标准表名';
SELECT '============================================' AS '';

SET @sql2 = CONCAT('
SELECT
    ORDINAL_POSITION AS `字段序号`,
    COLUMN_NAME AS `字段名`,
    COLUMN_TYPE AS `字段类型`,
    IS_NULLABLE AS `是否可空`,
    IFNULL(COLUMN_DEFAULT, ''(无默认值)'') AS `默认值`,
    EXTRA AS `额外属性`,
    COLUMN_COMMENT AS `字段注释`
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = ''', @db_name, '''
    AND TABLE_NAME = ''', @standard_table, '''
ORDER BY ORDINAL_POSITION');

PREPARE stmt2 FROM @sql2;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;

-- ========================================
-- 步骤 3: 统计每个表缺少的字段数量
-- 功能：汇总显示哪些表存在字段缺失，以及缺失数量
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤3: 缺失字段统计（哪些表需要修复）' AS '操作说明';
SELECT '============================================' AS '';

SET @sql3 = CONCAT('
SELECT
    t.TABLE_NAME AS `表名`,
    (SELECT COUNT(*) FROM information_schema.COLUMNS 
     WHERE TABLE_SCHEMA = ''', @db_name, ''' AND TABLE_NAME = ''', @standard_table, ''') AS `标准表字段数`,
    (SELECT COUNT(*) FROM information_schema.COLUMNS 
     WHERE TABLE_SCHEMA = ''', @db_name, ''' AND TABLE_NAME = t.TABLE_NAME) AS `当前表字段数`,
    COUNT(*) AS `缺少字段数`,
    CASE 
        WHEN COUNT(*) = 0 THEN ''✓ 正常''
        WHEN COUNT(*) <= 2 THEN ''⚠ 少量缺失''
        ELSE ''✗ 严重缺失''
    END AS `状态`
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
ORDER BY COUNT(*) DESC, t.TABLE_NAME');

PREPARE stmt3 FROM @sql3;
EXECUTE stmt3;
DEALLOCATE PREPARE stmt3;

-- ========================================
-- 步骤 4: 查看缺失字段详情
-- 功能：详细列出每个表缺少的具体字段信息
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤4: 缺失字段详情（具体缺少哪些字段）' AS '操作说明';
SELECT '============================================' AS '';

SET @sql4 = CONCAT('
SELECT
    t.TABLE_NAME AS `表名`,
    ref.ORDINAL_POSITION AS `字段序号`,
    ref.COLUMN_NAME AS `缺少的字段`,
    ref.COLUMN_TYPE AS `字段类型`,
    ref.IS_NULLABLE AS `是否可空`,
    IFNULL(ref.COLUMN_DEFAULT, ''(无)'') AS `默认值`,
    ref.COLUMN_COMMENT AS `字段注释`
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

PREPARE stmt4 FROM @sql4;
EXECUTE stmt4;
DEALLOCATE PREPARE stmt4;

-- ========================================
-- 步骤 5: 生成可执行的修复SQL语句（基础版）
-- 功能：生成 ALTER TABLE ADD COLUMN 语句（字段添加到末尾）
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤5: 生成修复SQL语句（基础版-添加到表末尾）' AS '操作说明';
SELECT '复制以下SQL语句执行即可修复缺失字段' AS '使用方法';
SELECT '============================================' AS '';

SET @sql5 = CONCAT('
SELECT CONCAT(
    ''ALTER TABLE `'', t.TABLE_NAME, ''` ADD COLUMN `'', ref.COLUMN_NAME, ''` '',
    ref.COLUMN_TYPE,
    IF(ref.IS_NULLABLE = ''NO'', '' NOT NULL'', '' NULL''),
    CASE
        WHEN ref.COLUMN_DEFAULT IS NULL AND ref.IS_NULLABLE = ''YES'' THEN '' DEFAULT NULL''
        WHEN ref.COLUMN_DEFAULT IS NULL THEN ''''
        WHEN ref.COLUMN_DEFAULT = ''CURRENT_TIMESTAMP'' THEN '' DEFAULT CURRENT_TIMESTAMP''
        WHEN ref.DATA_TYPE IN (''int'', ''bigint'', ''tinyint'', ''smallint'', ''mediumint'', ''decimal'', ''float'', ''double'', ''bit'')
            THEN CONCAT('' DEFAULT '', ref.COLUMN_DEFAULT)
        ELSE CONCAT('' DEFAULT \\'''', REPLACE(ref.COLUMN_DEFAULT, ''\\'''', ''\\\\\\''''), ''\\'''')
    END,
    IF(ref.EXTRA != '''', CONCAT('' '', ref.EXTRA), ''''),
    IF(ref.COLUMN_COMMENT != '''', CONCAT('' COMMENT \\'''', REPLACE(ref.COLUMN_COMMENT, ''\\'''', ''\\\\\\''''), ''\\''''), ''''),
    '';''
) AS `执行以下SQL修复`
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

PREPARE stmt5 FROM @sql5;
EXECUTE stmt5;
DEALLOCATE PREPARE stmt5;

-- ========================================
-- 步骤 6: 生成带字段位置的修复SQL语句（推荐版）
-- 功能：生成 ALTER TABLE ADD COLUMN ... AFTER 语句（保持字段顺序）
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤6: 生成修复SQL语句（推荐版-保持字段顺序）' AS '操作说明';
SELECT '使用 AFTER 子句确保字段顺序与标准表一致' AS '使用方法';
SELECT '============================================' AS '';

SET @sql6 = CONCAT('
SELECT CONCAT(
    ''ALTER TABLE `'', t.TABLE_NAME, ''` ADD COLUMN `'', ref.COLUMN_NAME, ''` '',
    ref.COLUMN_TYPE,
    IF(ref.IS_NULLABLE = ''NO'', '' NOT NULL'', '' NULL''),
    CASE
        WHEN ref.COLUMN_DEFAULT IS NULL AND ref.IS_NULLABLE = ''YES'' THEN '' DEFAULT NULL''
        WHEN ref.COLUMN_DEFAULT IS NULL THEN ''''
        WHEN ref.COLUMN_DEFAULT = ''CURRENT_TIMESTAMP'' THEN '' DEFAULT CURRENT_TIMESTAMP''
        WHEN ref.DATA_TYPE IN (''int'', ''bigint'', ''tinyint'', ''smallint'', ''mediumint'', ''decimal'', ''float'', ''double'', ''bit'')
            THEN CONCAT('' DEFAULT '', ref.COLUMN_DEFAULT)
        ELSE CONCAT('' DEFAULT \\'''', REPLACE(ref.COLUMN_DEFAULT, ''\\'''', ''\\\\\\''''), ''\\'''')
    END,
    IF(ref.EXTRA != '''', CONCAT('' '', ref.EXTRA), ''''),
    IF(ref.COLUMN_COMMENT != '''', CONCAT('' COMMENT \\'''', REPLACE(ref.COLUMN_COMMENT, ''\\'''', ''\\\\\\''''), ''\\''''), ''''),
    CASE
        WHEN ref.ORDINAL_POSITION = 1 THEN '' FIRST''
        ELSE CONCAT('' AFTER `'', 
            (SELECT c2.COLUMN_NAME FROM information_schema.COLUMNS c2 
             WHERE c2.TABLE_SCHEMA = ''', @db_name, ''' 
             AND c2.TABLE_NAME = ''', @standard_table, ''' 
             AND c2.ORDINAL_POSITION = ref.ORDINAL_POSITION - 1),
            ''`'')
    END,
    '';''
) AS `执行以下SQL修复(保持顺序)`
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

PREPARE stmt6 FROM @sql6;
EXECUTE stmt6;
DEALLOCATE PREPARE stmt6;

-- ========================================
-- 步骤 7: 汇总报告
-- 功能：生成修复操作的汇总信息
-- ========================================
SELECT '============================================' AS '';
SELECT '步骤7: 修复汇总报告' AS '操作说明';
SELECT '============================================' AS '';

SET @sql7 = CONCAT('
SELECT 
    ''总计'' AS `统计项`,
    COUNT(DISTINCT t.TABLE_NAME) AS `需要修复的表数`,
    COUNT(*) AS `需要添加的字段数`
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
    AND exist.COLUMN_NAME IS NULL');

PREPARE stmt7 FROM @sql7;
EXECUTE stmt7;
DEALLOCATE PREPARE stmt7;

SELECT '============================================' AS '';
SELECT '操作完成！请检查上方步骤5或步骤6生成的SQL语句' AS '提示';
SELECT '建议：1.先在测试环境执行 2.执行前备份数据库 3.在业务低峰期操作' AS '注意事项';
SELECT '============================================' AS '';
