/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |22/08/2017| Chamado 20782. Alterações gerais para versão 12
Lucas Borges  |09/05/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |10/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.CH"
#Include "RWMAKE.CH"

/*
===============================================================================================================================
Programa----------: MFIN003
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Rotina para possibilitar a alteração do vencimento de varios titulos do contas a Pagar de uma unica vez
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN003

Private _cPerg		:= "MFIN003"
Private _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Altera Vencimento Títulos a Pagar"				,; // Descrição da Rotina
					{|_oSelf| MFIN003P() }							,; // Função do processamento
					"Rotina para efetuar a alteração em massa do vencimento de títulos a Pagar." ,; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.F.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MFIN003P
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN003P

Local _nX		:= 0
Local oPanel
Local oDlg1
Local nHeight	:= 0
Local nWidth	:= 0
Local aSize		:= {}
Local aBotoes	:= {}
Local aCoors	:= {}
Local oOK		:= LoadBitmap(GetResources(),'LBOK')
Local oNO		:= LoadBitmap(GetResources(),'LBNO')
Local oAberto	:= LoadBitmap(GetResources(),'br_verde')
Local oBaixado	:= LoadBitmap(GetResources(),'br_azul')

Private oQtda
Private nOpca	:= 0
Private nQtdTit	:= 0
Private aObjects:= {}
Private aPosObj1:= {}
Private aInfo	:= {}
Private _cAlias	:= GetNextAlias()
Private aTitulo	:= {}
Private _aStru	:= {}
Private oBrowse
Private oFont12b

//Define a fonte a ser utilizada no GRID
Define Font oFont12b   Name "Courier New"       Size 0,-12 Bold  // Tamanho 12 Negrito

Begin Transaction

//Criando estrutura da tabela temporaria
aAdd(_aStru,{"E2_STATUS"	,"C",02,00})
aAdd(_aStru,{"E2_LEGEND"	,"C",02,00})
aAdd(_aStru,{"E2_PREFIXO"	,"C",GetSX3Cache("E2_PREFIXO","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_NUM"		,"C",GetSX3Cache("E2_NUM","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_PARCELA"	,"C",GetSX3Cache("E2_PARCELA","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_TIPO"		,"C",GetSX3Cache("E2_TIPO","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_NATUREZ"	,"C",GetSX3Cache("E2_NATUREZ","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_FORNECE"	,"C",GetSX3Cache("E2_FORNECE","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_LOJA"		,"C",GetSX3Cache("E2_LOJA","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_NOMFOR"	,"C",GetSX3Cache("E2_NOMFOR","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_EMISSAO"	,"D",GetSX3Cache("E2_EMISSAO","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_VENCTO"	,"D",GetSX3Cache("E2_VENCTO","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_VENCREA"	,"D",GetSX3Cache("E2_VENCREA","X3_TAMANHO"),00})
aAdd(_aStru,{"E2_VALOR"		,"N",GetSX3Cache("E2_VALOR","X3_TAMANHO"),GetSX3Cache("E2_VALOR","X3_DECIMAL")})
aAdd(_aStru,{"E2_SALDO"		,"N",GetSX3Cache("E2_SALDO","X3_TAMANHO"),GetSX3Cache("E2_SALDO","X3_DECIMAL")})
aAdd(_aStru,{"SE2RECNO"		,"N",08,00})

//Armazena no array aCampos o nome, descricao dos campos e picture
aAdd(aTitulo,{"E2_STATUS"	,"  "				," "})
aAdd(aTitulo,{"E2_LEGEND"	,"  "				," "})
aAdd(aTitulo,{"E2_PREFIXO"	,"PREFIXO"			,GetSX3Cache("E2_PREFIXO","X3_PICTURE")})
aAdd(aTitulo,{"E2_NUM"		,"NUMERO >>"		,GetSX3Cache("E2_NUM","X3_PICTURE")})
aAdd(aTitulo,{"E2_PARCELA"	,"PARCELA"			,GetSX3Cache("E2_PARCELA","X3_PICTURE")})
aAdd(aTitulo,{"E2_TIPO"		,"TIPO"				,GetSX3Cache("E2_TIPO","X3_PICTURE")})
aAdd(aTitulo,{"E2_NATUREZ"	,"NATUREZA"			,GetSX3Cache("E2_NATUREZ","X3_PICTURE")})
aAdd(aTitulo,{"E2_FORNECE"	,"FORNECEDOR >>"	,GetSX3Cache("E2_FORNECE","X3_PICTURE")})
aAdd(aTitulo,{"E2_LOJA"		,"LOJA"				,GetSX3Cache("E2_LOJA","X3_PICTURE")})
aAdd(aTitulo,{"E2_NOMFOR"	,"RAZAO SOCIAL >>"	,"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"})//Picture passada desta forma para que o espacamento seja respeitado 
aAdd(aTitulo,{"E2_EMISSAO"	,"EMISSAO"			,GetSX3Cache("E2_EMISSAO","X3_PICTURE")})
aAdd(aTitulo,{"E2_VENCTO"	,"VENCIMENTO"		,GetSX3Cache("E2_VENCTO","X3_PICTURE")})
aAdd(aTitulo,{"E2_VENCREA"	,"VENC. REAL >>"	,GetSX3Cache("E2_VENCREA","X3_PICTURE")})
aAdd(aTitulo,{"E2_VALOR"	,"VALOR >> "		,GetSX3Cache("E2_VALOR","X3_PICTURE")})
aAdd(aTitulo,{"E2_SALDO"	,"SALDO >>"			,GetSX3Cache("E2_SALDO","X3_PICTURE")})
aAdd(aTitulo,{"SE2RECNO"	,"RECNO"			,"@!"})

_cQuery := " SELECT E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_NATUREZ, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO,"
_cQuery += " E2_VENCTO, E2_VENCREA, E2_VALOR, E2_SALDO, R_E_C_N_O_ SE2RECNO"
_cQuery += " FROM " + RetSqlName("SE2")
_cQuery += " WHERE D_E_L_E_T_ = ' '"
_cQuery += " AND E2_SALDO > 0"
_cQuery += " AND E2_TIPO <> 'PA '"
_cQuery += " AND E2_FILIAL = '"  + xFilial("SE2") + "'"
_cQuery += " AND E2_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
_cQuery += " AND E2_VENCREA BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "'"
_cQuery += " AND E2_FORNECE BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "'"
_cQuery += " AND E2_LOJA BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR08 + "'"
If !Empty(MV_PAR09)
	_cQuery  += " AND E2_PREFIXO IN " + FormatIn(MV_PAR09,";")
EndIf
If !Empty(MV_PAR10)
	_cQuery  += " AND E2_TIPO IN " + FormatIn(MV_PAR10,";")
EndIf
If !Empty(MV_PAR11)
	_cQuery  += " AND E2_NATUREZ IN " + FormatIn(MV_PAR11,";")
EndIf
_cQuery += " ORDER BY  E2_NUM,E2_PARCELA"

_oTempTable := FWTemporaryTable():New( _cAlias, _aStru )
_oTempTable:AddIndex( "01", {"E2_NUM"} )
_oTempTable:AddIndex( "02", {"E2_FORNECE", "E2_LOJA"} )
_oTempTable:AddIndex( "03", {"E2_NOMFOR"} )
_oTempTable:AddIndex( "04", {"E2_VALOR"} )
_oTempTable:AddIndex( "05", {"E2_SALDO"} )
_oTempTable:AddIndex( "06", {"E2_VENCREA"} )
_oTempTable:Create()
SQLToTrb(_cQuery, _aStru, _cAlias)

IncProc('Lendo os dados...')

DBSelectArea("SE2")
(_cAlias)->( DBGoTop() )
While (_cAlias)->(!Eof())
	//Bloqueia os titulos selecionados na pesquisa, para que não seja possivel enquanto esta rotina estiver sendo utilizada a sua alteracao
	SE2->( DBGoTo((_cAlias)->SE2RECNO) )
	SE2->(MSUnLock())	
	RecLock("SE2",.F.)
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBGoTop() )

//Faz o calculo automatico de dimensoes de objetos
aSize := MSADVSIZE()

//Obtem tamanhos das telas
aAdd( aObjects, { 0, 0, .T., .T., .T. } )

aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 } 
aPosObj1 := MsObjSize( aInfo, aObjects,  , .T. ) 

//Botoes da tela
aAdd( aBotoes, {"PESQUISA" ,{||xPesqTRB(_cAlias)},"Pesquisar..."					,"Pesquisar"   })
aAdd( aBotoes, {"S4WB005N" ,{||xVisuTRB()		},"Visualizar Titulo..."			,"Titulo"      })
aAdd( aBotoes, {'RELATORIO',{||MsgRun("Imprimindo Relatório Aguarde...",,{||CursorWait(),RelatSE2(),CursorArrow(),(_cAlias)->(DBGoTop())})  },"Imprimir"})
aAdd( aBotoes, {"RESPONSA" ,{||AtualzTits()		},"Atualizar varios titulos..."    ,"Atual.Titulos"})

//Cria a tela para selecao dos Titulos
DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Rotina de Alteração de Vencimento dos Títulos a Pagar") From 0,0 To aSize[6]+15,aSize[5] OF oMainWnd PIXEL

oPanel       := TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,315,30,.T.,.T. )
//oPanel:Align := CONTROL_ALIGN_TOP // Somente Interface MDI

@ 0.8 ,00.8 Say OemToAnsi("Quantidade:")        OF oPanel FONT oFont12b 
@ 0.8 ,0005 Say oQtda VAR nQtdTit Picture "@E 999999" SIZE 60,8 OF oPanel FONT oFont12b 

//Legenda
@ 0.0 ,037.5 Say OemToAnsi("Legenda:")        OF oPanel FONT oFont12b 
@ 0.6 ,039   Say OemToAnsi("- Título em aberto(Não sofreu baixa) ")        OF oPanel FONT oFont12b 
@ 1.2 ,039  Say OemToAnsi("- Baixado parcialmente ")        OF oPanel FONT oFont12b 
@ 007, 300 BITMAP oBitmap1 SIZE 022, 016 OF oPanel FILENAME 'br_verde' NOBORDER PIXEL
@ 015, 300 BITMAP oBitmap1 SIZE 022, 016 OF oPanel FILENAME 'br_azul'  NOBORDER PIXEL

If FlatMode()
	aCoors := GetScreenRes()
	nHeight	:= aCoors[2]
	nWidth	:= aCoors[1]
Else
	nHeight	:= 143
	nWidth	:= 315
EndIf

(_cAlias)->(DBGoTop())

oBrowse := TCBrowse():New( 35,01,aPosObj1[1,3] + 7,aPosObj1[1,4],,;
	                     ,{20,20,02,09,02,02,10,06,04,54,08,08,08,17,17},;
	                     oDlg1,,,,,{||},,oFont12b,,,,,.F.,_cAlias,.T.,,.F.,,.T.,.T.)

For _nX:=1 to Len(_aStru)
	If _aStru[_nX,1] == "E2_STATUS" 
		oBrowse:AddColumn(TCColumn():New("",{|| IIf((_cAlias)->E2_STATUS == Space(2),oNO,oOK)},,,,"CENTER",,.T.,.F.,,,,.F.,))
	ElseIf _aStru[_nX,1] == "E2_LEGEND"
	    oBrowse:AddColumn(TCColumn():New("",{|| IIf((_cAlias)->E2_VALOR == (_cAlias)->E2_SALDO,oAberto,oBaixado)},,,,"CENTER",,.T.,.F.,,,,.F.,))
	Else
		oBrowse:AddColumn(TCColumn():New(OemToAnsi(aTitulo[_nX,2]),&("{ || " + _cAlias + '->' + _aStru[_nX,1]+"}"),aTitulo[_nX,3],,,If(_aStru[_nX,2]=="N","RIGHT","LEFT"),,.F.,.F.,,,,.F.,))
	EndIf
Next _nX

oBrowse:GetColSizes()

// Evento de duplo click na celula
oBrowse:bLDblClick   := {|| setStatus(_cAlias,(_cAlias)->E2_STATUS)}  

//Evento quando o usuario clica na coluna desejada
oBrowse:bHeaderClick := { |oBrowse, nCol| nColuna:= nCol,MsgRun("Realizando operação...",,{|| ordenaDado(_cAlias,nColuna) }) }

ACTIVATE MSDIALOG oDlg1 ON INIT (EnchoiceBar(oDlg1,{|| IIf(vldAlter(nQtdTit),Eval({|| nOpca := 1,oDlg1:End(),MsgRun("Processando alteraão do(s)Título(s).",,{||CursorWait(), procAltVen(), CursorArrow()})}),) },{|| nOpca := 2,oDlg1:End()},,aBotoes),oPanel:Align := CONTROL_ALIGN_TOP,oBrowse:Align := CONTROL_ALIGN_ALLCLIENT,oBrowse:Refresh())

//Efetuando o desbloqueio dos titulos anteriormente bloqueados no momento de sua selecao
Processa( {||desarmTit()}/*bAction*/, "Aguarde..."/*cTitle */, "Efetuando o desbloqueio dos títulos..."/*cMsg */,.F./*lAbort */)

//Fecha a area de uso do arquivo temporario no Protheus
(_cAlias)->(DBCloseArea())
_oTempTable:Delete()

End Transaction

Return

/*
===============================================================================================================================
Programa----------: lstPre
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Tem por objetivo auxiliar na escolha dos Prefixos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function lstPre()

Local i           := 0
Private nTam      := 0
Private nMaxSelect:= 0
Private aCat      := {}
Private MvRet     := AllTrim(ReadVar())
Private MvPar     := ""
Private cTitulo   := ""
Private MvParDef  := ""

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam       := 3
nMaxSelect := 18 //75 / 4
cTitulo    := "Prefixos"
                 
DBSelectArea("ZAB")
ZAB->(DBSetOrder(1))
ZAB->(DBGoTop())

While ZAB->(!Eof())  
	MvParDef += ZAB->ZAB_PREFIX
	aAdd(aCat,AllTrim(ZAB->ZAB_DESCRI))
	ZAB->(DBSkip())
EndDo

//Trativa abaixo para no caso de uma alteracao do campo trazer todos os dados que foram selecionados anteriormente
If Len(AllTrim(&MvRet)) == 0
	MvPar:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
	&MvRet:= PadR(AllTrim(StrTran(&MvRet,";","")),Len(aCat))
Else
	MvPar:= AllTrim(StrTran(&MvRet,";","/"))
EndIf

//Somente altera o conteudo caso o usuario clique no botao ok
//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aCat,MvParDef,12,49,.F.,nTam,nMaxSelect)

	//Tratamento para separar retorno com barra ";"
	&MvRet := ""
	For i:=1 to Len(MvPar) step nTam
		If !(SubStr(MvPar,i,1) $ " |*")
			&MvRet  += SubStr(MvPar,i,nTam) + ";"
		EndIf
	Next i

	//Trata para tirar o ultimo caracter
	&MvRet := SubStr(&MvRet,1,Len(&MvRet)-1) 

EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: setStatus
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Seta status
Parametros--------: _cAlias, _cStatus
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function setStatus(_cAlias,_cStatus)

If _cStatus == Space(2)
	RecLock(_cAlias,.F.)
	(_cAlias)->E2_STATUS:= 'XX'
	nQtdTit++
	(_cAlias)->(MSUnLock())
Else
	RecLock(_cAlias,.F.)
	(_cAlias)->E2_STATUS:= Space(2)
	nQtdTit--
	(_cAlias)->(MSUnLock())
EndIf

nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)

oQtda:Refresh()

oBrowse:DrawSelect()
oBrowse:Refresh(.T.)

Return

Static Function ordenaDado(_cAlias,nColuna)

Local _aArea:= FWGetArea()

Do Case	
	//Marca ou desmarca todos os titulos selecionados
	Case nColuna == 1
		(_cAlias)->(DBGoTop())
		While (_cAlias)->(!Eof())
			//Se o titulo nao estiver selecionado
			If (_cAlias)->E2_STATUS == Space(2) 
				RecLock(_cAlias,.F.)
				(_cAlias)->E2_STATUS:= 'XX'
				nQtdTit++
				(_cAlias)->(MSUnLock())
			//Titulo selecionado
			Else
				RecLock(_cAlias,.F.)
				(_cAlias)->E2_STATUS:= Space(2) 
				nQtdTit--
				(_cAlias)->(MSUnLock())
			EndIf
			(_cAlias)->(DBSkip())
		EndDo
		nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)
		oQtda:Refresh()
		FWRestArea(_aArea)
	//Numero do Titulo
	Case nColuna == 4
		(_cAlias)->(DBSetOrder(1))
	//Codigo do Fornecedor + Loja
	Case nColuna == 8
		(_cAlias)->(DBSetOrder(2))
	//Nome do Fornecedor
	Case nColuna == 10
		(_cAlias)->(DBSetOrder(3))
		//Data de vencimento real
	Case nColuna == 13
		(_cAlias)->(DBSetOrder(6))
	//Valor do Titulo
	Case nColuna == 14
		(_cAlias)->(DBSetOrder(4))
	//Saldo do Titulo
	Case nColuna == 15
		(_cAlias)->(DBSetOrder(5))
EndCase

(_cAlias)->(DBGoTop())
oBrowse:DrawSelect()
oBrowse:Refresh(.T.)

Return

Static Function xPesqTRB(_cAlias)

Local oDlg
Local aComboBx1	 := {"Numero do Titulo","Codigo+Loja","Nome do Fornecedor","Valor","Saldo"}
Local nOpca      := 0
Local nI         := 0

Private cGet1	 := Space(09)
Private oGet1
Private cComboBx1:= ""

@ 178,181 TO 259,697 Dialog oDlg Title "Pesquisar"

@ 004,003 ComboBox cComboBx1 Items aComboBx1 Size 213,010 PIXEL OF oDlg ON CHANGE alteraMasc()
@ 020,003 MsGet oGet1 Var cGet1 Size 212,009 COLOR CLR_BLACK Picture "999999999" PIXEL OF oDlg

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION (nOpca:=1,oDlg:End()) OF oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION (nOpca:=0,oDlg:End()) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1
	If (Len(AllTrim(cGet1)) > 0 .And. Type("cGet1") == 'C') .Or. (Type("cGet1") == 'N' .And. cGet1 > 0 )
		For nI := 1 To Len(aComboBx1)
			If cComboBx1 == aComboBx1[nI]
					(_cAlias)->(DBSetOrder(nI))
					MsSeek(cGet1,.T.)
					oBrowse:DrawSelect()
					oBrowse:Refresh(.T.)
			EndIf
		Next nI
	Else
		MsgStop("Favor informar um conteúdo a ser pesquisado. Para realizar a pesquisa é necessário que se forneça o conteúdo a ser pesquisado.","MFIN00301")
	EndIf
EndIf

Return

Static Function alteraMasc()

If cComboBx1 == "Numero do Titulo"
	cGet1	 := Space(09)  
	oGet1:Picture:= "999999999"
ElseIf cComboBx1 == "Codigo+Loja"
	cGet1:= Space(10)
	oGet1:Picture:= "@!"
ElseIf cComboBx1 == "Nome do Fornecedor"
	cGet1:= Space(20)
	oGet1:Picture:= "@!"
ElseIf cComboBx1 == "Valor"
	cGet1:= Space(17)
	oGet1:Picture:= PesqPict("SE2","E2_VALOR")
	cGet1:= 0
ElseIf cComboBx1 == "Saldo"
	cGet1:= Space(17)
	oGet1:Picture:= PesqPict("SE2","E2_SALDO")
	cGet1:= 0
EndIf

oGet1:SetFocus()

Return

Static Function xVisuTRB()

Local 	aArea 		:= FWGetArea()
Private cCadastro 	:= OemToAnsi( "Visualizar" )

DBSelectArea("SE2")
SE2->(DBSetOrder(1))
SE2->(DBGoTo((_cAlias)->SE2RECNO))
AxVisual( "SE2", (_cAlias)->SE2RECNO, 2 )
FWRestArea( aArea )

Return

Static Function Cabecalho(impNrPag)

Local cRaizServer := If(issrvunix(), "/", "\")
Local cTitulo     := "Relação de títulos do contas a pagar - Rotina de alteração de vencimento do Título" 
 
nLinha:=0100

oPrint:SayBitmap(nLinha,nColInic,cRaizServer + "system/lgrl01.bmp",250,100)
If impNrPag <> 0
	oPrint:Say (nlinha,(nColInic + 2750),"PÁGINA: " + AllTrim(Str(nPagina)),oFont12b)
Else
	oPrint:Say (nlinha,(nColInic + 2750),"SIGA/MFIN003",oFont12b)
	oPrint:Say (nlinha + 100,(nColInic + 2750),"EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL),oFont12b)
EndIf
oPrint:Say (nlinha + 50,(nColInic + 2750),"DATA DE EMISSÃO: " + DToC(DATE()),oFont12b)
nlinha+=(nSaltoLinha * 3)

oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont16b,nColFinal,,,2)

nlinha+=nSaltoLinha
nlinha+=nSaltoLinha

oPrint:Line(nLinha,nColInic,nLinha,nColFinal)

nlinha+=nSaltoLinha
nlinha+=nSaltoLinha

Return

Static Function cabecDados()
 
nLinInBox:= nlinha
 
oPrint:FillRect({(nlinha+3),nColInic,nlinha + nSaltoLinha,nColFinal},oBrush)
 
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10   ,"Pref."          ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 160  ,"Numero"         ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 500  ,"Tipo"           ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 650  ,"Natureza"       ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 990  ,"Fornecedor"     ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1330 ,"Nome Fornecedor",oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1820 ,"Emissao"        ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2060 ,"Vencimento"     ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2350 ,"Venc.Real"      ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2890 ,"Valor"          ,oFont12b)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 3210 ,"Saldo"          ,oFont12b)

Return

Static Function prtDados(_cPref,_cNumTit,_cParcTit,_cTipoTit,_cNatur,_cFornec,_cLojaForn,_cNomeForn,_dDtEmis,_dDtVencto,_dDtVencRe,_nValor,_nSaldo)                 

oPrint:Say (nlinha + nAjuAltLi1,nColInic + 10   ,_cPref                                     ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 160  ,_cNumTit+'/'+_cParcTit                     ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 500  ,_cTipoTit                                  ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 650  ,_cNatur                                    ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 990  ,_cFornec+'/'+_cLojaForn                    ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1330 ,_cNomeForn                                 ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 1820 ,DToC(_dDtEmis)                             ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2060 ,DToC(_dDtVencto)                           ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2350 ,DToC(_dDtVencRe)                           ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2610 ,Transform(_nValor,"@E 999,999,999,999.99") ,oFont12)
oPrint:Say (nlinha + nAjuAltLi1,nColInic + 2930 ,Transform(_nSaldo,"@E 999,999,999,999.99") ,oFont12)

Return

Static Function boxDivisor()
      
oPrint:Line(nLinInBox,nColInic + 155 ,nLinha+nSaltoLinha,nColInic + 155 )
oPrint:Line(nLinInBox,nColInic + 495 ,nLinha+nSaltoLinha,nColInic + 495 )
oPrint:Line(nLinInBox,nColInic + 645 ,nLinha+nSaltoLinha,nColInic + 645 )
oPrint:Line(nLinInBox,nColInic + 985 ,nLinha+nSaltoLinha,nColInic + 985 )
oPrint:Line(nLinInBox,nColInic + 1325,nLinha+nSaltoLinha,nColInic + 1325)
oPrint:Line(nLinInBox,nColInic + 1815,nLinha+nSaltoLinha,nColInic + 1815)
oPrint:Line(nLinInBox,nColInic + 2055,nLinha+nSaltoLinha,nColInic + 2055)
oPrint:Line(nLinInBox,nColInic + 2345,nLinha+nSaltoLinha,nColInic + 2345)
oPrint:Line(nLinInBox,nColInic + 2685,nLinha+nSaltoLinha,nColInic + 2685)
oPrint:Line(nLinInBox,nColInic + 3025,nLinha+nSaltoLinha,nColInic + 3025)

oPrint:Box(nLinInBox ,nColInic,nLinha+nSaltoLinha,nColFinal) //Box Totalizador Descontos

Return

Static Function qbrPag(nLinhas,impBox,impCabec)

//Quebra de pagina
If nLinha > nqbrPagina
	nlinha:= nlinha - (nSaltoLinha * nLinhas)
	If impBox == 1
		boxDivisor()
	EndIf
	oPrint:EndPage()					// Finaliza a Pagina.
	oPrint:StartPage()					//Inicia uma nova Pagina
	nPagina++
	Cabecalho(1)
	If impCabec == 1
		cabecDados()
		nlinha+=nSaltoLinha
		oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	EndIf
EndIf
	
Return

/*
===============================================================================================================================
Programa----------: RelatSE2
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Imprime relação de títulos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/                          
Static Function RelatSE2

Local _aArea        := FWGetArea()

Private oFont10
Private oFont10b
Private oFont12
Private oFont12b
Private oFont16b
Private oFont14
Private oFont14b
Private oPrint
Private nPagina     := 1
Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 3360 
Private nqbrPagina  := 2200 
Private nLinInBox
Private nSaltoLinha := 50
Private nAjuAltLi1  := 11 //ajusta a altura de impressao dos dados do relatorio 
Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)

Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold   // Tamanho 14
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14
Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito

oPrint:= TMSPrinter():New( "ALTERA VENCIMENTO SE2" )
oPrint:SetPaperSize(9)	// Seta para papel A4
oPrint:SetLandscape() // Paisagem

(_cAlias)->(DBGoTop())

//Imprime o cabecalho e cabecalho de dados da primeira pagina
Cabecalho(0)

cabecDados()

While (_cAlias)->(!Eof())

	 nlinha+=nSaltoLinha
     oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
     qbrPag(1,1,1)

     prtDados((_cAlias)->E2_PREFIXO,(_cAlias)->E2_NUM,(_cAlias)->E2_PARCELA,(_cAlias)->E2_TIPO,(_cAlias)->E2_NATUREZ,;
              (_cAlias)->E2_FORNECE,(_cAlias)->E2_LOJA,(_cAlias)->E2_NOMFOR,(_cAlias)->E2_EMISSAO,(_cAlias)->E2_VENCTO,;
              (_cAlias)->E2_VENCREA,(_cAlias)->E2_VALOR,(_cAlias)->E2_SALDO)

	(_cAlias)->(DBSkip())
EndDo

oPrint:EndPage()
oPrint:Preview()

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AtualzTits
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Atualiza o campo da vencimento real dos registros do arquivo temporario de acordo com a data de vencimento
					real fornecida pelo usuario, isto diante de algumas validações
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AtualzTits() 

Local oGet1
Local dGet1   := Date()
Local oSay1
Local nOpca
Local oDlg

Local _aArea  := FWGetArea()

DEFINE MSDIALOG oDlg TITLE "ATUALIA TODOS OS TITULOS MARCADOS COM A DATA DE VENCIMENTO" FROM 000, 000  TO 150, 400 COLORS 0, 16777215 PIXEL

@ 027, 014 Say oSay1 PROMPT "Data de Vencimento:" SIZE 051, 010 OF oDlg COLORS 0, 16777215 PIXEL
@ 023, 067 MSGET oGet1 VAR dGet1 SIZE 094, 010 OF oDlg COLORS 0, 16777215 PIXEL

DEFINE SBUTTON FROM 052,042 Type 1 ENABLE ACTION (nOpca:=1,oDlg:End()) OF oDlg
DEFINE SBUTTON FROM 052,134 Type 2 ENABLE ACTION (nOpca:=0,oDlg:End()) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1
	//Efetua a validacao da data fornecida pelo usuario para constatar se nao caiu em um feriado sabado/Domingo, caso isso aconteca
	//a data sera incrementa para o proximo dia util disponivel
	dGet1:= DataValida(dGet1,.T.)
	//Caso nao encontre problemas para atualizar a data de vencimento no arquivo temporario
	If vldDtVenct(dGet1)
		//Atualiza no arquivo temporario todos os registros do arquivo temporario marcados com a data de vencimento fornecida
//		MsgRun("Inserindo os dados selecionados...",,{||CursorWait(),AtualVenRe(dGet1),CursorArrow()})
		Processa( {||AtualVenRe(dGet1)}/*bAction*/, "Aguarde..."/*cTitle */, "Validando data informada..."/*cMsg */,.F./*lAbort */)	
	EndIf
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: vldDtVenct
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Valida se nova data informada é válida
Parametros--------: dDtVencto
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function vldDtVenct(dDtVencto)

Local _lRet:= .T.

If Empty(dDtVencto)
	MsgStop("Favor fornecer uma data de vencimento válida antes de realizar este operação.","MFIN00302")
	_lRet:= .F.
EndIf

//Verifica se o usuario selecionou algum titulo para realizar a alteração da data de vencimento
If nQtdTit == 0 .And. _lRet
	MsgStop("Favor selecionar o(s) titulo(s) que deseja alterar a data de vencimento real."+;
			"Favor informar um ou mais titulos que deseja realizar esta operação.","MFIN00303")
	_lRet:= .F.  		
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AtualVenRe
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Valida se nova data informada é válida
Parametros--------: _dDtVencRe
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AtualVenRe(_dDtVencRe)

Local _aArea:= FWGetArea()
Local _lRet := .T.

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())
	//Somente registros marcados 
	If (_cAlias)->E2_STATUS == 'XX' 
		If _dDtVencRe < (_cAlias)->E2_EMISSAO 
		     MsgStop("Data de Vencimento Real Inválida fornecida para o título: " + (_cAlias)->E2_NUM + "/" + (_cAlias)->E2_PARCELA + " do Fornecedor: " + (_cAlias)->E2_FORNECE + "/" + (_cAlias)->E2_LOJA +;
					". Favor fornecer uma data de vencimento real maior que a data de emissão do título.","MFIN00304")
			_lRet:= .F.	
		EndIf 
		If (_dDtVencRe < (_cAlias)->E2_VENCTO) .And. _lRet
		     MsgStop("Data de Vencimento Real Inválida fornecida para o título: " + (_cAlias)->E2_NUM + "/" + (_cAlias)->E2_PARCELA + " do Fornecedor: " + (_cAlias)->E2_FORNECE + "/" + (_cAlias)->E2_LOJA +;
					". Favor fornecer uma data de vencimento real maior ou igual a data de vencimento do título.","MFIN00305")
			_lRet:= .F.
		EndIf
		If _lRet
			RecLock(_cAlias,.F.)
				(_cAlias)->E2_VENCREA:= _dDtVencRe 
			(_cAlias)->(MSUnLock())
		EndIf
	EndIf
     
	(_cAlias)->(DBSkip())
EndDo

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: vldAlter
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Valida se foram selecionados títulos
Parametros--------: nQtdTit -> quantidade de títulos selecionados
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function vldAlter(nQtdTit)

Local _lRet:= .T.

If nQtdTit == 0
	MsgStop("Favor selecionar um ou mais títulos antes de realizar esta operação."+;
            "Favor proceder de acordo com a solicitação efetuada acima, qualquer dúvida favor entrar em contato com o depto de informática.","MFIN00306")
	_lRet:= .F.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: desarmTit
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Libera títulos lockados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function desarmTit()

DBSelectArea("SE2")
(_cAlias)->( DBGoTop() )
While (_cAlias)->(!Eof())
	SE2->( DBGoTo((_cAlias)->SE2RECNO) )
	SE2->(MSUnLock())	
	(_cAlias)->( DBSkip() )
EndDo

Return

/*
===============================================================================================================================
Programa----------: procAltVen
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 02/09/2010
Descrição---------: Altera via siga-auto a data de vencimento real do titulo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function procAltVen()

Local _aArea        := FWGetArea()
Local _nModOld      := nModulo
Local _cModOld      := cModulo
Local _aAutoSE2     := {}

Private lMsErroAuto := .F.

(_cAlias)->(DBGoTop())

While (_cAlias)->(!Eof())

	//Somente registros marcados 
	If (_cAlias)->E2_STATUS == 'XX' 

		DBSelectArea("SE2")
		SE2->( DBGoTo((_cAlias)->SE2RECNO) )

		SE2->(MSUnLock())
		nModulo		:= 6
		cModulo 	:= "FIN"

		_aAutoSE2:={}

		aAdd( _aAutoSE2, { "E2_FILIAL"	, xFilial("SE2") , nil } )
		aAdd( _aAutoSE2, { "E2_PREFIXO"	, (_cAlias)->E2_PREFIXO, nil } )
		aAdd( _aAutoSE2, { "E2_NUM"		, (_cAlias)->E2_NUM   , nil } )
		aAdd( _aAutoSE2, { "E2_PARCELA"	, (_cAlias)->E2_PARCELA, nil } )
		aAdd( _aAutoSE2, { "E2_TIPO"	, (_cAlias)->E2_TIPO  , nil } )
		aAdd( _aAutoSE2, { "E2_NATUREZ"	, (_cAlias)->E2_NATUREZ, nil } )
		aAdd( _aAutoSE2, { "E2_FORNECE"	, (_cAlias)->E2_FORNECE, nil } )
		aAdd( _aAutoSE2, { "E2_LOJA"	, (_cAlias)->E2_LOJA  , nil } )
		aAdd( _aAutoSE2, { "E2_EMISSAO"	, (_cAlias)->E2_EMISSAO, nil } )
		aAdd( _aAutoSE2, { "E2_VENCTO"	, (_cAlias)->E2_VENCTO, nil } )
		aAdd( _aAutoSE2, { "E2_VENCREA"	, DataValida((_cAlias)->E2_VENCREA), nil } )
		aAdd( _aAutoSE2, { "E2_VALOR"	, (_cAlias)->E2_VALOR , nil } )

		lMsErroAuto := .F.
		MSExecAuto({|x,y,z| Fina050(x,y,z)},_aAutoSE2,,4) //Alteracao

		If lMsErroAuto
			MsgStop("Erro ao alterar o seguinte título: " + (_cAlias)->E2_NUM+'/'+(_cAlias)->E2_PARCELA + " do Fornecedor: " +(_cAlias)->E2_FORNECE + "/" + (_cAlias)->E2_LOJA,"MFIN00307")
			mostraerro()
		EndIf

		nModulo := _nModOld
		cModulo := _cModOld

	EndIf

	(_cAlias)->(DBSkip())

EndDo

FWRestArea(_aArea)  

Return
