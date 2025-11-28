/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |04/12/2015| Chamado 13081. Revisão e normatização de fonte
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.ch"

/*
===============================================================================================================================
Programa----------: AEST029
Autor-------------: Erich Buttner
Data da Criacao---: 06/08/2013
Descrição---------: Cadastro de Tipos de Custo  - CHAMADO 3953  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST029()

Private cArqInd 		:= CriaTrab(,.F.)		//Nome do arq. temporario
Private cCadastro 	:= "Tipos de Custo"
Private aRotina   	:= {}
Private aTitulos   	:= {}
Private _cAlias 		:= "ZL4"


aAdd(aRotina,{"Pesquisar" 	,"AxPesqui"  ,0,1 })
aAdd(aRotina,{"Visualizar"	,"AxVisual"  ,0,2 })
aAdd(aRotina,{"Incluir"		,"AxInclui"  ,0,3 })
aAdd(aRotina,{"Alterar"		,"AxAltera"  ,0,4 })
aAdd(aRotina,{"Excluir"		,"U_AEST029EX"  ,0,5 })

DBSelectArea("ZL4")
DBSetOrder(1) 

mBrowse( 6, 1,22,75,"ZL4")

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST029EX
Autor-------------: Erich Buttner
Data da Criacao---: 06/08/2013
Descrição---------: Cadastro de Tipos de Custo  - CHAMADO 3953  
Parametros--------: 	_cAlias -> tabela aberta
						_nReg -> registro selecionado
						_nOpc -> opção de deleção
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST029EX(_cAlias,_nReg,_nOpc)

DBSelectArea("ZL5")
DBSetOrder(2)

If DBSeek(xFilial("ZL5")+ZL4->ZL4_COD)

	Alert( "Tipo Custo Já Amarrado a um Grupo de custo!!")
	Return .F.

Else

	AxDeleta(_cAlias,_nReg,_nOpc) 
	Return .T.

EndIf

Return


/*
===============================================================================================================================
Programa----------: AEST029G
Autor-------------: Josué Danich
Data da Criacao---: 04/12/2015
Descrição---------: Rotina para retornar próximo código de evento para campo ZL4->COD
Parametros--------: 
Retorno-----------: _ccod - próximo valor para ZL4->COD
===============================================================================================================================
*/
User Function AEST029G()

Local _ccod 	:= "000001"
Local _cQuery := ""
Local _aarea	:= FWGetArea()

_cQuery	:= " SELECT " 
_cQuery  	+= 	" MAX(ZL4_COD) AS CODI" 
_cQuery  	+= 	" FROM " + RetSqlName("ZL4") + " ZL4 "
_cQuery  	+= 	" WHERE ZL4_FILIAL = '" + xFilial("ZL4") + "'"
_cQuery 	+= 	" AND   ZL4.D_E_L_E_T_ 	= ' '	"

TcQuery _cQuery New Alias ZL4T
	
DBSelectArea("ZL4T")

If .not. ZL4T->( Eof() )

	_ccod := StrZero( ( Val( ZL4T->CODI) + 1 ),6 )

EndIf

If Select("ZL4T") > 0 

	ZL4T->( DBCloseArea() )

EndIf

FWRestArea(_aarea)

Return _ccod
