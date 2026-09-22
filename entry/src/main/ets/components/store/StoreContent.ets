import { ProductSummary, StoreSummary } from '../../model/StoreModels'
import { BrowseRepository } from '../../repository/BrowseRepository'
import { BrowseProductCard } from '../product/BrowseProductCard'
import { PageStateType, PageStateView } from '../common/PageStateView'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { ProductArtwork } from '../../theme/ProductArtwork'
import { AppColors } from '../../theme/AppTheme'

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
  @State loadingMore: boolean = false
  @State moreFailed: boolean = false
  @State hasMore: boolean = false
  private page: number = 1
  onOpenProduct: (storeId: number, productId: number) => void = () => {}

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
    this.loadingMore = false
    this.moreFailed = false
    this.page = 1
    try {
      const products = await this.repository.getProducts(storeId)
      // 快速切店时，只接受最后一次选择的结果。
      if (this.alive && serial === this.requestSerial) { this.products = products; this.hasMore = products.length === 20 }
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

  private async loadMore(): Promise<void> {
    if (this.loadingProducts || this.loadingMore || !this.hasMore) { return }
    const serial = this.requestSerial
    const next = this.page + 1
    this.loadingMore = true
    this.moreFailed = false
    try {
      const items = await this.repository.getProducts(this.activeStoreId, next)
      if (!this.alive || serial !== this.requestSerial) { return }
      this.products = this.products.concat(items.filter((item: ProductSummary) =>
        !this.products.some((old: ProductSummary) => old.id === item.id)))
      this.page = next
      this.hasMore = items.length === 20
    } catch (_) {
      if (this.alive && serial === this.requestSerial) { this.moreFailed = true }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loadingMore = false }
    }
  }

  private storeName(): string {
    const store = this.stores.find((item: StoreSummary) => item.id === this.activeStoreId)
    return store === undefined ? '' : store.name
  }

  @Builder
  productCell(product: ProductSummary, index: number) {
    Column() {
      BrowseProductCard({
        product: product,
        artwork: ProductArtwork.resolve(product.id),
        sequence: `${index + 1}`.padStart(2, '0'),
        onOpen: (productId: number) => this.onOpenProduct(this.activeStoreId, productId)
      })
    }.layoutWeight(1).alignSelf(ItemAlign.Start)
  }

  build() {
    Scroll() {
      Column({ space: 22 }) {
        Column({ space: 12 }) {
          Row() {
            Text('拾光集 / 店铺目录').fontSize(11).fontColor(BrowseTheme.OLIVE).letterSpacing(1)
            Blank()
            Image($r('app.media.nav_store')).width(22).height(22).opacity(0.65)
          }.width('100%')
          Row({ space: 12 }) {
            Column({ space: 8 }) {
              Text('发现值得常来的小店').fontSize(26).lineHeight(36)
                .fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
                .lineBreakStrategy(LineBreakStrategy.BALANCED)
              Text('慢一点逛，发现值得留下的好物。').fontSize(12).fontColor(BrowseTheme.MUTED)
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          }.width('100%')
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
                    Column({ space: 12 }) {
                      Row() {
                        Text(`${index + 1}`.padStart(2, '0')).fontSize(11)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                        Blank()
                        Text(this.activeStoreId === store.id ? '正在逛' : '去逛 ↗').fontSize(11)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                      }.width('100%')
                      Column({ space: 6 }) {
                        Text(store.name).fontSize(15).lineHeight(22).fontWeight(FontWeight.Medium).maxLines(2)
                          .constraintSize({ minHeight: '44fp' }).textOverflow({ overflow: TextOverflow.Ellipsis })
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.INK)
                        Text(`${store.productCount} 件商品`).fontSize(11)
                          .fontColor(this.activeStoreId === store.id ? BrowseTheme.PAPER : BrowseTheme.MUTED)
                      }.width('100%').alignItems(HorizontalAlign.Start)
                    }.width(152).padding(16).alignItems(HorizontalAlign.Start)
                  }.backgroundColor(this.activeStoreId === store.id ? BrowseTheme.INK : AppColors.SURFACE)
                    .border({ width: 1, color: this.activeStoreId === store.id ? BrowseTheme.INK : BrowseTheme.LINE })
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
                Text('店内好物').fontSize(11).fontColor(BrowseTheme.OLIVE)
                Text(this.storeName()).fontSize(21).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              if (!this.loadingProducts && !this.productError) {
                Text(`${this.products.length} 件${this.hasMore ? '+' : ''}`).fontSize(12).fontColor(BrowseTheme.MUTED)
              }
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
              }.width('100%').alignItems(HorizontalAlign.Start).padding(24).backgroundColor(BrowseTheme.WASH).borderRadius(BrowseTheme.RADIUS)
            } else {
              ForEach(this.products, (product: ProductSummary, index: number) => {
                if (index % 2 === 0) {
                  Row({ space: 12 }) {
                    this.productCell(product, index)
                    if (index + 1 < this.products.length) {
                      this.productCell(this.products[index + 1], index + 1)
                    } else {
                      Column().layoutWeight(1)
                    }
                  }.width('100%').alignItems(VerticalAlign.Top)
                }
              }, (product: ProductSummary) => `${product.id}`)
              if (this.hasMore) {
                Button(this.loadingMore ? '正在加载…' : this.moreFailed ? '加载失败，点击重试' : '加载更多商品', { type: ButtonType.Normal })
                  .width('100%').height(44).backgroundColor(BrowseTheme.WASH).fontColor(BrowseTheme.INK).borderRadius(12)
                  .enabled(!this.loadingMore).onClick(() => this.loadMore())
              }
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
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(BrowseTheme.PAPER)

  }
}
