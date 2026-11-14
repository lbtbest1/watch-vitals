# VitalsWatch(元气表)— 个人健康监测 watchOS 应用

> 自用项目:心率/睡眠/HRV/血氧/步数聚合 → 本地计算「准备指数」→ 表盘小组件一抬腕可见。
> 无 Mac 开发链路:Windows 写码 → GitHub Actions(macOS runner)云编译出未签名 IPA → HermesFixGui 免费证书重签 → 经 iPhone 装上手表。

## 指标范围(v1 冻结)

| 指标 | 来源 | 说明 |
|---|---|---|
| 心率 | HealthKit `heartRate` | 当前/静息,被动数据 |
| HRV | `heartRateVariabilitySDNN` | 系统主要在**睡眠期**采集,晨间读昨夜均值 |
| 睡眠 | `sleepAnalysis` | 时长+分期(深睡/REM/核心),watchOS 9+ 分期数据 |
| 血氧 | `oxygenSaturation` | ⚠️ 国行手表可能被禁用,App 必须优雅降级(无数据不计分) |
| 步数 | `stepCount` 统计聚合 | 当日+7日基线 |
| 准备指数 | 本地计算 | 0-100 加权综合分,详见下方公式 |

## 准备指数 v1 公式(参数可调)

```
总分 = HRV得分×0.25 + 静息心率得分×0.20 + 睡眠得分×0.30 + 血氧得分×0.10 + 恢复负荷得分×0.15

· HRV得分    昨夜SDNN均值 vs 30天基线:≥基线+10%→100,线性映射
· 静息心率   晨间RHR vs 30天基线:低3bpm→100,高5bpm→40
· 睡眠得分   时长效率70% + 结构(深睡≥15%、REM≥20%)30%
· 血氧得分   夜间均值≥96%→100;<93%→40;无数据→权重归零并重归一
· 恢复负荷   昨日活动量 vs 7日均值:适度↑,过量↓
```

## 架构

```
┌─────────────────── Apple Watch ───────────────────┐
│  VitalsWatch App (SwiftUI)                        │
│   ├─ HealthKitService   读 6 类指标(授权一次)      │
│   ├─ ReadinessEngine    计算 0-100 + 分项          │
│   ├─ BaselineStore      7/30天滚动基线(本地)       │
│   └─ App Group 共享容器 → WidgetKit 读取           │
│  Complications (accessory 家族)                    │
│   circular(指数环) / rectangular(指数+心率+睡眠)   │
│   inline(文本) / corner(小环)                      │
│  刷新:开App时 + WKApplicationRefreshScheduler 定时  │
└───────────────────────┬───────────────────────────┘
                        │ Companion 配对
┌─────────────────── iPhone ────────────────────────┐
│  Vitals 宿主 App(最小化)                           │
│   └─ 长趋势页:7/30/90天各指标折线,数据由手表同步     │
└────────────────────────────────────────────────────┘
```

## 里程碑(每个都有可验证判据)

- **M0 管道验证**:空壳 App(照抄 HermesEnabler 的 iphone+watch 双包结构)→ CI 出 IPA → HermesFixGui 签名 → 装上你的手表能打开。
  判据:手表桌面出现图标且不闪退。**这是最大风险点,必须最先做。**
- **M1 核心数据**:HealthKit 授权+读取,主页显示心率/步数/昨夜睡眠时长。
- **M2 准备指数**:HRV/基线/公式全量 + 表盘小组件(App Group 链路,若签名不兼容则降级方案)。
- **M3 打磨**:iPhone 趋势页、指标详情页、参数设置页。
- **M4 续签脚本化**:7 天到期一键重签(复用打包好的工具)。

## v2 迭代(2026-11-14 需求确认,四项全选)

- **身体数据全集**:体重、睡眠心率、日照时间、呼吸频率、手腕温度(全 HealthKit 被动数据)
- **智能洞察提醒**:基线偏离告警——生病前兆/过度训练/睡眠负债,本地判定 + 本地通知
- **趋势与报告**:7/30/90 天趋势、每周健康报告摘要、连续达标 streak
- **压力与正念**:压力评分、呼吸练习引导、Breathe 会话即时 HRV

## 构建链路(无 Mac)

```
Windows(写码) ──push──▶ GitHub 仓库(公开)
                          │ macos runner + xcodegen + xcodebuild(关签名)
                          ▼
                    unsigned VitalsWatch.ipa(artifact/Release)
                          │ 下载回 Windows
                          ▼
              HermesFixGui 重签(免费 Apple ID)→ 装表
```

## 已知风险与对策

| 风险 | 对策 |
|---|---|
| HermesFixGui 引擎对自研 App 的 bundle ID / App Group 处理未验证 | M0 用最小壳先验证;不行则调整结构直至与 HermesEnabler 同构 |
| 国行手表血氧禁用 | 血氧项可选,无数据自动重归一权重 |
| 免费证书 7 天过期 | M4 做一键重签;App 数据存 HealthKit/本地,重签不丢 |
| Widget 扩展的 App Group 签名兼容性 | M2 先做 30 分钟 spike;失败降级为「仅 App 内查看」 |
| watchOS 后台限制 | 不做常驻后台;依赖系统被动采集 + 定时后台刷新 |
