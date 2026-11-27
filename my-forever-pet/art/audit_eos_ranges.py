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

# Verify the checked-in runtime independently of the reference binary's internal aliases.
root=args.baseline.parent
catalog=json.loads((root/"eos_runtime_catalog.json").read_text())
source=(root.parent/"godot-arcade"/"dungeon_rules.gd").read_text()
runtime=json.loads(next(line.removeprefix("const MOVE_LIBRARY=") for line in source.splitlines() if line.startswith("const MOVE_LIBRARY=")))
assert len(catalog)==468
assert len(runtime)==522
assert {k for k in runtime if k.startswith("eos_")}==set(catalog)
fields={"power":"power","pp":"pp","type":"type","category":"category","acc1":"accuracy1","acc2":"accuracy2","crit":"crit","strikes":"strikes","reference_range":"range"}
runtime_fields={"crit":"reference_crit","strikes":"reference_strikes"}
# Neutral menu classification for the three typeless/dynamic moves is intentional.
neutral_menu={"eos_324":("hidden_power",True),"eos_360":("typeless",True),"eos_394":("special_rule","35")}
runtime_errors=[]
for key,record in catalog.items():
    i=record["reference_id"]
    entry=runtime[key]
    assert key==f"eos_{i:03d}" and entry["reference_id"]==i
    assert record["status"]!="pending_special_rules"
    for field,baseline_field in fields.items():
        expected=rows[i][baseline_field]
        if record[field]!=expected:
            runtime_errors.append((key,field,"catalog",record[field],expected))
        actual=entry[runtime_fields.get(field,field)]
        if field=="type" and key in neutral_menu:
            flag,value=neutral_menu[key]
            if expected=="none" and actual=="normal" and entry.get(flag)==value:
                continue
        if actual!=expected:
            runtime_errors.append((key,field,"runtime",actual,expected))
    assert entry["prototype"] is True
    assert 0<=entry["reach"]<=10 and entry["frame_count"]>0 and entry["duration"]>0
assert not runtime_errors,runtime_errors
report["runtime_audit"]={"catalog_count":len(catalog),"runtime_count":len(runtime),"matched_reference_count":len(catalog),"field_errors":runtime_errors,"neutral_menu_exceptions":list(neutral_menu),"visual_fidelity":"not validated"}
args.output.write_text(json.dumps(report,indent=2)+"\n")
print("KINDRIA_RUNTIME_METADATA_PASS",len(catalog),"moves;",len(runtime),"runtime entries; zero unexplained metadata differences")
