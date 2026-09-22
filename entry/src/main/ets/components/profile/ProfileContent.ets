import { SessionViewModel } from '../../viewmodel/SessionViewModel'
import { AppColors, AppRadius } from '../../theme/AppTheme'

@Component
export struct ProfileContent {
  @ObjectLink session: SessionViewModel
  onLogin: () => void = () => {}
  onOpenOrders: (status: string) => void = () => {}
  onOpenAddresses: () => void = () => {}
  onOpenAfterSales: () => void = () => {}
  onOpenHelp: () => void = () => {}
  onOpenSettings: () => void = () => {}

  @Builder
  orderEntry(icon: Resource, label: string, status: string) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 10 }) {
        Image(icon).width(26).height(26)
        Text(label).fontSize(12).fontColor(AppColors.BRAND)
      }.width('100%').padding({ top: 15, bottom: 15 })
    }.layoutWeight(1).padding(0).backgroundColor(Color.Transparent).borderRadius(12)
      .onClick(() => this.onOpenOrders(status)).accessibilityText(label)
  }

  @Builder
  service(icon: Resource, title: string, description: string, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Image(icon).width(42).height(42).padding(10).backgroundColor(AppColors.BRAND_SOFT).borderRadius(13)
        Column({ space: 5 }) {
          Text(title).fontSize(16).fontColor(AppColors.BRAND)
          Text(description).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text('›').fontSize(24).fontColor(AppColors.TEXT_SECONDARY)
      }.width('100%').padding({ top: 18, bottom: 18 })
    }.width('100%').padding(0).backgroundColor(Color.Transparent).borderRadius(8).onClick(action)
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Row() {
          Text('我的拾光').fontSize(26).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
          Blank()
          Button('设置', { type: ButtonType.Normal }).height(44).fontSize(13).fontColor(AppColors.BRAND)
            .backgroundColor(Color.Transparent).onClick(this.onOpenSettings)
        }.width('100%')
        Button({ type: ButtonType.Normal }) {
          Row({ space: 16 }) {
            Stack() {
              if (this.session.username.length > 0) {
                Text(this.session.username.substring(0, 1)).fontSize(23).fontColor(AppColors.BRAND)
              } else {
                Image($r('app.media.nav_profile')).width(27).height(27)
              }
            }.width(54).height(54).backgroundColor(AppColors.BRAND_SOFT).borderRadius(18)
            Column({ space: 8 }) {
              Text(this.session.username || '欢迎来到拾光集').fontSize(21).fontWeight(FontWeight.Medium)
                .fontColor(AppColors.SURFACE).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.session.username.length > 0 ? '每一次选择，都值得认真对待' : '登录 / 注册，保存你的好物清单')
                .fontSize(12).lineHeight(20).fontColor('#DBE2D7')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('›').fontSize(26).fontColor(AppColors.SURFACE)
          }.width('100%').padding(20)
        }.width('100%').padding(0).backgroundColor(AppColors.BRAND).borderRadius(AppRadius.CARD)
          .onClick(() => { if (this.session.username.length === 0) { this.onLogin() } else { this.onOpenSettings() } })
        if (this.session.error.length > 0) {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 10 }) {
              Text('!').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.DANGER)
              Text(this.session.error).fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).layoutWeight(1).textAlign(TextAlign.Start)
              Text('登录 ›').fontSize(12).fontColor(AppColors.DANGER)
            }.width('100%').padding(14)
          }.width('100%').padding(0).backgroundColor(AppColors.ACCENT_SOFT).borderRadius(AppRadius.CONTROL)
            .onClick(this.onLogin).accessibilityText(`${this.session.error}，登录`)
        }
        Column() {
          Row() {
            Text('我的订单').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
            Blank()
            Button('全部订单 ›', { type: ButtonType.Normal }).height(44).fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY).backgroundColor(Color.Transparent).onClick(() => this.onOpenOrders(''))
          }.width('100%')
          Divider().color(AppColors.DIVIDER)
          Row() {
            this.orderEntry($r('app.media.icon_pending'), '待付款', 'PENDING_PAYMENT')
            this.orderEntry($r('app.media.icon_paid'), '已付款', 'PAID')
            this.orderEntry($r('app.media.icon_cancelled'), '已取消', 'CANCELLED')
          }.width('100%')
        }.width('100%').padding(18).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
        Column() {
          this.service($r('app.media.icon_address'), '收货地址', '管理你的收货信息', this.onOpenAddresses)
          Divider().color(AppColors.DIVIDER)
          this.service($r('app.media.icon_after_sale'), '售后服务', '申请售后并查看处理进度', this.onOpenAfterSales)
          Divider().color(AppColors.DIVIDER)
          this.service($r('app.media.icon_help'), '购物帮助', '购物流程与常见问题', this.onOpenHelp)
          Divider().color(AppColors.DIVIDER)
          this.service($r('app.media.icon_settings'), '账户与设置', '账号信息与使用说明', this.onOpenSettings)
        }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
      }.width('100%').constraintSize({ maxWidth: 640 }).padding({ top: 20, bottom: 108, left: 4, right: 4 })
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(AppColors.BACKGROUND)
  }
}
