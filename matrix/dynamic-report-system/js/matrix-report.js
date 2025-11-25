// 混淆矩阵报告页面逻辑

let reportConfig = null;
let reportData = null;
let matrixData = null;
let matrixSize = 0;

// 页面初始化
document.addEventListener('DOMContentLoaded', function() {
    loadReportData();
    if (reportConfig && reportData) {
        initReport();
    } else {
        showMessage('未找到报告数据,即将返回主页', 'error');
        setTimeout(() => {
            goBack();
        }, 2000);
    }
});

// 加载报告数据
function loadReportData() {
    reportConfig = loadFromStorage('reportConfig');
    reportData = loadFromStorage('reportData');
}

// 初始化报告
function initReport() {
    // 更新报告信息
    document.getElementById('reportTitle').textContent = reportConfig.reportName;
    document.getElementById('versionName').textContent = '版本: ' + reportConfig.versionName;
    document.getElementById('generateTime').textContent = '生成时间: ' + reportConfig.generateTime;

    // 处理数据
    try {
        const processedData = processData();
        buildMatrix(processedData);
        renderMatrix();
        renderMetrics();
    } catch (error) {
        showMessage('数据处理失败: ' + error.message, 'error');
        console.error(error);
    }
}

// 处理数据
function processData() {
    const { expectedField, actualField, labelField, nullStrategy } = reportConfig;
    const processed = [];

    for (let i = 0; i < reportData.length; i++) {
        const row = reportData[i];
        let expected = row[expectedField];
        let actual = row[actualField];
        const label = row[labelField];

        // 处理空值和异常
        if (expected === null || expected === undefined || expected === '' ||
            actual === null || actual === undefined || actual === '') {

            if (nullStrategy === 'error') {
                throw new Error(`第 ${i + 1} 行数据包含空值: expected=${expected}, actual=${actual}`);
            } else if (nullStrategy === 'discard') {
                continue; // 跳过这条数据
            } else {
                // 记为0
                expected = expected === null || expected === undefined || expected === '' ? 0 : expected;
                actual = actual === null || actual === undefined || actual === '' ? 0 : actual;
            }
        }

        // 转换为数字
        expected = Number(expected);
        actual = Number(actual);

        if (isNaN(expected) || isNaN(actual)) {
            if (nullStrategy === 'error') {
                throw new Error(`第 ${i + 1} 行数据无法转换为数字: expected=${row[expectedField]}, actual=${row[actualField]}`);
            } else if (nullStrategy === 'discard') {
                continue;
            } else {
                expected = isNaN(expected) ? 0 : expected;
                actual = isNaN(actual) ? 0 : actual;
            }
        }

        processed.push({
            expected: Math.floor(expected),
            actual: Math.floor(actual),
            label: label || `值${actual}`,
            original: row
        });
    }

    return processed;
}

// 构建矩阵
function buildMatrix(processedData) {
    // 确定矩阵大小
    if (reportConfig.maxStrategy === 'manual') {
        matrixSize = reportConfig.manualMax;
    } else {
        let maxVal = 0;
        processedData.forEach(item => {
            maxVal = Math.max(maxVal, item.expected, item.actual);
        });
        matrixSize = maxVal + 1; // 包含0,所以+1
    }

    // 初始化矩阵
    const matrix = Array(matrixSize).fill(0).map(() => Array(matrixSize).fill(0));
    const cellData = Array(matrixSize).fill(null).map(() => Array(matrixSize).fill(null).map(() => []));

    // 创建标签映射 (actual value -> label)
    const labelMap = {};

    // 填充矩阵
    let totalCount = 0;
    let correctCount = 0;

    processedData.forEach(item => {
        const { expected, actual, label, original } = item;

        if (expected >= 0 && expected < matrixSize && actual >= 0 && actual < matrixSize) {
            matrix[actual][expected]++;
            cellData[actual][expected].push(original);
            totalCount++;

            if (expected === actual) {
                correctCount++;
            }

            // 记录标签
            if (!labelMap[actual]) {
                labelMap[actual] = label;
            }
        }
    });

    // 计算召回率和精准率
    const recall = Array(matrixSize).fill(0);
    const precision = Array(matrixSize).fill(0);
    const rowSum = Array(matrixSize).fill(0);
    const colSum = Array(matrixSize).fill(0);

    for (let i = 0; i < matrixSize; i++) {
        for (let j = 0; j < matrixSize; j++) {
            rowSum[i] += matrix[i][j];
            colSum[j] += matrix[i][j];
        }
    }

    for (let i = 0; i < matrixSize; i++) {
        recall[i] = rowSum[i] > 0 ? (matrix[i][i] / rowSum[i] * 100) : 0;
        precision[i] = colSum[i] > 0 ? (matrix[i][i] / colSum[i] * 100) : 0;
    }

    matrixData = {
        matrix,
        cellData,
        labelMap,
        recall,
        precision,
        rowSum,
        colSum,
        totalCount,
        correctCount,
        accuracy: totalCount > 0 ? (correctCount / totalCount * 100) : 0
    };

    // 更新统计卡片
    document.getElementById('totalCount').textContent = totalCount;
    document.getElementById('correctCount').textContent = correctCount;
    document.getElementById('wrongCount').textContent = totalCount - correctCount;
    document.getElementById('accuracy').textContent = matrixData.accuracy.toFixed(2) + '%';
}

// 渲染矩阵
function renderMatrix() {
    const table = document.getElementById('matrixTable');
    let html = '';

    // 表头
    html += '<thead><tr>';
    html += '<th class="label-header">显示说明</th>';
    html += '<th class="value-header">实际\\预测</th>';
    for (let i = 0; i < matrixSize; i++) {
        html += `<th>${i}</th>`;
    }
    html += '<th>合计</th>';
    html += '<th>召回率</th>';
    html += '</tr></thead>';

    // 数据行
    html += '<tbody>';
    for (let i = 0; i < matrixSize; i++) {
        html += '<tr>';

        // 左侧第一列 - 显示说明
        const label = matrixData.labelMap[i] || `值${i}`;
        html += `<td class="label-cell">${label}</td>`;

        // 左侧第二列 - 实际值
        html += `<td class="value-cell">${i}</td>`;

        // 矩阵数据
        for (let j = 0; j < matrixSize; j++) {
            const value = matrixData.matrix[i][j];
            let cellClass = 'cell-clickable ';

            if (value === 0) {
                cellClass += 'cell-zero';
            } else if (i === j) {
                cellClass += 'cell-correct';
            } else {
                cellClass += 'cell-error';
            }

            html += `<td class="${cellClass}" onclick="showCellDetail(${i}, ${j})">${value}</td>`;
        }

        // 行合计
        html += `<td class="sum-column">${matrixData.rowSum[i]}</td>`;

        // 召回率
        const recallClass = getMetricClass(matrixData.recall[i]);
        html += `<td class="recall-column ${recallClass}">${matrixData.recall[i].toFixed(2)}%</td>`;

        html += '</tr>';
    }

    // 合计行
    html += '<tr class="sum-row">';
    html += '<td colspan="2">合计</td>';
    for (let j = 0; j < matrixSize; j++) {
        html += `<td>${matrixData.colSum[j]}</td>`;
    }
    html += `<td>${matrixData.totalCount}</td>`;
    html += '<td>-</td>';
    html += '</tr>';

    // 精准率行
    html += '<tr class="precision-row">';
    html += '<td colspan="2">精准率</td>';
    for (let j = 0; j < matrixSize; j++) {
        const precisionClass = getMetricClass(matrixData.precision[j]);
        html += `<td class="${precisionClass}">${matrixData.precision[j].toFixed(2)}%</td>`;
    }
    html += `<td colspan="2">准确率: ${matrixData.accuracy.toFixed(2)}%</td>`;
    html += '</tr>';

    html += '</tbody>';
    table.innerHTML = html;
}

// 获取指标颜色类
function getMetricClass(value) {
    if (value >= 90) return 'recall-high';
    if (value >= 70) return 'recall-medium';
    return 'recall-low';
}

// 渲染详细指标
function renderMetrics() {
    const grid = document.getElementById('metricsGrid');
    let html = '';

    // 找出召回率和精准率最高/最低的
    let maxRecall = { index: 0, value: matrixData.recall[0] };
    let minRecall = { index: 0, value: matrixData.recall[0] };
    let maxPrecision = { index: 0, value: matrixData.precision[0] };
    let minPrecision = { index: 0, value: matrixData.precision[0] };

    for (let i = 1; i < matrixSize; i++) {
        if (matrixData.recall[i] > maxRecall.value) {
            maxRecall = { index: i, value: matrixData.recall[i] };
        }
        if (matrixData.recall[i] < minRecall.value && matrixData.rowSum[i] > 0) {
            minRecall = { index: i, value: matrixData.recall[i] };
        }
        if (matrixData.precision[i] > maxPrecision.value) {
            maxPrecision = { index: i, value: matrixData.precision[i] };
        }
        if (matrixData.precision[i] < minPrecision.value && matrixData.colSum[i] > 0) {
            minPrecision = { index: i, value: matrixData.precision[i] };
        }
    }

    const metrics = [
        { name: `最高召回率 (值${maxRecall.index})`, value: maxRecall.value.toFixed(2) + '%' },
        { name: `最低召回率 (值${minRecall.index})`, value: minRecall.value.toFixed(2) + '%' },
        { name: `最高精准率 (值${maxPrecision.index})`, value: maxPrecision.value.toFixed(2) + '%' },
        { name: `最低精准率 (值${minPrecision.index})`, value: minPrecision.value.toFixed(2) + '%' }
    ];

    metrics.forEach(metric => {
        html += `
            <div class="metric-card">
                <div class="metric-name">${metric.name}</div>
                <div class="metric-value">${metric.value}</div>
            </div>
        `;
    });

    grid.innerHTML = html;
}

// 显示单元格详情
function showCellDetail(actual, expected) {
    const count = matrixData.matrix[actual][expected];
    if (count === 0) return;

    const data = matrixData.cellData[actual][expected];

    document.getElementById('modalActual').textContent = actual;
    document.getElementById('modalExpected').textContent = expected;
    document.getElementById('modalCount').textContent = count;

    // 渲染详情表格
    const table = document.getElementById('detailTable');
    if (data.length === 0) {
        table.innerHTML = '<tr><td colspan="100%">暂无数据</td></tr>';
    } else {
        const fields = getObjectKeys(data[0]);

        let html = '<thead><tr>';
        html += '<th>序号</th>';
        fields.forEach(field => {
            html += `<th>${field}</th>`;
        });
        html += '</tr></thead><tbody>';

        data.slice(0, 100).forEach((row, index) => {
            html += '<tr>';
            html += `<td>${index + 1}</td>`;
            fields.forEach(field => {
                html += `<td>${row[field] ?? '-'}</td>`;
            });
            html += '</tr>';
        });

        if (data.length > 100) {
            html += `<tr><td colspan="${fields.length + 1}" style="text-align:center;color:#999;">... 还有 ${data.length - 100} 条数据</td></tr>`;
        }

        html += '</tbody>';
        table.innerHTML = html;
    }

    document.getElementById('detailModal').style.display = 'block';
}

// 关闭模态框
function closeModal() {
    document.getElementById('detailModal').style.display = 'none';
}

// 点击模态框外部关闭
window.onclick = function(event) {
    const modal = document.getElementById('detailModal');
    if (event.target === modal) {
        closeModal();
    }
};
