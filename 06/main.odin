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

	testGuard := guard
	getVisitedFields(&fields, &testGuard)
	fields[guard.y][guard.x] = .ftGuard
	fmt.println(getNumInfiniteLoops(fields, guard))
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

getVisitedFields :: proc(fields: ^[][]FieldType, guard: ^Guard) {
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
}

getNumInfiniteLoops :: proc(fields: [][]FieldType, guard: Guard) -> int {
	num := 0
	for i in 0..<len(fields) {
		for j in 0..<len(fields[0]) {
			newFields := fields
			if newFields[i][j] == .ftVisited {
				newFields[i][j] = .ftObstacle
				if isInfiniteLoop(newFields, guard) {
					num += 1
				}
				newFields[i][j] = .ftVisited
			}
		}
	}
	return num
}

isInfiniteLoop :: proc(newFields: [][]FieldType, guard: Guard) -> bool {
	previousPositions: [dynamic]Guard
	defer delete(previousPositions)
	previousGuard := guard
	isGuardInArea := true
	for isGuardInArea {
		newGuard := previousGuard
		nextX := 0
		nextY := 0
		switch newGuard.direction {
			case .dUp:
				nextX = newGuard.x + 0
				nextY = newGuard.y - 1
			case .dDown:
				nextX = newGuard.x + 0
				nextY = newGuard.y + 1 
			case .dLeft:
				nextX = newGuard.x - 1
				nextY = newGuard.y + 0
			case .dRight:
				nextX = newGuard.x + 1
				nextY = newGuard.y + 0
		}
		isGuardInArea = ((nextY >= 0) && (nextY < len(newFields))) && ((nextX >= 0) && (nextX < len(newFields[0])))
		if !isGuardInArea {
			return false
		}
		collided := newFields[nextY][nextX] == .ftObstacle
		if collided {
			newGuard.direction = Direction((int(newGuard.direction) + 1) % 4)
			for prevGuard in previousPositions {
				if (prevGuard.x == newGuard.x) && (prevGuard.y == newGuard.y) && (prevGuard.direction == newGuard.direction) {
					return true
				}
			}
			append(&previousPositions, newGuard)
		} else {
			newGuard.x = nextX
			newGuard.y = nextY
		}
		previousGuard = newGuard
	}
	return false
}
