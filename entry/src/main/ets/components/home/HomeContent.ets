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
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.search(), 250)
  }
  private async search(): Promise<void> {
    clearTimeout(this.timer)
    const serial = ++this.requestSerial
    this.loading = true
    this.failed = false
    try {
      const products = await this.repository.searchProducts(this.keyword)
      if (this.alive && serial === this.requestSerial) { this.products = products }
    } catch (_) {
      if (this.alive && serial === this.requestSerial) { this.failed = true }
    } finally {
      if (this.alive && serial === this.requestSerial) { this.loading = false }
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
      Column({ space: 24 }) {
        Row() {
          Text('SHIGUANG MARKET / 2026').fontSize(10).letterSpacing(1.2).fontColor(BrowseTheme.OLIVE)
          Blank()
          Text('今日选物').fontSize(10).fontColor(BrowseTheme.MUTED)
        }.width('100%')
        Row({ space: 12 }) {
          Text('发现好物，\n从这里开始。').fontSize(32).lineHeight(43).fontWeight(FontWeight.Medium)
          .fontColor(BrowseTheme.INK).width('100%')
          Text('01').fontSize(12).fontColor(BrowseTheme.OLIVE).margin({ top: 8 })
        }.width('100%').alignItems(VerticalAlign.Top)
        Search({ value: this.keyword, placeholder: '搜索商品或店铺' }).height(48)
          .textFont({ size: 14 }).placeholderFont({ size: 14 }).placeholderColor(BrowseTheme.MUTED)
          .backgroundColor(BrowseTheme.WASH).borderRadius(8)
          .onChange((value: string) => this.onKeyword(value)).onSubmit(() => this.search())
        if (this.keyword.trim().length === 0) {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 18 }) {
              Column({ space: 12 }) {
                Text('从一家好店开始').fontSize(23).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.PAPER)
                Text('看见商品，也发现值得常来的店铺。').fontSize(12).lineHeight(20).fontColor('#D2D5C9')
                Text('打开店铺目录  ↗').fontSize(13).fontColor(BrowseTheme.PAPER).margin({ top: 6 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('逛\n店').fontSize(22).lineHeight(32).fontColor('#D2D5C9')
            }.width('100%').padding(22)
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
          Text('商品图片为示意图 · 当前为演示商品').fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
        }
      }.width('100%').constraintSize({ maxWidth: 640 }).padding({ left: 4, right: 4, top: 22, bottom: 108 })
    }.width('100%').height('100%').scrollBar(BarState.Off).backgroundColor(BrowseTheme.PAPER)
  }
}
