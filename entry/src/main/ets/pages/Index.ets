import { HomeContent } from '../components/home/HomeContent'
import { StoreContent } from '../components/store/StoreContent'
import { CartContent } from '../components/cart/CartContent'
import { ProfileContent } from '../components/profile/ProfileContent'
import { FloatingTabBar } from '../components/navigation/FloatingTabBar'
import { PrototypeFlow } from '../components/flow/PrototypeFlow'
import { AppColors, AppSpacing } from '../theme/AppTheme'

@Entry
@Component
struct Index {
  private pageStack: NavPathStack = new NavPathStack()
  @State selectedTabIndex: number = 0
  @State flowPage: string = ''
  @State browseStoreId: number = 1001

  build() {
    Navigation(this.pageStack) {
      if (this.flowPage.length > 0) {
        PrototypeFlow({
          page: this.flowPage,
          onBack: () => this.flowPage = '',
          onNavigate: (page: string) => this.flowPage = page
        })
      } else {
      Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.selectedTabIndex === 0) {
          HomeContent({ onNavigate: (index: number) => this.selectedTabIndex = index })
        } else if (this.selectedTabIndex === 1) {
          StoreContent({
            selectedStoreId: this.browseStoreId,
            onSelectStore: (storeId: number) => this.browseStoreId = storeId
          })
        } else if (this.selectedTabIndex === 2) {
          CartContent({ onNavigate: (index: number) => this.selectedTabIndex = index, onCheckout: () => this.flowPage = 'checkout' })
        } else {
          ProfileContent({ onNavigate: (index: number) => this.selectedTabIndex = index, onOpenOrders: () => this.flowPage = 'orders' })
        }

      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 8 })

      Column() {
        FloatingTabBar({
          selectedIndex: this.selectedTabIndex,
          onSelect: (index: number) => this.selectedTabIndex = index
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 20, right: 20, bottom: AppSpacing.FLOATING_BAR_BOTTOM })
      }
      }
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }
}
