package main

import "core:mem"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"

Rule :: struct {
	first: int,
	second: int,
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
  rulesPages := strings.split(fileAsStr, "\n\n")
  defer delete(rulesPages)

  rules := getRules(rulesPages[0])
  defer delete(rules)

  pages := getPages(strings.trim(rulesPages[1], "\n"))
  defer {
  	for i in 0..<len(pages) {
  		delete(pages[i])
  	}
  	delete(pages)
  }

  fmt.println(getSumMiddleNumbers(pages, rules))
}

getRules :: proc(rulesStr: string) -> []Rule {
	lines := strings.split_lines(rulesStr)
	defer delete(lines)

	rules := make([]Rule, len(lines))
	for i in 0..<len(lines) {
		firstAndSecond := strings.split(lines[i], "|")
		defer delete(firstAndSecond)
		rules[i].first = strconv.atoi(firstAndSecond[0])
		rules[i].second = strconv.atoi(firstAndSecond[1])
	}
	return rules
}

getPages :: proc (pagesStr: string) -> [][]int {
	lines := strings.split_lines(pagesStr)
	defer delete(lines)

	pages := make([][]int, len(lines))
	for i in 0..<len(lines) {
		splitPages := strings.split(lines[i], ",")
		defer delete(splitPages)
		pages[i] = make([]int, len(splitPages))
		for j in 0..<len(splitPages) {
			pages[i][j] = strconv.atoi(splitPages[j])
		}
	}
	return pages
}

getSumMiddleNumbers :: proc(pages: [][]int, rules: []Rule) -> int {
	sum := 0
	for i in 0..<len(pages) {
		correct := true
		for rule in rules {
			firstIndex := getNumberIndex(pages[i], rule.first)
			secondIndex := getNumberIndex(pages[i], rule.second)
			correct = (firstIndex == -1) || (secondIndex == -1)
			if !correct {
				correct = firstIndex < secondIndex
				if !correct {
					break
				}
			}
		}
		if correct {
			sum += getMiddleNumber(pages[i])
		}
	}
	return sum
}

getNumberIndex :: proc(pages: []int, number: int) -> int {
	index, found := slice.linear_search(pages, number)
	if found {
		return index
	}
	return -1
}

getMiddleNumber :: proc(pages: []int) -> int {
	return pages[len(pages)/2]
}
