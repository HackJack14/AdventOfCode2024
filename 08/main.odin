package main

import "core:mem"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math/linalg"

Antenna :: struct {
	position: [2]f32,
	type: u8,
}

width, height: f32

main :: proc() {
  // Memoryleak detection boilerplate
  when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}
	// Memoryleak detection boilerplate

	file, ok := os.read_entire_file_from_filename("input.txt")
  if !ok {
    panic("failed to read file")
  }
  defer delete(file)	

	fileAsStr := string(file)
	antennas := getAllAntennas(fileAsStr)
	defer delete(antennas)
	antinodes := createAllAntinodes(antennas)
	defer delete(antinodes)
	fmt.println(len(antinodes))
}

getAllAntennas :: proc(file: string) -> []Antenna {
	antennas := make([dynamic]Antenna)
	lines := strings.split_lines(file)
	defer delete(lines)
	height = f32(len(lines)-1)
	width = f32(len(lines[0]))
	for y in 0..<len(lines)-1 {
		for x in 0..<len(lines[y]) {
			if lines[y][x] != '.' {
				pos := [2]f32{f32(x), f32(y)}	
				antenna := Antenna {
					position = pos,
					type = lines[y][x],
				}
				append(&antennas, antenna)
			}
		}
	}

	
	return antennas[:]
}

createAllAntinodes :: proc(antennas: []Antenna) -> [][2]f32 {
	antinodes := make([dynamic][2]f32)
	for i in 0..<len(antennas) {
		for j in 0..<len(antennas) {
			node1, node2: [2]f32
			if tryCreateAntinodes(antennas[i], antennas[j], &node1, &node2) {
				if !isNodeOutOfBounds(node1) && !nodeAlreadyExists(node1, antinodes[:]) {
					append(&antinodes, node1)
				}
				if !isNodeOutOfBounds(node2) && !nodeAlreadyExists(node2, antinodes[:]) {
					append(&antinodes, node2)
				}
			}
		}
	}
	return antinodes[:]
}

tryCreateAntinodes :: proc(ant1, ant2: Antenna, node1, node2: ^[2]f32) -> bool {
	if ant1.type != ant2.type {
		return false
	}
	if ant1.position == ant2.position { // Don't compare the same antenna
		return false
	}

	vec1to2 := ant2.position - ant1.position
	vec2to1 := ant1.position - ant2.position
	node1^ = ant2.position - vec1to2 * 2
	node2^ = ant1.position - vec2to1 * 2
	return true
}

isNodeOutOfBounds :: proc(node: [2]f32) -> bool {
	return (node.x < 0) || (node.x > width-1) || (node.y < 0) || (node.y > height-1)
}

nodeAlreadyExists :: proc(node: [2]f32, nodes: [][2]f32) -> bool {
	for i in 0..<len(nodes) {
		if nodes[i] == node {
			return true
		}
	}
	return false
}
