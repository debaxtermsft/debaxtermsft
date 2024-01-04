<!DOCTYPE html>
<html>

<head>
	<title>Getting Clients IP</title>
	<style>
	p, h1 {
		color: green;
	}
	</style>

	<script src=
"https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js">
	</script>
	
	<script>
	
	/* Add "https://api.ipify.org?format=json" statement
			this will communicate with the ipify servers in
			order to retrieve the IP address $.getJSON will
			load JSON-encoded data from the server using a
			GET HTTP request */
				
	$.getJSON("https://api.ipify.org?format=json", function(data) {
		
		// Setting text of element P with id gfg
		$("#gfg").html(data.ip);
	})
	</script>
</head>

<body>
	<center>
		<h1>GeeksforGeeks</h1>
		<h3>Public IP Address of user is:</h3>
		<p id="gfg"></p>

	</center>
</body>

</html>
