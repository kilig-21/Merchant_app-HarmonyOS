import { CheckoutRequest } from '../model/CheckoutModels'

/** 结果未确认时冻结原始请求，重试不能悄悄更换地址或购物项。 */
export class CheckoutIntent {
  request: CheckoutRequest | null = null
  key: string = ''
  begin(ids: number[], addressId: number): CheckoutRequest {
    if (this.request === null) {
      this.request = new CheckoutRequest(ids.slice(), addressId)
      this.key = 'checkout-' + Date.now() + '-' + Math.floor(Math.random() * 1000000000)
    }
    return this.request
  }
  reset(): void { this.request = null; this.key = '' }
}
