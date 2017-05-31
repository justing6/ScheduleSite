<cfset _eventID = url['event']>
<cfset _inputDate = url['date']>

<CFTRY>
	<CFSET data.ERROR = false>
	<CFSET data.SUCCESS=false>
	<CFSET data.SAME = false>
	<CFSET data.TAKEN = false>
	<CFSET data.VALID = true>
	<CFQUERY datasource="schedule" name = "options">
	select slotlength, concurslots, MaxAdvanceSchedule
	from options
	where ID = 1;
	</CFQUERY>
	<CFSET data.MAXDAY = options.MaxAdvanceSchedule>
	<CFSET _maxdate = #DateAdd("d",options.MaxAdvanceSchedule,"#Now()#")#>
<CFIF _inputDate LE _maxdate>
	
	<CFQUERY datasource="schedule" name="spots">
	select NumOfPeople, ID, Start
	From spots
	where Start <= '#_inputDate#'
	AND End >= '#_inputDate#';
	</CFQUERY>
	
	<CFQUERY datasource="schedule" name="oldspot">
	select ReservedSlot, FirstName, LastName, Email
	From reservedspot
	where ID = '#_eventID#';
	</CFQUERY>
<CFIF oldspot.RecordCount GT 0>
	<CFQUERY datasource="schedule" name="usersspots">
	SELECT spots.ID
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	where reservedspot.FirstName = "#oldspot.FirstName#"
	AND reservedspot.LastName = "#oldspot.LastName#"
	AND reservedspot.Email = "#oldspot.Email#";
	</cfquery>
	<CFIF spots.RecordCount IS 0>
		<CFQUERY datasource="schedule" name="timeslot">
		SELECT time, Endtime
		FROM timeslots
		WHERE time <= '#TimeFormat(_inputDate,"HH:mm:ss")#'
		AND Endtime >= '#TimeFormat(_inputDate,"HH:mm:ss")#';
		</cfquery>
		<CFQUERY datasource="schedule">
		Insert into spots
		(Start, End, NumOfPeople)
		VALUES ('#DateFormat(#_inputDate#,"yyyy-mm-dd")# #TimeFormat(#timeslot.time#,"HH:mm:ss")#', '#DateFormat(#_inputDate#,"yyyy-mm-dd")# #TimeFormat(#timeslot.Endtime#,"HH:mm:ss")#', 0);
		</CFQUERY>
		<CFQUERY datasource="schedule" name="spots">
		select NumOfPeople, ID, Start
		From spots
		where start = '#DateFormat(#_inputDate#,"yyyy-mm-dd")# #TimeFormat(#timeslot.time#,"HH:mm:ss")#';
		</CFQUERY>
	</CFIF>
	<CFQUERY dbtype="query" name="check">
	Select ID
	from usersspots
	Where ID = #spots.ID#;
	</cfquery>
	<CFIF spots.NumOfPeople LT options.concurslots AND check.RecordCount IS 0>
		<CFQUERY datasource="schedule">
		UPDATE spots
		set NumOfPeople = NumofPeople - 1
		where ID = '#oldspot.ReservedSlot#';
		</CFQUERY>
		<CFQUERY datasource="schedule">
		UPDATE reservedspot
		SET ReservedSlot = #spots.ID#, ManagerModified = 'Y'
		WHERE ID = #_eventID#;
		</CFQUERY>
		<CFQUERY datasource="schedule">
		UPDATE spots
		set NumOfPeople = NumOfPeople + 1
		where ID = '#spots.ID#';
		</CFQUERY>
		<CFSET data.SUCCESS=true>
	<CFELSEIF spots.NumOfPeople GE options.concurslots>
		<CFSET data.TAKEN = true>
	<CFELSE>
		<CFSET data.SAME = true>
	</CFIF>
<CFELSE>
	<CFSET data.VALID = false>
	<CFSET data.MAXDAY = options.MaxAdvanceSchedule>
</CFIF>
<CFELSE>
	<CFSET data.ERROR = true>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET data.AJAXOUTPUT = "MoveReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>

</CFTRY>
<CFIF oldspot.RecordCount GT 0>
	<cfset _tempstruct= {
		"function":"move",
		"success": #data.SUCCESS#,
		"error": #data.ERROR#,
		"valid": #data.VALID#,
		"same": #data.SAME#,
		"taken": #data.TAKEN#,
		"maxdate": #data.MAXDAY#,
		"fname": "#oldspot.FirstName#",
		"lname": "#oldspot.LastName#",
		"email": "#oldspot.Email#"
		}>
<CFELSE>
	<cfset _tempstruct= {
		"function":"move",
		"error": #data.ERROR#,
		"success": #data.SUCCESS#,
		"valid": #data.VALID#,
		"same": #data.SAME#,
		"taken": #data.TAKEN#,
		"maxdate": #data.MAXDAY#
		}>
</CFIF>
	<cfset _jsondate = serializeJSON(_tempstruct)>


<CFOUTPUT>
#_jsondate#
</cfoutput>
