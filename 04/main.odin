package main

import "core:mem"
import "core:os"
import "core:fmt"
import "core:strings"

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
	fileAsStr = applyFilePadding(fileAsStr, getLineLength(fileAsStr) + 6)
	defer delete(fileAsStr)
  lines := strings.split_lines(fileAsStr)
  defer delete(lines)
  sum := 0
  for i in 0 ..<len(lines) - 3 {
		sum += parseForXMas(lines[i:i+4])
	}
	fmt.println(sum)
}

getLineLength :: proc(file: string) -> int {
	num := 0
	currChar: byte = 0
	for currChar != '\n' {
		currChar = file[num]
		num += 1
	}
	return num
}

applyFilePadding :: proc(file: string, paddingLen: int) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, file)
	for i in 0..<3 {
		for j in 0..<paddingLen {
			strings.write_byte(&builder, '0')
		}
		if i != 2 {
			strings.write_byte(&builder, '\n')
		}
	}
	return strings.to_string(builder)
}

applyLinePadding :: proc(line: string) -> string {
	builder := strings.builder_make()
	for i in 0..<3 {
		strings.write_byte(&builder, '0')
	}
	strings.write_string(&builder, line)
	for i in 0..<3 {
		strings.write_byte(&builder, '0')
	}
	return strings.to_string(builder)
}

parseForXMas :: proc(lines: []string) -> int {
	newLines := make([]string, 4)
	defer delete(newLines)
	for i in 0..<4 {
		newLines[i] = applyLinePadding(lines[i])
	}
	defer {
		for i in 0..<4 {
			delete(newLines[i])
		}
	}

	num := 0
	for i in 0..<len(newLines[0]) - 3 {
		if newLines[0][i:i+4] == "XMAS" {
			num += 1
		}
		if newLines[0][i:i+4] == "SAMX" {
			num += 1
		}
		if (newLines[0][i] == 'X') && (newLines[1][i] == 'M') && (newLines[2][i] == 'A') && (newLines[3][i] == 'S') {
			num += 1
		}
		if (newLines[0][i] == 'S') && (newLines[1][i] == 'A') && (newLines[2][i] == 'M') && (newLines[3][i] == 'X') {
			num += 1
		}
		if (newLines[0][i] == 'X') && (newLines[1][i+1] == 'M') && (newLines[2][i+2] == 'A') && (newLines[3][i+3] == 'S') {
			num += 1
		}
		if (newLines[0][i] == 'S') && (newLines[1][i+1] == 'A') && (newLines[2][i+2] == 'M') && (newLines[3][i+3] == 'X') {
			num += 1
		}
		if (newLines[0][i] == 'X') && (newLines[1][i-1] == 'M') && (newLines[2][i-2] == 'A') && (newLines[3][i-3] == 'S') {
			num += 1
		}
		if (newLines[0][i] == 'S') && (newLines[1][i-1] == 'A') && (newLines[2][i-2] == 'M') && (newLines[3][i-3] == 'X') {
			num += 1
		}
	}
	
	return num
}
