unit users;

interface
	
	const USERSFILE_ = 'data/users'
		;

	type
			userTree = ^tree
		;	userFields = 
				record
						nick : String [ 8 ]
					;	password : String [ 8 ]
				end
		;	tree = 
				record 
						nick : String [ 8 ]
					;	password : String [ 8 ]
					; low : userTree
					;	big	: userTree
				end
		;	usersFile = file of userFields
		;


	function createUserNode   ( var newNode: userTree; userData: userFields ): boolean;
	procedure insertUserNode  ( var _tree, _userNode: userTree );
	procedure loadUsers       ( var users: userTree );
	function userExists       ( users: userTree; nick: String ): userTree;
	procedure saveUser        ( users: userTree );
	procedure showUsers       ( users: userTree );
	function passwordAccepted ( user: userTree; password: String ): Boolean;
	procedure deleteUser      ( var currentUser: userTree );

implementation
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
		if ( error ) then
			begin
				close(usersStored);
				rewrite(usersStored);
			end;
		createTreeFromFile ( users, usersStored );
		close ( usersStored );
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
		close ( usersStore );
		rewrite ( usersStore );{HABÍA UN IF}
		rewrite ( usersStore );
		getUsersNode ( users, usersStore );
	end;

procedure showUsers ( users: userTree );
	begin
		if ( users <> nil ) then
			begin
				showUsers ( users^.low );
				writeln ( users^.nick );
				showUsers ( users^.big );
			end;
	end;

function passwordAccepted ( user: userTree; password: String ): Boolean;
	begin	
		passwordAccepted := true;
		if ( user^.password <> password ) then
			passwordAccepted := false;
	end;

	procedure shiftTree ( var currentUser: userTree; direction: String );
	begin
		if ( direction = 'low' ) then
			begin
				if ( currentUser^.low^.low = nil ) then
					begin
						currentUser^.nick := currentUser^.low^.nick;
						currentUser^.password := currentUser^.low^.nick;
						currentUser^.low := nil;
					end
				else
					begin
						currentUser^.nick := currentUser^.low^.nick;
						currentUser^.password := currentUser^.low^.nick;
						shiftTree ( currentUser^.low, direction );
					end;
			end
		else
			begin
				if ( currentUser^.big^.big = nil ) then
					begin
						currentUser^.nick := currentUser^.big^.nick;
						currentUser^.password := currentUser^.big^.nick;
						currentUser^.big := nil;
					end
				else
					begin
						currentUser^.nick := currentUser^.big^.nick;
						currentUser^.password := currentUser^.big^.nick;
						shiftTree ( currentUser^.big, direction );
					end;
			end;
	end;

procedure deleteUser ( var currentUser: userTree );
	begin
		if ( currentUser <> nil) then
			if ( currentUser^.low <> nil ) or ( currentUser^.big <> nil ) then
				if ( currentUser^.low <> nil ) then
					shiftTree ( currentUser, 'low' )
				else
					shiftTree ( currentUser, 'big' )
			else
				currentUser := nil;
	end;

end.
