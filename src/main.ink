std := load('../vendor/std')
str := load('../vendor/str')
sort := load('../vendor/quicksort').sort
http := load('../vendor/http')
mime := load('../vendor/mime')
percent := load('../vendor/percent')

log := std.log
f := std.format
cat := std.cat
map := std.map
filter := std.filter
slice := std.slice
readFile := std.readFile
writeFile := std.writeFile
hasSuffix? := str.hasSuffix?
mimeForPath := mime.forPath
pctDecode := percent.decode

md := load('../lib/md')

transform := md.transform

Port := 7650
Newline := char(10)

server := (http.new)()
NotFound := {status: 404, body: 'file not found'}
MethodNotAllowed := {status: 405, body: 'method not allowed'}

serveStatic := path => (req, end) => req.method :: {
	'GET' -> readFile('static/' + path, file => file :: {
		() -> end(NotFound)
		_ -> end({
			status: 200
			headers: {'Content-Type': mimeForPath(path)}
			body: file
		})
	})
	_ -> end(MethodNotAllowed)
}

addRoute := server.addRoute

addRoute('/doc/*fileName', params => (req, end) => req.method :: {
	'GET' -> readFile(f('db/{{0}}.md', [pctDecode(params.fileName)]), file => file :: {
		() -> end(NotFound)
		_ -> end({
			status: 200
			headers: {'Content-Type': 'text/plain'}
			body: file
		})
	})
	'PUT' -> writeFile(f('db/{{0}}.md', [pctDecode(params.fileName)]), req.body, res => res :: {
		true -> end({
			status: 200
			body: ''
		})
		_ -> end({
			status: 500
			body: 'server error'
		})
	})
	'DELETE' -> delete(f('db/{{0}}.md', [pctDecode(params.fileName)]), evt => evt.type :: {
		'end' -> end({
			status: 204
			body: ''
		})
		_ -> end({
			status: 500
			body: 'server error'
		})
	})
	_ -> end(MethodNotAllowed)
})

addRoute('/doc/', params => (req, end) => req.method :: {
	'GET' -> dir('db', evt => evt.type :: {
		'data' -> end({
			status: 200
			headers: {'Content-Type': 'text/plain'}
			body: (
				mdFiles := filter(evt.data, entry => hasSuffix?(entry.name, '.md'))
				mdNames := map(mdFiles, entry => slice(entry.name, 0, len(entry.name) - 3))
				cat(sort(mdNames), Newline)
			)
		})
		_ -> end({status: 500, body: 'server error'})
	})
	_ -> end(MethodNotAllowed)
})

addRoute('/view/*fileName', params => (req, end) => req.method :: {
	'GET' -> readFile(f('db/{{0}}.md', [pctDecode(params.fileName)]), file => file :: {
		() -> end(NotFound)
		_ -> readFile('static/preview.html', tpl => tpl :: {
			() -> end(NotFound)
			_ -> (
				start := time()
				doc := transform(file)
				elapsed := time() - start

				end({
					status: 200
					headers: {'Content-Type': mimeForPath('.html')}
					body: f(tpl, {
						fileName: pctDecode(params.fileName)
						previewHTML: doc
						renderTime: floor(elapsed * 1000) ` in ms `
					})
				})
			)
		})
	})
	_ -> end(MethodNotAllowed)
})

addRoute('/static/*staticPath', params => serveStatic(params.staticPath))
addRoute('/favicon.ico', params => serveStatic('favicon.ico'))
addRoute('/manifest.json', params => serveStatic('manifest.json'))
addRoute('/', params => serveStatic('dyn-index.html'))

start := () => (
	end := (server.start)(Port)
	log(f('Lucerne started, listening on 0.0.0.0:{{0}}', [Port]))
)

start()

