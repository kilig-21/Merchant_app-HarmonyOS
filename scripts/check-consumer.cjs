/* 消费者端回归：运行真实 ArkTS 状态类，以假接口验证失败恢复，不连接后端。 */
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const assert = require('node:assert/strict');
const ts = require(process.argv[2] || process.env.HARMONY_TYPESCRIPT);
const root = path.resolve(__dirname, '../entry/src/main/ets');
const cache = new Map();
global.Observed = value => value;
function load(relative) {
  const full = path.resolve(root, relative);
  if (cache.has(full)) return cache.get(full).exports;
  const mod = new Module(full);
  cache.set(full, mod);
  mod.require = id => {
    if (id === '@kit.NetworkKit') return { http: { RequestMethod: { GET: 'GET', POST: 'POST', PUT: 'PUT', DELETE: 'DELETE' } } };
    if (id === '@kit.ArkData') return { preferences: {} };
    if (id === '@kit.AbilityKit') return {};
    return id.startsWith('.') ? load(path.relative(root, path.resolve(path.dirname(full), id + '.ets'))) : require(id);
  };
  const result = ts.transpileModule(fs.readFileSync(full, 'utf8'), {
    compilerOptions: { target: ts.ScriptTarget.ES2021, module: ts.ModuleKind.CommonJS, experimentalDecorators: true }
  });
  mod._compile(result.outputText, full);
  return mod.exports;
}
async function run() {
  const { SessionViewModel } = load('viewmodel/SessionViewModel.ets');
  const { SessionRepository } = load('repository/SessionRepository.ets');
  const { AuthApi } = load('api/AuthApi.ets');
  const { HttpClient } = load('network/HttpClient.ets');
  const { ApiError, ApiErrorKind } = load('network/ApiError.ets');
  const user = { id: 1, username: 'consumerA', userType: 'CONSUMER', tenantId: null };
  let token = '';
  let cleared = 0;
  HttpClient.setAccessToken = value => { token = value; };
  HttpClient.clearAccessToken = () => { token = ''; };
  SessionRepository.load = async () => ({ accessToken: 'test-only', user });
  SessionRepository.clear = async () => { cleared++; };
  SessionRepository.save = async () => {};
  AuthApi.getCurrentUser = async () => { throw new ApiError(ApiErrorKind.Network, 'offline'); };
  const offline = new SessionViewModel();
  await offline.restore({});
  assert.equal(offline.username, 'consumerA', '离线启动不能自动退出');
  assert.equal(cleared, 0);
  assert.equal(offline.ready, true);
  AuthApi.getCurrentUser = async () => { throw new ApiError(ApiErrorKind.Http, 'expired', 401); };
  const expired = new SessionViewModel();
  await expired.restore({});
  assert.equal(expired.username, '');
  assert.equal(token, '');
  assert.equal(cleared, 1);
  let loginCount = 0;
  let finishLogin;
  AuthApi.login = () => { loginCount++; return new Promise(resolve => { finishLogin = resolve; }); };
  const account = new SessionViewModel();
  const first = account.signIn({}, 'consumerA', 'test-password', false);
  const second = await account.signIn({}, 'consumerA', 'test-password', false);
  assert.equal(second, false);
  assert.equal(loginCount, 1, '连点只能发起一次登录');
  finishLogin({ accessToken: 'test-only', user });
  assert.equal(await first, true);
  assert.equal(account.username, 'consumerA');
  await account.signOut({});
  assert.equal(account.username, '');
  assert.equal(token, '');

  const { CheckoutIntent } = load('viewmodel/CheckoutIntent.ets');
  const intent = new CheckoutIntent();
  const ids = [4, 8];
  const original = intent.begin(ids, 12);
  const key = intent.key;
  ids.push(19);
  assert.deepEqual(original.cartItemIds, [4, 8], '购物选择后续变化不能修改原提交');
  assert.strictEqual(intent.begin([99], 20), original, '结果不明时重试复用原请求');
  assert.equal(intent.key, key);
  assert.equal(intent.request.addressId, 12);
  intent.reset();
  assert.deepEqual(intent.begin([99], 20).cartItemIds, [99]);
  assert.equal(intent.request.addressId, 20);

  const { OrderPresentation } = load('utils/OrderPresentation.ets');
  const orders = [
    { id: 1, status: 'PENDING_PAYMENT', items: [{ quantity: 2 }, { quantity: 3 }] },
    { id: 2, status: 'PAID', items: [{ quantity: 1 }] },
    { id: 3, status: 'CANCELLED', items: [] }
  ];
  assert.deepEqual(OrderPresentation.filter(orders, 'PAID').map(x => x.id), [2]);
  assert.equal(OrderPresentation.filter(orders, '').length, 3);
  assert.equal(OrderPresentation.quantity(orders[0]), 5, '订单件数必须按购买数量累计');

  const { BrowseConfig, BrowseSource } = load('config/BrowseConfig.ets');
  BrowseConfig.source = BrowseSource.Mock;
  BrowseConfig.delayMs = 0;
  const { BrowseRepository } = load('repository/BrowseRepository.ets');
  const browse = new BrowseRepository();
  const pages = [];
  for (let page = 1; page <= 4; page++) pages.push(...await browse.searchProducts('', page, 2));
  assert.equal(pages.length, 5);
  assert.equal(new Set(pages.map(x => x.id)).size, 5, '翻页不能重复或漏商品');
  assert.deepEqual(await browse.searchProducts('', 4, 2), []);

  const { CartViewModel } = load('viewmodel/CartViewModel.ets');
  const item = { id: 2, storeId: 1001, quantity: 1, purchasable: true, availableStock: 10 };
  const partial = new CartViewModel({
    remove: async () => { throw new Error('第二项删除失败'); },
    list: async () => [item]
  });
  partial.items = [{ ...item, id: 1 }, item];
  partial.selectedIds = [1, 2];
  await partial.remove([1, 2]);
  assert.deepEqual(partial.items.map(x => x.id), [2], '部分删除失败后必须同步已删除项');
  assert.deepEqual(partial.selectedIds, [2]);
  assert.ok(partial.error.length > 0);
  console.log('PASS: 离线会话保留、401 失效、登录连点、退出清理、原请求重试、订单筛选/数量、商品分页、批量删除部分失败恢复。');
}
run().catch(error => { console.error(error); process.exitCode = 1; });
