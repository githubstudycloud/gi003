#!/usr/bin/env node

/**
 * Claude Code Feishu Message Sender
 * 通过飞书 MCP 发送任务完成通知
 *
 * 环境变量配置:
 * - FEISHU_CHAT_ID: 飞书群聊ID
 * - FEISHU_USER_OPEN_ID: 飞书用户OpenID（与CHAT_ID二选一）
 * - FEISHU_USE_CARD: 是否使用卡片消息（true/false）
 */

const { spawn } = require('child_process');
const path = require('path');

// 解析命令行参数
function parseArgs() {
  const args = process.argv.slice(2);
  const params = {
    session_id: 'unknown',
    summary: '无任务摘要',
    timestamp: new Date().toISOString(),
    cwd: process.cwd(),
    event: 'Stop'
  };

  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace('--', '');
    const value = args[i + 1];
    if (key && value) {
      params[key] = value;
    }
  }

  return params;
}

// 构建文本消息内容
function buildTextMessage(params) {
  return {
    text: `📋 Claude Code 任务完成\n\n` +
          `会话ID: ${params.session_id}\n` +
          `完成时间: ${params.timestamp}\n` +
          `Hook事件: ${params.event}\n` +
          `工作目录: ${params.cwd}\n\n` +
          `━━━━━━━━━━━━━━━━\n\n` +
          `任务摘要:\n${params.summary.substring(0, 800)}`
  };
}

// 构建卡片消息内容
function buildCardMessage(params) {
  // 限制摘要长度
  const truncatedSummary = params.summary.length > 500
    ? params.summary.substring(0, 500) + '...'
    : params.summary;

  return {
    elements: [
      {
        tag: "div",
        text: {
          content: "**📋 Claude Code 任务完成报告**",
          tag: "lark_md"
        }
      },
      {
        tag: "hr"
      },
      {
        tag: "div",
        fields: [
          {
            is_short: true,
            text: {
              content: `**会话ID:**\n${params.session_id.substring(0, 20)}...`,
              tag: "lark_md"
            }
          },
          {
            is_short: true,
            text: {
              content: `**完成时间:**\n${params.timestamp}`,
              tag: "lark_md"
            }
          }
        ]
      },
      {
        tag: "div",
        fields: [
          {
            is_short: true,
            text: {
              content: `**Hook事件:**\n${params.event}`,
              tag: "lark_md"
            }
          },
          {
            is_short: true,
            text: {
              content: `**工作目录:**\n${path.basename(params.cwd)}`,
              tag: "lark_md"
            }
          }
        ]
      },
      {
        tag: "hr"
      },
      {
        tag: "div",
        text: {
          content: `**任务摘要:**\n\n${truncatedSummary}`,
          tag: "lark_md"
        }
      },
      {
        tag: "hr"
      },
      {
        tag: "note",
        elements: [
          {
            tag: "plain_text",
            content: "🤖 此消息由 Claude Code Hook 自动发送"
          }
        ]
      }
    ],
    header: {
      template: "blue",
      title: {
        content: "🤖 Claude Code 任务完成",
        tag: "plain_text"
      }
    }
  };
}

// 调用飞书 MCP 发送消息
async function sendMessage(params) {
  // 从环境变量读取配置
  const receiveId = process.env.FEISHU_CHAT_ID || process.env.FEISHU_USER_OPEN_ID;
  const receiveIdType = process.env.FEISHU_CHAT_ID ? 'chat_id' : 'open_id';
  const useCard = process.env.FEISHU_USE_CARD === 'true';

  if (!receiveId) {
    console.error('❌ 错误: 未设置环境变量 FEISHU_CHAT_ID 或 FEISHU_USER_OPEN_ID');
    console.error('请在环境变量或 .env 文件中设置接收者ID');
    process.exit(1);
  }

  // 构建消息内容
  const msgType = useCard ? 'interactive' : 'text';
  const content = useCard ? buildCardMessage(params) : buildTextMessage(params);

  // 构建 MCP 请求
  const mcpRequest = {
    jsonrpc: '2.0',
    method: 'tools/call',
    params: {
      name: 'mcp__mcp-feishu__im_v1_message_create',
      arguments: {
        params: {
          receive_id_type: receiveIdType
        },
        data: {
          receive_id: receiveId,
          msg_type: msgType,
          content: JSON.stringify(content)
        }
      }
    },
    id: Date.now()
  };

  console.log('📤 正在发送飞书消息...');
  console.log(`   接收者: ${receiveId}`);
  console.log(`   消息类型: ${msgType}`);

  return new Promise((resolve, reject) => {
    // 启动 MCP Server 进程
    // 注意: 这里假设飞书 MCP 可以通过 npx 启动
    // 实际使用时可能需要根据 MCP Server 的实际配置调整
    const mcpServer = spawn('npx', ['-y', '@modelcontextprotocol/server-feishu'], {
      stdio: ['pipe', 'pipe', 'pipe']
    });

    let stdout = '';
    let stderr = '';

    mcpServer.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    mcpServer.stderr.on('data', (data) => {
      stderr += data.toString();
      // 实时输出错误信息
      if (stderr.includes('error') || stderr.includes('Error')) {
        console.error('⚠️  MCP Server 错误:', data.toString());
      }
    });

    mcpServer.on('close', (code) => {
      if (code === 0) {
        console.log('✅ 飞书消息发送成功！');
        console.log('   响应:', stdout.substring(0, 200));
        resolve(stdout);
      } else {
        console.error(`❌ MCP Server 退出，代码: ${code}`);
        console.error('   错误信息:', stderr);
        reject(new Error(`MCP Server exited with code ${code}`));
      }
    });

    mcpServer.on('error', (err) => {
      console.error('❌ 启动 MCP Server 失败:', err.message);
      console.error('提示: 请确保已安装飞书 MCP Server');
      reject(err);
    });

    // 发送请求到 MCP Server
    mcpServer.stdin.write(JSON.stringify(mcpRequest) + '\n');
    mcpServer.stdin.end();

    // 设置超时
    setTimeout(() => {
      mcpServer.kill();
      reject(new Error('请求超时 (30秒)'));
    }, 30000);
  });
}

// 主函数
async function main() {
  try {
    const params = parseArgs();

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🚀 Claude Code Feishu Reporter');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    await sendMessage(params);

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ 发送失败:', error.message);
    process.exit(1);
  }
}

main();
