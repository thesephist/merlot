` Main application UI `

` constants `

PersistenceDelay := 1000

` utility fns `

navigate := url => bind(window.history, 'pushState')(document.title, (), url)

inRange? := (min, max, val) => min < val & val < max

matchScrollProgress := (from, to) => (
	` get scroll percent `
	fromRect := bind(from, 'getBoundingClientRect')()
	scrollPercent := from.scrollTop / (from.scrollHeight - fromRect.height)

	` set scroll percent `
	toRect := bind(to, 'getBoundingClientRect')()
	desiredScrollTop := (to.scrollHeight - toRect.height) * scrollPercent
	inRange?(desiredScrollTop - 2, desiredScrollTop + 2, to.scrollTop) :: {
		true -> ()
		_ -> to.scrollTop := desiredScrollTop
	}
)

withFetch := (url, opts, cb) => (
	State.loading? := true
	render()

	req := fetch(url, opts)
	payload := bind(req, 'then')(resp => bind(resp, 'text')())
	bind(payload, 'then')(data => (
		State.loading? := false
		render()

		cb(data)
	))
)

` a debounce without leading edge, with 2 hard-coded arguments `
delay := (fn, timeout) => (
	S := {
		to: ()
	}
	dateNow := bind(Date, 'now')

	(a, b) => (
		clearTimeout(S.to)
		S.to := setTimeout(() => fn(a, b), timeout)
	)
)

` components `

Link := (name, href) => ha('a', [], {
	href: href
	target: '_blank'
}, name)

Header := () => h('header', [], [
	h('div', ['header-left'], [
		hae('button', ['icon button toggleSidebar'], {}, {
			click: () => render(State.sidebar? := ~(State.sidebar?))
		}, ['☰'])
		State.loading? :: {
			true -> h('h1', [], ['Loading...'])
			_ -> h('h1', [], ['Merlot.'])
		}
		hae('button', ['icon button addFile'], {}, {
			click: addFile
		}, ['+'])
	])
	h('nav', [], [
		ha('a', ['button'], {
			href: 'https://github.com/thesephist/merlot'
			target: '_blank'
		}, ['About'])
		hae('button', ['button'], {}, {
			click: toggleMode
		}, ['Change view'])
	])
])

FileItem := (file, active?) => h(
	'div'
	[
		'file-item'
		active? :: {
			true -> 'active'
			_ -> ''
		}
	]
	[hae('a', [], {href: f('/{{0}}', [file])}, {
		click: evt => (
			bind(evt, 'preventDefault')()
			setActive(file)
		)
	}, [file])]
)

Sidebar := () => (
	children := []

	items := map(State.files, file => FileItem(
		file
		file = State.activeFile
	))

	h('div', ['sidebar', State.sidebar? :: {true -> 'show', _ -> 'hide'}], [
		h('div', ['file-list'], items)
		h('footer', [], [
			h('p', [], [
				'Merlot is a project by '
				Link('Linus', 'https://thesephist.com/')
				' built with '
				Link('Ink', 'https://dotink.co/')
				' and '
				Link('Torus', 'https://github.com/thesephist/torus')
				'.'
			])
		])
	])
)

handleEditorInput := delay(
	evt => (
		State.content := evt.target.value
		render()

		persistImmediately(State.activeFile, State.content)
	)
	PersistenceDelay
)

Editor := () => h('div', ['editor'], [
	hae(
		'textarea'
		['editor-textarea']
		{
			placeholder: 'Say something...'
			value: State.content
			autofocus: true
		}
		{
			input: handleEditorInput
			scroll: evt => preview := bind(document, 'querySelector')('.preview') :: {
				() -> ()
				_ -> matchScrollProgress(evt.target, preview)
			}
		}
		[]
	)
])

Preview := () => hae(
	'div'
	['preview']
	{}
	{
		scroll: evt => editor := bind(document, 'querySelector')('.editor-textarea') :: {
			() -> ()
			_ -> matchScrollProgress(evt.target, editor)
		}
	}
	[(
		div := bind(document, 'createElement')('div')
		bind(div.classList, 'add')('preview-content')
		div.innerHTML := transform(State.content)
		div
	)]
)

` globals `

DefaultMode := () => window.innerWidth < 600 :: {
	true -> 'preview'
	_ -> 'both'
}

State := {
	sidebar?: true
	loading?: false
	files: []
	activeFile: ()
	content: 'loading editor...'
	editor: {
		mode: DefaultMode()
		colorScheme: 'light'
	}
}

setActive := file => (
	navigate(f('/{{0}}', [file]))
	render(State.activeFile := file)
	withFetch(f('/doc/{{0}}', [file]), {}, data => (
		State.content := data
		render()
	))
)

persistImmediately := (name, content) => withFetch(
	f('/doc/{{0}}', [name])
	{
		method: 'PUT'
		body: content
	}
	() => ()
)
persist := delay(persistImmediately, persistImmediately)

` main app render loop `

root := bind(document, 'querySelector')('#root')
r := Renderer(root)
update := r.update

toggleMode := () => render(State.editor.mode := (State.editor.mode :: {
	'edit' -> 'preview'
	'preview' -> 'both'
	'both' -> 'edit'
}))

addFile := () => fileName := prompt('File name?') :: {
	() -> ()
	_ -> (
		State.files.len(State.files) := fileName
		State.editor.mode :: {
			'preview' -> State.editor.mode := DefaultMode()
		}
		render()

		withFetch('/doc/' + fileName, {method: 'PUT', body: ''}, () => (
			setActive(fileName)
		))
	)
}

handleKeyEvents := evt => [evt.key, evt.metaKey | evt.ctrlKey] :: {
	['h', true] -> (
		bind(evt, 'preventDefault')()
		render(State.sidebar? := ~(State.sidebar?))
	)
	['j', true] -> (
		bind(evt, 'preventDefault')()
		toggleMode()
	)
	['k', true] -> (
		bind(evt, 'preventDefault')
		addFile()
	)
	['e', true] -> (
		bind(evt, 'preventDefault')
		ta := bind(document, 'querySelector')('.editor-textarea') :: {
			() -> ()
			_ -> (
			 bind(ta, 'setSelectionRange')(0, 0)
			bind(ta, 'focus')()
			 )
		}
	)
}

render := () => update(h('div', ['app'], [
	Header()
	Sidebar()
	State.editor.mode :: {
		'preview' -> ()
		_ -> Editor()
	}
	State.editor.mode :: {
		'edit' -> ()
		_ -> Preview()
	}
]))

render()

` fasten keyboard events `
bind(document.documentElement, 'addEventListener')('keydown', handleKeyEvents)

` fetch initial data `
withFetch('/doc/', {}, data => (
	files := split(data, Newline)
	State.files := files
	render()

	fileName := slice(location.pathname, 1, len(location.pathname))
	fileName := replace(fileName, '%20', ' ')
	len(filter(files, f => f = fileName)) :: {
		0 -> ()
		_ -> setActive(fileName)
	}
))

