# UI 大改版设计规格 — 课表星图

日期: 2026-05-13 | 版本: 1.0 | 目标版本: 1.5.0

## 设计语言

**参考**: Apple Health / Fitness — 半透明卡片、模糊背景、大留白、渐变强调

### 颜色系统

| Token | 值 | 用途 |
|-------|-----|------|
| `primaryGradient` | `#0066FF → #7C3AED` (135°) | 按钮、选中态、用户气泡、首页头部 |
| `surface` | `rgba(255,255,255,0.72)` | 毛玻璃卡片背景 |
| `surfaceBorder` | `rgba(255,255,255,0.4)` | 卡片边框 |
| `background` | `#F2F4F7` | 底层背景（比当前稍暖） |
| `textPrimary` | `#1A1A2E` | 主文字（更深） |
| `textSecondary` | `#6B7280` | 次要文字（不变） |
| `textTertiary` | `#9CA3AF` | 辅助文字 |
| `shadow` | `rgba(0,0,0,0.06)` | 卡片阴影（更柔和） |

### 圆角

- 大卡片（课程卡片、聊天泡泡、表单分组）: 20px
- 小元素（按钮、输入框、chips）: 14px
- 胶囊（周选择器 pill、导航栏）: 28px

### 间距

- 卡片间距: 16px → 20px
- 卡片内边距: 14px → 20px (水平), 16px (垂直)
- 屏幕水平边距: 16px → 20px
- Section 间距: 24px

### 阴影

- 卡片阴影: `BoxShadow(color: rgba(0,0,0,0.06), blurRadius: 16, offset: 0,4)`
- 浮动导航: `BoxShadow(color: rgba(0,0,0,0.10), blurRadius: 24, offset: 0,-2)`

### 字体

- 大标题: 28px, weight 300（当前页周数）
- 页面标题: 22px, weight 600
- 卡片标题: 16px, weight 600
- 正文: 15px, weight 400
- 辅助: 13px, weight 400

---

## 逐页设计

### 1. AuthGate（启动门）

**不变**：loading/超时/重试逻辑完全不变。

**视觉改动**：
- Loading 页：白底 + 渐变色 CircularProgressIndicator + App 名
- 超时页：毛玻璃卡片替代纯文字

### 2. LoginPage / RegisterPage

**不变**：表单字段、校验逻辑、登录流程。

**视觉改动**：
- 顶部 35% 高度：蓝紫渐变背景 + App logo（白色半透明）+ "课表星图" 标题
- 底部 65%：白色圆角容器（top-left/top-right 32px）浮在渐变区上方
- 输入框：`filled` 样式，浅灰背景，圆角 14px，去掉边框
- 登录按钮：渐变填充，圆角 14px，白色文字
- 注册链接：蓝色文字链接

### 3. HomePage（首页）

**不变**：课程加载、周切换、增删改、导入、AI 跳转逻辑。

**视觉改动**：

**Header 区域**：
- 顶部渐变背景条（高度 ~120px），带 backdrop-filter 模糊（Android 不可用时降级为半透渐变）
- AppBar 消失，融入 header
- 大标题 "第 X 周"（28px, weight 300）+ 日期范围（14px 灰色）
- 右上角小图标：设置、导入、AI

**周选择器**：
- 横向滚动胶囊 pills（圆角 20px）
- 未选中：半透白背景
- 选中：蓝紫渐变填充 + 白色数字
- 显示月.日格式

**课程卡片**：
- 半透白背景（rgba(255,255,255,0.72)）+ 柔和阴影
- 左侧 4px 彩色竖条（period 对应颜色：第1节蓝、第2节绿、第3节橙、第4节紫、第5节日落、第6节深蓝）
- 内边距：20px 水平, 16px 垂直
- period 数字显示在左侧圆形渐变徽章内
- 课程名 16px bold，时间+教室 13px gray
- 日期分隔条：更淡、更小字号

**底部导航**：
- 浮动胶囊式（圆角 28px，半透白 + backdrop-blur）
- 悬浮于内容之上，不贴底（margin-bottom: 12px）
- 4 个图标：新增、导入、课表（高亮）、AI
- 选中项有渐变色指示点

### 4. AiChatPage（AI 聊天）

**不变**：聊天逻辑、搜索触发、fallback、profile、history。

**视觉改动**：

**Header**：
- 渐变背景条，标题 "AI 日程助手" 白色
- 功能图标（搜索开关、画像、历史、新对话、Key）白色半透明
- 强制搜索开关：开启时图标渐变高亮

**聊天气泡**：
- 用户气泡：蓝紫渐变填充（左深右浅），白色文字，圆角 20px（右下角 4px）
- AI 气泡：半透白毛玻璃（rgba(255,255,255,0.72)），1px 半透白边框，圆角 20px（左下角 4px）
- 系统消息：无背景，居中，12px 灰色，上下间距更小
- 气泡最大宽度：75%
- 间距：用户/AI 连续消息 4px，切换角色 16px

**快捷提问**：
- 横向滚动圆角胶囊（14px 圆角）
- 半透白背景 + 细边框
- 点击后填入输入框

**输入区域**：
- 半透白容器，与底部融为一体
- 输入框内嵌，圆角 24px，浅灰填充
- 发送按钮：渐变圆形（直径 44px）

**Key 输入页**：
- 居中毛玻璃卡片
- 模型选择改为圆角 chips 横向排列

**画像编辑**：
- 分组卡片式，每组一个半透白卡片
- 保存按钮渐变

**历史对话**：
- 列表项毛玻璃卡片
- 当前对话有左侧蓝色竖条

### 5. AddCoursePage / EditCoursePage

**不变**：表单逻辑、校验、保存。

**视觉改动**：
- 周次+星期 一行两个字段，半透白卡片包裹
- 节次下拉单独一张卡片
- 课程名、教室、备注 合为一张卡片
- 保存按钮改为 AppBar 右侧渐变文字按钮
- 间距增大到 16px

### 6. ImportCoursePage

**不变**：解析、预览、提交逻辑。

**视觉改动**：
- 输入区域：半透白卡片
- 解析/导入按钮：渐变
- 预览列表：卡片左侧彩色 period 竖条，与首页统一
- 滑动删除保持

### 7. 公共组件

**UpdateDialog**：
- 毛玻璃弹窗背景
- 渐变进度条
- 下载按钮渐变

**EmptyState**：
- 更大的渐变色图标
- 文字更轻

**FormFields**（WeekNumberField, DayDropdown, PeriodDropdown）：
- 输入框改为 filled 样式（浅灰背景，无边框）

---

## 技术实现要点

1. **性能守卫**：`BackdropFilter` 仅在 HomePage header 和底部导航使用，且被 `enableHardwareAcceleration` 功能开关包裹。低端机型关闭后降级为纯色半透。

2. **渐变实现**：使用 `LinearGradient`，方向统一 135°（左上→右下）。按钮、用户气泡、周选择器选中态共用同一个渐变定义。

3. **颜色系统**：在 `AppConfig` 或新文件 `app_theme.dart` 中集中定义所有颜色、渐变、阴影常量。禁止在 widget 中硬编码颜色。

4. **文件拆分**：`ai_chat_page.dart`（当前 492 行）在改版中拆分：气泡组件 → `widgets/chat_bubble.dart`，Key 输入 → `widgets/key_input.dart`，画像编辑 → `widgets/profile_editor.dart`，历史 → `widgets/history_sheet.dart`。

5. **兼容性**：Android API 24+，毛玻璃效果在 API 31+ 用原生 `RenderEffect`，低版本降级为半透纯色。

---

## 非功能性要求

- 所有现有功能逻辑不变
- `flutter analyze` 0 issues
- 所有现有测试继续通过
- 不引入新的第三方依赖
- 渐变/阴影常量在单一文件中定义，避免重复
