import { ProductDetail, ProductSku } from '../model/ProductModels'
import { BrowseRepository } from '../repository/BrowseRepository'
import { BrowseConfig, BrowseSource } from '../config/BrowseConfig'
import { CartViewModel } from '../viewmodel/CartViewModel'
import { BrowseTheme } from '../theme/BrowseTheme'
import { ProductArtwork } from '../theme/ProductArtwork'
import { AppColors, AppRadius, AppSpacing } from '../theme/AppTheme'
import { QuantityStepper } from '../components/common/QuantityStepper'
import { PageStateType, PageStateView } from '../components/common/PageStateView'

@Component
export struct ProductDetailPage {
  @Prop storeId: number = 0
  @Prop productId: number = 0
  @Prop initialSkuId: number = 0
  @ObjectLink cart: CartViewModel
  @Prop signedIn: boolean = false
  onLogin: () => void = () => {}
  onBack: () => void = () => {}
  onOpenStore: (storeId: number) => void = () => {}
  onOpenCart: () => void = () => {}
  @State detail: ProductDetail = { id: 0, name: '', description: '', updatedAt: '', skus: [] }
  @State storeName: string = ''
  @State selectedSkuId: number = 0
  @State quantity: number = 1
  @State loading: boolean = true
  @State error: string = ''
  @State feedback: string = ''
  @State success: boolean = false
  @State showSku: boolean = false
  private repository: BrowseRepository = new BrowseRepository()
  private alive: boolean = false

  aboutToAppear(): void { this.alive = true; this.load() }
  aboutToDisappear(): void { this.alive = false }

  private async load(): Promise<void> {
    this.loading = true
    this.error = ''
    try {
      const detail = await this.repository.getProduct(this.storeId, this.productId)
      const store = await this.repository.getStore(this.storeId)
      if (!this.alive) { return }
      this.detail = detail
      this.storeName = store.name
      const requested = detail.skus.find((sku: ProductSku) => sku.id === this.initialSkuId && sku.availableStock > 0)
      const available = requested === undefined ? detail.skus.find((sku: ProductSku) => sku.availableStock > 0) : requested
      this.selectedSkuId = available === undefined ? 0 : available.id
      this.quantity = 1
    } catch (error) {
      if (this.alive) { this.error = (error as Error).message || '商品加载失败，请重试' }
    } finally {
      if (this.alive) { this.loading = false }
    }
  }

  private selectedSku(): ProductSku | undefined {
    return this.detail.skus.find((sku: ProductSku) => sku.id === this.selectedSkuId)
  }
  private price(): string {
    const sku = this.selectedSku()
    if (sku !== undefined) { return sku.salePrice.toFixed(2) }
    if (this.detail.skus.length === 0) { return '—' }
    return Math.min(...this.detail.skus.map((item: ProductSku) => item.salePrice)).toFixed(2)
  }
  private stock(): number { return this.selectedSku()?.availableStock ?? 0 }
  private canBuy(): boolean { return this.stock() > 0 && !this.cart.busy }
  private selectSku(sku: ProductSku): void {
    if (sku.availableStock === 0 || this.cart.busy) { return }
    this.selectedSkuId = sku.id
    this.quantity = Math.min(this.quantity, sku.availableStock)
    this.feedback = ''
  }
  private async addToCart(): Promise<void> {
    if (!this.signedIn && BrowseConfig.source === BrowseSource.Remote) {
      this.showSku = false
      this.onLogin()
      return
    }
    const sku = this.selectedSku()
    if (sku === undefined || !this.canBuy()) { return }
    this.feedback = ''
    this.success = false
    const added = await this.cart.add(sku.id, this.quantity)
    if (!this.alive) { return }
    this.success = added
    if (!added && this.cart.authRequired) { this.showSku = false; this.onLogin() }
    this.feedback = added ? `已加入购物车 · ${sku.skuName} × ${this.quantity}` : this.cart.error
    if (added) {
      this.showSku = false
      try { this.getUIContext().getPromptAction().showToast({ message: '已加入购物车', duration: 1800 }) }
      catch (_) { /* 页面反馈仍然显示加购结果。 */ }
    }
  }

  @Builder
  skuPicker() {
    Column({ space: 18 }) {
      Row({ space: 16 }) {
        Image(ProductArtwork.resolve(this.productId)).width(76).height(76).objectFit(ImageFit.Cover).borderRadius(AppRadius.CONTROL)
        Column({ space: 7 }) {
          Text(`¥ ${this.price()}`).fontSize(27).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
          Text(this.stock() > 0 ? `库存 ${this.stock()} 件` : '暂无可购规格').fontSize(12).fontColor(BrowseTheme.MUTED)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      }.width('100%')
      Scroll() {
        Column({ space: 18 }) {
          Text('选择规格').fontSize(15).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.detail.skus, (sku: ProductSku) => {
              Button(`${sku.skuName}${sku.availableStock === 0 ? ' · 售罄' : ''}`, { type: ButtonType.Normal })
                .fontSize(13).height(44).padding({ left: 14, right: 14 })
                .backgroundColor(this.selectedSkuId === sku.id ? BrowseTheme.WASH : AppColors.SURFACE)
                .fontColor(BrowseTheme.INK)
                .border({ width: 1, color: this.selectedSkuId === sku.id ? BrowseTheme.INK : BrowseTheme.LINE })
                .borderRadius(AppRadius.CONTROL).margin({ right: 8, bottom: 10 })
                .enabled(sku.availableStock > 0 && !this.cart.busy)
                .onClick(() => this.selectSku(sku))
            }, (sku: ProductSku) => sku.id.toString())
          }.width('100%')
          Row() {
            Column({ space: 5 }) {
              Text('购买数量').fontSize(15).fontColor(BrowseTheme.INK)
              Text(this.stock() > 0 ? `最多 ${this.stock()} 件` : '暂时售罄').fontSize(11).fontColor(BrowseTheme.MUTED)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            QuantityStepper({ value: this.quantity, maximum: this.stock(), disabled: !this.canBuy(),
              onChange: (value: number) => { this.quantity = value; this.feedback = '' } })
          }.width('100%')
        }.width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      Button(this.cart.busy ? '正在加入…' : '选好了，加入购物车', { type: ButtonType.Normal }).width('100%').height(48).borderRadius(AppRadius.CONTROL)
        .backgroundColor(BrowseTheme.INK).fontColor(BrowseTheme.PAPER)
        .enabled(this.canBuy()).onClick(() => this.addToCart())
    }.width('100%').height('100%').padding({ left: 22, right: 22, bottom: 24 })
  }

  @Builder
  informationRow(label: string, value: string) {
    Row({ space: 16 }) {
      Text(label).width(64).fontSize(12).fontColor(BrowseTheme.MUTED)
      Text(value).layoutWeight(1).fontSize(13).lineHeight(21).fontColor(BrowseTheme.INK)
    }.width('100%').alignItems(VerticalAlign.Top)
  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Normal }) {
          Image($r('app.media.icon_back')).width(22).height(22)
        }.width(44).height(44).padding(0).borderRadius(AppRadius.CONTROL)
          .backgroundColor(Color.Transparent).onClick(this.onBack).accessibilityText('返回')
        Text('商品详情').layoutWeight(1).textAlign(TextAlign.Center).fontSize(16).fontColor(BrowseTheme.INK)
        Text('选物').width(44).textAlign(TextAlign.Center).fontSize(11).fontColor(BrowseTheme.OLIVE)
      }.width('100%').padding({ left: 8, right: 8 })
      if (this.loading) {
        Column() { PageStateView({ type: PageStateType.Loading, title: '正在打开商品', description: '稍等片刻。' }) }
          .layoutWeight(1).width('100%').padding(20)
      } else if (this.error.length > 0) {
        Column() { PageStateView({ type: PageStateType.Error, title: '暂时无法打开商品', description: this.error, onAction: () => this.load() }) }
          .layoutWeight(1).width('100%').padding(20)
      } else {
        Scroll() {
          Column({ space: 22 }) {
            Stack({ alignContent: Alignment.BottomStart }) {
              Image(ProductArtwork.resolve(this.productId)).width('100%').aspectRatio(1.15).objectFit(ImageFit.Cover)
              Text('商品示意图').fontSize(10).fontColor(BrowseTheme.MUTED)
                .padding({ left: 9, right: 9, top: 5, bottom: 5 }).backgroundColor(BrowseTheme.PAPER).margin(14)
            }.width('100%').borderRadius(AppRadius.CARD).clip(true)
            Column({ space: 12 }) {
              Row({ space: 6 }) {
                Text('¥').fontSize(16).fontColor(AppColors.ACCENT)
                Text(this.price()).fontSize(32).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
                Blank()
                Text(this.stock() > 0 ? '有货' : '暂时售罄').fontSize(12).fontColor(BrowseTheme.OLIVE)
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor(BrowseTheme.WASH).borderRadius(12)
              }.width('100%').alignItems(VerticalAlign.Bottom)
              Text(this.detail.name).fontSize(24).lineHeight(34).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
            }.width('100%').alignItems(HorizontalAlign.Start)
            Button({ type: ButtonType.Normal }) {
              Row({ space: 14 }) {
                Text('已选').fontSize(12).fontColor(BrowseTheme.MUTED)
                Text(this.selectedSku() === undefined ? '暂无可购规格' : `${this.selectedSku()?.skuName} / ${this.quantity} 件`)
                  .fontSize(14).fontColor(BrowseTheme.INK).layoutWeight(1).maxLines(2)
                Text('›').fontSize(24).fontColor(BrowseTheme.INK)
              }.width('100%').padding(16)
            }.width('100%').padding(0).backgroundColor(AppColors.SURFACE)
              .border({ width: 1, color: BrowseTheme.LINE })
              .borderRadius(AppRadius.CARD)
              .onClick(() => this.showSku = true)
            Button({ type: ButtonType.Normal }) {
              Row({ space: 14 }) {
                Image($r('app.media.nav_store')).width(44).height(44).padding(11)
                  .backgroundColor(BrowseTheme.WASH).borderRadius(AppRadius.CONTROL)
                Column({ space: 5 }) {
                  Text(this.storeName).fontSize(16).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
                  Text('查看店内全部商品').fontSize(12).fontColor(BrowseTheme.MUTED)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text('进店 ›').fontSize(12).fontColor(BrowseTheme.OLIVE)
              }.width('100%').padding({ top: 10, bottom: 10 })
            }.width('100%').padding(0).backgroundColor(Color.Transparent).onClick(() => this.onOpenStore(this.storeId))
            Divider().color(BrowseTheme.LINE)
            Column({ space: 16 }) {
              Text('关于这件好物').fontSize(20).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
              this.informationRow('商品名称', this.detail.name)
              this.informationRow('规格选项', this.detail.skus.map((sku: ProductSku) => sku.skuName).join(' / '))
              this.informationRow('当前库存', this.selectedSku() === undefined ? '暂无可购规格' : `${this.stock()} 件，以所选规格为准`)
              this.informationRow('商品说明', this.detail.description)
            }.width('100%').alignItems(HorizontalAlign.Start)
            Text('商品图片为示意图，价格与库存以当前页面结果为准。').fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
          }.width('100%').constraintSize({ maxWidth: AppSpacing.CONTENT_MAX }).padding({ left: 20, right: 20, top: 8, bottom: 28 })
        }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
        if (this.feedback.length > 0) {
          Text(this.feedback).fontSize(12).lineHeight(19).fontColor(this.success ? BrowseTheme.OLIVE : '#99442E')
            .width('100%').padding({ left: 20, right: 20, top: 10, bottom: 10 }).backgroundColor(BrowseTheme.WASH)
        }
        Row({ space: 12 }) {
          Button(`购物车 ${this.cart.count() > 0 ? this.cart.count() : ''}`, { type: ButtonType.Normal })
            .fontSize(13).fontColor(BrowseTheme.INK).backgroundColor(BrowseTheme.WASH)
            .width(102).height(50).borderRadius(BrowseTheme.RADIUS).onClick(this.onOpenCart)
          Button(this.cart.busy ? '正在加入…' : this.stock() === 0 ? '暂时售罄' : '加入购物车', { type: ButtonType.Normal })
            .layoutWeight(1).height(50).fontSize(16).fontColor(BrowseTheme.PAPER).backgroundColor(BrowseTheme.INK)
            .borderRadius(BrowseTheme.RADIUS).enabled(this.canBuy()).onClick(() => this.addToCart())
        }.width('100%').padding({ left: 20, right: 20, top: 12, bottom: 16 }).backgroundColor(AppColors.SURFACE)
          .border({ width: { top: 1 }, color: BrowseTheme.LINE })
      }
    }.width('100%').height('100%').backgroundColor(BrowseTheme.PAPER)
      .bindSheet($$this.showSku, this.skuPicker(), {
        height: SheetSize.MEDIUM, showClose: true,
        title: { title: '选择规格与数量' }, backgroundColor: BrowseTheme.PAPER
      })
  }
}
