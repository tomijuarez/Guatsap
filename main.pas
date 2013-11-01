program guatsap;
uses 
		crt
	,	sysutils
	;

const USERSFILE_ = 'users'
	;

type
			userTree = ^tree
		;	conversationsList = ^doubleList
		;	messagesList = ^simpleList
		;	userFields = 
				record
						nick : String [ 8 ]
					;	password : String [ 8 ]
				end
		;	messageFields = 
				record
						date : String
					;	viewed : Boolean
					;	text : String
					;	sender : userTree
				end
		;	conversationFields =
				record
						code : Integer
					;	message : messagesList
					;	sender : userTree
					;	receiver : userTree
				end
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

{**
 * ETAPA DE CARGA DE USUARIOS
 *}

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

function createUserNode ( var newNode: userTree; userData: userFields ): boolean;
  begin
   	createUserNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createUserNode := true;
      	with newNode^ do begin
        	nick := userData.nick;
        	password := userData.password;
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
			if ( _tree^.nick <= _userNode^.nick ) then
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
				if ( createUserNode ( userNode, Information ) ) then
					insertUserNode ( _tree, userNode );
			end;
	end;

procedure loadUsers ( var users: userTree );
	var error
				: boolean
	;	usersStored
			:usersFile
	;
	begin
		users := nil;
		openUsersFile ( usersStored, USERSFILE_, error );
		if not ( error ) then
			begin
				createTreeFromFile ( users, usersStored );
				close ( usersStored );
			end;
	end;

function userExists ( users: userTree; nick: String ): userTree;
	begin
		if ( users <> nil ) then
			begin
				if ( users^.nick < nick ) then
					userExists := userExists ( users^.big, nick );
				if ( users^.nick > nick ) then
					userExists := userExists ( users^.low, nick );
				if ( users^.nick = nick ) then
					userExists := users;
			end
		else
			userExists := nil;
	end;

{**
 * ETAPA DE CARGA DE MENSAJES
 *}

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

function createMessageNode ( var newNode: messagesList; messageData: messageFields ): boolean;
  begin
   	createMessageNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createMessageNode := true;
      	with newNode^ do begin
        	sender := messageData.Sender;
        	text := messageData.Text;
        	date := null;
        	next := nil;
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

procedure createMessagesListFromFile ( var messages: messagesList; var messagesStored: messagesFile );
	var	messageData
				: messageFields
		;	newNode 
				:messagesList
		;
	begin
		
		while not eof ( messagesStored ) do
			begin
				read ( messagesStored, messageData );
				if ( createMessageNode ( newNode, messageData ) ) then
					insertSortedMessage ( messages, newNode );
			end;
	end;

procedure loadMessages ( var messages: messagesList; fileName: String );
	var error
				: boolean
		;	messagesStored
				: messagesFile
		;
	begin
		openMessagesFile ( messagesStored, fileName, error );
		if not ( error ) then
			createMessagesListFromFile ( messages, messagesStored );
	end;

{**
 * ETAPA DE CARGA DE CONVERSACIONES
 *}

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


function createConversationNode ( var newNode: conversationsList; conversationData: conversationFields ): boolean;
  begin
   	createConversationNode := false;
    new ( newNode );
    if ( newNode <> nil ) then
      begin
      	createConversationNode := true;
      	with newNode^ do 
      		begin
        		code := conversationData.Code;
        		message := conversationData.Message;
        		sender := conversationData.Sender;
        		receiver := conversationData.Receiver;
        		next := nil;
        		previous := nil;
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

procedure createConversationListFromFile ( var conversations: conversationsList; var conversationsStored: conversationsFile );
	var	conversationData
				: conversationFields
		;	newNode 
				:conversationsList
		;
	begin
		
		while not eof ( conversationsStored ) do
			begin
				read ( conversationsStored, conversationData );
				if ( createConversationNode ( newNode, conversationData ) ) then
					insertSortedConversation ( conversations, newNode );
			end;
	end;

procedure loadConversations ( var conversations: conversationsList; fileName: String );
	var error
				: boolean
		;	conversationsStored
				: conversationsFile
		;
	begin
		openConversationsFile ( conversationsStored, fileName, error );
		if not ( error ) then
			createConversationListFromFile ( conversations, conversationsStored );
	end;


{**
 * ETAPA DE GUARDADO
 *}

procedure saveUserInformationFromTree ( var usersStore: usersFile; var node: userTree );
	var	newUser
				:userFields
		;
	begin
		with newUser do
			begin
				nick := node^.nick;
				password := node^.password;
			end;
		write ( usersStore, newUser );
	end;

procedure getUsersNode ( users: userTree; var usersStore: usersFile );
	begin
		if ( users <> nil ) then
			begin
				getUsersNode ( users^.low, usersStore );
				saveUserInformationFromTree ( usersStore, users );
				getUsersNode ( users^.big, usersStore ); 
			end;
	end;

procedure saveUser ( users: userTree );
	var usersStore 
				:usersFile
		;	error
				:Boolean
		;
	begin
		openUsersFile ( usersStore, USERSFILE_, error );
		if ( error ) then
			writeln('No se pudo guardar')
		else
			begin
				writeln('Se ha guardado el usuario');
				rewrite ( usersStore );
				getUsersNode ( users, usersStore );
			end;
	end;

{**
 * ETAPA DE MENUES
 *}

procedure imprimirArbolAscendente ( arbol: userTree );
	begin
		if ( arbol <> nil ) then
			begin
				imprimirArbolAscendente ( arbol^.low );
				writeln ( arbol^.nick );
				imprimirArbolAscendente ( arbol^.big );
			end;
	end;

procedure logout ( var users: userTree );
	begin
		writeln('Guardando usuario');
		saveUser ( users );	
		imprimirArbolAscendente ( users );	
	end;

procedure afterLog ( var users, currentUser: userTree );
	var option
				:Integer
		;
	begin
		writeln('Presiona 1 para cerrar sesion');
		readln ( option );
		if ( option = 1 ) then
			logout ( users );

	end;

function passwordAccepted ( user: userTree; password: String ): Boolean;
	begin	
		passwordAccepted := true;
		if ( user^.password <> password ) then
			passwordAccepted := false;
	end;

procedure login;
	var nick
		,	password
				: String [ 8 ]
		;	currentUser
		,	users
				:userTree
		;
	begin
		
		writeln('Ingrese su nombre de usuario');
		loadUsers ( users );
		readln ( nick );
		if ( users <> nil ) then
			begin
				currentUser := userExists ( users, nick );
				if ( currentUser <> nil ) then
					begin
						writeln ('Ingrese su contraseña');
						readln ( password );
						if ( passwordAccepted ( currentUser, password ) ) then
							afterLog ( users, currentUser )
						else
							begin
								writeln( 'La contraseña no es correcta' );
								login ();
							end
					end
				else
					begin
						writeln( 'El usuario no existe' );
						login ()
					end
			end
		else
			writeln('No existen usuarios aun');
	end;

procedure register;
	var	_nick
		,	_password
				:String [ 8 ]	
		;	users
		,	currentUser
		,	newUser
				:userTree
		;	temporalUser
				:userFields
		;	validate
				:Boolean
		;
	begin
		validate := true;
		
		writeln('Ingrese su nombre de usuario');
		readln ( _nick );
		
		loadUsers ( users );
		
		if ( users <> nil ) then
			begin
				currentUser := userExists ( users, _nick );
				if ( currentUser <> nil ) then
					begin
						validate := false;
						writeln('El nombre de usuario ya ha sido seleccionado, por favor, elija otro');
						register();
					end;
			end;

		if ( validate ) then
			begin
				writeln ('Ingrese su contraseña');
				readln ( _password );
				with temporalUser do
					begin
						nick := _nick;
						password := _password;
					end;
				if ( createUserNode ( newUser, temporalUser ) ) then
					begin
						insertUserNode ( users, newUser );
						afterLog ( users, newUser );
					end
				else
					begin
						writeln('Un error ha ocurrido, por favor vuelva a intentarlo');
						register();
					end;
			end;
	end;

procedure beforeLog;
	var option
				:Integer
		;
	begin
		repeat 
			clrscr;
			gotoxy ( 30, 2 ); 
			writeln(':: Bienvenido a Guatsap ::');
			writeln('Presione 1 para crear una cuenta');
			writeln('Presione 2 para iniciar sesion');

			readln ( option );

			case option of
				1: register();
				2: login();
			end;
		until ( option <> 1 ) or ( option <> 2 ); 
	end;

begin
	beforeLog();
end.
