// 场景/因子评估报告页面逻辑

let reportConfig = null;
let reportData = null;

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

    // 渲染数据
    renderStats();
    renderTable();
}

// 渲染统计信息
function renderStats() {
    const totalRecords = reportData.length;

    // 统计不同的场景和因子数量
    const scenarios = new Set();
    const factors = new Set();

    reportData.forEach(row => {
        if (row.scenario) scenarios.add(row.scenario);
        if (row.factor) factors.add(row.factor);
    });

    document.getElementById('totalRecords').textContent = totalRecords;
    document.getElementById('scenarioCount').textContent = scenarios.size;
    document.getElementById('factorCount').textContent = factors.size;
}

// 渲染数据表格
function renderTable() {
    if (reportData.length === 0) {
        document.getElementById('tableHead').innerHTML = '<tr><th>暂无数据</th></tr>';
        document.getElementById('tableBody').innerHTML = '';
        return;
    }

    // 获取所有字段
    const fields = getObjectKeys(reportData[0]);

    // 渲染表头
    const thead = document.getElementById('tableHead');
    let headerHtml = '<tr><th>序号</th>';
    fields.forEach(field => {
        headerHtml += `<th>${field}</th>`;
    });
    headerHtml += '</tr>';
    thead.innerHTML = headerHtml;

    // 渲染表体
    const tbody = document.getElementById('tableBody');
    let bodyHtml = '';

    reportData.forEach((row, index) => {
        bodyHtml += '<tr>';
        bodyHtml += `<td>${index + 1}</td>`;
        fields.forEach(field => {
            const value = row[field];
            bodyHtml += `<td>${value !== null && value !== undefined ? value : '-'}</td>`;
        });
        bodyHtml += '</tr>';
    });

    tbody.innerHTML = bodyHtml;
}
