# CLAUDE.md

本文件为在此仓库中使用 Claude Code (claude.ai/code) 提供指导。

## 技术栈

- **引擎**: Godot 4.6
- **语言**: GDScript（静态类型）
- **渲染**: GL Compatibility（OpenGL 兼容模式）
- **平台**: 桌面应用
- **分辨率**: 1600x900

## 构建与运行

**运行游戏：**
- 在 Godot 4.x 中打开项目，按 F5
- 主场景：`res://scenes/main/main.tscn`

**无头烟雾测试：**
```bash
godot4 --headless --path . -s res://tests/run_smoke_tests.gd
```

## 项目结构

```
game/
├── scripts/
│   ├── core/          # 核心系统（单例、游戏循环）
│   ├── data/          # 数据定义（Resource 类）
│   └── ui/            # UI 组件和战斗界面
├── scenes/
├── assets/
└── tests/             # 烟雾测试
```

## 架构概述

### 自动加载单例（autoload）

三个全局单例管理核心状态：
- `GameData` (res://scripts/core/game_data.gd) - 所有游戏定义的中央注册表（英雄、敌人、天赋、图腾、关卡、事件）
- `Localization` (res://scripts/core/localization.gd) - 中/英文本切换
- `SaveService` (res://scripts/core/save_service.gd) - 已解锁关卡和种子的本地持久化

### 脚本依赖关系

```
main.tscn → BattleRoot → BoardManager + WaveDirector + EventDirector
```

1. **RunState** 保存当前对局状态（金币、生命值、天赋、图腾等级、波次进度）
2. **WaveDirector** 根据波次定义生成敌人
3. **CombatResolver** 处理攻击瞄准、伤害计算、状态效果
4. **EventDirector** 在波次间触发随机事件
5. **TraitDraftSystem** 提供全局天赋和进化天赋的三选一

### 数据定义（scripts/data/）

所有游戏数据使用 `Resource` 类以便编辑器配置：
- `HeroDef` (res://scripts/data/hero_def.gd) - 8 名英雄，包含职业、攻击模式、星级成长、天赋池
- `EnemyDef` (res://scripts/data/enemy_def.gd) - 敌人属性、标签、首领标记
- `TraitDef` (res://scripts/data/trait_def.gd) - 全局增益和英雄专属进化天赋
- `TotemDef` (res://scripts/data/totem_def.gd) - 毒液/暴击/冰冻图腾，带等级成长
- `WaveDef` / `StageDef` (res://scripts/data/wave_def.gd) - 5 波次关卡，第 5 波为首领
- `EventDef` (res://scripts/data/event_def.gd) - 随机事件选项及效果

### 关键系统

| 系统 | 文件 | 说明 |
|------|------|------|
| SummonEconomySystem | scripts/core/summon_economy_system.gd | 花费成长（基础 10，每次召唤 +2，上限 30）、折扣、免费召唤 |
| TotemSystem | scripts/core/totem_system.gd | 被动增益和命中触发效果（每 6 次命中触发中毒，每 8 次触发冻结） |
| BoardManager | scripts/ui/board_manager.gd | 20 格部署带、拖拽合并、右键出售 |
| PieceStats | scripts/core/piece_stats.gd | 聚合英雄单位的所有增益效果 |
| WaveDirector | scripts/core/wave_director.gd | 根据波次定义生成敌人 |
| CombatResolver | scripts/core/combat_resolver.gd | 攻击瞄准、伤害计算、状态效果 |
| EventDirector | scripts/core/event_director.gd | 波次间随机事件 |
| TraitDraftSystem | scripts/core/trait_draft_system.gd | 全局天赋和进化天赋的三选一 |
| RunState | scripts/core/run_state.gd | 当前对局状态（金币、HP、天赋、图腾、波次） |

### UI 结构

| 组件 | 文件 | 说明 |
|------|------|------|
| BattleRoot | scripts/ui/battle_root.gd | 战斗根容器 |
| BoardManager | scripts/ui/board_manager.gd | 部署槽位和英雄放置 |
| BoardSlot | scripts/ui/board_slot.gd | 单个部署槽位 |
| HeroPiece | scripts/ui/hero_piece.gd | 英雄单位视觉组件 |
| EnemyActor | scripts/ui/enemy_actor.gd | 敌人视觉组件 |
| IconBadge | scripts/ui/icon_badge.gd | 可复用的状态/指示器组件 |

## UI 开发指南

开发 UI 时请遵循 `demo/ui-refresh-guidelines.md`：
- 以战场为中心，战斗区域居中
- 单层部署带（无叠加面板）
- 底部操作带：金币（左）、核心生命值（中）、图腾/召唤按钮（右）
- 多车道敌人推进与横向部署对应
- 统一的西方魔幻卡通头像风格

## 编码约定

- 使用静态类型的 GDScript（`: Type` 注解）
- 使用 `preload()` 在脚本顶部加载资源
- Resource 类使用 `@export` 进行编辑器序列化
- 状态可变是预期的（RefCounted 对象，非不可变模式）
- 基于字典的增益/减益效果模式
- 通过 `Localization.is_chinese()` 实现中/英文本本地化

## Repository Editing Rules

- On Windows, prefer modifying files via PowerShell instead of apply_patch when editing text files.
- Always write files using UTF-8 encoding.
- Prefer UTF-8 without BOM unless the target file already uses another encoding.
- When using PowerShell to write files, explicitly set encoding and avoid default system encoding.
- Be careful not to introduce mojibake or garbled Chinese text.