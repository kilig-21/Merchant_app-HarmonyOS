import { common } from '@kit.AbilityKit'
import { HomeContent } from '../components/home/HomeContent'
import { StoreContent } from '../components/store/StoreContent'
import { CartContent } from '../components/cart/CartContent'
import { ProfileContent } from '../components/profile/ProfileContent'
import { FloatingTabBar } from '../components/navigation/FloatingTabBar'
import { PageStateType, PageStateView } from '../components/common/PageStateView'
import { ProductDetailPage } from './ProductDetailPage'
import { AddressManagerPage } from './AddressManagerPage'
import { CheckoutPage } from './CheckoutPage'
import { OrdersPage } from './OrdersPage'
import { AfterSalesPage } from './AfterSalesPage'
import { PromotionDetailPage } from './PromotionDetailPage'
import { PromotionsPage } from './PromotionsPage'
import { AuthPage } from './AuthPage'
import { ServicePage } from './ServicePage'
import { ProductRoute } from '../model/ProductModels'
import { PromotionRoute } from '../model/PromotionModels'
import { CartViewModel } from '../viewmodel/CartViewModel'
import { SessionViewModel } from '../viewmodel/SessionViewModel'
import { BrowseConfig, BrowseSource } from '../config/BrowseConfig'
import { AppColors, AppSpacing } from '../theme/AppTheme'

class PageRoute {
  status: string
  constructor(status: string = '') { this.status = status }
}

@Entry
@Component
struct Index {
  private pageStack: NavPathStack = new NavPathStack()
  @State selectedTabIndex: number = 0
  @State browseStoreId: number = 1001
  @State cart: CartViewModel = new CartViewModel()
  @State session: SessionViewModel = new SessionViewModel()
  @State homeQuery: string = ''
  @State addressRevision: number = 0
  @State checkoutLocked: boolean = false
  private pendingPage: string = ''
  private pendingStatus: string = ''

  aboutToAppear(): void { this.restore() }
  private async restore(): Promise<void> {
    await this.session.restore(this.getUIContext().getHostContext() as common.UIAbilityContext)
    if (this.session.username.length > 0 || BrowseConfig.source === BrowseSource.Mock) { this.cart.load() }
  }
  private authenticated(): boolean { return this.session.username.length > 0 }
  private login(next: string = '', status: string = ''): void {
    if (!this.session.ready || this.pageStack.getAllPathName().includes('login')) { return }
    this.pendingPage = next
    this.pendingStatus = status
    this.pageStack.pushPath({ name: 'login', param: new PageRoute() })
  }
  private openPage(name: string, status: string = ''): void {
    if (['orders', 'addresses', 'checkout', 'afterSales'].includes(name) && !this.authenticated()) {
      this.login(name, status)
      return
    }
    this.pageStack.pushPath({ name: name, param: new PageRoute(status) })
  }
  private signedIn(): void {
    this.cart = new CartViewModel()
    this.cart.load()
    this.pageStack.pop()
    const next = this.pendingPage
    const status = this.pendingStatus
    this.pendingPage = ''
    if (next.length > 0) { this.openPage(next, status) }
  }
  private async signOut(): Promise<void> {
    if (await this.session.signOut(this.getUIContext().getHostContext() as common.UIAbilityContext)) {
      // 替换实例，旧请求即使迟到也只能更新已卸载的实例。
      this.cart = new CartViewModel()
      this.pageStack.clear()
      this.selectedTabIndex = 3
    }
  }
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
          storeId: (param as ProductRoute).storeId, productId: (param as ProductRoute).productId,
          initialSkuId: (param as ProductRoute).skuId ?? 0, cart: this.cart,
          signedIn: this.authenticated(), onLogin: () => this.login(),
          onBack: () => this.pageStack.pop(), onOpenStore: (id: number) => this.openStore(id),
          onOpenCart: () => { this.selectedTabIndex = 2; this.pageStack.clear() }
        })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    } else if (name === 'addresses') {
      NavDestination() {
        AddressManagerPage({ onBack: () => this.pageStack.pop(), onChanged: () => this.addressRevision++ })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    } else if (name === 'checkout') {
      NavDestination() {
        CheckoutPage({ cart: this.cart, addressRevision: this.addressRevision,
          onLockChange: (locked: boolean) => this.checkoutLocked = locked,
          onBack: () => this.pageStack.pop(), onOpenAddresses: () => this.openPage('addresses'),
          onOpenOrders: () => { this.pageStack.pop(); this.openPage('orders') } })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND).onBackPressed(() => this.checkoutLocked)
    } else if (name === 'orders') {
      NavDestination() {
        OrdersPage({ initialFilter: (param as PageRoute).status, onBack: () => this.pageStack.pop(),
          onBrowse: () => { this.pageStack.clear(); this.selectedTabIndex = 1 } })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    } else if (name === 'afterSales') {
      NavDestination() {
        AfterSalesPage({ onBack: () => this.pageStack.pop() })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    } else if (name === 'promotions') {
      NavDestination() {
        PromotionsPage({ onBack: () => this.pageStack.pop(),
          onOpenDetail: (activityId: number) => this.pageStack.pushPath({ name: 'promotion', param: new PromotionRoute(activityId) }) })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    } else if (name === 'promotion') {
      NavDestination() {
        PromotionDetailPage({ activityId: (param as PromotionRoute).activityId, onBack: () => this.pageStack.pop() })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    } else if (name === 'login') {
      NavDestination() {
        AuthPage({ session: this.session, onBack: () => this.pageStack.pop(), onSuccess: () => this.signedIn() })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND).onBackPressed(() => this.session.busy)
    } else if (name === 'help' || name === 'settings') {
      NavDestination() {
        ServicePage({ settings: name === 'settings', session: this.session,
          onBack: () => this.pageStack.pop(), onLogin: () => this.login(), onLogout: () => this.signOut() })
      }.hideTitleBar(true).backgroundColor(AppColors.BACKGROUND)
    }
  }

  build() {
    Navigation(this.pageStack) {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.selectedTabIndex === 0) {
            HomeContent({ initialQuery: this.homeQuery, cartCount: this.cart.count(),
              onQueryChange: (query: string) => this.homeQuery = query,
              onNavigate: (index: number) => this.selectedTabIndex = index,
              onOpenPromotions: () => this.openPage('promotions'),
              onOpenProduct: (storeId: number, productId: number) => this.openProduct(storeId, productId) })
          } else if (this.selectedTabIndex === 1) {
            StoreContent({ selectedStoreId: this.browseStoreId,
              onSelectStore: (id: number) => this.browseStoreId = id,
              onOpenProduct: (storeId: number, productId: number) => this.openProduct(storeId, productId) })
          } else if (this.selectedTabIndex === 2) {
            if (!this.session.ready) {
              PageStateView({ type: PageStateType.Loading, title: '正在恢复账户', description: '稍等片刻。' })
            } else if (!this.authenticated() && BrowseConfig.source === BrowseSource.Remote) {
              Column({ space: 20 }) {
                Text('购物车').fontSize(28).fontWeight(FontWeight.Medium).fontColor(AppColors.BRAND).width('100%')
                PageStateView({ type: PageStateType.Empty, title: '登录，找回你的好物',
                  description: '登录后可同步购物车，继续挑选和下单。', actionLabel: '登录 / 注册', onAction: () => this.login() })
                Button('先去逛逛', { type: ButtonType.Normal }).height(44).fontColor(AppColors.BRAND)
                  .backgroundColor(AppColors.BRAND_SOFT).onClick(() => this.selectedTabIndex = 1)
              }.width('100%').padding({ top: 20 })
            } else {
              CartContent({ cart: this.cart, onLogin: () => this.login(), onNavigate: (index: number) => this.selectedTabIndex = index,
                onOpenStore: (id: number) => this.openStore(id),
                onOpenProduct: (storeId: number, productId: number, skuId: number) => this.openProduct(storeId, productId, skuId),
                onCheckout: () => this.openPage('checkout') })
            }
          } else if (!this.session.ready) {
            PageStateView({ type: PageStateType.Loading, title: '正在恢复账户', description: '稍等片刻。' })
          } else {
            ProfileContent({ session: this.session, onLogin: () => this.login(),
              onOpenOrders: (status: string) => this.openPage('orders', status),
              onOpenAddresses: () => this.openPage('addresses'),
              onOpenAfterSales: () => this.openPage('afterSales'),
              onOpenHelp: () => this.openPage('help'), onOpenSettings: () => this.openPage('settings') })
          }
        }.width('100%').height('100%').padding({ left: 16, right: 16, top: 8 })
        Column() {
          FloatingTabBar({ selectedIndex: this.selectedTabIndex, cartCount: this.cart.count(), onSelect: (index: number) => this.selectedTabIndex = index })
        }.width('100%').alignItems(HorizontalAlign.Center)
          .padding({ left: 20, right: 20, bottom: AppSpacing.FLOATING_BAR_BOTTOM })
      }
    }.mode(NavigationMode.Stack).hideTitleBar(true).navDestination(this.destination)
      .width('100%').height('100%').backgroundColor(AppColors.BACKGROUND)
  }
}
