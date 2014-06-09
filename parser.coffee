aliases = []
stops = []
occt = """
#WS Westside
#LRS Leroy Southside
#OAK Oakdale Mall
#RRT Riviera Ridge
#RES Residential Shuttle
#DCR Downtown Center
#ITC ITC Shuttle
#UP University Plaza
#TC Triple Cities
;University Union
	*M-F
		`WS
			7-13 0:30
			13:20-24 0:20
		`LRS
			8:20-16:20 2:0
			18-24 1:0
		`OAK
			15-22 1:0
		`RRT
			15:30-22:30 1:0
		`RES
			7:15-23:45 0:30
		`DCR
			7:15-23:45 0:30
	*M-R
		`OAK
			23
		`RES
			24:15
	*F
		`DCR
			24:15
;Mohawk/Dickinson
	*M-F
		`TC
			7:15-12:45 0:30
		`UP
			7-21:30 0:30
		`ITC
			7:20-22:00 0:20
	*M-R
		`UP
			24
			24:30
"""

window.strip = (x) -> /^\s*(.*?)\s*$/.exec(x)[1] # thanks mwizard in #coffeescript
window.tail = (x) -> x[1..]
window.split = (x) -> x.split(' ')
window.join = (x) -> x.join(' ')
window.mtry_to_hour = (x) ->
	if not (':' in x)
		return parseInt(x)*60
	else
		h = parseInt(x.split(':')[0])
		m = parseInt(x.split(':')[1])
		return h*60 + m
window.hour_to_mtry = (x) ->
	div = Math.floor(x/60)
	rem = x % 60
	if rem < 10
		return div + ':0' + rem
	else
		return div + ':' + rem



stop_parsed = (ln) ->
	{lbl: (tail(ln)), ones: []} # the word 'one' refers to the event of a bus stopping at a stop

ones_parsed = (ln, bus_alias, day_range) ->
	hour_range = (split(ln))[0]
	time_step = if '-' in hour_range then (split(ln))[1] else null
	if time_step	
		time_start = mtry_to_hour(hour_range.split('-')[0])
		time_stop = mtry_to_hour(hour_range.split('-')[1])
		time_range = (x for x in [time_start..time_stop] by mtry_to_hour(time_step))
	else
		time_range = [mtry_to_hour(hour_range)]
	return ({t: x, bus: bus_alias, day_range: day_range} for x in time_range)

parsed = (s, aliases, stops) ->
	cstop = null
	cbus = ''
	cdayrange = ''
	aliases = {}
	for ln in (strip a for a in s.split('\n'))
		do (ln) ->
			switch ln[0]
				when '#'
					aliases[split tail ln] = join tail split tail ln
				when ';'
					cstop = stop_parsed(ln)
					stops.push(cstop)
				when '*'
					cdayrange = tail(ln)
				when '`'
					cbus = tail(ln)
				else
					cstop.ones = cstop.ones.concat(ones_parsed(ln, cbus, cdayrange))
	return stops

window.stops = parsed(occt, aliases, stops)
window.ones = []
for stop in window.stops
	do (stop) ->
		for one in stop.ones
			do (one) ->
				window.ones.push({id: one.bus, \
								  name: stop.lbl, \ 
								  day_range: one.day_range, \
								  h_depart_time: one.t, \
								  depart_time: moment(hour_to_mtry(one.t),"HH:mm").format("h:mma")})
ones_sortfunc = (a, b) ->
	a.h_depart_time - b.h_depart_time
window.ones.sort(ones_sortfunc)

window.filter_by_location = (ones, loc) ->
	if loc then (one for one in ones when one.name.toLowerCase().indexOf(loc) != -1) else ones

window.filter_by_time = (ones, t) ->
	(one for one in ones when one.h_depart_time >= t)