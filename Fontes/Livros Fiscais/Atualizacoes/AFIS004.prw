/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |22/12/2015| Chamado 13062. Tratativa na cláusula "ORDER BY" para remover a referência numérica.
Alex Wallauer |31/01/2019| Chamado 27890. Aviso para quando os campos F4_DUPLIC e F4_UPRC estiverem diferentes.
Lucas Borges  |02/04/2019| Chamado 28346. Revisão de fontes. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AFIS004
Autor-----------: Alexandre Villar
Data da Criacao-: 03/08/2015
Descrição-------: Rotina para liberação de TES pelas áreas: Fiscal, Pis/Cofins e Estoque - Chamado 9688
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS004()

Local _aCores := {	{ "F4_MSBLQL <> '1' "							, "BR_VERDE"	},;  //TES Liberada
					{ "F4_MSBLQL == '1' .And. F4_I_BLFPE == 'SSS'"	, "BR_AMARELO"	},;  //TES bloqueada para uso
					{ "F4_MSBLQL == '1' .And. F4_I_BLFPE <> 'SSS'"	, "BR_VERMELHO"	} }  //TES bloqueada pelo cadastro

Private cCadastro	:= "Liberação do cadastro de TES"
Private aRotina	:={}
aRotina		:= {	{ "Pesquisar"	, "AxPesqui"		, 0 , 01 } ,;
					{ "Visualizar"	, "AxVisual"		, 0 , 02 } ,;
					{ "Consultar"	, "U_AFIS004C()"	, 0 , 02 } ,;
					{ "Liberar"		, "U_AFIS004L()"	, 0 , 04 } ,;
					{ "Legenda"		, "U_AFIS004S()"	, 0 , 08 }  }

DBSelectArea("SF4")
SF4->( DBSetOrder(1) )
MBrowse( ,,,, "SF4" ,,,,,, _aCores )

Return

/*
===============================================================================================================================
Programa--------: AFIS004S
Autor-----------: Alexandre Villar
Data da Criacao-: 03/08/2015
Descrição-------: Legenda da tela
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS004S()

Local _aCores := {	{ 'BR_VERDE'	, "TES Liberada"		  		},;
					{ 'BR_AMARELO'	, "TES Bloqueada para uso"		},;
					{ 'BR_VERMELHO'	, "TES Bloqueada pelo cadastro"	} }

BrwLegenda( cCadastro , "Legenda" , _aCores )

Return

/*
===============================================================================================================================
Programa----------: AFIS004L
Autor-------------: Alexandre Villar
Data da Criacao---: 03/08/2015
Descrição---------: Rotina para Liberar a TES bloqueada pelo cadastro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIS004L()

Local _aDadLog	:= {}
Local _xValid	:= U_ITACSUSR( 'ZZL_LCADTE' )

//====================================================================================================
// Validacao para verificar se o Usuario tem acesso à rotina de manutenção de TES
//====================================================================================================
If ValType(_xValid) == 'C' .And. !Empty(_xValid) .And. _xValid $ ('FPE')
	
//1) Quando F4_DUPLIC = 'N' .And. SF4->F4_UPRC = 'S'  ===========>  "Para TES que NÂO geram financeiro o campo atualiza preço de compra deveria estar também como "NÃO", deseja de continuar? "
	If SF4->F4_TIPO = 'E' .And. SF4->F4_DUPLIC = 'N' .And. SF4->F4_UPRC = 'S' .And. !MSgYesNo("Para TES que NÂO geram financeiro o campo atualiza preço de compra deveria estar também como NÃO, deseja de continuar ?","AFIS00401")
	   Return .F.
	EndIf

//2) Quando F4_DUPLIC = 'S' .And. SF4->F4_UPRC = 'N'  ===========>  "Para TES que GERAM financeiro o campo atualiza preço de compra deveria estar com preenchido com "SIM", deseja de continuar?"
	If SF4->F4_TIPO = 'E' .And. SF4->F4_DUPLIC = 'S' .And. SF4->F4_UPRC = 'N' .And. !MsgYesNo("Para TES que GERAM financeiro o campo atualiza preço de compra deveria estar com preenchido com SIM, deseja de continuar?","AFIS00402")
	   Return .F.
	EndIf

//TES de saida (F4_TIPO = 'S') realizar a validação somente se F4_UPRC = 'S', caso esteja apresentar a seguinte mensagem: "Para TES de saida o campo atualiza preço deveria estar preenchido como "NAO", deseja continuar?"
	If SF4->F4_TIPO = 'S' .And. M->F4_UPRC = 'S' .And. !MsgYesNo("Para TES de saida o campo atualiza preço deveria estar preenchido como NÃO, deseja de continuar?","AGLT00403")
	   Return .F.
	EndIf

	If _xValid == 'F'
		
		If SubStr( SF4->F4_I_BLFPE , 1 , 1 ) == "S"
			Help(NIL, NIL, "AFIS00404", NIL, "A TES selecionada já está liberada pelo Depto. Fiscal!",1, 0, NIL, NIL, NIL, NIL, NIL, {"Selecione uma uma TES não liberada."})
		Else
			
			If MsgYesNo("Confirma a liberação Fiscal para a TES: "+ SF4->F4_CODIGO +" ?","AFIS00405")
				
				aAdd( _aDadLog , { "F4_I_BLFPE" , SF4->F4_I_BLFPE , 'S' + SubStr( SF4->F4_I_BLFPE , 2 , 2 ) } )
				
				RecLock( 'SF4' , .F. )
				SF4->F4_I_BLFPE := 'S' + SubStr( SF4->F4_I_BLFPE , 2 , 2 )
				SF4->( MSUnLock() )
				
				U_ITGrvLog( _aDadLog , 'SF4' , 1 , SF4->( F4_FILIAL + F4_CODIGO ) , 'A' , RetCodUsr() , Date() , Time() )
				
			EndIf
			
		EndIf
	
	EndIf
	
	If _xValid == 'P'
		
		If SubStr( SF4->F4_I_BLFPE , 2 , 1 ) == "S"
			Help(NIL, NIL, "AFIS00406", NIL, "A TES selecionada já está liberada pelo responsável pelas configurações de PIS/COFINS!",1, 0, NIL, NIL, NIL, NIL, NIL, {"Selecione uma uma TES não liberada."})
		Else
			If MsgYesNo("Confirma a liberação de PIS/COFINS para a TES: "+ SF4->F4_CODIGO +" ?","AFIS00407")
				
				aAdd( _aDadLog , { "F4_I_BLFPE" , SF4->F4_I_BLFPE , SubStr( SF4->F4_I_BLFPE , 1 , 1 ) +'S'+ SubStr( SF4->F4_I_BLFPE , 3 , 1 ) } )
				
				RecLock( 'SF4' , .F. )
				SF4->F4_I_BLFPE := SubStr( SF4->F4_I_BLFPE , 1 , 1 ) +'S'+ SubStr( SF4->F4_I_BLFPE , 3 , 1 )
				SF4->( MSUnLock() )
				
				U_ITGrvLog( _aDadLog , 'SF4' , 1 , SF4->( F4_FILIAL + F4_CODIGO ) , 'A' , RetCodUsr() , Date() , Time() )
				
			EndIf
			
		EndIf
	
	EndIf
	
	If _xValid == 'E'
		
		If SubStr( SF4->F4_I_BLFPE , 3 , 1 ) == "S"
			Help(NIL, NIL, "AFIS00408", NIL, "A TES selecionada já está liberada pelo responsável pelas configurações de Estoque!",1, 0, NIL, NIL, NIL, NIL, NIL, {"Selecione uma uma TES não liberada."})
		Else
			
			If MsgYesNo("Confirma a liberação de Estoque para a TES: "+ SF4->F4_CODIGO +" ?","AFIS00409")
				
				aAdd( _aDadLog , { "F4_I_BLFPE" , SF4->F4_I_BLFPE , SubStr( SF4->F4_I_BLFPE , 1 , 2 ) +'S' } )
				
				RecLock( 'SF4' , .F. )
				SF4->F4_I_BLFPE := SubStr( SF4->F4_I_BLFPE , 1 , 2 ) +'S'
				SF4->( MSUnLock() )
				
				U_ITGrvLog( _aDadLog , 'SF4' , 1 , SF4->( F4_FILIAL + F4_CODIGO ) , 'A' , RetCodUsr() , Date() , Time() )
				
			EndIf
			
		EndIf
	
	EndIf
	
Else
	Help(NIL, NIL, "AFIS00410", NIL, "O usuário atual não tem permissão para liberação do cadastro de TES na Gestão de Usuários da Italac.",1, 0, NIL, NIL, NIL, NIL, NIL, {"Solicite o Acesso ao Depto responsavel."})	
EndIf

Return

/*
===============================================================================================================================
Programa--------: AFIS004C
Autor-----------: Alexandre Villar
Data da Criacao-: 03/08/2015
Descrição-------: Consulta histórico de alterações da TES
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AFIS004C()

Local _aLogReg	:= {}
Local _cAlias	:= GetNextAlias()
Local _cTitLog	:= 'Consulta histórico de alterações da TES: '+ SF4->F4_CODIGO
Local _aHeader	:= { 'Data' , 'Hora' , 'Opção' , 'Campo' , 'Conteúdo Orig.' , 'Conteúdo Alt.' , 'Usuário' }
Local _cTxtAux	:= ''
Local _aAllusers:= FWSFAllUsers() //não é permitirdo chamar a função que retorna apenas o nome por estar dentro do Loop
Local _nPos		:= 0

BeginSql alias _cAlias
	SELECT Z07_DATA, Z07_HORA, Z07_OPCAO, Z07_CAMPO, Z07_CONORG, Z07_CONALT, Z07_CODUSU
	FROM %Table:Z07%
	WHERE D_E_L_E_T_ = ' '
	AND Z07_FILIAL = %xFilial:Z07%
	AND Z07_ALIAS = 'SF4'
	AND Z07_CHAVE = %exp:SF4->(F4_FILIAL+F4_CODIGO)%
EndSql
	
While (_cAlias)->( !Eof() )
	_nPos:= aScan(_aAllusers,{|x| x[2] == (_cAlias)->Z07_CODUSU})
	aAdd( _aLogReg , {	DToC( SToD( (_cAlias)->Z07_DATA ) )								,;
						AllTrim( (_cAlias)->Z07_HORA )									,;
						IIf( (_cAlias)->Z07_OPCAO == 'I' , 'Inclusão' , 'Alteração' )	,;
						AllTrim( (_cAlias)->Z07_CAMPO )									,;
						AllTrim( (_cAlias)->Z07_CONORG )								,;
						AllTrim( (_cAlias)->Z07_CONALT )								,;
						IIf(_nPos>0,_aAllusers[_nPos][4],(_cAlias)->Z07_CODUSU) })
	
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If Empty( _aLogReg )
	_aLogReg := { { '' , '' , '' , '' , '' , '' , '' } }
EndIf

_cTxtAux := 'Status para uso: '		+ IIf( SF4->F4_MSBLQL == '1' , 'Bloqueado' , 'Liberado' )						+ Space(20)
_cTxtAux += 'Status Fiscal: '		+ IIf( SubStr( SF4->F4_I_BLFPE , 1 , 1 ) == 'S' , 'Liberado' , 'Bloqueado' )	+ Space(20)
_cTxtAux += 'Status PIS/COFINS: '	+ IIf( SubStr( SF4->F4_I_BLFPE , 2 , 1 ) == 'S' , 'Liberado' , 'Bloqueado' )	+ Space(20)
_cTxtAux += 'Status Estoque: '		+ IIf( SubStr( SF4->F4_I_BLFPE , 3 , 1 ) == 'S' , 'Liberado' , 'Bloqueado' )

U_ITListBox( _cTitLog , _aHeader , _aLogReg , .T. , 1 , _cTxtAux )

Return
