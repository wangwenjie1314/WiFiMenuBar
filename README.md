# WiFi MenuBar

一个轻量级的macOS菜单栏应用，用于显示当前连接的WiFi网络名称。

## 项目结构

```
WiFiMenuBar/
├── WiFiMenuBar.xcodeproj/          # Xcode项目文件
├── WiFiMenuBar/                    # 主应用目录
│   ├── Models/                     # 数据模型
│   ├── Controllers/                # 控制器
│   ├── Services/                   # 服务层
│   ├── Utilities/                  # 工具类
│   ├── Resources/                  # 资源文件
│   │   ├── Assets.xcassets/        # 图标和颜色资源
│   │   └── Base.lproj/             # 本地化资源
│   ├── AppDelegate.swift           # 应用委托
│   ├── Info.plist                  # 应用配置
│   └── WiFiMenuBar.entitlements    # 应用权限
└── README.md                       # 项目说明
```

## 功能特性

- 在macOS菜单栏实时显示当前WiFi网络名称
- 支持网络状态变化的实时更新
- 提供用户设置和偏好配置
- 支持开机自启动
- 轻量级设计，最小化资源占用

## 系统要求

- macOS 10.15 或更高版本
- Xcode 15.0 或更高版本（用于开发）

## 开发状态

项目当前处于开发阶段，基础项目结构已创建完成。

## 框架依赖

- **CoreWLAN**: 用于获取WiFi网络信息
- **Network**: 用于监听网络状态变化
- **AppKit**: 用于macOS原生UI组件

## 构建说明

1. 使用Xcode打开 `WiFiMenuBar.xcodeproj`
2. 选择目标设备为Mac
3. 点击运行按钮构建和运行应用

## 启动命令
```bash
./start_wifi_menubar.sh
```

## 许可证

MIT