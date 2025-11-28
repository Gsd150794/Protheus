/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Xavier        |20/04/2015| Chamado 9869. retirada da tela personalizada de escolha da filial, causando não conformidade  	
Josué Danich  |04/12/2015| Chamado 13081. Revisão e normatização de fonte
Josué Danich  |10/06/2019| Chamado 29593. Revisão para loboguara
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.ch"

/*
===============================================================================================================================
Programa----------: AEST030
Autor-------------: Erich Buttner
Data da Criacao---: 06/08/2013
Descrição---------: Cadastro de Grupo de Tipos de Custo  - CHAMADO 3953  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST030()


Local _ncont := 0

Private 	cCadastro 	:= "Grupos de Custo Gerencial"
Private 	aRotina   	:= {}
Private 	aTitulos  	:= {}
Private 	cArquivo 	:= ""
Private 	aCores    	:= {}
Private 	aLegenda 	:= {{"BR_VERMELHO","Bloqueado"}, {"BR_VERDE", "Ativo"}} 
Public 	aNmRet 	:= {}
Public 	cFlRet 	:= ""
Public 	aFlRet 	:= {}
Public 	cFlRet1	:= ""

aAdd(aRotina,{"Pesquisar" 	,"AxPesqui"   	,0,1 })
aAdd(aRotina,{"Visualizar"	,"AxVisual"    	,0,2 })
aAdd(aRotina,{"Incluir"		,"AxInclui"		,0,3 })
aAdd(aRotina,{"Alterar"		,"AxAltera"    	,0,4 })
aAdd(aRotina,{"Excluir"		,"AxDeleta"    	,0,5 })
aAdd(aRotina,{"Legenda"		,"BrwLegenda('Status dos grupos','Legenda',aLegenda)"  		,0,6 })

aAdd(aCores,{"ZL5_MSBLQL == '2'" ,"BR_VERDE" })   
aAdd(aCores,{"ZL5_MSBLQL <> '2'" ,"BR_VERMELHO" })    

DBSelectArea("ZL5")
DBSetOrder(2)

_aCpos:={"ZL5_TPCUST","ZL5_DTPCUS","ZL5_CODGRP","ZL5_DESGRP"}
_aCampos:={}

_astruct := ZL5->(Dbstruct())

For _nCont:=1 to Len(_aCpos)

	_np := aScan(_astruct,{|pos| AllTrim(pos[1]) == AllTrim(_acpos[_ncont])})

	If _np > 0 

		aAdd(aTitulos,{Getsx3cache(_astruct[_np][1],"X3_TITULO"),;
						_astruct[_np][1],;
						_astruct[_np][2],;
						_astruct[_np][3],;
						_astruct[_np][4],;
						Getsx3cache(_astruct[_np][1],"X3_PICTURE")})

	EndIf

Next _nCont

DBSelectArea("ZL5")
DBSetOrder(2)
ZL5->(DBGoTop())

mBrowse( 6, 1,22,75,"ZL5"  ,aTitulos,,,, ,aCores)

ZL6->(DBCloseArea())


Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST030G
Autor-------------: Josué Danich
Data da Criacao---: 04/12/2015
Descrição---------: Rotina para retornar próximo código de evento para campo ZL5->CODGRP
Parametros--------: 
Retorno-----------: _ccod - próximo valor para ZL5->CODGRP
===============================================================================================================================
*/
User Function AEST030G()

Local _ccod 	:= "000001"
Local _cQuery := ""
Local _aarea	:= FWGetArea()

_cQuery	:= " SELECT " 
_cQuery  	+= 	" MAX(ZL5_CODGRP) AS CODI" 
_cQuery  	+= 	" FROM " + RetSqlName("ZL5") + " ZL5 "
_cQuery  	+= 	" WHERE ZL5_FILIAL = '" + xFilial("ZL5") + "'"
_cQuery  	+= 	" AND   ZL5_TPCUST  = '" + AllTrim(M->ZL5_TPCUST) + "'"
_cQuery 	+= 	" AND   ZL5.D_E_L_E_T_ 	= ' '	"

TcQuery _cQuery New Alias ZL5T
	
DBSelectArea("ZL5T")

If .not. ZL5T->( Eof() )

	_ccod := StrZero( ( Val( ZL5T->CODI) + 1 ),6 )

EndIf

If Select("ZL5T") > 0 

	ZL5T->( DBCloseArea() )

EndIf

FWRestArea(_aarea)

Return _ccod

