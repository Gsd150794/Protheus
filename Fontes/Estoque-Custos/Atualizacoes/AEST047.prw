/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST047
Autor-------------: Alex Wallauer
Data da Criacao---: 25/09/2019 
Descrição---------: Criacao de Tela de Cadastro do Nivel 5   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function AEST047()

Local cAlias		:= "ZA0"
Private cCadastro	:= ""
Private aRotina		:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"U_ValZA0",0,4})
aAdd(aRotina,{"Excluir"		,"U_ValZA0",0,5})
	
cCadastro	:= "Cadastro de Nivel 5"
DBSelectArea(cAlias)
DBSetOrder(1)
mBrowse(6,1,22,75,cAlias)

Return
/*
===============================================================================================================================
Programa----------: ValZA0
Autor-------------: Alex Wallauer
Data da Criacao---: 25/09/2019 
Descrição---------: Validacao da Alteracao e Exclusao
Parametros--------: cAlias,nReg,nOpc  
Retorno-----------: Retorno Logico (.T. ou .F.) para exclusao ou alteracao 
===============================================================================================================================
*/
User Function ValZA0(cAlias,nReg,nOpc)

Local lRet		:= .T. 
Local _cCod		:= ZA0->ZA0_COD
Local cQuery	:= 	""

cQuery := "SELECT COUNT(B.B1_I_NIV5) AS CONT"
cQuery += " FROM " + RetSqlName("SB1") + " B"
cQuery += " WHERE B.D_E_L_E_T_ = ' ' AND B.B1_I_NIV5 = '"+_cCod+"' "

dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TEMP", .T., .F. )
DBSelectArea("TEMP")

If TEMP->CONT <> 0
	lRet	:= .F.
EndIf
	
TEMP->(DBCloseArea())

If lRet .And. nOpc == 4
	AxAltera(cAlias,nReg,nOpc)
ElseIf lRet .And. nOpc == 5 
	AxDeleta(cAlias,nReg,nOpc)
EndIf

Return lRet 
