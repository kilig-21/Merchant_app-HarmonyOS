import { DiscoveryProduct } from '../../model/ProductModels'
import { BrowseRepository } from '../../repository/BrowseRepository'
import { BrowseProductCard } from '../product/BrowseProductCard'
import { PageStateType, PageStateView } from '../common/PageStateView'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { ProductArtwork } from '../../theme/ProductArtwork'

@Component
export struct HomeContent {
  @Prop initialQuery: string = ''
  @Prop cartCount: number = 0
  onNavigate: (index: number) => void = () => {}
  onOpenProduct: (storeId: number, productId: number) => void = () => {}
  onQueryChange: (keyword: string) => void = () => {}
  @State keyword: string = ''
  @State products: DiscoveryProduct[] = []
  @State loading: boolean = true
  @State failed: boolean = false
  @State loadingMore: boolean = false
  @State moreFailed: boolean = false
  @State hasMore: boolean = false
  private page: number = 1
  private repository: BrowseRepository = new BrowseRepository()
  private requestSerial: number = 0
  private timer: number = -1
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    this.keyword = this.initialQuery
    this.search()
  }
  aboutToDisappear(): void {
    this.alive = false
    this.requestSerial++
    clearTimeout(this.timer)
  }
  private onKeyword(value: string): void {
    this.keyword = value
    this.onQueryChange(value)
    this.requestSerial++
    this.loading = true
    this.loadingMore = false
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.search(), 250)
  }
  private async search(): Promise<void> {
    clearTimeout(this.timer)
    const serial = ++this.requestSerial
    this.loading = true
    this.failed = false
    this.loadingMore = false
    this.moreFailed = false
    this.page = 1
    try {
      const products = await this.repository.searchProducts(this.keyword)
      if (this.alive && serial === this.requestSerial) { this.products = products; this.hasMore = products.length === 20 }
    } catch (_) {
      if (this.alive && serial === this.requestSerial) { this.failed = true }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loading = false }
    }
  }

  private async loadMore(): Promise<void> {
    if (this.loading || this.loadingMore || !this.hasMore) { return }
    const serial = this.requestSerial
    const next = this.page + 1
    this.loadingMore = true
    this.moreFailed = false
    try {
      const items = await this.repository.searchProducts(this.keyword, next)
      if (!this.alive || serial !== this.requestSerial) { return }
      this.products = this.products.concat(items.filter((item: DiscoveryProduct) =>
        !this.products.some((old: DiscoveryProduct) => old.id === item.id && old.storeId === item.storeId)))
      this.page = next
      this.hasMore = items.length === 20
    } catch (_) {
      if (this.alive && serial === this.requestSerial) { this.moreFailed = true }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loadingMore = false }
    }
  }

  @Builder
  productCell(product: DiscoveryProduct, index: number) {
    Column({ space: 7 }) {
      BrowseProductCard({ product: product, artwork: ProductArtwork.resolve(product.id),
        sequence: `${index + 1}`.padStart(2, '0'),
        onOpen: (productId: number) => this.onOpenProduct(product.storeId, productId) })
      Text(product.storeName).fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
    }.layoutWeight(1).alignItems(HorizontalAlign.Start)
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Text('拾光集 / 日常好物').fontSize(12).letterSpacing(1).fontColor(BrowseTheme.OLIVE)
          Blank()
          Text('今日选物').fontSize(10).fontColor(BrowseTheme.MUTED)
        }.width('100%')
        Row({ space: 12 }) {
          Text('发现日常好物').fontSize(28).lineHeight(38).fontWeight(FontWeight.Medium)
          .fontColor(BrowseTheme.INK).layoutWeight(1)
        }.width('100%').alignItems(VerticalAlign.Top)
        Search({ value: this.keyword, placeholder: '搜索商品或店铺' }).height(48)
          .textFont({ size: 14 }).placeholderFont({ size: 14 }).placeholderColor(BrowseTheme.MUTED)
          .backgroundColor(BrowseTheme.WASH).borderRadius(8)
          .onChange((value: string) => this.onKeyword(value)).onSubmit(() => this.search())
        if (this.keyword.trim().length === 0) {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 18 }) {
              Column({ space: 8 }) {
                Text('从一家好店开始').fontSize(21).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.PAPER)
                Text('看见商品，也发现值得常来的店铺。').fontSize(12).lineHeight(20).fontColor('#D2D5C9')
                Text('打开店铺目录  ↗').fontSize(13).fontColor(BrowseTheme.PAPER).margin({ top: 6 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('逛\n店').fontSize(22).lineHeight(32).fontColor('#D2D5C9')
            }.width('100%').padding(18)
          }.width('100%').padding(0).backgroundColor(BrowseTheme.INK).borderRadius(BrowseTheme.RADIUS)
            .shadow({ radius: 18, color: '#2E24352C', offsetX: 0, offsetY: 7 }).onClick(() => this.onNavigate(1))
          Row({ space: 12 }) {
            Button({ type: ButtonType.Normal }) {
              Row() {
                Column({ space: 5 }) {
                  Text('购物车').fontSize(16).fontColor(BrowseTheme.INK)
                  Text(this.cartCount > 0 ? `${this.cartCount} 件好物待整理` : '把喜欢的，留在这里').fontSize(11).fontColor(BrowseTheme.MUTED)
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text('↗').fontSize(20).fontColor(BrowseTheme.OLIVE)
              }.padding(16).width('100%')
            }.layoutWeight(1).padding(0).backgroundColor(BrowseTheme.WASH).borderRadius(BrowseTheme.RADIUS).onClick(() => this.onNavigate(2))
            Button('我的 ›', { type: ButtonType.Normal }).width(88).height(72).padding(8).fontSize(14)
              .fontColor(BrowseTheme.INK).backgroundColor('#EFEBDF').borderRadius(BrowseTheme.RADIUS).onClick(() => this.onNavigate(3))
          }.width('100%')
        }
        Row() {
          Text(this.keyword.trim().length > 0 ? '搜索结果' : '慢慢挑选').fontSize(22).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
          Blank()
          if (!this.loading && !this.failed) {
            Text(`${this.products.length} 件商品`).fontSize(12).fontColor(BrowseTheme.MUTED)
          }
        }.width('100%')
        if (this.loading) {
          PageStateView({ type: PageStateType.Loading, title: '正在寻找好物', description: '' })
        } else if (this.failed) {
          PageStateView({ type: PageStateType.Error, title: '商品暂时没有加载出来', description: '再试一次。', onAction: () => this.search() })
        } else if (this.products.length === 0) {
          Column({ space: 14 }) {
            Text('还没有找到合适的商品').fontSize(18).fontColor(BrowseTheme.INK)
            Text('换个关键词，或去店铺里逛逛。').fontSize(13).fontColor(BrowseTheme.MUTED)
            Button('查看全部商品', { type: ButtonType.Normal }).height(44).fontColor(BrowseTheme.PAPER)
              .backgroundColor(BrowseTheme.INK).borderRadius(8).onClick(() => this.onKeyword(''))
          }.width('100%').alignItems(HorizontalAlign.Start).padding(22).backgroundColor(BrowseTheme.WASH)
        } else {
          ForEach(this.products, (product: DiscoveryProduct, index: number) => {
            if (index % 2 === 0) {
              Row({ space: 14 }) {
                this.productCell(product, index)
                if (index + 1 < this.products.length) {
                  this.productCell(this.products[index + 1], index + 1)
                } else { Column().layoutWeight(1) }
              }.width('100%').alignItems(VerticalAlign.Top)
            }
          }, (product: DiscoveryProduct) => `${product.storeId}-${product.id}`)
          if (this.hasMore) {
            Button(this.loadingMore ? '正在加载…' : this.moreFailed ? '加载失败，点击重试' : '加载更多商品', { type: ButtonType.Normal })
              .width('100%').height(44).backgroundColor(BrowseTheme.WASH).fontColor(BrowseTheme.INK).borderRadius(12)
              .enabled(!this.loadingMore).onClick(() => this.loadMore())
          }
          Text(this.hasMore ? '商品图片为示意图' : '已经到底了 · 商品图片为示意图').fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
        }
      }.width('100%').constraintSize({ maxWidth: 640 }).padding({ left: 4, right: 4, top: 12, bottom: 108 })
    }.width('100%').height('100%').scrollBar(BarState.Off).backgroundColor(BrowseTheme.PAPER)
  }
}
