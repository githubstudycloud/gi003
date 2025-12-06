package com.example.matrix.controller;

import com.example.matrix.service.MatrixReportService;
import com.example.matrix.vo.MatrixQueryRequest;
import com.example.matrix.vo.MatrixReportVO;
import com.example.matrix.vo.Result;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 矩阵报告Controller
 */
@Slf4j
@RestController
@RequestMapping("/matrix")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MatrixReportController {

    private final MatrixReportService reportService;

    /**
     * 获取矩阵报告数据
     * 
     * GET /api/matrix/report?reportId=xxx&taskId=xxx
     */
    @GetMapping("/report")
    public Result<List<MatrixReportVO>> getReport(
            @RequestParam("reportId") String reportId,
            @RequestParam("taskId") String taskId) {
        
        log.info("获取矩阵报告: reportId={}, taskId={}", reportId, taskId);
        
        try {
            List<MatrixReportVO> data = reportService.getMatrixReport(reportId, taskId);
            return Result.success(data);
        } catch (Exception e) {
            log.error("获取矩阵报告失败", e);
            return Result.error("获取报告失败: " + e.getMessage());
        }
    }

    /**
     * POST方式获取矩阵报告数据
     * 
     * POST /api/matrix/report
     * Body: { "reportId": "xxx", "taskId": "xxx" }
     */
    @PostMapping("/report")
    public Result<List<MatrixReportVO>> getReportPost(
            @RequestBody @Validated MatrixQueryRequest request) {
        
        log.info("获取矩阵报告(POST): reportId={}, taskId={}", 
                request.getReportId(), request.getTaskId());
        
        try {
            List<MatrixReportVO> data = reportService.getMatrixReport(
                    request.getReportId(), 
                    request.getTaskId()
            );
            return Result.success(data);
        } catch (Exception e) {
            log.error("获取矩阵报告失败", e);
            return Result.error("获取报告失败: " + e.getMessage());
        }
    }

    /**
     * 健康检查
     */
    @GetMapping("/health")
    public Result<String> health() {
        return Result.success("OK");
    }
}

