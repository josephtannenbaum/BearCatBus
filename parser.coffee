strip = (x) -> /^\s*(.*?)\s*$/.exec(x)[1] # thanks mwizard in #coffeescript
tail = (x) -> x[1..]
split = (x) -> x.split(' ')
splitd = (x, d) -> x.split(d)
join = (x) -> ' '.join(x)
mtry_to_hour = (x) ->
	if not (':' in x)
		return parseInt(x)*60
	else
		h = parseInt(x.split(':')[0])
		m = parseInt(x.split(':')[1])
		return h*60 + m


stop_parsed = (ln, stops) ->
	stops.push {lbl: (tail ln), ones: []} # the word 'one' refers to the event of a bus stopping at a stop
ones_parsed = (ln, bus_alias, day_range) ->
	hour_range = (split ln)[0]
	time_step = if '-' in hour_range then (split ln)[1] else null
	if time_step
		time_start = mtry_to_hour hour_range.split('-')[0]
		time_stop = mtry_to_hour hour_range.split('-')[1]
		time_range = (x for x in [time_start..time_stop] by time_step)
	else
		time_range = [mtry_to_hour hour_range]
	return ({t: x, bus: bus_alias, day_range: day_range} for x in time_range)

parsed = (s, aliases, stops) ->
	cstop = null
	cbus = ''
	aliases = {}
	for ln in (strip a for a in s.split('\n'))
		do (ln) ->
			switch ln[0]
				when '#'
					aliases[split tail ln] = join tail split tail ln
				when ';'
					cstop = stop_parsed(ln, stops)
				when '*'
					cdayrange = tail ln
				when '`'
					cbus = tail ln
				else
					cstop.ones += ones_parsed(tail ln, cbus, cdayrange)
	return stops			