$(function(){

	var finishRegister = function (json_response) {
		console.log(json_response);
		if (json_response["status"] == "OK") {
			$("#id_div_register").html("<p>" + json_response["message"] + "</p>");
		} else {
			$("#id_div_register").html("<p><u>" + json_response["message"] + "</u></p>");
		}
		
	};

	$("#id_btn_register").click(function () {
		var username = $("#id_username").val();
		var pass = $("#id_password").val();

		var ajax_url =  "/ajax/register/" + username + "/" + pass + "/";

		$.ajax({
			url: ajax_url,
			// data: {
			// 	"username": username,
			// 	"password": pass
			// },
			success: function (json_response) { finishRegister(json_response); }
		});
	});
});
