package com.example.matrix.service;

import com.example.matrix.entity.MatrixDetail;
import com.example.matrix.entity.MatrixMark;
import com.example.matrix.entity.MatrixParam;
import com.example.matrix.mapper.MatrixDetailMapper;
import com.example.matrix.mapper.MatrixMarkMapper;
import com.example.matrix.mapper.MatrixParamMapper;
import com.example.matrix.vo.MatrixReportVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 矩阵报告服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MatrixReportService {

    private final MatrixParamMapper paramMapper;
    private final MatrixDetailMapper detailMapper;
    private final MatrixMarkMapper markMapper;

    /**
     * 获取矩阵报告数据
     *
     * @param reportId 报告ID
     * @param taskId   任务ID
     * @return 报告数据列表（按case_id分组）
     */
    public List<MatrixReportVO> getMatrixReport(String reportId, String taskId) {
        log.info("获取矩阵报告: reportId={}, taskId={}", reportId, taskId);

        // 1. 查询参数配置列表
        List<MatrixParam> paramList = paramMapper.selectByReportAndTask(reportId, taskId);
        if (paramList == null || paramList.isEmpty()) {
            log.warn("未找到参数配置: reportId={}, taskId={}", reportId, taskId);
            return new ArrayList<>();
        }

        // 2. 为每个case_id构建报告数据
        List<MatrixReportVO> result = new ArrayList<>();
        for (MatrixParam param : paramList) {
            MatrixReportVO vo = buildCaseReport(param);
            result.add(vo);
        }

        return result;
    }

    /**
     * 构建单个case的报告数据
     */
    private MatrixReportVO buildCaseReport(MatrixParam param) {
        MatrixReportVO vo = new MatrixReportVO();

        // 设置配置
        vo.setCaseConfig(param);

        // 查询详情数据
        List<MatrixDetail> detailList = detailMapper.selectByCaseId(
                param.getReportId(),
                param.getTaskId(),
                param.getCaseId()
        );
        vo.setDetailList(detailList);

        // 查询标记映射
        List<MatrixMark> markList = markMapper.selectByCaseId(param.getCaseId());
        List<MatrixReportVO.MarkItemVO> markItems = markList.stream()
                .map(mark -> {
                    MatrixReportVO.MarkItemVO item = new MatrixReportVO.MarkItemVO();
                    item.setId(mark.getIndicateId());
                    item.setValue(mark.getValue());
                    item.setDesc(mark.getDescValue());
                    return item;
                })
                .collect(Collectors.toList());
        vo.setMarkList(markItems);

        // 计算统计信息
        MatrixReportVO.MatrixStatistics statistics = calculateStatistics(detailList);
        vo.setStatistics(statistics);

        return vo;
    }

    /**
     * 计算统计信息
     * 只统计actural_value和predicted_value都是有效数字的记录
     */
    private MatrixReportVO.MatrixStatistics calculateStatistics(List<MatrixDetail> detailList) {
        MatrixReportVO.MatrixStatistics stats = new MatrixReportVO.MatrixStatistics();

        int totalCount = detailList.size();
        int validCount = 0;
        int correctCount = 0;
        int matrixMax = 0;

        for (MatrixDetail detail : detailList) {
            // 判断是否为有效数字
            Integer actualVal = parseIntOrNull(detail.getActuralValue());
            Integer predictedVal = parseIntOrNull(detail.getPredictedValue());

            if (actualVal != null && predictedVal != null) {
                validCount++;

                // 计算正确数
                if (actualVal.equals(predictedVal)) {
                    correctCount++;
                }

                // 计算最大值
                matrixMax = Math.max(matrixMax, Math.max(actualVal, predictedVal));
            }
        }

        int invalidCount = totalCount - validCount;
        int wrongCount = validCount - correctCount;

        stats.setTotalCount(totalCount);
        stats.setValidCount(validCount);
        stats.setInvalidCount(invalidCount);
        stats.setCorrectCount(correctCount);
        stats.setWrongCount(wrongCount);
        stats.setMatrixMax(matrixMax);

        // 计算准确率和召回率（基于有效样本）
        if (validCount > 0) {
            double accuracy = (double) correctCount / validCount * 100;
            stats.setAccuracy(Math.round(accuracy * 100.0) / 100.0);
            stats.setRecall(Math.round(accuracy * 100.0) / 100.0);
        } else {
            stats.setAccuracy(0.0);
            stats.setRecall(0.0);
        }

        return stats;
    }

    /**
     * 将字符串解析为整数，如果不是有效数字则返回null
     */
    private Integer parseIntOrNull(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}

