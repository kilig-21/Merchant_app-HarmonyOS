/* 不连接后端的发布静态检查；个人证书与正式应用身份仅报告，不代填。 */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const childProcess = require('node:child_process');

const root = path.resolve(__dirname, '..');
function json(relative) {
  const source = fs.readFileSync(path.join(root, relative), 'utf8');
  return JSON.parse(source.replace(/,\s*([}\]])/g, '$1'));
}

const app = json('AppScope/app.json5').app;
const moduleProfile = json('entry/src/main/module.json5').module;
const backup = json('entry/src/main/resources/base/profile/backup_config.json');

assert.ok(typeof app.bundleName === 'string' && app.bundleName.length > 0, 'bundleName 不能为空');
assert.ok(Number.isInteger(app.versionCode) && app.versionCode > 0, 'versionCode 必须是正整数');
assert.match(app.versionName, /^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/, 'versionName 应使用语义版本');
assert.ok(moduleProfile.deviceTypes.includes('phone'), '当前消费者 App 必须支持 phone（包含常规手机与折叠屏手机形态）');
const permissions = (moduleProfile.requestPermissions || []).map(item => item.name);
assert.deepEqual(permissions, ['ohos.permission.INTERNET'], '权限应保持最小化，仅申请当前功能所需的网络权限');
assert.equal(backup.allowToBackupRestore, false, '保存登录令牌的应用不应允许系统备份恢复应用数据');

const tracked = childProcess.execFileSync('git', ['ls-files'], { cwd: root, encoding: 'utf8' }).split(/\r?\n/).filter(Boolean);
const secretPattern = /\.(?:p12|pfx|jks|keystore|cer|p7b|pem)$/i;
assert.equal(tracked.some(file => secretPattern.test(file)), false, '仓库中不能跟踪签名证书或私钥');

const warnings = [];
if (app.bundleName.startsWith('com.example.')) warnings.push('bundleName 仍为示例身份，正式发布前需由开发者确定永久包名');
if (app.vendor === 'example') warnings.push('vendor 仍为示例值，正式发布前需填写真实开发者主体');
const buildProfile = fs.readFileSync(path.join(root, 'build-profile.json5'), 'utf8');
if (buildProfile.includes('"signingConfigs": []')) warnings.push('尚未配置个人签名；请仅在本机 DevEco Studio 中配置，不要提交证书');

console.log(`PASS: 应用版本、设备类型、最小权限、备份策略与证书跟踪检查通过。`);
for (const warning of warnings) console.log(`WARN: ${warning}`);
