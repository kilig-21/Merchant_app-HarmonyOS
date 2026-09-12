import { BrowseConfig, BrowseScenario } from '../config/BrowseConfig'
import { MOCK_CATALOGS, MockStoreCatalog } from '../mock/BrowseMockData'
import { ProductSummary, StoreSummary } from '../model/StoreModels'

export class BrowseRepository {
  private hasFailed: boolean = false

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
