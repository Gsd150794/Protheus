/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Abrahao		  |08/10/2008| Adicinar novos campos e ajustar campos dos itens - Monis(leite)
André Lisboa  |22/08/2017| Chamado 20782. Ajustar rotina para nova versão 12
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#DEFINE LINHAS 999

/*
===============================================================================================================================
Programa----------: AFIS001
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Rotina desenvolvida para possibilitar a amarracao dos CFOPs com tipo de Operacao(Venda,Transf,Bonificacao)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIS001()

Private bAltera 	:= {|| FIS001ALT('ZAY',Recno(),4)  }
Private cCadastro 	:= "Amarracao CFOP x Tipo Operacao"
Private aRotina   	:= MenuDef()
Private cAlias 		:= "ZAY"

DBSelectArea("ZAY")
mBrowse( 6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: FIS001ALT
Autor-------------: Jeovane
Data da Criacao---: 11/09/2008
Descrição---------: Funcao usada para dar manutencao - Inclusao/Alteracao/Exclusao da tabela ZAY - CFOP X Tipo Operacao
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function FIS001ALT(cAlias,nReg,nOpc)

Local cTitulo	:= "CFOP x Tipo Operacao"
Local aObjects 	:={}
Local aPosObj	:={}
Local aSize    	:=MsAdvSize()
Local aInfo    	:={aSize[1],aSize[2],aSize[3],aSize[4],3,3}
Local aNoFields	:= {}
Local _nI		:= 0
Private oDlg
Private lConfirmou 	:= .F.
Private cSeek	    := xFilial("ZAY")
Private bSeekFor	:= {|| 	ZAY->ZAY_FILIAL == xFilial("ZAY")  }
Private bSeekWhile	:= {|| ZAY->ZAY_FILIAL } //Condicao While para montar o aCols

aButtons  := If(Type("aButtons") == "U", {}, aButtons)

//===================================================================================================
// Monta a entrada de dados do arquivo                  
//===================================================================================================
cSeek	  := xFilial("ZAY")

//===================================================================================================
// Monta aHeader e aCols utilizando a funcao FillGetDados       
//===================================================================================================
Private aHeader[0],aCols[0]

//===================================================================================================
// Variaveis privadas para montagem da tela             
//===================================================================================================
SetPrvt("aRotina,CCADASTRO,CALIAS")
SetPrvt("NOPCE,NOPCG,NUSADO")
SetPrvt("CTITULO,CALIASENCHOICE,CLINOK,CTUDOK,CFIELDOK")
SetPrvt("NREG,NOPC")

//==========================================================================================================================================================================================================================
// Sintaxe da FillGetDados( nOpcx, cAlias, nOrder, cSeekKey, bSeekWhile, uSeekFor, aNoFields, aYesFields, lOnlyYes, cQuery, bMontCols, lEmpty, aHeaderAux, aColsAux, bAfterCols, bBeforeCols, bAfterHeader, cAliasQry )   |
//==========================================================================================================================================================================================================================
FillGetDados(nOpc,cAlias,1,cSeek,bSeekWhile,bSeekFor,aNoFields,,,,,,,,,)

//aAdd(aObjects,{100,055,.T.,.F.,.T.})
aAdd(aObjects,{100,100,.T.,.T.})
//aAdd(aObjects,{100,002,.T.,.F.})

aPosObj:=MsObjSize(aInfo,aObjects)

//===================================================================================================
// Tela do model 2 - Rececpcao de Leite                 
//===================================================================================================

DEFINE MSDIALOG oDlg TITLE cTitulo OF oMainWnd PIXEL FROM aSize[7],0 TO aSize[6],aSize[5]
//@ 1.3,0.3 TO 2.3,43.0
//@ 5.9,0.3 TO 7.0,43.0

oGet := MSGetDados():New(aPosObj[1,1],aPosObj[1,2],aPosObj[1,3],aPosObj[1,4],nOpc,,,"",.F.,NIL,NIL,NIL,LINHAS)

ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| lConfirmou := .T. ,If(lConfirmou,oDlg:End(),)},{||oDlg:End()},,aButtons)

//===================================================================================================
// Grava dados da ZAY                                   
//===================================================================================================
If lConfirmou
    nPosTpOp := aScan(aHeader,{|x| AllTrim(x[2]) == "ZAY_TPOPER" }) //Busca idx da coluna do ZAY_TPOPER
    nPosCf := aScan(aHeader,{|x| AllTrim(x[2]) == "ZAY_CF" })    //Busca idx da coluna do ZAY_TPCF
	DBSelectArea("ZAY")
	BEGIN TRANSACTION
	For _nI := 1 To Len(aCols)
		If DBSeek(xFilial("ZAY")+aCols[_nI,nPosCf])
			RecLock("ZAY",.F.)
			ZAY->ZAY_TPOPER := aCols[_nI,nPosTpOp]
			ZAY->(MSUnLock())
		EndIf
	Next _nI
	END TRANSACTION
Else
	
EndIf

U_ITLOGACS('AFIS001')

Return

/*
===============================================================================================================================
Programa----------: menuDef
Autor-------------: Jeovane
Data da Criacao---: 11/09/2008
Descrição---------: Funcao usada para criar menu da tela MBrowse de Recepcao de leite
Parametros--------: 1. Nome a aparecer no cabecalho                             											
					2. Nome da Rotina associada                                 											
					3. Reservado                                                											
					4. Tipo de Transa‡„o a ser efetuada:                        													
						1 - Pesquisa e Posiciona em um Banco de Dados           													
						2 - Simplesmente Mostra os Campos                       													
						3 - Inclui registros no Bancos de Dados                 													
						4 - Altera o registro corrente                         													
						5 - Remove o registro corrente do Banco de Dados        													
					5. Nivel de acesso                                          													
					6. Habilita Menu Funcional  
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Private aRotina	:=  {	{OemToAnsi("Pesquisar"),"AxPesqui"  , 0 , 1,0,.F.},;		//"Pesquisar"
						{OemToAnsi("Visualizar"),"AxVisual", 0 , 2,0,nil},;		//"Visualizar"
						{OemToAnsi("Incluir"),"AxInclui", 0 , 3,0,nil},;		//"Incluir"
						{OemToAnsi("Alterar"),"eval(bAltera)", 0 , 4,0,nil},;		//"Alterar"
						{OemToAnsi("Excluir"),"AxDeleta", 0 , 5,0,nil}}		//"Excluir" 
Return (aRotina)
