std := load('../vendor/std')
http := load('../vendor/http')
mime := load('../vendor/mime')

log := std.log
f := std.format
readFile := std.readFile
writeFile := std.writeFile
mimeForPath := mime.forPath

md := load('../lib/md')

transform := md.transform

Port := 7650

server := (http.new)()
MethodNotAllowed := {status: 405, body: 'method not allowed'}

serveStatic := path => (req, end) => req.method :: {
	'GET' -> readFile('static/' + path, file => file :: {
		() -> end({status: 404, body: 'file not found'})
		_ -> end({
			status: 200
			headers: {'Content-Type': mimeForPath(path)}
			body: file
		})
	})
	_ -> end(MethodNotAllowed)
}

addRoute := server.addRoute

addRoute('/static/*staticPath', params => serveStatic(params.staticPath))
addRoute('/', params => serveStatic('index.html'))

start := () => (
	end := (server.start)(Port)
	log(f('Lucerne started, listening on 0.0.0.0:{{0}}', [Port]))
)

start()

