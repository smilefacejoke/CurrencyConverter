# 人民币美元自动转换器

一个用 SwiftUI 编写的 iOS 汇率换算 App：实时查询人民币 ↔ 美元汇率，支持双向换算，无网络时自动使用本地缓存。

## 功能

- **双向换算**：人民币 → 美元 / 美元 → 人民币，一键交换方向
- **实时汇率**：通过 [Frankfurter](https://frankfurter.dev)（欧洲央行 ECB 数据，免费无需 API Key）获取最新汇率
- **离线可用**：最近一次成功汇率落盘缓存，断网时自动回落，并在界面标记「离线缓存汇率」
- **下拉刷新**：随时手动更新汇率
- **清晰展示**：输入金额、换算结果、1 单位汇率、汇率日期与更新时间

## 技术栈

| 项目 | 说明 |
|------|------|
| 语言 | Swift 5 |
| UI | SwiftUI（`@Observable` / `NavigationStack`） |
| 平台 | iOS 17.0+ |
| 网络 | `URLSession` + async/await |
| 数据源 | Frankfurter API（`https://api.frankfurter.dev/v1/latest`） |

## 项目结构

```
CurrencyConverter/
├── CurrencyConverterApp.swift      # App 入口
├── Models/
│   ├── ExchangeRate.swift          # 汇率模型、币种枚举
│   └── ConverterViewModel.swift    # 转换逻辑与界面状态
├── Services/
│   ├── ExchangeRateService.swift   # 网络请求与错误处理
│   └── RateCache.swift             # 离线汇率缓存
├── Views/
│   └── ContentView.swift           # 主界面
└── Assets.xcassets/                # 图标与颜色资源
```

## 运行

1. 用 **Xcode 15+** 打开 `CurrencyConverter.xcodeproj`
2. 选择模拟器或真机（iOS 17.0+）
3. 按 `⌘R` 运行

> 真机运行需在 Signing & Capabilities 中选择你的开发者账号。

## 版本管理

本仓库使用 Git。常用命令：

```bash
# 保存修改
git add .
git commit -m "描述本次改动"

# 同步到远程
git push

# 拉取最新
git pull

# 打版本标签
git tag v1.0.0
git push origin v1.0.0
```

## 许可

仅供学习与个人使用。
