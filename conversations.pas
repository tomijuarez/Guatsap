unit conversations;

interface
	uses users, messages;
	const CONVERSATIONSFILE_ = 'data/conversations'
		;

	type	conversationsList = ^simpleCList
			;	conversationFields =
					record
							code : Integer
						;	sender : String [ 8 ]
						;	receiver : String [ 8 ]
					end
			;	simpleCList =
					record
							code : Integer
						;	sender : Users.UserTree
						;	receiver	: Users.UserTree
						;	message : messagesList
						;	next :	conversationsList
						;
					end
			;	conversationsFile
					=	file of conversationFields
			;	

	procedure openConversationsFile   ( var _file: conversationsFile; _fileName: String; var error: Boolean );
	procedure loadConversations       ( var conversations: conversationsList; users: userTree );
	procedure saveConversations       ( conversations: conversationsList );
	function  newConversation         ( _users, currentUser: Users.userTree; destinatary: String; var conversations: conversationsList ): conversationsList;
	procedure activeConversations     ( users, currentUser: userTree; conversations: conversationsList );
	procedure allConversations        ( currentUser: userTree; conversations: conversationsList );
	procedure particularConversation  ( code, quantity: Integer; conversations: conversationsList; users, currentUser: userTree );
	procedure deleteConversationsData ( var conversations: conversationsList; currentUser: userTree );
	function  hasActiveConversations  ( conversations: conversationsList; currentUser: userTree ): Boolean;

implementation

function getConversationLastCode ( conversations: conversationsList ): Integer;
	begin
		getConversationLastCode := 0;

		if ( conversations <> nil ) then
			if ( conversations^.next <> nil ) then
				getConversationLastCode := getConversationLastCode ( conversations^.next )
			else
				getConversationLastCode := conversations^.code;
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

function createConversationNode ( var newNode: conversationsList; conversationData: conversationFields; users, currentUser, destinatary: userTree ): boolean;
  var _messages
  		:messagesList
  	;
  begin
   	createConversationNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createConversationNode := true;
      	with newNode^ do 
      		begin
        		code := conversationData.code;
        		if ( currentUser <> nil ) and ( destinatary <> nil ) then
        			begin
        				sender := currentUser;
        				receiver := destinatary;
        			end
        		else
        			begin
        				sender := userExists (users, conversationData.sender);
        				receiver := userExists(users, conversationData.receiver);
		        	end;
		        loadmessages ( _messages, conversationData.code, users );
		        message := _messages;
        		next := nil;
        end;
      end;
  end;

procedure insertSortedConversation ( var conversations, newNode: conversationsList );
	begin
		if ( conversations <> nil ) then
			if ( conversations^.code >= newNode^.code ) then
        begin
          newNode^.next := conversations;
          conversations := newNode;
        end
      else
        if ( conversations^.next <> nil ) and ( conversations^.next^.code >= newNode^.code ) then
          begin
            newNode^.next := conversations^.next;
            conversations^.next := newNode;
          end
        else
          insertSortedConversation ( conversations^.next, newNode )
    else
      begin
        newNode^.next := conversations;
        conversations := newNode;
      end;
    end;

procedure createConversationListFromFile ( var conversations: conversationsList; var conversationsStored: conversationsFile; users: userTree );
	var	conversationData
				: conversationFields
		;	newNode 
				:conversationsList
		;
	begin
		
		while not eof ( conversationsStored ) do
			begin
				read ( conversationsStored, conversationData );
				if ( createConversationNode ( newNode, conversationData, users, nil, nil ) ) then begin
					insertSortedConversation ( conversations, newNode );
				end;
			end;
	end;

procedure loadConversations ( var conversations: conversationsList; users: userTree );
	var error
				: boolean
		;	conversationsStored
				: conversationsFile
		;	r
				:conversationFields
		;
	begin
		openConversationsFile ( conversationsStored, CONVERSATIONSFILE_, error );
		if ( error ) then
			begin
				close ( conversationsStored );
				rewrite ( conversationsStored );
			end;
		
		createConversationListFromFile ( conversations, conversationsStored, users );
		close ( conversationsStored );
	end;

procedure saveConversationsInformationFromList ( var conversationsStore: conversationsFile; var node: conversationsList );
	var	newNode
				:conversationFields
		;
	begin
		with newNode do
			begin
				code := node^.code;
				sender := node^.sender^.nick;
				receiver := node^.receiver^.nick;
			end;
		write ( conversationsStore, newNode );
	end;

procedure getconversationsNode ( conversations: conversationsList; var conversationsStore: conversationsFile );
	begin
		if ( conversations <> nil ) then
			begin
				saveConversationsInformationFromList ( conversationsStore, conversations );
				getconversationsNode ( conversations^.next, conversationsStore );
			end;
	end;

procedure saveMessagesFromConversation ( conversations: conversationsList );
	begin
		if ( conversations <> nil ) then
			begin
				saveMessages ( conversations^.message, conversations^.code );
				saveMessagesFromConversation ( conversations^.next );
			end;
	end;


procedure saveConversations ( conversations: conversationsList );
	var conversationsStore 
				:conversationsFile
		;	error
				:Boolean
		;
	begin
		openConversationsFile ( conversationsStore, CONVERSATIONSFILE_, error );
		close ( conversationsStore );
		rewrite ( conversationsStore );
		getconversationsNode ( conversations, conversationsStore );
		saveMessagesFromConversation ( conversations );
	end;


function conversationExists ( conversations: conversationsList; currentUser, destinatary: userTree ): Boolean;
	begin
		conversationExists := false;
		if ( conversations <> nil ) then
			begin
				if ( ( conversations^.sender = currentUser ) and ( conversations^.receiver = destinatary ) ) or ( ( conversations^.sender = destinatary ) and ( conversations^.receiver = currentUser ) ) then
					conversationExists := true
				else
					conversationExists := conversationExists ( conversations^.next, currentUser, destinatary );	
			end;	
	end;

function isParticipant ( conversations: conversationsList; currentUser: userTree ): Boolean;
	begin
		isParticipant := false;
		if ( conversations <> nil ) then
			if ( conversations^.sender = currentUser ) or ( conversations^.receiver = currentUser ) then
				isParticipant := true;
	end;

function createConversation ( var conversations: conversationsList; currentUser, destinatary: userTree ): conversationsList;
	var	conversationData
				: conversationFields
		;	newNode 
				:conversationsList
		;
	begin
		createConversation := nil;

		conversationData.code := getConversationLastCode(conversations) + 1;
		if ( createConversationNode ( newNode, conversationData, nil, currentUser, destinatary ) ) then
			begin
				insertSortedConversation ( conversations, newNode );
				createConversation := newNode;
			end;
	end;


function newConversation ( _users, currentUser: userTree; destinatary: String; var conversations: conversationsList ): conversationsList;
	var userDestinatary
				:userTree
		;
	begin
		newConversation := nil;
		userDestinatary := userExists ( _users, destinatary );

		if ( userDestinatary <> nil ) then
			begin
				if not conversationExists ( conversations, currentUser, userDestinatary ) then
					newConversation := createConversation ( conversations, currentUser, userDestinatary )
				else
					writeln('La conversacion ya existe');
			end
		else
			writeln('El usuario seleccionado no existe');
	end;

procedure activeConversations ( users, currentUser: userTree; conversations: conversationsList );
	var messages
				:messagesList
		;	unreaded 
				:Integer
		;
	begin
		if ( conversations <> nil ) then
			begin
				if ( isParticipant ( conversations, currentUser ) ) then
					if ( conversations^.message <> nil ) then
						begin
							unreaded := countUnreadedMessages ( conversations^.message, currentUser );
							if ( unreaded > 0 ) then
								if ( conversations^.sender = currentUser ) then
									writeln('<',conversations^.receiver^.nick,'><',conversations^.code,'>[',unreaded,'] mensajes no leidos en esta conversacion')
								else
									writeln('<',conversations^.sender^.nick,'><',conversations^.code,'>[',unreaded,'] mensajes no leidos en esta conversacion');
						end;
				activeConversations ( users, currentUser, conversations^.next );
			end
		else
			writeln('No hay mas conversaciones activas.');
	end;

function hasActiveConversations ( conversations: conversationsList; currentUser: userTree ): Boolean;
	begin
		hasActiveConversations := false;
		if ( conversations <> nil ) then
			if ( conversations^.message <> nil ) then
				if ( hasUnreadedMessages ( conversations^.message, currentUser ) ) then
					hasActiveConversations := true
				else
					hasActiveConversations := hasActiveConversations ( conversations^.next, currentUser );
	end;

procedure allConversations ( currentUser: userTree; conversations: conversationsList );
	begin
		if ( conversations <> nil ) then
			begin
				if ( isParticipant ( conversations, currentUser ) ) then
					if ( currentUser = conversations^.receiver ) then
						writeln('<',conversations^.code,'><',conversations^.sender^.nick,'>')
					else
						writeln('<',conversations^.code,'><',conversations^.receiver^.nick,'>');
				allConversations( currentUser, conversations^.next );
			end;
	end;

function findConversation ( conversations: conversationsList; code: Integer ): conversationsList;
	begin
		findConversation := nil;
		if ( conversations <> nil ) then
			begin
				if ( conversations^.code = code ) then
					findConversation := conversations
				else
					findConversation := findConversation ( conversations^.next, code );			
			end;		
	end;

procedure particularConversation ( code, quantity: Integer; conversations: conversationsList; users, currentUser: userTree );
		var option
					:Integer
			;	conversationf
					:conversationsList
			;

		begin
			conversationf := findConversation ( conversations, code );
			if ( conversationf <> nil ) then
				if ( isParticipant ( conversationf, currentUser ) ) then
					begin
						lastMessages ( conversationf^.message, quantity, currentUser );
						writeln('Presiona 1 para enviar un mensaje, en caso contrario pulsa cualquier otra tecla');
						readln(option);
						while ( option = 1 ) do
							begin
								sendMessage ( conversationf^.message, users, currentUser );
								writeln('Presiona 1 para enviar un mensaje, en caso contrario pulsa cualquier otra tecla');
								readln(option);
							end;
					end
				else
					writeln('No perteneces a esta conversacion')
			else
				writeln('La conversacion que intentas ver no existe o se ha eliminado');{OJO}
		end;

	procedure deleteConversationsData ( var conversations: conversationsList; currentUser: userTree );
		var toDelete
					:conversationsList
			;

		begin
			if ( conversations <> nil ) then
				begin
					if ( isParticipant ( conversations^.next, currentUser ) ) then
						begin
							toDelete := conversations;
					    conversations := toDelete^.next;
					    dispose ( toDelete );
					  end
					else
					  deleteConversationsData ( conversations^.next, currentUser );
				end;
		end;
end.
