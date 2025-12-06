package com.example.matrix.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * 矩阵参数配置实体
 */
@Data
@TableName("task_evaluate_matrix_param")
public class MatrixParam implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 报告ID
     */
    @TableField("report_id")
    private String reportId;

    /**
     * 任务ID
     */
    @TableField("task_id")
    private String taskId;

    /**
     * 用例ID
     */
    @TableField("case_id")
    private String caseId;

    /**
     * 实际值字段名
     */
    @TableField("actural_value_field")
    private String acturalValueField;

    /**
     * 实际值ID字段名
     */
    @TableField("actural_id_field")
    private String acturalIdField;

    /**
     * 预测值字段名
     */
    @TableField("predicted_value_field")
    private String predictedValueField;

    /**
     * 预测值ID字段名
     */
    @TableField("predicted_id_field")
    private String predictedIdField;

    /**
     * 描述值字段名
     */
    @TableField("desc_value_field")
    private String descValueField;

    /**
     * 矩阵策略
     */
    @TableField("matrix_strategy")
    private String matrixStrategy;

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

