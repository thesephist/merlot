root := bind(document, 'querySelector')('#root')

Header := state => h('header', [], [
	h('h1', [], 'Merlot.')
	h('nav', [], [
		ha('a', [], {href: 'https://thesephist.com/'}, ['thesephist'])
	])
])

Sidebar := state => h('div', ['sidebar', state.sidebar? :: {true -> 'show'}], [
	'sidebar'
])

App := state => (
	r := Renderer(root)
	update := r.update

	render := () => update(h('div', ['app'], [
		Header(state)
	]))

	{
		render: render
	}
)

render := App({
	sidebar?: true
	files: []
	activeFile: ()
	sortBy: 'name'
	content: ''
	editor: {
		mode: 'edit' `` also 'preview'
		colorScheme: 'light'
	}
}).render
render()

