"""Adapted City Zero specialist review: evidence is not equivalent to art approval."""
import argparse,json,hashlib,struct,sys
from pathlib import Path
from PIL import Image
VIEWS=('front','rear','side','front34','rear34','underside')
MARKS=('silhouette','surface_detail','materials','face_and_expression','rear_and_paws','art_style','animation_pivots','in_game_readability')
def inspect(folder):
 report=json.loads((folder/'asset-report.json').read_text())
 issues=[];captures={}
 for tier in ('master','mobile'):
  model=folder/('mosskit-'+tier+'.glb')
  b=model.read_bytes()
  assert struct.unpack('<4sII',b[:12])==(b'glTF',2,len(b))
  assert hashlib.sha256(b).hexdigest()==report[tier]['sha256']
  size,kind=struct.unpack_from('<I4s',b,12);assert kind==b'JSON'
  g=json.loads(b[20:20+size])
  tris=sum(g['accessors'][p['indices']]['count']//3 if 'indices' in p else g['accessors'][p['attributes']['POSITION']]['count']//3 for m in g['meshes'] for p in m['primitives'])
  assert tris==report[tier]['triangles'],(tier,tris,report[tier]['triangles'])
  assert (folder/('mosskit-'+tier+'.blend')).stat().st_size>30000
  for view in VIEWS:
   p=folder/('mosskit-'+tier+'-'+view+'.png');im=Image.open(p).convert('RGBA')
   assert im.size==(960,960)
   mask=im.getchannel('A').point(lambda v:255 if v>127 else 0)
   box=mask.getbbox();assert box is not None
   x0,y0,x1,y1=box
   assert x0>12 and y0>12 and x1<948 and y1<948,(tier,view,box)
   assert (y1-y0)/960>(.30 if view=='underside' else .60) and (x1-x0)/960>.26,(tier,view,box)
   captures[tier+'-'+view]=[x0,y0,x1,y1]
 # Master/mobile silhouettes must remain consistent under the same calibrated cameras.
 for view in VIEWS:
  a=Image.open(folder/('mosskit-master-'+view+'.png')).getchannel('A').point(lambda v:255 if v>127 else 0)
  b=Image.open(folder/('mosskit-mobile-'+view+'.png')).getchannel('A').point(lambda v:255 if v>127 else 0)
  from PIL import ImageChops
  union=ImageChops.lighter(a,b).histogram()[255];intersection=ImageChops.darker(a,b).histogram()[255]
  assert union and intersection/union>=.94,(view,intersection/union)
 if not (folder/'godot-report.json').is_file():issues.append('Independent Godot import and pivot evidence missing')
 else:
  g=json.loads((folder/'godot-report.json').read_text())
  if not g.get('pass'):issues.append('Godot technical evidence failed')
  for v in VIEWS:
   p=folder/('godot-'+v+'.png')
   if not p.is_file() or p.stat().st_size<10000:issues.append('Missing genuine Godot view: '+v)
 approval=folder/'human_visual_review.json'
 if not approval.is_file():issues.append('Explicit visual approval pending; no automatic approval')
 else:
  a=json.loads(approval.read_text())
  if a.get('decision')!='APPROVE' or not a.get('reviewer') or not a.get('notes') or any(not isinstance(a.get('marks',{}).get(k),int) or not 4<=a['marks'][k]<=5 for k in MARKS):issues.append('Visual review does not meet >=4/5 on all criteria')
  if a.get('mobile_sha256')!=report['mobile']['sha256']:issues.append('Review is not tied to the exact mobile GLB')
 device=folder/'android-device-report.json'
 if not device.is_file():issues.append('Physical Android performance and touch review pending')
 else:
  d=json.loads(device.read_text())
  if d.get('mobile_sha256')!=report['mobile']['sha256'] or not d.get('device') or d.get('p95_frame_ms',999)>33.3 or not d.get('pass'):issues.append('Device evidence does not meet gate')
 result={'asset':'mosskit','status':'REJECTED_OR_PENDING' if issues else 'APPROVED','ship_allowed':not issues,'missing_or_failed':issues,'blender_capture_bounds':captures}
 (folder/'release-gate.json').write_text(json.dumps(result,indent=2))
 print(json.dumps(result,indent=2))
 return not issues
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--require-release',action='store_true');a=p.parse_args()
 ok=inspect(a.folder);sys.exit(1 if a.require_release and not ok else 0)
