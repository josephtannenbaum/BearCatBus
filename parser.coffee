strip = (x) -> /^\s*(.*?)\s*$/.exec(x)[1] # thanks mwizard in #coffeescript
tail = (x) -> x[1..]
split = (x) -> x.split(' ')
join = (x) -> ' '.join(x)

alias_parsed = (ln, aliases) ->
	aliases[split tail ln] = join tail split tail ln
stop_parsed = (ln, stops) ->
	stops.push {lbl: (tail ln)}

parsed = (s, aliases, stops) ->
	cstop = null
	for ln in (strip a for a in s.split('\n'))
		do (ln) ->
			switch ln[0]
				when '#'
					alias_parsed(ln, aliases)
				when ';'
					cstop = stop_parsed(ln, stops)
				

