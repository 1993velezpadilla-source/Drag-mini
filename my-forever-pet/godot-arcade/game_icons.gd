extends RefCounted
# Native SVG vector icon artwork, drawn in source and rasterized once per icon.
static var cache:Dictionary={}
static func texture(key:String)->Texture2D:
	if cache.has(key): return cache[key]
	var art=""
	var color="#aee6ff"
	match key:
		"Home":
			art='<path d="M6 27L32 5 58 27V56H39V39H25V56H9V27Z" fill="url(#g)"/><path d="M5 29L32 6 59 29" fill="none" stroke="#fff0b3" stroke-width="6" stroke-linecap="round"/>'
			color="#f4be59"
		"Wallpaper":
			art='<rect x="14" y="4" width="36" height="56" rx="8" fill="url(#g)"/><rect x="18" y="10" width="28" height="40" rx="4" fill="#372452"/><path d="M21 32Q21 24 25 24L29 29H35L39 24Q43 24 43 32V41Q32 49 21 41Z" fill="#efb6ff"/><circle cx="28" cy="35" r="2" fill="#372452"/><circle cx="36" cy="35" r="2" fill="#372452"/><path d="M30 40Q32 42 34 40" stroke="#372452" fill="none" stroke-width="2"/><circle cx="32" cy="55" r="2.5" fill="#fff0ff"/>'
			color="#c295ff"
		"Rooms":
			art='<rect x="8" y="10" width="48" height="44" rx="9" fill="url(#g)"/><path d="M8 28H56M32 10V54" stroke="#26355b" stroke-width="5"/><rect x="13" y="14" width="14" height="10" rx="3" fill="#f1f7ff"/><rect x="37" y="34" width="14" height="15" rx="3" fill="#c8b8ff"/>'
		"Arcade","toy","play":
			art='<path d="M19 15H45Q55 16 59 38L57 49Q53 56 46 49L39 40H25L18 49Q11 56 7 49L5 38Q9 16 19 15Z" fill="url(#g)"/><path d="M19 22V38M11 30H27" stroke="#26355b" stroke-width="5" stroke-linecap="round"/><circle cx="44" cy="25" r="4" fill="#f8b4dc"/><circle cx="51" cy="33" r="4" fill="#ffe4a4"/>'
			color="#bb9bff"
		"Shop":
			art='<path d="M6 13H14L22 44H52L58 20H17" fill="url(#g)" stroke="#d9f6ff" stroke-width="4" stroke-linejoin="round"/><circle cx="26" cy="53" r="5" fill="#eaf8ff"/><circle cx="48" cy="53" r="5" fill="#eaf8ff"/><path d="M29 23V39M42 23V39" stroke="#516aab" stroke-width="3"/>'
		"More":
			art='<rect x="8" y="9" width="48" height="46" rx="13" fill="url(#g)"/><circle cx="20" cy="32" r="4.5" fill="#24244e"/><circle cx="32" cy="32" r="4.5" fill="#24244e"/><circle cx="44" cy="32" r="4.5" fill="#24244e"/>'
			color="#c6afff"
		"energy":
			art='<path d="M35 4L9 36H29L24 60 56 24H36L43 4Z" fill="url(#g)" stroke="#d9faff" stroke-width="2" stroke-linejoin="round"/>'
			color="#55d9ff"
		"mood":
			art='<circle cx="32" cy="32" r="25" fill="url(#g)"/><circle cx="23" cy="25" r="3.7" fill="#65305a"/><circle cx="41" cy="25" r="3.7" fill="#65305a"/><path d="M19 36Q32 51 45 36" fill="none" stroke="#65305a" stroke-width="4.5" stroke-linecap="round"/>'
			color="#ff8ac9"
		"bond":
			art='<path d="M32 55C19 45 5 35 5 21 5 7 24 4 32 19 40 4 59 7 59 21 59 35 45 45 32 55Z" fill="url(#g)"/><path d="M13 20Q16 11 25 15" stroke="#fff4ff" stroke-width="4" fill="none" stroke-linecap="round"/>'
			color="#ff91bf"
		"food","cook","snack":
			art='<ellipse cx="32" cy="22" rx="25" ry="12" fill="#ffc367"/><circle cx="20" cy="17" r="6" fill="#e99446"/><circle cx="32" cy="13" r="6" fill="#ffdf80"/><circle cx="45" cy="18" r="6" fill="#e99446"/><path d="M6 23L12 46Q32 57 52 46L58 23Q32 40 6 23Z" fill="url(#g)"/><ellipse cx="32" cy="23" rx="25" ry="11" stroke="#e4f5ff" stroke-width="3" fill="none"/>'
		"clean","soap","rinse","toilet":
			art='<path d="M13 22Q13 8 29 8H38V18H29Q23 18 23 24" fill="none" stroke="#cdeaff" stroke-width="6" stroke-linecap="round"/><path d="M8 31Q10 16 32 16T56 31Z" fill="url(#g)"/><path d="M15 37L12 44M27 37L25 48M39 37L40 48M51 37L54 44" stroke="#98dfff" stroke-width="5" stroke-linecap="round"/><circle cx="32" cy="55" r="3" fill="#e5faff"/>'
		"sleep","lamp":
			art='<path d="M44 6C17 9 5 27 15 46 24 62 48 60 58 42 35 48 25 24 44 6Z" fill="url(#g)"/><path d="M48 11L51 18 58 20 51 23 48 30 45 23 38 20 45 18Z" fill="#fff5ba"/>'
			color="#cfb2ff"
		"daily":
			art='<rect x="10" y="25" width="44" height="31" rx="5" fill="url(#g)"/><rect x="6" y="19" width="52" height="12" rx="4" fill="#ffe0a0"/><path d="M32 20V56" stroke="#f9a448" stroke-width="8"/><path d="M32 20Q5 17 17 7Q25 1 32 20Q39 1 47 7Q59 17 32 20Z" fill="none" stroke="#ffca66" stroke-width="5"/>'
			color="#f2a948"
		_: return null
	var svg='<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff8ff"/><stop offset=".25" stop-color="'+color+'"/><stop offset="1" stop-color="'+color+'" stop-opacity=".78"/></linearGradient></defs>'+art+'</svg>'
	var im=Image.new()
	if im.load_svg_from_string(svg,2.0)!=OK: return null
	var result=ImageTexture.create_from_image(im)
	cache[key]=result
	return result
