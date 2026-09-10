/**
 * 消费者商城原型的视觉 Token。
 * 页面和通用组件只引用语义名称，后续换肤时不需要逐页查找颜色与尺寸。
 */
export class AppColors {
  static readonly BACKGROUND: string = '#F7F5EF'
  static readonly SURFACE: string = '#FFFFFF'
  static readonly BRAND: string = '#215C49'
  static readonly BRAND_SOFT: string = '#E5F0EA'
  static readonly ACCENT: string = '#C45F3B'
  static readonly ACCENT_SOFT: string = '#FFF0DF'
  static readonly TEXT_PRIMARY: string = '#18352C'
  static readonly TEXT_SECONDARY: string = '#66776F'
  static readonly TEXT_TERTIARY: string = '#8A9690'
  static readonly DIVIDER: string = '#E8ECE8'
  static readonly DANGER: string = '#B94B3A'
}

export class AppSpacing {
  static readonly PAGE_HORIZONTAL: number = 18
  static readonly SECTION: number = 20
  static readonly CARD: number = 16
  static readonly ITEM: number = 12
  // 页面默认已避让系统导航区，只额外保留少量呼吸空间。
  static readonly FLOATING_BAR_BOTTOM: number = 8
}

export class AppRadius {
  static readonly CARD: number = 22
  static readonly CONTROL: number = 16
  static readonly PILL: number = 24
}
