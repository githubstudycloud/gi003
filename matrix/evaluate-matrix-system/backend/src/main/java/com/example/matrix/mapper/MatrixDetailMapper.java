package com.example.matrix.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.matrix.entity.MatrixDetail;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 矩阵详情数据Mapper
 */
@Mapper
public interface MatrixDetailMapper extends BaseMapper<MatrixDetail> {

    /**
     * 根据reportId、taskId和caseId查询详情列表
     */
    @Select("SELECT * FROM task_evaluate_matrix_detail WHERE report_id = #{reportId} AND task_id = #{taskId} AND case_id = #{caseId}")
    List<MatrixDetail> selectByCaseId(@Param("reportId") String reportId, 
                                       @Param("taskId") String taskId, 
                                       @Param("caseId") String caseId);

    /**
     * 根据reportId和taskId查询所有详情
     */
    @Select("SELECT * FROM task_evaluate_matrix_detail WHERE report_id = #{reportId} AND task_id = #{taskId}")
    List<MatrixDetail> selectByReportAndTask(@Param("reportId") String reportId, @Param("taskId") String taskId);
}

