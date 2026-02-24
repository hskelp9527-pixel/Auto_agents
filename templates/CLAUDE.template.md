# [项目名称] - Agent 工作流程

## 项目上下文

[项目简短描述]

> 详细需求请参考 `PRD.md` 和 `architecture.md`
> 编码规则请参考 `rules.md`
> 测试规则请参考 `testing.md`

---

## ⚠️ 强制工作流程 (MANDATORY)

**Claude Code 执行时必须严格遵守以下流程：**

---

## STEP 1: 初始化环境

```bash
./init.sh
```

**这会:**
- 安装所有依赖
- 启动开发服务器
- 显示服务器地址

**⚠️ 不要跳过这一步！** 确保服务器运行后再继续。

---

## STEP 2: 选择下一个任务

读取 `task.json` 并选择**一个** `passes: false` 的任务。

**选择标准（按优先级）:**
1. 选择 `passes: false` 的任务
2. 检查 `dependencies` — 确保依赖任务已完成
3. 选择 `priority` 最高的未完成任务

```bash
# 查看所有未完成任务
cat task.json | grep -B 10 '"passes": false'

# 统计剩余任务数
grep -c '"passes": false' task.json
```

---

## STEP 3: 实现任务

- 仔细阅读任务的 `title`、`description` 和 `steps`
- 按照 `steps` 中的步骤逐一实现
- 遵循 `rules.md` 中的编码规范
- 参考项目中已有的类似代码

**重要:**
- 一次只做一个任务
- 不要跳过步骤
- 遵循现有代码风格

---

## STEP 4: 测试和验证 (Test Thoroughly)

实现后，验证任务中的**所有步骤**：

### 测试分层

| 修改类型 | 测试要求 |
|---------|---------|
| **大幅修改** | 新建页面、重写组件、修改核心交互 |
| → 浏览器测试 | 使用 MCP Playwright，验证加载、交互、UI |
| **小修改** | Bug修复、样式调整、添加辅助函数 |
| → lint + build | `npm run lint` 和 `npm run build` |

### 测试清单

- [ ] 代码符合 `rules.md` 的规范
- [ ] `npm run lint` 无错误
- [ ] `npm run build` 成功
- [ ] 浏览器测试功能正常（UI 修改）
- [ ] 控制台无错误
- [ ] 符合 `testing.md` 的要求

---

## STEP 5: 更新进度和任务文件

### 5.1 更新 progress.txt

```markdown
## [YYYY-MM-DD] - Task: [任务ID - 任务标题]

### What was done:
- [具体修改1]
- [具体修改2]
- [创建/修改的文件]

### Testing:
- [如何测试的]
- [测试结果]
- [截图位置]

### Notes:
- [重要的注意事项]
```

### 5.2 更新 task.json

**重要: 只能修改 `passes` 字段！**

```json
// 修改前
"passes": false

// 修改后
"passes": true
```

**⚠️ 禁止事项:**
- ❌ 不要删除任务
- ❌ 不要修改任务描述
- ❌ 不要修改步骤
- ❌ 不要重新排序任务

---

## STEP 6: Git 提交代码

```bash
# 一次性提交所有更改
git add .
git commit -m "[任务ID] [任务标题] - completed"
```

**Commit 规范:**
```
[ID] [标题] - completed

示例:
[5] 用户登录页面 - completed
[12] 数据库 Schema - completed
```

---

## 🚫 阻塞处理 (Blocking Issues)

**如果任务无法完成或需要人工介入，必须遵循以下规则:**

### 需要停止并请求人工帮助的情况:

1. **缺少环境配置**
   - `.env` 需要真实的 API 密钥
   - 数据库需要创建和配置
   - 外部服务需要开通账号

2. **外部依赖不可用**
   - 第三方 API 服务宕机
   - 需要人工授权的 OAuth 流程
   - 需要付费升级的服务

3. **测试无法进行**
   - 功能需要真实用户账号
   - 依赖外部系统尚未部署
   - 需要特定硬件环境

4. **需求不明确**
   - `PRD.md` 或 `architecture.md` 描述不清楚
   - `task.json` 的步骤有歧义
   - 技术方案存在冲突

### 阻塞时的正确操作

#### ❌ 禁止 (DO NOT)
- ❌ 提交 git commit
- ❌ 将 task.json 的 `passes` 设为 `true`
- ❌ 假装任务已完成

#### ✅ 必须 (DO)
- ✅ 在 `progress.txt` 中记录当前进度
- ✅ 清晰说明阻塞原因
- ✅ 明确列出需要人工做什么
- ✅ 停止任务，输出 🚫 阻塞信息

### 阻塞信息格式

```markdown
🚫 任务阻塞 - 需要人工介入

**当前任务**: [任务ID - 任务标题]

**已完成的工作**:
- [已完成的代码/配置]

**阻塞原因**:
- [具体说明为什么无法继续]

**需要人工帮助**:
1. [具体的步骤 1]
2. [具体的步骤 2]
3. [需要配置的内容]

**解除阻塞后**:
- 运行 [命令] 继续任务
```

---

## 项目结构

```
project-root/
├── CLAUDE.md          # 本文件 - Agent 工作流程
├── PRD.md             # 产品需求文档
├── architecture.md    # 架构设计文档
├── rules.md           # 编码规范
├── testing.md         # 测试规则
├── task.json          # 任务定义（单一真理来源）
├── progress.txt       # 进度日志
├── init.sh            # 初始化脚本
├── .env.example       # 环境变量模板
└── [项目代码目录]/
```

---

## 命令速查

```bash
# 初始化环境
./init.sh

# 运行开发服务器
npm run dev

# 检查代码规范
npm run lint

# 构建项目
npm run build

# 查看剩余任务
grep -c '"passes": false' task.json

# 查看未完成任务
cat task.json | grep -B 10 '"passes": false'

# 查看进度
cat progress.txt

# 查看 Git 历史
git log --oneline -10
```

---

## 核心规则

1. **每会话一个任务** — 专注于完成一个任务
2. **测试后再标记完成** — 所有步骤必须通过
3. **UI 修改必须浏览器测试** — 新建或大幅修改页面必须在浏览器测试
4. **遵守编码规范** — 严格按照 `rules.md` 执行
5. **遵守测试规则** — 严格按照 `testing.md` 验证
6. **在 progress.txt 中记录** — 帮助未来的 Agent 理解工作
7. **一个任务一个 commit** — 所有更改（代码、progress.txt、task.json）必须在同一个 commit 中提交
8. **永远不要移除任务** — 只能将 `passes: false` 改为 `true`
9. **阻塞时停止** — 需要人工介入时，不要提交，输出阻塞信息并停止
