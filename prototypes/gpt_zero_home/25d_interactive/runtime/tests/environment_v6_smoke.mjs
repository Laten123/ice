import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const root=path.resolve(import.meta.dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const html=read('index.html'),js=read('web/ambient_25d.js'),gd=read('scripts/home_25d_atmosphere.gd');
const shader=read('shaders/home_25d_wind.gdshader');
for(const p of ['art/layers/tree_lantern_clean_plate.png','art/layers/tree_lantern_sprite.png']){
 const data=fs.readFileSync(path.join(root,p));
 assert.equal(data.subarray(0,8).toString('hex'),'89504e470d0a1a0a',`${p} is not a PNG`);
}
const readPng=p=>{const data=fs.readFileSync(path.join(root,p));return [data.readUInt32BE(16),data.readUInt32BE(20)]};
assert.deepEqual(readPng('art/layers/tree_lantern_clean_plate.png'),[77,104]);
assert.deepEqual(readPng('art/layers/tree_lantern_sprite.png'),[72,85]);
assert.deepEqual(readPng('art/home_25d_exterior.png'),[1536,1024]);
assert.match(html,/id="lantern-plate"/);
assert.match(html,/id="lantern-sprite"/);
assert.match(read('web/preview.js'),/attachLanternLayers\(/);
assert.match(gd,/_draw_swing_lantern/);
assert.match(gd,/SHORE_SHIMMERS/);
assert.match(shader,/exterior_window/);
assert.match(shader,/lit_mask/);
for(const s of [js,gd,shader])assert.doesNotMatch(s,/\bfetch\s*\(|\/observation|X-Resident-Token|\bPOST\b|localStorage/);
const ops=[];
const ctx={
  globalAlpha:1,filter:'none',
  set fillStyle(_s){},set strokeStyle(_s){},set lineWidth(_v){},
  createRadialGradient(){return {addColorStop(){}}},
  clearRect(){},fillRect(){},beginPath(){},arc(){},ellipse(){},
  moveTo(){},lineTo(){},closePath(){},fill(){},stroke(){},
  save(){},restore(){},translate(...v){ops.push(['translate',...v])},
  rotate(a){ops.push(['rotate',a])},clip(){},
  drawImage(img,...rest){ops.push(['image',img.kind,...rest])}
};
const canvas={width:0,height:0,style:{},getContext:()=>ctx};
const doc={hidden:false,addEventListener(){},removeEventListener(){}};
const host={document:doc,window:{matchMedia:()=>({matches:false})},performance:{now:()=>1000},requestAnimationFrame:()=>7,cancelAnimationFrame(){},Math,console};
vm.createContext(host);vm.runInContext(js,host);
const fx=new host.window.FantasiaAmbient25D(canvas);
const original={kind:'original',complete:true,naturalWidth:1536,naturalHeight:1024};
const plate={kind:'plate',complete:true,naturalWidth:77,naturalHeight:104};
const sprite={kind:'sprite',complete:true,naturalWidth:72,naturalHeight:85};
fx.attachArt(original);fx.attachLanternLayers(plate,sprite);
fx.setScene('exterior',1536,1024);
fx.render(2000);
assert.ok(ops.some(e=>e[0]==='image'&&e[1]==='plate'&&e[2]===570&&e[3]===330),'static lamp must be erased with the local clean plate');
assert.ok(ops.some(e=>e[0]==='image'&&e[1]==='sprite'&&e[2]===-32&&e[3]===11),'swinging lantern cutout is missing');
assert.ok(ops.some(e=>e[0]==='translate'&&e[1]===603&&e[2]===335),'fixed branch pivot is wrong');
assert.ok(ops.some(e=>e[0]==='rotate'&&Math.abs(e[1])>.00001),'lantern should genuinely rotate with wind');
fx.setDusk(true);for(let t=2100;t<5500;t+=120)fx.render(t);
assert.ok(ops.some(e=>e[0]==='image'&&e[1]==='original'&&e[2]===881),'dusk glass must preserve warm window pixels');
fx.setMotion(false);ops.length=0;const frozen=fx.clock;
fx.render(5700);
assert.equal(fx.clock,frozen,'paused environment clock must stop');
assert.ok(ops.some(e=>e[0]==='rotate'&&e[1]===0),'lamp should return to static orientation when animation is off');
fx.setScene('interior',1448,1086);ops.length=0;fx.render(5800);
assert.equal(ops.some(e=>e[0]==='image'&&e[1]==='plate'),false,'outdoor lantern must not render inside the house');
fx.destroy();
console.log('ENVIRONMENT_V6_BROWSER_OK: moving lantern, clean plate, window emissive, water shimmer, freeze and indoor isolation');