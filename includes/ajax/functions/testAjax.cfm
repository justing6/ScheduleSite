<!--- _cfscriptTestAjaxLocation --->
<CFINCLUDE TEMPLATE="/includes/ajax/cfajax.cfm">

<CFFUNCTION NAME="templateFunctionDoNotChangeDoNotMove">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	 

	...  INSERT FUNCTION LOGIC HERE, if appropriate ...

	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">

	...  INSERT FUNCTION OUTPUT HERE, if appropriate ...
	
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "functionNameHere() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>



<!---Function that creates a new reservation with name, phone, email, and time/date--->
<CFFUNCTION NAME="AddReservation">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss')#">
	<CFSET object.VALID = 'true'>
	<CFQUERY datasource="schedule" name = "options">
	select slotlength, concurslots, MaxAdvanceSchedule
	from options
	where ID = 1;
	</CFQUERY>
	<CFSET _maxdate = #DateAdd("d",options.MaxAdvanceSchedule,"#Now()#")#>
<CFIF _inputArray[1] LE _maxdate>
	<CFIF IsDefined("Session.FNAME")>
		<CFQUERY datasource="schedule" name="usersspots">
		SELECT spots.ID
		FROM reservedspot
		INNER JOIN spots
		ON reservedspot.ReservedSlot = spots.ID
		WHERE FirstName = "#Session.FNAME#"
		AND LastName = "#Session.LNAME#"
		AND Email = "#Session.EMAIL#"
		AND spots.Start >= "#_currDateTime#";
		</cfquery>
	</CFIF>
	<CFQUERY datasource="schedule" name="spots">
	select NumOfPeople, ID
	From spots
	where start = '#DateFormat('#_inputArray[1]#',"yyyy-mm-dd")# #TimeFormat('#_inputArray[1]#',"HH:mm:ss")#';
	</CFQUERY>
	<CFIF spots.RecordCount IS 0>
		<cfset _endmin = TimeFormat("#_inputArray[1]#", "H") *60 + TimeFormat("#_inputArray[1]#", "m")+options.slotlength-1>
		<cfset _endmin = _endmin \60 & ':' &  _endmin -((_endmin \60)*60) & ':00'>
		<CFQUERY datasource="schedule">
		Insert into spots
		(Start, End, NumOfPeople)
		VALUES ('#DateFormat('#_inputArray[1]#',"yyyy-mm-dd")# #TimeFormat('#_inputArray[1]#',"HH:mm:ss")#', '#DateFormat('#_inputArray[1]#',"yyyy-mm-dd")# #_endmin#', 0);
		</CFQUERY>
		<CFQUERY datasource="schedule" name="spots">
		select NumOfPeople, ID
		From spots
		where start = '#DateFormat('#_inputArray[1]#',"yyyy-mm-dd")# #TimeFormat('#_inputArray[1]#',"HH:mm:ss")#';
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
		VALUES ('#Session.FNAME#','#Session.LNAME#','#Session.PHONE#','#Session.EMAIL#', '#spots.ID#');
		</CFQUERY>
		<CFQUERY datasource="schedule" name="eventID">
		SELECT reservedspot.ID, spots.Start
		FROM reservedspot
		INNER JOIN spots
		ON reservedspot.ReservedSlot = spots.ID
		WHERE FirstName = '#Session.FNAME#'
		AND LastName = '#Session.LNAME#'
		AND Phone = '#Session.PHONE#'
		AND Email = '#Session.EMAIL#'
		AND ReservedSlot = '#spots.ID#';
		</CFQUERY>
		<CFSET object.FNAME = Session.FNAME>
		<CFSET object.LNAME = Session.LNAME>
		<CFSET object.EMAIL = Session.EMAIL>
		<cflock timeout=20 scope="Session" type="Exclusive"> 
			<cfset StructDelete(Session, "FNAME")>
			<cfset StructDelete(Session, "LNAME")>
			<cfset StructDelete(Session, "EMAIL")>
			<cfset StructDelete(Session, "PHONE")>
		</cflock>
		<CFQUERY datasource="schedule">
		UPDATE spots
		set NumOfPeople = NumOfPeople + 1
		where ID = '#spots.ID#';
		</CFQUERY>
		<CFSET object.DATE = DateFormat(eventID.Start,"yyyy-mm-dd")>
		<CFSET object.SLOT = spots.ID>
	<CFELSEIF spots.NumOfPeople GE options.concurslots>
		<CFSET object.TAKEN = 'true'>
	<CFELSE>
		<CFSET object.SAME = 'true'>
		<CFSET object.FNAME = Session.FNAME>
		<CFSET object.LNAME = Session.LNAME>
		<CFSET object.EMAIL = Session.EMAIL>
	</CFIF>
<CFELSE>
	<CFSET object.VALID = 'false'>
	<CFSET object.MAXDAY = options.MaxAdvanceSchedule>
</CFIF>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "NewReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>


<!--- Function that takes name, phone, and email and if an event that matches is found,
it sets a session variable to it --->
<CFFUNCTION NAME="LookupReservation">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">

	<CFQUERY datasource="schedule" name="reservedspot">
	SELECT reservedspot.ID
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE FirstName = "#_inputArray[1]#"
	AND LastName = "#_inputArray[2]#"
	AND Email = "#_inputArray[3]#"
	AND spots.Start >= "#_currDateTime#";
	</cfquery>
	<CFIF reservedspot.RecordCount IS NOT 0>
		<CFSET _events = "">
		<CFLOOP query="reservedspot">
			<CFIF _events IS "">
				<CFSET _events = reservedspot.ID>
			<CFELSE>
				<CFSET _events = _events & " or reservedspot.ID = " & reservedspot.ID>
			</CFIF>
		</cfloop>
		<CFQUERY datasource="schedule" name="spots">
		SELECT spots.ID
		FROM reservedspot
		INNER JOIN spots
		ON reservedspot.ReservedSlot = spots.ID
		WHERE reservedspot.ID = #_events#
		ORDER BY spots.ID;
		</cfquery>
		<CFSET _spots = "">
		<CFLOOP query="spots">
			<CFIF _spots IS "">
				<CFSET _spots = ID>
			<CFELSE>
				<CFSET _spots = _spots & " AND ID <> " & ID>
			</CFIF>
		</cfloop>
		<cflock timeout=20 scope="Session" type="Exclusive"> 
			<cfset Session.EVENTID = _events>
			<cfset Session.SPOTSID = _spots>
		</cflock>
		<CFSET object.FOUND = "true">
	<CFELSE>
		<CFSET object.FOUND = "false">
	</CFIF>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>	
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "LookupReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<CFFUNCTION NAME="TempPerson">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>

	<cflock timeout=10 scope="Session" type="Exclusive">
		<cfset Session.FNAME = _inputArray[1]>
		<cfset Session.LNAME = _inputArray[2]>
		<cfset Session.PHONE = _inputArray[3]>
		<cfset Session.EMAIL = _inputArray[4]>
	</cflock>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>
	
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "TempPerson() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<CFFUNCTION NAME="FindSpot">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	 
<CFIF IsDefined("Session.FNAME")>
	<cfset object.SESSION = "true">
	<CFQUERY datasource="schedule" name="options">
	select dow, concurslots, wdend, wdstart, PickInAdvance
	FROM options
	WHERE ID = 1;
	</cfquery>
	<CFIF _inputArray[1] < Now()>
		<CFSET _inputArray[1] = Now()>
	</CFIF>
	<CFIF #TimeFormat('#_inputArray[1]#','HH:mm:ss')# GT #TimeFormat('#options.wdend#','HH:mm:ss')#>
		<CFSET _time = #TimeFormat('#options.wdstart#','HH:mm:ss')#>
		<cfset _inputArray[1] = #DateAdd("d", 1, "#_inputArray[1]#")#>
		<cfset _inputArray[1] = #DateFormat('#_inputArray[1]#','yyyy-mm-dd')# & " " & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
	<CFELSE>
		<CFSET _time = #TimeFormat('#_inputArray[1]#','HH:mm:ss')#>
	</CFIF>
	
	<CFQUERY datasource="schedule" name="timeslot">
	SELECT time
	FROM timeslots
	WHERE time >= '#_time#';
	</cfquery>
<CFIF timeslot.RecordCount IS 0>
	<cfset _inputArray[1] = #DateAdd("d", 1, "#_inputArray[1]#")#>
	<cfset _date = #DateFormat('#_inputArray[1]#','yyyy-mm-dd')# & ' ' & #TimeFormat('#options.wdstart#','HH:mm:ss')#>	
<CFELSE>
	<cfset _date = #DateFormat('#_inputArray[1]#','yyyy-mm-dd')# & ' ' & #TimeFormat('#timeslot.time#','HH:mm:ss')#>
</CFIF>
	<cfset _maxsearch = #DateAdd("d", #options.PickInAdvance#, "#_inputArray[1]#")#>
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
	<CFLOOP condition = "#spots.RecordCount# IS NOT 0 AND #_date# LT #_maxsearch# AND #_found# IS 'false'">--->
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
				<cfset _date = #DateFormat('#_date#','yyyy-mm-dd')# & " " & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
			</cfloop>
		</cfif>
	</cfloop>
</CFIF>
<CFIF _found IS 'true'>
	<CFSET object.FOUND = 'true'>
<CFELSE>
	<CFSET object.FOUND = 'false'>
</CFIF>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	<CFIF _found IS 'true'>
	The next available appointment is at #TimeFormat("#_date#","h:mm tt")# on #DateFormat("#_date#","dddd, mmmm d, yyyy")#.
	<cfelse>
	No appointments are available within #options.PickInAdvance# days of this date. Please pick another date.
	</cfif>
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage2">
	<input type="button" onClick="addReservation('#_date#');" value="Yes" id="addResButton">
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT2 = _returnToPage2>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage3">
	<CFIF _found IS 'true'>
	<input type="button" onClick="findSpot2(false);" value="Search Availability" id="addResButton">
	<CFELSE>
	<input type="button" disabled onClick="findSpot2(false);" value="Search Availability" id="addResButton">
	</CFIF>
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT3 = _returnToPage3>
<cfelse>
	<cfset object.SESSION = "false">
</cfif>

	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "functionNameHere() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<CFFUNCTION NAME="LookupReservationEventID">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	 

		<cflock timeout=20 scope="Session" type="Exclusive"> 
			<cfset Session.EVENTID = _inputArray[1]>
		</cflock>
		<CFSET object.FOUND = "true">
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>	
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "LookupReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>