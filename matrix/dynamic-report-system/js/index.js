// 主页面逻辑

let currentData = null;
let availableFields = [];

// 页面初始化
document.addEventListener('DOMContentLoaded', function() {
    // 监听报告类型切换
    const reportTypeRadios = document.querySelectorAll('input[name="reportType"]');
    reportTypeRadios.forEach(radio => {
        radio.addEventListener('change', handleReportTypeChange);
    });

    // 监听最值策略切换
    const maxStrategyRadios = document.querySelectorAll('input[name="maxStrategy"]');
    maxStrategyRadios.forEach(radio => {
        radio.addEventListener('change', handleMaxStrategyChange);
    });

    // 监听文件上传
    document.getElementById('fileInput').addEventListener('change', handleFileUpload);

    // 初始化显示
    handleReportTypeChange();
});

// 处理报告类型切换
function handleReportTypeChange() {
    const selectedType = document.querySelector('input[name="reportType"]:checked').value;
    const matrixConfig = document.getElementById('matrixConfig');

    if (selectedType === 'confusion-matrix') {
        matrixConfig.style.display = 'block';
    } else {
        matrixConfig.style.display = 'none';
    }
}

// 处理最值策略切换
function handleMaxStrategyChange() {
    const manualRadio = document.querySelector('input[name="maxStrategy"][value="manual"]');
    const manualInput = document.getElementById('manualMax');

    if (manualRadio.checked) {
        manualInput.disabled = false;
    } else {
        manualInput.disabled = true;
    }
}

// 处理文件上传
function handleFileUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    document.getElementById('fileName').textContent = file.name;

    const reader = new FileReader();
    reader.onload = function(e) {
        try {
            const data = JSON.parse(e.target.result);
            validateData(data);
            currentData = data;
            displayDataPreview(data);
            populateFieldSelectors(data);
            showMessage('数据加载成功!', 'success');
        } catch (error) {
            showMessage('数据格式错误: ' + error.message, 'error');
            currentData = null;
        }
    };
    reader.readAsText(file);
}

// 显示数据预览
function displayDataPreview(data) {
    const preview = document.getElementById('dataPreview');
    const previewData = data.slice(0, 3); // 只显示前3条

    let html = '<div class="data-stats">';
    html += `<div class="stat-card"><div class="value">${data.length}</div><div class="label">总数据条数</div></div>`;
    html += `<div class="stat-card"><div class="value">${getObjectKeys(data[0]).length}</div><div class="label">字段数量</div></div>`;
    html += '</div>';
    html += '<pre>' + JSON.stringify(previewData, null, 2) + '</pre>';
    html += data.length > 3 ? `<p style="text-align:center; color: #909399; margin-top: 10px;">... 还有 ${data.length - 3} 条数据</p>` : '';

    preview.innerHTML = html;
    preview.classList.remove('empty');
}

// 填充字段选择器
function populateFieldSelectors(data) {
    if (!data || data.length === 0) return;

    availableFields = getObjectKeys(data[0]);

    const selectors = ['expectedField', 'actualField', 'labelField'];
    selectors.forEach(selectorId => {
        const selector = document.getElementById(selectorId);
        selector.innerHTML = '<option value="">-- 请选择字段 --</option>';

        availableFields.forEach(field => {
            const option = document.createElement('option');
            option.value = field;
            option.textContent = field;
            selector.appendChild(option);
        });
    });
}

// 加载示例数据
function loadSampleData(dimensions = 10) {
    let data;
    let description;
    let count;

    switch(dimensions) {
        case 10:
            count = 200;
            description = '10维矩阵 (200条)';
            data = generateDynamicData(10, count);
            break;

        case 15:
            count = 300;
            description = '15维矩阵 (300条) - 高质量';
            data = generateHighQualityData(15, count);
            break;

        case 20:
            count = 206;
            description = '20维矩阵 (206条)';
            data = generateDynamicData(20, count);
            break;

        case 30:
            count = 394;
            description = '30维矩阵 (394条)';
            data = generateDynamicData(30, count);
            break;

        default:
            showMessage('不支持的维度', 'error');
            return;
    }

    currentData = data;
    displayDataPreview(data);
    populateFieldSelectors(data);
    document.getElementById('fileName').textContent = `示例数据: ${description}`;
    showMessage(`${description} 数据加载成功!`, 'success');
}

// 动态生成指定维度的数据
function generateDynamicData(dimensions, count) {
    // 根据维度生成对应的等级说明
    const levelNames = generateLevelNames(dimensions);

    const scenarios = ['电商推荐', '内容推荐', '搜索排序', '广告投放', '智能客服'];
    const factors = ['用户活跃度', '点击率', '转化率', '留存率', 'ROI', 'CTR', 'CVR', '满意度', 'NPS', '复购率'];

    const data = [];

    // 为每个等级生成数据,确保每个等级都有样本
    const samplesPerLevel = Math.floor(count / dimensions);
    const extraSamples = count % dimensions;

    let id = 1;
    for (let level = 0; level < dimensions; level++) {
        const numSamples = samplesPerLevel + (level < extraSamples ? 1 : 0);

        for (let j = 0; j < numSamples; j++) {
            // 80% 概率预测正确
            let actual;
            if (Math.random() < 0.80) {
                actual = level;
            } else {
                // 预测错误时,倾向于预测为相邻等级
                const offset = Math.random() < 0.5 ?
                    (Math.random() < 0.5 ? -1 : 1) :
                    (Math.random() < 0.5 ? -2 : 2);
                actual = Math.max(0, Math.min(dimensions - 1, level + offset));
            }

            data.push({
                id: id++,
                expected_level: level,
                actual_level: actual,
                level_name: levelNames[level],
                scenario: scenarios[Math.floor(Math.random() * scenarios.length)],
                factor: factors[Math.floor(Math.random() * factors.length)],
                score: Math.floor(Math.random() * 40) + 60,
                timestamp: `2025-11-25 ${Math.floor(Math.random() * 13) + 8}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}`
            });
        }
    }

    // 打乱数据顺序
    for (let i = data.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [data[i], data[j]] = [data[j], data[i]];
    }

    return data;
}

// 生成高质量数据 (矩阵单元格0值尽可能少)
function generateHighQualityData(dimensions, count) {
    const levelNames = generateLevelNames(dimensions);
    const scenarios = ['电商推荐', '内容推荐', '搜索排序', '广告投放', '智能客服', 'AI助手', '个性化推送'];
    const factors = ['用户活跃度', '点击率', '转化率', '留存率', 'ROI', 'CTR', 'CVR', '满意度', 'NPS', '复购率', '参与度', '响应率'];

    const data = [];
    let id = 1;

    // 计算矩阵单元格总数
    const totalCells = dimensions * dimensions;

    // 策略：首先确保每个单元格至少有1条数据
    // 为每个(expected, actual)组合至少分配1条数据
    const matrixDistribution = [];
    for (let expected = 0; expected < dimensions; expected++) {
        for (let actual = 0; actual < dimensions; actual++) {
            matrixDistribution.push({ expected, actual, count: 1 });
        }
    }

    // 剩余数据量
    let remainingCount = count - totalCells;

    // 将剩余数据按照合理的分布策略分配
    // 对角线(预测正确)分配更多: 60%
    // 相邻对角线分配中等: 30%
    // 其他位置分配较少: 10%

    const diagonalCount = Math.floor(remainingCount * 0.60);
    const adjacentCount = Math.floor(remainingCount * 0.30);
    const otherCount = remainingCount - diagonalCount - adjacentCount;

    // 分配对角线数据
    for (let i = 0; i < dimensions; i++) {
        const cell = matrixDistribution.find(c => c.expected === i && c.actual === i);
        cell.count += Math.floor(diagonalCount / dimensions);
    }

    // 分配相邻对角线数据
    let adjacentCells = [];
    for (let i = 0; i < dimensions; i++) {
        if (i > 0) adjacentCells.push({ expected: i, actual: i - 1 });
        if (i < dimensions - 1) adjacentCells.push({ expected: i, actual: i + 1 });
    }
    const perAdjacentCell = Math.floor(adjacentCount / adjacentCells.length);
    adjacentCells.forEach(pos => {
        const cell = matrixDistribution.find(c => c.expected === pos.expected && c.actual === pos.actual);
        cell.count += perAdjacentCell;
    });

    // 剩余数据随机分配到其他单元格
    let distributed = 0;
    for (let i = 0; i < otherCount; i++) {
        const randomCell = matrixDistribution[Math.floor(Math.random() * matrixDistribution.length)];
        randomCell.count++;
        distributed++;
    }

    // 根据分配方案生成实际数据
    matrixDistribution.forEach(cell => {
        for (let i = 0; i < cell.count; i++) {
            data.push({
                id: id++,
                expected_level: cell.expected,
                actual_level: cell.actual,
                level_name: levelNames[cell.expected],
                scenario: scenarios[Math.floor(Math.random() * scenarios.length)],
                factor: factors[Math.floor(Math.random() * factors.length)],
                score: Math.floor(Math.random() * 30) + 70,
                timestamp: `2025-11-25 ${Math.floor(Math.random() * 13) + 8}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}`
            });
        }
    });

    // 打乱数据顺序
    for (let i = data.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [data[i], data[j]] = [data[j], data[i]];
    }

    return data;
}

// 根据维度生成等级说明
function generateLevelNames(dimensions) {
    const baseNames = [
        '极低', '很低', '低', '较低', '偏低',
        '中下', '中等', '中上', '偏高', '较高',
        '高', '很高', '极高', '优秀', '卓越',
        '完美', 'S-', 'S', 'S+', 'SS-',
        'SS', 'SS+', 'SSS-', 'SSS', 'SSS+',
        '传奇-', '传奇', '传奇+', '神话', '巅峰'
    ];

    // 如果维度少于30,使用前N个
    if (dimensions <= 30) {
        return baseNames.slice(0, dimensions);
    }

    // 如果维度多于30,扩展数组
    const names = [...baseNames];
    for (let i = 30; i < dimensions; i++) {
        names.push(`等级${i}`);
    }
    return names;
}

// 生成报告
function generateReport() {
    // 验证基本信息
    const reportName = document.getElementById('reportName').value.trim();
    const versionName = document.getElementById('versionName').value.trim();

    if (!reportName) {
        showMessage('请输入报告名称', 'warning');
        return;
    }

    if (!versionName) {
        showMessage('请输入版本名称', 'warning');
        return;
    }

    if (!currentData) {
        showMessage('请先加载数据', 'warning');
        return;
    }

    const reportType = document.querySelector('input[name="reportType"]:checked').value;

    if (reportType === 'confusion-matrix') {
        generateMatrixReport(reportName, versionName);
    } else {
        generateScenarioReport(reportName, versionName);
    }
}

// 生成混淆矩阵报告
function generateMatrixReport(reportName, versionName) {
    const expectedField = document.getElementById('expectedField').value;
    const actualField = document.getElementById('actualField').value;
    const labelField = document.getElementById('labelField').value;

    if (!expectedField || !actualField || !labelField) {
        showMessage('请选择所有必填字段', 'warning');
        return;
    }

    if (expectedField === actualField || expectedField === labelField || actualField === labelField) {
        showMessage('字段不能重复选择', 'warning');
        return;
    }

    // 获取策略配置
    const maxStrategy = document.querySelector('input[name="maxStrategy"]:checked').value;
    const manualMax = parseInt(document.getElementById('manualMax').value);
    const nullStrategy = document.querySelector('input[name="nullStrategy"]:checked').value;

    // 准备配置
    const config = {
        reportName,
        versionName,
        reportType: 'confusion-matrix',
        expectedField,
        actualField,
        labelField,
        maxStrategy,
        manualMax,
        nullStrategy,
        generateTime: getCurrentTimeString()
    };

    // 保存配置和数据
    saveToStorage('reportConfig', config);
    saveToStorage('reportData', currentData);

    // 跳转到报告页面
    window.location.href = 'matrix-report.html';
}

// 生成场景/因子报告
function generateScenarioReport(reportName, versionName) {
    const config = {
        reportName,
        versionName,
        reportType: 'scenario-factor',
        generateTime: getCurrentTimeString()
    };

    saveToStorage('reportConfig', config);
    saveToStorage('reportData', currentData);

    window.location.href = 'scenario-report.html';
}
