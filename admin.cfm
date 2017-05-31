<CFIF IsDefined("Session.LoggedIn")>
<cfquery datasource=schedule name="options">
select * from options;
</cfquery>

<CFINCLUDE TEMPLATE="/includes/css/style.css">

<table class="ds_box" cellpadding="0" cellspacing="0" id="ds_conclass" style="display: none;">
<tr><td id="ds_calclass">
</td></tr>
</table>

<cfoutput>
<head>
<link rel='stylesheet' href='includes/css/fullcalendar.css' />
<link rel='stylesheet' href='includes/jquery-ui-1.11.3/jquery-ui.min.css' />
<link rel='stylesheet' href='includes/assets/components/timepicker/css/ng_timepicker_style.css' />
<script src='includes/moment.js' type="text/javascript"></script>
<script src="includes/jquery.min.js" type="text/javascript"></script>
<script src="includes/jquery-ui-1.11.3/jquery-ui.min.js" type="text/javascript"></script>
<script src="includes/jquery.maskedinput.js" type="text/javascript"></script>
<script src='includes/fullcalendar.min.js' type="text/javascript"></script>
<script src="includes/Calendar.js" type="text/javascript"></script>
<script src="includes/ajax/engine.js" type="text/javascript"></script>
<script src="includes/ajax/util.js"   type="text/javascript"></script>
<script src="includes/ajax/settings.js" type="text/javascript"></script>



<script>
_cfscriptAdminAjaxLocation = "/includes/ajax/functions/adminAjax.cfm";
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

				getPeople(calEvent.id);
			},
			eventDrop: function(event, delta, revertFunc) {
			dragDropappointment(event.id, event.start.format());
			},
			eventConstraint: {
				start: '#TimeFormat(#options.wdstart#,"HH:mm:ss")#',
				end: '#TimeFormat(#options.wdend#,"HH:mm:ss")#',
				dow: #options.dow#
			},
			allDaySlot: false,
			minTime: '#TimeFormat(#options.CalStart#,"HH:mm:ss")#',
			maxTime: '#TimeFormat(#options.CalEnd#,"HH:mm:ss")#',
			defaultView: 'agendaWeek',
			editable: true,
			<CFIF #options.concurslots# IS 1>
			eventOverlap : false,
			<CFELSE>
			eventOverlap : true,
			</CFIF>
			contentHeight: #options.calheight#,
		businessHours: {
				start: '#TimeFormat(#options.wdstart#,"HH:mm:ss")#',
				end: '#TimeFormat(#options.wdend#,"HH:mm:ss")#',
				dow: #options.dow#
		},
		events: {
        url: '/json.cfm',
		lazyFetching: false,
        error: function() {
            alert('there was an error while fetching events!');
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
	minWidth: 400,
	close: function( event, ui ) {closePopup()}
	});
});

 } ) ( jQuery );
 

 function closePopup()
 {
	dialogbox.dialog( "option", "title", " ");
	FullCalendar.fullCalendar( 'refetchEvents' );
	document.getElementById('dialog').style.display="none";
	document.getElementById('options').style.display="none";
	dialogbox.dialog( "option", "position", { my: "center", at: "center", of: window } );
 }
 
function getPeople(slotID)
{
	var sendToServer = encodeURI(slotID);
	var functionName = "GetPeople";
	DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, showPopup);
}
function showPopup(object)
{
	if(object.FOUND === "true"){
		if(object.TITLE === "true"){
			dialogbox.dialog( "option", "title", object.AJAXOUTPUT2);
		}
		dialogbox.dialog( "option", "width", 580 );
		document.getElementById("changepasstable").style.display = "none";
		document.getElementById('options').style.display = "none";
		document.getElementById("timetable").style.display = "none";
		document.getElementById("lookuprestable").style.display = "none";
		document.getElementById("newrestable").style.display = "none";
		document.getElementById("infobox").style.display = "inline";
		document.getElementById('infobox').innerHTML = object.AJAXOUTPUT;
		document.getElementById('dialog').style.display="inline";
		dialogbox.dialog( "open" );
	}
	else{
		FullCalendar.fullCalendar( 'refetchEvents' );
		dialogbox.dialog( "close" );
	}
}

function dragDropappointment(slotID, time)
{
	dialogbox.dialog( "option", "title", "Move Appointment");
	var sendToServer = encodeURI(slotID + "||" + time);
	var functionName = "DragDropReservation";
	DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, showPopup);
}

function moveReservation(eventID, time)
{
	var sendToServer = encodeURI(eventID + "||" + time);
	var functionName = "MoveReservation";
	DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, moveappointmentReciever);
}

function moveappointmentReciever(object)
{
	dialogbox.dialog( "option", "title", "Error");
	if(object.VALID === 'false')
	{
		alert("Please select a date under "+object.MAXDAY+" days in the future.");
	}
	else if(object.SAME === 'true')
		alert("One person cannot have two appointments at the same time.");
	else if(object.TAKEN === 'true')
		alert("We're sorry, but this slot of time has filled.");
	else{
		FullCalendar.fullCalendar( 'gotoDate' , object.DATE);
		dialogbox.dialog( "close" );
	}
}

function deleteReservation(eventID)
{	
	if(confirm("Are you sure you want to delete this appointment?")){
	var sendToServer = encodeURI(eventID);
	var functionName = "DeleteReservation";
	DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, deleteappointmentReciever);
	}
}

function deleteappointmentReciever(object)
{
	FullCalendar.fullCalendar( 'refetchEvents' );
	getPeople(object.SPOTID);
}

function findSpot(now, eventID)
{	
	
	if(document.getElementById("timepicker_input").value == "" && !now)
		alert("Please select or reselect a valid time.");
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
		DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, findSpotReciever);
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
		alert("Please select a valid time.");
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


function dropOldReservations() 
{
	var sendToServer = encodeURI();
	var functionName = "DropOldReservations";
	DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, dropOldReciever);
}

function dropOldReciever(){}

window.onload = dropOldReservations;

function showNewRes()
{
	document.getElementById("changepasstable").style.display = "none";
	document.getElementById('options').style.display = "none";
	dialogbox.dialog( "option", "title", "Add New Appointment");
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
	document.getElementById("changepasstable").style.display = "none";
	document.getElementById('options').style.display = "none";
	dialogbox.dialog( "option", "title", "Look Up Existing Appointment");
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

function lookupappointment()
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
		DWREngine._execute(_cfscriptAdminAjaxLocation, null, functionName, sendToServer, lookupReciever);
	}
}

function lookupReciever(object)
{
	if(object.FOUND === "true"){
		FullCalendar.fullCalendar( 'gotoDate' , object.DATE);
		getPeople(object.SLOT);
		}
	else
		alert("No appointment found for the provided information");
}

function addReservation(time)
{
	var sendToServer = encodeURI(time);
	var functionName = "AddReservation";
	DWREngine._execute(_cfscriptTestAjaxLocation, null, functionName, sendToServer, addappointmentReciever);
}

function addappointmentReciever(object)
{
	if(object.VALID === 'false')
	{
		alert("Please select a date under "+object.MAXDAY+" days in the future.");
	}
	else if(object.SAME === 'true'){
		alert("This person already has an appointment at this time and cannot have another.");
	}
	else if(object.TAKEN === 'true'){
		alert("We're sorry, but this slot of time has filled. Please select another time.");
		findSpot(true);
		}
	else{
		getPeople(object.SLOT);
		FullCalendar.fullCalendar( 'gotoDate' , object.DATE);
	}
}

function isEmail(email){
        return /^([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x22([^\x0d\x22\x5c\x80-\xff]|\x5c[\x00-\x7f])*\x22))*\x40([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d)(\x2e([^\x00-\x20\x22\x28\x29\x2c\x2e\x3a-\x3c\x3e\x40\x5b-\x5d\x7f-\xff]+|\x5b([^\x0d\x5b-\x5d\x80-\xff]|\x5c[\x00-\x7f])*\x5d))*$/.test( email );
}


</script>


<!----Functions for the options page---->
<script>
_cfscriptOptionsAjaxLocation = "/includes/ajax/functions/optionsAjax.cfm";

function showOptions()
{
	dialogbox.dialog( "option", "title", "Options");
	document.getElementById("changepasstable").style.display = "none";
	document.getElementById("infobox").style.display = "none";
	document.getElementById("timetable").style.display = "none";
	document.getElementById("newrestable").style.display = "none";
	document.getElementById("lookuprestable").style.display = "none";
	document.getElementById("options").style.display = "inline";
	dialogbox.dialog( "option", "height", 420 );
	dialogbox.dialog( "option", "width", 700 );
	dialogbox.dialog( "open" );
}

function convertTo24h(time_str) {
    var time = time_str.match(/(\d+):(\d+) (\w)/);
    var hours = Number(time[1]);
    var minutes = Number(time[2]);
    var meridian = time[3].toLowerCase();

    if (meridian == 'p' && hours < 12) {
      hours = hours + 12;
    }
    else if (meridian == 'a' && hours == 12) {
      hours = hours - 12;
    }
	time = hours*60+minutes;
    return time;
  };

function changeOptions()
{
	regex = /^[0-9]*$/;
	if(!regex.test(document.getElementById('PastBox').value)
	|| !regex.test(document.getElementById('FutureBox').value)
	|| !regex.test(document.getElementById('DurationBox').value)
	|| !regex.test(document.getElementById('SlotsBox').value))
		alert("Please enter only positive whole numbers in the boxes");
	else{
		var error = false;
		var past = document.getElementById('PastBox').value;
		var future = document.getElementById('FutureBox').value;
		if(past === "")
			past = #options.KeepRecordsFor#;
		if(future === "")
			future = #options.MaxAdvanceSchedule#;
		if(past < 0){
			alert("Please enter a positive value for past");
			error = true;
		}
		else if(future < 1){
			alert("Please enter a value greater than 0 for future");
			error = true;
		}
		var slots = document.getElementById('SlotsBox').value;
		if(slots === "")
			slots = #options.concurslots#;
		else if(slots == 0)
			{
				alert("Please enter a non-zero value for number of slots.");
				error = true;
			}
		var dow = "[";
		if(document.getElementById('sun').checked)
			dow = dow + '0';
		if(document.getElementById('mon').checked){
			if(dow !== "[")
				dow = dow + ',1';
			else
				dow = dow + '1';
		}
		if(document.getElementById('tue').checked){
			if(dow !== "[")
				dow = dow + ',2';
			else
				dow = dow + '2';
		}
		if(document.getElementById('wed').checked){
			if(dow !== "[")
				dow = dow + ',3';
			else
				dow = dow + '3';
		}
		if(document.getElementById('thur').checked){
			if(dow !== "[")
				dow = dow + ',4';
			else
				dow = dow + '4';
		}
		if(document.getElementById('fri').checked){
			if(dow !== "[")
				dow = dow + ',5';
			else
				dow = dow + '5';
		}
		if(document.getElementById('sat').checked){
			if(dow !== "[")
				dow = dow + ',6';
			else
				dow = dow + '6';
		}
		dow = dow + ']';	
		if(dow === "[]")
		{
			alert("Please select at least one day.");
			error = true;
		}
		var duration = document.getElementById('DurationBox').value;
		if(duration === "")
			duration = #options.slotlength#;
		else{
			var test5 = duration/5;
			if(test5 % 1 != 0)
			{
				alert("Please enter a multiple of 5 for slot duration.");
				error = true;
			}
			if(duration == 0)
			{
				alert("Please enter a non-zero value for duration.");
				error = true;
			}
		}
		
		
		
		var wdstart = document.getElementById('wdstart').value;
		var wdend = document.getElementById('wdend').value;
		if(wdstart === "")
			wdstart = "#TimeFormat(options.wdstart, "hh:mm tt")#";
		if(wdend === "")
			wdend = "#TimeFormat(options.wdend, "hh:mm tt")#";
		if(convertTo24h(wdstart) > convertTo24h(wdend)){
			alert("Please choose an ending time after the starting time.");
			error = true;
		}
		var bstart = document.getElementById('breakstart').value;
		var bend = document.getElementById('breakend').value;
		if(bstart === "")
			<CFIF options.breakstart IS NOT "">
			bstart = "#TimeFormat(options.breakstart, "hh:mm tt")#";
			<CFELSE>
			bstart = "!";
			</CFIF>
		if(bend === "")
			<CFIF options.breakstart IS NOT "">
			bend = "#TimeFormat(options.breakend, "hh:mm tt")#";
			<CFELSE>
			bend = "!";
			</CFIF>
		if((bstart === '!' || bend === '!') && !(bstart === '!' && bend === '!')){
			alert("A break is currently not set, so please choose both a starting and an end time.");
			error = true;
		}
		else if(bstart !== bend && !error){
			if((convertTo24h(bstart) <= convertTo24h(wdstart) || convertTo24h(bend) >= convertTo24h(wdend))){
				alert("Please choose a break range within the workday.");
				error = true;
			}
			else if(convertTo24h(bstart) > convertTo24h(bend) && !error){
				alert("Please choose an ending time after the starting time.");
				error = true;
			}
		}
		if(!error){
			var sendToServer = encodeURI(duration + "||" + wdstart +"||"+ wdend +"||"+ bstart +"||"+ bend +"||"+ dow +"||"+ past +"||"+ future +"||"+ slots);
			var functionName = "SetOptions";
			DWREngine._execute(_cfscriptOptionsAjaxLocation, null, functionName, sendToServer, durationReciever);
			document.getElementById('options').style.display = "none";
			document.getElementById('infobox').style.display = "inline";
			dialogbox.dialog( "option", "height", 120 );
			document.getElementById('infobox').innerHTML = "<center><p>Applying changes, please wait...</p></center>";
		}
	}
}
function durationReciever(object)
{
	alert("Your changes have been applied. The page will now reload.")
	window.location.href = "/admin.cfm"
}

</script>
<style>

.checkbox-group ul {
  display: inline-block;
  margin-bottom: 10;
  margin-top: 2;
  margin-left: 0;
  padding: 0 0 0 0px;
}


.checkbox-group ul > li {
  display: inline; /* display list items horizontally */
}


</style>
<!----END of options page functions/css---->

<!----Login page functions--->
<script>
function logout()
{
	var sendToServer = encodeURI("Nothing");
	var functionName = "logOut";
	DWREngine._execute(_cfscriptLoginAjaxLocation, null, functionName, sendToServer, logoutReceiver);
}
function logoutReceiver(object)
{
	alert(object.AJAXOUTPUT);
	window.location.href = "/index.cfm"
}

function changePass()
{
		var OPASS = document.getElementById('opassword').value;
		var NPASS = document.getElementById('npassword').value;
		var VPASS = document.getElementById('vpassword').value;
		if(VPASS != NPASS){
			alert('New passwords do not match');
		}else{
			if(OPASS!=="" && NPASS!=="" && VPASS!==""){
				var sendToServer = encodeURI(OPASS + "||" + NPASS);
				var functionName = "changePass";
				DWREngine._execute(_cfscriptLoginAjaxLocation, null, functionName, sendToServer, changePassReciever);
			}else
				alert('Please fill in all fields');
			}
}

function changePassReciever(object)
{
	if(object.AJAXFOUND === "T"){
		alert('Your password has been changed successfully.');
		window.location.href = "/admin.cfm"
	}
	else{
		alert('Invalid Credentials.');
	}
}

function showChangePass()
{
	dialogbox.dialog( "option", "title", "Change Password");
	document.getElementById("infobox").style.display = "none";
	document.getElementById("timetable").style.display = "none";
	document.getElementById("newrestable").style.display = "none";
	document.getElementById("lookuprestable").style.display = "none";
	document.getElementById("options").style.display = "none";
	document.getElementById("changepasstable").style.display = "inline";
	dialogbox.dialog( "option", "width", 400 );
	dialogbox.dialog( "option", "height", 180 );
	dialogbox.dialog( "open" );
}
</script>
<!----END of login page functions--->
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
<center><font size="5px;"><b>Manager View</b></font></center>
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
	<td><input id="timepicker_input" placeholder="Click Here" size="14" readonly="readonly" type="text"></td>
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
	<td colspan=2 align="right"><input type="button" onClick="tempPerson();" value="Submit" onkeydown="if (event.keyCode == 13) tempPerson();" id="submitButton"></td>
</tr>
</table>
<table cellpadding="4" id="lookuprestable" style="display:none">
<tr>
	<td>First Name:</td>
	<td align="right"><input type="textbox" placeholder="First Name" id="F_Name_Box2" onkeydown="if (event.keyCode == 13) lookupappointment();" style="width:175px;"></td><td><span id="F_NAME_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Last Name:</td>
	<td align="right"><input type="textbox" placeholder="Last Name" id="L_Name_Box2" onkeydown="if (event.keyCode == 13) lookupappointment();"style="width:175px;"></td><td><span id="L_NAME_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td>Email Address:</td>
	<td align="right"><input type="textbox" placeholder="example@email.com" id="Email_Box2" onkeydown="if (event.keyCode == 13) lookupappointment();"style="width:175px;"></td><td><span id="EMAIL_SPAN"><font color="white" style="visibility: hidden">*</font></span></td>
</tr>
<tr>
	<td colspan=2 align="right"><input type="button" onClick="lookupappointment();" value="Submit" id="submitButton"></td>
</tr>
</table>
</center>
<!----Table for the options page---->
<div id="options" style="display:none">
<center>
<font size="2px;"><b>Only edit the fields of the options you want to change.
<br>If you want to remove the midday break entirely, set the start and end times equal to each other.</b></font>
<br><br>
<table>
<tr>
	<td>Set Duration (in minutes):</td>
	<td><input type="textbox" placeholder="#options.slotlength#" id="DurationBox" onkeydown="if (event.keyCode == 13) changeOptions();"></td>
</tr>
</table>
<table>
<tr>
	<td>Start and end of the workday:</td>
	<td align ="right"><input id="wdstart" placeholder="#TimeFormat(options.wdstart, "hh:mm tt")#" size="14" type="text"></td>
	<td ><input id="wdend" placeholder="#TimeFormat(options.wdend, "hh:mm tt")#" size="14" type="text"></td>
</tr>
<tr>
	<td>Start and end of the midday break:</td>
	<CFIF options.breakstart IS NOT "">
	<td align ="right"><input id="breakstart" placeholder="#TimeFormat(options.breakstart, "hh:mm tt")#" size="14" type="text"></td>
	<td><input id="breakend" placeholder="#TimeFormat(options.breakend, "hh:mm tt")#" size="14" type="text"></td>
	<CFELSE>
	<td align ="right"><input id="breakstart" placeholder="None" size="14" type="text"></td>
	<td><input id="breakend" placeholder="None" size="14" type="text"></td>
	</CFIF>
</tr>
</table>
<br>
<table>
<tr>
	<td colspan=2 align=center>Days of the week appointments can be made on:</td>
</tr>
<tr>
	<td colspan=2 align ="center"><div class="checkbox-group">
              <ul>
				<li>
                	<input type="checkbox" 
					<CFIF Find(0, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="sun"/>
	                <label for="sun">SUN</label>
                </li>
                <li>
                	<input type="checkbox" 
					<CFIF Find(1, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="mon"/>
	                <label for="mon">MON</label>
                </li>
                <li>
                	<input type="checkbox" 
					<CFIF Find(2, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="tue"/>
	                <label for="tue">TUE</label>
                </li>
                <li>
                	<input type="checkbox" 
					<CFIF Find(3, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="wed"/>
	                <label for="wed">WED</label>
                </li>
                <li>
                	<input type="checkbox" 
					<CFIF Find(4, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="thur"/>
	                <label for="thur">THUR</label>
                </li>
                <li>
                	<input type="checkbox" 
					<CFIF Find(5, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="fri"/>
	                <label for="fri">FRI</label>
                </li>
                <li>
                	<input type="checkbox" 
					<CFIF Find(6, '#options.dow#') IS NOT 0>
					checked
					</CFIF>
					id="sat"/>
	                <label for="sat">SAT</label>
                </li>
              </ul>
</div></td>
</tr>
<tr>
	<td>Set length of time for past events to be stored (in days):</td>
	<td><input type="textbox" placeholder="#options.KeepRecordsFor#" id="PastBox" onkeydown="if (event.keyCode == 13) changeOptions();"></td>
<tr>
<tr>
	<td>Set length of time to allow future events to be scheduled (in days):</td>
	<td><input type="textbox" placeholder="#options.MaxAdvanceSchedule#" id="FutureBox" onkeydown="if (event.keyCode == 13) changeOptions();"></td>
<tr>
<tr>
	<td>Set number of concurrent slots:</td>
	<td><input type="textbox" placeholder="#options.concurslots#" id="SlotsBox" onkeydown="if (event.keyCode == 13) changeOptions();"></td>
<tr>
<tr>
	<td colspan="2" align="center"><input type="button" onClick="changeOptions();" value="Submit" id="submitButton"></td>
</tr>
</table>
<div id="MessageDiv"></div>
</center>
</div>
<!----End of options---->
<!---Change password table--->
<center>
<table id="changepasstable" style="display:none">
	<tr>
		<td>Old Password:</td>
		<td align="right" width=50%><input type="password" placeholder="Old Password" id="opassword" onkeydown="if (event.keyCode == 13) changePass();"><br></td>
	</tr>
	<tr>
		<td>New Password:</td>
		<td align="right"><input type="password" placeholder="New Password" id="npassword" onkeydown="if (event.keyCode == 13) changePass();"><br></td>
	</tr>
	<tr>
		<td>Validate Password: </td>
		<td align="right"><input type="password" placeholder="Verify Password"  id="vpassword" onkeydown="if (event.keyCode == 13) changePass();"><br></td>
	</tr>
	<tr>
		<td align="right" colspan=2><input type="button"  onClick="changePass();" value="Submit" id="loginButton"></td>
	</tr>
</table>
</center>
<!---END of change password table--->
</div>	
	<div id='calendar'></div>
	<center>
<!---<font size="2px;"><b>Click <a href='##' onclick='showNewRes()'>here</a> to schedule a new appointment or <a href='##' onclick='showLookup()'>here</a> to look up an existing appointment.</b></font>--->
<br><input type=button value="Schedule New Appointment" onclick='showNewRes();'>  <input type=button value="Lookup Existing Appointment" onclick='showLookup();'>
</center><br>
	<center><font size="2px;">Drag an appointment to reschedule or click one for more options.</font></center>
	<center><font size="2px;">Slots that are full are marked in red.</font></center>
	<br>
<center>
<table cellpadding="4px">
<tr>
	<td><input type=button onclick='logout();' value="Logout"></td>
	<td><input type=button onclick='showChangePass();' value="Change Password"></td>
	<td><input type=button onclick='showOptions();' value="Options"></td>
<tr>
</table>
</center> 
</body>


<script src="includes/ng_lite.js" type="text/javascript"></script>
<script src="includes/components/timepicker_lite.js" type="text/javascript"></script>
<script type="text/javascript">
ng.ready( function() {
    tp = new ng.TimePicker({
        input: 'timepicker_input',  // the input field id
        start: '#TimeFormat(#options.wdstart#,'h:mm tt')#',  // what's the first available hour
        end: '#TimeFormat(#options.endslot#,'h:mm tt')#',  // what's the last avaliable hour
        top_hour: 12 // what's the top hour (in the clock face, 0 = midnight)
    });
	tp1 = new ng.TimePicker({
        input: 'wdstart',  // the input field id
        top_hour: 12 // what's the top hour (in the clock face, 0 = midnight)
    });
	tp2 = new ng.TimePicker({
        input: 'wdend',  // the input field id
        top_hour: 12 // what's the top hour (in the clock face, 0 = midnight)
    });
	tp3 = new ng.TimePicker({
        input: 'breakstart',  // the input field id
        top_hour: 12 // what's the top hour (in the clock face, 0 = midnight)
    });
	tp4 = new ng.TimePicker({
        input: 'breakend',  // the input field id
        top_hour: 12 // what's the top hour (in the clock face, 0 = midnight)
    });
});
</script>
</cfoutput>
<CFELSE>
<CFOUTPUT>
<script>
alert("Please login to view this page.");
window.location.href = "/index.cfm"
</script>
</CFOUTPUT>
</CFIF>
