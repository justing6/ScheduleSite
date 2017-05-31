<!--- _cfscriptOptionsAjaxLocation --->
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

<CFFUNCTION NAME="FindSpot" access="public" returnType="string">
<CFARGUMENT NAME="_inputdate" type="string" REQUIRED="YES">
 
<CFTRY>
	 
	<CFQUERY datasource="schedule" name="options">
	select dow, concurslots, wdend, wdstart, PickInAdvance
	FROM options
	WHERE ID = 1;
	</cfquery>
	<CFIF _inputdate < Now()>
		<CFSET _inputdate = Now()>
	</CFIF>
	<CFIF #TimeFormat('#_inputdate#','HH:mm:ss')# GT #TimeFormat('#options.wdend#','HH:mm:ss')#>
		<CFSET _time = #TimeFormat('#options.wdstart#','HH:mm:ss')#>
		<cfset _inputdate = #DateAdd("d", 1, "#_inputdate#")#>
		<cfset _inputdate = #DateFormat('#_inputdate#','yyyy-mm-dd')# & " " & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
	<CFELSE>
		<CFSET _time = #TimeFormat('#_inputdate#','HH:mm:ss')#>
	</CFIF>
	<CFQUERY datasource="schedule" name="timeslot">
	SELECT time
	FROM timeslots
	WHERE time >= '#_time#';
	</cfquery>
<CFIF timeslot.RecordCount IS 0>
	<cfset _inputdate = #DateAdd("d", 1, "#_inputdate#")#>
	<cfset _date = #DateFormat('#_inputdate#','yyyy-mm-dd')# & ' ' & #TimeFormat('#options.wdstart#','HH:mm:ss')#>	
<CFELSE>
	<cfset _date = #DateFormat('#_inputdate#','yyyy-mm-dd')# & ' ' & #TimeFormat('#timeslot.time#','HH:mm:ss')#>
</CFIF>
	<cfset _maxsearch = #DateAdd("d", #options.PickInAdvance#, "#_inputdate#")#>
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
				<cfset _date = #DateFormat('#_date#','yyyy-mm-dd')# & " " & #TimeFormat('#options.wdstart#', 'HH:mm:ss')#>
			</cfloop>
		</cfif>
	</cfloop>
</CFIF>

	<CFCATCH TYPE="Any">
	<CFSET _date = "findSpot() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN _date />
</CFFUNCTION>

<!--- Function that moves a reservation to a different spot when passed event ID and time--->
<CFFUNCTION NAME="MoveReservation" access="public">
<CFARGUMENT NAME="_eventid" type="string" REQUIRED="YES">
<CFARGUMENT NAME="_inputdate" type="string" REQUIRED="YES">
 
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
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
<CFIF _inputdate LE _maxdate>
	
	<CFQUERY datasource="schedule" name="spots">
	select NumOfPeople, ID, Start
	From spots
	where Start <= '#_inputdate#'
	AND End >= '#_inputdate#';
	</CFQUERY>
	
	<CFQUERY datasource="schedule" name="oldspot">
	select ReservedSlot, FirstName, LastName, Email
	From reservedspot
	where ID = '#_eventid#';
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
		WHERE time <= '#_inputdate#'
		AND Endtime >= '#_inputdate#';
		</cfquery>
		<CFQUERY datasource="schedule">
		Insert into spots
		(Start, End, NumOfPeople)
		VALUES ('#DateFormat(#_inputdate#,"yyyy-mm-dd")# #TimeFormat(#timeslot.time#,"HH:mm:ss")#', '#DateFormat(#_inputdate#,"yyyy-mm-dd")# #TimeFormat(#timeslot.Endtime#,"HH:mm:ss")#', 0);
		</CFQUERY>
		<CFQUERY datasource="schedule" name="spots">
		select NumOfPeople, ID, Start
		From spots
		where start = '#DateFormat(#_inputdate#,"yyyy-mm-dd")# #TimeFormat(#timeslot.time#,"HH:mm:ss")#';
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
		WHERE ID = #_eventid#;
		</CFQUERY>
		<CFQUERY datasource="schedule">
		UPDATE spots
		set NumOfPeople = NumOfPeople + 1
		where ID = '#spots.ID#';
		</CFQUERY>
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

<!--- Function that populates the timeslots table --->
<CFFUNCTION NAME="setDurations" access="public" returnType="Struct">
<CFARGUMENT NAME="_slotlength" type="string" REQUIRED="NO" DEFAULT="">

<CFTRY>
<CFSET _changed = 'true'>
<CFQUERY datasource="schedule" name="options">
		Select slotlength, wdstart, wdend, breakstart, breakend
		From options
		where ID = 1;
</CFQUERY>
<CFIF _slotlength IS "">
	<CFSET _slotlength = options.slotlength>
<CFELSEIF _slotlength IS options.slotlength>
	<CFSET _changed = 'false'>
</CFIF>
<CFSET oldlength = options.slotlength>
<CFIF _slotlength\5 IS _slotlength/5 AND _slotlength GT 0 AND _changed IS 'true'>

		<cfset _startmin = TimeFormat("#options.wdstart#", "H") *60 + TimeFormat("#options.wdstart#", "m")>
		<CFIF options.breakstart IS NOT "">
			<cfset _endmin = TimeFormat("#options.breakstart#", "H") *60 + TimeFormat("#options.breakstart#", "m")>
		<cfelse>
			<cfset _endmin = TimeFormat("#options.wdend#", "H") *60 + TimeFormat("#options.wdend#", "m")>
		</cfif>
		<CFIF _slotlength GTE _endmin - _startmin>
			<CFSET _slotlength = (((_endmin - _startmin)\5)*5)>
		</CFIF>
		<CFIF options.breakstart IS NOT "">
			<cfset _startmin = TimeFormat("#options.breakend#", "H") *60 + TimeFormat("#options.breakend#", "m")>
			<cfset _endmin = TimeFormat("#options.wdend#", "H") *60 + TimeFormat("#options.wdend#", "m")>
			<CFIF _slotlength GTE _endmin - _startmin>
				<CFSET _slotlength = (((_endmin - _startmin)\5)*5)>
			</CFIF>
		</CFIF>

		<CFQUERY datasource="schedule">
		Update options
		set slotlength = #_slotlength#
		where ID = 1;
		</CFQUERY>
		
		<CFQUERY datasource="schedule">
		Delete from timeslots;
		</CFQUERY>
		<CFQUERY datasource="schedule" name="options">
		Select slotlength, wdstart, wdend, breakstart, breakend
		From options
		where ID = 1;
		</CFQUERY>
		<cfset _startmin = TimeFormat("#options.wdstart#", "H") *60 + TimeFormat("#options.wdstart#", "m")>
		<CFIF options.breakstart IS NOT "">
			<cfset _endmin = TimeFormat("#options.breakstart#", "H") *60 + TimeFormat("#options.breakstart#", "m")>
		<cfelse>
			<cfset _endmin = TimeFormat("#options.wdend#", "H") *60 + TimeFormat("#options.wdend#", "m")>
		</cfif>
		<cfset _curslot = TimeFormat("#options.wdstart#", "H:m:ss")>
		<cfset _curmin = _startmin>
		<cfset _curendmin = _curmin + options.slotlength-1>
		<cfset _curendhour = _curendmin \60>
		<cfset _curendslot = _curendhour & ':' &  _curendmin -(_curendhour*60) & ':00'>
		<cfset _index = 1>
		<CFLOOP condition="#_endmin# GT #_curendmin#">
		<CFQUERY datasource="schedule">
		insert into timeslots
		(ID, time, Endtime)
		VALUES ('#_index#','#_curslot#', '#_curendslot#');
		</cfquery>
			<cfset _curmin = _curmin + options.slotlength>
			<cfset _curhour = _curmin \60>
			<cfset _curslot = _curhour & ':' &  _curmin -(_curhour*60) & ':00'>
			<cfset _curendmin = _curmin + options.slotlength-1>
			<cfset _curendhour = _curendmin \60>
			<cfset _curendslot = _curendhour & ':' &  _curendmin -(_curendhour*60) & ':00'>
			<cfset _index = _index +1>
		</CFLOOP>
	<CFIF options.breakstart IS NOT "">
		<cfset _startmin = TimeFormat("#options.breakend#", "H") *60 + TimeFormat("#options.breakend#", "m")>
		<cfset _endmin = TimeFormat("#options.wdend#", "H") *60 + TimeFormat("#options.wdend#", "m")>
		<cfset _curslot = TimeFormat("#options.breakend#", "H:m:ss")>
		<cfset _curmin = _startmin>
		<cfset _curendmin = _curmin + options.slotlength-1>
		<cfset _curendhour = _curendmin \60>
		<cfset _curendslot = _curendhour & ':' &  _curendmin -(_curendhour*60) & ':00'>
		<CFLOOP condition="#_endmin# GT #_curendmin#">
		<CFQUERY datasource="schedule">
		insert into timeslots
		(ID, time, Endtime)
		VALUES ('#_index#','#_curslot#', '#_curendslot#');
		</cfquery>
			<cfset _curmin = _curmin + options.slotlength>
			<cfset _curhour = _curmin \60>
			<cfset _curslot = _curhour & ':' &  _curmin -(_curhour*60) & ':00'>
			<cfset _curendmin = _curmin + options.slotlength-1>
			<cfset _curendhour = _curendmin \60>
			<cfset _curendslot = _curendhour & ':' &  _curendmin -(_curendhour*60) & ':00'>
			<cfset _index = _index +1>
		</CFLOOP>
	</cfif>
	<cfquery datasource=schedule name="endslot">
	select time
	from timeslots
	GROUP BY time DESC
	LIMIT 1;
	</cfquery>
	<cfquery datasource="schedule">
	UPDATE options
	SET endslot = "#TimeFormat(endslot.time,"HH:mm:ss")#"
	WHERE ID=1;
	</cfquery>
</cfif>
	<CFSET stuff2.slotlength = _slotlength>
	<CFIF oldlength IS _slotlength>
		<CFSET stuff2.changed = 'false'>
	<CFELSE>
		<CFSET stuff2.changed = 'true'>
	</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET _changed = "setDurations() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</cftry>
<CFRETURN stuff2 />
</CFFUNCTION>

<CFFUNCTION NAME="rescheduleAll" access="public">
 
<CFTRY>
	<CFSET _success = 'true'>
	<CFQUERY datasource="schedule" name="allevents">
	SELECT spots.Start, reservedspot.ID
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#"
	ORDER BY reservedspot.ID;
	</cfquery>
	
	<CFQUERY datasource="schedule">
	DELETE FROM spots
	WHERE spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#";
	</cfquery>
	<CFQUERY datasource="schedule" name="timeslots">
	SELECT ID, time
	FROM timeslots
	ORDER BY ID;
	</cfquery>
	<CFSET index=0>
	<CFLOOP query="allevents">
	<CFSET index2=0>
	<CFSET index=index+1>
	<CFSET _date = FindSpot("#allevents.Start#")>
	<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
	<CFLOOP condition= "#_message.TAKEN# IS 'true'">
		<CFSET _message = MoveReservation("#allevents.ID#", "#FindSpot("#allevents.Start#")#")>
	</CFLOOP>
	<CFLOOP condition= "#_message.SAME# IS 'true'">
		<CFSET index2=index2+1>

		<CFQUERY datasource="schedule" name="curslot">
		SELECT ID
		FROM timeslots
		WHERE time = "#TimeFormat(#_date#,"HH:mm:ss")#";
		</cfquery>
		<CFSET _nextid = #curslot.ID# +1>
		<CFQUERY datasource="schedule" name="nextslot">
		SELECT time
		FROM timeslots
		WHERE ID = #_nextid#;
		</cfquery>
		<CFIF nextslot.RecordCount GT 0>
			<CFSET _newdate = #DateFormat(_date,"yyyy-mm-dd")# & " " & #TimeFormat(nextslot.time, "HH:mm:ss")#>
		<CFELSE>
			<CFSET _newdate = #DateFormat(#DateAdd("d",1,_date)#,"yyyy-mm-dd")# & " 00:00:00">	
		</CFIF>
			<CFSET _date = FindSpot("#_newdate#")>
			<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
		<CFSET stuff.date[index][index2]=_date>
		<CFSET stuff.newdate[index][index2]=_newdate>
	</CFLOOP>
	<CFIF _message.VALID IS 'false'>
		<CFQUERY datasource="schedule">
		Delete
		FROM reservedspot
		WHERE ID = #allevents.id#;
		</cfquery>
		<CFSET _success = 'false'>
	</CFIF>
	</CFLOOP>
	<CFCATCH TYPE="Any">
		<CFSET _success = "rescheduleAll() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>
<CFSET stuff.success=_success>
<CFRETURN stuff />
</CFFUNCTION>

<CFFUNCTION NAME="ChangeWD" access="public">
<CFARGUMENT NAME="_wdstart" type="string" REQUIRED="YES">
<CFARGUMENT NAME="_wdend" type="string" REQUIRED="YES">

<CFTRY>
<CFQUERY datasource="schedule" name="options">
	select ID
	FROM options
	WHERE wdstart = "#TimeFormat(_wdstart,'HH:mm:ss')#"
	AND wdend = "#TimeFormat(_wdend,'HH:mm:ss')#";
	</cfquery>
<CFIF options.RecordCount IS 0>
	<CFIF _wdstart IS NOT _wdend>
		<CFSET _changed = 'true'>
		<CFSET _success = 'true'>
		<CFSET _wdstartmin = Minute(_wdstart)>
		<CFSET _wdstarthour = Hour(_wdstart)>
		<CFSET _wdendmin = Minute(_wdend)>
		<CFSET _wdendhour = Hour(_wdend)>
		<CFIF _wdstartmin GT 30>
			<cfset _wdstartmin=30>
		<CFELSEIF _wdstartmin LT 30>
			<cfset _wdstartmin=00>
		</CFIF>
		<CFIF _wdendmin GT 30>
			<CFSET _wdendhour = _wdendhour + 1>
			<cfset _wdendmin=00>
		<CFELSEIF _wdendmin LT 30 AND _wdendmin GT 0>
			<cfset _wdendmin=30>
		</CFIF>
		<CFSET _calwdstart = #_wdstarthour#&':'&#_wdstartmin#>
		<CFSET _calwdend= #_wdendhour#&':'&#_wdendmin#>
		<cfset _calHeight = 20+42*(#DateDiff("n",_calwdstart,_calwdend)#/60)>
		<CFQUERY datasource="schedule">
		UPDATE options
		SET wdstart = "#TimeFormat(_wdstart,"HH:mm:ss")#",
		wdend = "#TimeFormat(_wdend,"HH:mm:ss")#",
		CalStart = "#_calwdstart#",
		CalEnd = "#_calwdend#",
		calheight = #_calHeight#
		WHERE ID = 1;
		</cfquery>
	<CFELSE>
		<CFSET _changed = 'false'>
	</CFIF>
<CFELSE>
	<CFSET _changed = 'false'>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET _success = "ChangeWD() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN _changed />
</CFFUNCTION>

<CFFUNCTION NAME="ChangeBreak" access="public">
<CFARGUMENT NAME="_breakstart" type="string" REQUIRED="YES">
<CFARGUMENT NAME="_breakend" type="string" REQUIRED="YES">

<CFTRY>
<CFSET _changed = 'false'>
<CFIF _breakstart IS NOT '!'>
	<CFQUERY datasource="schedule" name="options">
		select ID
		FROM options
		WHERE breakstart = "#TimeFormat(_breakstart,'HH:mm:ss')#"
		AND breakend = "#TimeFormat(_breakend,'HH:mm:ss')#";
		</cfquery>
	<CFIF options.RecordCount IS 0>
		<CFIF _breakstart IS NOT _breakend>
			<CFSET _changed = 'true'>
			<CFQUERY datasource="schedule">
			UPDATE options
			SET breakstart = "#TimeFormat(_breakstart,"HH:mm:ss")#",
			breakend = "#TimeFormat(_breakend,"HH:mm:ss")#"
			WHERE ID = 1;
			</cfquery>
		<CFELSE>
			<CFSET _changed = 'true'>
			<CFQUERY datasource="schedule">
			UPDATE options
			SET breakstart = NULL,
			breakend = NULL
			WHERE ID = 1;
			</cfquery>
		</CFIF>
	</CFIF>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET _changed = "ChangeWD() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN _changed />
</CFFUNCTION>


<CFFUNCTION NAME="rescheduleWD" access="public">

<CFTRY>
	<CFSET _success = 'true'>
	<CFQUERY datasource="schedule" name="timeslots">
	SELECT ID, time, Endtime
	FROM timeslots
	ORDER BY ID;
	</cfquery>
	<CFSET _timequery = "">
	<CFLOOP query="timeslots">
		<CFIF _timequery IS "">
			<CFSET _timequery = '(CONVERT(spots.Start,TIME) <> "' & TimeFormat(time,"HH:mm:ss") & '" AND CONVERT(spots.End,TIME) <> "' & TimeFormat(Endtime,"HH:mm:ss") & '")'>
		<CFELSE>
			<CFSET _timequery = _timequery & ' AND (CONVERT(spots.Start,TIME) <> "' & TimeFormat(time,"HH:mm:ss") & '" AND CONVERT(spots.End,TIME) <> "' & TimeFormat(Endtime,"HH:mm:ss") & '")'>
		</CFIF>
	</cfloop>
	<CFQUERY datasource="schedule" name="allevents">
	SELECT spots.Start, reservedspot.ID
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE #_timequery#
	AND spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#"
	ORDER BY reservedspot.ID;
	</cfquery>
	
	<CFQUERY datasource="schedule">
	DELETE 
	FROM spots
	WHERE spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#"
	AND #_timequery#;
	</cfquery>

	<CFSET index=0>
	<CFLOOP query="allevents">
	<CFSET index2=0>
	<CFSET index=index+1>
	<CFSET _date = FindSpot("#allevents.Start#")>
	<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
	<CFLOOP condition= "#_message.TAKEN# IS 'true'">
		<CFSET _message = MoveReservation("#allevents.ID#", "#FindSpot("#allevents.Start#")#")>
	</CFLOOP>
	<CFLOOP condition= "#_message.SAME# IS 'true'">
		<CFSET index2=index2+1>

		<CFQUERY datasource="schedule" name="curslot">
		SELECT ID
		FROM timeslots
		WHERE time = "#TimeFormat(#_date#,"HH:mm:ss")#";
		</cfquery>
		<CFSET _nextid = #curslot.ID# +1>
		<CFQUERY datasource="schedule" name="nextslot">
		SELECT time
		FROM timeslots
		WHERE ID = #_nextid#;
		</cfquery>
		<CFIF nextslot.RecordCount GT 0>
			<CFSET _newdate = #DateFormat(_date,"yyyy-mm-dd")# & " " & #TimeFormat(nextslot.time, "HH:mm:ss")#>
		<CFELSE>
			<CFSET _newdate = #DateFormat(#DateAdd("d",1,_date)#,"yyyy-mm-dd")# & " 00:00:00">	
		</CFIF>
			<CFSET _date = FindSpot("#_newdate#")>
			<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
		<CFSET stuff3.date[index][index2]=_date>
		<CFSET stuff3.newdate[index][index2]=_newdate>
	</CFLOOP>
	<CFIF _message.VALID IS 'false'>
		<CFQUERY datasource="schedule">
		Delete
		FROM reservedspot
		WHERE ID = #allevents.id#
		AND spots.Start > "#DateFormat(Now(),"yyyy-mm-dd")#";
		</cfquery>
		<CFSET _success = 'false'>
	</CFIF>
	</CFLOOP>
	<CFSET _success = allevents.ID>
	<CFCATCH TYPE="Any">
		<CFSET _success = "ChangeWD() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>
<CFSET stuff3.success=_success>
<CFRETURN stuff3 />
</CFFUNCTION>

<CFFUNCTION NAME="ChangeWorkweek" access="public">
<CFARGUMENT NAME="_newdow" type="string" REQUIRED="YES">

<CFTRY>
<CFSET object = CreateObject("Component","cfobject")>
<CFQUERY datasource="schedule" name="options">
Select dow
FROM options
where ID = 1;
</cfquery>
<CFSET _olddow = options.dow>
<CFIF _newdow IS NOT '!'>
	<CFIF _olddow IS NOT _newdow>
		<CFSET object.CHANGED = 'true'>
		<CFQUERY datasource="schedule">
		UPDATE options
		SET dow = "#_newdow#"
		WHERE ID = 1;
		</cfquery>
		<CFSET object.QUERY = "">
		<CFLOOP FROM='0' TO='6' INDEX='i'>
			<CFIF Find('#i#', '#_olddow#') IS NOT 0 AND Find('#i#', '#_newdow#') IS NOT 0>
			<CFELSE>
				<CFIF object.QUERY IS "">
					<CFSET object.QUERY = 'DATE_FORMAT(Start,"%w") = ' & i>
				<CFELSE>
					<CFSET object.QUERY = object.QUERY & ' OR DATE_FORMAT(Start,"%w") = ' & i>
				</CFIF>
			</CFIF>
		</CFLOOP>
	<CFELSE>
		<CFSET object.CHANGED = 'false'>
	</CFIF>
<CFELSE>
	<CFSET object.CHANGED = 'false'>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET object.SUCCESS = "ChangeWorkweek() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object />
</CFFUNCTION>


<CFFUNCTION NAME="rescheduleWW" access="public">
<CFARGUMENT NAME="_query" type="string" REQUIRED="YES">

<CFTRY>
	<CFSET _success = 'true'>
	<CFQUERY datasource="schedule" name="allevents">
	SELECT spots.Start, reservedspot.ID
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE (#_query#)
	AND spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#"
	ORDER BY reservedspot.ID;
	</cfquery>
	
	<CFQUERY datasource="schedule">
	DELETE 
	FROM spots
	WHERE spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#"
	AND (#_query#);
	</cfquery>
	<CFSET index=0>
	<CFLOOP query="allevents">
	<CFSET index2=0>
	<CFSET index=index+1>
	<CFSET _date = FindSpot("#allevents.Start#")>
	<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
	<CFLOOP condition= "#_message.TAKEN# IS 'true'">
		<CFSET _message = MoveReservation("#allevents.ID#", "#FindSpot("#allevents.Start#")#")>
	</CFLOOP>
	<CFLOOP condition= "#_message.SAME# IS 'true'">
		<CFSET index2=index2+1>

		<CFQUERY datasource="schedule" name="curslot">
		SELECT ID
		FROM timeslots
		WHERE time = "#TimeFormat(#_date#,"HH:mm:ss")#";
		</cfquery>
		<CFSET _nextid = #curslot.ID# +1>
		<CFQUERY datasource="schedule" name="nextslot">
		SELECT time
		FROM timeslots
		WHERE ID = #_nextid#;
		</cfquery>
		<CFIF nextslot.RecordCount GT 0>
			<CFSET _newdate = #DateFormat(_date,"yyyy-mm-dd")# & " " & #TimeFormat(nextslot.time, "HH:mm:ss")#>
		<CFELSE>
			<CFSET _newdate = #DateFormat(#DateAdd("d",1,_date)#,"yyyy-mm-dd")# & " 00:00:00">	
		</CFIF>
			<CFSET _date = FindSpot("#_newdate#")>
			<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
		<CFSET stuff4.date[index][index2]=_date>
		<CFSET stuff4.newdate[index][index2]=_newdate>
	</CFLOOP>
	<CFIF _message.VALID IS 'false'>
		<CFQUERY datasource="schedule">
		Delete
		FROM reservedspot
		WHERE ID = #allevents.id#;
		</cfquery>
		<CFSET _success = 'false'>
	</CFIF>
	</CFLOOP>
	<CFCATCH TYPE="Any">
		<CFSET stuff.success = "rescheduleWW() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>
<CFSET stuff4._success=_success>
<CFRETURN stuff4 />
</CFFUNCTION>


<CFFUNCTION NAME="ChangeKeepFor" access="public">
<CFARGUMENT NAME="_past" type="string" REQUIRED="YES">
<CFARGUMENT NAME="_future" type="string" REQUIRED="YES">

<CFTRY>
<CFSET _changed = 'false'>
<CFQUERY datasource="schedule" name="options">
Select MaxAdvanceSchedule, KeepRecordsFor
FROM options
where ID = 1;
</cfquery>
<CFSET _oldpast = options.KeepRecordsFor>
<CFSET _oldfuture = options.MaxAdvanceSchedule>
<CFIF _past IS NOT '!' OR  _future IS NOT '!'>
	<CFIF _oldfuture IS NOT _future OR _oldpast IS NOT _past>
		<CFSET _changed = 'true'>
	<CFQUERY datasource="schedule">
		UPDATE options
		SET MaxAdvanceSchedule = #_future#,
		KeepRecordsFor = #_past#
		WHERE ID = 1;
		</cfquery>
	</CFIF>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET _changed = "ChangeKeepFor() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN _changed />
</CFFUNCTION>


<CFFUNCTION NAME="DropOldAndNew">
 
<CFTRY>
	<CFSET _success = 'true'>
	<cfquery datasource=schedule name="options">
	select KeepRecordsFor, MaxAdvanceSchedule
	from options;
	</cfquery>
	<CFSET _date = #DateAdd("d",-options.KeepRecordsFor,"#Now()#")#>
	<CFSET _minDate = "#dateFormat(_date,'yyyy-mm-dd')# #timeFormat(_date,'HH:mm:ss tt')#">
	<CFSET _date = #DateAdd("d",options.MaxAdvanceSchedule,"#Now()#")#>
	<CFSET _maxDate = "#dateFormat(_date,'yyyy-mm-dd')# #timeFormat(_date,'HH:mm:ss tt')#">
	<CFQUERY datasource="schedule" name="dropold">
	SELECT ID
	FROM spots
	WHERE Start <= "#_minDate#"
	OR Start >= "#_maxDate#"
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
		WHERE Start <= "#_minDate#"
		OR Start >= "#_maxDate#";
		</cfquery>
	</CFIF>
	
	<CFCATCH TYPE="Any">
		<CFSET _success = "DropOldReservations() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN _success>
</CFFUNCTION>
<CFFUNCTION NAME="ChangeConcurslots" access="public">
<CFARGUMENT NAME="_newconcurslots" type="string" REQUIRED="YES">

<CFTRY>
<CFSET _changed = 'false'>
<CFQUERY datasource="schedule" name="options">
Select concurslots
FROM options
where ID = 1;
</cfquery>
<CFSET _oldconcurslots = options.concurslots>
<CFIF _newconcurslots IS NOT '!'>
	<CFIF _newconcurslots IS NOT _oldconcurslots>
		<CFIF _newconcurslots LT _oldconcurslots>
			<CFSET _changed = 'true'>
		</CFIF>
		<CFQUERY datasource="schedule">
		UPDATE options
		SET concurslots = #_newconcurslots#
		WHERE ID = 1;
		</cfquery>
	</CFIF>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET _changed = "ChangeConcurslots() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN _changed />
</CFFUNCTION>


<CFFUNCTION NAME="rescheduleSlots" access="public">

<CFTRY>
	
	<CFSET _success = 'true'>
	<CFQUERY datasource="schedule" name="options">
	SELECT concurslots
	FROM options
	WHERE ID = 1;
	</CFQUERY>
	
	<CFQUERY datasource="schedule" name="allevents">
	SELECT spots.Start, reservedspot.ID
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE spots.NumOfPeople > #options.concurslots#
	AND spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#"
	ORDER BY reservedspot.ID;
	</cfquery>

	<CFQUERY datasource="schedule">
	DELETE 
	FROM spots
	WHERE spots.NumOfPeople > #options.concurslots#
	AND spots.Start >= "#DateFormat(Now(),"yyyy-mm-dd")# #TimeFormat(Now(),"HH:mm:ss")#";
	</cfquery>
	<CFLOOP query="allevents">
	<CFSET index2=0>
	<CFSET index=index+1>
	<CFSET _date = FindSpot("#allevents.Start#")>
	<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
	<CFLOOP condition= "#_message.TAKEN# IS 'true'">
		<CFSET _message = MoveReservation("#allevents.ID#", "#FindSpot("#allevents.Start#")#")>
	</CFLOOP>
	<CFLOOP condition= "#_message.SAME# IS 'true'">
		<CFSET index2=index2+1>
		<CFQUERY datasource="schedule" name="curslot">
		SELECT ID
		FROM timeslots
		WHERE time = "#TimeFormat(#_date#,"HH:mm:ss")#";
		</cfquery>
		<CFSET _nextid = #curslot.ID# +1>
		<CFQUERY datasource="schedule" name="nextslot">
		SELECT time
		FROM timeslots
		WHERE ID = #_nextid#;
		</cfquery>
		<CFIF nextslot.RecordCount GT 0>
			<CFSET _newdate = #DateFormat(_date,"yyyy-mm-dd")# & " " & #TimeFormat(nextslot.time, "HH:mm:ss")#>
		<CFELSE>
			<CFSET _newdate = #DateFormat(#DateAdd("d",1,_date)#,"yyyy-mm-dd")# & " 00:00:00">	
		</CFIF>
			<CFSET _date = FindSpot("#_newdate#")>
			<CFSET _message = MoveReservation("#allevents.ID#", "#_date#")>
		<CFSET stuff5.date[index][index2]=_date>
		<CFSET stuff5.newdate[index][index2]=_newdate>
	</CFLOOP>
	<CFIF _message.VALID IS 'false'>
		<CFQUERY datasource="schedule">
		Delete
		FROM reservedspot
		WHERE ID = #allevents.id#;
		</cfquery>
		<CFSET _success = 'false'>
	</CFIF>
	</CFLOOP>
	<CFCATCH TYPE="Any">
		<CFSET object.output = "rescheduleSlots() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>
<CFSET stuff5.success = _success>
<CFRETURN stuff5 />
</CFFUNCTION>

<CFFUNCTION NAME="SetOptions">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
 
<CFTRY>
	<CFSET all='false'>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _changewd = ChangeWD("#_inputArray[2]#","#_inputArray[3]#")>
	<CFSET _changebreak = ChangeBreak("#_inputArray[4]#","#_inputArray[5]#")>
	<CFSET _changeww = ChangeWorkweek("#_inputArray[6]#")>
	<CFSET _changeKeepFor = ChangeKeepFor("#_inputArray[7]#","#_inputArray[8]#")>
	<CFIF _inputArray[9] IS NOT 0>
		<CFSET _changeConcurslots = ChangeConcurslots("#_inputArray[9]#")>
	</CFIF>
	<CFIF _inputArray[1] IS NOT 0>
		<CFSET _durationchanged = setDurations("#_inputArray[1]#")>
	</CFIF>
	<CFIF _durationchanged.changed IS 'true'>
		<CFSET _rescheduleall = rescheduleAll()>
		<!---<CFSET _message[1] = "Would have run rescheduleall">---->
		<CFSET all='true'>
	<CFELSE>
		<CFIF _changeKeepFor IS 'true' AND all IS NOT 'true'>
			<CFSET _success = DropOldAndNew()>
		</CFIF>
		<CFIF _changewd IS 'true' OR _changebreak IS 'true' AND all IS NOT 'true'>
			<CFSET _duration = setDurations()>
			<CFIF _duration.slotlength IS NOT _inputArray[1]>
				<!---<CFSET _message[2] = "Would have run rescheduleall">---->
				<CFSET _rescheduleall = rescheduleAll()>
				<CFSET all='true'>
			<CFELSE>
				<!---<CFSET _message[3] = "Would have run rescheduleWD">---->
				<CFSET _success1 = rescheduleWD()>
			</CFIF>
		</CFIF>
		<CFIF _changeww.CHANGED IS 'true' AND all IS NOT 'true'>
			<CFSET _success2 = rescheduleWW(_changeww.QUERY)>
			<!---<CFSET _message[4] = "Would have run rescheduleWW">---->
		</CFIF>
		<CFIF _changeConcurslots IS 'true' AND all IS NOT 'true'>
			<!---<CFSET _message[5] = "Would have run rescheduleSlots">---->
			<CFSET _success3= rescheduleSlots()>
		</CFIF>
	</CFIF>
	
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	<!---<CFIF IsDefined("_message")>
	<CFDUMP var=#_message#>
	</CFIF>
	<CFIF IsDefined("_success1")>
	<CFDUMP var=#_success1#>
	</CFIF>
		<CFIF IsDefined("_success2")>
	<CFDUMP var=#_success2#>
	</CFIF>
		<CFIF IsDefined("_success3")>
	<CFDUMP var=#_success3#>
	</CFIF>
	<CFIF IsDefined("_rescheduleall")>
	<CFDUMP var=#_rescheduleall#>
	</CFIF>---->
	</CFSAVECONTENT>
	</CFOUTPUT>
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "SetOptions() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>