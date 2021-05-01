` Main application UI `

` constants `

PersistenceDelay := 1000

Mobile? := window.innerWidth < 600
Touch? := navigator.maxTouchPoints > 0

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
		false -> to.scrollTop := desiredScrollTop
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

prompt := (str, confirmText, withResp) => (
	r := Renderer(document.body)
	update := r.update

	el := update(h('div', ['modal-wrapper'], [
		h('div', ['modal', 'modal-prompt'], [
			h('div', ['modal-title'], [str])
			h('input', ['modal-input'], [])
			h('div', ['modal-buttons'], [
				hae('button', ['button okButton'], {}, {
					click: () => callback(input.value)
				}, [confirmText])
				hae('button', ['button cancelButton'], {}, {
					click: () => callback(())
				}, ['Cancel'])
			])
		])
	]))

	handleKeys := evt => evt.key :: {
		'Enter' -> callback(input.value)
		'Escape' -> callback(())
	}

	input := bind(document, 'querySelector')('.modal-input')
	bind(input, 'focus')()

	bind(document, 'addEventListener')('keydown', handleKeys)

	callback := s => (
		bind(document.body, 'removeChild')(el)
		bind(document, 'removeEventListener')('keydown', handleKeys)
		withResp(s)
	)
)

confirm := (str, withResp) => (
	r := Renderer(document.body)
	update := r.update

	el := update(h('div', ['modal-wrapper'], [
		h('div', ['modal', 'modal-prompt'], [
			h('div', ['modal-title'], [str])
			h('div', ['modal-buttons'], [
				hae('button', ['button okButton'], {}, {
					click: () => callback(true)
				}, ['Ok'])
				hae('button', ['button cancelButton'], {}, {
					click: () => callback(false)
				}, ['Cancel'])
			])
		])
	]))

	input := bind(document, 'querySelector')('.cancelButton')
	bind(input, 'focus')()

	handleKeys := evt => evt.key :: {
		'Enter' -> callback(true)
		'Escape' -> callback(false)
	}

	bind(document, 'addEventListener')('keydown', handleKeys)

	callback := resp => (
		bind(document.body, 'removeChild')(el)
		bind(document, 'removeEventListener')('keydown', handleKeys)
		withResp(resp)
	)
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
			true -> h('div', ['loading'], [])
			_ -> h('h1', [], ['Merlot.'])
		}
		hae('button', ['icon button addFile'], {}, {
			click: addFile
		}, ['+'])
	])
	h('nav', [], [
		hae('button', ['button'], {}, {
			click: () => toggleColorScheme()
		}, [State.colorScheme :: {'light' -> '☽', 'dark' -> '☉'}])
		ha('a', ['button'], {
			href: f('/view/{{0}}', [State.activeFile])
			target: '_blank'
		}, ['Share'])
		hae('button', ['button'], {}, {click: toggleMode}, [State.editor.mode :: {
			'edit' -> 'Preview'
			'preview' -> 'Full'
			'both' -> 'Editor'
		}])
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
	[
		hae('a', [], {href: f('/{{0}}', [file])}, {
			click: evt => evt.metaKey | evt.ctrlKey :: {
				true -> ()
				_ -> (
					bind(evt, 'preventDefault')()
					window.innerWidth < 600 :: {
						true -> State.sidebar? := false
					}
					setActive(file)
				)
			}
		}, [file])
		hae('button', ['button deleteFile'], {}, {
			click: () => confirm(f('Delete "{{0}}" forever?', [file]), resp => resp :: {
				true -> withFetch('/doc/' + file, {method: 'DELETE'}, () => (
					State.files := filter(State.files, f => ~(f = file))
					setDefaultActiveFile()
					render()
				))
				_ -> ()
			})
		}, ['×'])
	]
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
				Link('Merlot', 'https://github.com/thesephist/merlot')
				' is a project by '
				Link('Linus', 'https://thesephist.com/')
				' built with '
				Link('Ink', 'https://dotink.co/')
				' and '
				Link('Torus', 'https://github.com/thesephist/torus')
				'.'
			])
		])
		hae('div', ['sidebar-shade'], {}, {
			click: () => render(State.sidebar? := ~(State.sidebar?))
		}, [])
	])
)

handleEditorInput := delay(
	(name, content) => (
		render()
		persistImmediately(name, State.content)
	)
	PersistenceDelay
)

Editor := () => h('div', ['editor'], [
	hae(
		'textarea'
		['editor-textarea', State.stale? :: {true -> 'readonly', _ -> ''}]
		{
			placeholder: 'Say something...'
			value: State.content
			autofocus: true
		}
		{
			input: evt => State.stale? :: {
				true -> render()
				_ -> (
					State.content := evt.target.value
					handleEditorInput(State.activeFile, State.content)
				)
			}
			scroll: evt => preview := bind(document, 'querySelector')('.preview') :: {
				() -> ()
				_ -> matchScrollProgress(evt.target, preview)
			}
		}
		[]
	)
])

PreviewCache := {
	content: ''
	preview: ()
}
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
	[State.content :: {
		PreviewCache.content -> PreviewCache.preview
		_ -> (
			div := bind(document, 'createElement')('div')
			bind(div.classList, 'add')('preview-content')
			div.innerHTML := transform(State.content)

			PreviewCache.content := State.content
			PreviewCache.preview := div

			div
		)
	}]
)

` globals `

DefaultMode := () => Mobile? :: {
	true -> 'preview'
	_ -> 'both'
}

State := {
	sidebar?: Mobile? :: {
		true -> false
		_ -> true
	}
	loading?: false
	files: []
	activeFile: ()
	content: 'loading editor...'
	colorScheme: 'light'
	editor: {
		mode: DefaultMode()
	}
}

setActive := file => (
	navigate(f('/{{0}}', [file]))
	document.title := f('{{0}} | Merlot', [file])
	State.stale? := true
	render(State.activeFile := file)

	withFetch(f('/doc/{{0}}', [file]), {}, data => (
		State.stale? := false
		render(State.content := data)

		textarea := bind(document, 'querySelector')('.editor-textarea') :: {
			() -> ()
			_ -> textarea.scrollTop := 0
		}
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
persist := delay(persistImmediately, PersistenceDelay)

` main app render loop `

root := bind(document, 'querySelector')('#root')
r := Renderer(root)
update := r.update

toggleMode := () => render(State.editor.mode := (State.editor.mode :: {
	'edit' -> 'preview'
	'preview' -> 'both'
	'both' -> 'edit'
}))

toggleColorScheme := () => render(State.colorScheme := (State.colorScheme :: {
	'light' -> 'dark'
	'dark' -> 'light'
}))

addFile := () => prompt('File name?', 'Create', fileName => fileName :: {
	() -> ()
	_ -> (
		State.files.len(State.files) := fileName
		sort!(State.files)

		State.editor.mode :: {
			'preview' -> State.editor.mode := DefaultMode()
		}
		render()

		withFetch('/doc/' + fileName, {method: 'PUT', body: ''}, () => (
			setActive(fileName)
			focusEditor()
		))
	)
})

focusEditor := () => ta := bind(document, 'querySelector')('.editor-textarea') :: {
	() -> ()
	_ -> (
		bind(ta, 'setSelectionRange')(0, 0)
		bind(ta, 'focus')()
	)
}

setDefaultActiveFile := () => State.files :: {
	[] -> ()
	_ -> setActive(State.files.0)
}

handleKeyEvents := evt => [evt.key, evt.metaKey | evt.ctrlKey] :: {
	['h', true] -> (
		bind(evt, 'preventDefault')()
		render(State.sidebar? := ~(State.sidebar?))
	)
	['y', true] -> (
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
		focusEditor()
	)
	['.', true] -> (
		bind(evt, 'preventDefault')
		toggleColorScheme()
	)
	['p', true] -> (
		bind(evt, 'preventDefault')
		window.open(f('/view/{{0}}', [State.activeFile]), '_blank')
	)
	[_, true] -> keyNum := number(evt.key) :: {
		() -> ()
		_ -> (
			selection := State.files.(keyNum :: {
				0 -> 9
				_ -> keyNum - 1
			})
			selection :: {
				() -> ()
				_ -> setActive(selection)
			}
		)
	}
}

render := () => (
	document.body.className := State.colorScheme

	update(h('div', ['app', Touch? :: {true -> 'has-touch', _ -> ''}], [
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
)

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
		0 -> setDefaultActiveFile()
		_ -> setActive(fileName)
	}
))

render()

