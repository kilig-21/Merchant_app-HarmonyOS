import { CartItem } from '../../model/CartModels'
import { BrowseTheme } from '../../theme/BrowseTheme'
import { ProductArtwork } from '../../theme/ProductArtwork'
import { QuantityStepper } from '../common/QuantityStepper'

/** 点击商品信息打开详情；勾选、数量、删除拥有独立热区。 */
@Component
export struct CartItemCard {
  @Prop item: CartItem
  @Prop selected: boolean = false
  @Prop busy: boolean = false
  onSelect: (selected: boolean) => void = () => {}
  onQuantityChange: (quantity: number) => void = () => {}
  onRemove: () => void = () => {}
  onOpen: () => void = () => {}

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Checkbox({ name: this.item.id.toString() }).select(this.selected)
          .shape(CheckBoxShape.CIRCLE).selectedColor(BrowseTheme.INK).unselectedColor('#899080')
          .width(22).height(22).margin({ left: 0, right: 4 })
          .enabled(!this.busy && this.item.purchasable).onChange(this.onSelect)
          .accessibilityText(`选择${this.item.productName} ${this.item.skuName}`)
        Image(ProductArtwork.resolve(this.item.productId)).width(76).height(94).objectFit(ImageFit.Cover)
          .borderRadius(BrowseTheme.RADIUS).onClick(this.onOpen).accessibilityText(`查看${this.item.productName}`)
        Column({ space: 7 }) {
          Text(this.item.productName).fontSize(16).fontWeight(FontWeight.Medium).fontColor(BrowseTheme.INK)
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).onClick(this.onOpen)
          Text(this.item.skuName).fontSize(12).lineHeight(18).fontColor(BrowseTheme.MUTED).maxLines(2).onClick(this.onOpen)
          Text(`¥ ${this.item.salePrice.toFixed(2)}`).fontSize(18).fontColor(BrowseTheme.INK)
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      }.width('100%').alignItems(VerticalAlign.Top)
      if (!this.item.purchasable) {
        Text(this.item.unavailableReason ?? '商品暂时不可购买').width('100%').fontSize(12).fontColor('#98482F')
      }
      Row() {
        Button('移除', { type: ButtonType.Normal }).height(40).padding({ left: 0, right: 16 }).fontSize(12)
          .fontColor(BrowseTheme.MUTED).backgroundColor(Color.Transparent).enabled(!this.busy).onClick(this.onRemove)
        Blank()
        QuantityStepper({ value: this.item.quantity, maximum: this.item.availableStock,
          disabled: this.busy || this.item.availableStock === 0, onChange: this.onQuantityChange })
      }.width('100%')
    }.width('100%').padding({ top: 16, bottom: 12 })
  }
}
