

<cfquery datasource=schedule name="options">
select * from options;
</cfquery>


<CFINCLUDE TEMPLATE="/includes/css/style.css">

<table class="ds_box" cellpadding="0" cellspacing="0" id="ds_conclass" style="display: none;">
<tr><td id="ds_calclass">
</td></tr>
</table>


<cfif IsDefined("Session.EVENTID")>
	<CFQUERY datasource="schedule" name="eventinfo">
	select Start
	FROM spots
	INNER JOIN reservedspot
	ON spots.ID = reservedspot.ReservedSlot
	WHERE reservedspot.ID = #Session.EVENTID#
	ORDER BY spots.START;
	</cfquery>

	<CFQUERY datasource="schedule" name="modified">
	select ManagerModified
	FROM reservedspot
	WHERE (ID = #Session.EVENTID#)
	AND ManagerModified = 'Y'
	GROUP BY ManagerModified;
	</cfquery>
	<CFIF modified.RecordCount IS NOT 0>
		<CFSET _modified = 'true'>
	</CFIF>
</cfif>
<cfoutput>
<head>
<link rel='stylesheet' href='includes/css/fullcalendar.css' />
<link rel='stylesheet' href='includes/jquery-ui-1.11.3/jquery-ui.min.css' />
<link rel='stylesheet' href='includes/assets/components/timepicker/css/ng_timepicker_style.css' />
<script src='includes/moment.js' type="text/javascript"></script>
<script src="includes/jquery.min.js" type="text/javascript"></script>
<script src="includes/jquery.maskedinput.js" type="text/javascript"></script>
<script src="includes/jquery-ui-1.11.3/jquery-ui.min.js" type="text/javascript"></script>
<script src="includes/Calendar.js" type="text/javascript"></script>
<script src='includes/fullcalendar.min.js' type="text/javascript"></script>
<script src="includes/ajax/engine.js" type="text/javascript"></script>
<script src="includes/ajax/util.js"   type="text/javascript"></script>
<script src="includes/ajax/settings.js" type="text/javascript"></script>



<script>
_cfscriptCalendarAjaxLocation = "/includes/ajax/functions/calendarAjax.cfm";
( function($) {

$(document).ready(function() {
		
		FullCalendar = $('##calendar').fullCalendar({
			header: {
				left: 'prev,next today',
				center: 'title',
				right: 'agendaWeek,agendaDay'
			},
			eventDurationEditable:false,
			eventClick: function(calEvent, jsEvent, view) {

				usergetPeople(calEvent.id);
			},
			eventDrop: function(event, delta, revertFunc) {
				userdragDropReservation(event.id, event.start.format());
			},
			eventConstraint: {
				start: '#TimeFormat(#options.wdstart#,"HH:mm:ss")#',
				end: '#TimeFormat(#options.wdend#,"HH:mm:ss")#',
				dow: #options.dow#
			},
			allDaySlot: false,
			defaultView: 'agendaWeek',
			editable: true,
			eventOverlap : false,
			eventLimit: true, // allow "more" link when too many events
			<cfif IsDefined("Session.EVENTID")>
			defaultDate: "#DateFormat('#eventinfo.Start#','yyyy-mm-dd')#",
			</CFIF>
			contentHeight: #options.calheight#,
		businessHours: {
				start: '#TimeFormat(#options.wdstart#,"HH:mm:ss")#',
				end: '#TimeFormat(#options.wdend#,"HH:mm:ss")#',
				dow: #options.dow#
		},
		minTime: '#TimeFormat(#options.CalStart#,"HH:mm:ss")#',
		maxTime: '#TimeFormat(#options.CalEnd#,"HH:mm:ss")#',
		events: {
        url: '/userjson.cfm',
		lazyFetching: false,
        error: function() {
            alert('Your session has expired, please enter your information.');
			window.location.href = "/index.cfm"
        },
        color: 'yellow',   // a non-ajax option
        textColor: 'black' // a non-ajax option
    }
		});
		
	});

    } ) ( jQuery );
	
( function($) {

 $(function() {

dialogbox = $( "##dialog" ).dialog({
	autoOpen: false,
	close: function( event, ui ) {closePopup()},
	minWidth: 400
	});
});
 $(function() {
	 $('.phone').mask("(999) 999-9999");
});

 } ) ( jQuery );

 function closePopup()
 {
	dialogbox.dialog( "option", "title", " ");
	FullCalendar.fullCalendar( 'refetchEvents' );
	document.getElementById("logintable").style.display = "none";
	document.getElementById('dialog').style.display="none";
	document.getElementById('timetable').style.display="none";
	dialogbox.dialog( "option", "position", { my: "center", at: "center", of: window } );
 }
 
function usergetPeople(eventID)
{
	var sendToServer = encodeURI(eventID);
	var functionName = "UserGetPeople";
	DWREngine._execute(_cfscriptCalendarAjaxLocation, null, functionName, sendToServer, showPopup);
}
function showPopup(object)
{
	if(object.FOUND === "true"){
		if(object.TITLE === "true"){
			dialogbox.dialog( "option", "title", object.AJAXOUTPUT2);
		}
		dialogbox.dialog( "option", "width", 580 );
		document.getElementById('newrestable').style.display="none";
		document.getElementById('lookuprestable').style.display="none";
		document.getElementById('infobox').innerHTML = object.AJAXOUTPUT;
		document.getElementById('dialog').style.display="inline";
		document.getElementById('infobox').style.display="inline";
		document.getElementById('logintable').style.display="none";
		dialogbox.dialog( "open" );
		}
	else{
		FullCalendar.fullCalendar( 'refetchEvents' );
		dialogbox.dialog( "close" );
	}
}

function userdragDropReservation(slotID, time)
{
	dialogbox.dialog( "option", "title", "Move Reservation");
	var sendToServer = encodeURI(slotID + "||" + time);
	var functionName = "UserDragDropReservation";
	DWREngine._execute(_cfscriptCalendarAjaxLocation, null, functionName, sendToServer, showPopup);
}

function moveReservation(eventID, time)
{
	var sendToServer = encodeURI(eventID + "||" + time);
	var functionName = "MoveReservation";
	DWREngine._execute(_cfscriptCalendarAjaxLocation, null, functionName, sendToServer, moveReservationReciever);
}

function moveReservationReciever(object)
{
	dialogbox.dialog( "option", "title", "Error");
	if(object.VALID === 'false')
	{
		alert("Please select a date under "+object.MAXDAY+" days in the future.");
	}
	else if(object.SAME === 'true')
		alert("You already have an appointment at this time and cannot schedule another one.");
	else if(object.TAKEN === 'true')
		alert("We're sorry, but this slot of time has filled.");
	else{
		FullCalendar.fullCalendar( 'gotoDate' , object.DATE);
		dialogbox.dialog( "close" );
	}
}

function deleteReservation(eventID)
{	
	if(confirm("Are you sure you want to delete this reservation?")){
	var sendToServer = encodeURI(eventID);
	var functionName = "UserDeleteReservation";
	DWREngine._execute(_cfscriptCalendarAjaxLocation, null, functionName, sendToServer, deleteReservationReciever);
	}
}

function deleteReservationReciever(object)
{
	if(object.RETURN === 'true')
		window.location.href = "/index.cfm"
	else{
		FullCalendar.fullCalendar( 'gotoDate' , object.DATE);
		dialogbox.dialog( "close" );
	}
}


function findSpot(now, eventID)
{		
	if(document.getElementById("timepicker_input").value == "" && !now)
		alert("Please select a valid time.");
	else{
		if(now === 'true'){
			var datetime = "#DateFormat(Now(),'yyyy-mm-dd')#" + ' ' + "#TimeFormat(Now(),'HH:mm:ss')#";
			document.getElementById("Date").value = "";
			dialogbox.dialog( "option", "height", 290 );
			document.getElementById("timepicker_input").value = "";
			}
		else{
			var datetime = document.getElementById("Date").value + ' ' + document.getElementById("timepicker_input").value;
		}
		var sendToServer = encodeURI(datetime + "||" + eventID);
		var functionName = "FindSpot";
		DWREngine._execute(_cfscriptCalendarAjaxLocation, null, functionName, sendToServer, findSpotReciever);
		document.getElementById("datespan").innerHTML = "Loading, please wait...";
	}
}


function findSpotReciever(object)
{
	dialogbox.dialog( "option", "title", object.AJAXOUTPUT4);
	document.getElementById("infobox").style.display = "none";
	document.getElementById("timetable").style.display = "inline";
	document.getElementById("datespan").innerHTML = object.AJAXOUTPUT;
	document.getElementById("addResSpan").innerHTML = object.AJAXOUTPUT2;
	document.getElementById("findSpotSpan").innerHTML = object.AJAXOUTPUT3;
}

function tempPerson()
{	
	var regex = /^[a-zA-Z_ ]*$/;
	var error = false;
	var F_name = document.getElementById('F_Name_Box').value;
	var L_name = document.getElementById('L_Name_Box').value;

	if(L_name === "" || F_name === ""){
		alert("Please enter your name");
		error = true;
	}
	else if((!regex.test(F_name) || !regex.test(L_name)) && !error){
		alert('Please input only letters in the name fields.');
		error = true;
	}
	var phone = document.getElementById('P_num_Box').value;
	if(phone === "" && !error){
		alert("Please enter your Phone Number");
		error = true;
	}
	var email = document.getElementById('Email_Box').value;
	email = email.replace(/##/g, "");
	email = email.replace(/\'/g, "");
	if(email === "" && !error){
		alert("Please enter your email address");
		error = true;
	}
	else if (!isEmail(email) && !error){
		alert("Please enter a valid email address");
		error = true;
	}
	if(!error){
	var sendToServer = encodeURI(F_name + "||" + L_name + "||" + phone + "||" + email);
	var functionName = "TempPerson";
	DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, tempPersonReciever);
	}
}

function tempPersonReciever(object)
{
	document.getElementById("timetable").style.display = "inline";
	document.getElementById("newrestable").style.display = "none";
	document.getElementById("lookuprestable").style.display = "none";
	findSpot2(true);
}

function findSpot2(now)
{		
	if(document.getElementById("timepicker_input").value == "" && !now)
		alert("Please select or reselect a valid time.");
	else{
		if(now){
			var datetime = "#DateFormat(Now(),'yyyy-mm-dd')#" + ' ' + "#TimeFormat(Now(),'HH:mm:ss')#";
			document.getElementById("Date").value = "";
			document.getElementById("timepicker_input").value = "";
		}
		else{
			var datetime = document.getElementById("Date").value + ' ' + document.getElementById("timepicker_input").value;
		}
		var sendToServer = encodeURI(datetime);
		var functionName = "FindSpot";
		DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, findSpotReciever2);
		document.getElementById("datespan").innerHTML = "Loading, please wait...";
	}
}

jQuery(function($){
   $('.phone').mask("(999) 999-9999");
   
});

function findSpotReciever2(object)
{
	dialogbox.dialog( "option", "height", 300 );
	dialogbox.dialog( "option", "width", 600 );
	document.getElementById("datespan").innerHTML = object.AJAXOUTPUT;
	document.getElementById("timetable").style.display = "inline";
	document.getElementById("addResSpan").innerHTML = object.AJAXOUTPUT2;
	document.getElementById("findSpotSpan").innerHTML = object.AJAXOUTPUT3;
}



function showNewRes()
{
	dialogbox.dialog( "option", "title", "Schedule New Appointment");
	document.getElementById("logintable").style.display = "none";
	document.getElementById("infobox").style.display = "none";
	document.getElementById("timetable").style.display = "none";
	document.getElementById('F_Name_Box').value = "";
	document.getElementById('L_Name_Box').value = "";
	document.getElementById('P_num_Box').value = "";
	document.getElementById('Email_Box').value = "";
	document.getElementById("newrestable").style.display = "inline";
	document.getElementById("lookuprestable").style.display = "none";
	dialogbox.dialog( "option", "height", 240 );
	dialogbox.dialog( "option", "width", 400 );
	dialogbox.dialog( "open" );
}

function showLookup()
{
	dialogbox.dialog( "option", "title", "Lookup Existing Appointment");
	document.getElementById("logintable").style.display = "none";
	document.getElementById("infobox").style.display = "none";
	document.getElementById("timetable").style.display = "none";
	document.getElementById('F_Name_Box2').value = "";
	document.getElementById('L_Name_Box2').value = ""; 
	document.getElementById('Email_Box2').value = "";
	document.getElementById("newrestable").style.display = "none";
	document.getElementById("lookuprestable").style.display = "inline";
	dialogbox.dialog( "option", "height", 210 );
	dialogbox.dialog( "option", "width", 400 );
	dialogbox.dialog( "open" );
	}

function lookupReservation()
{
	var regex = /^[a-zA-Z_ ]*$/;
	var error = false;
	var F_name = document.getElementById('F_Name_Box2').value;
	var L_name = document.getElementById('L_Name_Box2').value;

	if(L_name === "" || F_name === ""){
		alert("Please enter a name");
		error = true;
	}
	else if((!regex.test(F_name) || !regex.test(L_name)) && !error){
		alert('Please input only letters in the name fields.');
		error = true;
	}
	var email = document.getElementById('Email_Box2').value;
	email = email.replace(/##/g, "");
	email = email.replace(/\'/g, "");
	if(email === "" && !error){
		alert("Please enter a email address");
		error = true;
	}
	else if (!isEmail(email) && !error){
		alert("Please enter a valid email address");
		error = true;
	}
	if(!error){
		var sendToServer = encodeURI(F_name + "||" + L_name + "||" + email);
		var functionName = "LookupReservation";
		DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, lookupReciever);
	}
}

function lookupReciever(object)
{
	if(object.FOUND === "true")
		window.location.href = "/index.cfm"
	else
		alert("No reservation found for the provided information");
}

function addReservation(time)
{
	var sendToServer = encodeURI(time);
	var functionName = "AddReservation";
	DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, addReservationReciever);
}

function addReservationReciever(object)
{
	if(object.VALID === 'false')
	{
		alert("Please select a date under "+object.MAXDAY+" days in the future.");
	}
	else if(object.SAME === 'true'){
		if(confirm("You already have an appointment at this time. Would you like to see it on a calendar?"))
		{
		var sendToServer = encodeURI(object.FNAME + "||" + object.LNAME + "||" + object.EMAIL);
		var functionName = "LookupReservation";
		DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, lookupReciever);
		}
	}
	else if(object.TAKEN === 'true'){
		alert("We're sorry, but this slot of time has filled. Please select another time.");
		findSpot(true);
		}
	else{
		if(confirm("Your reservation has been accepted.")){
			var sendToServer = encodeURI(object.FNAME + "||" + object.LNAME + "||" + object.EMAIL);
			var functionName = "LookupReservation";
			DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, lookupReciever);
		}
		else{
		var sendToServer = encodeURI(object.FNAME + "||" + object.LNAME + "||" + object.EMAIL);
		var functionName = "LookupReservation";
		DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, lookupReciever);
		}
	}
}

function isEmail(email){
        return /^([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22))*\x40([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d))*$/.test( email );
}

</script>

<!----Login page functions--->
<script>
function checkLogin()
{
		var UNAME = document.getElementById('username').value;
		var PASS = document.getElementById('password').value;
		if(UNAME!=="" && PASS!==""){
		var sendToServer = encodeURI(UNAME + "||" + PASS);
			var functionName = "loginCheck";
			DWREngine._execute(_cfscriptLoginAjaxLocation, null, functionName, sendToServer, checkReciever);
		}else
			alert('Please enter your username and password.');
}

function checkReciever(object)
{
	if(object.AJAXFOUND === "T")
		window.location.href = "/admin.cfm"
	else{
		alert('Invalid Credentials.');
	}
}

function showLogin()
{
	dialogbox.dialog( "option", "title", "Please enter your username and password:");
	document.getElementById("infobox").style.display = "none";
	document.getElementById("timetable").style.display = "none";
	document.getElementById("newrestable").style.display = "none";
	document.getElementById("lookuprestable").style.display = "none";
	document.getElementById("logintable").style.display = "inline";
	dialogbox.dialog( "option", "width", 400 );
	dialogbox.dialog( "option", "height", 150 );
	dialogbox.dialog( "open" );
}


</script>
<!----END of login page functions--->
<CFIF IsDefined("_modified")>
	<CFIF _modified IS 'true'>
		<script>
		function modifiedAlert() 
		{
			var sendToServer = encodeURI();
			var functionName = "ViewedModified";
			DWREngine._execute(_cfscriptCalendarAjaxLocation, null, functionName, sendToServer, ModifiedReciever);

            alert('Alert: A manager has modified one of your appointments.\nPlease double check their times and information.');
        }
		function ModifiedReciever(){}
        window.onload = modifiedAlert;
		</script>
	</cfif>
</cfif>
<style>

	body {
		margin: 40px 10px;
		padding: 0;
		font-family: "Lucida Grande",Helvetica,Arial,Verdana,sans-serif;
		font-size: 14px;
	}

	##calendar {
		max-width: 900px;
		margin: 0 auto;
	}
	##slotinfo td {color:##000000;font-size: 13px;padding:6px;font-family:Tahoma,Arial,sans-serif;font-weight:500;width:auto}
	##slotinfo th {background:##474747;color:##ffffff;font-size: 12px;padding:8px;font-family:Tahoma,Arial,sans-serif;font-weight:500;}


</style>

</head>
<body>
<center><font size="5px;"><b>Appointment System</b></font></center>
<br>
<br>
<div id="dialog" style="display:none">
<div id="infobox"></div>
<center>
<table  cellpadding="4" align="center" id = "timetable" style="display:none">
<col width="40%" />
<tr>
	<td colspan=2 align="center"><span id="datespan">Loading, please wait...</span></td>
</tr>
<tr>
	<td colspan=2 align="center">Would you like to schedule this time?    <span id=addResSpan><input type="button" onClick="moveReservation();" value="Yes" id="addResButton"></span></td>
</tr>
<tr>
	<td colspan=2 align="center">If not, please select a date and time.</td>
</tr>
<tr>
	<td colspan=2 align="center"><font size="1px">Note: The message above will be automatically updated after searching.</font></td>
</tr>
<tr>
	<td align="right">Date:</td>
	<td><input onclick="ds_sh(this);" placeholder="Click Here" name="date" value="#DateFormat(Now(),'yyyy-mm-dd')#" size="17" id="Date" readonly="readonly" style="cursor: text;" /></td>
</tr>
<tr>
	<td align="right">Time:</td>
	<td><input id="timepicker_input" placeholder="Click Here" onkeydown="if (event.keyCode == 13) findSpot('false');" size="14" readonly="readonly" type="text"></td>
</tr>
<tr>
	<td colspan=2 align="center"><span id=findSpotSpan><input type="button" onClick="findSpot('false');" value="Search Availability" id="addResButton"></span></td>
</tr>
</table>
<table cellpadding="4" id="newrestable" style="display:none">
<tr>
	<td>First Name:</td>
	<td align="right"><input type="textbox" placeholder="First Name" id="F_Name_Box" onkeydown="if (event.keyCode == 13) tempPerson();" style="width:175px;"></td><td><span id="F_NAME_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Last Name:</td>
	<td align="right"><input type="textbox" placeholder="Last Name" id="L_Name_Box" onkeydown="if (event.keyCode == 13) tempPerson();" style="width:175px;"></td><td><span id="L_NAME_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Phone Number:</td>
	<td align="right"><input type="textbox" placeholder="(xxx) xxx-xxxx" class=phone id="P_num_Box" onkeydown="if (event.keyCode == 13) tempPerson();" style="width:175px;"></td><td><span id="P_num_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Email Address:</td>
	<td align="right"><input type="textbox" placeholder="example@email.com" id="Email_Box" onkeydown="if (event.keyCode == 13) tempPerson();" style="width:175px;"></td><td><span id="EMAIL_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td colspan=2 align="right"><input type="button" onClick="tempPerson();" value="Submit" id="submitButton"></td>
</tr>
</table>
<table cellpadding="4" id="lookuprestable" style="display:none">
<tr>
	<td>First Name:</td>
	<td align="right"><input type="textbox" placeholder="First Name" id="F_Name_Box2" onkeydown="if (event.keyCode == 13) lookupReservation();" style="width:175px;"></td><td><span id="F_NAME_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Last Name:</td>
	<td align="right"><input type="textbox" placeholder="Last Name" id="L_Name_Box2" onkeydown="if (event.keyCode == 13) lookupReservation();" style="width:175px;"></td><td><span id="L_NAME_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Email Address:</td>
	<td align="right"><input type="textbox" placeholder="example@email.com" onkeydown="if (event.keyCode == 13) lookupReservation();" id="Email_Box2" style="width:175px;"></td><td><span id="EMAIL_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td colspan=2 align="right"><input type="button" onClick="lookupReservation();" value="Submit" id="submitButton"></td>
</tr>
</table>
</center>
<!---Login page table--->
<center>
<table id="logintable" style="display:none">
	<tr>
		<td>Username:</td>
		<td align="right"><input type="textbox" style="width:175px;" onkeydown="if (event.keyCode == 13) checkLogin();" placeholder="Username" id="username"></td>
	</tr>
	<tr>
		<td>Password:</td>
		<td align="right"><input type="password" style="width:175px;" onkeydown="if (event.keyCode == 13) checkLogin();" placeholder="Password" id="password"></td>
	</tr>
	<tr>
		<td align="right" colspan=2><input type="submit"  onClick="checkLogin();" value="Login" id="loginButton"></td>
	<tr>
</table>
</center>
<!----END of login page table --->
</div>
	
	<div id='calendar'></div>
	<center>
<!---<font size="2px;"><b>Click <a href='##' onclick='showNewRes()'>here</a> to schedule a new reservation or <a href='##' onclick='showLookup()'>here</a> to look up an existing reservation.</b></font>---->
<br><input type=button value="Schedule New Appointment" onclick='showNewRes();'>  <input type=button value="Lookup Existing Appointment" onclick='showLookup();'>
</center><br>
	<cfif IsDefined("Session.EVENTID")>
	<center><font size="2px;">Drag an appointment to reschedule or click one for more options.</font></center>
	</CFIF>
	<center><font size="2px;">Slots that are full are marked in red.</font></center>
	<br>
	<center><input type=button value="Login" onclick="showLogin();"></center>
</body>

<script src="includes/ng_lite.js" type="text/javascript"></script>
<script src="includes/components/timepicker_lite.js" type="text/javascript"></script>
<script type="text/javascript">
ng.ready( function() {
    var tp = new ng.TimePicker({
        input: 'timepicker_input',  // the input field id
        start: '#TimeFormat(#options.wdstart#,'h:mm tt')#',  // what's the first available hour
        end: '#TimeFormat(#options.endslot#,'h:mm tt')#',  // what's the last avaliable hour
        top_hour: 12 // what's the top hour (in the clock face, 0 = midnight)
    });
});

</script>
</cfoutput>

