` application utility tests `

std := load('../vendor/std')

f := std.format
each := std.each

util := load('../lib/util')


run := (m, t) => (
	m('formatNumber')
	(
		formatNumber := util.formatNumber

		TestVals := [
			` normal cases `
			[0, '0']
			[3, '3']
			[27, '27']
			[100, '100']
			[123, '123']
			[7331, '7,331']
			[14243, '14,243']
			[153243, '153,243']
			[8765432, '8,765,432']
			[87654321, '87,654,321']

			` regression tests `
			[1007, '1,007']
			[1023, '1,023']
			[10234, '10,234']
			[10034, '10,034']
			[9000000, '9,000,000']
		]

		each(TestVals, pair => (
			num := pair.0
			result := pair.1

			t(f('correctly formats {{ 0 }}', [num])
				formatNumber(num), result)
		))
	)
)
