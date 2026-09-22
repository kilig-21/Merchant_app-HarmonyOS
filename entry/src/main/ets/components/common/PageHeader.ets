import { AppColors, AppRadius } from '../../theme/AppTheme'

/** 二级页面统一的标题栏；页面仍负责导航及业务状态。 */
@Component
export struct PageHeader {
  @Prop title: string = ''
  @Prop subtitle: string = ''
  @Prop actionLabel: string = ''
  @Prop backDisabled: boolean = false
  @Prop actionDisabled: boolean = false
  @Prop inset: number = 0
  onBack: () => void = () => {}
  onAction: () => void = () => {}

  build() {
    Row({ space: 4 }) {
      Button({ type: ButtonType.Normal }) {
        Image($r('app.media.icon_back')).width(22).height(22)
      }.width(44).height(44).padding(0).backgroundColor(Color.Transparent).borderRadius(AppRadius.CONTROL)
        .enabled(!this.backDisabled).onClick(this.onBack).accessibilityText('返回')
      Column({ space: 3 }) {
        Text(this.title).fontSize(20).lineHeight(28).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND)
        if (this.subtitle.length > 0) {
          Text(this.subtitle).fontSize(12).lineHeight(18).fontColor(AppColors.TEXT_SECONDARY)
        }
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
      if (this.actionLabel.length > 0) {
        Button(this.actionLabel, { type: ButtonType.Normal }).height(44).fontSize(13)
          .padding({ left: 14, right: 14 }).backgroundColor(AppColors.BRAND_SOFT)
          .fontColor(AppColors.BRAND).borderRadius(AppRadius.CONTROL)
          .enabled(!this.actionDisabled).onClick(this.onAction)
      }
    }.width('100%').constraintSize({ minHeight: 52 }).padding({ left: this.inset, right: this.inset })
  }
}
