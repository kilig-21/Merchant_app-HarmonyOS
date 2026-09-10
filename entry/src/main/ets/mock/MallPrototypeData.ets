/**
 * 仅供界面原型使用的展示数据。
 * 接入 Repository 前，页面只从这里取样例；组件不发起网络请求，也不计算交易结果。
 */
export interface PrototypeStore {
  name: string
  tag: string
  tone: string
  mark: string
}

export const PROTOTYPE_STORES: PrototypeStore[] = [
  { name: '山野杂货铺', tag: '器物 · 香氛 · 日用', tone: '#4C7B67', mark: '⌂' },
  { name: '浮光咖啡研究所', tag: '咖啡 · 烘焙 · 风味', tone: '#D47B58', mark: '☕' },
  { name: '慢慢生活馆', tag: '织物 · 收纳 · 灵感', tone: '#AA9A77', mark: '✺' }
]

export const PROTOTYPE_CART_TOTAL: string = '¥ 134'
export const PROTOTYPE_PRODUCT_NAME: string = '云南小粒咖啡豆'
export const PROTOTYPE_PRODUCT_PRICE: string = '¥ 58'
