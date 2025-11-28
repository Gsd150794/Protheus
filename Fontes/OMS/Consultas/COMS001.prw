/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 12/04/2019 | Leitura de logs de transferências de pedido de vendas - Chamado 28589 
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 08/08/2019 | Ajustes para funcionar com as atulizaçoes recentes  - Chamado: 30213
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 02/08/2021 | Correção na exibição log para transferência de Pedidos de Vendas. Chamado 37304.
-------------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 06/08/2021 | Tratamento para o novo campo Z07_ORIGEM. Chamado 36432 
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

#Define TITULO "Log de Alterações - Pedido de Venda"

/*
===============================================================================================================================
Programa----------: COMS001
Autor-------------: Alexandre Villar
Data da Criacao---: 02/10/2014
===============================================================================================================================
Descrição---------: Rotina de consulta dos Logs de Alteração dos Pedidos de Venda
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function COMS001( _cAlias , _cChave )

Local aArea	        := FWGetArea()
Local oDlg			:= Nil
Local oLbxCAB		:= Nil
Local oLbxHIS		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bSelDados		:= Nil
Local bMontaHIS		:= NIL

Local oBar			:= Nil
Local aBtn 	    	:= Array(02)
Local oBold			:= Nil
Local oScrPanel		:= Nil

Local aCabLbxCAB	:= {	"Tipo"					,; //01
							"Ação"					,; //02
							"Data"					,; //03
							"Hora"					,; //04
							"Cód. Usuário"			,; //05
							"Nome"					,; //06
							"Filial"				,; //07
							"Origem (Menu)"		    } //07

Local aCabLbxHIS	:= {	"Item"					,; //01
							"Campo"					,; //02
	                        "Descrição"				,; //03
	                        "Valor Original"		,; //04
	                        "Valor Alterado"		 } //05

//Private	nDvPosAnt	:= 0
Private	cCadastro	:= ''

Default _cAlias		:= "SC5" //jjs
Default _cChave     :=  SC5->C5_FILIAL+SC5->C5_NUM //jjs

bSelDados:= {|| FWMsgRun(,{|lEnd| COMS001HIS( @oLbxCAB , _cAlias , _cChave ) },"Aguarde...","Carregando histórico..." ) }
bMontaHIS:= {|| IIf( !Empty(oLbxCAB:aArray) , COMS001ITH( @oLbxHIS , _cAlias , oLbxCAB:aArray[oLbxCAB:nAt] ) , ) }


If Empty( _cChave )
   U_ITMsg( 'Não foi informada uma chave válida para a consulta do Pedido!',  'Atenção!' ,  , 1 )
   FWRestArea(aArea)
   Return
EndIf

cCadastro := "Consulta Histórico ["+ _cChave +"] - "+ TITULO            

//================================================================================
// Posiciona no Pedido de Venda
//================================================================================
DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If !SC5->( DBSeek( _cChave ) )
   U_ITMsg( 'O pedido referente à chave ['+ _cChave +'] não foi encontrado!' , 'Atenção!' ,, 1 )
   FWRestArea(aArea)
   Return
EndIf

aAdd( aObjects, { 100, 025, .T. , .F. , .T. } )
aAdd( aObjects, { 100, 100, .T. , .F. } )
aAdd( aObjects, { 100, 050, .T. , .T. } )

aInfo   := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 2 }
aPosObj := MsObjSize( aInfo, aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Pixel//Of oMainWnd 

  	aPosObj[01][01] := 15
  	aPosObj[01][02] := 3
	aPosObj[02][01] := 45
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	_n1Linha:=(aPosObj[01][01] + 8)	
	_n2Linha:=_n1Linha+8	
	//================================================================================
	// Parte 01 - Cliente.
	//================================================================================

    oScrPanel:=oDlg
	@ aPosObj[01][01],aPosObj[01][02] To aPosObj[02][01]-2,aPosObj[02][04] LABEL "Dados do Pedido:" COLOR CLR_HBLUE OF oScrPanel PIXEL

	@ _n1Linha , 010 Say "Filial:"					SIZE 025,07 OF oScrPanel PIXEL
	@ _n2Linha , 010 Say SC5->C5_FILIAL			 	SIZE 060,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE

	@ _n1Linha , 040 Say "Número:"					SIZE 035,07 OF oScrPanel PIXEL
	@ _n2Linha , 040 Say SC5->C5_NUM				SIZE 035,09	OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	_cNomCli := SC5->C5_CLIENTE +'/'+ SC5->C5_LOJACLI +': '+ AllTrim( Posicione('SA1',1,xFilial('SA1')+SC5->( C5_CLIENTE + C5_LOJACLI ),'A1_NOME') )
	
	@ _n1Linha , 075 Say "Cliente/Loja:"			SIZE 165,07 OF oScrPanel PIXEL
	@ _n2Linha , 075 Say _cNomCli					SIZE 165,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	@ _n1Linha , 320 Say "Emissão:"			  		SIZE 040,07 OF oScrPanel PIXEL
	@ _n2Linha , 320 Say DToC( SC5->C5_EMISSAO )	SIZE 040,09 OF oScrPanel PIXEL FONT oBold COLOR CLR_BLUE
	
	//================================================================================
	// Parte 02 - Titulos Processados.
	//================================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Ações realizadas:" COLOR CLR_HBLUE OF oDlg PIXEL
	//================================================================================
	// ListBox com Cabecalho do Historico do Pedido
	//================================================================================
  	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxCAB Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
	oLbxCAB:AHeaders	:= aClone(aCabLbxCAB)
	oLbxCAB:bChange		:= { || Eval(bMontaHIS) }  
	                 
	Eval(bSelDados)  
	//================================================================================
	// Parte 03 - Historico das Alterações
	//================================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03]-10,aPosObj[03][04] LABEL "Histórico das alterações:" COLOR CLR_HBLUE OF oDlg PIXEL
      
	//================================================================================
	// ListBox com Itens do Historico do Titulo
	//================================================================================
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxHIS Fields	;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 20 Of oDlg Pixel
	
	oLbxHIS:AHeaders := aClone(aCabLbxHIS)
	Eval(bMontaHIS)

	//================================================================================
	// Monta os Botoes da Barra Superior
	//================================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg
	
	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxCAB:AHeaders,oLbxCAB:aArray}})	TOOLTIP "Exportar para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 												TOOLTIP "Sair da Tela..."
	aBtn[02]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED ON INIT IIf( Empty(oLbxCAB:aArray) , ( U_ITMsg( "O Pedido ["+ SC5->C5_FILIAL +"/"+ SC5->C5_NUM +"] não possui histórico de alterações." , 'Atenção!' ,, 1 ) , oDlg:End() ) , )

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: COMS001HIS
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
===============================================================================================================================
Descrição---------: Monta a estrutura de dados da consulta detalhada do histórico
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function COMS001HIS( oLbxAux , _cAlias , _cChave )

Local aLbxAux	:= {}

Local _cQuery 	:= ""
Local _cAliAux	:= GetNextAlias()

Local nTotReg   := 0

_cQuery := " SELECT DISTINCT "
_cQuery += "     Z07.Z07_OPCAO	, "
_cQuery += "     Z07.Z07_CODUSU	, "
_cQuery += "     Z07.Z07_DATA	, "
_cQuery += "     Z07.Z07_HORA	, "
_cQuery += "     Z07.Z07_CHAVE  , "
_cQuery += "     Z07.Z07_INUM   , "
_cQuery += "     Z07.Z07_IFILIA , "
_cQuery += "     Z07.Z07_ALIAS  , "
_cQuery += "     Z07.Z07_IITEM  , "
_cQuery += "     Z07.Z07_FILIAM , "
_cQuery += "     Z07.Z07_ORIGEM   "
_cQuery += " FROM "+ RetSqlName('Z07') +" Z07 "
_cQuery += " WHERE "
_cQuery += "     Z07.D_E_L_E_T_	= ' ' "
_cQuery += " AND Z07.Z07_INUM = '" + SC5->C5_NUM + "'
_cQuery += " ORDER BY Z07.Z07_DATA , Z07.Z07_HORA, Z07_ALIAS "
_cQuery	:= ChangeQuery(_cQuery)

If Select(_cAliAux) > 0
	(_cAliAux)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAliAux , .F. , .T. )

(_cAliAux)->( DBGoTop() )
COUNT TO nTotReg
(_cAliAux)->( DBGoTop() )

ProcRegua( nTotReg )

While (_cAliAux)->( !Eof() )

	_amots   := COMS001S( (_cAliAux)->Z07_OPCAO, (_cAliAux)->Z07_IITEM )
	_cdesc := _amots[1]
	_cmotivo := _amots[2] 	
	
   aAdd( aLbxAux ,	{	IIf((_cAliAux)->Z07_ALIAS=='SC5',"Cabeçalho","Item " + SubStr((_cAliAux)->Z07_CHAVE,9,2)),;
   						_cdesc													,; //02
						DToC( SToD( (_cAliAux)->Z07_DATA ) )						,; //03
						(_cAliAux)->Z07_HORA										,; //04
						(_cAliAux)->Z07_CODUSU										,; //05
						U_COMS001U((_cAliAux)->Z07_CODUSU)							,; //06
						(_cAliAux)->Z07_CHAVE										,; //07
						IIf(Empty((_cAliAux)->Z07_FILIAM),(_cAliAux)->Z07_IFILIA,(_cAliAux)->Z07_FILIAM)  ,; //08
						(_cAliAux)->Z07_INUM                                        ,; //09
						(_cAliAux)->Z07_ORIGEM                                      ,; //10
						_cmotivo													}) //11
						

   (_cAliAux)->( DBSkip() )

EndDo

(_cAliAux)->( DBCloseArea() )

If Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"

	oLbxAux:SetArray(aLbxAux)
	
	oLbxAux:bLine := {|| {	aLbxAux[oLbxAux:nAt][01]	,; // 01
							aLbxAux[oLbxAux:nAt][02]	,; // 02
							aLbxAux[oLbxAux:nAt][03]	,; // 03
							aLbxAux[oLbxAux:nAt][04]	,; // 04
							aLbxAux[oLbxAux:nAt][05]	,; // 05
							aLbxAux[oLbxAux:nAt][06]	,; // 06
							aLbxAux[oLbxAux:nAt][08]    ,; // 07
							aLbxAux[oLbxAux:nAt][10]    }} // 08
	
	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: COMS001ITH
Autor-------------: Alexandre Villar
Data da Criacao---: 23/04/2014
===============================================================================================================================
Descrição---------: Recupera os dados dos itens do histórico
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function COMS001ITH( oLbxAux , _cAlias , _aChave )

Local _cQuery	:= ""
Local _cAliAux	:= GetNextAlias()
Local aLbxAux	:= {}

_cQuery	:= " SELECT DISTINCT "
_cQuery += "     Z07.Z07_CHAVE	, "
_cQuery	+= "     Z07.Z07_CAMPO	, "
_cQuery	+= "     Z07.Z07_CONORG	, "
_cQuery	+= "     Z07.Z07_CONALT	  "
_cQuery	+= " FROM "+ RetSqlName('Z07') +" Z07 "
_cQuery	+= " WHERE "
_cQuery	+= "     Z07.D_E_L_E_T_	= ' ' "
_cQuery	+= " AND ( Z07.Z07_ALIAS = '"+ _cAlias +"' "

If _cAlias == 'SC5'
_cQuery += " OR Z07.Z07_ALIAS = 'SC6' ) "
Else
_cQuery += " ) "
EndIf

_cQuery	+= " AND Z07.Z07_CHAVE	= '"+ _aChave[07] +"' "
_cQuery	+= " AND Z07.Z07_CODUSU	= '"+ _aChave[05] +"' "
_cQuery += " AND Z07.Z07_IFILIA = '" + _aChave[08] + "'
_cQuery += " AND Z07.Z07_INUM = '" + _aChave[09] + "'
_cQuery	+= " AND Z07.Z07_DATA	= '"+ DToS(CtoD(_aChave[03])) +"' "
_cQuery	+= " AND Z07.Z07_HORA	= '"+ _aChave[04] +"' "
_cQuery	+= " ORDER BY Z07.Z07_CHAVE "
_cQuery	:= ChangeQuery(_cQuery)

If Select(_cAliAux) > 0
	(_cAliAux)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAliAux , .F. , .T. )

DBSelectArea(_cAliAux)
(_cAliAux)->( DBGoTop() )

While !(_cAliAux)->( Eof() )
		
		aAdd( aLbxAux , {	SubStr(_aChave[07],9,2)												,; //01
							(_cAliAux)->Z07_CAMPO												,; //02
                         	AllTrim( Posicione('SX3',2,(_cAliAux)->Z07_CAMPO,'X3_DESCRIC') )	,; //03
  							Rtrim( (_cAliAux)->Z07_CONORG )										,; //04
							Rtrim( (_cAliAux)->Z07_CONALT )										}) //05

		(_cAliAux)->(DBSkip())
EndDo

(_cAliAux)->(DBCloseArea())

If	Len(aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(aLbxAux)
	oLbxAux:bLine:={||{	aLbxAux[oLbxAux:nAt][01] ,; //01
						aLbxAux[oLbxAux:nAt][02] ,; //02
						aLbxAux[oLbxAux:nAt][03] ,; //03
						aLbxAux[oLbxAux:nAt][04] ,; //04
						aLbxAux[oLbxAux:nAt][05] }} //05

	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: COMS001U
Autor-------------: Josué Danich
Data da Criacao---: 30/11/2018
===============================================================================================================================
Descrição---------: Retorna nome de usuário fora do Loop
===============================================================================================================================
Parametros--------: _ncod - Código do usuário
===============================================================================================================================
Retorno-----------: _csname - Nome do usuário
===============================================================================================================================
*/

User Function COMS001U(_ncod)

Local _csname := Space(40)

_csname := Capital( AllTrim( UsrFullName( _ncod ) ) )	
	
Return _csname


/*
===============================================================================================================================
Programa----------: COMS001S
Autor-------------: Josué Danich
Data da Criacao---: 30/11/2018
===============================================================================================================================
Descrição---------: Retorna descrição do campo de operação da Z07
===============================================================================================================================
Parametros--------: _ccodigo - codigo gravado
					_citem - codigo de corte gravado
===============================================================================================================================
Retorno-----------: _aretorno - array com descrição da operação e motivo do corte 
===============================================================================================================================
*/
Static Function COMS001S(_ccodigo, _citem)

Local _cdesc := ""
Local _cmotivo := ""
Local _aretorno := {"",""}

If _ccodigo == "I"

	_cdesc := "Inclusão"

ElseIf _ccodigo == "B"

	_cdesc := "Bloqueio Log"
	
ElseIf _ccodigo == "E"

	_cdesc := "Exclusão"
	If !Empty(_citem)
	
		_cQuery := " SELECT "
		_cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
		_cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
		_cQuery += " WHERE "
		_cQuery += "     D_E_L_E_T_ = ' ' "
		_cQuery += " AND X5_TABELA  = 'Z1' AND X5_CHAVE = '" + _citem + "'"
		_cQuery += " ORDER BY X5_CHAVE "

		If Select("TMPCF") > 0 
			("TMPCF")->( DBCloseArea() )
		EndIf

		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , 'TMPCF' , .F. , .T. )

		_cDesc := "Corte"

		If TMPCF->( !Eof() )
		
			_cmotivo := AllTrim(TMPCF->DESCRI)
		
		EndIf	
	
		("TMPCF")->( DBCloseArea() )
	
	EndIf
	
ElseIf _ccodigo == "A"

	_cdesc := "Alteração"	
	
	If !Empty(_citem)
	
		_cdesc := "Corte"
		
		_cQuery := " SELECT "
		_cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
		_cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
		_cQuery += " WHERE "
		_cQuery += "     D_E_L_E_T_ = ' ' "
		_cQuery += " AND X5_TABELA  = 'Z1' AND X5_CHAVE = '" + _citem + "'"
		_cQuery += " ORDER BY X5_CHAVE "

		If Select("TMPCF") > 0 
			("TMPCF")->( DBCloseArea() )
		EndIf

		DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , 'TMPCF' , .F. , .T. )

		If TMPCF->( !Eof() )
		
			_cmotivo := AllTrim(TMPCF->DESCRI)
		
		EndIf	
	
		("TMPCF")->( DBCloseArea() )
		
	EndIf

ElseIf _ccodigo == "T"

	_cdesc := "Transferência"	

EndIf

_aretorno[1] := _cdesc
_aretorno[2] := _cmotivo
	
Return _aretorno
