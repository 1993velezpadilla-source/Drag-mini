# Original Need for Speed Underground 2 cars — full local import to City Zero

**Real NFSU2 models only. No imaginary/generated cars.** This is a local converter for the user's own original or modded PC game installation. The GitHub repository does not include EA models, vinyl textures, engine sound recordings or game data.

## One command for everything

Prerequisites: Blender 4.2+; Python 3.10+; a legally obtained installed PC copy of NFSU2; optional vgmstream-cli for audio decoding.

\`\`\`bash
git clone https://github.com/mininxd/NFSU2-World-Editor.git NFSU2-World-Editor
python3 tools/nfsu2_import_all.py \
  --game-root "/path/to/Need for Speed Underground 2" \
  --converter-dir "./NFSU2-World-Editor" \
  --out "/private/CityZeroNFSU2Imported" \
  --export-all
\`\`\`

The importer visits every CARS/<XNAME>/GEOMETRY.BIN, uses the open-source parser to inventory all real body-kit, bumper, skirt, hood, trunk, engine, exhaust, spoiler, headlight, rim/wheel and trunk audio part meshes and LODs, and writes a JSON catalogue with authentic original part names/hashes. Blender exports the real stock car to a GLB and independent kit/part variants to separate GLBs using original geometry, UVs and texture classes. VINYLS.BIN is catalogued and can be extracted into all decodable private PNG files. It also scans SOUND/ and decodes all vgmstream-supported subsongs in ABK/GIN banks when vgmstream-cli is available, while tracking the CarSoundData stock/street/pro/extreme engine/shift/turbo mappings and Unlimiter settings where installed.

For a quick proof before all cars: add \`--cars SUPRA\`. For A/B/C/D low-LOD variants too: add \`--every-lod\`. To run only the catalogue, omit \`--export-all\`.

## Critical accuracy notes

- The source game directory is essential; neither GitHub nor this package embeds the original NFSU2 meshes, textures, engine sounds or mod assets. The workflow cannot manufacture them.
- PARTS_ANIMATIONS.BIN is inventoried; full original keyframe/pivot import **is not yet implemented**. See the [PartAnimatorulator project](https://github.com/TVasya/PartAnimatorulator) for the native pivot layout.
- Most visual/bodykit items are importable as real named meshes. 3D GLB part exports are not an already-playable Godot garage: scene pivots, attachment IDs, compatibility, wheels and animation integration need validation on actual files.
- GLOBALB/CarTypeInfo is used when available for wheel placement. **Exact performance upgrade physics and sound RPM/Ginsu mixing have not been reconstructed** here. The original files and upgrade stage mappings are inventoried but the complete dynamic game engine remains separate work.
- Modded NFSU2 add-on vehicles are included when their individual CARS folders are part of your input installation.
- Exported original audio/textures/meshes are **private local conversions**. Do not redistribute EA or unlicensed mod authors' media with a commercial City Zero game.

## Verify

\`\`\`bash
python3 -m unittest discover -v -s tools/tests -p test_nfsu2_import_all.py
\`\`\`

GitHub CI: [Importer Tests](../../.github/workflows/cityzero-nfsu2-importer.yml). The CI uses synthetic fixtures only and cannot prove game import success without your local original game data and real Blender rendering.
