export enum BrowseScenario {
  Normal = 'normal',
  FailOnce = 'failOnce',
  FailProductsOnce = 'failProductsOnce',
  EmptyStores = 'emptyStores'
}

/** 故障验收切换 scenario，验收结束恢复 Normal。真实模式尚未实现。 */
export class BrowseConfig {
  static readonly source: string = 'mock'
  static readonly scenario: BrowseScenario = BrowseScenario.Normal
  static readonly delayMs: number = 240
}
