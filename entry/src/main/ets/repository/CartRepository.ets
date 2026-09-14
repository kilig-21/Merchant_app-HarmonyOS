import { CartItem } from '../model/CartModels'
import { MOCK_CATALOGS, MockStoreCatalog } from '../mock/BrowseMockData'
import { MOCK_PRODUCT_SKUS, MockProductSkus } from '../mock/ProductMockData'
import { ProductSku } from '../model/ProductModels'
import { ProductSummary } from '../model/StoreModels'
import { BrowseConfig } from '../config/BrowseConfig'
import { BrowseSource } from '../config/BrowseConfig'
import { CartApi } from '../api/CartApi'

/** 仅在本次 App 进程中保存的 Mock 购物车，不与账号同步。 */
export class CartRepository {
  private items: CartItem[] = []
  private nextId: number = 4001

  private async wait(): Promise<void> {
    if (BrowseConfig.source === BrowseSource.Remote) { return }
    await new Promise<void>((resolve) => { setTimeout(() => resolve(), BrowseConfig.delayMs) })
  }

  async list(): Promise<CartItem[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      this.items = await CartApi.list()
      return this.items.slice()
    }
    await this.wait()
    this.items = this.items.map((item: CartItem) => this.refreshed(item))
    return this.items.slice()
  }

  private refreshed(item: CartItem): CartItem {
    const catalog = MOCK_CATALOGS.find((entry: MockStoreCatalog) => entry.store.id === item.storeId)
    const product = catalog?.products.find((entry: ProductSummary) => entry.id === item.productId)
    const variants = MOCK_PRODUCT_SKUS.find((entry: MockProductSkus) => entry.productId === item.productId)
    const sku = variants?.skus.find((entry: ProductSku) => entry.id === item.skuId)
    const availableStock = sku === undefined || product === undefined ? 0 : sku.availableStock
    const purchasable = availableStock > 0 && item.quantity <= availableStock
    return { id: item.id, skuId: item.skuId, productId: item.productId, productName: item.productName,
      skuName: sku === undefined ? item.skuName : sku.skuName,
      storeId: item.storeId, storeName: item.storeName,
      salePrice: sku === undefined ? item.salePrice : sku.salePrice,
      availableStock: availableStock, quantity: item.quantity, purchasable: purchasable,
      unavailableReason: purchasable ? null : availableStock > 0 ? '库存不足，请减少数量' : '商品暂时不可购买' }
  }

  async update(itemId: number, quantity: number): Promise<CartItem[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      await CartApi.update(itemId, quantity)
      return await this.list()
    }
    await this.wait()
    const item = this.items.find((entry: CartItem) => entry.id === itemId)
    if (item === undefined) { throw new Error('购物车商品已不存在，请刷新') }
    const current = this.refreshed(item)
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > current.availableStock) {
      throw new Error('购买数量需在 1 件与当前库存之间')
    }
    current.quantity = quantity
    current.purchasable = true
    current.unavailableReason = null
    this.items = this.items.map((entry: CartItem) => entry.id === itemId ? current : entry)
    return this.items.slice()
  }

  async remove(itemIds: number[]): Promise<CartItem[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      if (itemIds.length === 0) { throw new Error('请重新选择要移除的商品') }
      for (const itemId of itemIds) {
        await CartApi.remove(itemId)
      }
      return await this.list()
    }
    await this.wait()
    if (itemIds.length === 0 || !itemIds.every((id: number) => this.items.some((item: CartItem) => item.id === id))) {
      throw new Error('请重新选择要移除的商品')
    }
    this.items = this.items.filter((item: CartItem) => !itemIds.includes(item.id))
    return this.items.slice()
  }

  async add(skuId: number, quantity: number): Promise<CartItem[]> {
    if (BrowseConfig.source === BrowseSource.Remote) {
      await CartApi.add(skuId, quantity)
      return await this.list()
    }
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
