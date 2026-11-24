#!/usr/bin/env node
// City Zero: real local Chromium/CDP probe. Zero npm dependencies or paid browser APIs.
// Only public site interactions; never downloads/repackages proprietary game assets.
import {spawn} from 'node:child_process';
import {existsSync,mkdirSync,mkdtempSync,readFileSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve,join} from 'node:path';
const opts=Object.fromEntries(process.argv.slice(2).filter(x=>x.startsWith('--')).map(x=>{
  const i=x.indexOf('='); return i<0?[x.slice(2),true]:[x.slice(2,i),x.slice(i+1)];
}));
const selfTest=Boolean(opts['self-test']);
const url=selfTest?'about:blank':String(opts.url||'https://nfsu2mod.xyz/');
const out=resolve(String(opts.out||'artifacts/nfsu2-public'));
const wait=Math.min(Math.max(Number(opts.wait||15000),500),60000);
if(!selfTest&&!/^https?:\/\//.test(url)) throw Error('The URL must be http(s)');
mkdirSync(out,{recursive:true});
const profile=mkdtempSync(join(tmpdir(),'cityzero-browser-'));
const chromePath=[process.env.CHROME_PATH,'/usr/bin/google-chrome','/usr/bin/chromium','/usr/bin/chromium-browser'].find(x=>x&&existsSync(x))||'google-chrome';
const browser=spawn(chromePath,['--headless=new','--no-sandbox','--no-first-run','--disable-extensions',
  '--disable-dev-shm-usage','--window-size=1365,768','--remote-debugging-port=0',
  '--user-data-dir='+profile,'about:blank'],{stdio:'ignore'});
const report={url,date:new Date().toISOString(),status:'pending',screenshots:[],events:[],requests:[],errors:[]};
const pause=ms=>new Promise(r=>setTimeout(r,ms));
const pending=new Map();
let ws,id=0;
function command(method,params={}){
  return new Promise((resolve,reject)=>{
    const key=++id;
    const timeout=setTimeout(()=>{pending.delete(key);reject(Error('CDP timeout '+method));},20000);
    pending.set(key,{resolve,reject,timeout});
    ws.send(JSON.stringify({id:key,method,params}));
  });
}
const evaluate=async expression=>{
  const r=await command('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});
  return r.result?.result?.value;
};
async function snapshot(label){
  const info=await evaluate("JSON.stringify({title:document.title,url:location.href,state:document.readyState,text:(document.body?.innerText||'').slice(0,2500),canvases:Array.from(document.querySelectorAll('canvas')).map(c=>({width:c.width,height:c.height,cssWidth:Math.round(c.getBoundingClientRect().width),cssHeight:Math.round(c.getBoundingClientRect().height)})),controls:Array.from(document.querySelectorAll('button,input[type=button],[role=button]')).slice(0,35).map(x=>({text:(x.innerText||x.value||x.getAttribute('aria-label')||'').trim().slice(0,80),disabled:!!x.disabled})),featureWords:Object.fromEntries(['garage','body shop','trunk audio','hood','bonnet','multiplayer','free roam'].map(x=>[x,(document.body?.innerText||'').toLowerCase().includes(x)]))})");
  try{report[label]=JSON.parse(info)}catch{report[label]={raw:info}}
  const shot=await command('Page.captureScreenshot',{format:'png'});
  writeFileSync(join(out,label+'.png'),Buffer.from(shot.result.data,'base64'));
  report.screenshots.push(label+'.png');
}
try{
  let port;
  const devtoolsFile=join(profile,'DevToolsActivePort');
  for(let i=0;i<120;i++){
    if(existsSync(devtoolsFile)){port=Number(readFileSync(devtoolsFile,'utf8').split('\n')[0]);break}
    await pause(100);
  }
  if(!port)throw Error('Chromium CDP port unavailable');
  const targets=await(await fetch('http://127.0.0.1:'+port+'/json/list')).json();
  const page=targets.find(x=>x.type==='page');
  if(!page)throw Error('No CDP page available');
  ws=new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((ok,bad)=>{ws.addEventListener('open',ok,{once:true});ws.addEventListener('error',bad,{once:true})});
  ws.addEventListener('message',event=>{
    let data;try{data=JSON.parse(event.data)}catch{return}
    if(data.id){
      const p=pending.get(data.id);
      if(p){clearTimeout(p.timeout);pending.delete(data.id);data.error?p.reject(Error(data.error.message)):p.resolve(data)}
    }else if(data.method==='Network.responseReceived'&&report.requests.length<250){
      let u;try{u=new URL(data.params.response.url)}catch{return}
      if(!/^https?:$/.test(u.protocol))return;
      u.search='';u.hash='';
      report.requests.push({url:u.toString(),status:data.params.response.status,type:data.params.type});
    }else if(data.method==='Network.loadingFailed'&&report.errors.length<30){
      report.errors.push({type:'network',message:data.params.errorText});
    }else if(data.method==='Runtime.consoleAPICalled'&&report.events.length<50){
      report.events.push({type:data.params.type,message:(data.params.args||[]).map(x=>String(x.value||x.description||'')).join(' ').slice(0,250)});
    }
  });
  for(const name of ['Page.enable','Runtime.enable','Network.enable'])await command(name);
  if(selfTest){
    await evaluate("document.title='CityZeroSmoke';document.body.innerHTML='<h1>CityZeroReady</h1><button onclick=\\\"this.textContent=\\\'Started\\\';let c=document.createElement(\\\'canvas\\\');c.width=640;c.height=360;document.body.appendChild(c);c.getContext(\\\'2d\\\').fillRect(0,0,640,360)\\\">Play</button>';true");
  }else{
    const r=await command('Page.navigate',{url});
    if(r.result?.errorText)report.errors.push({type:'navigation',message:r.result.errorText});
    await pause(wait);
  }
  await snapshot('landing');
  if(opts['click-play']){
    const clicked=await evaluate("(()=>{const b=Array.from(document.querySelectorAll('button,input[type=button],[role=button]')).find(x=>/^play$/i.test((x.innerText||x.value||x.getAttribute('aria-label')||'').trim())&&!x.disabled);if(!b)return false;b.click();return true})()");
    report.clicked_play=Boolean(clicked);
    if(clicked){await pause(selfTest?300:5000);await snapshot('after_play');if(!selfTest){await pause(12000);await snapshot('after_play_17s');}}
  }
  report.summary={capturedFrames:report.screenshots.length,canvasDetected:report.screenshots.some((name)=>Array.isArray(report[name.replace('.png','')]?.canvases)&&report[name.replace('.png','')].canvases.length>0),wasmRequests:report.requests.filter(x=>/\\.wasm(?:$|\\?)/i.test(x.url)).map(x=>({url:x.url,status:x.status})),requestCount:report.requests.length,playButtonClicked:!!report.clicked_play};
  report.status=report.errors.some(x=>x.type==='navigation')?'navigation_error':'captured';
}catch(e){report.status='error';report.errors.push({type:'probe',message:String(e)})}
finally{
  writeFileSync(join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
  try{ws?.close()}catch{}
  browser.kill('SIGTERM');
  await pause(150);
  if(browser.exitCode===null)browser.kill('SIGKILL');
  rmSync(profile,{force:true,recursive:true});
}
console.log(JSON.stringify({status:report.status,report:join(out,'report.json'),screenshots:report.screenshots,errors:report.errors.slice(0,3)}));
if(report.status!=='captured')process.exitCode=1;
