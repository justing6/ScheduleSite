<!--- _cfscriptAdminAjaxLocation --->
<CFINCLUDE TEMPLATE="/includes/ajax/cfajax.cfm">

<CFFUNCTION NAME="templateFunctionDoNotChangeDoNotMove">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">

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



<!---Function returns table with all people with reservations on the passed timeslot--->
<CFFUNCTION NAME="GetPeople">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">

	<CFQUERY datasource="schedule" name="people">
	select FirstName, LastName, Phone, Email, reservedspot.ID, spots.Start, spots.End
	from reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	where ReservedSlot = "#_inputArray[1]#"
	</cfquery>
<CFIF people.RecordCount GT 0>
	<CFSET object.FOUND = "true">
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">

	<table style="table-layout: fixed; max-width: 2800px" align="center" id="slotinfo">
	<tr>
		<th>Name</th>
		<th>Email</th>
		<th>Phone Number</th>
		<th>Options</th>
	</tr>
	<CFLOOP query="people">
	<tr>
		<td>#FirstName# #LastName#</td>
		<td>#Email#</td>
		<td>#Phone#</td>
		<td><input type="button" onClick="findSpot('true' , '#people.ID#');" value="Reschedule" id="rescheduleButton">
		<input type="button" onClick="deleteReservation(#people.ID#);" value="Delete" id="DeleteButton"></td>
	</tr>
	</CFLOOP>
	</table>
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFSET object.TITLE = 'true'>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
#TimeFormat("#people.Start#","h:mm tt")# to #TimeFormat("#people.End#","h:mm tt")# on #DateFormat("#people.Start#","dddd, mmmm d, yyyy")#
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT2 = _returnToPage>
<CFELSE>
	<CFSET object.FOUND = "false">
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "GetPeople() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<!---Function creates a table with an option button to move one for when a reservation is dragged
and dropped on the calendar--->
<CFFUNCTION NAME="DragDropReservation">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">
	<CFSET object.FOUND = "true">
	<CFQUERY datasource="schedule" name = "options">
	select concurslots
	from options
	where ID = 1;
	</CFQUERY>
	
	<CFQUERY datasource="schedule" name="spots">
	select NumOfPeople, ID, Start
	from spots
	where Start <= "#DateFormat(#_inputArray[2]#,"yyyy-mm-dd")# #TimeFormat(#_inputArray[2]#,"HH:mm:ss")#"
	AND End >= "#DateFormat(#_inputArray[2]#,"yyyy-mm-dd")# #TimeFormat(#_inputArray[2]#,"HH:mm:ss")#";
	</cfquery>
	
<CFIF spots.RecordCount IS 0>
	
	<CFQUERY datasource="schedule" name="people">
	select FirstName, LastName, Phone, Email, ID
	from reservedspot
	where ReservedSlot = "#_inputArray[1]#"
	</cfquery>
	<CFIF people.RecordCount IS 0>
		<CFSET object.FOUND = "false">
		<CFELSEIF #_inputArray[2]# LE #Now()#>
		<CFSET _past = 'true'>
		<CFSET object.FOUND = "true">
	<CFELSE>
		<CFSET _past = 'false'>
		<CFSET object.FOUND = "true">
	</CFIF>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	<CFIF _past IS 'false'>
	<center>
<CFIF people.RecordCount IS NOT 1>
	Which appointment do you want to move to<br>#TimeFormat("#_inputArray[2]#","h:mm tt")# on #DateFormat("#_inputArray[2]#","mmmm d, yyyy")#?
<CFELSE>
	Do you want to move this appointment to<br>#TimeFormat("#_inputArray[2]#","h:mm tt")# on #DateFormat("#_inputArray[2]#","mmmm d, yyyy")#?
</CFIF>
	</center>
	<br>
	<table style="table-layout: fixed; max-width: 2800px" align="center" id="slotinfo">
	<tr>
		<th>Name</th>
		<th>Email</th>
		<th>Phone Number</th>
		<th>Options</th>
	</tr>
	<CFLOOP query="people">
	<tr>
		<td>#FirstName# #LastName#</td>
		<td>#Email#</td>
		<td>#Phone#</td>
		<td><input type="button" onClick="moveReservation(#people.ID#, '#DateFormat(#_inputArray[2]#, "yyyy-mm-dd")# #TimeFormat(#_inputArray[2]#, "HH:mm:ss")#');" value="Confirm" id="ConfirmButton"></td>
	</tr>
	</CFLOOP>
	</table>
	<CFELSE>
	<center><p>You cannot reschedule to a past date.</p></center>
	</CFIF>
	</CFSAVECONTENT>
	</CFOUTPUT>
	
	<CFSET object.AJAXOUTPUT = _returnToPage>
<CFELSEIF spots.NumOfPeople LT options.concurslots>
		<CFQUERY datasource="schedule" name="people">
	select FirstName, LastName, Phone, Email, ID
	from reservedspot
	where ReservedSlot = "#_inputArray[1]#"
	</cfquery>
	<CFIF people.RecordCount IS 0>
		<CFSET object.FOUND = "false">
			<CFSET object.FOUND = "false">
		<CFELSEIF #_inputArray[2]# LE #Now()#>
		<CFSET _past = 'true'>
		<CFSET object.FOUND = "true">
	<CFELSE>
		<CFSET _past = 'false'>
		<CFSET object.FOUND = "true">
	</CFIF>

	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	<CFIF _past IS 'false'>
	<center>
<CFIF people.RecordCount IS NOT 1>
	Which appointment do you want to move to<br>#TimeFormat("#_inputArray[2]#","h:mm tt")# on #DateFormat("#_inputArray[2]#","mmmm d, yyyy")#?
<CFELSE>
	Do you want to move this appointment to<br>#TimeFormat("#_inputArray[2]#","h:mm tt")# on #DateFormat("#_inputArray[2]#","mmmm d, yyyy")#?
</CFIF>
	</center>
	<br>
	<table style="table-layout: fixed; max-width: 2800px" align="center" id="slotinfo">
	<tr>
		<th>Name</th>
		<th>Email</th>
		<th>Phone Number</th>
		<th>Options</th>
	</tr>
	<CFLOOP query="people">
	<tr>
		<td>#FirstName# #LastName#</td>
		<td>#Email#</td>
		<td>#Phone#</td>
		<td><input type="button" onClick="moveReservation(#people.ID#, '#DateFormat(#spots.Start#, "yyyy-mm-dd")# #TimeFormat(#spots.Start#, "HH:mm:ss")#');" value="Confirm" id="confirmButton"></td>
	</tr>
	</CFLOOP>
	</table>
	<CFELSE>
	<center><p>You cannot reschedule to a past date.</p></center>
	</CFIF>
	</CFSAVECONTENT>
	</CFOUTPUT>
	
	<CFSET object.AJAXOUTPUT = _returnToPage>
<CFELSE>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	<center><p>This slot is currently full, you cannot move any appointments here.</p></center>
	</CFSAVECONTENT>
	</CFOUTPUT>
	
	<CFSET object.AJAXOUTPUT = _returnToPage>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "DragDropReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<!--- Function that moves a reservation to a different spot when passed event ID and time--->
<CFFUNCTION NAME="MoveReservation">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">
	<CFSET object.SAME = 'false'>
	<CFSET object.TAKEN = 'false'>
	<CFSET object.VALID = 'true'>
	<CFQUERY datasource="schedule" name = "options">
	select slotlength, concurslots, MaxAdvanceSchedule
	from options
	where ID = 1;
	</CFQUERY>
	<CFSET _maxdate = #DateAdd("d",options.MaxAdvanceSchedule,"#Now()#")#>
<CFIF _inputArray[2] LE _maxdate>
	
	<CFQUERY datasource="schedule" name="spots">
	select NumOfPeople, ID, Start
	From spots
	where Start <= '#_inputArray[2]#'
	AND End >= '#_inputArray[2]#';
	</CFQUERY>
	
	<CFQUERY datasource="schedule" name="oldspot">
	select ReservedSlot, FirstName, LastName, Email
	From reservedspot
	where ID = '#_inputArray[1]#';
	</CFQUERY>
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
		WHERE time <= '#_inputArray[2]#'
		AND Endtime >= '#_inputArray[2]#';
		</cfquery>
		<CFQUERY datasource="schedule">
		Insert into spots
		(Start, End, NumOfPeople)
		VALUES ('#DateFormat(#_inputArray[2]#,"yyyy-mm-dd")# #TimeFormat(#timeslot.time#,"HH:mm:ss")#', '#DateFormat(#_inputArray[2]#,"yyyy-mm-dd")# #TimeFormat(#timeslot.Endtime#,"HH:mm:ss")#', 0);
		</CFQUERY>
		<CFQUERY datasource="schedule" name="spots">
		select NumOfPeople, ID, Start
		From spots
		where start = '#DateFormat(#_inputArray[2]#,"yyyy-mm-dd")# #TimeFormat(#timeslot.time#,"HH:mm:ss")#';
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
		WHERE ID = #_inputArray[1]#;
		</CFQUERY>
		<CFQUERY datasource="schedule">
		UPDATE spots
		set NumOfPeople = NumOfPeople + 1
		where ID = '#spots.ID#';
		</CFQUERY>
		<CFSET object.DATE = _inputArray[2]>
	<CFELSEIF spots.NumOfPeople GE options.concurslots>
		<CFSET object.TAKEN = 'true'>
	<CFELSE>
		<CFSET object.SAME = 'true'>
	</CFIF>

	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
<CFELSE>
	<CFSET object.VALID = 'false'>
	<CFSET object.MAXDAY = options.MaxAdvanceSchedule>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "MoveReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>


<!---Deletes the event with the passed event ID from the table--->
<CFFUNCTION NAME="DeleteReservation">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">

	<CFQUERY datasource="schedule" name="spot">
	select ReservedSlot
	from reservedspot
	where ID = "#_inputArray[1]#";
	</cfquery>
	<CFQUERY datasource="schedule">
	DELETE FROM reservedspot
	where ID = "#_inputArray[1]#";
	</cfquery>
	<CFQUERY datasource="schedule">
	UPDATE spots
	SET NumOfPeople = NumOfPeople - 1
	WHERE ID = "#spot.ReservedSlot#";
	</cfquery>
	<CFSET object.SPOTID = spot.ReservedSlot>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "functionNameHere() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<CFFUNCTION NAME="FindSpot">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	 
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
	<CFIF _found IS 'true'>
	<input type="button" onClick="moveReservation('#_inputArray[2]#','#_date#');" value="Yes" id="addResButton">
	<CFELSE>
	<input type="button" onClick="addReservation('#_date#');" value="Yes" disabled id="addResButton">
	</CFIF>
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT2 = _returnToPage2>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage3">
	<CFIF _found IS 'true'>
	<input type="button" onClick="findSpot('false','#_inputArray[2]#');" value="Search Availability" id="addResButton">
	<CFELSE>
	<input type="button" disabled onClick="findSpot('false','#_inputArray[2]#');" value="Search Availability" id="addResButton">
	
	</CFIF>
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT3 = _returnToPage3>
	<CFQUERY datasource="schedule" name="name">
	SELECT FirstName, LastName
	FROM reservedspot
	WHERE ID = "#_inputArray[2]#";
	</cfquery>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage3">
Reschedule #name.FirstName# #name.LastName#'s Appointment
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT4 = _returnToPage3>
	<CFCATCH TYPE="Any">
	<CFSET object.AJAXOUTPUT = "functionNameHere() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<CFFUNCTION NAME="DropOldReservations">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	
	
	<cfquery datasource=schedule name="options">
	select KeepRecordsFor from options;
	</cfquery>
	<CFSET _date = #DateAdd("d",-options.KeepRecordsFor,"#Now()#")#>
	<CFSET _minDate = "#dateFormat(_date,'yyyy-mm-dd')# #timeFormat(_date,'HH:mm:ss tt')#">
	<CFQUERY datasource="schedule" name="dropold">
	SELECT ID
	FROM spots
	WHERE Start <= "#_minDate#"
	GROUP BY ID;
	</cfquery>
	<CFIF dropold.RecordCount IS NOT 0>
		<CFSET _dropOld = "">
		<CFLOOP query="dropold">
			<CFIF _dropOld IS "">
				<CFSET _dropOld = dropold.ID>
			<CFELSE>
				<CFSET _dropOld = _dropOld & " or ReservedSlot = " & dropold.ID>
			</CFIF>
		</CFLOOP>
		<CFQUERY datasource="schedule">
		Delete
		FROM reservedspot
		WHERE ReservedSlot = #_dropOld#;
		</cfquery>
		<CFQUERY datasource="schedule">
		Delete
		FROM spots
		WHERE Start <= "#_minDate#";
		</cfquery>
	</CFIF>

	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	</CFSAVECONTENT>
	</CFOUTPUT>
	
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "DropOldReservations() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>


<CFFUNCTION NAME="LookupReservation">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">

	<CFQUERY datasource="schedule" name="reservedspot">
	SELECT spots.ID, spots.Start
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE FirstName = "#_inputArray[1]#"
	AND LastName = "#_inputArray[2]#"
	AND Email = "#_inputArray[3]#"
	AND spots.Start >= "#_currDateTime#"
	ORDER BY spots.Start;
	</cfquery>
	<CFIF reservedspot.RecordCount IS NOT 0>
		<CFSET object.DATE = DateFormat(reservedspot.Start,"yyyy-mm-dd")>
		<CFSET object.SLOT = reservedspot.ID>
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
