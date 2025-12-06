package com.example.matrix.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * 标记映射实体
 */
@Data
@TableName("task_evaluate_matrix_mark")
public class MatrixMark implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 自增主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 用例ID
     */
    @TableField("case_id")
    private String caseId;

    /**
     * 指标ID/值ID
     */
    @TableField("indicate_id")
    private String indicateId;

    /**
     * 值
     */
    @TableField("value")
    private String value;

    /**
     * 描述值
     */
    @TableField("desc_value")
    private String descValue;

    /**
     * 创建时间
     */
    @TableField("create_time")
    private Date createTime;

    /**
     * 更新时间
     */
    @TableField("update_time")
    private Date updateTime;
}

