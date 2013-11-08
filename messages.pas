unit messages;

interface
	uses
		crt, SysUtils, users;

	const PATH_ = 'data/messages/'
		;

	type
			messagesList = ^simpleMList
		;	messageFields = 
				record
						date : String
					;	viewed : Boolean
					;	text : String
					;	sender : String [ 8 ]
				end
		;	simpleMList = 
				record 
						date : TDateTime
					;	viewed : Boolean
					;	text : String
					;	sender : users.userTree
					;	next : messagesList
				end
		;	messagesFile = file of messageFields 
		; 

	procedure loadMessages          ( var messages: messagesList; fileName: Integer; _users: userTree );
	procedure lastMessages          ( messages: messagesList; quantity: Integer; currentUser: userTree );
	procedure sendMessage           ( var messages: messagesList; userT, currentUser: userTree );
	procedure saveMessages          ( messages: messagesList; code: Integer );
	procedure printMessages         ( messages: messagesList; quantity, counter: Integer );
	procedure viewAll               ( var messages: messagesList; currentUser: userTree );
	function  hasUnreadedMessages   ( messages: messagesList; currentUser: userTree ): Boolean;
	function  countUnreadedMessages ( messages: messagesList; currentUser: userTree ): Integer;

implementation

	procedure openMessagesFile ( var _file: messagesFile; _fileName: Integer; var error: Boolean );
		begin
			error := false;
			assign ( _file, PATH_+intToStr(_fileName) );
			{$I-}
				reset ( _file );
			{$I+}	
			if ( ioResult <> 0 ) then
				error := true;
		end;

	function createMessageNode ( var newNode: messagesList; _text, userString, _date: string; userT, currentUser: userTree; _viewed: boolean; fromFile: boolean ): boolean;
	  begin
	   	createMessageNode := false;
	    new ( newNode );
	    if ( newNode <> nil ) then
	      begin
	      	createMessageNode := true;
	      	with newNode^ do begin
	      		next := nil;
	      		text := _text;
	      		if ( fromFile ) then
	      			begin
	      				sender := userExists ( userT, userString );
	      				viewed := _viewed;
	      				date := StrToDateTime ( _date );
	      			end
	      		else
	      			begin
			        	sender := currentUser;
			        	viewed := false;
			        	date := Now;
			        end;
	        end;
	      end;
	  end;

	procedure insertSortedMessage ( var messages, newNode: messagesList );
		begin
			if ( messages <> nil ) then
				if ( messages^.date >= newNode^.date ) then
	        begin
	          newNode^.next := messages;
	          messages := newNode;
	        end
	      else
	        if ( messages^.next <> nil ) and ( messages^.next^.date >= newNode^.date ) then
	          begin
	            newNode^.next := messages^.next;
	            messages^.next := newNode;
	          end
	        else
	          insertSortedMessage ( messages^.next, newNode )
	    else
	      begin
	        newNode^.next := messages;
	        messages := newNode;
	      end;
	    end;

	procedure createMessagesListFromFile ( var messages: messagesList; var messagesStored: messagesFile; _users: userTree );
		var	messageData
					: messageFields
			;	newNode 
					:messagesList
			;
		begin
			
			while not eof ( messagesStored ) do
				begin
					read ( messagesStored, messageData );
					if ( createMessageNode ( newNode, messageData.text, messageData.sender, messageData.date, _users, nil, messageData.viewed, true ) ) then
						insertSortedMessage ( messages, newNode );
				end;
		end;

	procedure loadMessages ( var messages: messagesList; fileName: Integer; _users: userTree );
		var error
					: boolean
			;	messagesStored
					: messagesFile
			;
		begin
			messages := nil;
			openMessagesFile ( messagesStored, fileName, error );
			if ( error ) then
				begin
					close(messagesStored);
					rewrite ( messagesStored );
				end;
	
			createMessagesListFromFile ( messages, messagesStored, _users );
			close ( messagesStored );
		end;

	procedure lastMessages ( messages: messagesList; quantity: Integer; currentUser: userTree );
		begin
			if ( messages = nil ) then
				writeln ('No hay mensajes en esta conversacion')
			else
				begin
					printMessages(messages, quantity, 0);
					viewAll ( messages, currentUser );
				end;
		end;
	
	procedure printMessages ( messages: messagesList; quantity, counter: Integer );
		begin
			if ( messages <> nil ) and ( ( quantity = 0 ) or ( counter <= quantity ) ) then
				begin
					writeln('_____________');
					writeln ( '<',messages^.date,'>','<',messages^.sender^.nick,'>: ',messages^.text);
					writeln('_____________');
					printMessages(messages^.next, quantity, counter + 1 );
				end;
		end;

	procedure sendMessage ( var messages: messagesList; userT, currentUser: userTree );
		var text
					:String
			;	newNode
					:messagesList
			;

		begin
			writeln('Ingrese el texto del mensaje');
			readln (text);
			if ( text <> '' ) then
				begin
					if ( createMessageNode ( newNode, text, '', '', userT, currentUser, false, false ) ) then
						insertSortedMessage ( messages, newNode );
				end;
		end;

	{Guarda en archivo desde un nodo}
procedure saveMessagesInformationFromList ( var MessagesStore: MessagesFile; var node: messagesList );
	var	newNode
				:messageFields
		;
	begin
		with newNode do
			begin
				date := datetimetostr ( node^.date );
				sender := node^.sender^.nick;
				viewed := node^.viewed;
				text := node^.text;
			end;
		write ( messagesStore, newNode );
	end;

procedure getMessagesNode ( var messages: messagesList; var messagesStore: messagesFile );
	begin
		if ( messages <> nil ) then
			begin
				saveMessagesInformationFromList ( messagesStore, messages );
				getMessagesNode ( messages^.next, messagesStore );
			end;
	end;

procedure viewAll ( var messages: messagesList; currentUser: userTree );
	begin
		if ( messages <> nil ) then
			begin
				if not ( messages^.viewed ) and ( messages^.sender <> currentUser ) then
					messages^.viewed := true;
				viewAll ( messages^.next, currentUser );
			end;
	end;

function countUnreadedMessages ( messages: messagesList; currentUser: userTree ): Integer;
	var sum
				:Integer
		;
	begin
		sum := 0;
		if ( messages <> nil ) then
			begin
				if ( messages^.sender <> currentUser ) and not ( messages^.viewed ) then
					sum := 1;

				sum := countUnreadedMessages ( messages^.next, currentUser ) + sum;
			end;

		countUnreadedMessages := sum;
	end;

function hasUnreadedMessages ( messages: messagesList; currentUser: userTree ): Boolean;
	begin
		hasUnreadedMessages := false;
		if ( messages <> nil ) then
			begin
				if ( messages^.sender = currentUser ) or ( messages^.viewed ) then
					hasUnreadedMessages := hasUnreadedMessages ( messages^.next, currentUser )
				else
					hasUnreadedMessages := true;
			end;
	end;

	procedure saveMessages ( messages: messagesList; code: Integer );
		var messagesStore
					:messagesFile
			;	error
					:Boolean
			;
		begin
			openMessagesFile ( messagesStore, code, error );{OJO, HABÍA UN IF RESPECTO AL ERROR Y ESTO ESTABA DENTRO}
			close(messagesStore);
			rewrite ( messagesStore );
			if ( messages <> nil ) then
				begin
					getMessagesNode ( messages, messagesStore );
					close(messagesStore);
				end
		end;
end.
