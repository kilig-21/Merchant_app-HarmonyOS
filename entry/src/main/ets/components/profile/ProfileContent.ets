import { SessionViewModel } from '../../viewmodel/SessionViewModel'
import { AppColors, AppRadius } from '../../theme/AppTheme'

@Component
export struct ProfileContent {
  @ObjectLink session: SessionViewModel
  onLogin: () => void = () => {}
  onOpenOrders: (status: string) => void = () => {}
  onOpenAddresses: () => void = () => {}
  onOpenHelp: () => void = () => {}
  onOpenSettings: () => void = () => {}

  @Builder
  orderEntry(symbol: string, label: string, status: string) {
    Button({ type: ButtonType.Normal }) {
      Column({ space: 10 }) {
        Text(symbol).fontSize(24).fontColor(AppColors.ACCENT)
        Text(label).fontSize(12).fontColor(AppColors.BRAND)
      }.width('100%').padding({ top: 15, bottom: 15 })
    }.layoutWeight(1).padding(0).backgroundColor(Color.Transparent).borderRadius(12)
      .onClick(() => this.onOpenOrders(status)).accessibilityText(label)
  }

  @Builder
  service(title: string, description: string, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
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
      Column({ space: 24 }) {
        Row() {
          Text('我的拾光').fontSize(28).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
          Blank()
          Button('设置', { type: ButtonType.Normal }).height(44).fontSize(13).fontColor(AppColors.BRAND)
            .backgroundColor(Color.Transparent).onClick(this.onOpenSettings)
        }.width('100%')
        Button({ type: ButtonType.Normal }) {
          Row({ space: 16 }) {
            Text(this.session.username.length > 0 ? this.session.username.substring(0, 1) : '客')
              .width(56).height(56).padding({ top: 13 }).textAlign(TextAlign.Center).fontSize(23)
              .fontColor(AppColors.BRAND).backgroundColor(AppColors.BRAND_SOFT).borderRadius(28)
            Column({ space: 8 }) {
              Text(this.session.username || '欢迎来到拾光集').fontSize(21).fontWeight(FontWeight.Medium)
                .fontColor(AppColors.SURFACE).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.session.username.length > 0 ? '每一次选择，都值得认真对待' : '登录 / 注册，保存你的好物清单')
                .fontSize(12).lineHeight(20).fontColor('#DBE2D7')
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('›').fontSize(26).fontColor(AppColors.SURFACE)
          }.width('100%').padding(22)
        }.width('100%').padding(0).backgroundColor(AppColors.BRAND).borderRadius(AppRadius.CARD)
          .onClick(() => { if (this.session.username.length === 0) { this.onLogin() } else { this.onOpenSettings() } })
        Column() {
          Row() {
            Text('我的订单').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
            Blank()
            Button('全部订单 ›', { type: ButtonType.Normal }).height(44).fontSize(12)
              .fontColor(AppColors.TEXT_SECONDARY).backgroundColor(Color.Transparent).onClick(() => this.onOpenOrders(''))
          }.width('100%')
          Divider().color(AppColors.DIVIDER)
          Row() {
            this.orderEntry('◷', '待付款', 'PENDING_PAYMENT')
            this.orderEntry('✓', '已付款', 'PAID')
            this.orderEntry('↶', '已取消', 'CANCELLED')
          }.width('100%')
        }.width('100%').padding(18).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
        Column() {
          this.service('收货地址', '添加、编辑和管理默认地址', this.onOpenAddresses)
          Divider().color(AppColors.DIVIDER)
          this.service('购物帮助', '购物流程、订单与售后说明', this.onOpenHelp)
          Divider().color(AppColors.DIVIDER)
          this.service('账户与设置', '账号状态、使用说明与退出登录', this.onOpenSettings)
        }.width('100%').padding({ left: 18, right: 18 }).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
        Text('拾光集 · 把喜欢，带进日常').fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
      }.width('100%').constraintSize({ maxWidth: 640 }).padding({ top: 20, bottom: 108, left: 4, right: 4 })
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(AppColors.BACKGROUND)
  }
}
