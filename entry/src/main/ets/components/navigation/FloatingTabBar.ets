import { AppColors, AppRadius } from '../../theme/AppTheme'

@Component
export struct FloatingTabBar {
  @Prop selectedIndex: number = 0
  onSelect: (index: number) => void = () => {}

  @Builder
  tabItem(index: number, icon: string, title: string) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(index === this.selectedIndex ? 20 : 18)
        .lineHeight(22)
        .fontWeight(index === this.selectedIndex ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(index === this.selectedIndex ? AppColors.SURFACE : AppColors.TEXT_TERTIARY)
        .scale({
          x: index === this.selectedIndex ? 1.08 : 1,
          y: index === this.selectedIndex ? 1.08 : 1
        })
        .animation({ duration: 240, curve: Curve.EaseInOut })
      Text(title)
        .fontSize(11)
        .lineHeight(15)
        .fontWeight(index === this.selectedIndex ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(index === this.selectedIndex ? AppColors.SURFACE : AppColors.TEXT_TERTIARY)
        .animation({ duration: 200, curve: Curve.EaseInOut })
    }
    .layoutWeight(1)
    .height(50)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.getUIContext().animateTo({ duration: 280, curve: Curve.EaseInOut }, () => {
        this.onSelect(index)
      })
    })
  }

  build() {
    Stack({ alignContent: Alignment.Start }) {
      Row() {
      }
      .width('25%')
      .height(50)
      .backgroundColor(AppColors.BRAND)
      .borderRadius(18)
      .translate({ x: `${this.selectedIndex * 100}%` })
      .shadow({
        radius: 10,
        color: '#38215C49',
        offsetX: 0,
        offsetY: 4
      })
      .animation({ duration: 280, curve: Curve.EaseInOut })

      Row() {
        this.tabItem(0, '⌂', '首页')
        this.tabItem(1, '▦', '逛店')
        this.tabItem(2, '▱', '购物车')
        this.tabItem(3, '○', '我的')
      }
      .width('100%')
      .height(50)
    }
    .width('100%')
    .height(60)
    .padding(5)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(AppRadius.PILL)
    .constraintSize({ maxWidth: 328 })
    .clip(false)
    .shadow({
      radius: 18,
      color: '#2B0F2D23',
      offsetX: 0,
      offsetY: 5
    })
  }
}
