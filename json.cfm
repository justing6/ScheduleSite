<cfset startd = url['start'] & " 00:00:00">
<cfset endd = url['end'] & " 00:00:00">
<CFQUERY datasource="schedule" name="options">
Select concurslots, dow, wdstart, wdend, breakstart, breakend
FROM options
where ID = 1;
</cfquery>
<CFQUERY datasource=schedule name="events">
select Start, End, NumOfPeople, ID from spots
where Start >= #DateFormat("#Now()#","yyyy-mm-dd")#
AND Start >= "#startd#"
AND Start <= "#endd#"
AND NumOfPeople > 1;
</cfquery>

<CFQUERY datasource=schedule name="eventsname">
select spots.Start, spots.End, reservedspot.FirstName, reservedspot.LastName, spots.ID
from spots
inner join reservedspot
on spots.ID = reservedspot.ReservedSlot
where Start >= #DateFormat("#Now()#","yyyy-mm-dd")#
AND Start >= "#startd#"
AND Start <= "#endd#"
AND spots.NumOfPeople = 1;
</cfquery>
<cfset _events = "">
<CFLOOP query="events">
	<cfset _start = #DateFormat("#Start#","yyyy-mm-dd")# & 'T' & #TimeFormat("#Start#","HH:mm:ss")#>
	<cfset _end =  #DateFormat("#End#","yyyy-mm-dd")# & 'T' & #TimeFormat("#End#","HH:mm:ss")# >
	<cfset _title = #NumOfPeople# & " People">
<CFIF End < Now()>
	<cfset _tempstruct= {
	"id": "#ID#",
	"title": _title,
	"allDay": false,
	"start": #_start#,
	"end": #_end#,
	"color": "##8E8E8E"
	}>
<CFELSEIF NumOfPeople IS options.concurslots>
	<cfset _tempstruct= {
	"id": "#ID#",
	"title": _title,
	"allDay": false,
	"start": #_start#,
	"end": #_end#,
	"color": "##FF0000"
	}>
<CFELSE>
	<cfset _tempstruct= {
	"id": "#ID#",
	"title": _title,
	"allDay": false,
	"start": #_start#,
	"end": #_end#,
	"color": "##0099FF"
	}>	
</CFIF>
	<cfset _Json =serializeJSON(_tempstruct)>
	<CFIF _events IS "">
		<cfset _events=_Json>
	<CFELSE>
		<cfset _events= _events & ',' & _Json>
	</CFIF>
</CFLOOP>
<CFLOOP query="eventsname">
	<cfset _start = #DateFormat("#Start#","yyyy-mm-dd")# & 'T' & #TimeFormat("#Start#","HH:mm:ss")#>
	<cfset _end =  #DateFormat("#End#","yyyy-mm-dd")# & 'T' & #TimeFormat("#End#","HH:mm:ss")# >
	<cfset _title = "#FirstName# #LastName#">
<CFIF End < Now()>
	<cfset _tempstruct= {
	"id": "#ID#",
	"title": _title,
	"allDay": false,
	"start": #_start#,
	"end": #_end#,
	"color": "##8E8E8E"
	}>
<CFELSE>
	<cfset _tempstruct= {
	"id": "#ID#",
	"title": _title,
	"allDay": false,
	"start": #_start#,
	"end": #_end#,
	"color": "green"
	}>
</CFIF>
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