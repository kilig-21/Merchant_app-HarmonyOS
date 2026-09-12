import { BrowseTheme } from '../../theme/BrowseTheme'

@Component
export struct QuantityStepper {
  @Prop value: number = 1
  @Prop maximum: number = 1
  @Prop disabled: boolean = false
  onChange: (quantity: number) => void = () => {}

  build() {
    Row({ space: 0 }) {
      Button('−', { type: ButtonType.Normal }).width(40).height(40).padding(0)
        .fontSize(20).fontColor(BrowseTheme.INK).backgroundColor(BrowseTheme.WASH)
        .enabled(!this.disabled && this.value > 1 && this.maximum > 0)
        .onClick(() => this.onChange(Math.max(1, Math.min(this.value - 1, this.maximum)))).accessibilityText('减少数量')
      Text(this.value.toString()).width(38).textAlign(TextAlign.Center).fontSize(14).fontColor(BrowseTheme.INK)
      Button('+', { type: ButtonType.Normal }).width(40).height(40).padding(0)
        .fontSize(20).fontColor(BrowseTheme.INK).backgroundColor(BrowseTheme.WASH)
        .enabled(!this.disabled && this.value < this.maximum)
        .onClick(() => this.onChange(this.value + 1)).accessibilityText('增加数量')
    }.borderRadius(6).clip(true)
  }
}
