export enum BrowseScenario {
  Normal = 'normal',
  FailOnce = 'failOnce',
  FailProductsOnce = 'failProductsOnce',
  EmptyStores = 'emptyStores'
}

export enum BrowseSource {
  Mock = 'mock',
  Remote = 'remote'
}

/** Mock 只供无后端时演示；切换到 Remote 后，接口失败必须直接展示失败状态。 */
export class BrowseConfig {
  static readonly source: BrowseSource = BrowseSource.Remote
  static readonly scenario: BrowseScenario = BrowseScenario.Normal
  static readonly delayMs: number = 240
}
