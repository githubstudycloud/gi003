-- ========================================
-- 使用示例：实际场景演示
-- ========================================

-- 假设场景：
-- 我们有一个用户分表系统，标准表为 aa_example
-- 其他表为 aa_user_001, aa_user_002, aa_user_003 等
-- 需要确保所有分表结构与标准表一致

-- ========================================
-- 示例 1: 基础使用流程
-- ========================================

-- 1. 切换到目标数据库
USE my_database;

-- 2. 查看所有以 aa 开头的表
SELECT TABLE_NAME, ENGINE, TABLE_ROWS, CREATE_TIME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME LIKE 'aa%'
ORDER BY TABLE_NAME;

-- 预期输出：
-- +-------------+--------+------------+---------------------+
-- | TABLE_NAME  | ENGINE | TABLE_ROWS | CREATE_TIME         |
-- +-------------+--------+------------+---------------------+
-- | aa_example  | InnoDB |       1000 | 2024-01-01 10:00:00 |
-- | aa_user_001 | InnoDB |        500 | 2024-01-02 10:00:00 |
-- | aa_user_002 | InnoDB |        300 | 2024-01-03 10:00:00 |
-- | aa_user_003 | InnoDB |        200 | 2024-01-04 10:00:00 |
-- +-------------+--------+------------+---------------------+

-- 3. 查看标准表结构
SHOW FULL COLUMNS FROM aa_example;

-- 预期输出示例：
-- +--------------+--------------+------+-----+-------------------+-------+----------+
-- | Field        | Type         | Null | Key | Default           | Extra | Comment  |
-- +--------------+--------------+------+-----+-------------------+-------+----------+
-- | id           | int(11)      | NO   | PRI | NULL              |       | 主键ID   |
-- | user_name    | varchar(100) | NO   |     | NULL              |       | 用户名   |
-- | email        | varchar(100) | YES  |     | NULL              |       | 邮箱     |
-- | phone        | varchar(20)  | YES  |     | NULL              |       | 手机号   |
-- | status       | tinyint(1)   | NO   |     | 1                 |       | 状态     |
-- | created_at   | datetime     | NO   |     | CURRENT_TIMESTAMP |       | 创建时间 |
-- | updated_at   | datetime     | YES  |     | NULL              |       | 更新时间 |
-- +--------------+--------------+------+-----+-------------------+-------+----------+

-- 4. 快速检查：统计缺失字段数量
SELECT
    t.TABLE_NAME as '表名',
    COUNT(ref.COLUMN_NAME) as '缺少字段数量'
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
GROUP BY t.TABLE_NAME
HAVING COUNT(ref.COLUMN_NAME) > 0
ORDER BY COUNT(ref.COLUMN_NAME) DESC;

-- 预期输出示例：
-- +-------------+------------------+
-- | 表名        | 缺少字段数量     |
-- +-------------+------------------+
-- | aa_user_002 |                2 |
-- | aa_user_003 |                1 |
-- +-------------+------------------+

-- 5. 生成修复语句并执行
SELECT CONCAT(
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
) as 'ALTER_TABLE_语句'
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY t.TABLE_NAME, ref.ORDINAL_POSITION;

-- 预期输出示例（可直接复制执行）：
-- ALTER TABLE `aa_user_002` ADD COLUMN `phone` varchar(20) NULL COMMENT '手机号';
-- ALTER TABLE `aa_user_002` ADD COLUMN `updated_at` datetime NULL COMMENT '更新时间';
-- ALTER TABLE `aa_user_003` ADD COLUMN `updated_at` datetime NULL COMMENT '更新时间';


-- ========================================
-- 示例 2: 检查特定表的缺失字段
-- ========================================

-- 检查 aa_user_002 表缺少哪些字段
SELECT
    ref.COLUMN_NAME as '缺少的字段',
    ref.COLUMN_TYPE as '字段类型',
    ref.IS_NULLABLE as '可为空',
    ref.COLUMN_DEFAULT as '默认值',
    ref.COLUMN_COMMENT as '注释',
    ref.ORDINAL_POSITION as '位置'
FROM information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = DATABASE()
    AND exist.TABLE_NAME = 'aa_user_002'
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY ref.ORDINAL_POSITION;


-- ========================================
-- 示例 3: 详细对比两个表的字段差异
-- ========================================

-- 对比 aa_example 和 aa_user_001 的字段差异
SELECT
    COALESCE(ref.COLUMN_NAME, exist.COLUMN_NAME) as '字段名',
    ref.COLUMN_NAME as '标准表中存在',
    exist.COLUMN_NAME as '目标表中存在',
    CASE
        WHEN ref.COLUMN_NAME IS NULL THEN '多余字段'
        WHEN exist.COLUMN_NAME IS NULL THEN '缺失字段'
        ELSE '都存在'
    END as '状态',
    ref.COLUMN_TYPE as '标准表类型',
    exist.COLUMN_TYPE as '目标表类型',
    CASE
        WHEN ref.COLUMN_TYPE = exist.COLUMN_TYPE THEN '一致'
        WHEN exist.COLUMN_TYPE IS NULL THEN '-'
        ELSE '不一致'
    END as '类型对比'
FROM information_schema.COLUMNS ref
FULL OUTER JOIN information_schema.COLUMNS exist
    ON exist.COLUMN_NAME = ref.COLUMN_NAME
    AND exist.TABLE_SCHEMA = DATABASE()
    AND exist.TABLE_NAME = 'aa_user_001'
WHERE ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
ORDER BY COALESCE(ref.ORDINAL_POSITION, exist.ORDINAL_POSITION);


-- ========================================
-- 示例 4: 批量修复（完整流程）
-- ========================================

-- 步骤 1: 开始事务（可选，用于回滚）
START TRANSACTION;

-- 步骤 2: 执行修复语句（从步骤 5 的输出复制）
-- 示例：
-- ALTER TABLE `aa_user_002` ADD COLUMN `phone` varchar(20) NULL COMMENT '手机号';
-- ALTER TABLE `aa_user_002` ADD COLUMN `updated_at` datetime NULL COMMENT '更新时间';
-- ALTER TABLE `aa_user_003` ADD COLUMN `updated_at` datetime NULL COMMENT '更新时间';

-- 步骤 3: 验证修复结果
SELECT
    t.TABLE_NAME as '表名',
    COUNT(ref.COLUMN_NAME) as '缺少字段数量'
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
GROUP BY t.TABLE_NAME
HAVING COUNT(ref.COLUMN_NAME) > 0;

-- 预期：查询结果为空，表示所有字段已补齐

-- 步骤 4: 如果验证通过，提交事务
COMMIT;
-- 如果验证失败，回滚事务
-- ROLLBACK;


-- ========================================
-- 示例 5: 不同前缀的表结构检查
-- ========================================

-- 检查所有以 user_ 开头的表
SELECT
    t.TABLE_NAME as '表名',
    COUNT(ref.COLUMN_NAME) as '缺少字段数量'
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'user_%'  -- 修改前缀
    AND t.TABLE_NAME != 'user_master'  -- 修改标准表名
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'user_master'  -- 修改标准表名
    AND exist.COLUMN_NAME IS NULL
GROUP BY t.TABLE_NAME
HAVING COUNT(ref.COLUMN_NAME) > 0
ORDER BY COUNT(ref.COLUMN_NAME) DESC;


-- ========================================
-- 示例 6: 导出可执行的修复脚本
-- ========================================

-- 生成完整的可执行脚本
SELECT CONCAT(
    '-- 修复表: ', t.TABLE_NAME, '\n',
    'ALTER TABLE `', t.TABLE_NAME, '` ADD COLUMN `', ref.COLUMN_NAME, '` ',
    ref.COLUMN_TYPE,
    IF(ref.IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'),
    IFNULL(CONCAT(' DEFAULT ',
        IF(ref.DATA_TYPE IN ('varchar', 'char', 'text', 'date', 'datetime', 'timestamp', 'time'),
            CONCAT("'", ref.COLUMN_DEFAULT, "'"),
            ref.COLUMN_DEFAULT)
    ), ''),
    IF(ref.COLUMN_COMMENT != '', CONCAT(" COMMENT '", ref.COLUMN_COMMENT, "'"), ''),
    ';\n'
) as 'SQL脚本'
FROM information_schema.TABLES t
CROSS JOIN information_schema.COLUMNS ref
LEFT JOIN information_schema.COLUMNS exist
    ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND exist.TABLE_NAME = t.TABLE_NAME
    AND exist.COLUMN_NAME = ref.COLUMN_NAME
WHERE t.TABLE_SCHEMA = DATABASE()
    AND t.TABLE_NAME LIKE 'aa%'
    AND t.TABLE_NAME != 'aa_example'
    AND ref.TABLE_SCHEMA = DATABASE()
    AND ref.TABLE_NAME = 'aa_example'
    AND exist.COLUMN_NAME IS NULL
ORDER BY t.TABLE_NAME, ref.ORDINAL_POSITION
INTO OUTFILE '/tmp/repair_script.sql';

-- 然后可以执行：
-- mysql -u username -p database_name < /tmp/repair_script.sql


-- ========================================
-- 示例 7: 验证所有表结构完全一致
-- ========================================

-- 检查所有表的字段数量是否一致
SELECT
    TABLE_NAME as '表名',
    COUNT(*) as '字段数量'
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME LIKE 'aa%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

-- 如果所有表字段数量相同，则结构基本一致
-- 预期输出示例（所有表字段数都是 7）：
-- +-------------+--------------+
-- | 表名        | 字段数量     |
-- +-------------+--------------+
-- | aa_example  |            7 |
-- | aa_user_001 |            7 |
-- | aa_user_002 |            7 |
-- | aa_user_003 |            7 |
-- +-------------+--------------+
