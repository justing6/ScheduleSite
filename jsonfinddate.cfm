<cfset _inputDate= url['date']>
<CFIF _inputDate IS 'now'>
<CFSET _inputDate = Now()>
</CFIF>
<CFTRY>
<!---http://cptgschedule.ddns.net/jsonfinddate.cfm?date=2015-03-16T23:50:00&_=1426574894827---->
<CFQUERY datasource="schedule" name="options">
select dow, concurslots, wdend, wdstart, PickInAdvance
FROM options
WHERE ID = 1;
</cfquery>
	<CFIF _inputDate < Now()>
		<CFSET _inputDate = Now()>
	</CFIF>
	<CFIF #TimeFormat('#_inputDate#','HH:mm:ss')# GT #TimeFormat('#options.wdend#','HH:mm:ss')#>
		<CFSET _time = #TimeFormat('#options.wdstart#','HH:mm:ss')#>
		<cfset _inputDate = #DateAdd("d", 1, "#_inputDate#")#>
		<cfset _inputDate = #DateFormat('#_inputDate#','yyyy-mm-dd')# & " " & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
	<CFELSE>
		<CFSET _time = #TimeFormat('#_inputDate#','HH:mm:ss')#>
	</CFIF>
	<CFQUERY datasource="schedule" name="timeslot">
	SELECT time
	FROM timeslots
	WHERE time >= '#_time#';
	</cfquery>
<CFIF timeslot.RecordCount IS 0>
	<cfset _inputDate = #DateAdd("d", 1, "#_inputDate#")#>
	<cfset _date = #DateFormat('#_inputDate#','yyyy-mm-dd')# & ' ' & #TimeFormat('#options.wdstart#','HH:mm:ss')#>	
<CFELSE>
	<cfset _date = #DateFormat('#_inputDate#','yyyy-mm-dd')# & ' ' & #TimeFormat('#timeslot.time#','HH:mm:ss')#>
</CFIF>
	<cfset _maxsearch = #DateAdd("d", #options.PickInAdvance#, "#_inputDate#")#>
	<CFSET _dow = (#DayOfWeek('#_date#')#) - 1>
	<CFLOOP condition="#Find('#_dow#', '#options.dow#')# IS 0">
		<cfset _date = #DateAdd("d", 1, "#_date#")#>
		<CFSET _dow = (#DayOfWeek('#_date#')#) - 1>
		<cfset _date = #DateFormat('#_date#','yyyy-mm-dd')# & " " & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
	</cfloop>
	<cfset _found = 'true'>
	<CFQUERY datasource="schedule" name="spots">
	SELECT ID, Start
	FROM spots
	WHERE Start = "#_date#"
	AND NumOfPeople = "#options.concurslots#";
	</cfquery>
<CFIF spots.RecordCount IS NOT 0>
	<cfset _found = 'false'>
	<CFQUERY datasource="schedule" name="timeslot">
	SELECT time
	FROM timeslots
	WHERE time > '#TimeFormat('#_date#','HH:mm:ss')#'
	ORDER BY time;
	</cfquery>
	<CFLOOP condition = "#spots.RecordCount# IS NOT 0 AND #_date# LT #_maxsearch# AND #_found# IS 'false'">
		<CFLOOP query = "timeslot">
			<CFQUERY datasource="schedule" name="spots">
			SELECT ID
			FROM spots
			WHERE Start = "#DateFormat('#_date#','yyyy-mm-dd')# #TimeFormat('#timeslot.time#', 'HH:mm:ss')#"
			AND NumOfPeople = "#options.concurslots#";
			</cfquery>
			<CFIF #spots.RecordCount# IS 0>
				<cfset _found = 'true'>
				<CFSET _date = #DateFormat('#_date#','yyyy-mm-dd')# & ' ' & #TimeFormat('#timeslot.time#', 'HH:mm:ss')#>
				<CFBREAK>
			</cfif>
		</cfloop>
		<CFIF _found IS 'false'>
			<CFQUERY datasource="schedule" name="timeslot">
			SELECT time
			FROM timeslots
			ORDER BY time;
			</cfquery>
			<cfset _date = #DateAdd("d", 1, "#_date#")#>
			<CFSET _dow = (#DayOfWeek('#_date#')#) - 1>
			<CFLOOP condition="#Find('#_dow#', '#options.dow#')# IS 0">
				<cfset _date = #DateAdd("d", 1, "#_date#")#>
				<CFSET _dow = (#DayOfWeek('#_date#')#) - 1>
				<cfset _date = #DateFormat('#_date#','yyyy-mm-dd')# & "T" & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
			</cfloop>
		</cfif>
	</cfloop>
</CFIF>

<CFIF _found IS 'true'>
	<cfset _tempstruct= {
		"function":"findID",
		"date": "#DateFormat(_date,"yyyy-mm-dd")#T#TimeFormat(_date,"HH:mm:ss")#",
		"nicetime": "#TimeFormat(_date,"h:mm tt")#",
		"nicedate":"#DateFormat(_date,"dddd, mmmm d, yyyy")#"
		}>
	<cfset _jsondate = serializeJSON(_tempstruct)>
<CFELSE>
	<cfset _jsondate = "">
</CFIF>
		
	<cfset _date = #DateAdd("d", 1, "#_date#")#>
	<CFSET _dow = (#DayOfWeek('#_date#')#) - 1>
	<CFCATCH TYPE="Any">
	<CFSET _date = "FindSlot() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFOUTPUT>
#_jsondate#
</cfoutput>