# [项目名称] - 测试和验证规范 (testing.md)

**本文档定义 Agent 必须遵守的测试和验证规则。**

---

## 1. 测试分层策略

### 1.1 按修改类型分层

| 修改类型 | 测试方法 | 验证标准 |
|---------|---------|---------|
| **大幅修改** | 浏览器自动化测试 | 页面加载、交互、UI 正确 |
| **小修改** | lint + build | 代码规范、构建成功 |
| **API 修改** | curl + lint | 端点响应正确 |

### 1.2 大幅修改定义

**包括以下任一项都属于大幅修改：**
- 新建页面
- 重写组件
- 修改核心交互逻辑
- 添加新的用户流程
- 修改路由配置
- 修改状态管理

### 1.3 小修改定义

**包括以下任一项属于小修改：**
- Bug 修复
- 样式调整（颜色、间距等）
- 添加辅助函数
- 重构代码（不改变行为）
- 添加常量或配置

---

## 2. 浏览器自动化测试

### 2.1 必须使用浏览器测试的情况

```
if (是大幅修改) {
  必须使用 MCP Playwright 工具进行浏览器测试;

  测试步骤:
  1. puppeteer_navigate(url)     // 导航到页面
  2. puppeteer_screenshot(name)   // 截图初始状态
  3. puppeteer_click(selector)    // 点击元素
  4. puppeteer_fill(selector, value)  // 填写表单
  5. puppeteer_screenshot(name)   // 截图操作后
  6. 验证结果正确
}
```

### 2.2 浏览器测试模板

```javascript
// 标准测试流程
await puppeteer_navigate("http://localhost:3000");
await puppeteer_screenshot("01_initial_state");

// 执行操作
await puppeteer_click("#submit-button");
await sleep(1000);  // 等待响应

// 验证结果
await puppeteer_screenshot("02_after_click");

// 检查控制台
const hasErrors = await puppeteer_evaluate("!!window.consoleErrors");
assert(hasErrors === false, "Console has errors");
```

### 2.3 截图要求

**每次浏览器测试必须截图：**
- 初始状态截图
- 操作后截图
- 错误状态截图（如果有）

**截图命名规范：**
```
01_initial_state.png
02_after_click.png
03_error_state.png
```

---

## 3. Lint 和 Build 测试

### 3.1 小修改测试流程

```bash
# 1. 运行 lint
npm run lint

# 必须通过，无错误
# 如果有 warning，确认是否可以接受

# 2. 运行 build
npm run build

# 必须成功，无错误
```

### 3.2 修复流程

```
if (lint 有错误) {
  修复所有 lint 错误;
  再次运行 npm run lint;
}

if (build 失败) {
  修复所有编译错误;
  再次运行 npm run build;
}

if (有 TypeScript 错误) {
  修复类型错误;
  确保没有使用 any;
}
```

---

## 4. 测试清单

### 4.1 大幅修改检查清单

```markdown
## 测试清单 - [任务名称]

### 基础验证
- [ ] 页面可以正常访问
- [ ] 控制台无错误
- [ ] 没有 404 错误
- [ ] 没有网络请求失败

### 功能验证
- [ ] 所有按钮可点击
- [ ] 表单可以提交
- [ ] 数据正确显示
- [ ] 交互响应正确

### 视觉验证
- [ ] 布局正确
- [ ] 样式符合设计
- [ ] 响应式正常
- [ ] 动画流畅

### 截图
- [ ] 01_initial_state.png
- [ ] 02_after_action.png
```

### 4.2 小修改检查清单

```markdown
## 测试清单 - [任务名称]

### 代码质量
- [ ] npm run lint 通过
- [ ] npm run build 成功
- [ ] 没有 TypeScript 错误
- [ ] 没有 console.log 残留

### 功能验证
- [ ] 修改的功能正常工作
- [ ] 没有破坏现有功能
```

---

## 5. 验证规则

### 5.1 功能验证

```
必须验证任务中的每一个步骤:
1. 读取 task.json 中的 steps
2. 对每个 step 进行验证
3. 所有 step 验证通过才能标记 passes: true
```

### 5.2 回归验证

```
每次修改后，必须验证:
- 之前实现的功能没有被破坏
- 至少运行 1-2 个之前任务的验证步骤
```

### 5.3 边界情况验证

```
对于边界情况，必须验证:
- 空数据状态
- 错误输入处理
- 网络错误处理
- 极端数据量
```

---

## 6. 测试报告格式

### 6.1 在 progress.txt 中的报告

```markdown
### Testing:

**测试方法**: [浏览器测试 / lint+build]

**测试步骤**:
1. [步骤1]
2. [步骤2]
3. [步骤3]

**测试结果**:
- ✅ 页面加载正常
- ✅ 按钮可点击
- ✅ 数据正确显示

**截图**:
- 01_initial_state.png
- 02_after_action.png

**Lint/Build**:
- npm run lint: ✅ 通过
- npm run build: ✅ 成功
```

### 6.2 失败测试报告

```markdown
### Testing:

**测试方法**: [测试方法]

**失败的测试**:
- [ ] [未通过的测试项]
- [ ] [未通过的测试项]

**失败原因**:
- [原因描述]

**需要的帮助**:
- [具体需要什么帮助]
```

---

## 7. 阻塞情况的处理

### 7.1 无法测试时

```
如果出现以下情况，必须停止并请求人工:
- 环境变量未配置（API 密钥等）
- 外部服务不可用
- 需要真实用户账号
- 测试环境未搭建

阻塞信息格式:
🚫 任务阻塞 - 无法测试

**原因**: [具体原因]
**需要人工**: [需要什么帮助]
```

### 7.2 测试失败时

```
如果测试失败，必须:
1. 记录失败原因
2. 尝试修复
3. 重新测试
4. 如果无法修复，记录详细问题并请求人工
```

---

## 8. 持续集成要求

### 8.1 提交前检查

```bash
# 必须运行的命令
npm run lint
npm run build
npm test  # 如果有测试

# 全部通过才能提交
```

### 8.2 禁止提交的情况

```
❌ lint 有错误
❌ build 失败
❌ 测试失败
❌ 有 TypeScript 错误
❌ 控制台有错误
❌ 截图显示明显问题
```
