/* 执行真实 ArkTS 数据/状态逻辑，不模拟 ArkUI 渲染。
 * node scripts/check-shopping.cjs <SDK 的 typescript 模块路径>
 */
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const assert = require('node:assert/strict');
const compiler = process.argv[2] || process.env.HARMONY_TYPESCRIPT;
if (!compiler) throw new Error('请传入 DevEco SDK ets-loader/node_modules/typescript 路径');
const ts = require(compiler);
const sourceRoot = path.resolve(__dirname, '../entry/src/main/ets');
const cache = new Map();
global.Observed = value => value;
function load(relative) {
  const full = path.resolve(sourceRoot, relative);
  if (cache.has(full)) return cache.get(full).exports;
  const mod = new Module(full);
  cache.set(full, mod);
  mod.require = id => id.startsWith('.') ? load(path.relative(sourceRoot, path.resolve(path.dirname(full), id + '.ets'))) : require(id);
  const result = ts.transpileModule(fs.readFileSync(full, 'utf8'), {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS, experimentalDecorators: true }
  });
  mod._compile(result.outputText, full);
  return mod.exports;
}
async function run() {
  const { BrowseConfig, BrowseScenario } = load('config/BrowseConfig.ets');
  const { BrowseRepository } = load('repository/BrowseRepository.ets');
  const { CartRepository } = load('repository/CartRepository.ets');
  const { CartViewModel } = load('viewmodel/CartViewModel.ets');
  const { Money } = load('utils/Money.ets');
  BrowseConfig.delayMs = 0;
  const browse = new BrowseRepository();
  const stores = await browse.getStores();
  const skuIds = new Set();
  for (const store of stores) {
    const products = await browse.getProducts(store.id);
    assert.equal(products.length, store.productCount);
    for (const product of products) {
      const detail = await browse.getProduct(store.id, product.id);
      assert.equal(Math.min(...detail.skus.map(s => s.salePrice)), product.minSalePrice);
      assert.equal(detail.skus.reduce((n, s) => n + s.availableStock, 0), product.totalAvailableStock);
      for (const sku of detail.skus) { assert.ok(!skuIds.has(sku.id)); skuIds.add(sku.id); }
    }
  }
  await assert.rejects(browse.getProduct(1002, 2001), /不存在/);
  assert.equal((await browse.getProducts(1003)).length, 0);
  BrowseConfig.scenario = BrowseScenario.FailOnce;
  const retry = new BrowseRepository();
  await assert.rejects(retry.getStores());
  assert.equal((await retry.getStores()).length, 3);
  BrowseConfig.scenario = BrowseScenario.Normal;
  const repo = new CartRepository();
  for (const quantity of [0, -1, 1.5, NaN]) { await assert.rejects(repo.add(3001, quantity)); }
  await assert.rejects(repo.add(3111, 1));
  await assert.rejects(repo.add(-1, 1));
  const first = await repo.add(3001, 2);
  const merged = await repo.add(3001, 1);
  assert.equal(merged.length, 1);
  assert.equal(merged[0].id, first[0].id);
  assert.equal(merged[0].quantity, 3);
  await repo.add(3002, 1);
  await repo.add(3101, 2);
  assert.equal((await repo.list()).length, 3);
  const before = JSON.stringify(await repo.list());
  await assert.rejects(repo.add(3001, 18));
  assert.equal(JSON.stringify(await repo.list()), before, '失败不能部分修改购物车');
  const vm = new CartViewModel();
  const concurrent = await Promise.all([vm.add(3001, 1), vm.add(3001, 1)]);
  assert.deepEqual(concurrent, [true, false], '提交中重复加购只能处理一次');
  assert.equal(vm.count(), 1);
  await vm.add(3101, 2);
  assert.equal(vm.groups().length, 2);
  assert.equal(vm.subtotal(), '244.00');
  await vm.load();
  assert.equal(vm.count(), 3);
  assert.equal(await vm.add(3001, 999), false);
  assert.equal(vm.count(), 3);
  assert.ok(vm.error.length > 0);
  assert.equal(Money.format(Money.cents(42.5) * 3 + Money.cents(0.1) * 3), '127.80');
  assert.equal((await browse.searchProducts('咖啡')).length, 2);
  assert.equal((await browse.searchProducts(' 山野杂货铺 ')).length, 3);
  assert.equal((await browse.searchProducts('绝不存在的关键词')).length, 0);
  assert.equal((await browse.searchProducts('')).length, 5);
  const choose = new CartViewModel();
  await choose.add(3001, 2);
  await choose.add(3002, 1);
  await choose.add(3101, 2);
  assert.equal(choose.allSelected(), true);
  assert.equal(choose.selectedCount(), 5);
  assert.equal(choose.selectedSubtotal(), '610.00');
  const tea = choose.items.find(i => i.skuId === 3001);
  const gift = choose.items.find(i => i.skuId === 3002);
  const coffee = choose.items.find(i => i.skuId === 3101);
  choose.selectItem(tea.id, false);
  assert.equal(choose.allSelected(1001), false);
  assert.equal(choose.allSelected(1002), true);
  assert.equal(choose.selectedSubtotal(), '354.00');
  choose.selectStore(1001, false);
  assert.equal(choose.selectedSubtotal(), '116.00');
  choose.selectAll(false);
  assert.equal(choose.selectedCount(), 0);
  assert.equal(choose.selectedSubtotal(), '0.00');
  choose.selectStore(1001, true);
  await choose.update(tea.id, 3);
  assert.equal(choose.items.find(i => i.id === coffee.id).quantity, 2, '每个商品数量独立');
  assert.equal(choose.selectedSubtotal(), '622.00');
  await choose.load();
  assert.equal(choose.selectedIds.includes(coffee.id), false, '刷新不能擅自全选');
  const unchanged = JSON.stringify(choose.items);
  await choose.update(tea.id, 0);
  assert.ok(choose.error.length > 0);
  assert.equal(JSON.stringify(choose.items), unchanged);
  await choose.update(tea.id, 1000);
  assert.equal(JSON.stringify(choose.items), unchanged);
  await choose.remove([tea.id, -123]);
  assert.equal(JSON.stringify(choose.items), unchanged, '批量移除失败不能部分删除');
  await choose.remove([tea.id, gift.id]);
  assert.equal(choose.groups().length, 1);
  assert.equal(choose.selectedCount(), 0);
  assert.equal(choose.count(), 2);
  // 模拟服务端库存变化后重新读取，失效项必须退出勾选。
  const { MOCK_PRODUCT_SKUS } = load('mock/ProductMockData.ets');
  const coffeeSku = MOCK_PRODUCT_SKUS.find(p => p.productId === 2101).skus.find(s => s.id === 3101);
  const savedStock = coffeeSku.availableStock;
  choose.selectAll(true);
  coffeeSku.availableStock = 0;
  await choose.load();
  assert.equal(choose.items[0].purchasable, false);
  assert.equal(choose.selectedCount(), 0);
  choose.selectAll(true);
  assert.equal(choose.allSelected(), false);
  assert.equal(choose.selectedSubtotal(), '0.00');
  coffeeSku.availableStock = 1;
  await choose.load();
  assert.equal(choose.items[0].purchasable, false);
  await choose.update(coffee.id, 1);
  assert.equal(choose.items[0].purchasable, true);
  choose.selectAll(true);
  assert.equal(choose.selectedSubtotal(), '58.00');
  coffeeSku.availableStock = savedStock;
  await choose.remove([coffee.id]);
  assert.equal(choose.count(), 0);
  assert.equal(choose.groups().length, 0);
  assert.deepEqual(choose.selectedIds, []);
  const concurrentVm = new CartViewModel();
  await concurrentVm.add(3001, 1);
  const onlyId = concurrentVm.items[0].id;
  await Promise.all([concurrentVm.update(onlyId, 2), concurrentVm.remove([onlyId])]);
  assert.equal(concurrentVm.count(), 2, '写操作进行中，不交错处理另一个写操作');
  BrowseConfig.source = 'real';
  await assert.rejects(new CartRepository().list());
  BrowseConfig.source = 'mock';
  console.log('PASS: 商品/SKU/加购、跨店单选/店选/全选、独立数量、无效数量回滚、批量删除原子性、失效项/库存恢复、空车/角标计数、写操作互斥、搜索、金额精度、Mock 边界。');
}
run().catch(error => { console.error(error); process.exitCode = 1; });
