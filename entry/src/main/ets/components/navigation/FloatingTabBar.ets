import { AppColors, AppRadius } from '../../theme/AppTheme'

@Component
export struct FloatingTabBar {
  @Prop selectedIndex: number = 0
  @Prop cartCount: number = 0
  onSelect: (index: number) => void = () => {}

  @Builder
  tabItem(index: number, icon: Resource, title: string) {
    Column({ space: 2 }) {
      Stack({ alignContent: Alignment.TopEnd }) {
      Image(icon).width(22).height(22)
        .fillColor(index === this.selectedIndex ? AppColors.SURFACE : AppColors.TEXT_SECONDARY)
        .scale({
          x: index === this.selectedIndex ? 1.08 : 1,
          y: index === this.selectedIndex ? 1.08 : 1
        })
        .animation({ duration: 240, curve: Curve.EaseInOut })
      if (index === 2 && this.cartCount > 0) {
        Text(this.cartCount > 99 ? '99+' : this.cartCount.toString())
          .fontSize(9).fontColor('#FFFFFF').backgroundColor('#934C35')
          .padding({ left: 4, right: 4, top: 1, bottom: 1 }).borderRadius(8)
          .translate({ x: 16, y: -5 })
      }
      }.width(24).height(22).clip(false)
      Text(title)
        .fontSize(11)
        .lineHeight(15)
        .fontWeight(index === this.selectedIndex ? FontWeight.Medium : FontWeight.Regular)
        .fontColor(index === this.selectedIndex ? AppColors.SURFACE : AppColors.TEXT_SECONDARY)
        .animation({ duration: 200, curve: Curve.EaseInOut })
    }
    .layoutWeight(1)
    .height(50)
    .justifyContent(FlexAlign.Center)
    .accessibilityText(title + (index === this.selectedIndex ? '，当前页面' : ''))
    .focusable(true)
    .stateStyles({ pressed: { opacity: 0.65 } })
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
      .borderRadius(20)
      .translate({ x: `${this.selectedIndex * 100}%` })
      .shadow({
        radius: 10,
        color: '#38215C49',
        offsetX: 0,
        offsetY: 4
      })
      .animation({ duration: 280, curve: Curve.EaseInOut })

      Row() {
        this.tabItem(0, $r('app.media.nav_home'), '首页')
        this.tabItem(1, $r('app.media.nav_store'), '逛店')
        this.tabItem(2, $r('app.media.nav_cart'), '购物车')
        this.tabItem(3, $r('app.media.nav_profile'), '我的')
      }
      .width('100%')
      .height(50)
    }
    .width('100%')
    .height(60)
    .padding(5)
    .backgroundColor(AppColors.SURFACE)
    .border({ width: 1, color: AppColors.DIVIDER })
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
