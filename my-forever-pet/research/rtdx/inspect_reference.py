"""Read-only reference inspection of already-extracted RTDX tables.

Layouts independently expressed from public DreamNexus documentation/code.
No ROM extraction or original game data included. Keep output local.
"""
import argparse
import json
import struct
from pathlib import Path

def records(data, width):
    if len(data) % width:
        raise ValueError(f"Unexpected table size {len(data)} for width {width}")
    return [data[i:i + width] for i in range(0, len(data), width)]

def u16(row, offset):
    return struct.unpack_from("<H", row, offset)[0]

def inspect_tables(waza, actions, visuals, charges=None):
    moves = records(waza, 18)
    logic = records(actions, 160)
    effects = records(visuals, 76)
    if len(logic) != len(effects):
        raise ValueError("Action and audiovisual tables have different row counts")
    out = []
    visual_fields = {"ally_invoke":0x18, "enemy_invoke":0x1a,
                     "caster":0x1c, "area":0x20, "impact":0x22,
                     "projectile":0x24, "projectile_impact":0x26}
    sound_fields = {"ally_invoke":0x28, "enemy_invoke":0x2a,
                    "initiate":0x2c, "impact":0x2e, "projectile_launch":0x30}
    for move_id, move in enumerate(moves):
        action_id = u16(move, 12)
        if action_id >= len(logic):
            out.append({"move_id":move_id,"action_id":action_id,"unresolved":True})
            continue
        a, v = logic[action_id], effects[action_id]
        out.append({"move_id":move_id,"action_id":action_id,
                    "accuracy_raw":[u16(a,0x58),u16(a,0x5a)],
                    "type_id":a[0x7d],"category_id":a[0x7e],
                    "power":[a[0x7f],a[0x80]],"pp":[a[0x81],a[0x82]],
                    "range":a[0x88],"area_id":a[0x8c],"target_id":a[0x8d],
                    "hit_count_index":a[0x93],
                    "logic_effects":[{"type_id":u16(a,0x10+2*j),
                        "parameters":[{"type_id":a[0x5c+8*j+k],
                            "value":u16(a,0x18+16*j+2*k)} for k in range(8)]}
                            for j in range(4)],
                    "visual_symbols":{k:u16(v,o) for k,o in visual_fields.items()},
                    "sound_symbols":{k:u16(v,o) for k,o in sound_fields.items()}})
    charged = []
    if charges is not None:
        for row_id,row in enumerate(records(charges,10)):
            b,ba,f,fa,unknown = struct.unpack("<5H",row)
            charged.append({"row":row_id,"base_move":b,"base_action":ba,
                            "final_move":f,"final_action":fa,"unknown_08":unknown})
    return {"source":"local RTDX reference tables; numeric IDs only",
            "move_count":len(moves),"action_count":len(logic),
            "unresolved_count":sum(bool(r.get("unresolved")) for r in out),
            "moves":out,"charged_actions":charged}

def self_test():
    w=bytearray(36); a=bytearray(320); v=bytearray(152)
    struct.pack_into("<H",w,12,1)
    struct.pack_into("<H",w,30,3)
    struct.pack_into("<H",a,160+0x58,9000)
    a[160+0x81]=15
    struct.pack_into("<H",v,76+0x24,42)
    result=inspect_tables(w,a,v,struct.pack("<5H",1,1,2,3,0))
    assert result["moves"][0]["visual_symbols"]["projectile"]==42
    assert result["moves"][0]["accuracy_raw"][0]==9000
    assert result["moves"][0]["pp"][0]==15
    assert result["unresolved_count"]==1
    assert result["charged_actions"][0]["final_action"]==3
    try:
        records(b"x",18)
    except ValueError:
        pass
    else:
        raise AssertionError("malformed table accepted")
    print("RTDX_REFERENCE_SYNTHETIC_PASS")

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--self-test",action="store_true")
    p.add_argument("--native-data",type=Path)
    p.add_argument("--output",type=Path)
    args=p.parse_args()
    if args.self_test:
        self_test()
        return
    if not args.native_data or not args.output:
        p.error("--native-data and --output required unless --self-test")
    root=args.native_data
    charge=root/"dungeon/act_tamewaza.bin"
    result=inspect_tables((root/"pokemon/waza_data_info.bin").read_bytes(),
                          (root/"dungeon/act_data_info.bin").read_bytes(),
                          (root/"dungeon/act_effect_data_info.bin").read_bytes(),
                          charge.read_bytes() if charge.exists() else None)
    with args.output.open("x",encoding="utf-8") as f:
        json.dump(result,f,indent=2)
if __name__=="__main__":
    main()
