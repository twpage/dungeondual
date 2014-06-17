$(function(){
	var checkSocket = function () {
		$("#socket_test").html("<strong>Co-Op Server Status: Offline</strong>");
		var mySocket = new window.WebSocket(
			"ws://108.59.10.243:10496/?game_id=0&user_id=0"
		);
		mySocket.onopen = function () {
			$("#socket_test").html("<strong>Co-Op Server Status: ONLINE</strong>");
		};
	};

	checkSocket();
	// var finishRegister = function (json_response) {
	// 	console.log(json_response);
	// 	if (json_response["status"] == "OK") {
	// 		$("#id_div_register").html("<p>" + json_response["message"] + "</p>");
	// 	} else {
	// 		$("#id_div_register").html("<p><u>" + json_response["message"] + "</u></p>");
	// 	}
		
	// };

	// $("#id_btn_register").click(function () {
	// 	var username = $("#id_username").val();
	// 	var pass = $("#id_password").val();

	// 	var ajax_url =  "/ajax/register/" + username + "/" + pass + "/";

	// 	$.ajax({
	// 		url: ajax_url,
	// 		// data: {
	// 		// 	"username": username,
	// 		// 	"password": pass
	// 		// },
	// 		success: function (json_response) { finishRegister(json_response); }
	// 	});
	// });
});
