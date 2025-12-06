package com.example.matrix.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.util.Date;

/**
 * 矩阵详情数据实体
 */
@Data
@TableName("task_evaluate_matrix_detail")
public class MatrixDetail implements Serializable {

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
     * 语料ID/数据ID
     */
    @TableField("corpus_id")
    private String corpusId;

    /**
     * 实际值
     */
    @TableField("actural_value")
    private String acturalValue;

    /**
     * 预测值
     */
    @TableField("predicted_value")
    private String predictedValue;

    /**
     * 描述值/显示说明
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

