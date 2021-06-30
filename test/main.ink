runMarkdownTests := load('md').run
runReaderTests := load('reader').run
runUtilTests := load('util').run

s := (load('../vendor/suite').suite)(
	'Merlot test suite'
)

runMarkdownTests(s.mark, s.test)
runReaderTests(s.mark, s.test)
runUtilTests(s.mark, s.test)

(s.end)()

