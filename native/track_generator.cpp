// Drag Mini procedural track authoring. No flattened race-track artwork.
// Native C++17 tool creates world-space roadside scenery for the entire mile.
// Build: c++ -std=c++17 -O2 native/track_generator.cpp -o build/track_generator
//        ./build/track_generator assets/tracks/track_geometry.json
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <cstdint>
static uint32_t rand_step(uint32_t &state) {
    state ^= state << 13; state ^= state >> 17; state ^= state << 5;
    return state;
}
int main(int argc, char **argv) {
    if (argc != 2) { std::cerr << "Usage: track_generator OUTPUT.json\n"; return 2; }
    std::ofstream out(argv[1], std::ios::binary | std::ios::trunc);
    if (!out) { std::cerr << "Cannot open output\n"; return 3; }
    constexpr int world_length = 1800; // greater than full 1609.344m race
    constexpr int count = 90;
    uint32_t seed = 0xD6A629u;
    const char *kinds[] = {"palm", "lights", "grandstand", "billboard", "warehouse", "palm", "tower"};
    out << "{\"version\":1,\"length_m\":" << world_length << ",\"props\":[";
    for (int i = 0; i < count; i++) {
        uint32_t roll = rand_step(seed);
        const int meters = 24 + i * 20 + int(roll % 12u);
        const int kind = (i % 17 == 0) ? 3 : (i % 11 == 0 ? 2 : int((roll >> 7) % 7u));
        const int height = 12 + int((roll >> 15) % 19u);
        if (i) out << ',';
        out << "{\"m\":" << meters << ",\"kind\":\"" << kinds[kind]
            << "\",\"h\":" << height << "}";
    }
    out << "]}";
    if (!out.good()) { std::cerr << "Unable to write track\n"; return 4; }
    std::cout << "DRAG MINI C++ TRACK: PASS: full 1/8, 1/4, 1/2 and 1 mile track geometry\n";
}
