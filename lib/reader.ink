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

	` polymorphic helper fns `
	base := (type(s) :: {
		'string' -> () => ''
		_ -> () => []
	})
	push := (type(s) :: {
		'string' -> (a, b) => a + b
		_ -> (a, b) => a.len(a) := b
	})
	matchPrefix? := (type(s) :: {
		'string' -> hasPrefix?
		_ -> (a, b) => slice(a, 0, len(b)) = b
	})

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
	readUntil := c => (sub := substr => peek() :: {
		c -> substr
		() -> substr
		_ -> sub(push(substr, next()))
	})(base())
	readUntilPrefix := prefix => (
		(sub := substr => matchPrefix?(slice(s, S.i, len(s)), prefix) :: {
			true -> substr
			_ -> n := next() :: {
				() -> substr
				_ -> sub(push(substr, n))
			}
		})(base())
	)
	readUntilEnd := () => readUntil(())
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

