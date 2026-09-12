import { ProductSummary, StoreSummary } from '../../model/StoreModels'
import { BrowseRepository } from '../../repository/BrowseRepository'
import { BrowseProductCard } from '../product/BrowseProductCard'
import { PageStateType, PageStateView } from '../common/PageStateView'
import { BrowseTheme } from '../../theme/BrowseTheme'

@Component
export struct StoreContent {
  @Prop selectedStoreId: number = 1001
  onSelectStore: (storeId: number) => void = () => {}
  @State stores: StoreSummary[] = []
  @State products: ProductSummary[] = []
  @State activeStoreId: number = 1001
  @State loadingStores: boolean = true
  @State loadingProducts: boolean = false
  @State storeError: boolean = false
  @State productError: boolean = false
  @State showOverview: boolean = false
  @State overview: ProductSummary | undefined = undefined
  private repository: BrowseRepository = new BrowseRepository()
  private requestSerial: number = 0
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    this.activeStoreId = this.selectedStoreId
    this.loadStores()
  }

  aboutToDisappear(): void {
    this.alive = false
    this.requestSerial++
  }

  private async loadStores(): Promise<void> {
    this.loadingStores = true
    this.storeError = false
    try {
      const stores = await this.repository.getStores()
      if (!this.alive) { return }
      this.stores = stores
      if (stores.length > 0) {
        const selected = stores.find((store: StoreSummary) => store.id === this.activeStoreId)
        this.activeStoreId = selected === undefined ? stores[0].id : selected.id
        this.onSelectStore(this.activeStoreId)
        this.loadProducts(this.activeStoreId)
      }
    } catch (_) {
      if (this.alive) { this.storeError = true }
    } finally {
      if (this.alive) { this.loadingStores = false }
    }
  }

  private async loadProducts(storeId: number): Promise<void> {
    const serial = ++this.requestSerial
    this.products = []
    this.loadingProducts = true
    this.productError = false
    try {
      const products = await this.repository.getProducts(storeId)
      // 快速切店时，只接受最后一次选择的结果。
      if (this.alive && serial === this.requestSerial) { this.products = products }
    } catch (_) {
      if (this.alive && serial === this.requestSerial) { this.productError = true }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loadingProducts = false }
    }
  }

  private selectStore(storeId: number): void {
    if (this.activeStoreId === storeId) { return }
    this.activeStoreId = storeId
    this.onSelectStore(storeId)
    this.loadProducts(storeId)
  }

  private storeName(): string {
    const store = this.stores.find((item: StoreSummary) => item.id === this.activeStoreId)
    return store === undefined ? '' : store.name
  }

  private artwork(productId: number): Resource {
    if (productId === 2002) { return $r('app.media.browse_glass') }
    if (productId === 2003) { return $r('app.media.browse_scent') }
    if (productId >= 2100) { return $r('app.media.browse_coffee') }
    return $r('app.media.browse_tea')
  }

  private openOverview(productId: number): void {
    this.overview = this.products.find((item: ProductSummary) => item.id === productId)
    this.showOverview = this.overview !== undefined
  }

  @Builder
  overviewSheet() {
    Scroll() {
    Column({ space: 16 }) {
      if (this.overview !== undefined) {
        Image(this.artwork(this.overview.id)).width('100%').height(220).objectFit(ImageFit.Contain)
        Text(this.overview.name).fontSize(25).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
        Text(this.overview.description).fontSize(15).lineHeight(24).fontColor(BrowseTheme.MUTED)
        Text(`¥ ${this.overview.minSalePrice.toFixed(2)} 起`).fontSize(26).fontColor(BrowseTheme.INK)
        Text(this.overview.totalAvailableStock > 0 ? `可用库存 ${this.overview.totalAvailableStock} 件` : '暂时售罄')
          .fontSize(14).fontColor(BrowseTheme.OLIVE)
        Text('演示商品 · 图片为示意图').fontSize(12).fontColor(BrowseTheme.MUTED)
      }
    }.width('100%').alignItems(HorizontalAlign.Start).padding({ left: 24, right: 24, bottom: 24 })
    }.width('100%').height('100%').scrollBar(BarState.Off)
  }

  @Builder
  productCell(product: ProductSummary, index: number) {
    Column() {
      BrowseProductCard({
        product: product,
        artwork: this.artwork(product.id),
        sequence: `${index + 1}`.padStart(2, '0'),
        onOpen: (productId: number) => this.openOverview(productId)
      })
    }.layoutWeight(1).alignSelf(ItemAlign.Start)
  }

  build() {
    Scroll() {
      Column({ space: 26 }) {
        Column({ space: 18 }) {
          Row() {
            Text('日常选物 / 店铺目录').fontSize(11).fontColor(BrowseTheme.OLIVE).letterSpacing(1)
            Blank()
            Text('本地演示').fontSize(10).fontColor(BrowseTheme.MUTED)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 }).border({ width: 1, color: BrowseTheme.LINE })
          }.width('100%')
          Row({ space: 12 }) {
            Column({ space: 8 }) {
              Text('把日常，\n过成喜欢的样子').fontSize(28).lineHeight(40)
                .fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
              Text('慢一点逛，发现值得留下的好物。').fontSize(12).fontColor(BrowseTheme.MUTED)
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Text('选\n物').fontSize(19).lineHeight(28).fontColor(BrowseTheme.OLIVE)
              .padding({ left: 11, right: 11, top: 15, bottom: 15 })
              .border({ width: 1, color: BrowseTheme.OLIVE }).borderRadius(28).rotate({ angle: 8 })
          }.width('100%')
          Divider().color(BrowseTheme.INK).strokeWidth(1)
        }.width('100%').alignItems(HorizontalAlign.Start)

        if (this.loadingStores) {
          PageStateView({ type: PageStateType.Loading, title: '正在打开店铺目录', description: '好物，稍候就来。' })
        } else if (this.storeError) {
          PageStateView({ type: PageStateType.Error, title: '店铺暂时没有加载出来', description: '再试一次，继续逛逛。', onAction: () => this.loadStores() })
        } else if (this.stores.length === 0) {
          PageStateView({ type: PageStateType.Empty, title: '店铺正在准备中', description: '等小店开门，再来发现日常好物。' })
        } else {
          Column({ space: 14 }) {
            Row() {
              Text('从一家小店开始').fontSize(14).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
              Blank()
              Text(`${this.stores.length} 家店铺`).fontSize(11).fontColor(BrowseTheme.MUTED)
            }.width('100%')
            Scroll() {
              Row({ space: 10 }) {
                ForEach(this.stores, (store: StoreSummary, index: number) => {
                  Button({ type: ButtonType.Normal }) {
                    Column({ space: 14 }) {
                      Row() {
                        Text(`0${index + 1}`).fontSize(12)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                        Blank()
                        Text(this.activeStoreId === store.id ? '正在逛' : '去逛 ↗').fontSize(11)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                      }.width('100%')
                      Column({ space: 6 }) {
                        Text(store.name).fontSize(16).fontWeight(FontWeight.Medium).maxLines(2)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                        Text(`${store.productCount} 件商品`).fontSize(11)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.MUTED)
                      }.width('100%').alignItems(HorizontalAlign.Start)
                    }.width(170).padding(16).alignItems(HorizontalAlign.Start)
                  }.backgroundColor(this.activeStoreId === store.id ? BrowseTheme.INK : BrowseTheme.WASH)
                    .padding(0)
                    .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                    .borderRadius(BrowseTheme.RADIUS)
                    .onClick(() => this.selectStore(store.id))
                    .accessibilityText(`${store.name}，${store.productCount}件商品，${this.activeStoreId === store.id ? '已选择' : '点击切换'}`)
                }, (store: StoreSummary) => `${store.id}`)
              }.alignItems(VerticalAlign.Top)
            }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
          }.width('100%')

          Column({ space: 18 }) {
            Row({ space: 12 }) {
              Column({ space: 6 }) {
                Text('店 内 选 物').fontSize(10).fontColor(BrowseTheme.OLIVE)
                Text(this.storeName()).fontSize(23).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('↓').fontSize(24).fontColor(BrowseTheme.OLIVE)
            }.width('100%')
            if (this.loadingProducts) {
              PageStateView({ type: PageStateType.Loading, title: '正在整理本店好物', description: '稍等片刻。' })
            } else if (this.productError) {
              PageStateView({ type: PageStateType.Error, title: '商品加载失败', description: '你可以重试，或换一家店逛逛。', onAction: () => this.loadProducts(this.activeStoreId) })
            } else if (this.products.length === 0) {
              Column({ space: 14 }) {
                Text('好物，还在路上。').fontSize(24).fontColor(BrowseTheme.INK)
                Text('本店暂无商品\n先去隔壁小店看看，也许有新的发现。').fontSize(13).lineHeight(23).fontColor(BrowseTheme.MUTED)
                Button('逛逛其他店铺', { type: ButtonType.Normal }).fontSize(13)
                  .fontColor(BrowseTheme.PAPER).backgroundColor(BrowseTheme.INK).borderRadius(BrowseTheme.RADIUS)
                  .height(44).onClick(() => {
                    const other = this.stores.find((store: StoreSummary) => store.id !== this.activeStoreId)
                    if (other !== undefined) { this.selectStore(other.id) }
                  })
              }.width('100%').alignItems(HorizontalAlign.Start).padding(24).backgroundColor(BrowseTheme.WASH)
            } else {
              ForEach(this.products, (product: ProductSummary, index: number) => {
                if (index % 2 === 0) {
                  Row({ space: 14 }) {
                    this.productCell(product, index)
                    if (index + 1 < this.products.length) {
                      this.productCell(this.products[index + 1], index + 1)
                    } else {
                      Column().layoutWeight(1)
                    }
                  }.width('100%').alignItems(VerticalAlign.Top)
                }
              }, (product: ProductSummary) => `${product.id}`)
              Row() {
                Divider().layoutWeight(1).color(BrowseTheme.LINE)
                Text(`${this.products.length} 件选物 · 商品图片为示意图`).fontSize(10)
                  .fontColor(BrowseTheme.MUTED).margin({ left: 12, right: 12 })
                Divider().layoutWeight(1).color(BrowseTheme.LINE)
              }.width('100%').margin({ top: 8 })
            }
          }.width('100%')
        }
      }.width('100%').constraintSize({ maxWidth: 640 })
        .padding({ left: 4, right: 4, top: 20, bottom: BrowseTheme.BOTTOM_CLEARANCE })
    }.width('100%').height('100%').scrollBar(BarState.Off).backgroundColor(BrowseTheme.PAPER)
      .bindSheet($$this.showOverview, this.overviewSheet(), {
        height: SheetSize.LARGE,
        showClose: true,
        title: { title: '商品概览', subtitle: '浏览演示' },
        backgroundColor: BrowseTheme.PAPER
      })
  }
}
