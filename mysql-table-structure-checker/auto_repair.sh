#!/bin/bash

# ========================================
# MySQL 表结构自动检查和修复脚本
# ========================================

set -e  # 遇到错误立即退出

# ========================================
# 配置部分（请根据实际情况修改）
# ========================================

# MySQL 连接配置
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-your_database}"

# 表配置
TABLE_PREFIX="${TABLE_PREFIX:-aa}"
STANDARD_TABLE="${STANDARD_TABLE:-aa_example}"

# 工作目录
WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${WORK_DIR}/output"
BACKUP_DIR="${WORK_DIR}/backups"
LOG_DIR="${WORK_DIR}/logs"

# 创建必要的目录
mkdir -p "$OUTPUT_DIR" "$BACKUP_DIR" "$LOG_DIR"

# 日志文件
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/repair_${TIMESTAMP}.log"

# ========================================
# 颜色输出
# ========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ========================================
# 日志函数
# ========================================
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

# ========================================
# MySQL 执行函数
# ========================================
mysql_exec() {
    local query="$1"
    local output_file="$2"

    if [ -z "$DB_PASSWORD" ]; then
        if [ -z "$output_file" ]; then
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" "$DB_NAME" -e "$query"
        else
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" "$DB_NAME" -e "$query" > "$output_file"
        fi
    else
        if [ -z "$output_file" ]; then
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$query"
        else
            mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "$query" > "$output_file"
        fi
    fi
}

# ========================================
# 主函数
# ========================================

main() {
    log "=========================================="
    log "MySQL 表结构检查和修复工具"
    log "=========================================="
    log "数据库: $DB_NAME"
    log "表前缀: ${TABLE_PREFIX}%"
    log "标准表: $STANDARD_TABLE"
    log "=========================================="

    # 1. 测试数据库连接
    log "步骤 1: 测试数据库连接..."
    if ! mysql_exec "SELECT 1;" > /dev/null 2>&1; then
        log_error "数据库连接失败！请检查配置。"
        exit 1
    fi
    log "数据库连接成功！"

    # 2. 检查标准表是否存在
    log "步骤 2: 检查标准表是否存在..."
    table_exists=$(mysql_exec "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB_NAME' AND TABLE_NAME='$STANDARD_TABLE';" | tail -n 1)
    if [ "$table_exists" -eq 0 ]; then
        log_error "标准表 $STANDARD_TABLE 不存在！"
        exit 1
    fi
    log "标准表 $STANDARD_TABLE 存在。"

    # 3. 查找所有匹配的表
    log "步骤 3: 查找所有匹配的表..."
    tables_list="${OUTPUT_DIR}/tables_list_${TIMESTAMP}.txt"
    mysql_exec "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB_NAME' AND TABLE_NAME LIKE '${TABLE_PREFIX}%' ORDER BY TABLE_NAME;" "$tables_list"

    table_count=$(cat "$tables_list" | wc -l)
    log "找到 $table_count 个表（包括标题行）"

    # 4. 检查缺失字段
    log "步骤 4: 检查缺失字段..."
    missing_fields="${OUTPUT_DIR}/missing_fields_${TIMESTAMP}.txt"

    mysql_exec "
    SELECT
        t.TABLE_NAME as '表名',
        COUNT(ref.COLUMN_NAME) as '缺少字段数量'
    FROM information_schema.TABLES t
    CROSS JOIN information_schema.COLUMNS ref
    LEFT JOIN information_schema.COLUMNS exist
        ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND exist.TABLE_NAME = t.TABLE_NAME
        AND exist.COLUMN_NAME = ref.COLUMN_NAME
    WHERE t.TABLE_SCHEMA = '$DB_NAME'
        AND t.TABLE_NAME LIKE '${TABLE_PREFIX}%'
        AND t.TABLE_NAME != '$STANDARD_TABLE'
        AND ref.TABLE_SCHEMA = '$DB_NAME'
        AND ref.TABLE_NAME = '$STANDARD_TABLE'
        AND exist.COLUMN_NAME IS NULL
    GROUP BY t.TABLE_NAME
    HAVING COUNT(ref.COLUMN_NAME) > 0
    ORDER BY COUNT(ref.COLUMN_NAME) DESC;
    " "$missing_fields"

    missing_count=$(tail -n +2 "$missing_fields" | wc -l)

    if [ "$missing_count" -eq 0 ]; then
        log "所有表结构一致，无需修复！"
        exit 0
    fi

    log_warning "发现 $missing_count 个表有字段缺失："
    cat "$missing_fields" | tee -a "$LOG_FILE"

    # 5. 生成修复语句
    log "步骤 5: 生成修复语句..."
    repair_sql="${OUTPUT_DIR}/repair_${TIMESTAMP}.sql"

    mysql_exec "
    SELECT CONCAT(
        'ALTER TABLE \`', t.TABLE_NAME, '\` ADD COLUMN \`', ref.COLUMN_NAME, '\` ',
        ref.COLUMN_TYPE,
        IF(ref.IS_NULLABLE = 'NO', ' NOT NULL', ' NULL'),
        IFNULL(CONCAT(' DEFAULT ',
            IF(ref.DATA_TYPE IN ('varchar', 'char', 'text', 'date', 'datetime', 'timestamp', 'time'),
                CONCAT(\"'\", ref.COLUMN_DEFAULT, \"'\"),
                ref.COLUMN_DEFAULT)
        ), ''),
        IF(ref.COLUMN_COMMENT != '', CONCAT(\" COMMENT '\", ref.COLUMN_COMMENT, \"'\"), ''),
        ';'
    )
    FROM information_schema.TABLES t
    CROSS JOIN information_schema.COLUMNS ref
    LEFT JOIN information_schema.COLUMNS exist
        ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND exist.TABLE_NAME = t.TABLE_NAME
        AND exist.COLUMN_NAME = ref.COLUMN_NAME
    WHERE t.TABLE_SCHEMA = '$DB_NAME'
        AND t.TABLE_NAME LIKE '${TABLE_PREFIX}%'
        AND t.TABLE_NAME != '$STANDARD_TABLE'
        AND ref.TABLE_SCHEMA = '$DB_NAME'
        AND ref.TABLE_NAME = '$STANDARD_TABLE'
        AND exist.COLUMN_NAME IS NULL
    ORDER BY t.TABLE_NAME, ref.ORDINAL_POSITION;
    " "$repair_sql"

    repair_statement_count=$(tail -n +2 "$repair_sql" | wc -l)
    log "生成了 $repair_statement_count 条修复语句，保存到: $repair_sql"

    # 6. 显示修复语句预览
    log "修复语句预览（前 10 条）："
    head -n 11 "$repair_sql" | tail -n 10 | tee -a "$LOG_FILE"

    # 7. 询问是否执行
    echo ""
    read -p "是否执行修复？(yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_warning "用户取消执行。修复语句已保存到: $repair_sql"
        exit 0
    fi

    # 8. 备份数据库结构
    log "步骤 8: 备份数据库结构..."
    backup_file="${BACKUP_DIR}/schema_backup_${TIMESTAMP}.sql"

    if [ -z "$DB_PASSWORD" ]; then
        mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --no-data "$DB_NAME" > "$backup_file"
    else
        mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --no-data "$DB_NAME" > "$backup_file"
    fi

    log "结构备份完成: $backup_file"

    # 9. 执行修复
    log "步骤 9: 执行修复语句..."

    # 读取修复语句并逐条执行
    tail -n +2 "$repair_sql" | while IFS= read -r sql; do
        if [ -n "$sql" ]; then
            log "执行: $sql"
            if ! mysql_exec "$sql" 2>> "$LOG_FILE"; then
                log_error "执行失败: $sql"
            fi
        fi
    done

    log "修复语句执行完成！"

    # 10. 验证修复结果
    log "步骤 10: 验证修复结果..."
    verify_result="${OUTPUT_DIR}/verify_${TIMESTAMP}.txt"

    mysql_exec "
    SELECT
        t.TABLE_NAME as '表名',
        COUNT(ref.COLUMN_NAME) as '缺少字段数量'
    FROM information_schema.TABLES t
    CROSS JOIN information_schema.COLUMNS ref
    LEFT JOIN information_schema.COLUMNS exist
        ON exist.TABLE_SCHEMA = t.TABLE_SCHEMA
        AND exist.TABLE_NAME = t.TABLE_NAME
        AND exist.COLUMN_NAME = ref.COLUMN_NAME
    WHERE t.TABLE_SCHEMA = '$DB_NAME'
        AND t.TABLE_NAME LIKE '${TABLE_PREFIX}%'
        AND t.TABLE_NAME != '$STANDARD_TABLE'
        AND ref.TABLE_SCHEMA = '$DB_NAME'
        AND ref.TABLE_NAME = '$STANDARD_TABLE'
        AND exist.COLUMN_NAME IS NULL
    GROUP BY t.TABLE_NAME
    HAVING COUNT(ref.COLUMN_NAME) > 0;
    " "$verify_result"

    remaining_count=$(tail -n +2 "$verify_result" | wc -l)

    if [ "$remaining_count" -eq 0 ]; then
        log "✓ 验证通过！所有表结构已一致。"
    else
        log_warning "仍有 $remaining_count 个表存在字段缺失："
        cat "$verify_result" | tee -a "$LOG_FILE"
    fi

    log "=========================================="
    log "修复完成！"
    log "日志文件: $LOG_FILE"
    log "备份文件: $backup_file"
    log "=========================================="
}

# 执行主函数
main "$@"
