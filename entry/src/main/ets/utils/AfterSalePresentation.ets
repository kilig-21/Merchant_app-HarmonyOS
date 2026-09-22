/** 售后状态仅按服务端值展示，不由客户端推断退款结果。 */
export class AfterSalePresentation {
  static status(value: string): string {
    if (value === 'SUBMITTED') { return '已提交' }
    if (value === 'REVIEWING') { return '审核中' }
    if (value === 'APPROVED') { return '审核通过' }
    if (value === 'REJECTED') { return '审核未通过' }
    return '状态更新中'
  }

  static date(value: string | null): string {
    if (value === null || value.length === 0) { return '—' }
    return value.replace('T', ' ').substring(0, 16)
  }
}
