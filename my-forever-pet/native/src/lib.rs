// SPDX-License-Identifier: GPL-3.0-only
// Android adapter. The emulator and its game logic are unmodified Capybara.
pub mod emulator;
pub mod touches;
use emulator::{Machine, StepResult};
use jni::{JNIEnv, objects::{JClass,JString}, sys::{jint,jintArray,jlong,jstring}};
use std::{collections::{HashMap,VecDeque},sync::{Mutex,OnceLock},time::{Instant,Duration},path::PathBuf};
struct Session { m:Machine, pulses:HashMap<u32,u64>, wheel:VecDeque<(bool,bool)>, debt:f64 }
static SESSION:OnceLock<Mutex<Option<Session>>>=OnceLock::new();
fn state()-> &'static Mutex<Option<Session>> { SESSION.get_or_init(||Mutex::new(None)) }
fn save(s:&mut Session)->Result<(),String>{s.m.ecrire_sauvegarde()}
#[no_mangle]
pub extern "system" fn Java_org_myforeverpet_paradise_PetRuntime_nativeOpen(mut e:JNIEnv,_:JClass,rom:JString,slot:JString,key:jlong)->jstring{
 let result=(||->Result<(),String>{
  let path:String=e.get_string(&rom).map_err(|x|x.to_string())?.into();
  let slot:String=e.get_string(&slot).map_err(|x|x.to_string())?.into();
  if std::fs::metadata(&path).map_err(|x|x.to_string())?.len()!=16*1024*1024{return Err("Expected a 16 MiB personal dump".into())}
  let mut guard=state().lock().map_err(|x|x.to_string())?;
  if let Some(old)=guard.as_mut(){save(old)?;}
  let mut m=Machine::new(); m.device_key=Some(key as u32);
  let report=m.load_firmware_file(&path)?;
  if !report.bootable{return Err("Firmware not bootable with supplied key".into())}
  m.bus.mmio_trace.enabled=false;
  m.ouvrir_sauvegarde(PathBuf::from(slot))?;
  m.remplacer_la_pile();
  m.reset();m.is_running=true;
  *guard=Some(Session{m,pulses:HashMap::new(),wheel:VecDeque::new(),debt:0.0});
  Ok(())
 })();
 e.new_string(result.err().unwrap_or_default()).map(|s|s.into_raw()).unwrap_or(std::ptr::null_mut())
}
#[no_mangle]
pub extern "system" fn Java_org_myforeverpet_paradise_PetRuntime_nativeClose(e:JNIEnv,_:JClass)->jstring{
 let result=(||->Result<(),String>{let mut g=state().lock().map_err(|x|x.to_string())?;if let Some(s)=g.as_mut(){save(s)?;}*g=None;Ok(())})();
 e.new_string(result.err().unwrap_or_default()).map(|s|s.into_raw()).unwrap_or(std::ptr::null_mut())
}
#[no_mangle]
pub extern "system" fn Java_org_myforeverpet_paradise_PetRuntime_nativeInput(_:JNIEnv,_:JClass,cmd:jint){
 if let Ok(mut g)=state().lock(){if let Some(s)=g.as_mut(){
  if s.m.reveiller_par_broche(){s.pulses.clear();s.wheel.clear();return}
  let pin=match cmd{0=>Some(Machine::BOUTON_A),1=>Some(Machine::BOUTON_B),2=>Some(Machine::BOUTON_C),3=>Some(Machine::BOUTON_MOLETTE),_=>None};
  if let Some(p)=pin {let end=s.m.cpu.cycles.saturating_add(10_000_000);s.pulses.insert(p,end);}
  else if (cmd==4||cmd==5)&&s.wheel.len()<32 {for (a,b) in [(false,true),(false,false),(true,false),(true,true)]{s.wheel.push_back(if cmd==4{(a,b)}else{(b,a)});}}
 }}
}
#[no_mangle]
pub extern "system" fn Java_org_myforeverpet_paradise_PetRuntime_nativeTick(e:JNIEnv,_:JClass,ms:jint)->jintArray{
 let Ok(mut g)=state().lock() else{return std::ptr::null_mut()};let Some(s)=g.as_mut() else{return std::ptr::null_mut()};
 let now=s.m.cpu.cycles;s.pulses.retain(|_,v|*v>now);
 for pin in [Machine::BOUTON_A,Machine::BOUTON_B,Machine::BOUTON_C,Machine::BOUTON_MOLETTE]{if s.pulses.contains_key(&pin){s.m.appuyer(pin)}else{s.m.relacher(pin)}}
 if let Some((a,b))=s.wheel.pop_front(){for (pin,high) in [(Machine::ENCODEUR_1,a),(Machine::ENCODEUR_2,b)]{if high{s.m.relacher(pin)}else{s.m.appuyer(pin)}}}
 s.debt=(s.debt+96_000.0*ms.clamp(0,250) as f64).min(24_000_000.0);
 let start=Instant::now();let cycles=s.m.cpu.cycles;
 while s.m.is_running && (s.m.cpu.cycles.saturating_sub(cycles) as f64)<s.debt && start.elapsed()<Duration::from_millis(12){
  if !matches!(s.m.run_frame(),StepResult::Ok(_)){break}
 }
 s.debt=(s.debt-s.m.cpu.cycles.saturating_sub(cycles) as f64).max(0.0);
 if s.m.sauvegarde_a_ecrire(){if let Err(err)=save(s){log::error!("save: {}",err);}}
 let v:Vec<i32>=s.m.periph.display.vram.iter().map(|&p| (0xff000000u32 | (((p as u32>>11)&31)*255/31)<<16 | (((p as u32>>5)&63)*255/63)<<8 | ((p as u32&31)*255/31)) as i32).collect();
 let Ok(a)=e.new_int_array(v.len() as i32) else{return std::ptr::null_mut()};
 if e.set_int_array_region(&a,0,&v).is_err(){return std::ptr::null_mut()} a.into_raw()
}
