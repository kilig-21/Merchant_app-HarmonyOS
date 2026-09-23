import { AddressApi } from '../api/AddressApi'
import { CheckoutApi } from '../api/CheckoutApi'
import { CheckoutIntent } from '../viewmodel/CheckoutIntent'
import { ApiError } from '../network/ApiError'
import { CartItem } from '../model/CartModels'
import { Address, CheckoutCreateResult } from '../model/CheckoutModels'
import { CartViewModel } from '../viewmodel/CartViewModel'
import { Money } from '../utils/Money'
import { ProductArtwork } from '../theme/ProductArtwork'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { PageHeader } from '../components/common/PageHeader'

@Component
export struct CheckoutPage {
  @ObjectLink cart: CartViewModel
  onBack: () => void = () => {}
  onOpenAddresses: () => void = () => {}
  onOpenOrders: () => void = () => {}
  onLockChange: (locked: boolean) => void = () => {}
  @Prop @Watch('addressesChanged') addressRevision: number = 0
  @State addresses: Address[] = []
  @State selectedAddressId: number = 0
  @State loading: boolean = true
  @State error: string = ''
  @State submitting: boolean = false
  @State result: CheckoutCreateResult | null = null
  @State uncertain: boolean = false
  private intent: CheckoutIntent = new CheckoutIntent()

  aboutToAppear(): void { this.loadAddresses() }
  private addressesChanged(): void {
    if (!this.submitting && !this.uncertain && this.result === null) { this.loadAddresses() }
  }

  private async loadAddresses(): Promise<void> {
    this.loading = true
    this.error = ''
    try {
      this.addresses = await AddressApi.list()
      const defaultAddress = this.addresses.find((item: Address) => item.isDefault)
      if (!this.addresses.some((item: Address) => item.id === this.selectedAddressId)) {
        this.selectedAddressId = defaultAddress?.id ?? this.addresses[0]?.id ?? 0
      }
    } catch (error) { this.error = error instanceof Error ? error.message : '地址加载失败，请重试' }
    finally { this.loading = false }
  }

  private selectedAddress(): Address | undefined {
    return this.addresses.find((item: Address) => item.id === this.selectedAddressId)
  }

  private async submit(): Promise<void> {
    const items = this.cart.selectedItems()
    if (this.submitting || this.selectedAddressId === 0 || items.length === 0) { return }
    this.submitting = true
    this.onLockChange(true)
    this.error = ''
    try {
      const ids = items.map((item: CartItem) => item.id)
      this.result = await CheckoutApi.create(this.intent.begin(ids, this.selectedAddressId), this.intent.key)
      this.intent.reset()
      this.uncertain = false
      await this.cart.load()
    } catch (error) {
      const rejected = error instanceof ApiError && [400, 401, 403, 404, 409, 422].includes(error.statusCode)
      this.uncertain = !rejected
      if (rejected) { this.intent.reset() }
      this.error = this.uncertain ? '暂未确认提交结果。请点击下方按钮确认结果，期间保留当前商品与地址。' :
        (error instanceof Error ? error.message : '提交失败，请检查订单信息')
    }
    finally { this.submitting = false; this.onLockChange(this.uncertain) }
  }

  build() {
    Column({ space: AppSpacing.ITEM }) {
      PageHeader({ title: this.result === null ? '确认订单' : '提交结果',
        subtitle: this.result === null ? '确认地址与商品信息' : '查看订单最新信息',
        backDisabled: this.submitting || this.uncertain, onBack: this.onBack })
      if (this.result !== null) {
        Column({ space: 16 }) {
          Text('✓').fontSize(20).fontColor(AppColors.SURFACE).width(42).height(42).textAlign(TextAlign.Center).padding({ top: 9 }).backgroundColor(AppColors.SUCCESS).borderRadius(21)
          Text('订单已提交').fontSize(26).fontWeight(FontWeight.Bold).fontColor(AppColors.TEXT_PRIMARY)
          Text('可在订单中心查看详情。在线付款暂未开放。').fontSize(13).lineHeight(22).fontColor(AppColors.TEXT_SECONDARY)
          Column({ space: 9 }) {
            Text('订单确认').fontSize(11).letterSpacing(1).fontColor(AppColors.SUCCESS)
            Text(`结算单号：${this.result.checkoutNo}`).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
            Text(`订单金额：¥ ${this.result.totalAmount.toFixed(2)}`).fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
            Text(`已创建 ${this.result.orders.length} 个订单`).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
          }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.BRAND_SOFT).borderRadius(AppRadius.CARD)
          Button('查看我的订单').width('100%').height(46).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).onClick(this.onOpenOrders)
        }.width('100%').padding(22).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD).border({ width: 1, color: AppColors.DIVIDER })
      } else if (this.loading) {
        PageStateView({ type: PageStateType.Loading, title: '正在准备订单', description: '正在读取可用地址。' })
      } else if (this.error.length > 0 && this.addresses.length === 0) {
        PageStateView({ type: PageStateType.Error, title: '暂时无法准备订单', description: this.error, onAction: () => this.loadAddresses() })
      } else if (this.cart.selectedItems().length === 0) {
        PageStateView({ type: PageStateType.Empty, title: '还没有选择商品', description: '返回购物车勾选你想购买的商品。', actionLabel: '返回购物车', onAction: this.onBack })
      } else if (this.addresses.length === 0) {
        PageStateView({ type: PageStateType.Empty, title: '请先填写收货地址', description: '订单提交前需要一个有效地址。', actionLabel: '管理地址', onAction: this.onOpenAddresses })
      } else {
        Scroll() {
          Column({ space: AppSpacing.ITEM }) {
            Row() { Text('收货地址').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY); Blank(); Text(`${this.addresses.length} 个可用地址`).fontSize(11).fontColor(AppColors.TEXT_TERTIARY) }.width('100%')
            ForEach(this.addresses, (address: Address) => {
              Row({ space: 10 }) {
                Radio({ value: address.id.toString(), group: 'checkout-address' }).checked(this.selectedAddressId === address.id).onChange(() => this.selectedAddressId = address.id)
                  .width(22).height(22).margin({ left: 0, right: 4 })
                  .radioStyle({ checkedBackgroundColor: AppColors.BRAND, uncheckedBorderColor: AppColors.TEXT_SECONDARY, indicatorColor: AppColors.SURFACE })
                Column({ space: 5 }) {
                  Text(address.receiverName).fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY)
                  Text(address.receiverPhone).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
                  Text(`${address.province}${address.city}${address.district}${address.detailAddress}`).fontSize(12).lineHeight(18).fontColor(AppColors.TEXT_SECONDARY)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              }.width('100%').padding(AppSpacing.CARD).backgroundColor(this.selectedAddressId === address.id ? AppColors.BRAND_SOFT : AppColors.SURFACE)
                .border({ width: 1, color: this.selectedAddressId === address.id ? AppColors.BRAND : AppColors.DIVIDER })
                .borderRadius(AppRadius.CARD).stateStyles({ pressed: { opacity: 0.72 } }).enabled(!this.submitting && !this.uncertain)
                .onClick(() => this.selectedAddressId = address.id)
            }, (address: Address) => address.id.toString())
            Button('管理收货地址 ›', { type: ButtonType.Normal }).width('100%').height(44).fontSize(13)
              .backgroundColor(Color.Transparent).fontColor(AppColors.BRAND).borderRadius(AppRadius.CONTROL)
              .enabled(!this.submitting && !this.uncertain).onClick(this.onOpenAddresses)
            Text('已选商品').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.TEXT_PRIMARY).width('100%').margin({ top: 6 })
            ForEach(this.cart.selectedItems(), (item: CartItem) => {
              Row({ space: 12 }) {
                Image(ProductArtwork.resolve(item.productId)).width(52).height(60).objectFit(ImageFit.Cover).borderRadius(10)
                Column({ space: 5 }) { Text(item.productName).fontSize(14).fontColor(AppColors.TEXT_PRIMARY); Text(`${item.skuName} × ${item.quantity}`).fontSize(12).fontColor(AppColors.TEXT_SECONDARY) }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text(`¥ ${Money.format(Money.cents(item.salePrice) * item.quantity)}`).fontSize(14).fontColor(AppColors.TEXT_PRIMARY)
              }.width('100%').padding(AppSpacing.CARD).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD).border({ width: 1, color: AppColors.DIVIDER })
            }, (item: CartItem) => item.id.toString())
            Column({ space: 12 }) {
              Row() {
                Text(`共 ${this.cart.selectedCount()} 件商品`).fontSize(13).fontColor(AppColors.TEXT_SECONDARY)
                Blank()
                Text(`¥ ${this.cart.selectedSubtotal()}`).fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
              }.width('100%')
              Text('以上为预估金额，最终金额以订单提交结果为准。').fontSize(12).lineHeight(20).fontColor(AppColors.TEXT_SECONDARY)
            }.width('100%').padding(16).alignItems(HorizontalAlign.Start).backgroundColor(AppColors.SAND).borderRadius(AppRadius.CARD)
            if (this.error.length > 0) { Text(this.error).fontSize(12).lineHeight(19).fontColor(AppColors.DANGER).width('100%') }
          }.width('100%').padding({ bottom: 20 })
        }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
        Button(this.submitting ? '正在确认订单…' : this.uncertain ? '确认提交结果' : `提交订单 · ¥ ${this.cart.selectedSubtotal()}`).width('100%').height(50).backgroundColor(AppColors.BRAND).fontColor('#FFFFFF').borderRadius(AppRadius.CONTROL).enabled(!this.submitting && this.cart.selectedItems().length > 0).onClick(() => this.submit())
      }
      Blank().height(16)
    }.width('100%').height('100%').constraintSize({ maxWidth: AppSpacing.CONTENT_MAX }).alignSelf(ItemAlign.Center)
      .padding({ left: AppSpacing.PAGE_HORIZONTAL, right: AppSpacing.PAGE_HORIZONTAL, top: 12 }).backgroundColor(AppColors.BACKGROUND)
  }
}
