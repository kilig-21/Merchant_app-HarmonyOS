import { OrderApi } from '../api/OrderApi'
import { OrderDetail, OrderItem } from '../model/OrderModels'
import { Money } from '../utils/Money'
import { OrderPresentation } from '../utils/OrderPresentation'
import { AppColors, AppRadius } from '../theme/AppTheme'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { PageHeader } from '../components/common/PageHeader'

@Component
export struct OrdersPage {
  @Prop initialFilter: string = ''
  onBack: () => void = () => {}
  onBrowse: () => void = () => {}
  @State filter: string = ''
  @State orders: OrderDetail[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State detail: OrderDetail | null = null
  @State detailSheetVisible: boolean = false
  @State detailLoading: boolean = false
  @State detailError: string = ''
  @State actionBusy: boolean = false
  private selectedId: number = 0
  private serial: number = 0
  private alive: boolean = false

  aboutToAppear(): void { this.alive = true; this.filter = this.initialFilter; this.load() }
  aboutToDisappear(): void { this.alive = false; this.serial++ }
  private async load(): Promise<void> {
    this.loading = true
    this.error = ''
    try { const orders = await OrderApi.list(); if (this.alive) { this.orders = orders } }
    catch (error) { if (this.alive) { this.error = error instanceof Error ? error.message : '订单加载失败，请重试' } }
    finally { if (this.alive) { this.loading = false } }
  }
  private async openDetail(id: number): Promise<void> {
    const request = ++this.serial
    this.selectedId = id
    this.detail = null
    this.detailSheetVisible = true
    this.detailLoading = true
    this.detailError = ''
    try {
      const detail = await OrderApi.get(id)
      if (this.alive && request === this.serial) { this.detail = detail }
    } catch (error) {
      if (this.alive && request === this.serial) { this.detailError = error instanceof Error ? error.message : '详情读取失败' }
    } finally { if (this.alive && request === this.serial) { this.detailLoading = false } }
  }
  private confirmCancel(): void {
    if (this.detail === null || this.actionBusy) { return }
    this.getUIContext().showAlertDialog({
      title: '取消这笔订单？', message: '取消后可重新挑选商品，原订单将无法继续付款。',
      primaryButton: { value: '保留订单', action: () => {} },
      secondaryButton: { value: '取消订单', fontColor: AppColors.DANGER, action: () => this.cancel() }
    })
  }
  private async cancel(): Promise<void> {
    if (this.detail === null || this.actionBusy) { return }
    const id = this.detail.id
    this.actionBusy = true
    this.detailError = ''
    try { await OrderApi.cancel(id) }
    catch (error) { this.detailError = error instanceof Error ? error.message : '取消结果未确认，请刷新查看' }
    // 成功与冲突都重新读取；查询失败时禁用基于旧状态的取消操作。
    try { this.detail = await OrderApi.get(id) }
    catch (_) { this.detail = null; this.detailError = '订单状态暂时无法确认，请重新读取详情' }
    await this.load()
    this.actionBusy = false
  }

  @Builder
  filterTab(label: string, status: string) {
    Button(label, { type: ButtonType.Normal }).height(44).fontSize(13)
      .padding({ left: 16, right: 16 })
      .backgroundColor(this.filter === status ? AppColors.BRAND_SOFT : AppColors.SURFACE)
      .fontColor(this.filter === status ? AppColors.BRAND : AppColors.TEXT_SECONDARY)
      .border({ width: 1, color: this.filter === status ? AppColors.BRAND : AppColors.DIVIDER }).borderRadius(22)
      .onClick(() => this.filter = status)
  }
  @Builder
  detailSheet() {
    Column({ space: 16 }) {
      Row() {
        Text('订单详情').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND).layoutWeight(1)
        Button('×', { type: ButtonType.Normal }).width(44).height(44).padding(0).fontSize(25)
          .backgroundColor(Color.Transparent).fontColor(AppColors.BRAND).enabled(!this.actionBusy)
          .accessibilityText('关闭订单详情').onClick(() => { this.detailSheetVisible = false; this.serial++ })
      }.width('100%')
      if (this.detailLoading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取订单', description: '' })
      } else if (this.detail === null) {
        PageStateView({ type: PageStateType.Error, title: '暂时无法打开订单', description: this.detailError,
          onAction: () => this.openDetail(this.selectedId) })
      } else {
        Scroll() {
          Column({ space: 20 }) {
            Column({ space: 8 }) {
              Text(OrderPresentation.status(this.detail.status)).fontSize(25).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
              Text(this.detail.status === 'PENDING_PAYMENT' ? '订单已保留，当前版本暂未开放在线付款。' : '你可以在这里查看订单最新信息。')
                .fontSize(13).lineHeight(21).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start).padding(18).backgroundColor(AppColors.BRAND_SOFT).borderRadius(14)
            Text('商品清单').fontSize(17).fontColor(AppColors.BRAND).width('100%')
            ForEach(this.detail.items, (item: OrderItem) => {
              Row({ space: 12 }) {
                Image($r('app.media.product_placeholder')).width(48).height(56).objectFit(ImageFit.Cover).borderRadius(10)
                Column({ space: 6 }) {
                  Text(item.skuNameSnapshot).fontSize(15).fontColor(AppColors.BRAND)
                  Text('数量 ' + item.quantity).fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text('¥ ' + Money.format(Money.cents(item.salePrice) * item.quantity)).fontSize(15).fontColor(AppColors.BRAND)
              }.width('100%')
            }, (item: OrderItem) => item.id.toString())
            Divider().color(AppColors.DIVIDER)
            Column({ space: 8 }) {
              Text('收货信息').fontSize(17).fontColor(AppColors.BRAND)
              Text(this.detail.shippingAddress.receiverName + '  ' + this.detail.shippingAddress.receiverPhone)
                .fontSize(14).fontColor(AppColors.BRAND)
              Text(this.detail.shippingAddress.province + this.detail.shippingAddress.city + this.detail.shippingAddress.district + this.detail.shippingAddress.detailAddress)
                .fontSize(13).lineHeight(22).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').alignItems(HorizontalAlign.Start)
            Divider().color(AppColors.DIVIDER)
            Text('订单编号  ' + this.detail.orderNo).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).width('100%').copyOption(CopyOptions.InApp)
            Text('创建时间  ' + OrderPresentation.date(this.detail.createdAt)).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).width('100%')
            Row() {
              Text('订单金额').fontSize(14).fontColor(AppColors.BRAND)
              Blank()
              Text('¥ ' + this.detail.totalAmount.toFixed(2)).fontSize(24).fontColor(AppColors.BRAND)
            }.width('100%')
            if (this.detailError.length > 0) { Text(this.detailError).fontSize(13).lineHeight(21).fontColor(AppColors.DANGER) }
          }.width('100%').padding({ bottom: 24 })
        }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
        if (this.detail.status === 'PENDING_PAYMENT') {
          Button(this.actionBusy ? '正在确认状态…' : '取消订单', { type: ButtonType.Normal }).width('100%').height(48)
            .backgroundColor(AppColors.BACKGROUND).fontColor(AppColors.DANGER).borderRadius(12)
            .enabled(!this.actionBusy).onClick(() => this.confirmCancel())
        }
      }
    }.width('100%').height('100%').padding({ left: 22, right: 22, bottom: 24 })
  }

  build() {
    Column({ space: 16 }) {
      PageHeader({ title: '我的订单', actionLabel: '刷新', actionDisabled: this.loading,
        onBack: this.onBack, onAction: () => this.load() })
      Scroll() {
        Row({ space: 8 }) {
          this.filterTab('全部', '')
          this.filterTab('待付款', 'PENDING_PAYMENT')
          this.filterTab('已付款', 'PAID')
          this.filterTab('已取消', 'CANCELLED')
          this.filterTab('已关闭', 'CLOSED')
        }
      }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在读取订单', description: '' })
      } else if (this.error.length > 0 && this.orders.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '订单暂时无法加载', description: this.error, onAction: () => this.load() })
      } else if (OrderPresentation.filter(this.orders, this.filter).length === 0) {
        PageStateView({ type: PageStateType.Empty, title: this.filter.length > 0 ? '暂无' + OrderPresentation.status(this.filter) + '订单' : '还没有订单',
          description: this.orders.length > 0 ? '切换其他状态查看已有订单，或继续挑选。' : '挑一件喜欢的商品，开启你的第一笔订单。',
          actionLabel: '去逛逛', onAction: this.onBrowse })
      } else {
        Scroll() {
          Column({ space: 14 }) {
            if (this.error.length > 0) { Text(this.error).fontSize(13).fontColor(AppColors.DANGER) }
            ForEach(OrderPresentation.filter(this.orders, this.filter), (order: OrderDetail) => {
              Button({ type: ButtonType.Normal }) {
                Column({ space: 16 }) {
                  Row() {
                    Text(OrderPresentation.date(order.createdAt)).fontSize(12).fontColor(AppColors.TEXT_SECONDARY).layoutWeight(1)
                    Text(OrderPresentation.status(order.status)).fontSize(12).fontColor(order.status === 'PENDING_PAYMENT' ? AppColors.ACCENT : AppColors.BRAND)
                      .padding({ left: 9, right: 9, top: 5, bottom: 5 })
                      .backgroundColor(order.status === 'PENDING_PAYMENT' ? AppColors.ACCENT_SOFT : AppColors.BRAND_SOFT).borderRadius(10)
                  }.width('100%')
                  Divider().color(AppColors.DIVIDER)
                  Text(order.items.map((item: OrderItem) => item.skuNameSnapshot).join(' / ')).fontSize(16).lineHeight(24)
                    .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).fontColor(AppColors.BRAND).width('100%').textAlign(TextAlign.Start)
                  Row() {
                    Text('共 ' + OrderPresentation.quantity(order) + ' 件').fontSize(12).fontColor(AppColors.TEXT_SECONDARY)
                    Blank()
                    Text('¥ ' + order.totalAmount.toFixed(2)).fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
                  }.width('100%')
                  Row() { Blank(); Text('查看详情 ›').fontSize(13).fontColor(AppColors.BRAND) }.width('100%')
                }.width('100%').padding(18)
              }.width('100%').padding(0).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
                .onClick(() => this.openDetail(order.id))
            }, (order: OrderDetail) => order.id.toString())
          }.width('100%').padding({ bottom: 24 })
        }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').padding({ left: 18, right: 18, top: 8 }).backgroundColor(AppColors.BACKGROUND)
      .bindSheet($$this.detailSheetVisible, this.detailSheet(), { height: SheetSize.LARGE,
        showClose: false, backgroundColor: AppColors.SURFACE,
        shouldDismiss: (action: SheetDismiss) => { if (!this.actionBusy) { this.serial++; action.dismiss() } } })
  }
}
