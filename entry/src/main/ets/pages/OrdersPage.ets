import { OrderApi } from '../api/OrderApi'
import { OrderDetail, OrderItem } from '../model/OrderModels'
import { Money } from '../utils/Money'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { PageStateType, PageStateView } from '../components/common/PageStateView'

@Component
export struct OrdersPage {
  onBack: () => void = () => {}
  @State orders: OrderDetail[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State detail: OrderDetail | null = null
  @State detailSheetVisible: boolean = false
  @State detailLoading: boolean = false
  @State actionBusy: boolean = false

  aboutToAppear(): void { this.load() }

  private async load(): Promise<void> {
    this.loading = true
    this.error = ''
    try { this.orders = await OrderApi.list() }
    catch (error) { this.error = error instanceof Error ? error.message : '订单加载失败，请重试' }
    finally { this.loading = false }
  }

  private statusText(status: string): string {
    if (status === 'PENDING_PAYMENT') { return '待付款' }
    if (status === 'PAID') { return '已付款' }
    if (status === 'CANCELLED') { return '已取消' }
    if (status === 'CLOSED') { return '已关闭' }
    return status
  }

  private async openDetail(orderId: number): Promise<void> {
    this.detailLoading = true
    this.error = ''
    try { this.detail = await OrderApi.get(orderId); this.detailSheetVisible = true }
    catch (error) { this.error = error instanceof Error ? error.message : '订单详情加载失败，请重试' }
    finally { this.detailLoading = false }
  }

  private confirmCancel(): void {
    if (this.detail === null || this.actionBusy) { return }
    this.getUIContext().showAlertDialog({
      title: '取消订单？', message: '取消后订单状态以服务端返回结果为准。',
      primaryButton: { value: '保留', action: () => {} },
      secondaryButton: { value: '取消订单', fontColor: AppColors.DANGER, action: () => this.cancel() }
    })
  }

  private async cancel(): Promise<void> {
    if (this.detail === null || this.actionBusy) { return }
    this.actionBusy = true
    try {
      const orderId = this.detail.id
      await OrderApi.cancel(orderId)
      await this.load()
      this.detail = await OrderApi.get(orderId)
    } catch (error) { this.error = error instanceof Error ? error.message : '订单取消失败，请刷新后重试' }
    finally { this.actionBusy = false }
  }

  @Builder
  detailSheet() {
    if (this.detail === null) {
      Column() { PageStateView({ type: PageStateType.Loading, title: '正在读取订单', description: '稍等片刻。' }) }.width('100%').height('100%').justifyContent(FlexAlign.Center)
    } else {
      Column({ space: 14 }) {
        Row() { Text('订单详情').fontSize(18).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1); Text('×').fontSize(24).fontColor(AppColors.TEXT_SECONDARY).padding(5).onClick(() => { this.detailSheetVisible = false; this.detail = null }) }.width('100%')
        Text(this.statusText(this.detail.status)).fontSize(14).fontColor(AppColors.BRAND).padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor(AppColors.BRAND_SOFT).borderRadius(10)
        Text(`订单号：${this.detail.orderNo}`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).width('100%')
        ForEach(this.detail.items, (item: OrderItem) => {
          Row() {
            Column({ space: 4 }) { Text(item.skuNameSnapshot).fontSize(14).fontColor(AppColors.TEXT_PRIMARY); Text(`× ${item.quantity}`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY) }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text(`¥ ${Money.format(Money.cents(item.salePrice) * item.quantity)}`).fontSize(14).fontColor(AppColors.TEXT_PRIMARY)
          }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.BACKGROUND).borderRadius(14)
        }, (item: OrderItem) => item.id.toString())
        Text(`收货地址：${this.detail.shippingAddress.receiverName} ${this.detail.shippingAddress.receiverPhone}\n${this.detail.shippingAddress.province}${this.detail.shippingAddress.city}${this.detail.shippingAddress.district}${this.detail.shippingAddress.detailAddress}`)
          .width('100%').fontSize(12).lineHeight(19).fontColor(AppColors.TEXT_SECONDARY).padding(AppSpacing.CARD).backgroundColor(AppColors.BACKGROUND).borderRadius(14)
        Row() { Text('后端确认金额').fontSize(14).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1); Text(`¥ ${this.detail.totalAmount.toFixed(2)}`).fontSize(21).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY) }.width('100%')
        if (this.detail.status === 'PENDING_PAYMENT') { Button(this.actionBusy ? '正在取消…' : '取消订单').width('100%').height(46).backgroundColor(AppColors.SURFACE).fontColor(AppColors.DANGER).border({ width: 1, color: '#E6B7AF' }).borderRadius(AppRadius.CONTROL).enabled(!this.actionBusy).onClick(() => this.confirmCancel()) }
      }.width('100%').height('100%').padding(AppSpacing.CARD)
    }
  }

  build() {
    Column({ space: AppSpacing.ITEM }) {
      Row() {
        Text('‹').fontSize(32).width(42).height(42).textAlign(TextAlign.Center).fontColor(AppColors.TEXT_PRIMARY).onClick(this.onBack)
        Column({ space: 2 }) {
          Text('我的订单').fontSize(19).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text('订单状态以服务端最新结果为准').fontSize(10).fontColor(AppColors.TEXT_TERTIARY)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      }.width('100%')
      if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取订单', description: '稍等片刻。' })
      } else if (this.error.length > 0 && this.orders.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '订单暂时无法加载', description: this.error, onAction: () => this.load() })
      } else if (this.orders.length === 0) {
        PageStateView({ type: PageStateType.Empty, title: '还没有订单', description: '提交订单后，会在这里显示真实状态。', actionLabel: '返回商城', onAction: this.onBack })
      } else {
        Scroll() {
          Column({ space: 12 }) {
            if (this.error.length > 0) { Text(this.error).width('100%').fontSize(12).fontColor(AppColors.DANGER) }
            ForEach(this.orders, (order: OrderDetail) => {
              Column({ space: 12 }) {
                Row() {
                  Text(`订单 ${order.orderNo}`).fontSize(13).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
                  Text(this.statusText(order.status)).fontSize(11).fontColor(order.status === 'PENDING_PAYMENT' ? AppColors.ACCENT : AppColors.BRAND)
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor(order.status === 'PENDING_PAYMENT' ? AppColors.ACCENT_SOFT : AppColors.BRAND_SOFT).borderRadius(10)
                }.width('100%')
                Text(`${order.items.length} 件商品 · 创建于 ${order.createdAt}`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).width('100%')
                Row() { Blank(); Text(`¥ ${order.totalAmount.toFixed(2)}`).fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY); Button('查看详情', { type: ButtonType.Normal }).height(36).fontSize(12).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).margin({ left: 12 }).onClick(() => this.openDetail(order.id)) }.width('100%')
              }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD).border({ width: 1, color: AppColors.DIVIDER })
            }, (order: OrderDetail) => order.id.toString())
          }.width('100%').padding({ top: 4, bottom: 22 })
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
      Blank().height(76)
    }.width('100%').height('100%').padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 12 }).backgroundColor(AppColors.BACKGROUND)
      .bindSheet($$this.detailSheetVisible, this.detailSheet(), { height: SheetSize.LARGE, showClose: false, backgroundColor: AppColors.SURFACE })
  }
}
