program guatsap;

type
		userFields = 
				record
						nick : String [ 8 ]
					;	password : String [ 8 ]
				end
		;	messageFields = 
				record
						date : String
					;	viewed : Boolean
					;	text : String
				end
		;	conversationFields =
				record
						code : Integer
					;	message : String
					;	sender : String
					;	receiver : String
				end
		;
			userTree = ^tree
		;	conversationsList = ^doubleList
		;	messagesList = ^simpleList
		;	tree = 
				record 
						nick : String [ 8 ]
					;	password : String [ 8 ]
					; low : userTree
					;	big	: userTree
				end
		;	doubleList = 
				record 
						code : Integer
					;	message : messagesList
					;	sender : userTree
					;	receiver : userTree
					;	next	:	conversationsList
					;	previous	:	conversationsList
				end
		;	simpleList = 
				record 
						date : String
					;	viewed : Boolean
					;	text : String
					;	sender : userTree
					;	next : messagesList
				end
		;	usersFile = file of userFields
		;	conversationsFile = file of conversationFields
		;	messagesFile = file of messageFields 
		;


procedure openUsersFile ( var _file: usersFile; _fileName: String; var error: Boolean );
	begin
		error := false;
		assign ( _file, _fileName );
		{$I-}
			reset ( _file );
		{$I+}	
		if ( ioResult <> 0 ) then
			error := true;
	end;

procedure openConversationsFile ( var _file: conversationsFile; _fileName: String; var error: Boolean );
	begin
		error := false;
		assign ( _file, _fileName );
		{$I-}
			reset ( _file );
		{$I+}	
		if ( ioResult <> 0 ) then
			error := true;
	end;

procedure openMessagesFile ( var _file: messagesFile; _fileName: String; var error: Boolean );
	begin
		error := false;
		assign ( _file, _fileName );
		{$I-}
			reset ( _file );
		{$I+}	
		if ( ioResult <> 0 ) then
			error := true;
	end;

function createUserNode ( var newNode: userTree; _nick, _password: String ): boolean;
  begin
   	createUserNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createUserNode := true;
      	with newNode^ do begin
        	nick := _nick;
        	password := _password;
        	big := nil;
        	low := nil;
        end;
      end;
  end;

procedure insertUserNode ( var _tree, _userNode: userTree );
	begin
		if ( _tree = nil ) then
			_tree := _userNode
		else
			if ( _tree^.nick <= _tree^.nick ) then
				insertUserNode ( _tree^.big, _userNode )
			else
				insertUserNode ( _tree^.low, _userNode );

	end;

procedure createTreeFromFile ( var _tree: userTree; var _file: usersFile );
	var Information
				:userFields
		;	userNode
				:userTree
		;

	begin
		while not eof ( _file ) do
			begin
				read ( _file, Information );
				if ( createUserNode ( userNode, Information.nick, Information.password ) ) then
					insertUserNode ( _tree, userNode );
			end;
	end;

procedure loadUsers ( var _tree: userTree; var _file: usersFile );
	begin
		createTreeFromFile ( _tree, _file );
	end;

function createMessageNode ( var newNode: messagesList; _sender: userTree; _text : String ): boolean;
  begin
   	createMessageNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createMessageNode := true;
      	with newNode^ do begin
        	sender := _sender;
        	text := _text;
        	date := null;
        	next := nil;
        end;
      end;
  end;

function createConversationNode ( var newNode: conversationsList; _code: Integer; _message: messagesList; _sender, _receiver: userTree ): boolean;
  begin
   	createConversationNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createConversationNode := true;
      	with newNode^ do begin
        	code := _code;
        	message := _message;
        	sender := _sender;
        	receiver := _receiver;
        	next := nil;
        	previous := nil;
        end;
      end;
  end;

begin

end.
