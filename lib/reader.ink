std := load('../vendor/std')
str := load('../vendor/str')

slice := std.slice
append := std.append
split := str.split
hasPrefix? := str.hasPrefix?

Newline := char(10)

` Type-generic Reader over an Ink iterable interface, i.e. strings and lists.
This Reader is generic so that we can read through either a string (a list of
chars) or a list of strings. `
Reader := s => (
	S := {i: 0}

	peek := () => s.(S.i)
	last := () => s.(S.i - 1)
	back := () => S.i :: {
		0 -> 0
		_ -> S.i := S.i - 1
	}
	next := () => S.i :: {
		len(s) -> ()
		_ -> (
			c := s.(S.i)
			S.i := S.i + 1
			c
		)
	}
	expect? := prefix => hasPrefix?(slice(s, S.i, len(s)), prefix) :: {
		true -> (
			S.i := S.i + len(prefix)
			true
		)
		_ -> false
	}
	itemIndex := (list, it) => (sub := i => i < len(list) :: {
		true -> list.(i) :: {
			it -> i
			_ -> sub(i + 1)
		}
		_ -> ~1
	})(0)
	readUntil := c => i := itemIndex(slice(s, S.i, len(s)), c) :: {
		~1 -> ()
		_ -> (
			substr := slice(s, S.i, S.i + i)
			S.i := S.i + i
			substr
		)
	}
	readUntilPrefix := prefix => (sub := i => i + len(prefix) > len(s) :: {
		true -> ()
		_ -> part := slice(s, i, i + len(prefix)) :: {
			prefix -> (
				substr := slice(s, S.i, i)
				S.i := i
				substr
			)
			_ -> sub(i + 1)
		}
	})(S.i)
	readUntilEnd := () => (
		substr := slice(s, S.i, len(s))
		S.i := len(s)
		substr
	)
	` readUntilMatchingDelim is a helper specifically for parsing delimited
	expressions like text in [] or (), that will attempt to read until a
	matching delimiter and return that read if the match exists, and return ()
	if no match exists. This fn accounts for nested delimiters and ignores
	matching pairs within the delimited text expression. `
	readUntilMatchingDelim := left => (
		right := (left :: {
			` currently only supprots [] and () (for Markdown links) `
			'[' -> ']'
			'(' -> ')'
			_ -> ()
		})

		matchingDelimIdx := (sub := (i, stack) => stack :: {
			0 -> i - 1
			_ -> c := s.(i) :: {
				() -> ~1
				left -> sub(i + 1, stack + 1)
				right -> sub(i + 1, stack - 1)
				_ -> sub(i + 1, stack)
			}
		})(S.i, 1)

		matchingDelimIdx :: {
			~1 -> ()
			_ -> (
				substr := slice(s, S.i, matchingDelimIdx)
				S.i := matchingDelimIdx
				substr
			)
		}
	)

	{
		peek: peek
		last: last
		back: back
		next: next
		expect?: expect?
		readUntil: readUntil
		readUntilPrefix: readUntilPrefix
		readUntilEnd: readUntilEnd
		readUntilMatchingDelim: readUntilMatchingDelim
	}
)

