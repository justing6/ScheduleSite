<cfset _fname = Replace(url['fname'],'*',' ','all')>
<cfset _lname = Replace(url['lname'],'*',' ','all')>
<cfset _phone = Replace(url['phone'],'*',' ','all')>
<cfset _email = url['email']>
<cfset _inputDate = url['date']>


<CFTRY>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss')#">
	<CFSET data.VALID = true>
	<CFSET data.SUCCESS = false>
	<CFSET data.SAME = false>
	<CFSET data.TAKEN = false>
	<CFQUERY datasource="schedule" name = "options">
	select slotlength, concurslots, MaxAdvanceSchedule
	from options
	where ID = 1;
	</CFQUERY>
	<CFSET data.MAXDAY = options.MaxAdvanceSchedule>
	<CFSET _maxdate = #DateAdd("d",options.MaxAdvanceSchedule,"#Now()#")#>
	
<CFIF _inputDate LE _maxdate>
		<CFQUERY datasource="schedule" name="usersspots">
		SELECT spots.ID
		FROM reservedspot
		INNER JOIN spots
		ON reservedspot.ReservedSlot = spots.ID
		WHERE FirstName = "#_fname#"
		AND LastName = "#_lname#"
		AND Email = "#_email#"
		AND spots.Start >= "#_currDateTime#";
		</cfquery>
	<CFQUERY datasource="schedule" name="spots">
	select NumOfPeople, ID
	From spots
	where start = '#DateFormat('#_inputDate#',"yyyy-mm-dd")# #TimeFormat('#_inputDate#',"HH:mm:ss")#';
	</CFQUERY>
	<CFIF spots.RecordCount IS 0>
		<cfset _endmin = TimeFormat("#_inputDate#", "H") *60 + TimeFormat("#_inputDate#", "m")+options.slotlength-1>
		<cfset _endmin = _endmin \60 & ':' &  _endmin -((_endmin \60)*60) & ':00'>
		<CFQUERY datasource="schedule">
		Insert into spots
		(Start, End, NumOfPeople)
		VALUES ('#DateFormat('#_inputDate#',"yyyy-mm-dd")# #TimeFormat('#_inputDate#',"HH:mm:ss")#', '#DateFormat('#_inputDate#',"yyyy-mm-dd")# #_endmin#', 0);
		</CFQUERY>
		<CFQUERY datasource="schedule" name="spots">
		select NumOfPeople, ID
		From spots
		where start = '#DateFormat('#_inputDate#',"yyyy-mm-dd")# #TimeFormat('#_inputDate#',"HH:mm:ss")#';
		</CFQUERY>
	</CFIF>
	<CFQUERY dbtype="query" name="check">
	Select ID
	from usersspots
	Where ID = #spots.ID#;
	</cfquery>
	<CFIF spots.NumOfPeople LT options.concurslots AND check.RecordCount IS 0>
		<CFQUERY datasource="schedule">
		Insert into reservedspot
		(FirstName, LastName, Phone, Email, ReservedSlot)
		VALUES ('#_fname#','#_lname#','#_phone#','#_email#', '#spots.ID#');
		</CFQUERY>
		<CFQUERY datasource="schedule" name="eventID">
		SELECT reservedspot.ID, spots.Start
		FROM reservedspot
		INNER JOIN spots
		ON reservedspot.ReservedSlot = spots.ID
		WHERE FirstName = '#_fname#'
		AND LastName = '#_lname#'
		AND Phone = '#_phone#'
		AND Email = '#_email#'
		AND ReservedSlot = '#spots.ID#';
		</CFQUERY>
		<CFQUERY datasource="schedule">
		UPDATE spots
		set NumOfPeople = NumOfPeople + 1
		where ID = '#spots.ID#';
		</CFQUERY>
		<CFSET data.SUCCESS = true>
	<CFELSEIF spots.NumOfPeople GE options.concurslots>
		<CFSET data.TAKEN = true>
	<CFELSE>
		<CFSET data.SAME = true>
	</CFIF>
<CFELSE>
	<CFSET data.VALID = false>
	<CFSET data.MAXDAY = options.MaxAdvanceSchedule>
</CFIF>

	<CFCATCH TYPE="Any">
		<CFSET data.AJAXOUTPUT = "NewReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

	<cfset _tempstruct= {
		"function":"add",
		"success": #data.SUCCESS#,
		"valid": #data.VALID#,
		"same": #data.SAME#,
		"taken": #data.TAKEN#,
		"maxdate": #data.MAXDAY#
		}>
	<cfset _jsondate = serializeJSON(_tempstruct)>


<CFOUTPUT>
#_jsondate#
</cfoutput>
