
// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.afterDelete("ImaginaryFriend", function(request) {
	initiatorQuery = new Parse.Query("ChatRoom");
	initiatorQuery.equalTo("initiatorImaginaryFriendID", request.object.id);

	receiverQuery = new Parse.Query("ChatRoom");
	receiverQuery.equalTo("receiverImaginaryFriendID", request.object.id);

	query = Parse.Query.or(initiatorQuery, receiverQuery);
	query.find({
 		success: function(results) {
 			results.forEach(function(room) {
 				room.set("wasDeactivated", true);
 				room.save();
 			});
  		},

  		error: function(error) {
  		}
	});
});
