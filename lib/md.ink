std := load('../vendor/std')
str := load('../vendor/str')

cat := std.cat
slice := std.slice
map := std.map
filter := std.filter
reduce := std.reduce
each := std.each
every := std.every
append := std.append
f := std.format
ws? := str.ws?
digit? := str.digit?
letter? := str.letter?
index := str.index
hasPrefix? := str.hasPrefix?
hasSuffix? := str.hasSuffix?
trimPrefix := str.trimPrefix
replace := str.replace
split := str.split

Reader := load('reader').Reader

Newline := char(10)
Tab := char(9)

` Constant Node represents all possible types of AST nodes in the Merlot
Markdown abstract syntax tree. This also maps node types to their HTML tag
names. `
Node := {
	P: 'p'
	Em: 'em'
	Strong: 'strong'
	Strike: 'strike'
	A: 'a'
	H1: 'h1'
	H2: 'h2'
	H3: 'h3'
	H4: 'h4'
	H5: 'h5'
	H6: 'h6'
	Q: 'q'
	Img: 'img'
	Pre: 'pre'
	Code: 'code'
	UList: 'ul'
	OList: 'ol'
	Item: 'li'
	Checkbox: 'checkbox'
	Br: 'br'
	Hr: 'hr'
	Empty: '-empty'
	RawHTML: '-raw-html'
}

` wordChar? reports whether a given character is a "word character", i.e.
whether it is a part of a normal word. It intends to be Unicode-aware and is
used for text token disambiguation. `
wordChar? := c => digit?(c) | letter?(c) | point(c) > 127

` tokenizeText tokenizes a paragraph or paragraph-like Markdown text (like
headers) into a token stream.

This function encapsulates all disambiguation rules for e.g. parens inside A
(link) tag parens, undescores inside words, and escaped special characters with
backslashes. `
tokenizeText := line => (
	reader := Reader(line)

	peek := reader.peek
	next := reader.next

	tokens := ['']
	push := tok => (
		tokens.len(tokens) := tok
		tokens.len(tokens) := ''
	)
	append := suffix =>
		tokens.(len(tokens) - 1) := tokens.(len(tokens) - 1) + suffix

	(sub := () => c := next() :: {
		() -> ()
		` italics & bold `
		'_' -> (
			peek() :: {
				'_' -> (
					next()
					push('__')
				)
				_ -> push('_')
			}
			sub()
		)
		'*' -> (
			peek() :: {
				'*' -> (
					next()
					push('**')
				)
				_ -> push('*')
			}
			sub()
		)
		` \ escapes any character `
		'\\' -> d := next() :: {
			() -> ()
			_ -> sub(append(d))
		}
		` code snippet `
		'`' -> sub(push('`'))
		` strike out `
		'~' -> sub(push('~'))
		'!' -> sub(push('!'))
		'[' -> sub(push('['))
		']' -> sub(push(']'))
		'(' -> sub(push('('))
		')' -> sub(push(')'))
		_ -> sub(append(c))
	})()

	filter(tokens, tok => len(tok) > 0)
)

` unifyTextNodes normalizes a Markdown AST so that runs of consecutive plain
text nodes (strings) are combined into single plain text nodes. `
unifyTextNodes := (nodes, joiner) => reduce(nodes, (acc, child) => type(child) :: {
	'string' -> type(last := acc.(len(acc) - 1)) :: {
		'string' -> acc.(len(acc) - 1) := last + joiner + child
		_ -> acc.len(acc) := child
	}
	_ -> acc.len(acc) := (child.children :: {
		() -> child
		_ -> child.children := unifyTextNodes(child.children, joiner)
	})
}, [])

` parseText takes a stream of inline tokens from a header or paragraph section
of a Markdown document and produces a list of inline AST nodes to be included
in a Node.H or Node.P. `
parseText := tokens => (
	reader := Reader(tokens)

	peek := reader.peek
	next := reader.next
	readUntil := reader.readUntil
	readUntilMatchingDelim := reader.readUntilMatchingDelim

	handleDelimitedRange := (tok, tag, nodes, sub) => range := readUntil(tok) :: {
		() -> sub(nodes.len(nodes) := tok)
		_ -> (
			next() ` swallow trailing tok `
			nodes.len(nodes) := {
				tag: tag
				children: parseText(range)
			}
			sub(nodes)
		)
	}

	nodes := (sub := nodes => tok := next() :: {
		() -> nodes
		'_' -> handleDelimitedRange('_', Node.Em, nodes, sub)
		'__' -> handleDelimitedRange('__', Node.Strong, nodes, sub)
		'*' -> handleDelimitedRange('*', Node.Em, nodes, sub)
		'**' -> handleDelimitedRange('**', Node.Strong, nodes, sub)
		'`' -> handleDelimitedRange('`', Node.Code, nodes, sub)
		'~' -> handleDelimitedRange('~', Node.Strike, nodes, sub)
		'[' -> range := readUntilMatchingDelim('[') :: {
			() -> sub(nodes.len(nodes) := tok)
			['x'] -> (
				next() ` swallow matching ] `
				sub(nodes.len(nodes) := {
					tag: Node.Checkbox
					checked: true
				})
			)
			[' '] -> (
				next() ` swallow matching ] `
				sub(nodes.len(nodes) := {
					tag: Node.Checkbox
					checked: false
				})
			)
			_ -> c := (next() ` swallow matching ] `, next()) :: {
				'(' -> urlRange := readUntilMatchingDelim(c) :: {
					() -> sub(nodes.len(nodes) := tok + cat(range, '') + ']' + c)
					_ -> (
						next() ` swallow matching ) `
						link := {
							tag: Node.A
							href: cat(urlRange, '')
							children: parseText(range)
						}
						sub(nodes.len(nodes) := link)
					)
				}
				() -> sub(nodes.len(nodes) := tok + cat(range, '') + ']')
				_ -> sub(nodes.len(nodes) := tok + cat(range, '') + ']' + c)
			}
		}
		'!' -> peek() :: {
			'[' -> range := (next(), readUntilMatchingDelim('[')) :: {
				() -> sub(nodes.len(nodes) := tok + '[')
				['x'] -> (
					next() ` swallow matching ] `
					nodes.len(nodes) := tok
					sub(nodes.len(nodes) := {
						tag: Node.Checkbox
						checked: true
					})
				)
				[' '] -> (
					next() ` swallow matching ] `
					nodes.len(nodes) := tok
					sub(nodes.len(nodes) := {
						tag: Node.Checkbox
						checked: false
					})
				)
				_ -> c := (next() ` swallow matching ] `, next()) :: {
					'(' -> urlRange := readUntilMatchingDelim(c) :: {
						() -> sub(nodes.len(nodes) := tok + '[' + cat(range, '') + ']' + c)
						_ -> (
							next() ` swallow matching ) `
							img := {
								tag: Node.Img
								alt: cat(range, '')
								src: cat(urlRange, '')
							}
							sub(nodes.len(nodes) := img)
						)
					}
					() -> sub(nodes.len(nodes) := tok + '[' + cat(range, '') + ']')
					_ -> sub(nodes.len(nodes) := tok + '[' + cat(range, '') + ']' + c)
				}
			}
			_ -> sub(nodes.len(nodes) := tok)
		}
		_ -> sub(nodes.len(nodes) := tok)
	})([])

	unifyTextNodes(nodes, '')
)

uListItemLine? := line => line :: {
	() -> false
	_ -> hasPrefix?(trimPrefix(trimPrefix(line, ' '), Tab), '- ')
}

oListItemLine? := line => line :: {
	() -> false
	_ -> (
		trimmedStart := trimPrefix(trimPrefix(line, ' '), Tab)
		dotIndex := index(trimmedStart, '. ') :: {
			~1 -> false
			0 -> false
			_ -> every(map(slice(trimmedStart, 0, dotIndex), digit?))
		}
	)
}

listItemLine? := line => uListItemLine?(line) | oListItemLine?(line)

trimUListGetLevel := reader => (
	level := len((reader.readUntil)('-'))
	each('- ', reader.next)
	level
)

trimOListGetLevel := reader => (
	peek := reader.peek
	next := reader.next

	` read while whitespace `
	level := (sub := i => ws?(peek()) :: {
		true -> (
			next()
			sub(i + 1)
		)
		false -> i
	})(0)

	` swallow until dot `
	(reader.readUntil)('.')
	next()

	` if space after dot, swallow it `
	(reader.peek)() :: {
		' ' -> next()
	}
	level
)

` lineNodeType reports the node type of a particular markdown line for parsing. `
lineNodeType := line => true :: {
	(line = ()) -> ()
	(line = '') -> Node.Empty
	hasPrefix?(line, '# ') -> Node.H1
	hasPrefix?(line, '## ') -> Node.H2
	hasPrefix?(line, '### ') -> Node.H3
	hasPrefix?(line, '#### ') -> Node.H4
	hasPrefix?(line, '##### ') -> Node.H5
	hasPrefix?(line, '###### ') -> Node.H6
	hasPrefix?(line, '>') -> Node.Q
	hasPrefix?(line, '```') -> Node.Pre
	hasPrefix?(line, '---') -> Node.Hr
	hasPrefix?(line, '***') -> Node.Hr
	hasPrefix?(line, '!html ') -> Node.RawHTML
	uListItemLine?(line) -> Node.UList
	oListItemLine?(line) -> Node.OList
	_ -> Node.P
}

` parse parses a byte string of Markdown formatted text into a Markdown AST, by
looking at each line and either changing internal state if the line is a
special line like a code fence or a raw HTML literal, or calling tokenizeText()
if the line is a raw paragraph or header. `
parse := text => parseDoc(Reader(split(text, Newline)))

` parseDoc parses a Markdown docment from a line Reader. This allows
sub-sections of the document to re-use this document parser to parse e.g.
quoted sections that should be parsed as an independent subsection by providing
a line Reader interface. `
parseDoc := lineReader => (
	peek := lineReader.peek
	next := lineReader.next

	(sub := doc => nodeType := lineNodeType(peek()) :: {
		Node.H1 -> sub(doc.len(doc) := parseHeader(nodeType, lineReader))
		Node.H2 -> sub(doc.len(doc) := parseHeader(nodeType, lineReader))
		Node.H3 -> sub(doc.len(doc) := parseHeader(nodeType, lineReader))
		Node.H4 -> sub(doc.len(doc) := parseHeader(nodeType, lineReader))
		Node.H5 -> sub(doc.len(doc) := parseHeader(nodeType, lineReader))
		Node.H6 -> sub(doc.len(doc) := parseHeader(nodeType, lineReader))
		Node.Q -> sub(doc.len(doc) := parseBlockQuote(lineReader))
		Node.Pre -> sub(doc.len(doc) := parseCodeBlock(lineReader))
		Node.UList -> sub(doc.len(doc) := parseList(lineReader, nodeType))
		Node.OList -> sub(doc.len(doc) := parseList(lineReader, nodeType))
		Node.RawHTML -> sub(doc.len(doc) := parseRawHTML(lineReader))
		Node.P -> sub(doc.len(doc) := parseParagraph(lineReader))
		Node.Hr -> (
			next()
			sub(doc.len(doc) := {tag: Node.Hr})
		)
		Node.Empty -> (
			next()
			sub(doc)
		)
		_ -> doc
	})([])
)

parseHeader := (nodeType, lineReader) => (
	line := (lineReader.next)()
	reader := Reader(line)
	(reader.readUntil)(' ')
	(reader.next)()

	text := (reader.readUntilEnd)()
	{
		tag: nodeType
		children: parseText(tokenizeText(text))
	}
)

parseBlockQuote := lineReader => (
	peek := lineReader.peek
	next := lineReader.next

	` A piece of a document inside a quoted block needs to be parsed as if it
	were its own document. The BlockQuotedLineReader provides a line Reader
	that masquerades as a document reader to parseDoc. `
	BlockQuotedLineReader := lineReader => (

		returnIfQuoted := line => lineNodeType(line) :: {
			Node.Q -> slice(line, 1, len(line))
			_ -> ()
		}

		peek := () => returnIfQuoted((lineReader.peek)())
		last := () => returnIfQuoted((lineReader.last)())
		back := () => (lineReader.back)()
		next := () => lineNodeType((lineReader.peek)()) :: {
			Node.Q -> trimPrefix((lineReader.next)(), '>')
			_ -> ()
		}
		expect? := () => () `` NOTE: not implemented
		readUntil := c => (
			lines := (lineReader.readUntil)('>' + c)
			map(lines, line => slice(line, 1, len(line)))
		)
		readUntilPrefix := prefix => (
			lines := (lineReader.readUntilPrefix)('>' + c)
			map(lines, line => slice(line, 1, len(line)))
		)
		readUntilEnd := lineReader.readUntilEnd
		readUntilMatchingDelim := () => () `` NOTE: not implemented

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

	{
		tag: Node.Q
		children: parseDoc(BlockQuotedLineReader(lineReader, '>'))
	}
)

parseCodeBlock := lineReader => (
	peek := lineReader.peek
	next := lineReader.next

	startTag := next() ` swallow starting Pre tag `
	lang := (rest := slice(startTag, 3, len(startTag)) :: {
		'' -> ''
		_ -> rest
	})

	children := (sub := lines => lineNodeType(peek()) :: {
		Node.Pre -> lines
		() -> lines
		_ -> (
			text := next()
			sub(lines.len(lines) := text)
		)
	})([])

	next() ` swallow ending pre tag `

	{
		tag: Node.Pre
		children: [{
			tag: Node.Code
			lang: lang
			children: unifyTextNodes(children, Newline)
		}]
	}
)

parseRawHTML := lineReader => (
	peek := lineReader.peek
	next := lineReader.next

	startMarkLine := next()
	firstLine := slice(startMarkLine, len('!html '), len(startMarkLine))

	children := (sub := lines => lineNodeType(peek()) :: {
		Node.Empty -> lines
		() -> lines
		_ -> (
			text := next()
			sub(lines.len(lines) := text)
		)
	})([firstLine])

	{
		tag: Node.RawHTML
		children: unifyTextNodes(children, Newline)
	}
)

parseList := (lineReader, listType) => (
	peek := lineReader.peek
	next := lineReader.next

	children := (sub := items => listItemLine?(peek()) :: {
		false -> items
		_ -> (
			` TODO: provide a way for one listItem to contain 2+ paragraphs.
			The current convention seems to be that if there is at least one
			multi-paragraph listItem in a UL, every listItem in the UL gets
			<p>s rather than inline text nodes as content. `
			line := next()
			lineType := lineNodeType(line)
			reader := Reader(line)
			trimmer := (lineType :: {
				Node.UList -> trimUListGetLevel
				Node.OList -> trimOListGetLevel
			})
			level := trimmer(reader)

			text := (reader.readUntilEnd)()
			listItem := {
				tag: Node.Item
				level: level
				children: parseText(tokenizeText(text))
			}

			` handle list items that have distinct levels `
			lastItem := items.(len(items) - 1) :: {
				() -> sub(items.len(items) := listItem)
				_ -> lastItem.level :: {
					level -> lineType :: {
						` if the same type of list, continue; otherwise, re-parse `
						listType -> sub(items.len(items) := listItem)
						_ -> (
							(lineReader.back)()
							items
						)
					}
					_ -> lastItem.level < level :: {
						` indent in: begin parsing a separate list `
						true -> (
							(lineReader.back)()
							list := parseList(lineReader, lineType)
							lastItem.children.len(lastItem.children) := list
							sub(items)
						)
						` indent out: give up control in this parsing depth `
						_ -> (
							(lineReader.back)()
							items
						)
					}
				}
			}
		)
	})([])

	` remove the level annotation `
	children := map(children, child => child :: {
		{
			tag: Node.Item
			level: _
			children: _
		} -> {tag: Node.Item, children: child.children}
		_ -> child
	})

	{
		tag: listType
		children: children
	}
)

parseParagraph := lineReader => (
	peek := lineReader.peek
	next := lineReader.next

	children := (sub := lines => lineNodeType(peek()) :: {
		Node.P -> (
			text := next()
			[hasSuffix?(text, '  '), text.(len(text) - 1) = '\\'] :: {
				[true, _] -> (
					append(lines, parseText(tokenizeText(slice(text, 0, len(text) - 2))))
					sub(lines.len(lines) := {tag: Node.Br})
				)
				[_, true] -> (
					append(lines, parseText(tokenizeText(slice(text, 0, len(text) - 1))))
					sub(lines.len(lines) := {tag: Node.Br})
				)
				_ -> sub(append(lines, parseText(tokenizeText(text))))
			}
		)
		_ -> lines
	})([])

	{
		tag: Node.P
		children: unifyTextNodes(children, ' ')
	}
)

` compile transforms a Markdown AST node `
compile := nodes => cat(map(nodes, compileNode), '')

wrapTag := (tag, node) => f('<{{0}}>{{1}}</{{0}}>', [
	tag
	compile(node.children)
])

` compileNode transforms an individual Markdown AST node into HTML `
compileNode := node => type(node) :: {
	'string' -> replace(replace(node, '&', '&amp;'), '<', '&lt;')
	_ -> node.tag :: {
		Node.P -> wrapTag('p', node)
		Node.Em -> wrapTag('em', node)
		Node.Strong -> wrapTag('strong', node)
		Node.Strike -> wrapTag('strike', node)
		Node.A -> f('<a href="{{0}}">{{1}}</a>', [node.href, compile(node.children)])
		Node.H1 -> wrapTag('h1', node)
		Node.H2 -> wrapTag('h2', node)
		Node.H3 -> wrapTag('h3', node)
		Node.H4 -> wrapTag('h4', node)
		Node.H5 -> wrapTag('h5', node)
		Node.H6 -> wrapTag('h6', node)
		Node.Q -> wrapTag('q', node)
		Node.Img -> f('<img alt="{{0}}" src="{{1}}"/>', [
			node.alt
			node.src
		])
		Node.Pre -> wrapTag('pre', node)
		Node.Code -> node.lang :: {
			'' -> wrapTag('code', node)
			() -> wrapTag('code', node)
			_ -> f('<code data-lang="{{0}}">{{1}}</code>', [node.lang, compile(node.children)])
		}
		Node.UList -> wrapTag('ul', node)
		Node.OList -> wrapTag('ol', node)
		Node.Item -> wrapTag('li', node)
		Node.Checkbox -> f('<input type="checkbox" {{0}} />', [node.checked :: {
			true -> 'checked'
			_ -> ''
		}])
		Node.Br -> '<br/>'
		Node.Hr -> '<hr/>'
		Node.RawHTML -> node.children.0
		_ -> f('<span style="color:red">Unknown Markdown node {{0}}</span>', [string(node)])
	}
}

` transform wraps the Merlot Markdown parser and compiler into a single
function to be invoked by the library consumer. `
transform := text => compile(parse(text))

