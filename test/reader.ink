` Markdown parser's Reader tests `

std := load('../vendor/std')
each := std.each

Reader := load('../lib/reader').Reader

run := (m, t) => (
	m('Reader.peek')
	(
		t('peek the next character', (
			r := Reader('abc')
			(r.peek)()
		), 'a')
		t('peek at end of string returns ()', (
			r := Reader('abc')
			each([1, 2, 3], r.next)
			(r.peek)()
		), ())
		t('peek of empty string returns ()', (
			r := Reader('')
			(r.peek)()
		), ())

		t('peek the next item in list', (
			r := Reader([10, 20, 30])
			(r.peek)()
		), 10)
		t('peek at end of list returns ()', (
			r := Reader([10, 20, 30])
			each([1, 2, 3], r.next)
			(r.peek)()
		), ())
		t('peek of empty list returns ()', (
			r := Reader([])
			(r.peek)()
		), ())
	)

	m('Reader.last')
	(
		t('last character from 0 returns ()', (
			r := Reader('abc')
			(r.last)()
		), ())
		t('last character from middle of string', (
			r := Reader('hawaii')
			each([1, 2, 3], r.next)
			(r.last)()
		), 'w')
		t('last character from past end of string', (
			r := Reader('waikiki')
			each([1, 2, 3, 4, 5, 6, 7, 8, 9], r.next)
			(r.last)()
		), 'i')
		t('last item from 0 returns ()', (
			r := Reader([1, 2, 3, 4, 5])
			(r.last)()
		), ())
		t('last item from middle of list', (
			r := Reader([1, 2, 3, 4, 5])
			each([1, 2, 3], r.next)
			(r.last)()
		), 3)
		t('last item from past end of list', (
			r := Reader(['hi', 'hello', 'aloha'])
			each([1, 2, 3, 4, 5], r.next)
			(r.last)()
		), 'aloha')
	)

	m('Reader.back')
	(
		t('next, back, then next returns same char', (
			r := Reader('abc')
			(r.next)()
			(r.back)()
			(r.next)()
		), 'a')
		t('readUntil, back, readUntil returns correct char', (
			r := Reader('kauai island')
			(r.readUntil)('i')
			(r.back)()
			(r.readUntil)('s')
		), 'ai i')
	)

	m('Reader.next')
	(
		t('next from start of string', (
			r := Reader('abc')
			(r.next)()
		), 'a')
		t('next from middle of string', (
			r := Reader('abc')
			(r.next)()
			(r.next)()
		), 'b')
		t('next from end of string returns ()', (
			r := Reader('abc')
			each([1, 2, 3], r.next)
			(r.next)()
		), ())
	)

	m('Reader.expect?')
	(
		t('returns true with a correct prefix', (
			r := Reader('alphabet')
			(r.expect?)('alpha')
		), true)
		t('returns false with an incorrect prefix', (
			r := Reader('alphabet')
			(r.expect?)('beta')
		), false)
		t('returns false with a substring that is not a prefix', (
			r := Reader('alphabet')
			(r.expect?)('lph')
		), false)
		t('when returns true, moves next() target', (
			r := Reader('alphabet')
			(r.expect?)('alpha')
			(r.next)()
		), 'b')
		t('when returns false, does not move next() target', (
			r := Reader('alphabet')
			(r.expect?)('beta')
			(r.next)()
		), 'a')
	)

	m('Reader.readUntil')
	(
		t('Read until first character returns empty string', (
			r := Reader('abc')
			(r.readUntil)('a')
		), '')
		t('Read until character returns substring in between', (
			r := Reader('taylorswift')
			(r.readUntil)('s')
		), 'taylor')
		t('Read until character that occurs twice returns readUntil first', (
			r := Reader('hawaiian islands')
			(r.readUntil)('i')
		), 'hawa')
		t('readUntil followed by peek returns next character', (
			r := Reader('hawaiian islands')
			(r.readUntil)('s')
			(r.peek)()
		), 's')
		t('readUntil followed by next returns next character', (
			r := Reader('hawaiian islands')
			(r.readUntil)('s')
			(r.next)()
		), 's')
		t('readUntil when char never occurs returns rest of string', (
			r := Reader('hawaiian islands')
			(r.readUntil)('z')
		), 'hawaiian islands')
		t('readUntil for a list returns a list of entries', (
			r := Reader([1, 2, 3, 4, 5, 6])
			(r.next)()
			(r.next)()
			(r.readUntil)(5)
		), [3, 4])
		t('readUntil when item never occurs in list returns rest of list', (
			r := Reader([1, 2, 3, 4, 5, 6])
			(r.next)()
			(r.readUntil)(~1)
		), [2, 3, 4, 5, 6])
	)

	m('Reader.readUntilPrefix')
	(
		t('Read until prefix returns empty string', (
			r := Reader('abc')
			(r.readUntilPrefix)('ab')
		), '')
		t('Read until prefix that exists returns correct substring', (
			r := Reader('abcdefghi')
			(r.next)()
			(r.readUntilPrefix)('fgh')
		), 'bcde')
		t('Read until prefix past a first character match', (
			r := Reader('hawaiian islands')
			(r.readUntilPrefix)('islands')
		), 'hawaiian ')
		t('readUntilPrefix followed by peek returns next character', (
			r := Reader('hawaiian islands')
			(r.readUntilPrefix)('islands')
			(r.peek)()
		), 'i')
		t('readUntilPrefix followed by next returns next character', (
			r := Reader('hawaiian islands')
			(r.readUntilPrefix)('islands')
			(r.next)()
		), 'i')
		t('readUntilPrefix when prefix never occurs returns rest of string', (
			r := Reader('hawaiian islands')
			(r.next)()
			(r.readUntil)('india')
		), 'awaiian islands')
		t('readUntilPrefix for a list returns a list of entries', (
			r := Reader([1, 2, 1, 2, 3, 1, 2, 3, 1, 2, 4])
			each([1, 2, 3], r.next)
			(r.readUntilPrefix)([1, 2, 4])
		), [2, 3, 1, 2, 3])
		t('readUntilPrefix for a list with an incorrect subseq returns rest of list', (
			r := Reader(['hi', 'hello', 'what', 'where', 'how'])
			(r.next)()
			(r.readUntilPrefix)(['what', 'how'])
		), ['hello', 'what', 'where', 'how'])
	)

	m('Reader.readUntilEnd')
	(
		t('Read until end from beginning', (
			r := Reader('first second third')
			(r.readUntilEnd)()
		), 'first second third')
		t('Read until end from middle of string', (
			r := Reader('first second third')
			(r.readUntil)(' ')
			(r.next)()
			(r.readUntilEnd)()
		), 'second third')
	)

	m('Reader.readUntilMatchingDelim')
	(
		t('returns read up to matching delimiter', (
			r := Reader('(some delimited) string')
			(r.next)()
			(r.readUntilMatchingDelim)('(')
		), 'some delimited')
		t('does not swallow matching delimiter', (
			r := Reader('(some delimited) string')
			(r.next)()
			(r.readUntilMatchingDelim)('(')
			(r.next)()
		), ')')
		t('properly reads around matching pairs of delimiters', (
			r := Reader('an (example) [[with]] bracket]s')
			(r.readUntilMatchingDelim)('[')
		), 'an (example) [[with]] bracket')
		t('returns () if no matching delimiter before end of string', (
			r := Reader('this is a very long string')
			(r.readUntilMatchingDelim)('(')
		), ())
		t('returns () if unbalanced matching pairs before end of string', (
			r := Reader('a[bc[[d][xyz]]')
			(r.next)()
			(r.readUntilMatchingDelim)('[')
		), ())
		t('returns read until matching delimiter in list', (
			r := Reader(['(', 'some', 'delimited', ')', 'more', 'text'])
			(r.next)()
			(r.readUntilMatchingDelim)('(')
		), ['some', 'delimited'])
		t('returns () if no matching delimiter before end of list', (
			r := Reader(['this', 'is', 'a', 'very', 'long', 'list'])
			(r.readUntilMatchingDelim)('(')
		), ())
		t('properly reads around matching delimiters in lists', (
			r := Reader(['a', 'b', '(', 'def', ')', ')'])
			(r.readUntilMatchingDelim)('(')
		), ['a', 'b', '(', 'def', ')'])

	)

	m('Reader integrations')
	(
		t('Multiple readUntils in a row', (
			r := Reader('first, second, third, fourth')
			(sub := acc => (r.peek)() :: {
				() -> acc
				_ -> (
					acc.len(acc) := (r.readUntil)(',')
					(r.next)()
					sub(acc)
				)
			})([])
		), ['first', ' second', ' third', ' fourth'])
		t('Multiple readUntilPrefixes in a row', (
			r := Reader('first, second, third, fourth')
			(sub := acc => (r.peek)() :: {
				() -> acc
				_ -> (
					acc.len(acc) := (r.readUntilPrefix)(', ')
					(r.expect?)(', ')
					sub(acc)
				)
			})([])
		), ['first', 'second', 'third', 'fourth'])
	)
)

