import { BrowseConfig, BrowseScenario } from '../config/BrowseConfig'
import { MOCK_CATALOGS, MockStoreCatalog } from '../mock/BrowseMockData'
import { ProductSummary, StoreSummary } from '../model/StoreModels'
import { ProductDetail, DiscoveryProduct } from '../model/ProductModels'
import { MOCK_PRODUCT_SKUS, MockProductSkus } from '../mock/ProductMockData'

export class BrowseRepository {
  private hasFailed: boolean = false

  async getStore(storeId: number): Promise<StoreSummary> {
    await this.waitForMock()
    const catalog = MOCK_CATALOGS.find((item: MockStoreCatalog) => item.store.id === storeId)
    if (catalog === undefined) { throw new Error('店铺不存在') }
    return catalog.store
  }

  async getProduct(storeId: number, productId: number): Promise<ProductDetail> {
    const products = await this.getProducts(storeId)
    const product = products.find((item: ProductSummary) => item.id === productId)
    const variants = MOCK_PRODUCT_SKUS.find((item: MockProductSkus) => item.productId === productId)
    if (product === undefined || variants === undefined) { throw new Error('商品不存在或已下架') }
    return { id: product.id, name: product.name, description: product.description,
      updatedAt: product.updatedAt, skus: variants.skus.slice() }
  }

  private async waitForMock(): Promise<void> {
    if (BrowseConfig.source !== 'mock') { throw new Error('真实浏览接口尚未接入') }
    await new Promise<void>((resolve) => { setTimeout(() => resolve(), BrowseConfig.delayMs) })
    if (BrowseConfig.scenario === BrowseScenario.FailOnce && !this.hasFailed) {
      this.hasFailed = true
      throw new Error('演示加载失败，请重试')
    }
  }

  async getStores(): Promise<StoreSummary[]> {
    await this.waitForMock()
    if (BrowseConfig.scenario === BrowseScenario.EmptyStores) { return [] }
    return MOCK_CATALOGS.map((catalog: MockStoreCatalog) => catalog.store)
  }

  async getProducts(storeId: number): Promise<ProductSummary[]> {
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
