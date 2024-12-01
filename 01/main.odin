package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:strconv"
import "core:mem"

main :: proc() {
  // Memoryleak detection
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
	// Memoryleak detection
	
  file, ok := os.read_entire_file_from_filename("input.txt")
  if !ok {
    panic("failed to read file")
  }
  defer delete(file)

  left, right := getIdLists(file)
  defer {
    delete(left)
    delete(right)
  }

  sum := 0
  for i := 0; i < len(left); i += 1 {
    if left[i] < right[i] {
      sum += right[i] - left[i]
    } else {
      sum += left[i] - right[i]
    }
  } 

  fmt.println(sum)
}

getIdLists :: proc(file: []u8) -> (leftSlice, rightSlice: []int) {
  left: [dynamic]int
  right: [dynamic]int
  fileAsStr := string(file)
  for line in strings.split_lines_iterator(&fileAsStr) {
    ids, err := strings.split(line, "   ")
    if err != nil {
      panic("failed to split line")
    }

    append(&left, strconv.atoi(ids[0]))
    append(&right, strconv.atoi(ids[1]))
    delete(ids)
  }

  leftSlice = left[:]
  rightSlice = right[:]
  slice.sort(leftSlice)
  slice.sort(rightSlice)
  return
}
