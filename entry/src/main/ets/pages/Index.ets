import { HomeContent } from '../components/home/HomeContent'
import { StoreContent } from '../components/store/StoreContent'
import { CartContent } from '../components/cart/CartContent'
import { ProfileContent } from '../components/profile/ProfileContent'
import { FloatingTabBar } from '../components/navigation/FloatingTabBar'
import { PrototypeFlow } from '../components/flow/PrototypeFlow'
import { ProductDetailPage } from './ProductDetailPage'
import { AddressManagerPage } from './AddressManagerPage'
import { CheckoutPage } from './CheckoutPage'
import { ProductRoute } from '../model/ProductModels'
import { CartViewModel } from '../viewmodel/CartViewModel'
import { AppColors, AppSpacing } from '../theme/AppTheme'

@Entry
@Component
struct Index {
  private pageStack: NavPathStack = new NavPathStack()
  @State selectedTabIndex: number = 0
  @State flowPage: string = ''
  @State browseStoreId: number = 1001
  @State cart: CartViewModel = new CartViewModel()
  @State homeQuery: string = ''
  @State utilityPage: string = ''

  private openProduct(storeId: number, productId: number, skuId: number = 0): void {
    if (this.pageStack.size() > 0) { return }
    const route: ProductRoute = { storeId: storeId, productId: productId, skuId: skuId }
    this.pageStack.pushPath({ name: 'product', param: route })
  }

  private openStore(storeId: number): void {
    this.browseStoreId = storeId
    this.selectedTabIndex = 1
    this.pageStack.clear()
  }

  @Builder
  destination(name: string, param: Object) {
    if (name === 'product') {
      NavDestination() {
        ProductDetailPage({
          storeId: (param as ProductRoute).storeId,
          productId: (param as ProductRoute).productId,
          initialSkuId: (param as ProductRoute).skuId ?? 0,
          cart: this.cart,
          onBack: () => this.pageStack.pop(),
          onOpenStore: (storeId: number) => this.openStore(storeId),
          onOpenCart: () => { this.selectedTabIndex = 2; this.pageStack.clear() }
        })
      }.hideTitleBar(true)
    }
  }

  build() {
    Navigation(this.pageStack) {
      if (this.utilityPage === 'addresses') {
        AddressManagerPage({ onBack: () => this.utilityPage = '' })
      } else if (this.utilityPage === 'checkout') {
        CheckoutPage({ cart: this.cart, onBack: () => this.utilityPage = '', onOpenAddresses: () => this.utilityPage = 'addresses', onOpenOrders: () => { this.utilityPage = ''; this.flowPage = 'orders' } })
      } else if (this.flowPage.length > 0) {
        PrototypeFlow({ page: this.flowPage, onBack: () => this.flowPage = '', onNavigate: (page: string) => this.flowPage = page })
      } else {
        Stack({ alignContent: Alignment.Bottom }) {
          Column() {
            if (this.selectedTabIndex === 0) {
              HomeContent({ initialQuery: this.homeQuery, cartCount: this.cart.count(),
                onQueryChange: (query: string) => this.homeQuery = query,
                onNavigate: (index: number) => this.selectedTabIndex = index,
                onOpenProduct: (storeId: number, productId: number) => this.openProduct(storeId, productId) })
            } else if (this.selectedTabIndex === 1) {
              StoreContent({
                selectedStoreId: this.browseStoreId,
                onSelectStore: (storeId: number) => this.browseStoreId = storeId,
                onOpenProduct: (storeId: number, productId: number) => this.openProduct(storeId, productId)
              })
            } else if (this.selectedTabIndex === 2) {
              CartContent({ cart: this.cart, onNavigate: (index: number) => this.selectedTabIndex = index,
                onOpenStore: (storeId: number) => this.openStore(storeId),
                onOpenProduct: (storeId: number, productId: number, skuId: number) => this.openProduct(storeId, productId, skuId),
                onCheckout: () => this.utilityPage = 'checkout' })
            } else {
              ProfileContent({ onNavigate: (index: number) => this.selectedTabIndex = index, onOpenOrders: () => this.flowPage = 'orders', onOpenAddresses: () => this.utilityPage = 'addresses' })
            }
          }.width('100%').height('100%').padding({ left: 16, right: 16, top: 8 })
          Column() {
            FloatingTabBar({ selectedIndex: this.selectedTabIndex, cartCount: this.cart.count(), onSelect: (index: number) => this.selectedTabIndex = index })
          }.width('100%').alignItems(HorizontalAlign.Center)
            .padding({ left: 20, right: 20, bottom: AppSpacing.FLOATING_BAR_BOTTOM })
        }
      }
    }.mode(NavigationMode.Stack).hideTitleBar(true).navDestination(this.destination)
      .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
