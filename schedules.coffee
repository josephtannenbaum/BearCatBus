# functional helper functions
flatten = (a) -> [].concat a...
window.invertObj = (obj) -> 
	b = {}
	((b[i] = k for i in obj[k]) for k in Object.keys(obj))
	b

# string/array maipulation helper functions
strcmpl = (a, b) -> a.toLowerCase() == b.toLowerCase()
strcontainsl = (a, b) -> a.toLowerCase().indexOf(b.toLowerCase()) != -1

# day/time helper functions
militaryToMinutes = (s) ->
	[aH, aM] = (parseInt(n, 10) for n in s.split(':'))
	return aH*60 + (if aM then aM else 0)
momentToMinutes = (m) -> m.hours()*60 + m.minutes()
minutesToTraditional = (n) -> moment('00:00','HH:mm').add(n,'m').format('h:mm A')
dayrangeToRecur = (s) ->	# gives us a moment.recur object based on a string such as 'm-f'
	days = ['m','t','w','r','f','s','u']
	daysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
	[a, b] = s.split('-')
	a = days.indexOf(a) 
	b = days.indexOf(b) 
	applicableWeekdays = if b > -1 then daysFull[a..b] else [daysFull[a]]
	return moment.recur().every(applicableWeekdays).daysOfWeek()
blockToDepartTimeRange = (s, baseTimetable, dayRange, busCode) ->
	ret = []
	if (s[0] == '+') # this allows us to condense our schedule
		if baseTimetable	# second pass
			offset = militaryToMinutes(s[1..].split(' ')[0])
			stopName = s[(s.indexOf(' ')+1)..]
			for one in baseTimetable
				if one.stopName == stopName and one.strDayRange == dayRange and one.busCode == busCode
					ret.push(one.departTime + offset)
		return ret
	else
		if baseTimetable	# if we're in the second pass, ignore
			return []
		[startstop, stepStr] = s.split(' ') # this is the case where we have uncondensed data (i.e. no back-referring)
		if not stepStr
			return [militaryToMinutes(startstop)]
		else
			[start, stop] = startstop.split('-').map(militaryToMinutes)
			return (n for n in [start..stop] by militaryToMinutes(stepStr))

# parses schedule object into list of 'ones', i.e. departure events
scheduleParserPass = (data, baseSchedule) -> flatten(flatten(flatten(flatten( for stopName, dayRanges of data
	for dayRange, busCodes of dayRanges
		for busCode, blocks of busCodes
			for block in blocks
				for departTime in blockToDepartTimeRange(block, baseSchedule, dayRange, busCode)
					{departTime: departTime, \
					strDepartTime: minutesToTraditional(departTime), \
					dayRange: dayrangeToRecur(dayRange), \
					strDayRange: dayRange, \
					stopName: stopName, \
					busCode: busCode}))))

scheduleParser = (data) ->
	ret = scheduleParserPass(data, null) # first pass for uncondensed base schedule
	ret.concat(scheduleParserPass(data, ret)) # second pass for remaining condensed schedule
	   .sort((a, b) -> a.departTime - b.departTime) # sort from earliest to latest
	   

# ex: {code: 'WS', fullname: 'Westside Shuttle'}
aliasesParser = (data) -> for k, v of data
	{busCode: k, fullname: v}

# filter functions for 'ones'
id = (a) -> a
stopNameFilter = (loc) -> ((ones) -> ones.filter((one) -> strcontainsl(one.stopName, loc)))
busCodeFilter = (bus)  -> ((ones) -> ones.filter((one) -> strcmpl(one.busCode, bus)))
departTimeFilter = (m) -> ((ones) -> ones.filter((one) -> one.dayRange.matches(m) and one.departTime >= momentToMinutes(m)))
onesFilter = (ones=[], selectedLoc, selectedBus, msg) -> 
	if ones.length
		byLoc = (if selectedLoc then stopNameFilter(selectedLoc) else id)
		byBus = (if selectedBus then busCodeFilter(selectedBus) else id)
		ret = byLoc(byBus(ones))
		msg.s = if ret.length == 0 then 'Nothing found!' else 'Showing '+(ret[..25].length)+' results (max 26):'
		ret[..25]	
	else ones

angular.module('schedules',[])
	.value('aliasesParser', aliasesParser)
	.value('scheduleParser', scheduleParser)
	.value('departTimeFilter', departTimeFilter)
	.filter('oneFilter', () -> onesFilter)
