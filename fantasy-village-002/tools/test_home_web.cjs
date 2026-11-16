// Development-only: npm install playwright; serve builds/web locally first.
const {chromium}=require('playwright');const fs=require('fs');const path=require('path');
const url=process.env.HOME_WEB_URL||'http://127.0.0.1:8765/';
const out=process.env.HOME_WEB_OUTPUT||'/tmp/fv3-web-review';fs.mkdirSync(out,{recursive:true});
(async()=>{
const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const page=await browser.newPage({viewport:{width:480,height:800},hasTouch:true,isMobile:true,deviceScaleFactor:1});
const result={errors:[],responses:[],console:[],steps:[]};
page.on('pageerror',e=>result.errors.push(String(e)));page.on('console',m=>result.console.push(m.type()+': '+m.text()));page.on('response',r=>{if(r.url().startsWith(url))result.responses.push({url:r.url(),status:r.status()});});
await page.goto(url);await page.waitForTimeout(10000);
await page.touchscreen.tap(130,395);await page.keyboard.type('Forest',{delay:100});await page.touchscreen.tap(240,533);await page.waitForTimeout(2000);result.steps.push('Touch nickname field, enter local identity, tap enter');
await page.screenshot({path:path.join(out,'web-community.png')});
await page.touchscreen.tap(327,389);await page.waitForTimeout(2400);result.steps.push('Touch outdoor ground to move owner');
await page.screenshot({path:path.join(out,'web-moved.png')});
await page.touchscreen.tap(231,271);await page.waitForTimeout(6500);result.steps.push('Touch front door and wait for owner path/entry');
await page.screenshot({path:path.join(out,'web-interior.png')});
await page.setViewportSize({width:844,height:390});await page.waitForTimeout(1500);result.steps.push('Rotate viewport to landscape');
await page.screenshot({path:path.join(out,'web-landscape.png')});
await page.setViewportSize({width:360,height:800});await page.waitForTimeout(1000);
await page.screenshot({path:path.join(out,'web-360.png')});result.steps.push('360px portrait complete map check');
await page.setViewportSize({width:480,height:800});await page.waitForTimeout(500);
await page.touchscreen.tap(224,427);await page.waitForTimeout(2500);
await page.screenshot({path:path.join(out,'web-exit.png')});result.steps.push('Touch indoor doorway to leave');
fs.writeFileSync(path.join(out,'web.json'),JSON.stringify(result,null,2));
await browser.close();
if(result.errors.length||result.console.some(x=>x.startsWith('error:'))||result.responses.some(x=>x.status!==200))throw Error('Web runtime/resources failed');
console.log('PASS: Web resources, runtime and touch flow; review screenshots for visual outcome.');
})();
