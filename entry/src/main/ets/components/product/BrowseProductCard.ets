import { ProductSummary } from '../../model/StoreModels'
import { BrowseTheme } from '../../theme/BrowseTheme'

/** 展示卡片只报告商品 ID，不请求数据、不处理交易。 */
@Component
export struct BrowseProductCard {
  @Prop product: ProductSummary
  @Prop artwork: Resource = $r('app.media.browse_tea')
  @Prop sequence: string = '01'
  onOpen: (productId: number) => void = () => {}

  build() {
    Column({ space: 10 }) {
      Stack({ alignContent: Alignment.TopStart }) {
        Image(this.artwork).width('100%').aspectRatio(0.86).objectFit(ImageFit.Cover)
        Text(this.sequence).fontSize(11).fontColor(BrowseTheme.MUTED).margin(12)
        if (this.product.totalAvailableStock === 0) {
          Text('暂时售罄').fontSize(11).fontColor(BrowseTheme.INK)
            .padding({ left: 9, right: 9, top: 5, bottom: 5 })
            .backgroundColor(BrowseTheme.PAPER).margin({ top: 34, left: 12 })
        }
      }.width('100%').borderRadius(BrowseTheme.RADIUS).clip(true)
      Text(this.product.name).fontSize(16).fontWeight(FontWeight.Medium)
        .fontColor(BrowseTheme.INK).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.product.description).fontSize(12).lineHeight(19).fontColor(BrowseTheme.MUTED)
        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
      Row({ space: 3 }) {
        Text('¥').fontSize(12).fontColor(BrowseTheme.INK)
        Text(this.product.minSalePrice.toFixed(2)).fontSize(20).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
        Text('起').fontSize(11).fontColor(BrowseTheme.MUTED)
        Blank()
        Text('↗').fontSize(18).fontColor(BrowseTheme.OLIVE)
      }.width('100%').alignItems(VerticalAlign.Bottom)
    }.width('100%').alignItems(HorizontalAlign.Start)
      .onClick(() => this.onOpen(this.product.id))
      .accessibilityText(`${this.product.name}，${this.product.minSalePrice.toFixed(2)}元起，查看商品概览`)
      .focusable(true)
  }
}
