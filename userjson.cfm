
<cfset startd = url['start'] & " 00:00:00">
<cfset endd = url['end'] & " 00:00:00">
<CFQUERY datasource="schedule" name="options">
Select concurslots, dow,breakstart,breakend
FROM options
where ID = 1;
</cfquery>


<cfset _events = "">
<cfif IsDefined("Session.EVENTID")>
	<CFQUERY datasource=schedule name="userevent">
	select spots.Start, spots.End, reservedspot.FirstName, reservedspot.LastName, reservedspot.ID
	from reservedspot
	inner join spots
	on reservedspot.ReservedSlot = spots.ID
	where reservedspot.ID = #Session.EVENTID#;
	</cfquery>

	<CFQUERY datasource=schedule name="fullspots">
	select Start, End from spots
	where Start >= #DateFormat("#Now()#","yyyy-mm-dd")#
	AND Start >= "#startd#"
	AND Start <= "#endd#"
	AND NumOfPeople = "#options.concurslots#"
	AND ID <> #Session.SPOTSID#;
	</cfquery>

	<CFLOOP query="userevent">
		<cfset _start = #DateFormat("#userevent.Start#","yyyy-mm-dd")# & 'T' & #TimeFormat("#userevent.Start#","HH:mm:ss")#>
		<cfset _end =  #DateFormat("#userevent.End#","yyyy-mm-dd")# & 'T' & #TimeFormat("#userevent.End#","HH:mm:ss")# >
		<cfset _title = "#userevent.FirstName# #userevent.LastName#">
		<cfset _tempstruct= {
		"id": "#userevent.ID#",
		"title": _title,
		"allDay": false,
		"start": #_start#,
		"end": #_end#,
		"color": "##0099FF"
		}>
		<cfset _Json =serializeJSON(_tempstruct)>
		<CFIF _events IS "">
			<cfset _events=_Json>
		<CFELSE>
			<cfset _events= _events & ',' & _Json>
		</CFIF>
	</CFLOOP>
<CFELSE>
	<CFQUERY datasource=schedule name="fullspots">
	select Start, End from spots
	where Start >= #DateFormat("#Now()#","yyyy-mm-dd")#
	AND Start >= "#startd#"
	AND Start <= "#endd#"
	AND NumOfPeople = "#options.concurslots#";
	</cfquery>
</CFIF>
<CFLOOP query="fullspots">
	<cfset _start = #DateFormat("#Start#","yyyy-mm-dd")# & 'T' & #TimeFormat("#Start#","HH:mm:ss")#>
	<cfset _end =  #DateFormat("#End#","yyyy-mm-dd")# & 'T' & #TimeFormat("#End#","HH:mm:ss")# >
	<cfset _tempstruct= {
	"allDay": false,
	"start": #_start#,
	"end": #_end#,
	"color": "red",
	"rendering": "background"
	}>
	<cfset _Json =serializeJSON(_tempstruct)>
	<CFIF _events IS "">
		<cfset _events=_Json>
	<CFELSE>
		<cfset _events= _events & ',' & _Json>
	</CFIF>
</CFLOOP>

<CFSET _dow = (#DayOfWeek('#startd#')#) - 1>
<CFSET _date = startd>
<CFLOOP condition="#_date# LE #endd#">
	<CFIF #Find('#_dow#', '#options.dow#')# IS NOT 0>
	<CFIF options.breakstart IS NOT "">
		<CFSET _start = #DateFormat("#_date#","yyyy-mm-dd")# & 'T' & #TimeFormat('#DateAdd("s", 1, "#options.breakstart#")#','HH:mm:ss')#>
		<CFSET _end = #DateFormat("#_date#","yyyy-mm-dd")# & 'T' & #TimeFormat('#DateAdd("s", -1, "#options.breakend#")#','HH:mm:ss')#>		
		<cfset _tempstruct= {
		"allDay": false,
		"start": #_start#,
		"end": #_end#,
		"color": "##D3D3D3",
		"rendering": "background",
		"overlap": false
		}>
		<cfset _Json =serializeJSON(_tempstruct)>
		<CFIF _events IS "">
		<cfset _events=_Json>
	<CFELSE>
		<cfset _events= _events & ',' & _Json>
	</CFIF>
	</cfif>	
	</CFIF>
	<cfset _date = #DateAdd("d", 1, "#_date#")#>
	<CFSET _dow = (#DayOfWeek('#_date#')#) - 1>
</cfloop>
<CFOUTPUT>
[#_events#]
</cfoutput>

