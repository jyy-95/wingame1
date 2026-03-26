# 英雄图标美术规范 v1.0

## 目标
为 Godot 项目的英雄部署图标产出一套统一、可落地的正式美术规范。
这份文档只解决一件事：后续该让美术或图像模型产出什么样的素材，才能稳定接入当前 UI。

## 最终使用场景
- 主要场景：部署带中的英雄图标
- 图标外形：竖向徽记卡
- 图标观感：写实、可爱、干净、统一
- 信息优先级：先看角色，再看职业，再看稀有度

## 风格定义
### 核心关键词
- 写实材质
- 可爱神态
- 白底棚拍
- 轻收藏感
- 小型战斗伙伴

### 不要的方向
- 扁平职业图标
- Q 版表情包脸
- 过度夸张的卡通比例
- 脏乱复杂背景
- 大量技能特效挡住角色
- 把角色画成 UI 按钮或 logo

### 应该像什么
- 像摄影棚拍摄的小型战斗角色
- 像能被收集的精致角色徽记
- 保留毛发、皮革、金属、布料等真实细节
- 可爱来自眼神、比例、姿态，不来自夸张变形

## 构图规范
### 画面比例
- 原始出图建议比例：4:5
- 推荐尺寸：1024x1280 或 1536x1920
- 角色最终会被裁进竖向卡框

### 构图要求
- 角色必须完整露出主要识别部位
- 角色主体占画面可视面积 65% 到 78%
- 头部和上半身优先清晰
- 武器或道具可露出，但不能把脸挡住
- 角色尽量单体，不要多人
- 角色朝向可以略微侧身，但不要过度透视

### 背景要求
- 纯净浅色背景优先
- 推荐白色、暖白、极浅灰
- 只允许极轻微棚拍阴影
- 禁止场景背景、地面透视、建筑、特效墙

## UI 适配规范
### 图标卡面结构
- 外框：竖向圆角徽记卡
- 内部：角色主图
- 右上：职业角标
- 底部：稀有度或等级条

### 裁切原则
- 不要把角色画得太靠底
- 头顶保留 6% 到 10% 呼吸空间
- 左右保留 8% 到 12% 安全边距
- 底部允许略贴边，但脚部不是必须完整
- 脸、眼睛、主武器必须在安全区内

## 角色统一规则
### 所有英雄必须统一的部分
- 同一套光线逻辑
- 同一套背景逻辑
- 同一套材质完成度
- 同一套可爱程度
- 同一套裁切尺度

### 允许变化的部分
- 职业辅色
- 配件类型
- 站姿与动作
- 武器与道具
- 稀有度表现

## 职业辅色建议
- 盾卫 / 防御：象牙金 + 钢灰
- 法师 / 冰系：冷银 + 冰蓝
- 毒系 / 炼金：草药绿 + 苔藓绿
- 雷系 / 召唤：淡紫 + 冷紫
- 近战 / 刃系：暖铜 + 琥珀橙

## 当前英雄单独要求
### 铁壁守卫
- 锚点角色
- 可以保留浣熊持枪方向
- 关键词：真实毛发、金属枪械、反差萌、防御感
- 不要把枪裁掉，不要只剩半张脸

### 霜语先知
- 关键词：冷静、聪明、轻法器、干净、克制
- 不要大面积冰特效
- 更像安静的冰系角色，而不是技能图标

### 毒雾贤者
- 关键词：草药、毒剂、小瓶罐、柔和但危险
- 不要整张图只剩绿色
- 应靠配件和气质体现毒系

### 风暴召唤师
- 关键词：轻灵、术式感、微雷光、淡紫辅色
- 不要大面积闪电贴满画面
- 保持角色主体优先

### 刃舞者
- 关键词：敏捷、利落、轻武器、暖铜边框
- 不要做成一大坨橙色
- 轮廓要竖向清晰，动作可以更轻快

## 交付清单
每个英雄至少交付：
- 1 张正式 PNG 立式图标原图
- 1 张去背景透明 PNG
- 1 张白底版本 PNG
- 1 张缩略预览图

推荐额外交付：
- 角色半身备用图 1 张
- 不同裁切版本 2 张
- 源文件 1 份（PSD / 分层文件）

## 文件命名规范
- hero_iron_warden_portrait.png
- hero_frost_oracle_portrait.png
- hero_venom_sage_portrait.png
- hero_storm_caller_portrait.png
- hero_blade_dancer_portrait.png

如果有不同裁切：
- hero_iron_warden_portrait_crop_a.png
- hero_iron_warden_portrait_crop_b.png

## 出图模型提示词模板
可直接给图像模型使用：

"A realistic cute fantasy battle companion character, studio lighting, clean light background, full body or 3/4 body, highly detailed fur/fabric/metal materials, collectible character badge style, centered composition, readable face, soft shadow, premium mobile game hero portrait, no scene background, no text, no UI frame"

### 铁壁守卫附加词
- raccoon soldier
- rifle with metallic detail
- cute but sturdy
- warm fur, clean white background

### 霜语先知附加词
- frost oracle
- silver blue accessory
- calm eyes
- light magical focus item

### 毒雾贤者附加词
- venom sage
- herb vial accessory
- moss green accent
- soft but dangerous mood

### 风暴召唤师附加词
- storm caller
- subtle violet accent
- arcane summoner feeling
- light electric aura only

### 刃舞者附加词
- blade dancer
- light dual blade or short blade accessory
- agile posture
- copper warm accent

## 验收标准
一张图标合格，至少满足：
- 缩到小尺寸后还能一眼认出角色
- 角色脸和主体没有被裁掉
- 不依赖文字也能区分职业气质
- 和铁壁守卫放在一起不显得像两个游戏
- 放进竖向卡框后依然完整、干净、值钱

## 不合格示例判断
以下任意一条出现，就需要重做：
- 看起来像 app 图标而不是角色
- 背景过花
- 角色太小
- 角色被特效盖住
- 画风和其他英雄不统一
- 明显比铁壁守卫更扁平或更廉价

## 接入建议
等正式美术出来后，再做 Godot 接入：
- 先统一导入尺寸
- 再按英雄单独微调裁切
- 最后统一边框、角标、稀有度条

不要在没有正式素材的情况下继续强行做“成品感替身”。那样只能得到假的统一，不会得到真的成品。
