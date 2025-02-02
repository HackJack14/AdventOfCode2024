package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:strconv"
import "core:mem"

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

  left, right := getIdLists(file)
  defer {
    delete(left)
    delete(right)
  }
  
  fmt.printf("Part 1: %d", getScorePart1(left, right))
  fmt.printf("Part 2: %d", getScorePart2(left, right))
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

getScorePart1 :: proc(left, right: []int) -> int {
  sum := 0
  for i := 0; i < len(left); i += 1 {
    if left[i] < right[i] {
      sum += right[i] - left[i]
    } else {
      sum += left[i] - right[i]
    }
  }
  return sum
}

getScorePart2 :: proc(left, right: []int) -> int {
  sum := 0
  for id in left {
    i, found := slice.linear_search(right, id)
    if found {
      for j := i; j < len(right); j += 1 {
        if right[j] != id {
          break;
        }
        sum += id;
      }
    }
  }
  return sum
}
