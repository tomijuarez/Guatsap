unit screens;

interface
  uses SysUtils
		 , crt
		 , users
		 , conversations
		 ;
		 
	procedure beforeLog ( var users: userTree; var conversations: conversationsList );	
	procedure afterLog  ( var users, currentUser: userTree; var conversations: conversationsList );

implementation
	
  procedure logout ( var users: userTree; conversations: conversationsList );
    begin
      saveUser ( users );
      saveConversations( conversations );
    end;

  procedure deleteAccount ( var users, currentUser: userTree; conversations: conversationsList );
    var option
          :Char
      ;
    begin
      writeln('Estas seguro que queres eliminar tu cuenta? Presione [y] para afirmar. Cualquier otra tecla para cancelar.');
      readln(option);
      if ( option = 'y' ) then
        if not ( hasActiveConversations ( conversations, currentUser ) ) then
          begin
            deleteConversationsData ( conversations, currentUser );
            deleteUser(currentUser);
            logout ( users, conversations );
          end
        else
          afterLog ( users, currentUser, conversations );
    end;

  procedure displayAccount ( var users, currentUser: userTree; conversations: conversationsList );
	  var option
		  		:Integer
		  ;
	  begin
		  writeln('Para volver al menu anterior presione 0');
		  writeln('Para cerrar sesion presione 1');
		  writeln('Para eliminar su cuenta presione 2');
		  readln ( option );

		  case option of
			  0	:	displayAccount ( users, currentUser, conversations );
			  1	:	logout ( users, conversations ); 
			  2	:	deleteAccount ( users, currentUser, conversations );
			  else
				  beforeLog ( users, conversations );
		  end;
	  end;

  procedure displayOptions ( var users, currentUser: userTree; var conversation: conversationsList );
	  var key
		  ,	code
			  	:Integer
		  ;	destinatary
			  	:String [ 8 ]
		  ;	createdConversationNode 
			  	:conversationsList
		  ;

	  begin
		  writeln('Para volver al menu anterior presione 0');
		  writeln('Para ver la lista de usuarios presione 1');
		  writeln('Para crear una nueva conversacion pesione 2');
		  writeln('Para ver las conversaciones activas presione 3');
		  writeln('Para ver todas las conversaciones presione 4');
		  writeln('Para ver una conversacion particular presione 5');
		  writeln('Para contestar un mensaje presione 6');

		  readln ( key );

		  case ( key ) of
				0	:	afterLog ( users, currentUser, conversation );
				1	: begin
							writeln('________________________________________________________________________________');
							showUsers ( users );
							writeln('________________________________________________________________________________');
						end;
				2	: begin
							readln ( destinatary );
							createdConversationNode := newConversation ( users, currentUser, destinatary, conversation );
							if ( createdConversationNode <> nil ) then
								writeln('La conversacion se ha creado, el codigo es ',createdConversationNode^.code);
						end;
				3 :	activeConversations ( users, currentUser, conversation );
				4	:	allConversations ( currentUser, conversation );
				5	: begin
							writeln('Ingresa el codigo de la conversacion');
							readln ( code );
							particularConversation ( code, 0, conversation, users, currentUser );
						end;
				6	:	begin
							writeln('Ingresa el codigo de la conversacion');
							readln ( code );
							particularConversation ( code, 5, conversation, users, currentUser );
						end;
				7	:	displayAccount ( users, currentUser, conversation )
			  else
				  begin
					  writeln('La opcion ingresada no es correcta');
					  displayOptions( users, currentUser, conversation );
				  end;
		  end;
		  afterLog ( users, currentUser, conversation );
	  end;


  procedure afterLog ( var users, currentUser: userTree; var conversations: conversationsList );
	  var option
		  		:Integer
		  ;
	  begin
		  writeln('Para ver opciones de cuenta presione 1');
		  writeln('Para comenzar a chatear presione 2');
		  readln ( option );
		  case option of
			  1	:	displayAccount ( users, currentUser, conversations );
			  2	:	displayOptions ( users, currentUser, conversations );
			  else
				  begin
					  writeln('La opcion ingresada no es correcta');
					  afterLog ( users, currentUser, conversations );
				  end;
		  end;
	  end;


	procedure login ( var users: userTree; var conversations: conversationsList );
		var nick
			,	password
					: String [ 8 ]
			;	currentUser
					:userTree
			;
		begin
			writeln('Ingrese su nombre de usuario');
			readln ( nick );
			if ( users <> nil ) then
				begin
					currentUser := userExists ( users, nick );
					if ( currentUser <> nil ) then
						begin
							writeln ('Ingrese su contraseña');
							readln ( password );
							if ( passwordAccepted ( currentUser, password ) ) then
									afterLog ( users, currentUser, conversations )
							else
								begin
									writeln( 'La contraseña no es correcta' );
									beforeLog ( users, conversations );
								end
						end
					else
						begin
							writeln( 'El usuario no existe' );
							beforeLog ( users, conversations )
						end
				end
			else
				begin
					writeln('No existen usuarios aun');
					beforeLog ( users, conversations );
				end;
		end;

	procedure register ( var users: usertree; var conversations: conversationsList );
		var	_nick
			,	_password
					:String [ 8 ]	
			;	currentUser
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
			
			if ( users <> nil ) then
				begin
					currentUser := userExists ( users, _nick );
					if ( currentUser <> nil ) then
						begin
							validate := false;
							writeln('El nombre de usuario ya ha sido seleccionado, por favor, elija otro');
							beforeLog ( users, conversations );
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
							afterLog ( users, newUser, conversations );
						end
					else
						begin
							writeln('Un error ha ocurrido, por favor vuelva a intentarlo mas tarde');
							beforeLog ( users, conversations );
						end;
				end;
		end;

	procedure beforeLog ( var users: userTree; var conversations: conversationsList );
		var option
					:Integer
			;
		begin
			repeat 
				writeln('Presione 1 para crear una cuenta');
				writeln('Presione 2 para iniciar sesion');
				readln ( option );
				case option of
					1: register( users, conversations );
					2: login( users, conversations );
				end;
			until ( option <> 1 ) or ( option <> 2 ); 
		end;
end.
