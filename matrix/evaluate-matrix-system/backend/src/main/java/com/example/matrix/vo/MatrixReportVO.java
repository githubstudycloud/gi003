package com.example.matrix.vo;

import com.example.matrix.entity.MatrixDetail;
import com.example.matrix.entity.MatrixParam;
import lombok.Data;

import java.io.Serializable;
import java.util.List;

/**
 * 矩阵报告返回数据
 */
@Data
public class MatrixReportVO implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 用例配置
     */
    private MatrixParam caseConfig;

    /**
     * 详情数据列表
     */
    private List<MatrixDetail> detailList;

    /**
     * 标记映射列表
     */
    private List<MarkItemVO> markList;

    /**
     * 统计信息
     */
    private MatrixStatistics statistics;

    /**
     * 标记项VO
     */
    @Data
    public static class MarkItemVO implements Serializable {
        private static final long serialVersionUID = 1L;
        
        /**
         * 值ID
         */
        private String id;
        
        /**
         * 值
         */
        private String value;
        
        /**
         * 描述
         */
        private String desc;
    }

    /**
     * 统计信息
     */
    @Data
    public static class MatrixStatistics implements Serializable {
        private static final long serialVersionUID = 1L;

        /**
         * 总样本数
         */
        private Integer totalCount;

        /**
         * 有效样本数（actural_value和predicted_value都是数字的）
         */
        private Integer validCount;

        /**
         * 无效样本数
         */
        private Integer invalidCount;

        /**
         * 预测正确数
         */
        private Integer correctCount;

        /**
         * 预测错误数
         */
        private Integer wrongCount;

        /**
         * 准确率
         */
        private Double accuracy;

        /**
         * 召回率
         */
        private Double recall;

        /**
         * 矩阵最大值
         */
        private Integer matrixMax;
    }
}

