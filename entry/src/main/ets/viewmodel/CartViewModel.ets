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
  selectedIds: number[] = []
  message: string = ''
  private repository: CartRepository

  constructor(repository: CartRepository = new CartRepository()) { this.repository = repository }

  async load(): Promise<void> {
    if (this.busy) { return }
    this.busy = true
    this.loading = true
    this.error = ''
    this.message = ''
    try {
      this.items = await this.repository.list()
      this.reconcileSelection()
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
    this.message = ''
    try {
      this.items = await this.repository.add(skuId, quantity)
      const added = this.items.find((item: CartItem) => item.skuId === skuId)
      if (added !== undefined && !this.selectedIds.includes(added.id)) {
        this.selectedIds = this.selectedIds.concat([added.id])
      }
      this.reconcileSelection()
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

  selectable(item: CartItem): boolean {
    return item.purchasable && item.availableStock > 0 && item.quantity <= item.availableStock
  }

  private reconcileSelection(): void {
    this.selectedIds = this.selectedIds.filter((id: number) =>
      this.items.some((item: CartItem) => item.id === id && this.selectable(item)))
  }

  selectItem(itemId: number, selected: boolean): void {
    if (this.busy) { return }
    const item = this.items.find((entry: CartItem) => entry.id === itemId)
    if (item === undefined || !this.selectable(item)) { return }
    this.selectedIds = this.selectedIds.filter((id: number) => id !== itemId)
    if (selected) { this.selectedIds = this.selectedIds.concat([itemId]) }
  }

  selectStore(storeId: number, selected: boolean): void {
    if (this.busy) { return }
    const ids = this.items.filter((item: CartItem) => item.storeId === storeId && this.selectable(item))
      .map((item: CartItem) => item.id)
    this.selectedIds = this.selectedIds.filter((id: number) => !ids.includes(id))
    if (selected) { this.selectedIds = this.selectedIds.concat(ids) }
  }

  selectAll(selected: boolean): void {
    if (this.busy) { return }
    this.selectedIds = selected ? this.items.filter((item: CartItem) => this.selectable(item))
      .map((item: CartItem) => item.id) : []
  }

  allSelected(storeId: number = 0): boolean {
    const available = this.items.filter((item: CartItem) => this.selectable(item) && (storeId === 0 || item.storeId === storeId))
    return available.length > 0 && available.every((item: CartItem) => this.selectedIds.includes(item.id))
  }

  selectedItems(): CartItem[] {
    return this.items.filter((item: CartItem) => this.selectable(item) && this.selectedIds.includes(item.id))
  }

  selectedCount(): number {
    return this.selectedItems().reduce((sum: number, item: CartItem) => sum + item.quantity, 0)
  }

  selectedSubtotal(): string {
    return Money.format(this.selectedItems().reduce((sum: number, item: CartItem) =>
      sum + Money.cents(item.salePrice) * item.quantity, 0))
  }

  async update(itemId: number, quantity: number): Promise<void> {
    if (this.busy) { return }
    this.busy = true
    this.error = ''
    this.message = ''
    try {
      this.items = await this.repository.update(itemId, quantity)
      this.reconcileSelection()
    } catch (error) {
      this.error = (error as Error).message || '修改失败，请重试'
    } finally { this.busy = false }
  }

  async remove(itemIds: number[]): Promise<void> {
    if (this.busy) { return }
    this.busy = true
    this.error = ''
    this.message = ''
    try {
      this.items = await this.repository.remove(itemIds)
      this.reconcileSelection()
      this.message = '已从购物车移除'
    } catch (error) {
      this.error = (error as Error).message || '移除失败，请重试'
    } finally { this.busy = false }
  }
}
