package main

import "core:mem"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"

Operator :: enum {
	Add,
	Multiply,
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
	lines := strings.split_lines(fileAsStr) 
	defer delete(lines)
	sum := 0
	for i in 0..<len(lines)-1 {
		result, operands := getResultAndOperands(lines[i])
		defer delete(operands)
		if isEquationSolvable(result, operands) {
			sum += result
		}
	}
	fmt.println(sum)
}

getResultAndOperands :: proc(line: string) -> (int, []int) {
	resultAndOperands := strings.split(line, ": ")
	defer delete(resultAndOperands)
	result := strconv.atoi(resultAndOperands[0])
	operandsStr := strings.split(resultAndOperands[1], " ")
	defer delete(operandsStr)
	operands := make([]int, len(operandsStr))
	for opStr, i in operandsStr {
		operands[i] = strconv.atoi(opStr)
	}
	return result, operands
}

isEquationSolvable :: proc(result: int, operands: []int) -> bool {
	numPossibilities := 1 << uint(len(operands)-1)
	for i in 0..<numPossibilities {
		operators := make([]Operator, len(operands)-1)
		defer delete(operators)
		for j in 0..<len(operators) {
			digitVal := 1 << uint(j+1)
			digitValHalf := digitVal/2
			test := i % digitVal
			if test < digitValHalf {
				operators[j] = .Add 
			} else {
				operators[j] = .Multiply
			}
		}
		if solveEquation(operands, operators) == result {
			return true
		}
	}
	return false
}

solveEquation :: proc(operands: []int, operators: []Operator) -> int {
	prevResult := operands[0]
	for i in 1..<len(operands) {
		switch operators[i-1] {
			case .Add:
				prevResult += operands[i]
			case .Multiply:
				prevResult *= operands[i]
		}
	}
	return prevResult
}
