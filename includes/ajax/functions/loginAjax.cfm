<!--- _cfscriptLoginAjaxLocation --->
<CFINCLUDE TEMPLATE="/includes/ajax/cfajax.cfm">

<CFFUNCTION NAME="loginCheck">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
<!---
	Written by: <your name>
	Written on: <today's date>

	Purpose:
	Calling File:

	The _ajaxInput argument get broken into a <number> element array as follows:
	_inputArray[1]: <whatever comes first within _ajaxInput>
	_inputArray[2]: <whatever comes second within _ajaxInput>
	_inputArray[n]: <whatever comes nth within _ajaxInput>
--->
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">


<cfquery name="getUser" datasource="schedule">
select PasswordHash, UserID from login
where UserID = '#_inputArray[1]#';
</cfquery>

<CFSET object.accepted = "False">
<CFSET _message = "Invalid Credentials.">
<cfif getUser.recordcount IS 1>
	<cfif Hash(_inputArray[2], "SHA-256") IS getUser.PasswordHash> 
		<cflock timeout=20 scope="Session" type="Exclusive"> 
			<cfset Session.LoggedIn = getUser.UserID>
			<CFSET _message = "Password Accepted">
			<CFSET object.accepted = "True">
		</cflock>
	</cfif>
</cfif>

	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
	<CFIF object.accepted IS "True">
	<CFSET object.AJAXFOUND = "T">
	</CFIF>
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "functionNameHere() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>
<CFFUNCTION NAME="logOut">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
<!---
	Written by: <your name>
	Written on: <today's date>

	Purpose:
	Calling File:

	The _ajaxInput argument get broken into a <number> element array as follows:
	_inputArray[1]: <whatever comes first within _ajaxInput>
	_inputArray[2]: <whatever comes second within _ajaxInput>
	.
	.	
	.
	_inputArray[n]: <whatever comes nth within _ajaxInput>
--->
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"|")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">
	<cfset _message = "You were not logged in.">
	<cfif IsDefined("Session.LoggedIn")>
		<cflock timeout=20 scope="Session" type="Exclusive"> 
			<cfset StructDelete(Session, "LoggedIn")>
			<cfset _message = "You have been logged out successfully.">			
		</cflock>
	</cfif>

	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
#_message#
	</CFSAVECONTENT>
	</CFOUTPUT>
		
	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "logOut() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>

<CFFUNCTION NAME="changePass">
<CFARGUMENT NAME="_ajaxInput" REQUIRED="YES">
<!---
	Written by: <your name>
	Written on: <today's date>

	Purpose:
	Calling File:

	The _ajaxInput argument get broken into a <number> element array as follows:
	_inputArray[1]: <whatever comes first within _ajaxInput>
	_inputArray[2]: <whatever comes second within _ajaxInput>
	_inputArray[n]: <whatever comes nth within _ajaxInput>
--->
<CFTRY>
	<CFSET object = CreateObject("Component","cfobject")>
	<CFSET _inputArray = listToArray(URLDecode(URLDecode(_ajaxInput)),"||")>
	<CFSET _currDateTime = "#dateFormat(Now(),'yyyy-mm-dd')# #timeFormat(Now(),'HH:mm:ss tt')#">

<cfquery name="getUser" datasource="schedule">
select PasswordHash from login
where UserID = '#Session.LoggedIn#';
</cfquery>

<CFSET _message = "Invalid Credentials.">
<cfif getUser.recordcount IS 1>
	<cfif Hash(_inputArray[1], "SHA-256") IS getUser.PasswordHash> 
		<CFSET _newpass =  Hash(_inputArray[2], "SHA-256")>
		<CFQUERY datasource="schedule">
		UPDATE login
		SET PasswordHash = '#_newpass#'
		WHERE UserID = '#Session.LoggedIn#';
		</cfquery>
		<CFSET _message = "Your password has been successfully changed.">	
	</cfif>
</cfif>

<CFIF _message IS "Invalid Credentials.">
	<CFSET object.AJAXFOUND = "F">
<CFELSE>
	<CFSET object.AJAXFOUND = "T">
</CFIF>
	<CFOUTPUT>
	<CFSAVECONTENT VARIABLE="_returnToPage">
#_message#	
	</CFSAVECONTENT>
	</CFOUTPUT>

	<CFSET object.AJAXOUTPUT = _returnToPage>
	<CFCATCH TYPE="Any">
		<CFSET object.AJAXOUTPUT = "changePass() #CFCATCH.MESSAGE#: #CFCATCH.DETAIL#">
	</CFCATCH>
</CFTRY>

<CFRETURN object>
</CFFUNCTION>