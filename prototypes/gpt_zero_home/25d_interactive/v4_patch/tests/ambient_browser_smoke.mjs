import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import path from 'node:path';

// Small host-free test of the atmosphere; does NOT claim Godot/mobile acceptance.
const project = path.resolve(import.meta.dirname, '..');
const html = fs.readFileSync(path.join(project, 'index.html'), 'utf8');
const preview = fs.readFileSync(path.join(project, 'web/preview.js'), 'utf8');
assert.match(html, /id="hotspots">显示点位</);
assert.match(html, /id="ambient-canvas"/);
assert.match(html, /web\/ambient_25d\.js/);
assert.match(html, /id="motion">动态：开/);
assert.match(preview, /pins=false/);
assert.match(preview, /ambient\.setDusk\(dusk\)/);
assert.match(preview, /ambient\.setScene\(sceneId,p\.width,p\.height\)/);
assert.doesNotMatch(preview, /brightness\(\.78\) saturate\(\.84\) sepia/);
let operations = 0;
const context = {
  globalAlpha: 1,
  set fillStyle(v){operations++},
  set strokeStyle(v){operations++},
  set lineWidth(v){operations++},
  createRadialGradient:() => ({addColorStop(){operations++}}),
  clearRect(){operations++}, fillRect(){operations++},
  beginPath(){}, arc(){operations++}, ellipse(){operations++},
  fill(){operations++}, stroke(){operations++}, save(){},restore(){},
  translate(){},rotate(){},
};
const canvas={width:1,height:1,style:{},getContext:()=>context};
const fakeDoc={hidden:false,addEventListener(){},removeEventListener(){}};
const env={
  document:fakeDoc,
  window:{matchMedia:()=>({matches:false})},
  performance:{now:()=>1000},
  requestAnimationFrame:()=>7,
  cancelAnimationFrame:()=>{},
  Math, console,
};
vm.createContext(env);
vm.runInContext(fs.readFileSync(path.join(project,'web/ambient_25d.js'),'utf8'),env);
const Atmosphere=env.window.FantasiaAmbient25D;
assert.equal(typeof Atmosphere,'function');
const fx=new Atmosphere(canvas);
fx.setScene('exterior',1536,1024);
assert.equal(canvas.width,1536);assert.equal(canvas.height,1024);
fx.setDusk(true);
fx.render(1500);assert.equal(fx.dusk,true);
fx.setScene('interior',1448,1086);
fx.render(2500);assert.equal(canvas.width,1448);
fx.setMotion(false);assert.equal(fx.running,false);
fx.destroy();assert(operations>250);
assert.doesNotMatch(fs.readFileSync(path.join(project,'web/ambient_25d.js'),'utf8'),/fetch\(|XMLHttpRequest|navigator\.geolocation|localStorage/);
console.log('AMBIENT_BROWSER_SOURCE_OK: no hot-spot clutter, ambient dusk/day, paint-only particles, 2 scene sizes, no network intents');