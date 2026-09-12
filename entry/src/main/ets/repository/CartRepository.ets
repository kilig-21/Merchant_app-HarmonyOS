import { CartItem } from '../model/CartModels'
import { MOCK_CATALOGS, MockStoreCatalog } from '../mock/BrowseMockData'
import { MOCK_PRODUCT_SKUS, MockProductSkus } from '../mock/ProductMockData'
import { ProductSku } from '../model/ProductModels'
import { ProductSummary } from '../model/StoreModels'
import { BrowseConfig } from '../config/BrowseConfig'

/** 仅在本次 App 进程中保存的 Mock 购物车，不与账号同步。 */
export class CartRepository {
  private items: CartItem[] = []
  private nextId: number = 4001

  private async wait(): Promise<void> {
    if (BrowseConfig.source !== 'mock') { throw new Error('购物车接口尚未接入') }
    await new Promise<void>((resolve) => { setTimeout(() => resolve(), BrowseConfig.delayMs) })
  }

  async list(): Promise<CartItem[]> {
    await this.wait()
    return this.items.slice()
  }

  async add(skuId: number, quantity: number): Promise<CartItem[]> {
    await this.wait()
    const variants = MOCK_PRODUCT_SKUS.find((item: MockProductSkus) =>
      item.skus.some((sku: ProductSku) => sku.id === skuId))
    const sku = variants?.skus.find((item: ProductSku) => item.id === skuId)
    const catalog = MOCK_CATALOGS.find((item: MockStoreCatalog) =>
      item.products.some((product: ProductSummary) => product.id === variants?.productId))
    const product = catalog?.products.find((item: ProductSummary) => item.id === variants?.productId)
    if (sku === undefined || catalog === undefined || product === undefined) {
      throw new Error('商品或规格已不存在，请重新选择')
    }
    if (!Number.isInteger(quantity) || quantity < 1) { throw new Error('请选择有效的购买数量') }
    const old = this.items.find((item: CartItem) => item.skuId === skuId)
    const total = quantity + (old === undefined ? 0 : old.quantity)
    if (total > sku.availableStock) { throw new Error('所选数量加上购物车已有数量，已超过库存') }
    const entry: CartItem = {
      id: old === undefined ? this.nextId++ : old.id,
      skuId: sku.id, productId: product.id, productName: product.name, skuName: sku.skuName,
      storeId: catalog.store.id, storeName: catalog.store.name,
      salePrice: sku.salePrice, availableStock: sku.availableStock, quantity: total,
      purchasable: true, unavailableReason: null
    }
    this.items = old === undefined ? this.items.concat([entry]) :
      this.items.map((item: CartItem) => item.id === old.id ? entry : item)
    return this.items.slice()
  }
}
