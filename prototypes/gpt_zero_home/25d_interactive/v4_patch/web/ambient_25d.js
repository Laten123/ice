'use strict';
/**
 * Purely decorative atmosphere for the ONE starter-home artboard.
 * No resident movement, pathing, API calls, permissions or hit testing.
 * Coordinates are taken directly from the approved 1536x1024 and 1448x1086 images.
 * All movement is visual-only, driven by monotonic animation time.
 */
class FantasiaAmbient25D {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d', {alpha: true});
    this.scene = 'exterior';
    this.dusk = false;
    this.running = !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    this.lastFrame = 0;
    this.zero = performance.now();
    this.visibilityHandler = () => { this.lastFrame = 0; };
    document.addEventListener('visibilitychange', this.visibilityHandler);
    this.leaves = Array.from({length: 19}, (_,i) => ({
      x: 190 + (i * 131 % 535), y: 45 + (i * 87 % 520),
      speed: 9 + i % 6 * 4, drift: 11 + i % 4 * 5, phase: i * 2.37,
      size: i % 4 === 0 ? 5 : 3,
      color: ['#b1d66b','#e6c978','#f4aacb','#89c76b','#e4dc83'][i % 5]
    }));
    this.loop = this.loop.bind(this);
    this.frameHandle = requestAnimationFrame(this.loop);
  }
  setScene(scene, width, height) {
    this.scene = scene;
    this.canvas.width = width;
    this.canvas.height = height;
    this.canvas.style.width = width + 'px';
    this.canvas.style.height = height + 'px';
    this.render(performance.now());
  }
  setDusk(dusk) { this.dusk = !!dusk; this.render(performance.now()); }
  setMotion(on) { this.running = !!on; this.render(performance.now()); }
  loop(time) {
    this.frameHandle = requestAnimationFrame(this.loop);
    if (document.hidden || !this.running || time - this.lastFrame < 33) return;
    this.lastFrame = time;
    this.render(time);
  }
  circle(x,y,r,color,alpha=1) {
    const c=this.ctx;
    c.globalAlpha=alpha;
    c.fillStyle=color;
    c.beginPath();c.arc(x,y,r,0,Math.PI*2);c.fill();
    c.globalAlpha=1;
  }
  glow(x,y,r,amount,color) {
    const c=this.ctx;
    const gr=c.createRadialGradient(x,y,r*.04,x,y,r);
    gr.addColorStop(0,`rgba(${color},${Math.min(.72,amount*1.8)})`);
    gr.addColorStop(.26,`rgba(${color},${Math.min(.3,amount*.63)})`);
    gr.addColorStop(1,`rgba(${color},0)`);
    c.fillStyle=gr;c.fillRect(x-r,y-r,r*2,r*2);
  }
  render(time) {
    const c=this.ctx;if(!c)return;
    const w=this.canvas.width,h=this.canvas.height;
    c.clearRect(0,0,w,h);
    const t=this.running ? (time - this.zero)/1000 : 0;
    const breath=(a=1,b=1)=>Math.sin(t*a+b);
    if(this.scene==='interior') {
      // Window cool-hour light and lantern warm pool use distinct local colors.
      if(this.dusk){
        this.glow(348,245,200,.16,'117,149,206');
        this.glow(797,232,220,.28 + breath(1.7)*.023,'255,187,105');
        this.glow(1015,666,120,.10,'253,210,143');
      } else {
        this.glow(348,265,155,.08,'245,226,153');
        this.glow(790,235,125,.07+breath(2)*.008,'255,217,159');
      }
      // Indoor plant shadow shifts by a few pixels; the wall and furniture stay fixed.
      c.globalAlpha=.07;
      c.fillStyle='#355a3a';
      const dx=breath(.34)*5;
      c.fillRect(1264+dx,856,17,3);
      c.fillRect(1278+dx,850,8,3);
      c.globalAlpha=1;
      return;
    }
    // Outdoor house lights: the lanterns and windows get warmer at dusk,
    // instead of only reducing the brightness of the entire illustration.
    const points=[[608,381,66],[1082,452,78],[1220,672,80],[571,541,60],
                  [910,278,86],[867,473,92],[1206,408,98]];
    for(let i=0;i<points.length;i++){
      const [x,y,r]=points[i];
      const strength=(this.dusk?.40:.10)*(1 + breath(1.43+i*.17,i*1.5)*.075);
      this.glow(x,y,r*(this.dusk?1.35:1),strength,'255,195,95');
    }
    // Smoke from the existing cottage chimney; anchored above the chimney top.
    for(let i=0;i<9;i++){
      const age=((t*.22 + i/9)%1);
      const y=111-age*152;
      const x=1147+Math.sin(t*.5+i)*7+age*33;
      const radius=9+age*17;
      this.circle(x,y,radius,this.dusk?'#ecd5d6':'#f7ecdb',(1-age)*.14);
    }
    // Wind-dapple: small moving highlight flecks over the EXISTING canopy.
    // This does not claim the unlayered tree crown physically sways yet.
    for(let i=0;i<13;i++){
      const tx=236+(i*61)%464,ty=48+(i*53)%235;
      const dx=breath(.7+i*.03,i)*6;
      c.fillStyle=i%3===0?'rgba(240,226,110,.35)':'rgba(173,213,104,.28)';
      c.fillRect(Math.round(tx+dx),ty,5+(i%3)*3,3);
    }
    // Falling leaves. Most drift toward the grass, without moving interaction anchors.
    for(const p of this.leaves){
      const age=((t*p.speed + p.y)%(780))/780;
      const px=p.x+Math.sin(t*.7+p.phase)*p.drift + age*92;
      const py=40+age*730;
      c.save();c.translate(Math.round(px),Math.round(py));
      c.rotate(Math.sin(t*1.2+p.phase)*.52);
      c.globalAlpha=Math.min(1,age*10,(1-age)*9);
      c.fillStyle=p.color;
      c.fillRect(-p.size/2,-p.size/2,p.size,p.size);
      c.fillRect(0,p.size/2,Math.max(2,p.size-2),2);
      c.restore();
    }
    // Small moving water reflections and ripples in the already drawn river.
    c.lineWidth=3;
    for(let i=0;i<15;i++){
      const x=24+(i*73)%385, y=365+(i*97)%600;
      // Approximate left-of-bank water mask; skip the land by rule.
      const bank=x<150 ? 530 : x<280 ? 765 : 970;
      if(y<bank || x>410)continue;
      const wobble=breath(.82+i*.13,i*.9);
      c.globalAlpha=.16+(wobble+1)*.08;
      c.strokeStyle=this.dusk?'#e1b6cf':'#a7e1ee';
      c.beginPath();c.ellipse(x+8*wobble,y,13+i%3*3,3,0,0,Math.PI*2);c.stroke();
      c.globalAlpha=1;
    }
    if(this.dusk){
      // A few fireflies appear only at dusk, near tree roots/yard flower beds.
      for(let i=0;i<7;i++){
        const x=345+(i*191)%1110+breath(.31+i*.07,i)*10;
        const y=432+(i*83)%430+breath(.53+i*.1,i)*8;
        const pulse=Math.max(0,breath(1.3+i*.16,i));
        this.glow(x,y,14, pulse*.12,'255,228,142');
        this.circle(x,y,1.9,'#fff2b0',pulse*.72);
      }
    }
  }
  destroy(){cancelAnimationFrame(this.frameHandle);document.removeEventListener('visibilitychange',this.visibilityHandler);}
}
window.FantasiaAmbient25D=FantasiaAmbient25D;