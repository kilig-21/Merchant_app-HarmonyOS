import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { SessionViewModel } from '../viewmodel/SessionViewModel'
import { PageHeader } from '../components/common/PageHeader'

@Component
export struct ServicePage {
  @Prop settings: boolean = false
  @ObjectLink session: SessionViewModel
  onBack: () => void = () => {}
  onLogin: () => void = () => {}
  onLogout: () => void = () => {}
  @State expanded: number = -1

  @Builder
  question(index: number, title: string, answer: string) {
    Column({ space: 10 }) {
      Button({ type: ButtonType.Normal }) {
        Row() {
          Text(title).layoutWeight(1).fontSize(15).fontColor(AppColors.BRAND).textAlign(TextAlign.Start)
          Text(this.expanded === index ? '−' : '+').fontSize(20).fontColor(AppColors.BRAND)
        }.width('100%').padding({ top: 12, bottom: 12 })
      }.width('100%').padding(0).backgroundColor(Color.Transparent)
        .constraintSize({ minHeight: 48 }).accessibilityText(`${title}，${this.expanded === index ? '已展开' : '未展开'}`)
        .onClick(() => this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
          this.expanded = this.expanded === index ? -1 : index
        }))
      if (this.expanded === index) {
        Text(answer).fontSize(13).lineHeight(23).fontColor(AppColors.TEXT_SECONDARY).width('100%').padding({ bottom: 12 })
      }
      Divider().color(AppColors.DIVIDER)
    }.width('100%')
  }

  build() {
    Column() {
      PageHeader({ title: this.settings ? '账户与设置' : '购物帮助', inset: 16, onBack: this.onBack })
      Scroll() {
        Column({ space: 22 }) {
          if (this.settings) {
            Column({ space: 12 }) {
              Text('当前账户').fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
              Text(this.session.username || '尚未登录').fontSize(22).fontColor(AppColors.BRAND)
              Text('购物车、地址与订单属于当前登录账号。').fontSize(13).lineHeight(22).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start).padding(20).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
          }
          Text('购物有疑问，从这里了解').fontSize(23).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
          this.question(0, '如何挑选和购买商品？', '在首页搜索或进入店铺，查看商品详情，选择规格与数量并加入购物车。勾选商品后，确认收货地址和金额，再提交订单。')
          this.question(1, '为什么有些商品不能勾选？', '商品下架、售罄或数量超过当前库存时，暂时不能结算。可以调整数量或移除商品，再继续挑选。')
          this.question(2, '订单提交后如何查看？', '在“我的 → 我的订单”查看最新状态。待付款订单可以取消；取消前会再次确认。当前版本尚未开放在线付款。')
          this.question(3, '能查看物流、退款和售后吗？', '已付款订单可在“我的 → 售后服务”提交申请并查看审核进度。审核通过不代表退款已到账；物流和真实退款暂未开放。')
          this.question(4, '如何参加限量活动？', '从首页进入“限量活动”，倒计时会按服务端时间校准。登录后可选择限购范围内的数量申请资格；获得资格后，订单仍需等待服务端异步创建。')
          this.question(5, '网络中断后该怎么办？', '列表加载失败可点击重试。提交订单或抢购资格后若结果未确认，请使用页面提供的原请求重试，避免重复发起新的写操作。')
          this.question(6, '我的资料如何使用？', '当前 App 保存登录凭据以恢复会话，不保存登录密码。收货资料用于订单配送；退出账号会清理本机登录信息。')
          Text('拾光集 · 消费者商城').fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
          if (this.settings) {
            if (this.session.error.length > 0) { Text(this.session.error).fontSize(13).fontColor(AppColors.DANGER) }
            Button(this.session.username.length > 0 ? '退出当前账号' : '登录 / 注册').width('100%').height(48)
              .backgroundColor(AppColors.BRAND).fontColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL)
              .onClick(() => {
                if (this.session.username.length === 0) { this.onLogin() }
                else {
                  this.getUIContext().showAlertDialog({
                    title: '退出当前账号？', message: '本机购物车显示和登录状态会清理，账号中的商品与订单仍会保留。',
                    primaryButton: { value: '继续使用', action: () => {} },
                    secondaryButton: { value: '退出账号', fontColor: AppColors.DANGER, action: this.onLogout }
                  })
                }
              })
          }
        }.width('100%').constraintSize({ maxWidth: AppSpacing.CONTENT_MAX }).alignItems(HorizontalAlign.Start).padding(22)
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
