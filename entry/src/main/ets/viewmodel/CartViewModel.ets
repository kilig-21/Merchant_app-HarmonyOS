import { CartGroup, CartItem } from '../model/CartModels'
import { CartRepository } from '../repository/CartRepository'
import { Money } from '../utils/Money'

@Observed
export class CartViewModel {
  items: CartItem[] = []
  busy: boolean = false
  loading: boolean = false
  error: string = ''
  initialized: boolean = false
  private repository: CartRepository

  constructor(repository: CartRepository = new CartRepository()) { this.repository = repository }

  async load(): Promise<void> {
    if (this.busy) { return }
    this.busy = true
    this.loading = true
    this.error = ''
    try {
      this.items = await this.repository.list()
      this.initialized = true
    } catch (error) {
      this.error = (error as Error).message || '购物车加载失败，请重试'
    } finally {
      this.loading = false
      this.busy = false
    }
  }

  async add(skuId: number, quantity: number): Promise<boolean> {
    if (this.busy) { return false }
    this.busy = true
    this.error = ''
    try {
      this.items = await this.repository.add(skuId, quantity)
      this.initialized = true
      return true
    } catch (error) {
      this.error = (error as Error).message || '加入失败，请重试'
      return false
    } finally { this.busy = false }
  }

  count(): number {
    return this.items.reduce((sum: number, item: CartItem) => sum + item.quantity, 0)
  }

  subtotal(): string {
    return Money.format(this.items.reduce((sum: number, item: CartItem) =>
      sum + Money.cents(item.salePrice) * item.quantity, 0))
  }

  groups(): CartGroup[] {
    const result: CartGroup[] = []
    this.items.forEach((item: CartItem) => {
      const group = result.find((entry: CartGroup) => entry.storeId === item.storeId)
      if (group === undefined) {
        result.push({ storeId: item.storeId, storeName: item.storeName, items: [item] })
      } else { group.items.push(item) }
    })
    return result
  }
}
