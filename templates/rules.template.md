# [项目名称] - 编码规范 (rules.md)

**本文档是 Agent 必须严格遵守的编码规范。**

---

## 1. 通用规范

### 1.1 代码风格

```bash
# 提交前必须运行
npm run lint

# 必须通过，无错误
npm run build
```

### 1.2 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 文件名 | kebab-case | `user-list.tsx`, `api-client.ts` |
| 组件名 | PascalCase | `UserList`, `ApiClient` |
| 函数名 | camelCase | `getUserList`, `fetchData` |
| 常量名 | UPPER_SNAKE_CASE | `API_BASE_URL`, `MAX_RETRY` |
| 私有变量 | camelCase + `_` 前缀 | `_internalState` |
| 接口名 | PascalCase + `I` 前缀 | `IUserService` |
| 类型别名 | PascalCase | `UserID`, `ResponseData` |

### 1.3 注释规范

```typescript
// 函数必须有 JSDoc 注释
/**
 * 获取用户列表
 * @param page 页码，从 1 开始
 * @param limit 每页数量
 * @returns 用户列表
 */
async function getUsers(page: number, limit: number) {
  // ...
}

// 复杂逻辑必须有解释
// TODO: 这里需要优化性能
// FIXME: 这是一个临时解决方案
```

---

## 2. 前端规范 (React/Vue)

### 2.1 组件结构

```typescript
// 组件文件结构
import { useState, useEffect } from 'react';

// 1. 类型定义
interface Props {
  title: string;
  onConfirm: () => void;
}

// 2. 常量定义
const DEFAULT_TITLE = '默认标题';

// 3. 组件定义
export function MyComponent({ title, onConfirm }: Props) {
  // 3.1 状态
  const [state, setState] = useState(null);

  // 3.2 副作用
  useEffect(() => {
    // ...
  }, []);

  // 3.3 事件处理函数
  const handleClick = () => {
    // ...
  };

  // 3.4 渲染
  return (
    <div>
      {/* ... */}
    </div>
  );
}
```

### 2.2 Hooks 规范

```typescript
// useState
const [count, setCount] = useState(0);        // ✅
const [user, setUser] = useState<User | null>(null);  // ✅

// useEffect
useEffect(() => {
  // ...
}, []);  // ✅ 依赖数组必须有

// 自定义 Hook
function useMyHook() {  // ✅ 必须以 use 开头
  // ...
}
```

### 2.3 样式规范

```tsx
// 优先使用 className
<div className="flex items-center gap-4">  // ✅

// 避免内联样式
<div style={{ display: 'flex' }}>  // ❌ 除非动态值
<div style={{ marginLeft: offset }}>  // ✅ 动态值可以

// Tailwind 类名顺序
// 布局 → 间距 → 大小 → 颜色 → 其他
<div className="flex p-4 w-full bg-white rounded-lg">
```

---

## 3. 后端规范 (Node.js/Python)

### 3.1 API 路由规范

```typescript
// 路由文件命名
app/api/users/route.ts           // 集合路由
app/api/users/[id]/route.ts     // 单项路由

// HTTP 方法
export async function GET(request: Request) { }  // ✅ 大写
export async function POST(request: Request) { } // ✅ 大写

// 响应格式
return Response.json({
  success: true,
  data: result,
  message: 'Success'
});
```

### 3.2 错误处理

```typescript
// 统一错误处理
try {
  // ...
} catch (error) {
  console.error('操作失败:', error);
  return Response.json({
    success: false,
    error: error.message
  }, { status: 500 });
}
```

---

## 4. 数据库规范

### 4.1 查询规范

```typescript
// 使用参数化查询，防止 SQL 注入
db.query('SELECT * FROM users WHERE id = ?', [id]);  // ✅
db.query(`SELECT * FROM users WHERE id = ${id}`);    // ❌

// 使用事务处理多表操作
await db.transaction(async (trx) => {
  // ...
});
```

---

## 5. Git 规范

### 5.1 Commit 规范

```bash
# 格式
[ID] [标题] - completed

# 示例
[5] 用户登录页面 - completed
[12] 数据库 Schema - completed
```

### 5.2 分支规范

```bash
main          # 主分支，生产代码
develop       # 开发分支
feature/xxx   # 功能分支
hotfix/xxx    # 紧急修复分支
```

---

## 6. 安全规范

### 6.1 敏感信息

```typescript
// ❌ 不要硬编码敏感信息
const API_KEY = 'sk-xxxxx';

// ✅ 使用环境变量
const API_KEY = process.env.API_KEY;

// ❌ 不要打印敏感信息
console.log('Password:', password);

// ✅ 使用日志级别
logger.debug('Auth succeeded');
```

### 6.2 输入验证

```typescript
// 验证所有用户输入
function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

---

## 7. 性能规范

### 7.1 避免不必要的渲染

```typescript
// 使用 React.memo
export const MyComponent = React.memo(function MyComponent({ data }) {
  // ...
});

// 使用 useMemo
const computed = useMemo(() => expensiveCalc(data), [data]);

// 使用 useCallback
const handleClick = useCallback(() => {
  // ...
}, [dependency]);
```

### 7.2 代码分割

```typescript
// 懒加载组件
const HeavyComponent = lazy(() => import('./HeavyComponent'));
```

---

## 8. 测试规范

### 8.1 测试文件命名

```
__tests__/
  components/
    UserList.test.tsx
  utils/
    format.test.ts
```

### 8.2 测试编写

```typescript
// 测试必须有描述
describe('UserList', () => {
  it('should render users', () => {
    // ...
  });

  it('should handle empty state', () => {
    // ...
  });
});
```

---

## 9. 禁止事项

| 禁止项 | 原因 |
|--------|------|
| `console.log` | 使用 logger |
| `any` 类型 | 使用具体类型 |
| 魔法数字 | 使用常量 |
| 嵌套三元 | 使用 if/else |
| `==` 比较 | 使用 `===` |
| `var` | 使用 `const`/`let` |
| 硬编码路径 | 使用相对路径 |

---

## 10. 检查清单

提交代码前必须确认：

- [ ] `npm run lint` 通过
- [ ] `npm run build` 成功
- [ ] `npm test` 通过（如果有测试）
- [ ] 没有引入新的 `any` 类型
- [ ] 没有硬编码敏感信息
- [ ] 代码符合项目风格
- [ ] 删除了调试代码
- [ ] 更新了相关文档
