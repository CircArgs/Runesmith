package main

import "core:fmt"
import "core:strings"

// Create a Result type
Result :: struct {
    status: bool,
    index: int,
    value: any,
    furthest: int,
    expected: string,
}

// Define Result constructors
success :: proc(index: int, value: any) -> Result {
    return Result{status=true, index=index, value=value, furthest=-1, expected=""}
}

failure :: proc(index: int, expected: string) -> Result {
    return Result{status=false, index=-1, value=nil, furthest=index, expected=expected}
}

// Define Parser type
Parser :: struct {
    parse_fn: proc (stream: string, index: int) -> Result,
}

// Define Parser constructor
make_parser :: proc (parse_fn: proc (stream: string, index: int) -> Result) -> Parser {
    return Parser{parse_fn=parse_fn}
}

// Define Parser methods
parse :: proc (p: Parser, stream: string) -> any {
    result := (p.parse_fn)(stream, 0)
    if result.status {
        return result.value
    } else {
        panic(fmt.Sprintf("Parse error: expected %s at index %d", result.expected, result.furthest))
    }
}

parse_partial :: proc (p: Parser, stream: string) -> (any, string) {
    result := (p.parse_fn)(stream, 0)
    if result.status {
        return result.value, stream[result.index:]
    } else {
        panic(fmt.Sprintf("Parse error: expected %s at index %d", result.expected, result.furthest))
    }
}

// Define some basic parsers
any_char :: Parser = make_parser(proc (stream: string, index: int) -> Result {
    if index < len(stream) {
        return success(index + 1, stream[index])
    } else {
        return failure(index, "any character")
    }
})

string :: proc(expected: string) -> Parser {
    return make_parser(proc (stream: string, index: int) -> Result {
        if strings.has_prefix(stream[index:], expected) {
            return success(index + len(expected), expected)
        } else {
            return failure(index, fmt.Sprintf("'%s'", expected))
        }
    })
}

// Define a function to combine parsers
combine :: proc(parsers: []Parser) -> Parser {
    return make_parser(proc (stream: string, index: int) -> Result {
        values := make([]any, len(parsers))
        for i, parser in parsers {
            result := (parser.parse_fn)(stream, index)
            if result.status {
                index = result.index
                values[i] = result.value
            } else {
                return result
            }
        }
        return success(index, values)
    })
}

// Define a function to alternate parsers
alt :: proc(parsers: []Parser) -> Parser {
    return make_parser(proc (stream: string, index: int) -> Result {
        for parser in parsers {
            result := (parser.parse_fn)(stream, index)
            if result.status {
                return result
            }
        }
        return failure(index, "none of the alternatives matched")
    })
}

