/** 仅计算演示预估小计。真实订单金额必须以后端为准。 */
export class Money {
  static cents(value: number): number { return Math.round(value * 100) }
  static format(cents: number): string { return (cents / 100).toFixed(2) }
}
