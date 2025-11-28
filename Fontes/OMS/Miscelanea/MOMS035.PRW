/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include 'rwmake.ch' 
#Include "APWEBSRV.CH"
#Include "TOTVS.ch"  
#Include "TBICONN.CH"   

/*
===============================================================================================================================
Programa----------: MOMS035
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2018
===============================================================================================================================
Descrição---------: Tela de conferência de recebimento físico de canhotos - Chamado 23296
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS035()

Local oDlg
Local _cCodBarra := Space(Len(SF2->F2_FILIAL)+Len(SF2->F2_DOC)+Len(SF2->F2_SERIE))
Local aTitulo    := {"Filial","No. Nota Fiscal","Serie","Contador"}
Local aColsSize  := {20,45,20,30} //Tamanho das colunas
Local nLinha:=012
Local nPula :=030
Local nCol1 :=010
Local nColTW:=100
Local nLarg :=130
Local nAltu :=250
Local nLinTl:=510
Local nColTl:=460
Local lGrava:=.F.

Private _cFil := SubStr(_cCodBarra,01,2)
Private _cNF  := SubStr(_cCodBarra,03,9)
Private _cSer := SubStr(_cCodBarra,12,3)
Private aLista:= {{"","","",0}}

While .T.

   nLinha:=012 //Reinicia por causa do Loop
   If lGrava//Testa pora causa do Loop da pergunta, não pode zerar
      aLista:={{"","","",0}}//Reinicia por causa do Loop
   EndIf
   lGrava:=.F.//Reinicia por causa do Loop

   DEFINE MSDIALOG oDlg TITLE "REGISTRO DO CANHOTO" FROM 000, 000  TO nLinTl,nColTl PIXEL

	@ nLinha, nCol1 Say "Insira o Codigo de Barras"  SIZE 090, 007 PIXEL OF oDlg

	nLinha+=10
	@ nLinha, nCol1 MSGET _cCodBarra                 SIZE 075, 010 PIXEL OF oDlg VALID MOMS035Val(@_cCodBarra)

    oList:=TWBrowse():New(02,nColTW,nLarg,nAltu,,aTitulo,aColsSize,oDlg,,,,,,,,,,,,,"ARRAY",.T.)
  	oList:SetArray(aLista)					
    oList:bLine:={|| {aLista[oList:nAt,1],aLista[oList:nAt,2],aLista[oList:nAt,3],aLista[oList:nAt,4]} }
	
	nLinha+=nPula
	TButton():New(nLinha,nCol1, 'SALVAR', oDlg,{|| lGrava:=.T. , oDlg:End() },075,015,,,,.T.,,,,,,)

	nLinha+=nPula
    TButton():New(nLinha,nCol1, 'SAIR'  , oDlg,{|| lGrava:=.F. , oDlg:End() },075,015,,,,.T.,,,,,,)

   ACTIVATE MSDIALOG oDlg 

   If lGrava
      FWMsgRun( ,{|P| MOMS035Grava(P) },"Aguarde!","Gravando Canhotos..."  )
      Loop
   ElseIf !Empty(aLista[1,1]) .And. !U_ITMsg("Confirma Sair",'Atenção!',,3,2,2)
      Loop
   EndIf

   Exit

EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS035Val()
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2018
===============================================================================================================================
Descrição---------: Validação
===============================================================================================================================
Parametros--------: _cCodBarra,aLista
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS035Val(_cCodBarra)
_cFil:=SubStr(_cCodBarra,01,2)
_cNF :=SubStr(_cCodBarra,03,9)
_cSer:=SubStr(_cCodBarra,12,3)

If Empty(_cCodBarra)
   Return .T.
EndIf

SF2->(DBSetOrder(1))
If !SF2->(DBSeek(_cFil+_cNF+_cSer))
   U_ITMsg("Nota não existe: Filial: "+_cFil+", Nota: "+_cNF+", Serie: "+_cSer,"Alteração","Verifique o numero inserido",3)
   Return .F.
EndIf

ZGJ->(DBSetOrder(1))
If ZGJ->(DBSeek(_cFil+_cNF+_cSer))
   U_ITMsg("Canhoto já recepicionado: Filial: "+_cFil+", Nota: "+_cNF+", Serie: "+_cSer,"Alteração","Verifique o numero inserido",3)
   Return .F.
EndIf

If Empty(aLista[1,1])
   aLista [1,1]:=_cFil
   aLista [1,2]:=_cNF
   aLista [1,3]:=_cSer
   aLista [1,4]:=1
ElseIf aScan(aLista, {|L| L[1]+L[2]+L[3] == _cFil+_cNF+_cSer } ) = 0
   aAdd(aLista,{_cFil,_cNF,_cSer, Len(aLista)+1 })
EndIf
oList:Refresh()

_cCodBarra := Space(Len(SF2->F2_FILIAL)+Len(SF2->F2_DOC)+Len(SF2->F2_SERIE))

Return .F.

/*
===============================================================================================================================
Programa----------: MOMS035Grava()
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2018
===============================================================================================================================
Descrição---------: Gravação
===============================================================================================================================
Parametros--------: aLista
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS035Grava(oProc)
Local L

For L := 1 TO Len(aLista)
	
	oProc:cCaption := ("Gravando NF: "+aLista[L,2])
	ProcessMessages()
	If !ZGJ->(DBSeek(aLista[L,1]+aLista[L,2]+aLista[L,3]))  
		ZGJ->(RecLock("ZGJ",.T.))
		ZGJ->ZGJ_FILIAL:= aLista[L,1]
		ZGJ->ZGJ_NOTA  := aLista[L,2]
		ZGJ->ZGJ_SERIE := aLista[L,3]
		ZGJ->ZGJ_DATAI := Date()
		ZGJ->ZGJ_HORAI := Time()
		ZGJ->ZGJ_STATUS:= "Recepcionado"
        If ZGJ->(FIELDPOS("ZGJ_USERI")) # 0
		   ZGJ->ZGJ_USERI := AllTrim(UsrFullName(__cUserId))
		EndIf
		ZGJ->(MSUnLock())  
	EndIf
	
Next

Return .T.
