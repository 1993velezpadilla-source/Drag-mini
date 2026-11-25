import numpy as np, wave, sys
sr=22050
beat=60/132
n=round(32*beat*sr)
mix=np.zeros(n)
rng=np.random.default_rng(102)
def add(start,duration,note,gain,kind):
 count=int(duration*sr);t=np.arange(count)/sr;f=440*2**((note-69)/12)
 if kind=='kick': s=np.sin(2*np.pi*(45*t+36*(1-np.exp(-t*24))/24))*np.exp(-t*18)
 elif kind=='hat': s=rng.uniform(-1,1,count)*np.exp(-t*45)
 else:
  s=(np.sin(2*np.pi*f*t)+.24*np.sin(4*np.pi*f*t)+.08*np.sin(6*np.pi*f*t))*np.minimum(1,t*130)*np.exp(-t*(5 if kind=='bass' else 9))
 idx=(np.arange(count)+round(start*sr))%n
 np.add.at(mix,idx,s*gain)
chords=[(48,60,64,67),(45,57,60,64),(41,53,57,60),(43,55,59,62)]
for b in range(32):
 c=chords[(b//4)%4]
 add(b*beat,.20,36,.20,'kick')
 add((b+.5)*beat,.08,80,.06,'hat')
 add(b*beat,.36,c[0],.12,'bass')
 for j in range(2): add((b+j*.5)*beat,.23,c[1+(b+j)%3]+12,.075,'lead')
pcm=np.int16(np.clip(mix,-.8,.8)*32767)
with wave.open(sys.argv[1],'wb') as w:
 w.setnchannels(1);w.setsampwidth(2);w.setframerate(sr);w.writeframes(pcm.tobytes())
