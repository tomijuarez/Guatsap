program Arboles;

type 
		recordFile = record
				valor1 : Integer
			;	valor2 : Integer
			;
		end
	;	arch = file of recordFile
	;	arbolito = ^puntArbol
	;	puntArbol = record
				valor : Integer
			;	valor2 : Integer
			;	mayor : arbolito
			; menor : arbolito
		end
	;	listaSimple = ^lista
	;	lista = record 
				valor : Integer
			;	sgte : listaSimple
		end
	;
		
procedure abrirArchivo ( var archivo: arch; nombre: String; var error: Boolean );
	begin
		error := false;
		assign ( archivo, nombre );
		{$I-}
			reset ( archivo );
		{$I+}	
		if ( ioResult <> 0 ) then
			error := true;
	end;

procedure cargarArchivo ( var archivo: arch );
	var aux
				:recordFile
		;

	begin
		rewrite ( archivo );
		writeln ( 'Ingrese un nuevo nodo para el registro' );
		readln ( aux.valor1 );
		while ( aux.valor1 <> -1 ) do
			begin
				readln ( aux.valor2 );
				write ( archivo, aux );
				writeln ( 'Ingrese un nuevo nodo para el registro' );
				readln ( aux.valor1 );
			end;
	end;

procedure cargarArbol ( var arbol: arbolito; valor1, valor2: Integer );
	begin
		if ( arbol = nil ) then
			begin
				new ( arbol );
				arbol^.valor := valor1;
				arbol^.valor2 := valor2;
				arbol^.menor := nil;
				arbol^.mayor := nil;
			end
		else
			if ( arbol^.valor <= valor1 ) then
				cargarArbol ( arbol^.mayor, valor1, valor2 )
			else
				cargarArbol ( arbol^.menor, valor1, valor2 );

	end;

procedure cargarArbolConArchivo ( var arbol: arbolito; var archivo: arch );
	var i
		,	aux
				:recordFile
		;	
	begin
		while not eof ( archivo ) do
			begin
				read ( archivo, aux );

				cargarArbol ( arbol, aux.valor1, aux.valor2 );
			end;
	end;

procedure imprimirArbolAscendente ( arbol: arbolito );
	begin
		if ( arbol <> nil ) then
			begin
				imprimirArbolAscendente ( arbol^.menor );
				writeln ( arbol^.valor, ' -> ', arbol^.valor2 );
				imprimirArbolAscendente ( arbol^.mayor );
			end;
	end;

procedure imprimirArbolDescendente ( arbol: arbolito );
	begin
		if ( arbol <> nil ) then
			begin
				imprimirArbolDescendente ( arbol^.mayor );
				writeln ( arbol^.valor, ' - ' );
				imprimirArbolDescendente ( arbol^.menor );
			end;
	end;

procedure imprimirArbolPreOrden ( arbol: arbolito );
	begin
		if ( arbol <> nil ) then
			begin	
				imprimirArbolPreOrden ( arbol^.menor );
				imprimirArbolPreOrden ( arbol^.mayor );
				write ( arbol^.valor, ' - ' );
			end;
	end;

procedure correArbol ( var nodo: arbolito; direccion: String );
	begin
		if ( direccion = 'menor' ) then
			begin
				if ( nodo^.menor^.menor = nil ) then
					begin
						nodo^.valor := nodo^.menor^.valor;
						nodo^.menor := nil;
					end
				else
					begin
						nodo^.valor := nodo^.menor^.valor;
						correArbol ( nodo^.menor, direccion );
					end;
			end
		else
			begin
				if ( nodo^.mayor^.mayor = nil ) then
					begin
						nodo^.valor := nodo^.mayor^.valor;
						nodo^.mayor := nil;
					end
				else
					begin
						nodo^.valor := nodo^.mayor^.valor;
						correArbol ( nodo^.mayor, direccion );
					end;
			end;
	end;

function buscaNodo ( var arbol: arbolito; valor: Integer ): arbolito;
	begin
		if ( arbol <> nil ) then
			begin
				if ( arbol^.valor < valor ) then
					buscanodo := buscaNodo ( arbol^.mayor, valor );
				if ( arbol^.valor > valor ) then
					buscanodo := buscaNodo ( arbol^.menor, valor );
				if ( arbol^.valor = valor ) then
					buscaNodo := arbol;
			end
		else
			buscaNodo := nil;
	end;

procedure eliminarNodo ( var arbol: arbolito; valor: Integer );
	var nodo: arbolito;
	begin
		nodo := buscaNodo ( arbol, valor );		
		if ( nodo <> nil ) then
			if ( nodo^.menor <> nil ) or ( nodo^.mayor <> nil ) then
				if ( nodo^.menor <> nil ) then
					correArbol ( nodo, 'menor' )
				else
					correArbol ( nodo, 'mayor' )
			else
				nodo := nil;
	end;

function alturaArbol ( arbol: arbolito; contador: Integer ): Integer;
	begin
		if ( arbol <> nil ) then 
			begin
				if ( arbol^.menor <> nil ) then
					alturaArbol := alturaArbol ( arbol^.menor, ( contador + 1 ) );	
				if ( arbol^.mayor <> nil ) then
					alturaArbol := alturaArbol ( arbol^.mayor, ( contador + 1 ) );	
			end
		else
			alturaArbol := contador;
	end;

function contarDescendientes ( nodo: arbolito ): Integer;
	var auxiliar
				:Integer
		;
	begin
		auxiliar := 0;
		if ( nodo <> nil ) then
			begin
				auxiliar := 1;
				auxiliar := contarDescendientes ( nodo^.menor ) + auxiliar;
				auxiliar := contarDescendientes ( nodo^.mayor ) + auxiliar;	
			end;

		contarDescendientes := auxiliar;
	end;


{*-Criot -gl*}

function mayorNodo ( arbol: arbolito ): arbolito;
	var
			mayor
		,	mayorParcial
				:arbolito
		;

	begin
			mayor := arbol;
			if ( arbol <> nil ) then
				begin
					mayor := mayorNodo ( arbol^.mayor );

					if ( arbol^.menor <> nil ) then
						begin 
							mayorParcial := mayorNodo ( arbol^.menor );
							if ( mayorParcial^.valor2 > mayor^.valor2 ) then
								mayor := mayorParcial;
						end;

					if ( arbol^.valor2 > mayor^.valor2 ) then
						mayor := arbol;
				end;

	    mayorNodo := mayor;
	end;

{function mayorNodo ( arbol: arbolito ): arbolito;
	var
			mayor
		,	mayorParcial
				:arbolito
		;

	begin
			mayor := arbol;
			if ( arbol <> nil ) and ( ( arbol^.menor <> nil ) or ( arbol^.mayor <> nil ) ) then
				begin

					if ( arbol^.mayor <> nil ) then
						mayor := mayorNodo ( arbol^.mayor );

					if ( arbol^.menor <> nil ) then
						begin 
							mayorParcial := mayorNodo ( arbol^.menor );
							if ( mayorParcial^.valor2 > mayor^.valor2 ) then
								mayor := mayorParcial;
						end;

					if ( arbol^.valor2 > mayor^.valor2 ) then
						mayor := arbol;
				end;

	    mayorNodo := mayor;
	end;}

procedure imprimirLista ( lista: listaSimple );
	begin
		while ( lista <> nil ) do
			begin
				writeln( lista^.valor );
				lista := lista^.sgte;
			end;
	end;

var 
		arbol
	,	nodo
			:arbolito
	;	listas 
			:listaSimple
	;	archivo
			:arch
	;	nombreArchivo
			:String
	;	error
			:Boolean
	;	valor
			:Integer
	;	aux
			:recordFile
	;

begin
	readln ( nombreArchivo );
	abrirArchivo ( archivo, nombreArchivo, error );
	
	while not eof ( archivo ) do
		begin
			read ( archivo, aux );
			writeln ( aux.valor1,' -> ', aux.valor2 );
		end;

	writeln('_____________________');
	reset ( archivo );
	if not error then
		cargarArbolConArchivo ( arbol, archivo );
	imprimirArbolAscendente( arbol );
	writeln('_____________________');
	{writeln( contarDescendientes ( arbol ) - 1 );}
	nodo := mayorNodo ( arbol );
	writeln( nodo^.valor2 );
end.