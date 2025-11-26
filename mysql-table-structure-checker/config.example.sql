-- ========================================
-- 配置文件示例
-- 复制此文件为 config.sql 并修改为你的实际配置
-- ========================================

-- ========================================
-- 基础配置
-- ========================================

-- 数据库名称
SET @database_name = 'your_database_name';

-- 表前缀（支持 LIKE 模糊匹配）
SET @table_prefix = 'aa%';

-- 标准表名称（用作字段结构的参考模板）
SET @standard_table = 'aa_example';

-- ========================================
-- 高级配置
-- ========================================

-- 是否排除某些表（用逗号分隔）
-- 例如：排除备份表、临时表等
SET @exclude_tables = 'aa_backup,aa_temp,aa_archive';

-- 是否只检查特定的表（用逗号分隔）
-- 留空表示检查所有匹配前缀的表
SET @include_only_tables = '';

-- ========================================
-- 连接配置示例
-- ========================================

-- 方式 1: 直接在 SQL 文件中使用
USE your_database_name;

-- 方式 2: 通过命令行连接
-- mysql -h localhost -u username -p -D your_database_name < check_table_structure.sql

-- 方式 3: 使用配置文件
-- mysql --defaults-extra-file=/path/to/my.cnf < check_table_structure.sql

-- ========================================
-- 配置文件示例 (my.cnf)
-- ========================================
/*
[client]
host=localhost
port=3306
user=your_username
password=your_password
database=your_database_name

[mysql]
default-character-set=utf8mb4
*/

-- ========================================
-- 不同场景的配置示例
-- ========================================

-- 场景 1: 用户分表
-- ----------------------------------------
-- SET @database_name = 'user_database';
-- SET @table_prefix = 'user_%';
-- SET @standard_table = 'user_master';

-- 场景 2: 订单分表
-- ----------------------------------------
-- SET @database_name = 'order_database';
-- SET @table_prefix = 'order_%';
-- SET @standard_table = 'order_template';

-- 场景 3: 日志分表（按月）
-- ----------------------------------------
-- SET @database_name = 'log_database';
-- SET @table_prefix = 'log_202%';
-- SET @standard_table = 'log_202401';

-- 场景 4: 多个前缀的表（需要分别检查）
-- ----------------------------------------
-- 检查 aa 前缀
-- SET @table_prefix = 'aa%';
-- SET @standard_table = 'aa_example';

-- 检查 bb 前缀
-- SET @table_prefix = 'bb%';
-- SET @standard_table = 'bb_example';

-- ========================================
-- 安全配置建议
-- ========================================

-- 1. 使用只读用户进行检查
-- CREATE USER 'readonly_user'@'localhost' IDENTIFIED BY 'password';
-- GRANT SELECT ON your_database.* TO 'readonly_user'@'localhost';
-- GRANT SELECT ON information_schema.* TO 'readonly_user'@'localhost';

-- 2. 使用专门的 DBA 用户进行修复
-- CREATE USER 'dba_user'@'localhost' IDENTIFIED BY 'password';
-- GRANT ALTER, SELECT ON your_database.* TO 'dba_user'@'localhost';

-- ========================================
-- 性能优化配置
-- ========================================

-- 对于大量表的情况，可以分批处理
-- 批次 1: 处理前 100 个表
-- SET @batch_start = 0;
-- SET @batch_size = 100;

-- 在查询中添加限制：
-- LIMIT @batch_start, @batch_size

-- ========================================
-- 日志配置
-- ========================================

-- 启用查询日志（用于审计）
-- SET GLOBAL general_log = 'ON';
-- SET GLOBAL general_log_file = '/var/log/mysql/table_check.log';

-- 执行完成后关闭
-- SET GLOBAL general_log = 'OFF';

-- ========================================
-- 环境区分
-- ========================================

-- 开发环境
-- SET @environment = 'development';
-- SET @database_name = 'dev_database';

-- 测试环境
-- SET @environment = 'testing';
-- SET @database_name = 'test_database';

-- 生产环境（谨慎操作）
-- SET @environment = 'production';
-- SET @database_name = 'prod_database';

-- ========================================
-- 备份配置
-- ========================================

-- 执行修复前，建议先备份
-- 备份命令示例：
-- mysqldump -u username -p your_database_name > backup_$(date +%Y%m%d_%H%M%S).sql

-- 或者只备份表结构：
-- mysqldump -u username -p --no-data your_database_name > schema_backup_$(date +%Y%m%d_%H%M%S).sql

-- ========================================
-- 快速配置模板（复制后修改）
-- ========================================

/*
-- === 填写你的配置 ===
USE your_database_name;              -- 1. 修改数据库名

-- 在 SQL 查询中替换：
--   'aa%'         -> 'your_prefix%'  -- 2. 修改表前缀
--   'aa_example'  -> 'your_standard_table'  -- 3. 修改标准表名
*/
