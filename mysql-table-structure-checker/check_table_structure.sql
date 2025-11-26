-- ========================================
-- MySQL 5.7 表结构检查和修复工具
-- 用于检查以特定前缀开头的表是否缺少字段
-- ========================================

-- 使用说明：
-- 1. 修改数据库名称
-- 2. 修改表前缀（默认为 'aa'）
-- 3. 修改标准表名（默认为 'aa_example'）
-- 4. 依次执行以下 SQL 语句

USE your_database_name;  -- 请修改为实际的数据库名

-- ========================================
-- 步骤 1: 查找所有以指定前缀开头的表
-- ========================================
SELECT
    TABLE_NAME as '表名',
    TABLE_TYPE as '表类型',
    ENGINE as '引擎',
    TABLE_ROWS as '行数',
    CREATE_TIME as '创建时间'
FROM
    information_schema.TABLES
WHERE
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME LIKE 'aa%'  -- 修改前缀
ORDER BY
    TABLE_NAME;


-- ========================================
-- 步骤 2: 获取标准表（aa_example）的所有字段信息
-- ========================================
SELECT
    COLUMN_NAME as '字段名',
    COLUMN_TYPE as '字段类型',
    IS_NULLABLE as '可为空',
    COLUMN_DEFAULT as '默认值',
    COLUMN_COMMENT as '注释',
    ORDINAL_POSITION as '位置'
FROM
    information_schema.COLUMNS
WHERE
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'aa_example'  -- 标准表名
ORDER BY
    ORDINAL_POSITION;


-- ========================================
-- 步骤 3: 对比所有以 aa 开头的表，找出缺少的字段
-- ========================================
SELECT
    t.TABLE_NAME as '表名',
    ref.COLUMN_NAME as '缺少的字段',
    ref.COLUMN_TYPE as '字段类型',
    ref.IS_NULLABLE as '可为空',
    ref.COLUMN_DEFAULT as '默认值',
    ref.COLUMN_COMMENT as '注释',
    ref.ORDINAL_POSITION as '标准位置'
FROM
    information_schema.TABLES t
CROSS JOIN
    information_schema.COLUMNS ref
LEFT JOIN
    information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY
    t.TABLE_NAME, ref.ORDINAL_POSITION;


-- ========================================
-- 步骤 4: 统计每个表缺少的字段数量
-- ========================================
SELECT
    t.TABLE_NAME as '表名',
    COUNT(ref.COLUMN_NAME) as '缺少字段数量'
FROM
    information_schema.TABLES t
CROSS JOIN
    information_schema.COLUMNS ref
LEFT JOIN
    information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
GROUP BY
    t.TABLE_NAME
HAVING
    COUNT(ref.COLUMN_NAME) > 0
ORDER BY
    COUNT(ref.COLUMN_NAME) DESC, t.TABLE_NAME;


-- ========================================
-- 步骤 5: 查找某个特定表缺少哪些字段（示例）
-- ========================================
-- 将 'aa_test' 替换为实际要检查的表名
SELECT
    ref.COLUMN_NAME as '缺少的字段',
    ref.COLUMN_TYPE as '字段类型',
    ref.IS_NULLABLE as '可为空',
    ref.COLUMN_DEFAULT as '默认值',
    ref.COLUMN_COMMENT as '注释'
FROM
    information_schema.COLUMNS ref
LEFT JOIN
    information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = DATABASE()
    AND exist.TABLE_NAME = 'aa_test'  -- 要检查的表名
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY
    ref.ORDINAL_POSITION;


-- ========================================
-- 步骤 6: 生成所有缺失字段的 ALTER TABLE 修复语句
-- ========================================
SELECT
    CONCAT(
        'ALTER TABLE `', t.TABLE_NAME, '` ADD COLUMN `', ref.COLUMN_NAME, '` ',
        ref.COLUMN_TYPE,
        IF(ref.IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'),
        IFNULL(CONCAT(' DEFAULT ',
            IF(ref.DATA_TYPE IN ('varchar', 'char', 'text', 'date', 'datetime', 'timestamp', 'time'),
                CONCAT("'", ref.COLUMN_DEFAULT, "'"),
                ref.COLUMN_DEFAULT)
        ), ''),
        IF(ref.COLUMN_COMMENT != '', CONCAT(" COMMENT '", ref.COLUMN_COMMENT, "'"), ''),
        ';'
    ) as 'ALTER TABLE 语句'
FROM
    information_schema.TABLES t
CROSS JOIN
    information_schema.COLUMNS ref
LEFT JOIN
    information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY
    t.TABLE_NAME, ref.ORDINAL_POSITION;


-- ========================================
-- 步骤 7: 生成带有字段位置的 ALTER TABLE 修复语句（推荐使用）
-- 这个版本会将字段添加到正确的位置
-- ========================================
SELECT
    CONCAT(
        'ALTER TABLE `', t.TABLE_NAME, '` ADD COLUMN `', ref.COLUMN_NAME, '` ',
        ref.COLUMN_TYPE,
        IF(ref.IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'),
        IFNULL(CONCAT(' DEFAULT ',
            IF(ref.DATA_TYPE IN ('varchar', 'char', 'text', 'date', 'datetime', 'timestamp', 'time'),
                CONCAT("'", ref.COLUMN_DEFAULT, "'"),
                ref.COLUMN_DEFAULT)
        ), ''),
        IF(ref.COLUMN_COMMENT != '', CONCAT(" COMMENT '", ref.COLUMN_COMMENT, "'"), ''),
        -- 添加字段位置信息
        IF(ref.ORDINAL_POSITION = 1,
            ' FIRST',
            CONCAT(' AFTER `', (
                SELECT COLUMN_NAME
                FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                    AND TABLE_NAME = 'aa_example'
                    AND ORDINAL_POSITION = ref.ORDINAL_POSITION - 1
            ), '`')
        ),
        ';'
    ) as 'ALTER TABLE 语句'
FROM
    information_schema.TABLES t
CROSS JOIN
    information_schema.COLUMNS ref
LEFT JOIN
    information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE
    t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY
    t.TABLE_NAME, ref.ORDINAL_POSITION;
