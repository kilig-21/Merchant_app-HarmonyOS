import { DiscoveryProduct } from '../../model/ProductModels'
import { BrowseRepository } from '../../repository/BrowseRepository'
import { BrowseProductCard } from '../product/BrowseProductCard'
import { PageStateType, PageStateView } from '../common/PageStateView'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { ProductArtwork } from '../../theme/ProductArtwork'
import { AppColors, AppRadius, AppSpacing } from '../../theme/AppTheme'

@Component
export struct HomeContent {
  @Prop initialQuery: string = ''
  @Prop cartCount: number = 0
  onNavigate: (index: number) => void = () => {}
  onOpenPromotions: () => void = () => {}
  onOpenProduct: (storeId: number, productId: number) => void = () => {}
  onQueryChange: (keyword: string) => void = () => {}
  @State keyword: string = ''
  @State products: DiscoveryProduct[] = []
  @State loading: boolean = true
  @State failed: boolean = false
  @State loadingMore: boolean = false
  @State moreFailed: boolean = false
  @State hasMore: boolean = false
  @State productReveal: boolean = false
  @State sceneFloat: boolean = false
  private page: number = 1
  private repository: BrowseRepository = new BrowseRepository()
  private requestSerial: number = 0
  private timer: number = -1
  private revealTimer: number = -1
  private sceneTimer: number = -1
  private alive: boolean = false

  aboutToAppear(): void {
    this.alive = true
    this.keyword = this.initialQuery
    this.startSceneMotion()
    this.search()
  }
  aboutToDisappear(): void {
    this.alive = false
    this.requestSerial++
    clearTimeout(this.timer)
    clearTimeout(this.revealTimer)
    clearTimeout(this.sceneTimer)
  }

  private startSceneMotion(): void {
    this.sceneFloat = false
    this.sceneTimer = setTimeout(() => {
      if (!this.alive) { return }
      this.getUIContext().animateTo({ duration: 2600, curve: Curve.EaseInOut, iterations: 3, playMode: PlayMode.Alternate }, () => {
        this.sceneFloat = true
      })
    }, 180)
  }

  private revealProducts(): void {
    clearTimeout(this.revealTimer)
    this.productReveal = false
    this.revealTimer = setTimeout(() => {
      if (!this.alive) { return }
      this.getUIContext().animateTo({ duration: 520, curve: 'spring-motion(0.55,0.82,0)' }, () => {
        this.productReveal = true
      })
    }, 40)
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
      if (this.alive && serial === this.requestSerial) {
        this.products = products
        this.hasMore = products.length === 20
        this.revealProducts()
      }
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
    Column({ space: 0 }) {
      BrowseProductCard({ product: product, artwork: ProductArtwork.resolve(product.id),
        sequence: `${index + 1}`.padStart(2, '0'),
        onOpen: (productId: number) => this.onOpenProduct(product.storeId, productId) })
      Row({ space: 5 }) {
        Image($r('app.media.nav_store')).width(12).height(12).opacity(0.65)
        Text(product.storeName).fontSize(11).fontColor(BrowseTheme.MUTED).layoutWeight(1)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').padding({ left: 12, right: 12, top: 4, bottom: 12 })
    }.width('100%').alignItems(HorizontalAlign.Start)
      .backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD).clip(true)
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Row({ space: 9 }) {
          Text('拾').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppColors.SURFACE)
            .width(30).height(30).textAlign(TextAlign.Center).backgroundColor(BrowseTheme.INK).borderRadius(10)
          Text('拾光集').fontSize(17).fontWeight(FontWeight.Medium).letterSpacing(2).fontColor(BrowseTheme.INK)
          Blank()
          Text('日常好物，慢慢选').fontSize(11).fontColor(BrowseTheme.MUTED)
        }.width('100%')
        Search({ value: this.keyword, placeholder: '搜索商品或店铺' }).height(48)
          .textFont({ size: 14 }).placeholderFont({ size: 14 }).placeholderColor(BrowseTheme.MUTED)
          .backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CONTROL)
          .border({ width: 1, color: BrowseTheme.LINE })
          .onChange((value: string) => this.onKeyword(value)).onSubmit(() => this.search())
        if (this.keyword.trim().length === 0) {
          Button({ type: ButtonType.Normal }) {
            Row({ space: 4 }) {
              Column({ space: 8 }) {
                Text('把喜欢，带进日常').fontSize(22).lineHeight(30).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
                  .lineBreakStrategy(LineBreakStrategy.BALANCED)
                Text('发现好店与日常好物').fontSize(12).lineHeight(20).fontColor(BrowseTheme.MUTED)
                Text('去逛店  →').fontSize(13).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
                  .padding({ left: 12, right: 12, top: 7, bottom: 7 }).backgroundColor(AppColors.SURFACE).borderRadius(16)
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Image($r('app.media.scene_daily')).width('28%').aspectRatio(0.89).objectFit(ImageFit.Contain)
                .translate({ y: this.sceneFloat ? -6 : 2 }).scale({ x: this.sceneFloat ? 1.025 : 0.99, y: this.sceneFloat ? 1.025 : 0.99 })
                .accessibilityLevel('no')
            }.width('100%').padding(16).alignItems(VerticalAlign.Center)
          }.width('100%').padding(0).backgroundColor(AppColors.SAND).borderRadius(BrowseTheme.RADIUS)
            .onClick(() => this.onNavigate(1)).accessibilityText('从一家好店开始，打开店铺目录')
          Button({ type: ButtonType.Normal }) {
            Row({ space: 12 }) {
              Text('限').fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.SURFACE).width(30).height(30)
                .textAlign(TextAlign.Center).backgroundColor(AppColors.ACCENT).borderRadius(15)
              Column({ space: 3 }) {
                Text('限量活动').fontSize(14).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
                Text('跟随服务端时间，查看正在进行的精选。').fontSize(11).fontColor(BrowseTheme.MUTED)
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)
              Text('›').fontSize(20).fontColor(BrowseTheme.MUTED)
            }.width('100%').padding({ left: 14, right: 14, top: 10, bottom: 10 }).alignItems(VerticalAlign.Center)
          }.width('100%').padding(0).backgroundColor(AppColors.SURFACE).borderRadius(AppRadius.CARD)
            .border({ width: 1, color: BrowseTheme.LINE }).onClick(() => this.onOpenPromotions()).accessibilityText('打开限量活动')
          Row({ space: 8 }) {
            Button({ type: ButtonType.Normal }) {
              Row({ space: 8 }) {
                Image($r('app.media.nav_cart')).width(19).height(19)
                Text(this.cartCount > 0 ? `购物车 · ${this.cartCount} 件` : '我的购物车').fontSize(12).fontColor(BrowseTheme.INK)
                  .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('›').fontSize(18).fontColor(BrowseTheme.MUTED)
              }.width('100%').padding({ left: 12, right: 12 })
            }.layoutWeight(1).height(44).padding(0).backgroundColor(Color.Transparent).borderRadius(12).onClick(() => this.onNavigate(2))
            Divider().vertical(true).height(18).color(BrowseTheme.LINE)
            Button({ type: ButtonType.Normal }) {
              Row({ space: 8 }) {
                Image($r('app.media.nav_profile')).width(19).height(19)
                Text('我的拾光').fontSize(12).fontColor(BrowseTheme.INK).layoutWeight(1)
                Text('›').fontSize(18).fontColor(BrowseTheme.MUTED)
              }.width('100%').padding({ left: 12, right: 12 })
            }.layoutWeight(1).height(44).padding(0).backgroundColor(Color.Transparent).borderRadius(12).onClick(() => this.onNavigate(3))
          }.width('100%').margin({ top: -6, bottom: -4 })
        }
        Row() {
          Text(this.keyword.trim().length > 0 ? '搜索结果' : '为日常，挑一件').fontSize(21).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
          Blank()
          if (!this.loading && !this.failed) {
            Text(`${this.products.length} 件${this.hasMore ? '+' : ''}`).fontSize(12).fontColor(BrowseTheme.MUTED)
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
          }.width('100%').alignItems(HorizontalAlign.Start).padding(22).backgroundColor(BrowseTheme.WASH).borderRadius(AppRadius.CARD)
        } else {
          GridRow({ columns: 12, gutter: 12,
            breakpoints: { value: ['360vp', '600vp', '840vp'], reference: BreakpointsReference.WindowSize } }) {
            ForEach(this.products, (product: DiscoveryProduct, index: number) => {
              GridCol({ span: { xs: 12, sm: 6, md: 4, lg: 4 } }) {
                this.productCell(product, index)
              }.alignSelf(ItemAlign.Start).margin({ bottom: 12 })
            }, (product: DiscoveryProduct) => `${product.storeId}-${product.id}`)
          }.width('100%').alignItems(ItemAlign.Start).opacity(this.productReveal ? 1 : 0)
            .translate({ y: this.productReveal ? 0 : 14 })
          if (this.hasMore) {
            Button(this.loadingMore ? '正在加载…' : this.moreFailed ? '加载失败，点击重试' : '加载更多商品', { type: ButtonType.Normal })
              .width('100%').height(44).backgroundColor(BrowseTheme.WASH).fontColor(BrowseTheme.INK).borderRadius(12)
              .enabled(!this.loadingMore).onClick(() => this.loadMore())
          }
          Text(this.hasMore ? '商品图片为示意图' : '已经到底了 · 商品图片为示意图').fontSize(11).fontColor(BrowseTheme.MUTED).width('100%')
        }
      }.width('100%').constraintSize({ maxWidth: AppSpacing.CATALOG_MAX }).padding({ left: 4, right: 4, top: 12, bottom: BrowseTheme.BOTTOM_CLEARANCE })
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(BrowseTheme.PAPER)
  }
}
