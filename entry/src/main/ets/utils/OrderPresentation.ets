import { OrderDetail } from '../model/OrderModels'

export class OrderPresentation {
  static status(value: string): string {
    if (value === 'PENDING_PAYMENT') { return '待付款' }
    if (value === 'PAID') { return '已付款' }
    if (value === 'CANCELLED') { return '已取消' }
    if (value === 'CLOSED') { return '已关闭' }
    return '状态更新中'
  }
  static filter(orders: OrderDetail[], status: string): OrderDetail[] {
    return orders.filter((order: OrderDetail) => status.length === 0 || order.status === status)
  }
  static quantity(order: OrderDetail): number {
    return order.items.reduce((sum: number, item) => sum + item.quantity, 0)
  }
  static date(value: string): string { return value.replace('T', ' ').substring(0, 16) }
}
