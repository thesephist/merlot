` Main application UI `

` constants `

PersistenceDelay := 1000

Mobile? := window.innerWidth < 600
Touch? := navigator.maxTouchPoints > 0

Tab := char(9)
Newline := char(10)

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

withPersistedFetch := (url, opts, cb) => (
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

getItem := bind(localStorage, 'getItem')
setItem := bind(localStorage, 'setItem')
removeItem := bind(localStorage, 'removeItem')
withLocalFetch := (url, opts, cb) => url :: {
	'/doc/' -> opts.method :: {
		() -> cb(getItem('files'))
		'GET' -> cb(getItem('files'))
		_ -> bind(console, 'warn')(
			bind('Invalid request', 'valueOf')()
			bind(url, 'valueOf')()
			opts
		)
	}
	_ -> opts.method :: {
		() -> cb(getItem(url))
		'GET' -> cb(getItem(url))
		'PUT' -> (
			files := filter(split(getItem('files'), Newline), s => len(s) > 0)
			fileName := (
				urlParts := split(url, '/')
				urlParts.(len(urlParts) - 1)
			)

			` add file to files list if not exists already `
			(sub := i => i :: {
				~1 -> files.len(files) := fileName
				_ -> files.(i) :: {
					fileName -> ()
					_ -> sub(i - 1)
				}
			})(len(files))

			sort!(files)
			setItem('files', cat(files, Newline))

			setItem(url, opts.body)
			cb('')
		)
		'DELETE' -> (
			fileName := (
				urlParts := split(url, '/')
				urlParts.(len(urlParts) - 1)
			)
			files := filter(split(getItem('files'), Newline), s => len(s) > 0)
			files := filter(files, s => ~(s = fileName))
			setItem('files', cat(files, Newline))

			removeItem(url, opts.body)
			cb('')
		)
		_ -> bind(console, 'warn')(
			bind('Invalid request', 'valueOf')()
			bind(url, 'valueOf')()
			opts
		)
	}
}

` Merlot is deployed under two different configurations: one "dynamic" version
that's authenticated and persists data to a database on the server, and one
"static" version that's deployed as a static site and persists data to browser
localStorage. We build both of these versions on top of the exact same codebase
with one switch: the "Authed?" flag. Depending on this flag, we alter which
withFetch() function we use. When Authed? = false, we use withFetch to talk to
localStorage. `
withFetch := (Authed? :: {
	true -> withPersistedFetch
	_ -> (
		getItem('files') :: {
			() -> setItem('files', '')
		}
		withLocalFetch
	)
})

prompt := (str, confirmText, withResp) => (
	r := Renderer(document.body)
	update := r.update

	el := update(h('div', ['modal-wrapper'], [
		h('div', ['modal', 'modal-prompt'], [
			h('div', ['modal-title'], [str])
			h('input', ['modal-input'], [])
			h('div', ['modal-buttons'], [
				hae('button', ['button', 'okButton'], {}, {
					click: () => callback(input.value)
				}, [confirmText])
				hae('button', ['button', 'cancelButton'], {}, {
					click: () => callback(())
				}, ['Cancel'])
			])
		])
	]))

	handleKeys := evt => evt.key :: {
		'Enter' -> (
			bind(evt, 'preventDefault')()
			callback(input.value)
		)
		'Escape' -> (
			bind(evt, 'preventDefault')()
			callback(())
		)
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
				hae('button', ['button', 'okButton'], {}, {
					click: () => callback(true)
				}, ['Ok'])
				hae('button', ['button', 'cancelButton'], {}, {
					click: () => callback(false)
				}, ['Cancel'])
			])
		])
	]))

	input := bind(document, 'querySelector')('.cancelButton')
	bind(input, 'focus')()

	handleKeys := evt => evt.key :: {
		'Enter' -> (
			bind(evt, 'preventDefault')()
			callback(true)
		)
		'Escape' -> (
			bind(evt, 'preventDefault')()
			callback(false)
		)
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
		hae('button', ['icon', 'button', 'toggleSidebar', 'tooltip-right'], {title: 'Toggle sidebar'}, {
			click: () => render(State.sidebar? := ~(State.sidebar?))
		}, ['☰'])
		State.loading? :: {
			true -> h('div', ['loading'], [])
			_ -> h('h1', [], ['Merlot.'])
		}
		hae('button', ['icon', 'button', 'addFile'], {title: 'Add a file'}, {
			click: addFile
		}, ['+'])
	])
	h('nav', [], [
		hae('button', ['button', 'tooltip-left'], {title: 'Change color scheme'}, {
			click: () => toggleColorScheme()
		}, [State.colorScheme :: {'light' -> '☽', 'dark' -> '☉'}])
		Authed? :: {
			false -> ()
			_ -> ha('a', ['button', 'tooltip-left'], {
				href: f('/view/{{0}}', [State.activeFile])
				target: '_blank'
				title: 'Open a preview in its own tab'
			}, ['Share'])
		}
		hae('button', ['button', 'tooltip-left'], {title: 'Change editor mode'}, {click: toggleMode}, [State.editor.mode :: {
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
		hae('button', ['button', 'deleteFile', 'tooltip-left'], {title: 'Delete this file'}, {
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
		persistImmediately(name, content)
	)
	PersistenceDelay
)

Editor := () => (
	readOnly? := State.stale? | State.activeFile = ()

	handleInput := evt => readOnly? :: {
		true -> render()
		_ -> (
			State.content := evt.target.value
			handleEditorInput(State.activeFile, State.content)
		)
	}

	markupSection := (evt, mark) => (
		bind(evt, 'preventDefault')()

		start := evt.target.selectionStart
		end := evt.target.selectionEnd
		[start, end] :: {
			[(), ()] -> ()
			_ -> (
				val := evt.target.value
				front := slice(val, 0, start)
				middle := slice(val, start, end)
				back := slice(val, end, len(val))
				hasSuffix?(front, mark) & hasPrefix?(back, mark) :: {
					true -> (
						evt.target.value := slice(front, 0, len(front) - len(mark)) + middle + slice(back, len(mark), len(back))
						bind(evt.target, 'setSelectionRange')(start - len(mark), end - len(mark))
					)
					_ -> (
						evt.target.value := front + mark + middle + mark + back
						bind(evt.target, 'setSelectionRange')(start + len(mark), end + len(mark))
					)
				}

				handleInput(evt)
			)
		}
	)

	h('div', ['editor'], [
		hae(
			'textarea'
			['editor-textarea', readOnly? :: {true -> 'readonly', _ -> ''}]
			{
				placeholder: 'Say something...'
				value: State.content
				autofocus: true
			}
			{
				input: handleInput
				keydown: evt => [evt.key, evt.metaKey | evt.ctrlKey] :: {
					['Tab', false] -> (
						bind(evt, 'preventDefault')()

						idx := evt.target.selectionStart :: {
							() -> ()
							_ -> (
								val := evt.target.value
								front := slice(val, 0, idx)
								back := slice(val, idx, len(val))
								evt.target.value := front + Tab + back
								bind(evt.target, 'setSelectionRange')(idx + 1, idx + 1)

								handleInput(evt)
							)
						}
					)
					['b', true] -> markupSection(evt, '**')
					['i', true] -> markupSection(evt, '_')
				}
				scroll: evt => preview := bind(document, 'querySelector')('.preview') :: {
					() -> ()
					_ -> matchScrollProgress(evt.target, preview)
				}
			}
			[]
		)
	])
)

PreviewCache := {
	content: ()
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

			` do not let the preview's checkboxes be interactive `
			div.onclick := evt => evt.target.tagName :: {
				'INPUT' -> bind(evt, 'preventDefault')()
			}

			PreviewCache.content := State.content
			PreviewCache.preview := div

			div
		)
	}]
)

` globals `

DefaultMode := () => Mobile? :: {
	true -> 'edit'
	_ -> 'both'
}

State := {
	sidebar?: Mobile? :: {
		true -> false
		_ -> true
	}
	loading?: false
	stale?: false
	files: []
	activeFile: ()
	content: ''
	colorScheme: bind(localStorage, 'getItem')('colorScheme') :: {
		'dark' -> 'dark'
		_ -> 'light'
	}
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

		` this double-rAF trick lets us schedule the callback "after the next
		frame gets rendered", which we need so that we can accurately set the
		scrollTop of the text editor. `
		requestAnimationFrame(() => requestAnimationFrame(() => (
			textarea := bind(document, 'querySelector')('.editor-textarea') :: {
				() -> ()
				_ -> (
					bind(textarea, 'setSelectionRange')(0, 0)
					textarea.scrollTop := 0
				)
			}
		)))
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

toggleColorScheme := () => (
	State.colorScheme := (State.colorScheme :: {
		'light' -> 'dark'
		'dark' -> 'light'
	})
	bind(localStorage, 'setItem')('colorScheme', State.colorScheme)
	render()
)

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
	[] -> (
		document.title := 'Merlot'
		State.activeFile := ()
		State.content := ''
		render()
	)
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
	files := filter(split(data, Newline), s => len(s) > 0)
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

