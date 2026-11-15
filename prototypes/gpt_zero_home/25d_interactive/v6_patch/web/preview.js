'use strict';
/* Zero-dependency phone preview of the same Godot image-space hotspots.
 * Taps only inspect; offline TEST actor is always labeled. No POST, no auth.
 */
const $ = id => document.getElementById(id);
const scene = $('scene'), stage = $('stage'), art = $('art'), pts = $('points'), people = $('people');
const txt = $('spotname'), desc = $('description'), status = $('status');
const choice = $('activity'), actBtn = $('doaction');
const ambient = new FantasiaAmbient25D($('ambient-canvas'));
ambient.attachArt(art);
ambient.attachLanternLayers(document.getElementById('lantern-plate'),document.getElementById('lantern-sprite'));
let data, sceneId='exterior', current='stone_table', dusk=false, pins=false, test=false, busy=false;
let testScene='exterior',testZone='stone_table',testAvatar=null,lastRevision=-1,publicPeople={};
let k=1,x=0,y=0,base=1,drag=null,travelToken=0;
const edges = {
 exterior:[['door','path'],['path','garden'],['garden','window'],['path','old_tree'],['path','book_corner'],['old_tree','book_corner'],['book_corner','stone_table'],['stone_table','riverside'],['stone_table','riverbank'],['riverside','riverbank'],['stone_table','stump'],['stump','path']],
 interior:[['house_entry','rest_corner'],['house_entry','writing_desk'],['rest_corner','window_corner'],['writing_desk','bookcase'],['window_corner','bookcase'],['rest_corner','writing_desk']]
};
function place(n,which=sceneId){return data[which]?.spots[n]}
function actionText(a){return {stay:'停留',sit:'坐下',read:'阅读',rest:'休息',enter_house:'进入木屋',exit_house:'回到院子'}[a] || a}
function labelAction(a){return actionText(a)}
function fit(reset=true){
 const w=scene.clientWidth,h=scene.clientHeight,p=data[sceneId];
 base = h>w*1.13? h/p.height : Math.min(w/p.width,h/p.height);
 if(reset){k=base; x=(w-k*p.width)/2;y=(h-k*p.height)/2}
 else clamp(); transform();
}
function clamp(){const p=data[sceneId],w=scene.clientWidth,h=scene.clientHeight;
 const minX=Math.min(0,w-k*p.width), maxX=Math.max(0,w-k*p.width);
 const minY=Math.min(0,h-k*p.height), maxY=Math.max(0,h-k*p.height);
 x=Math.min(maxX,Math.max(minX,x));y=Math.min(maxY,Math.max(minY,y));}
function transform(){stage.style.transform=`translate(${x}px,${y}px) scale(${k})`}
function render(){
 const p=data[sceneId]; stage.style.width=p.width+'px';stage.style.height=p.height+'px';
 art.src=sceneId==='exterior'?'art/home_25d_exterior.png':'art/home_25d_interior.png';
 art.style.filter=dusk?'brightness(.97) saturate(.98) hue-rotate(-5deg)':'none';
 stage.classList.toggle('dusk',dusk);
 ambient.setScene(sceneId,p.width,p.height);
 ambient.setDusk(dusk);
 $('room').textContent=sceneId==='exterior'?'看室内':'看院子';
 $('dusk').textContent=dusk?'上午':'黄昏';
 $('title').textContent=sceneId==='exterior'?'幻想乡 · 初代家园（2.5D）':'幻想乡 · 木屋内部（2.5D）';
 pts.replaceChildren();Object.entries(p.spots).forEach(([id,v])=>{
  const node=document.createElement('span');node.className='spot'+(!pins?' hidden':'')+(current===id?' selected':'');node.dataset.id=id;
  node.style.left=v.x+'px';node.style.top=v.y+'px';pts.appendChild(node);
 });
 renderPeople();fit();select(current in p.spots?current:(sceneId==='exterior'?'stone_table':'house_entry'));
}
function select(id){const p=place(id);if(!p)return;current=id;txt.textContent='📍 '+p.name;
 desc.textContent=p.info+` · 容量 ${p.capacity} · 可用：${p.activities.map(labelAction).join(' / ')}`;
 choice.replaceChildren();let acts=p.transition?[p.transition]:p.activities;
 for(const a of acts){const opt=document.createElement('option');opt.value=a;opt.textContent=actionText(a);choice.appendChild(opt)}
 actBtn.disabled=!test||busy;
 pts.querySelectorAll('.spot').forEach(el=>el.classList.toggle('selected',el.dataset.id===current));
}
function changeScene(next){if(!data[next])return;sceneId=next;current=next==='exterior'?'stone_table':'house_entry';render();}
function renderPeople(){people.replaceChildren();
 for(const [id,r] of Object.entries(publicPeople)){
  if(r.scene_id!==sceneId)continue;
  const v=place(r.zone);if(!v)continue;
  const node=document.createElement('div');node.className='person public';node.textContent='🧍';node.style.left=v.x+'px';node.style.top=v.y+'px';node.title=`${r.name}: ${r.zone} / ${r.activity}`;people.appendChild(node);
 }
 if(test&&testScene===sceneId){
  const v=place(testZone);testAvatar=document.createElement('div');testAvatar.className='person test';testAvatar.textContent='🧑';
  testAvatar.style.left=v.x+'px';testAvatar.style.top=v.y+'px';people.appendChild(testAvatar);
 }else testAvatar=null;
}
function route(from,to){if(from===to)return[to];let q=[from],seen=new Set([from]),prev={};
 while(q.length){let node=q.shift();if(node===to)break;
  for(const [a,b] of edges[testScene]){let other=a===node?b:(b===node?a:null);if(other&&!seen.has(other)){seen.add(other);prev[other]=node;q.push(other)}}
 }
 if(!seen.has(to))return[];let result=[to];while(result[0]!==from)result.unshift(prev[result[0]]);return result;
}
function testCorridor(a,b){
 if(testScene!=='interior')return [];
 if(a==='rest_corner'&&b==='window_corner')return [[576,796],[602,516]];
 if(a==='window_corner'&&b==='rest_corner')return [[602,516],[576,796]];
 if(a==='writing_desk'&&b==='bookcase')return [[1276,790],[1276,597]];
 if(a==='bookcase'&&b==='writing_desk')return [[1276,597],[1276,790]];
 if(a==='bookcase'&&b==='window_corner')return [[1050,590],[650,584]];
 if(a==='window_corner'&&b==='bookcase')return [[650,584],[1050,590]];
 return [];
}
const sleep=ms=>new Promise(resolve=>setTimeout(resolve,ms));
async function goTest(dest){const steps=route(testZone,dest);if(!steps.length)return false;
 for(const id of steps.slice(1)){
  if(!testAvatar)return false;
  const prev=place(testZone,testScene),target=place(id,testScene);
  let from=[prev.x,prev.y];
  for(const waypoint of [...testCorridor(testZone,id),[target.x,target.y]]){
   const time=Math.max(230,Math.min(1500,Math.hypot(waypoint[0]-from[0],waypoint[1]-from[1])*2.2));
   testAvatar.style.transition=`left ${time}ms linear,top ${time}ms linear`;
   testAvatar.style.left=waypoint[0]+'px';testAvatar.style.top=waypoint[1]+'px';
   await sleep(time+30);from=waypoint;
  }
  testZone=id;
 }
 return true;
}
async function act(){if(!test||busy)return;let p=place(current),a=choice.value;if(!p||!a||testScene!==sceneId){desc.textContent='测试居民不在当前场景，请切换视角。';return}
 busy=true;actBtn.disabled=true;try{
  await goTest(current);
  if(a==='enter_house'&&testScene==='exterior'&&current==='door'){
    testScene='interior';testZone='house_entry';changeScene('interior');desc.textContent='【模拟居民】进屋成功；真实 AI 的进门必须由服务端确认。';
  }else if(a==='exit_house'&&testScene==='interior'&&current==='house_entry'){
    testScene='exterior';testZone='door';changeScene('exterior');desc.textContent='【模拟居民】返回院子。';
  }else{desc.textContent=`【模拟居民，非真实 AI】已经在「${p.name}」${actionText(a)}。`}
 }finally{busy=false;actBtn.disabled=!test}
}
function enableTest(){test=!test;travelToken++;
 testScene=sceneId;testZone=sceneId==='exterior'?'stone_table':'house_entry';
 $('test').textContent=test?'关闭离线测试':'开启离线测试';actBtn.disabled=!test;
 status.textContent=test?'本地脚本测试居民 · 不是 AI':(lastRevision>=0?`公开世界版本 ${lastRevision}`:'离线预览 · 未接入真实 AI');
 renderPeople();select(current);
}
function applyPublic(packet){const allowed=['schema_version','world_id','revision','residents'];
 if(!packet||Object.keys(packet).some(k=>!allowed.includes(k))||packet.schema_version!==1||packet.world_id!=='fantasia.first_home.prototype')return false;
 if(!Number.isInteger(packet.revision)||packet.revision<=lastRevision||!Array.isArray(packet.residents)||packet.residents.length>24)return false;
 const cleaned={};for(const r of packet.residents){if(!r||Object.keys(r).some(k=>!['resident_id','name','scene_id','zone','activity','action','path_progress','pos'].includes(k)))return false;
  const sc=r.scene_id||'exterior',st=r.activity||r.action||'stay';
  if(!data[sc]?.spots?.[r.zone]||!['stay','move','sit','read','rest','decline','idle','moving','sitting','reading','resting','declined'].includes(st))return false;
  if(typeof r.resident_id!=='string'||r.resident_id.length>96||!r.resident_id||typeof r.name!=='string'||r.name.length>32||cleaned[r.resident_id])return false;
  cleaned[r.resident_id]={name:r.name,scene_id:sc,zone:r.zone,activity:st};
 }
 lastRevision=packet.revision;publicPeople=cleaned;renderPeople();if(!test)status.textContent=`公开世界 · ${Object.keys(cleaned).length} 位居民 · 版本 ${lastRevision}`;return true;
}
function startPublicPoll(){// Same-origin token-free preview only, never /observation or public POST.
 if(location.protocol!=='https:'||new URLSearchParams(location.search).get('public')!=='1')return;
 async function poll(){try{const response=await fetch('/public/world',{method:'GET',cache:'no-store',credentials:'omit',headers:{'Accept-Encoding':'identity'}});
  if(!response.ok)return;const raw=await response.text();if(raw.length>65536)return;applyPublic(JSON.parse(raw));}catch(_){status.textContent='公开世界暂不可用'}}
 poll();setInterval(poll,2000);
}
function pointer(e){return{x:e.clientX-scene.getBoundingClientRect().left,y:e.clientY-scene.getBoundingClientRect().top}}
scene.addEventListener('pointerdown',e=>{drag={pointer:e.pointerId,from:pointer(e),last:pointer(e),moved:false};scene.setPointerCapture(e.pointerId);scene.classList.add('dragging')});
scene.addEventListener('pointermove',e=>{if(!drag||drag.pointer!==e.pointerId)return;const p=pointer(e),dx=p.x-drag.last.x,dy=p.y-drag.last.y;if(Math.abs(p.x-drag.from.x)+Math.abs(p.y-drag.from.y)>9)drag.moved=true;if(drag.moved){x+=dx;y+=dy;clamp();transform()}drag.last=p});
scene.addEventListener('pointerup',e=>{if(!drag||drag.pointer!==e.pointerId)return;let wasMoved=drag.moved;drag=null;scene.classList.remove('dragging');if(wasMoved)return;
 const p=pointer(e),tx=(p.x-x)/k,ty=(p.y-y)/k;let best=null,d=Math.max(48,28/k);
 for(const[id,v]of Object.entries(data[sceneId].spots)){let dd=Math.hypot(tx-v.x,ty-v.y);if(dd<d){best=id;d=dd}}if(best)select(best)
});
scene.addEventListener('wheel',e=>{e.preventDefault();const p=pointer(e),ox=(p.x-x)/k,oy=(p.y-y)/k;k=Math.max(base*.8,Math.min(base*2.3,k*(e.deltaY<0?1.13:.885)));x=p.x-ox*k;y=p.y-oy*k;clamp();transform()},{passive:false});
$('room').addEventListener('click',()=>changeScene(sceneId==='exterior'?'interior':'exterior'));
$('dusk').addEventListener('click',()=>{dusk=!dusk;art.style.filter=dusk?'brightness(.97) saturate(.98) hue-rotate(-5deg)':'none';stage.classList.toggle('dusk',dusk);ambient.setDusk(dusk);$('dusk').textContent=dusk?'上午':'黄昏'});
$('motion').addEventListener('click',()=>{ambient.setMotion(!ambient.running);$('motion').textContent=ambient.running?'动态：开':'动态：关'});
$('hotspots').addEventListener('click',()=>{pins=!pins;$('hotspots').textContent=pins?'隐藏点位':'显示点位';pts.querySelectorAll('.spot').forEach(el=>el.classList.toggle('hidden',!pins))});
$('test').addEventListener('click',enableTest);actBtn.addEventListener('click',act);
window.addEventListener('resize',()=>fit());
try{data=JSON.parse(document.getElementById('points-data').textContent);render();startPublicPoll()}catch(e){status.textContent='交互地点数据载入失败';console.error(e)}
// Tests can inspect this read-only-only interface without exposing a mutation API.
window.Fantasia25DPreview={applyPublic,changeScene,getState:()=>({sceneId,current,test,lastRevision,pins,dusk,motion:ambient.running})};