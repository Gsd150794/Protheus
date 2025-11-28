/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/04/2018| Chamado 24306. Inclusao do botão Altera Preco no MTA018MNU.PRW
Alex Wallauer |12/02/2019| Chamado 28064. Ajustes nas chamadas DE MENIDEF
Lucas Borges  |24/09/2024| Chamado 48465. Sanado problemas apresentados no Code Analysis
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST027
Autor-------------: Erich Buttne
Data da Criacao---: 04/04/2013 
Descrição---------: Rotina desenvolvida para possibilitar a alteracao de campos especificos dos Indicadores de Produtos
                     >>>>  Procurar MATA018 no menu fica no aRotina do MTA018MNU <<<<<
Parametros--------: cAlias - Nome do alias em uso no Browse.
                    nReg - Numero do Recno do alias em uso no Browse.
                    nOpc - Numero da opcao selecionada no menu lateral do Browse.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST027(_lAltSoPreco)
Local oDlg
Local aPosObj   := {}
Local aObjects  := {}
Local aSize     := {}
Local aPosGet   := {}
Local aInfo     := {}
Local nOpcA     := 0
Local aArea     := FWGetArea()
Local cCpos     := ""
Local cAlias    := "SBZ"
Local nReg      := SBZ->(Recno())
Local nOpc      := 4

Private aCols   := {}
Private aHeader := {}
Private aCpos1  := {}
Private aTELA[0][0]
Private aGETS[0]

Private aAreaSBZ := SBZ->(GetArea())

//Arrays de controle dos campos que deverao ser alterados no cabecalho qdo Pedido ja Faturado. 
If _lAltSoPreco
   cCpos := '{"BZ_UPRC"}'
Else
   cCpos := AllTrim(GetMv("IT_CMPSBZ"))
EndIf

aCpos1 := cCpos
aCpos1 := If(Empty(aCpos1),{},&aCpos1)

If _lAltSoPreco
   cCpos := ' campo: [ BZ_UPRC ]'
Else
   cCpos := " dos campos: "+cCpos
EndIf

ALTERA := .T.

//Inicializa desta forma para criar uma nova instancia de variaveis private
RegToMemory( "SBZ", .F., .F. )

aSize    := MsAdvSize()
aObjects := {}
aAdd( aObjects, { 100, 100, .T., .T. } )
aAdd( aObjects, { 100, 100, .T., .T. } )
aAdd( aObjects, { 100, 015, .T., .F. } )

aInfo   := { aSize[ 1 ],aSize[ 2 ],aSize[ 3 ],aSize[ 4 ],03,03 }
aPosObj := MsObjSize( aInfo, aObjects )
aPosGet := MsObjGetPos(aSize[3]-aSize[1],315,{{003,157,189,236,268}})

DEFINE MSDIALOG oDlg TITLE cCadastro+cCpos From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

oMsMGet:=MsMGet():New( cAlias, nReg, nOpc, , , , , {0,aSize[1],aSize[4],aSize[3]}/*aPosObj[1]*/, aCPos1, 3 )

oDlg:lMaximized:=.T.

ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{||nOpca:=1,If(EST27TuOk(),oDlg:End(),nOpca := 0)},{||oDlg:End()},,) , oMsMGet:oBox:Align:=CONTROL_ALIGN_ALLCLIENT )

If ( nOpcA == 1 )
   
   //Log de utilização
   U_ITLOGACS()
   
	MsgRun("Aguarde....Gravando dados...",,{||EST27Grv()})
	EvalTrigger()
EndIf

MSUnLockAll()
FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: EST27TuOk
Autor-------------: Erich Buttne
Data da Criacao---: 04/04/2013 
Descrição---------: Validacao GetDados.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function EST27TuOk()
Return(.T.)
/*
===============================================================================================================================
Programa----------: EST27Grv
Autor-------------: Erich Buttne
Data da Criacao---: 04/04/2013 
Descrição---------: Gravacao dos dados alterados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function EST27Grv()

Local nX   := 0
Local _cUser := AllTrim(UsrFullName(__cUserId))//Usuario alteorou Ult Preco
//Gravacao do cabecalho
FWRestArea(aAreaSBZ)
RecLock("SBZ",.F.)
For nX := 1 To FCount() //Conta as colunas da tabela no banco, nao considera os campos virtuais
	If aScan(aCpos1,FieldName(nX)) > 0 //Verifica se o campo existe no array aCpos1
	   FieldPut(nX,M->&(FieldName(nX)))

	   If FieldName(nX) = "BZ_UPRC" .And. FIELDPOS("BZ_I_USRUP") <> 0
          SBZ->BZ_I_USRUP:= _cUser
          SBZ->BZ_I_DATUP:=DATE()//Data alterou Ult Preco
	   EndIf
	   
	EndIf
Next nX
MSUnLock()


//Restaura a area do cabecalho		
FWRestArea(aAreaSBZ)

Return
