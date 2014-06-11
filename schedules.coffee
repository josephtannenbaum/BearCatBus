# functional helper functions
flatten = (a) -> [].concat a...

# string/array maipulation helper functions
strcmpl = (a, b) -> a.toLowerCase() == b.toLowerCase()
strcontainsl = (a, b) -> a.toLowerCase().indexOf(b.toLowerCase()) != -1

# day/time formatting helper functions
militaryToMoment = (s) ->
	moment(s, ['HH:mm', 'HH'])
dayrangeToRecur = (s) ->
	days = ['M','T','W','R','F','S','U']
	daysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
	[a, b] = s.split('-')
	a = days.indexOf(a)
	b = days.indexOf(b)
	applicableWeekdays = if b > -1 then daysFull[a..b] else daysFull[a]
	return moment.recur().every(applicableWeekdays).daysOfWeek()
blockToDepartTimeRange = (s) ->
	ret = []
	[startstop, stepStr] = s.split(' ')
	if not stepStr
		[militaryToMoment(startstop)]
	else
		[start, stop] = startstop.split('-').map(militaryToMoment)
		step = militaryToMoment(stepStr)
		ret = [start.clone()]
		while not start.isSame(stop, 'minute')
			start.add(step)
			ret.push(start.clone())
		return ret

# parses schedule object into list of 'ones', i.e. departure events
scheduleParser = (data) -> flatten(flatten(flatten(flatten( for stopName, dayRanges of data
	for dayRange, busCodes of dayRanges
		for busCode, blocks of busCodes
			for block in blocks
				for departTime in blockToDepartTimeRange(block)
					{departTime: departTime, \
					dayRange: dayrangeToRecur(dayRange), \
					strDayRange: dayRange, \
					stopName: stopName, \
					busCode: busCode})))).sort((a, b) -> if a.departTime.isBefore(b.departTime) then -1 else 1)

# ex: {code: 'WS', fullname: 'Westside Shuttle'}
aliasesParser = (data) -> for k, v of data
	{code: k, fullname: v}

# filter functions for 'ones'
id = (a) -> a
stopNameFilter = (loc) -> ((ones) -> ones.filter((one) -> strcontainsl(one.stopName, loc)))
busCodeFilter = (bus)  -> ((ones) -> ones.filter((one) -> strcmpl(one.busCode, bus)))
departTimeFilter = (m) -> ((ones) -> ones.filter((one) -> one.dayRange.matches(m) and one.departTime.isAfter(m, 'minute')))

angular.module("schedules",[])
	.value("aliasesParser", aliasesParser)
	.value("scheduleParser", scheduleParser)
	.filter('oneFilter', () ->
		return (ones, now, selectedLoc, selectedBus) ->
			(if not ones?    then []                               else \
			(if now?         then departTimeFilter(now)            else id)( \
			(if selectedLoc? then stopNameFilter(selectedLoc)      else id)( \
			(if selectedBus? then busCodeFilter(selectedBus.code)  else id)(ones))))
	)