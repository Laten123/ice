'use strict';
/**
 * V5 VISUAL-ONLY 2.5D atmosphere, with image-space coordinates matching Godot.
 * No input, no resident tokens, no paths, no API calls, no land allocation.
 * Keeps the two approved, unmodified PNG illustrations as the source imagery.
 */
class FantasiaAmbient25D {
  constructor(canvas) {
    this.canvas=canvas;
    this.ctx=canvas.getContext('2d',{alpha:true});
    this.scene='exterior'; this.dusk=false; this.duskMix=0;
    this.running=!window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    this.clock=0; this.prevNow=null; this.lastFrame=0; this.artImage=null;
    this.visibilityHandler=()=>{this.prevNow=null;this.lastFrame=0};
    document.addEventListener('visibilitychange',this.visibilityHandler);
    this.loop=this.loop.bind(this);
    this.frameHandle=requestAnimationFrame(this.loop);
    this.leaves=Array.from({length:24},(_,i)=>({
      x:190+(i*137%545),y:34+(i*109%575),speed:8+(i%7)*3,
      drift:10+(i%4)*3,phase:i*2.17,size:3+i%3,
      color:['#c9dd71','#f0d48c','#eaadcb','#b3d56b','#dae287'][i%5]
    }));
  }
  attachArt(image){this.artImage=image}
  setScene(scene,width,height){
    this.scene=scene;this.canvas.width=width;this.canvas.height=height;
    this.canvas.style.width=width+'px';this.canvas.style.height=height+'px';
    this.render(performance.now());
  }
  setDusk(value){this.dusk=!!value;this.render(performance.now())}
  setMotion(value){this.running=!!value;this.render(performance.now())}
  loop(time){
    this.frameHandle=requestAnimationFrame(this.loop);
    if(document.hidden || time-this.lastFrame<33)return;
    if(!this.running && Math.abs(this.duskMix-(this.dusk?1:0))<.002)return;
    this.lastFrame=time;this.render(time);
  }
  advance(time){
    const dt=this.prevNow===null?0:Math.min(.1,Math.max(0,(time-this.prevNow)/1000));
    this.prevNow=time;
    if(this.running && !document.hidden)this.clock+=dt;
    const target=this.dusk?1:0;
    const step=dt/2.8;
    this.duskMix=target>this.duskMix?Math.min(target,this.duskMix+step):Math.max(target,this.duskMix-step);
  }
  circle(x,y,r,color,alpha=1){
    const c=this.ctx;c.globalAlpha=alpha;c.fillStyle=color;
    c.beginPath();c.arc(x,y,r,0,Math.PI*2);c.fill();c.globalAlpha=1;
  }
  oval(x,y,rx,ry,color,alpha=1){
    const c=this.ctx;c.globalAlpha=alpha;c.fillStyle=color;
    c.beginPath();c.ellipse(x,y,rx,ry,0,0,Math.PI*2);c.fill();c.globalAlpha=1;
  }
  glow(x,y,r,amount,rgb){
    if(amount<=0)return;
    const c=this.ctx,g=c.createRadialGradient(x,y,r*.02,x,y,r);
    g.addColorStop(0,`rgba(${rgb},${Math.min(.67,amount*.9)})`);
    g.addColorStop(.28,`rgba(${rgb},${Math.min(.28,amount*.36)})`);
    g.addColorStop(1,`rgba(${rgb},0)`);
    c.fillStyle=g;c.fillRect(x-r,y-r,r*2,r*2);
  }
  /**
   * Physically displace only the TEXTURE of leaves INSIDE the tree canopy.
   * Original art remains untouched. We do NOT move its outer silhouette,
   * trunk, or interaction/collision anchors; a true foreground rig is later.
   * Crop source before drawing to keep GPU work small on Android browsers.
   */
  canopyTextureSway(t){
    const img=this.artImage,c=this.ctx;
    if(!this.running || !img || !img.complete || img.naturalWidth!==1536 || this.scene!=='exterior')return;
    const masks=[
      {cx:432,cy:194,rx:178,ry:109,rect:[240,78,400,250],seed:0},
      {cx:514,cy:67,rx:128,ry:54,rect:[364,3,306,128],seed:1},
      {cx:301,cy:264,rx:106,ry:68,rect:[182,182,240,155],seed:2}
    ];
    for(const p of masks){
      const [sx,sy,sw,sh]=p.rect;
      const offset=Math.sin(t*.71+p.seed*1.34)*1.55+Math.sin(t*.33+p.seed)*.7;
      c.save();c.beginPath();c.ellipse(p.cx,p.cy,p.rx,p.ry,0,0,Math.PI*2);c.clip();
      c.drawImage(img,sx,sy,sw,sh,sx+offset,sy,sw,sh);
      c.restore();
    }
  }
  render(now){
    const c=this.ctx;if(!c)return;
    this.advance(now);
    const t=this.clock,d=this.duskMix;
    c.clearRect(0,0,this.canvas.width,this.canvas.height);
    const breath=(speed=1,phase=0)=>Math.sin(t*speed+phase);
    if(this.scene==='interior'){
      // Cold-blue dusk window light and warm hanging lamp are distinct sources.
      this.glow(356,259,233,.17*d,'133,158,227');
      this.glow(809,242,229,.075+.35*d+breath(1.4)*.005,'255,191,112');
      this.glow(1070,676,168,.11*d,'255,209,137');
      // Sunbeam narrows as dusk arrives, staying off the wall art and labels.
      c.save();c.globalAlpha=(1-d)*.039;c.fillStyle='#ffe6a9';
      const shift=this.running?breath(.34)*5:0;
      c.beginPath();c.moveTo(233+shift,375);c.lineTo(324+shift,375);
      c.lineTo(435+shift,767);c.lineTo(360+shift,767);c.closePath();c.fill();c.restore();
      this.oval(1277+(this.running?breath(.48)*5:0),856,19,5,'#183826',.063);
      if(this.running)for(let i=0;i<10;i++){
        const phase=((t*(3.2+i%4)+i*47)%480)/480;
        this.circle(215+i*73%390+breath(.45,i)*11,660-phase*480,1.8,'#fff4d5',
          (.08+.10*d)*Math.sin(Math.PI*phase));
      }
      return;
    }
    // A few actual image pixels inside the crown now sway by 1-2px; not a
    // duplicated moving tree laid on top of a fully painted static tree.
    this.canopyTextureSway(t);
    // Moving cast shadows track the same slow wind without moving fixed feet.
    const wind=breath(.73)*.62+breath(.31)*.38;
    for(let i=0;i<12;i++){
      const px=294+(i*43%330),py=445+(i*41%183);
      this.oval(px+wind*(3+i%4*2.5),py,13+i%3*7,3+i%2*2,'#183821',.027);
    }
    // Sunlit foliage flecks move with a different speed to avoid a sliding mask.
    for(let i=0;i<15;i++){
      c.fillStyle=i%3?'rgba(188,223,102,.19)':'rgba(245,233,129,.25)';
      c.fillRect(228+i*57%420+breath(.68+i*.03,i)*5,49+i*61%242,5+i%3*2,3);
    }
    const lamps=[[608,379,72],[1081,452,88],[1218,670,82],[575,544,67],
                 [911,277,94],[868,479,91],[1204,404,103]];
    for(let i=0;i<lamps.length;i++){
      const [x,y,r]=lamps[i];
      const sway=i===0 && this.running?breath(.61)*2.4:0;
      const flicker=1+breath(1.19,i*1.61)*.038;
      this.glow(x+sway,y,r*(1+d*.45),(.055+d*.38)*flicker,'255,198,105');
    }
    // Smoky, shaded uneven puffs, with different ages and lateral drift.
    if(this.running)for(let i=0;i<10;i++){
      const age=((t*(.135+i%3*.008)+i/10)%1);
      const x=1149+age*35+breath(.42,i)*6,y=117-age*151,a=(1-age)*.23;
      this.oval(x,y,9+age*9,7+age*10,'#f2e8e5',a);
      this.oval(x-5,y+2,6+age*5,6+age*4,'#9d9cb8',a*.34);
    }
    if(this.running)for(const p of this.leaves){
      const phase=((t*p.speed+p.y)%770)/770;
      const x=p.x+breath(.64,p.phase)*p.drift+phase*55;
      const y=37+phase*731;
      c.save();c.translate(Math.round(x),Math.round(y));
      c.rotate(breath(1.1,p.phase)*.45);
      c.globalAlpha=Math.min(1,phase*8,(1-phase)*7)*.73;
      c.fillStyle=p.color;c.fillRect(-p.size/2,-p.size/2,p.size,p.size);
      c.fillRect(1,p.size/2,2,2);c.restore();
    }
    // Water-only ripples; avoid the dock, stone table, lawn, tree or roof.
    if(this.running)for(let i=0;i<27;i++){
      const x=13+i*67%343,y=374+i*127%639;
      const safe=(x<100&&y>410)||(x<190&&y>875)||(x<350&&y>1004);
      if(!safe)continue;
      const wobble=breath(.65,i*1.3)*5;
      c.globalAlpha=.13+(breath(.95,i)+1)*.045;c.strokeStyle=d>.5?'#eac6df':'#b8e4f3';
      c.lineWidth=2;c.beginPath();c.moveTo(x+wobble,y);c.lineTo(x+14+wobble,y);
      c.stroke();c.globalAlpha=1;
    }
    if(d>.17 && this.running)for(let i=0;i<7;i++){
      const x=310+i*141%1000+breath(.43,i)*8;
      const y=440+i*67%337+breath(.37,i)*7;
      const pulse=Math.max(0,breath(1.1+i*.09,i*2.3));
      this.glow(x,y,17,d*pulse*.12,'255,241,175');
      this.circle(x,y,1.4,'#fff3bd',d*pulse*.55);
    }
  }
  destroy(){cancelAnimationFrame(this.frameHandle);document.removeEventListener('visibilitychange',this.visibilityHandler)}
}
window.FantasiaAmbient25D=FantasiaAmbient25D;