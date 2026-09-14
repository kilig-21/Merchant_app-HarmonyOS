import { BrowseConfig, BrowseScenario, BrowseSource } from '../config/BrowseConfig'
import { ProductApi } from '../api/ProductApi'
import { StoreApi } from '../api/StoreApi'
import { MOCK_CATALOGS, MockStoreCatalog } from '../mock/BrowseMockData'
import { ProductSummary, StoreSummary } from '../model/StoreModels'
import { ProductDetail, DiscoveryProduct } from '../model/ProductModels'
import { MOCK_PRODUCT_SKUS, MockProductSkus } from '../mock/ProductMockData'

export class BrowseRepository {
  private hasFailed: boolean = false

  async searchProducts(keyword: string): Promise<DiscoveryProduct[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      return await ProductApi.searchProducts(keyword)
    }
    await this.waitForMock()
    if (BrowseConfig.scenario === BrowseScenario.EmptyStores) { return [] }
    const query = keyword.trim().toLowerCase()
    const result: DiscoveryProduct[] = []
    MOCK_CATALOGS.forEach((catalog: MockStoreCatalog) => {
      catalog.products.forEach((product: ProductSummary) => {
        if (query.length === 0 || (product.name + ' ' + product.description + ' ' + catalog.store.name).toLowerCase().includes(query)) {
          result.push({ storeId: catalog.store.id, storeName: catalog.store.name,
            id: product.id, name: product.name, description: product.description,
            minSalePrice: product.minSalePrice, totalAvailableStock: product.totalAvailableStock, updatedAt: product.updatedAt })
        }
      })
    })
    return result
  }

  async getStore(storeId: number): Promise<StoreSummary> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      const stores = await StoreApi.getStores()
      const store = stores.find((item: StoreSummary) => item.id === storeId)
      if (store === undefined) { throw new Error('店铺不存在或已下架') }
      return store
    }
    await this.waitForMock()
    const catalog = MOCK_CATALOGS.find((item: MockStoreCatalog) => item.store.id === storeId)
    if (catalog === undefined) { throw new Error('店铺不存在') }
    return catalog.store
  }

  async getProduct(storeId: number, productId: number): Promise<ProductDetail> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      return await ProductApi.getProduct(storeId, productId)
    }
    const products = await this.getProducts(storeId)
    const product = products.find((item: ProductSummary) => item.id === productId)
    const variants = MOCK_PRODUCT_SKUS.find((item: MockProductSkus) => item.productId === productId)
    if (product === undefined || variants === undefined) { throw new Error('商品不存在或已下架') }
    return { id: product.id, name: product.name, description: product.description,
      updatedAt: product.updatedAt, skus: variants.skus.slice() }
  }

  private async waitForMock(): Promise<void> {
    if (BrowseConfig.source !== BrowseSource.Mock) { return }
    await new Promise<void>((resolve) => { setTimeout(() => resolve(), BrowseConfig.delayMs) })
    if (BrowseConfig.scenario === BrowseScenario.FailOnce && !this.hasFailed) {
      this.hasFailed = true
      throw new Error('演示加载失败，请重试')
    }
  }

  async getStores(): Promise<StoreSummary[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      return await StoreApi.getStores()
    }
    await this.waitForMock()
    if (BrowseConfig.scenario === BrowseScenario.EmptyStores) { return [] }
    return MOCK_CATALOGS.map((catalog: MockStoreCatalog) => catalog.store)
  }

  async getProducts(storeId: number): Promise<ProductSummary[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      return await ProductApi.getProducts(storeId)
    }
    await this.waitForMock()
    if (BrowseConfig.scenario === BrowseScenario.FailProductsOnce && !this.hasFailed) {
      this.hasFailed = true
      throw new Error('演示商品加载失败，请重试')
    }
    const catalog = MOCK_CATALOGS.find((item: MockStoreCatalog) => item.store.id === storeId)
    if (catalog === undefined) { throw new Error('店铺不存在') }
    return catalog.products.slice()
  }
}
