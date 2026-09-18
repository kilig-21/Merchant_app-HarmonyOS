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
        .backgroundColor(AppColors.SURFACE)
        .border({ width: 1, color: AppColors.DIVIDER })
        .borderRadius(AppRadius.CONTROL)

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

      Text('↗')
        .fontSize(16)
        .fontColor(AppColors.BRAND)
    }
    .width('100%')
    .padding(AppSpacing.CARD)
    .backgroundColor(this.cardBackground)
    .borderRadius(AppRadius.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
    .shadow({ radius: 12, color: '#120F2118', offsetX: 0, offsetY: 5 })
    .stateStyles({ pressed: { opacity: 0.72 } })
    .onClick(() => this.onCardClick())
  }
}
