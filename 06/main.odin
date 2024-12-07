package main

import "core:mem"
import "core:os"
import "core:fmt"
import "core:strings"

FieldType :: enum {
	ftEmpty,
	ftObstacle,
	ftGuard,
	ftVisited,
}

Direction :: enum {
	dUp,
	dRight,
	dDown,
	dLeft,
}

Guard :: struct {
	x: int,
	y: int,
	direction: Direction,
}

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

	guard := Guard {
		x = 0,
		y = 0,
		direction = .dUp,
	}
	fields := getFieldsAndGuard(fileAsStr, &guard)
	defer {
		for i in 0..<len(fields) {
			delete(fields[i])
		}
		delete(fields)
	}
	fmt.println(getNumVisitedFields(fields, &guard))
}

getFieldsAndGuard :: proc(file: string, guard: ^Guard) -> [][]FieldType {
	lines := strings.split_lines(file)
	defer delete(lines)
	fields := make([][]FieldType, len(lines) - 1) // Y Coordinate
	for i in 0..<len(lines)-1 { // Exclude whitespace line at the end
		fields[i] = make([]FieldType, len(lines[i])) // X Coordinate
		for char, j in lines[i] {
			if char == '.' {
				fields[i][j] = .ftEmpty
			} else if char == '#' {
				fields[i][j] = .ftObstacle
			} else if (char == '^') || (char == '>') || (char == 'v') || (char == '<') {
				fields[i][j] = .ftGuard
				guard.x = j
				guard.y = i
				guard.direction = .dUp
			}
		}
	}
	return fields
}

getNumVisitedFields :: proc(fields: [][]FieldType, guard: ^Guard) -> int {
	isGuardInArea := true
	for isGuardInArea {
		nextX := 0
		nextY := 0
		switch guard.direction {
			case .dUp:
				nextX = guard.x + 0
				nextY = guard.y - 1
			case .dDown:
				nextX = guard.x + 0
				nextY = guard.y + 1 
			case .dLeft:
				nextX = guard.x - 1
				nextY = guard.y + 0
			case .dRight:
				nextX = guard.x + 1
				nextY = guard.y + 0
		}
		// fmt.println(nextX, nextY)
		isGuardInArea = ((nextY >= 0) && (nextY < len(fields))) && ((nextX >= 0) && (nextX < len(fields[0])))
		if !isGuardInArea {
			fields[guard.y][guard.x] = .ftVisited
			break
		}
		collided := fields[nextY][nextX] == .ftObstacle
		if collided {
			guard.direction = Direction((int(guard.direction) + 1) % 4)
		} else {
			fields[guard.y][guard.x] = .ftVisited
			guard.x = nextX
			guard.y = nextY
			fields[guard.y][guard.x] = .ftGuard
		}
	}
	sum := 0
	for i in 0..<len(fields) {
		for j in 0..<len(fields[i]) {
			if fields[i][j] == .ftVisited {
				sum += 1
			}
		}
	}
	return sum
}
