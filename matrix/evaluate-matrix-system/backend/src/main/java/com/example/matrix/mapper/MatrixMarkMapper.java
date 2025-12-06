package com.example.matrix.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.matrix.entity.MatrixMark;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 标记映射Mapper
 */
@Mapper
public interface MatrixMarkMapper extends BaseMapper<MatrixMark> {

    /**
     * 根据caseId查询标记映射列表
     */
    @Select("SELECT * FROM task_evaluate_matrix_mark WHERE case_id = #{caseId}")
    List<MatrixMark> selectByCaseId(@Param("caseId") String caseId);
}

