import { AppColors, AppRadius, AppSpacing } from '../../theme/AppTheme'

/** 适合提示、摘要和入口的通用信息卡；只展示输入并抛出点击事件。 */
@Component
export struct AppCard {
  @Prop eyebrow: string = ''
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop icon: string = '✦'
  @Prop cardBackground: string = AppColors.SURFACE
  onCardClick: () => void = () => {}

  build() {
    Row({ space: AppSpacing.ITEM }) {
      Text(this.icon)
        .width(42)
        .height(42)
        .fontSize(19)
        .fontColor(AppColors.BRAND)
        .textAlign(TextAlign.Center)
        .padding({ top: 10 })
        .backgroundColor(AppColors.BRAND_SOFT)
        .borderRadius(14)

      Column({ space: 4 }) {
        if (this.eyebrow.length > 0) {
          Text(this.eyebrow)
            .fontSize(11)
            .fontColor(AppColors.ACCENT)
        }
        Text(this.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
        Text(this.description)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
          .lineHeight(18)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(22)
        .fontColor(AppColors.TEXT_TERTIARY)
    }
    .width('100%')
    .padding(AppSpacing.CARD)
    .backgroundColor(this.cardBackground)
    .borderRadius(AppRadius.CARD)
    .onClick(() => this.onCardClick())
  }
}
