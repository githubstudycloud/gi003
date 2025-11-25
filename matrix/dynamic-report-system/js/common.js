// 通用工具函数

// 全局数据存储
window.reportData = {
    rawData: null,
    config: null,
    processedData: null
};

// 获取当前时间字符串
function getCurrentTimeString() {
    const now = new Date();
    return now.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false
    }).replace(/\//g, '-');
}

// 保存到本地存储
function saveToStorage(key, data) {
    try {
        localStorage.setItem(key, JSON.stringify(data));
    } catch (e) {
        console.error('保存数据失败:', e);
    }
}

// 从本地存储读取
function loadFromStorage(key) {
    try {
        const data = localStorage.getItem(key);
        return data ? JSON.parse(data) : null;
    } catch (e) {
        console.error('读取数据失败:', e);
        return null;
    }
}

// 显示提示消息
function showMessage(message, type = 'info') {
    const colors = {
        success: '#67C23A',
        error: '#F56C6C',
        warning: '#E6A23C',
        info: '#409EFF'
    };

    const messageDiv = document.createElement('div');
    messageDiv.style.cssText = `
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        padding: 12px 20px;
        background: ${colors[type] || colors.info};
        color: white;
        border-radius: 4px;
        box-shadow: 0 2px 12px rgba(0,0,0,0.15);
        z-index: 10000;
        animation: slideDown 0.3s ease;
    `;
    messageDiv.textContent = message;

    document.body.appendChild(messageDiv);

    setTimeout(() => {
        messageDiv.style.animation = 'slideUp 0.3s ease';
        setTimeout(() => {
            document.body.removeChild(messageDiv);
        }, 300);
    }, 3000);
}

// 添加CSS动画
if (!document.getElementById('message-animations')) {
    const style = document.createElement('style');
    style.id = 'message-animations';
    style.textContent = `
        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateX(-50%) translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(-50%) translateY(0);
            }
        }
        @keyframes slideUp {
            from {
                opacity: 1;
                transform: translateX(-50%) translateY(0);
            }
            to {
                opacity: 0;
                transform: translateX(-50%) translateY(-20px);
            }
        }
    `;
    document.head.appendChild(style);
}

// 验证数据格式
function validateData(data) {
    if (!Array.isArray(data)) {
        throw new Error('数据必须是数组格式');
    }
    if (data.length === 0) {
        throw new Error('数据不能为空');
    }
    if (typeof data[0] !== 'object') {
        throw new Error('数组元素必须是对象');
    }
    return true;
}

// 获取对象的所有键
function getObjectKeys(obj) {
    return Object.keys(obj).filter(key => key !== '__proto__');
}

// 深拷贝对象
function deepClone(obj) {
    return JSON.parse(JSON.stringify(obj));
}

// 返回主页
function goBack() {
    window.location.href = 'index.html';
}

// 导出报告(通用)
function exportReport() {
    showMessage('导出功能开发中...', 'info');
}
