<CFOUTPUT>

<body>
<ul class="nav" style="width:97%;z-index:3">
	<li><a href="/newreservation.cfm">Make Reservation</a></li>
	<li><a href="/admin.cfm">Manage Reservations</a></li>
    <li id="options">
        <a href="##">Options</a>
        <ul class="subnav" style="z-index:3;">
			<li><a href="/about.cfm"><font size="2px;">About</font></a></li>
            <li><a href="/change.cfm"><font size="2px;">Change Password</font></a></li>
            <li><a onClick="logout();"><font size="2px;">Logout</font></a></li>
        </ul>
    </li>
</ul>
</body>
</cfoutput>