<cfset _fname = Replace(url['fname'],'*',' ','all')>
<cfset _lname = Replace(url['lname'],'*',' ','all')>
<cfset _email = url['email']>


<!---http://cptgschedule.ddns.net/jsonlookup.cfm?fname=Justin*test&lname=Guiao&email=justing6@gmail.com&_=1426574894827---->
<!----http://cptgschedule.ddns.net/jsonlookup.cfm?fname=Justinnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn*test&lname=Guiao&email=justing6@gmail.com&_=1426574894827---->
<CFTRY>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss')#">
	
	<CFQUERY datasource="schedule" name="reservedspot">
	SELECT reservedspot.ID, spots.Start, spots.End, reservedspot.Phone
	FROM reservedspot
	INNER JOIN spots
	ON reservedspot.ReservedSlot = spots.ID
	WHERE FirstName = "#_fname#"
	AND LastName = "#_lname#"
	AND Email = "#_email#"
	AND spots.Start >= "#_currDateTime#"
	order by spots.Start;
	</cfquery>
	<CFIF reservedspot.RecordCount IS NOT 0>
		<CFSET _dateend = reservedspot.End>
		<CFSET _date = reservedspot.Start>
		<CFSET data.phone = reservedspot.Phone>
		<CFSET data.event = reservedspot.ID>
		<CFSET data.FOUND = true>
	<CFELSE>
		<CFSET _dateend = "">
		<CFSET _date = "">
		<CFSET data.phone = "">
		<CFSET data.event = 0>
		<CFSET data.FOUND = false>
	</CFIF>
	<CFCATCH TYPE="Any">
		<CFSET data.FOUND = "LookupReservation() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

	<cfset _tempstruct= {
		"function":"lookup",
		"found": #data.FOUND#,
		"event": #data.event#,
		"phone": "#data.phone#",
		"date": "#DateFormat(_date,"yyyy-mm-dd")#T#TimeFormat(_date,"HH:mm:ss")#",
		"nicetime": "#TimeFormat(_date,"h:mm tt")#",
		"nicedate":"#DateFormat(_date,"dddd, mmmm d, yyyy")#",
		"nicetimeend": "#TimeFormat(_dateend,"h:mm tt")#",
		}>
	<cfset _jsondate = serializeJSON(_tempstruct)>


<CFOUTPUT>
#_jsondate#
</cfoutput>