` Main application UI `

navigate := url => bind(window.history, 'pushState')(document.title, (), url)

matchScrollProgress := (from, to) => (
	` get scroll percent `
	fromRect := bind(from, 'getBoundingClientRect')()
	scrollPercent := from.scrollTop / (from.scrollHeight - fromRect.height)

	` set scroll percent `
	toRect := bind(to, 'getBoundingClientRect')()
	desiredScrollTop := (to.scrollHeight - toRect.height) * scrollPercent
	to.scrollTop :: {
		desiredScrollTop -> ()
		_ -> to.scrollTop := desiredScrollTop
	}
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
		h('h1', [], ['Merlot.'])
		hae('button', ['icon button addFile'], {}, {
			click: () => fileName := prompt('File name?') :: {
				'' -> ()
				_ -> (
					State.files.len(State.files) := fileName
					State.activeFile := fileName
					render()
				)
			}
		}, ['+'])
	])
	h('nav', [], [
		ha('a', ['button'], {
			href: 'https://github.com/thesephist/merlot'
			target: '_blank'
		}, ['About'])
		hae('button', ['button'], {}, {
			click: () => render(State.editor.mode := (State.editor.mode :: {
				'edit' -> 'preview'
				'preview' -> 'both'
				'both' -> 'edit'
			}))
		}, ['Change view'])
	])
])

FileItem := (file, active?, setActive) => h(
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
			navigate(f('/{{0}}', [file]))
			setActive()
		)
	}, [file])]
)

Sidebar := () => (
	children := []

	items := map(State.files, file => FileItem(
		file
		file = State.activeFile
		() => render(State.activeFile := file)
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
			input: evt => (
				State.content := evt.target.value
				render()
			)
			scroll: evt => preview := bind(document, 'querySelector')('.preview') :: {
				() -> ()
				_ -> matchScrollProgress(evt.target, preview)
			}
		}
		[]
	)
])

Preview := () => h('div', ['preview'], [(
	div := bind(document, 'createElement')('div')
	bind(div.classList, 'add')('preview-content')
	div.innerHTML := transform(State.content)
	div
)])

` globals `

State := {
	sidebar?: true
	files: [
		'Work vs. Play'
		'Ideaflow To-dos'
		'Merlot architecture'
	]
	activeFile: ()
	sortBy: 'name'
	content: '# Welcome to _Merlot_!'
	editor: {
		loading?: false
		mode: 'both'
		colorScheme: 'light'
	}
}

` main app render loop `

root := bind(document, 'querySelector')('#root')
r := Renderer(root)
update := r.update

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

` TODO: temporary, for testing `
State.content := '# Welcome to _Merlot_!

text the rendering _speed_ on this is pretty **not that bad** :)

- first bullet
- second bullet
- xxxxx


```
hello
how are you ding these days?
```

code `block` here :)

## text

---

hello'

render()

