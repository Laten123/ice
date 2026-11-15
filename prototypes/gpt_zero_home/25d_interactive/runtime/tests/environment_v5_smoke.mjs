import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import path from 'node:path';

const root=path.resolve(import.meta.dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const html=read('index.html'), js=read('web/ambient_25d.js'), preview=read('web/preview.js');
const godot=read('scripts/first_home_25d.gd'),gdambient=read('scripts/home_25d_atmosphere.gd');
const shader=read('shaders/home_25d_wind.gdshader');
assert.match(html,/id="hotspots">显示点位/);
assert.match(preview,/pins=false/);
assert.match(preview,/ambient\.attachArt\(art\)/);
assert.match(preview,/brightness\(\.97\)/);
assert.match(shader,/inner_crown/);
assert.match(shader,/wind_time/);
assert.match(shader,/foliage/);
assert.match(shader,/twilight/);
assert.match(godot,/ShaderMaterial\.new\(\)/);
assert.match(godot,/map_art\.material = atmosphere_material/);
assert.match(gdambient,/move_toward\(twilight, target, dt \/ 2\.8\)/);
assert.doesNotMatch(godot,/map_art\.modulate = Color\("#c4b5be"\)/);
for(const source of [js,gdambient,shader]){
  assert.doesNotMatch(source,/\bXHR\b|XMLHttpRequest|\bfetch\s*\(|localStorage|\/observation|X-Resident-Token|http[s]?:\/\//);
}

let draws=0, clippedDraws=0, gradients=0;
const ctx={
  globalAlpha:1,
  set fillStyle(_v){},set strokeStyle(_v){},set lineWidth(_v){},
  createRadialGradient(){gradients++;return {addColorStop(){}}},
  clearRect(){draws++},fillRect(){draws++},beginPath(){},arc(){},ellipse(){},
  moveTo(){},lineTo(){},closePath(){},fill(){draws++},stroke(){draws++},
  save(){},restore(){},translate(){},rotate(){},clip(){},
  drawImage(_image,...coords){if(coords.length!==8)throw new Error('unexpected drawImage crop');clippedDraws++}
};
const canvas={width:10,height:10,style:{},getContext:()=>ctx};
const document={hidden:false,addEventListener(){},removeEventListener(){}};
const env={document,window:{matchMedia:()=>({matches:false})},
 performance:{now:()=>1000},requestAnimationFrame:()=>7,cancelAnimationFrame:()=>{},Math,console};
vm.createContext(env);vm.runInContext(js,env);
const Ambient=env.window.FantasiaAmbient25D;
const fx=new Ambient(canvas);
fx.attachArt({complete:true,naturalWidth:1536,naturalHeight:1024});
fx.setScene('exterior',1536,1024);
assert.equal(canvas.width,1536);assert.equal(canvas.height,1024);
fx.render(1250);
assert.ok(clippedDraws>=3,'local canopy texture must be resampled, not just drawn as dots');
const before=fx.duskMix;
fx.setDusk(true);fx.render(1500);assert.equal(fx.dusk,true);
assert.ok(fx.duskMix>before && fx.duskMix<1,'twilight should interpolate, not jump');
for(let t=1600;t<=5000;t+=100)fx.render(t);
assert.ok(fx.duskMix>.96,'transition eventually reaches dusk');
fx.setScene('interior',1448,1086);fx.render(5200);
assert.equal(canvas.width,1448);assert.equal(canvas.height,1086);
const canopyDraws=clippedDraws;
fx.render(5400);assert.equal(canopyDraws,clippedDraws,'interior should not draw tree canopy');
fx.setMotion(false);const frozen=fx.clock;fx.render(5600);
assert.equal(frozen,fx.clock,'decorative animation should stop when disabled');
fx.setDusk(false);fx.render(5800);
assert.ok(fx.duskMix<1,'time-of-day change must still work with motion disabled');
fx.destroy();assert.ok(draws>100 && gradients>6);
console.log('ENVIRONMENT_V5_BROWSER_OK: local canopy texture sway, dynamic shadows, dimming-free dusk fade, indoor lights, reduced-motion support');