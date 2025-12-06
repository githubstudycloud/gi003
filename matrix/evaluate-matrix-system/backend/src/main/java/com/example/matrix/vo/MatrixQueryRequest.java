package com.example.matrix.vo;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.io.Serializable;

/**
 * 矩阵查询请求
 */
@Data
public class MatrixQueryRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 报告ID
     */
    @NotBlank(message = "报告ID不能为空")
    private String reportId;

    /**
     * 任务ID
     */
    @NotBlank(message = "任务ID不能为空")
    private String taskId;
}

