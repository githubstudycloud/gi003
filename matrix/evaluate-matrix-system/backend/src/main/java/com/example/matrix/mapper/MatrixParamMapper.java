package com.example.matrix.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.matrix.entity.MatrixParam;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 矩阵参数配置Mapper
 */
@Mapper
public interface MatrixParamMapper extends BaseMapper<MatrixParam> {

    /**
     * 根据reportId和taskId查询参数配置列表
     */
    @Select("SELECT * FROM task_evaluate_matrix_param WHERE report_id = #{reportId} AND task_id = #{taskId}")
    List<MatrixParam> selectByReportAndTask(@Param("reportId") String reportId, @Param("taskId") String taskId);
}

