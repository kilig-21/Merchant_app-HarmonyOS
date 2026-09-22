# 拾光集 · HarmonyOS 消费者商城

拾光集是一款面向 HarmonyOS 的日常好物商城 App。它以“暖白纸感、深绿品牌、陶土金额”为视觉基调，帮助用户浏览店铺、查看商品、选择规格、加入购物车、管理收货地址并提交订单。

## 当前能力

- 首页商品发现：商品搜索、店铺搜索、分页加载、空结果和失败重试。
- 店铺目录：横向切换店铺、查看店内商品、空店状态引导。
- 商品详情：商品示意图、价格与库存、规格选择、数量控制、店铺入口。
- 购物车：跨店分组、单品/店铺/全选、数量增减、售罄与库存校验、批量移除、预估合计。
- 账号与消费者流程：登录/注册、会话恢复、退出账号、收货地址、确认订单、订单列表、订单详情和取消待付款订单。
- 品牌化体验：统一页面标题栏、悬浮底栏、桌面图标、启动图标、线性图标和浅色系统栏。
- 可访问性与稳定性：主要操作提供无障碍描述，写操作互斥，网络错误提供可重试状态，接口响应格式异常会被明确识别。

在线支付、物流跟踪和退款售后目前保留为未开放能力，页面会明确提示，不虚构业务结果。

## 技术栈

- HarmonyOS ArkUI / ArkTS
- DevEco Studio SDK 26.0.0
- Stage 模型 UIAbility
- 远程数据源：`BrowseSource.Remote`
- 应用包名：`com.example.myapplication`

主要目录：

```text
AppScope/                         应用级资源、品牌图标和名称
entry/src/main/ets/api/           地址、账号、购物车、订单等接口封装
entry/src/main/ets/components/    首页、店铺、商品、购物车、个人中心组件
entry/src/main/ets/pages/         登录、详情、地址、结算、订单等页面
entry/src/main/ets/theme/         共享颜色、间距、圆角和商品示意图映射
entry/src/main/ets/viewmodel/     会话、购物车和结算状态
scripts/                          源码回归、主题检查和界面验收 fixture
docs/                             开发交接与视觉验收记录
```

## 构建

在已安装 DevEco Studio 的 Windows 环境中执行：

```powershell
$env:DEVECO_SDK_HOME = 'D:\Coding\IDEs\DevEco Studio\sdk'
& 'D:\Coding\IDEs\DevEco Studio\tools\node\node.exe' `
  'D:\Coding\IDEs\DevEco Studio\tools\hvigor\bin\hvigorw.js' `
  --mode module -p product=default -p module=entry@default assembleHap --no-daemon
```

构建产物：

```text
entry/build/default/outputs/default/entry-default-unsigned.hap
```

当前仓库没有个人签名配置，因此产物是未签名 HAP。接入正式签名时，请在本地安全配置签名，不要提交证书或密钥。

## 回归检查

```powershell
& 'D:\Coding\IDEs\DevEco Studio\tools\node\node.exe' scripts/check-theme.cjs
& 'D:\Coding\IDEs\DevEco Studio\tools\node\node.exe' scripts/check-shopping.cjs '<TypeScript模块目录>'
& 'D:\Coding\IDEs\DevEco Studio\tools\node\node.exe' scripts/check-consumer.cjs '<TypeScript模块目录>'
```

`check-theme.cjs` 检查共享色板的文字对比度；其余脚本覆盖商品/SKU/购物车金额、库存、会话恢复、登录、订单筛选和写操作互斥等逻辑。

## 界面验收 fixture

本地视觉验收可以使用纯内存 fixture：

```powershell
& 'D:\Coding\IDEs\DevEco Studio\tools\node\node.exe' scripts/consumer-ui-fixture.cjs --visual
```

然后将设备端口映射到本机：

```powershell
hdc rport tcp:18765 tcp:18765
```

fixture 只用于模拟器界面检查，不连接真实数据库、不代表真实商品、不产生真实交易。验收结束后应停止 fixture 并将 `entry/src/main/ets/config/NetworkConfig.ets` 保持为正式联调地址。

## 接口配置

正式联调地址集中维护在：

```text
entry/src/main/ets/config/NetworkConfig.ets
```

设备或模拟器不能把 `127.0.0.1` 当作电脑地址；如果后端运行在开发机上，请使用设备可访问的局域网地址，并确保网络与后端服务均已开放。

## 视觉验收

最近一次模拟器验收记录见：[docs/视觉验收-2026-09-22.md](docs/视觉验收-2026-09-22.md)。其中包含首页、店铺、个人中心、结算、桌面图标、接口不可达状态，以及默认字号和 1.3 倍字号的检查范围。

## 当前边界

- 商品图片为本地示意插画；未知商品使用中性占位图。
- 当前品牌采用固定浅色视觉，完整深色主题尚未开放。
- 真实服务端端到端、实体真机、屏幕阅读器、小屏/折叠屏仍需要后续专项验收。
- 在线支付、物流和退款售后尚未接入。
