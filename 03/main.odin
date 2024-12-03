package main

import "core:mem"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

mul :: struct {
	op1: int,
	op2: int,
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
  multis := parseForMultiplicationPart2(fileAsStr)
  defer delete(multis)
  sum := 0
  for mult in multis {
  	sum += mult.op1*mult.op2
  }
  fmt.println(sum)
}

parseForMultiplicationPart2 :: proc(memory: string) -> [dynamic]mul {
	multis: [dynamic]mul
	skip := false
	for i in 0..<len(memory) {
		if ((memory[i] == 'd') && (memory[i+1] == 'o') && (memory[i+2] == '(') && (memory[i+3] == ')')) { // if "do()" stop skipping
			skip = false
			continue
		}
		
		if skip {
			continue
		}

		if ((memory[i] == 'd') && (memory[i+1] == 'o') && (memory[i+2] == 'n') && (memory[i+3] == '\'') && (memory[i+4] == 't') && (memory[i+5] == '(') && (memory[i+6] == ')')) { // if "dont't()" skip until "do()"
			skip = true
			continue
		}
		
		if !((memory[i] == 'm') && (memory[i+1] == 'u') && (memory[i+2] == 'l') && (memory[i+3] == '(')) { // need to match "mul(" first
			continue
		}

		mult := mul {
			op1 = 0,
			op2 = 0,
		}
		
		num1, len1: int
		if tryBuildNumber(memory, i+4, &num1, &len1) { // returns true if valid number. Resulting number and char length as out param
			mult.op1 = num1
		} else {
			continue
		}
		
		if !(memory[i+4+len1] == ',') { // need to match "," between the numbers
			continue
		}
		
		num2, len2: int
		if tryBuildNumber(memory, i+4+len1+1, &num2, &len2) { // returns true if valid number. Resulting number and char length as out param
			mult.op2 = num2
		} else {
			continue
		}

		if !(memory[i+4+len1+1+len2] == ')') { // need to match ")" at the end
			continue
		}
		
		append(&multis, mult)
	}
	return multis
}

parseForMultiplicationPart1 :: proc(memory: string) -> [dynamic]mul {
	multis: [dynamic]mul
	for i in 0..<len(memory) {
		mult := mul {
			op1 = 0,
			op2 = 0,
		}
		
		if !((memory[i] == 'm') && (memory[i+1] == 'u') && (memory[i+2] == 'l') && (memory[i+3] == '(')) { // need to match "mul(" first
			continue
		}
		
		num1, len1: int
		if tryBuildNumber(memory, i+4, &num1, &len1) { // returns true if valid number. Resulting number and char length as out param
			mult.op1 = num1
			// fmt.printf("num1: %s\n", num1)
		} else {
			continue
		}
		
		if !(memory[i+4+len1] == ',') { // need to match "," between the numbers
			continue
		}
		
		num2, len2: int
		if tryBuildNumber(memory, i+4+len1+1, &num2, &len2) { // returns true if valid number. Resulting number and char length as out param
			mult.op2 = num2
			// fmt.printf("num2: %s\n", num2)
		} else {
			continue
		}

		if !(memory[i+4+len1+1+len2] == ')') { // need to match ")" at the end
			continue
		}
		
		append(&multis, mult)
	}
	return multis
}

isRuneNumber :: proc(char: u8) -> bool {
	return (char >= 48) && (char <= 57)
}

tryBuildNumber :: proc(memory: string, offset: int, number, length: ^int) -> bool {
	builder := strings.builder_make()
	length^ = 0
	for i in offset..<offset+3 {
		if isRuneNumber(memory[i]) {
			strings.write_byte(&builder, memory[i])
			length^ += 1
		} else {
			str := strings.to_string(builder)
			defer delete(str)
			number^ = strconv.atoi(str)
			return length^ > 0
		}
	}
	str := strings.to_string(builder)
	defer delete(str)
	number^ = strconv.atoi(str)
	return true
}
