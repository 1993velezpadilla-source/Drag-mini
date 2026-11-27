"""Audit numerical EoS move metadata from a locally supplied reference file.
No ROM, binary data, images or sound are written to the output.
The original format is documented by SkyTemple waza_p model/protocol.
"""
import argparse, json, struct, pathlib, hashlib
p=argparse.ArgumentParser()
p.add_argument("waza",type=pathlib.Path)
p.add_argument("baseline",type=pathlib.Path)
p.add_argument("output",type=pathlib.Path)
args=p.parse_args()
data=args.waza.read_bytes()
assert data[:4]==b"SIR0"
header=struct.unpack_from("<I",data,4)[0]
start=struct.unpack_from("<I",data,header)[0]
assert start+559*26<=len(data)
baseline=json.loads(args.baseline.read_text())
rows=baseline["rows"] if isinstance(baseline,dict) else baseline
assert len(rows)==559
ranges={0:"front",1:"three_front",2:"adjacent_eight",3:"room",4:"two_tiles",5:"straight_line",6:"floor",7:"self",8:"front_cuts_corners",9:"two_tiles_cuts_corners",15:"special"}
targets={0:"enemies",1:"allies",2:"everyone",3:"self",4:"two_turn",5:"everyone_except_self",6:"allies_except_self",15:"special"}
categories={0:"physical",1:"special",2:"status"}
type_names=["none","normal","fire","water","grass","electric","ice","fighting","poison","ground","flying","psychic","bug","rock","ghost","dragon","dark","steel"]
mismatch=[]
internal_aliases=[]
for i,row in enumerate(rows):
    off=start+i*26
    power=struct.unpack_from("<H",data,off)[0]
    move_id=struct.unpack_from("<H",data,off+22)[0]
    settings,ai=struct.unpack_from("<HH",data,off+4)
    if move_id!=i:
        assert i>=543,(i,move_id)
        internal_aliases.append({"slot":i,"embedded_id":move_id})
        row["range_review"]="internal_slot_not_verified"
        row["visual_review"]="pending_frame_by_frame"
        continue
    raw={"power":power,"pp":data[off+8],"accuracy1":data[off+10],"accuracy2":data[off+11],"strikes":data[off+13],"crit":data[off+15],"category":categories.get(data[off+3],"unknown"),"type":type_names[data[off+2]] if data[off+2]<len(type_names) else "unknown"}
    for key in raw:
        if row[key]!=raw[key]:mismatch.append({"id":i,"field":key,"baseline":row[key],"binary":raw[key]})
    row["reference_raw"]=raw
    row["target_code"]=settings&15
    row["range_code"]=(settings>>4)&15
    row["target_rule"]=targets.get(row["target_code"],"unknown")
    row["range_rule"]=ranges.get(row["range_code"],"unknown")
    row["ai_range_code"]=(ai>>4)&15
    row["ai_target_code"]=ai&15
    row["ai_condition_code"]=(ai>>8)&15
    row["ai_weight"]=data[off+9]
    row["mouth_move"]=bool(data[off+18])
    row["range_review"]="decoded_numeric_reference"
    row["visual_review"]="pending_frame_by_frame"
report={"reference_sha256":hashlib.sha256(data).hexdigest(),"record_count":len(rows),"mismatches":mismatch,"internal_aliases":internal_aliases,"moves":rows}
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+"\n")
assert rows[64]["range_code"]==0
assert rows[129]["range_code"]==2
assert rows[189]["range_code"]==5
assert rows[182]["range_code"]==0
assert rows[118]["range_code"]==3
print("EOS_RANGE_AUDIT_PASS",len(rows)-len(internal_aliases),"decoded records;",len(internal_aliases),"unverified internal aliases;",len(mismatch),"numeric disagreements retained for review")
