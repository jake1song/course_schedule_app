# UI 大改版实施计划

基于 `docs/superpowers/specs/2026-05-13-ui-redesign.md`

## 总览

6 个阶段，按依赖顺序执行。每阶段自包含，完成后立即可验证。

---

## Phase 0: 主题基础设施

**文件**: 新建 `lib/config/app_theme.dart`

**内容**:
- 颜色 token 常量（primaryGradient, surface, surfaceBorder, background, textPrimary/secondary/tertiary, shadow）
- `AppTheme.primaryGradient` — `LinearGradient(colors: [#0066FF, #7C3AED], begin: topLeft, end: bottomRight)`
- `AppTheme.cardShadow` — 统一 BoxShadow
- `AppTheme.cardBorderRadius` — 统一 20px
- `AppTheme.floatingNavShadow` — 导航阴影
- 6 个 period 颜色映射：`periodColors = {'第1节': blue, '第2节': green, '第3节': orange, '第4节': purple, '第5节': sunset, '第6节': navy}`

**修改**: `lib/main.dart` — ThemeData 更新
- 更新 `colorScheme` seed
- 更新 `scaffoldBackgroundColor` → `#F2F4F7`
- 更新 `inputDecorationTheme` → filled 样式

**验证**: `flutter analyze` 0 issues, ThemeData 编译通过

---

## Phase 1: LoginPage + RegisterPage 改版

**文件**: `lib/screens/login_page.dart`, `lib/screens/register_page.dart`

**改动**:
- 顶部渐变 hero 区（`Container(height: screenHeight * 0.35, decoration: gradient)`）
- 渐变区内：App 图标 + "课表星图" 标题（白色）
- 底部白色圆角容器（`BorderRadius.vertical(top: 32)`）
- 输入框改为 `filled` 样式，浅灰背景，无边框
- 登录按钮改为渐变填充

**逻辑不变**: 手机号校验、密码 toggle、loading 态、错误提示

**验证**: 视觉检查，登录/注册流程正常

---

## Phase 2: HomePage 大改版

**文件**: `lib/screens/home_page.dart`, `lib/widgets/action_strip.dart`, `lib/widgets/schedule_row_tile.dart`, `lib/widgets/nav_tab.dart`

**2a — Header**:
- 移除 AppBar，自定义渐变 header（高度 ~120px）
- 大标题 "第 X 周"（28px weight 300 白色）+ 日期范围 + 右上角图标
- ActionStrip 融入 header

**2b — 周选择器**:
- 胶囊 pills（`BorderRadius.circular(20)`）
- 选中：渐变填充 + 白色文字
- 未选中：半透白背景

**2c — 课程卡片**:
- 半透白背景 + 柔和阴影 + 20px 圆角
- 左侧 4px 彩色竖条（period 对应颜色）
- Period 数字在圆形渐变徽章内
- 日期分隔条更小更淡

**2d — 底部导航**:
- 浮动胶囊（`BorderRadius.circular(28)`）
- 半透白 + backdrop-blur（`BackdropFilter` 包裹在 `HW_ACCEL` flag 中）
- `margin: horizontal(20px), bottom(12px)`
- 选中项渐变指示点

**2e — EmptyState**:
- 更大的渐变色图标
- 文字更轻更小

**逻辑不变**: 课程加载、周切换、增删改、跳转、下拉刷新

**验证**: `flutter analyze`, 课程加载/删除/编辑/导入正常

---

## Phase 3: AiChatPage 改版 + 文件拆分

**文件**: `lib/screens/ai_chat_page.dart` → 拆分为主文件 + 4 个新 widget

**3a — 拆分**:
- `lib/widgets/chat_bubble.dart` — `ChatBubble` widget（用户/AI/系统三种样式）
- `lib/widgets/key_input_page.dart` — `KeyInputPage`（原 `_KeyInputPage`）
- `lib/widgets/profile_editor.dart` — `ProfileEditorSheet`（原画像编辑弹窗）
- `lib/widgets/history_sheet.dart` — `HistorySheet`（原历史对话弹窗）

**3b — Header**:
- 渐变背景 AppBar
- 标题白色
- 操作图标白色半透明
- 强制搜索开关开启时图标渐变高亮

**3c — 聊天气泡**:
- 用户：蓝紫渐变填充 + 白色文字 + 20px 圆角（右下角 4px）
- AI：半透白（`rgba(255,255,255,0.72)`）+ 1px 边框 + 20px 圆角（左下角 4px）
- 系统：无背景，居中，12px 灰字
- 间距：同角色连续 4px，切换 16px

**3d — 快捷提问**:
- 横向滚动圆角胶囊（14px）
- 半透白背景

**3e — 输入区域**:
- 半透白容器
- 输入框 24px 圆角，浅灰填充
- 发送按钮渐变圆形

**3f — 其他弹窗**:
- Key 输入、画像编辑、历史对话统一毛玻璃卡片样式

**逻辑不变**: 聊天、搜索、fallback、profile、history 全部保持不变

**验证**: `flutter analyze`, AI 聊天/搜索/开关/profile 全流程正常

---

## Phase 4: 表单页改版

**文件**: `lib/screens/add_course_page.dart`, `lib/screens/edit_course_page.dart`, `lib/screens/import_course_page.dart`

**4a — AddCoursePage / EditCoursePage**:
- 周次+星期 → 一张半透白卡片内水平排列
- 节次 → 单独一张卡片
- 课程名+教室+备注 → 一张卡片
- 保存按钮 → AppBar 右侧渐变文字
- 间距增大到 16px

**4b — ImportCoursePage**:
- 输入区 → 半透白卡片
- 按钮 → 渐变
- 预览列表 → 左侧彩色竖条，与首页统一

**逻辑不变**: 表单校验、保存、导入解析

**验证**: `flutter analyze`, 新增/编辑/导入课程正常

---

## Phase 5: 公共组件更新

**文件**: `lib/widgets/update_dialog.dart`, `lib/widgets/form_fields.dart`

**5a — UpdateDialog**:
- 毛玻璃弹窗背景
- 渐变进度条
- 下载按钮渐变

**5b — FormFields**:
- WeekNumberField、DayDropdown、PeriodDropdown → filled 样式

**逻辑不变**: 更新检测、APK 下载、表单行为

---

## Phase 6: 验证

- [ ] `flutter analyze` — 0 issues
- [ ] `flutter test` — 全部通过（可能需要更新 shell test 中的 widget 名称匹配）
- [ ] 全流程手动验证：启动→登录→首页→新增课程→编辑→删除→导入→AI 聊天→搜索→更新检测

---

## 执行顺序

```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
```

Phase 0 必须先完成（所有后续依赖 `AppTheme`）。
Phase 1-5 之间依赖较弱，但建议按序执行。
Phase 3 的文件拆分是最大的结构性改动。
