# ComicHarmony

鸿蒙原生漫画阅读器，支持折叠屏自适应、多数据源直连、离线缓存。

## 功能

- 📚 **漫画阅读** — 手势缩放、翻页动画、亮度调节、阅读器偏好设置
- 🔗 **多数据源** — 直连 Komga / WebDAV / 云盘，无需经过后端代理
- 📱 **折叠屏适配** — 手机、平板、折叠屏三种形态，Master-Detail 布局
- 💾 **离线缓存** — 阅读时自动缓存，无网络时也可阅读
- ⭐ **收藏管理** — 追番列表 + 阅读历史记录
- 🔍 **搜索** — 漫画搜索
- ☁️ **数据源管理** — 连接测试 + 持久化保存

## 技术栈

- **HarmonyOS 5.0 (API 12)** — ArkTS + Stage 模型
- **DevEco Studio** 开发
- 目标设备：手机、平板、折叠屏

## 页面

| 页面 | 功能 |
|------|------|
| Index | 首页（发现/收藏/我的，自适应布局） |
| ComicDetail | 漫画详情 + 章节列表 |
| Reader | 阅读器（手势/缩放/亮度/设置） |
| Search | 搜索 |
| Login | 登录 |
| Profile | 个人中心 |
| SourceManage | 数据源管理（连接测试） |
| DataSourceBrowser | 数据源浏览（3 级导航） |
| Favorites | 收藏列表 |
| Offline | 离线缓存管理 |

## 开发

1. 用 **DevEco Studio** 打开 `comic-harmony/` 目录
2. 等待 Gradle 同步完成
3. 连接手机/平板/模拟器，运行

后端 API 地址配置在 `api/HttpClient.ets`，默认连接 `http://10.0.2.2:9090`（Android 模拟器 → host）。

## 项目结构

```
entry/src/main/ets/
├── api/                    # HTTP 客户端 + API 定义
├── components/             # 通用组件 (7 个)
│   ├── BottomNav / SideNav # 导航组件
│   ├── ComicCard / ComicGridCard / DataSourceCard
│   ├── SettingsPanel       # 阅读器设置面板
│   └── SkeletonCard        # 加载骨架屏
├── datasource/             # 数据源直连实现
│   ├── IDataSource         # 接口定义
│   ├── KomgaDataSource     # Komga API 适配器
│   ├── WebDAVDataSource    # WebDAV 适配器
│   └── Manager             # 管理器
├── model/                  # 数据模型
├── pages/                  # 10 个页面
└── utils/                  # 工具类
    ├── OfflineStorage / DownloadManager  # 离线缓存
    ├── ReaderSettings                    # 阅读器偏好
    └── Responsive / Utils                # 自适应 + 通用工具
```
