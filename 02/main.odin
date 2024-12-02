package main

import "core:os"
import "core:mem"
import "core:strings"
import "core:fmt"
import "core:strconv"

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

	// Start of solution
	file, ok := os.read_entire_file_from_filename("input.txt")
  if !ok {
    panic("failed to read file")
  }
  defer delete(file)

	fileAsStr := string(file)
	sum := 0
  for line in strings.split_lines_iterator(&fileAsStr) {
  	if isReportSafe(line) {
  		sum += 1
  	}
  }
  fmt.println(sum)
}

isReportSafe :: proc(report: string) -> (result: bool) {
	levelsStr, err := strings.split(report, " ")
	if err != nil {
      panic("failed to split line")
  }
	defer delete(levelsStr)
	levels := levelStrToLevelsInt(levelsStr)
	defer delete(levels)
	increasing := levels[0] < levels[1]
	for i := 0; i < len(levels) - 1; i += 1 {
		difference := levels[i] - levels[i+1]
		safeInc := (difference <= -1) && (difference >= -3)
		safeDec := (difference >= 1) && (difference <= 3)
		result = (safeInc && increasing) || (safeDec && !increasing)

		if !result {
			return
		}
	}
	return
}

levelStrToLevelsInt :: proc(levelsStr: []string) -> []int {
	levels := make([]int, len(levelsStr))

	for i := 0; i < len(levelsStr); i += 1 {
		levels[i] = strconv.atoi(levelsStr[i])
	}
	return levels
}
