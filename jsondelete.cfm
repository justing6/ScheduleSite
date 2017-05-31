<cfset _eventID = url['event']>

<!---http://cptgschedule.ddns.net/jsondelete.cfm?event=6676&_=1426574894827---->
<CFTRY>
	<CFSET data.SUCCESS=false>
	<CFSET data.FOUND = false>
	<CFQUERY datasource="schedule" name="spot">
	select ReservedSlot
	from reservedspot
	where ID = "#_eventID#";
	</cfquery>
<CFIF spot.RecordCount IS 1>
	<CFSET data.FOUND = true>
	<CFQUERY datasource="schedule">
	DELETE FROM reservedspot
	where ID = "#_eventID#";
	</cfquery>
	<CFQUERY datasource="schedule">
	UPDATE spots
	SET NumOfPeople = NumOfPeople - 1
	WHERE ID = "#spot.ReservedSlot#";
	</cfquery>
	<CFSET data.SUCCESS=true>
</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET object.SUCCESS = "UserDeleteReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

	<cfset _tempstruct= {
		"function":"delete",
		"success": #data.SUCCESS#,
		"found": #data.FOUND#,
		"event": #_eventID#
		}>
	<cfset _jsondate = serializeJSON(_tempstruct)>


<CFOUTPUT>
#_jsondate#
</cfoutput>
