import { AppColors, AppRadius, AppSpacing } from '../../theme/AppTheme'

export enum PageStateType {
  Loading = 'loading',
  Empty = 'empty',
  Error = 'error'
}

/** 列表和页面共用的加载、空内容与错误反馈；不持有业务状态。 */
@Component
export struct PageStateView {
  @Prop type: PageStateType = PageStateType.Loading
  @Prop title: string = ''
  @Prop description: string = ''
  @Prop actionLabel: string = '重试'
  onAction: () => void = () => {}

  build() {
    Column({ space: 11 }) {
      if (this.type === PageStateType.Loading) {
        LoadingProgress()
          .width(30)
          .height(30)
          .color(AppColors.BRAND)
      } else {
        Text(this.type === PageStateType.Empty ? '○' : '!')
          .width(42)
          .height(42)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.type === PageStateType.Empty ? AppColors.BRAND : AppColors.DANGER)
          .textAlign(TextAlign.Center)
          .padding({ top: 8 })
          .backgroundColor(this.type === PageStateType.Empty ? AppColors.BRAND_SOFT : AppColors.ACCENT_SOFT)
          .borderRadius(21)
      }

      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY)
        .textAlign(TextAlign.Center)

      Text(this.description)
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY)
        .lineHeight(19)
        .textAlign(TextAlign.Center)

      if (this.type === PageStateType.Error) {
        Button(this.actionLabel)
          .height(36)
          .fontSize(13)
          .fontColor(AppColors.SURFACE)
          .backgroundColor(AppColors.BRAND)
          .borderRadius(AppRadius.CONTROL)
          .margin({ top: 4 })
          .onClick(() => this.onAction())
      }
    }
    .width('100%')
    .padding({ left: AppSpacing.CARD, right: AppSpacing.CARD, top: 20, bottom: 20 })
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.CARD)
    .border({ width: 1, color: AppColors.DIVIDER })
  }
}
