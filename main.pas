program test;

uses 
		conversations
	,	messages
	,	users
	,	screens
	;			


var conversation
			:conversationsList
	;	user
			:userTree
	;

begin
	loadUsers ( user );
	loadConversations ( conversation, user );
	writeln(':: Bienvenido a Guatsap ::');
	beforeLog ( user, conversation );
end.