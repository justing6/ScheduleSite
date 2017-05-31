_cfscriptTestAjaxLocation = "/includes/ajax/functions/testAjax.cfm";
_cfscriptLoginAjaxLocation = "/includes/ajax/functions/loginAjax.cfm";
_cfscriptAdminAjaxLocation = "/includes/ajax/functions/adminAjax.cfm";
_cfscriptCalendarAjaxLocation = "/includes/ajax/functions/calendarAjax.cfm";

function errorHandler(message)
{
	$('disabledZone').style.visibility = 'hidden';
    if (typeof message == "object" && message.name == "Error" && message.description)
    {
        alert("Error: " + message.description);
    }
    else
    {
        alert(message);
    }
};
