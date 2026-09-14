import { AddressApi } from '../api/AddressApi'
import { CheckoutApi } from '../api/CheckoutApi'
import { CartItem } from '../model/CartModels'
import { Address, CheckoutGroup, CheckoutRequest } from '../model/CheckoutModels'
import { CartViewModel } from '../viewmodel/CartViewModel'
import { Money } from '../utils/Money'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { PageStateType, PageStateView } from '../components/common/PageStateView'

@Component
export struct CheckoutPage {
  @ObjectLink cart: CartViewModel
  onBack: () => void = () => {}
  onOpenAddresses: () => void = () => {}
  onOpenOrders: () => void = () => {}
  @State addresses: Address[] = []
  @State selectedAddressId: number = 0
  @State loading: boolean = true
  @State error: string = ''
  @State submitting: boolean = false
  @State result: CheckoutGroup | null = null
  private idempotencyKey: string = ''

  aboutToAppear(): void { this.loadAddresses() }

  private async loadAddresses(): Promise<void> {
    this.loading = true
    this.error = ''
    try {
      this.addresses = await AddressApi.list()
      const defaultAddress = this.addresses.find((item: Address) => item.isDefault)
      this.selectedAddressId = defaultAddress?.id ?? this.addresses[0]?.id ?? 0
    } catch (error) { this.error = error instanceof Error ? error.message : '地址加载失败，请重试' }
    finally { this.loading = false }
  }

  private selectedAddress(): Address | undefined {
    return this.addresses.find((item: Address) => item.id === this.selectedAddressId)
  }

  private ensureIdempotencyKey(): string {
    if (this.idempotencyKey.length === 0) {
      this.idempotencyKey = `checkout-${Date.now()}-${Math.floor(Math.random() * 1000000)}`
    }
    return this.idempotencyKey
  }

  private async submit(): Promise<void> {
    const items = this.cart.selectedItems()
    if (this.submitting || this.selectedAddressId === 0 || items.length === 0) { return }
    this.submitting = true
    this.error = ''
    try {
      const ids = items.map((item: CartItem) => item.id)
      this.result = await CheckoutApi.create(new CheckoutRequest(ids, this.selectedAddressId), this.ensureIdempotencyKey())
      this.idempotencyKey = ''
      await this.cart.load()
    } catch (error) { this.error = error instanceof Error ? error.message : '订单提交状态未知，请使用同一页面重试确认结果' }
    finally { this.submitting = false }
  }

  build() {
    Column({ space: AppSpacing.ITEM }) {
      Row() {
        Text('‹').fontSize(32).width(42).height(42).textAlign(TextAlign.Center).fontColor(AppColors.TEXT_PRIMARY).onClick(this.onBack)
        Text(this.result === null ? '确认订单' : '提交结果').fontSize(19).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY).layoutWeight(1)
      }.width('100%')
      if (this.result !== null) {
        Column({ space: 14 }) {
          Text('订单已提交').fontSize(25).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text('等待支付。当前 App 不提供模拟付款。').fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
          Column({ space: 9 }) {
            Text(`结算单号：${this.result.checkoutNo}`).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
            Text(`后端确认金额：¥ ${this.result.totalAmount.toFixed(2)}`).fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            Text(`已创建 ${this.result.orders.length} 个订单`).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
          }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.BRAND_SOFT).borderRadius(AppRadius.CARD)
          Button('查看我的订单').width('100%').height(46).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).onClick(this.onOpenOrders)
        }.width('100%').padding(AppSpacing.CARD).backgroundColor('#FFFFFF').borderRadius(AppRadius.CARD)
      } else if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在准备订单', description: '正在读取可用地址。' })
      } else if (this.error.length > 0 && this.addresses.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '暂时无法准备订单', description: this.error, onAction: () => this.loadAddresses() })
      } else if (this.addresses.length === 0) {
        PageStateView({ type: PageStateType.Empty, title: '请先填写收货地址', description: '订单提交前需要一个有效地址。', actionLabel: '管理地址', onAction: this.onOpenAddresses })
      } else {
        Scroll() {
          Column({ space: AppSpacing.ITEM }) {
            Text('收货地址').fontSize(13).fontColor(AppColors.TEXT_SECONDARY).width('100%')
            ForEach(this.addresses, (address: Address) => {
              Row({ space: 10 }) {
                Radio({ value: address.id.toString(), group: 'checkout-address' }).checked(this.selectedAddressId === address.id).onChange(() => this.selectedAddressId = address.id)
                Column({ space: 5 }) {
                  Text(`${address.receiverName}  ${address.receiverPhone}`).fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                  Text(`${address.province}${address.city}${address.district}${address.detailAddress}`).fontSize(12).lineHeight(18).fontColor(AppColors.TEXT_SECONDARY)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }.width('100%').padding(AppSpacing.CARD).backgroundColor('#FFFFFF').borderRadius(AppRadius.CARD).onClick(() => this.selectedAddressId = address.id)
            }, (address: Address) => address.id.toString())
            Button('管理收货地址').width('100%').height(42).backgroundColor(AppColors.BRAND_SOFT).fontColor(AppColors.BRAND).borderRadius(AppRadius.CONTROL).onClick(this.onOpenAddresses)
            Text('已选商品').fontSize(13).fontColor(AppColors.TEXT_SECONDARY).width('100%').margin({ top: 6 })
            ForEach(this.cart.selectedItems(), (item: CartItem) => {
              Row() {
                Column({ space: 5 }) { Text(item.productName).fontSize(14).fontColor(AppColors.TEXT_PRIMARY); Text(`${item.skuName} × ${item.quantity}`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY) }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text(`¥ ${Money.format(Money.cents(item.salePrice) * item.quantity)}`).fontSize(14).fontColor(AppColors.TEXT_PRIMARY)
              }.width('100%').padding(AppSpacing.CARD).backgroundColor('#FFFFFF').borderRadius(AppRadius.CARD)
            }, (item: CartItem) => item.id.toString())
            Text(`商品预估金额：¥ ${this.cart.selectedSubtotal()}。成交金额以后端结算结果为准。`).fontSize(12).lineHeight(19).fontColor(AppColors.TEXT_SECONDARY).width('100%')
            if (this.error.length > 0) { Text(this.error).fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).width('100%') }
          }.width('100%').padding({ bottom: 20 })
        }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
        Button(this.submitting ? '正在提交订单…' : '提交订单').width('100%').height(48).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).enabled(!this.submitting && this.cart.selectedItems().length > 0).onClick(() => this.submit())
      }
      Blank().height(76)
    }.width('100%').height('100%').padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 12 }).backgroundColor(AppColors.BACKGROUND)
  }
}
