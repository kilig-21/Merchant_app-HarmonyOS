import { AppColors, AppRadius, AppSpacing } from './AppTheme'

/** 浏览页面沿用全局主题，避免同一款 App 出现两套色板。 */
export class BrowseTheme {
  static readonly PAPER: string = AppColors.BACKGROUND
  static readonly INK: string = AppColors.BRAND
  static readonly MUTED: string = AppColors.TEXT_SECONDARY
  static readonly LINE: string = AppColors.DIVIDER
  static readonly OLIVE: string = AppColors.SUCCESS
  static readonly WASH: string = AppColors.BRAND_SOFT
  static readonly RADIUS: number = AppRadius.CARD
  static readonly BOTTOM_CLEARANCE: number = AppSpacing.TAB_CLEARANCE
}
