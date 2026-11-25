package org.myforeverpet.paradise;
import android.media.*;
import android.os.SystemClock;
import java.util.function.IntConsumer;
/** Explicit opt-in, bounded, RAM-only voice mimic. No background recording or file/network I/O. */
final class PetVoice {
 private volatile boolean running,canceled;
 private volatile int phase;
 private AudioRecord recorder;
 private AudioTrack player;
 synchronized boolean busy(){return running;}
 int phase(){return phase;}
 synchronized void start(int voice,IntConsumer callback){if(running)return;running=true;canceled=false;phase=1;Thread worker=new Thread(()->run(voice,callback),"PetVoice");worker.start();}
 synchronized void cancel(){canceled=true;if(recorder!=null){try{recorder.stop();}catch(RuntimeException ignored){}}if(player!=null){try{player.pause();player.flush();}catch(RuntimeException ignored){}}}
 private void run(int voice,IntConsumer callback){AudioRecord input=null;AudioTrack output=null;short[] pcm=new short[48000];try{
  int min=AudioRecord.getMinBufferSize(16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT);
  if(min<=0)throw new IllegalStateException("Audio input unavailable");
  input=new AudioRecord(MediaRecorder.AudioSource.MIC,16000,AudioFormat.CHANNEL_IN_MONO,AudioFormat.ENCODING_PCM_16BIT,Math.max(min,4096));
  if(input.getState()!=AudioRecord.STATE_INITIALIZED)throw new IllegalStateException("Audio input unavailable");
  synchronized(this){if(canceled)return;recorder=input;input.startRecording();}
  callback.accept(1);int n=0;long end=SystemClock.elapsedRealtime()+3500;while(n<pcm.length&&!canceled&&SystemClock.elapsedRealtime()<end){int k=input.read(pcm,n,Math.min(1024,pcm.length-n),AudioRecord.READ_NON_BLOCKING);if(k<0)throw new IllegalStateException("Read failed");if(k==0){SystemClock.sleep(10);continue;}n+=k;}
  synchronized(this){if(recorder!=null){try{recorder.stop();}catch(RuntimeException ignored){}recorder=null;}}
  input.release();input=null;if(canceled||n==0)return;
  int rate=voice==0?21000:voice==1?24000:13000;
  output=new AudioTrack.Builder().setAudioAttributes(new AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()).setAudioFormat(new AudioFormat.Builder().setSampleRate(rate).setEncoding(AudioFormat.ENCODING_PCM_16BIT).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build()).setTransferMode(AudioTrack.MODE_STATIC).setBufferSizeInBytes(n*2).build();
  if(output.getState()!=AudioTrack.STATE_INITIALIZED)throw new IllegalStateException("Playback unavailable");
  if(output.write(pcm,0,n)!=n)throw new IllegalStateException("Playback write failed");
  synchronized(this){if(canceled)return;player=output;phase=2;output.play();}callback.accept(2);
  long until=SystemClock.elapsedRealtime()+n*1000L/rate+250;while(!canceled&&SystemClock.elapsedRealtime()<until)SystemClock.sleep(30);
 }catch(RuntimeException e){if(!canceled)callback.accept(-1);}finally{
  synchronized(this){recorder=null;player=null;if(input!=null){try{input.stop();}catch(RuntimeException ignored){}input.release();}if(output!=null){try{output.stop();}catch(RuntimeException ignored){}output.release();}java.util.Arrays.fill(pcm,(short)0);phase=0;running=false;}
  callback.accept(0);
 }}
}
