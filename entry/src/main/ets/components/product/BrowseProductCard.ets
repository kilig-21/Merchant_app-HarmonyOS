import { ProductSummary } from '../../model/StoreModels'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { AppColors } from '../../theme/AppTheme'

/** 展示卡片只报告商品 ID，不请求数据、不处理交易。 */
@Component
export struct BrowseProductCard {
  @Prop product: ProductSummary
  @Prop artwork: Resource = $r('app.media.browse_tea')
  @Prop sequence: string = '01'
  onOpen: (productId: number) => void = () => {}

  build() {
    Column({ space: 0 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.artwork).width('100%').aspectRatio(1).objectFit(ImageFit.Cover).accessibilityLevel('no')
        Text(this.sequence).fontSize(10).fontColor(BrowseTheme.INK).letterSpacing(1)
          .padding({ left: 7, right: 7, top: 4, bottom: 4 }).backgroundColor('#E6FFFEF9').borderRadius(8).margin(10)
        if (this.product.totalAvailableStock === 0) {
          Text('暂时售罄').fontSize(11).fontColor(BrowseTheme.INK)
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor(BrowseTheme.PAPER).margin({ top: 34, left: 12 })
        }
      }.width('100%').clip(true)
      Column({ space: 7 }) {
      Text(this.product.name).fontSize(16).fontWeight(FontWeight.Medium)
        .fontColor(BrowseTheme.INK).lineHeight(22).constraintSize({ minHeight: '44fp' })
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.product.description).fontSize(12).lineHeight(19).fontColor(BrowseTheme.MUTED)
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text() {
        Span('¥ ').fontSize(12).fontColor(AppColors.ACCENT)
        Span(this.product.minSalePrice.toFixed(2)).fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppColors.ACCENT)
        Span(' 起').fontSize(11).fontColor(BrowseTheme.MUTED)
      }.width('100%').maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').padding(12).alignItems(HorizontalAlign.Start)
    }.width('100%').alignItems(HorizontalAlign.Start)
      .backgroundColor(AppColors.SURFACE).borderRadius(BrowseTheme.RADIUS).clip(true)
      .stateStyles({ pressed: { opacity: 0.66 } })
      .onClick(() => this.onOpen(this.product.id))
      .accessibilityText(`${this.product.name}，${this.product.minSalePrice.toFixed(2)}元起，查看商品详情`)
      .accessibilityGroup(true)
      .focusable(true)
  }
}
