/**
 * 拾光集消费者商城的共享视觉 Token。
 * 页面和通用组件只引用语义名称，后续换肤时不需要逐页查找颜色与尺寸。
 */
export class AppColors {
  static readonly BACKGROUND: string = '#F7F5EF'
  static readonly SURFACE: string = '#FFFEF9'
  static readonly SAND: string = '#F0EADF'
  static readonly BRAND: string = '#24352C'
  static readonly BRAND_SOFT: string = '#E8EDE4'
  static readonly ACCENT: string = '#A85035'
  static readonly ACCENT_SOFT: string = '#F9E9DE'
  static readonly TEXT_PRIMARY: string = '#24352C'
  static readonly TEXT_SECONDARY: string = '#5C685F'
  static readonly TEXT_TERTIARY: string = '#626C63'
  static readonly DIVIDER: string = '#DCE0D7'
  static readonly DANGER: string = '#A64B39'
  static readonly SUCCESS: string = '#5C704A'
}

export class AppSpacing {
  static readonly PAGE_HORIZONTAL: number = 18
  static readonly SECTION: number = 20
  static readonly CARD: number = 16
  static readonly ITEM: number = 12
  /** 阅读与表单页面在展开态保持舒适行长。 */
  static readonly CONTENT_MAX: number = 720
  /** 商品目录在折叠屏展开态允许三列，但不无限拉宽。 */
  static readonly CATALOG_MAX: number = 840
  // 页面默认已避让系统导航区，只额外保留少量呼吸空间。
  static readonly FLOATING_BAR_BOTTOM: number = 8
  static readonly TAB_CLEARANCE: number = 100
}

export class AppRadius {
  static readonly CARD: number = 18
  static readonly CONTROL: number = 12
  static readonly PILL: number = 26
}
