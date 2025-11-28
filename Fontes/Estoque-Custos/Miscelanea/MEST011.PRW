/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |27/04/2017| Chamado 19813. Inclusão da função de Log ITLOGACS().
Josué Danich  |11/06/2019| Chamado 29593. Ajustes para loboguara
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST011
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/01/2015
Descrição---------: Geração planilhas de suporte ao fechamento de custo médio - Chamado 9696
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST011()


Local _cPerg   	:="MEST011"
Local _bprocess	:= nil
Local _oprocess	:= nil

Private _lsai		:= .F.

While .not. _lsai
	_lsai := .T.
	//============================================
	//Cria interface principal
	//============================================
	_bProcess    := {|_oprocess| MEST011PR(_oprocess) }
	tNewProcess():New( _cPerg, "Geração de planilhas de suporte ao fechamento de custo",;
								 _bProcess, "Rotina de geracao de planilhas de suporte ao fechamento de custo","MEST011")
EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011PR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Processamento principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011PR(_oProcess)

Local _cHRINI		:= Time()
Local _aSTRU		:= {}
Local _cARQTMPES	:= ""
Local _cARQTMP	:= ""
Private MV_PAR07 	:= 2 //Definido aqui para poder trabalhar sem a pergunta no SX1 quando necessário

Private _nSeqCalc	:=StrZero(1,10)

_lsai := .F.  //Se veio para rotina não sai da tela principal

If MV_PAR07==1
	_oProcess:SetRegua2(11)
Else
	_oProcess:SetRegua2(10)
EndIf

_oProcess:IncRegua2("Saldos Iniciais")
ProcessMessages()
_oProcess:SaveLog( "Iniciada geração de planilhas - " + DToC(date()) + " - " + _cHrini + " - " + cUserName )

If LastKey() == 27
	Return
EndIf

aAdd(_aSTRU,{"ARMAZ"      ,"C", 02,0})
aAdd(_aSTRU,{"PRODUTO"    ,"C", 15,0})
aAdd(_aSTRU,{"TIPO"       ,"C", 02,0})
aAdd(_aSTRU,{"GRUPO"      ,"C", 02,0})
aAdd(_aSTRU,{"UNMED"      ,"C", 05,0})
aAdd(_aSTRU,{"DATASLD"    ,"D", 08,0})
aAdd(_aSTRU,{"QTDE"       ,"N", 12,2})
aAdd(_aSTRU,{"CUSTO"      ,"N", 14,2})
aAdd(_aSTRU,{"CMCALC"     ,"N", 20,4})
aAdd(_aSTRU,{"CST_SIGA"   ,"N", 12,2})
aAdd(_aSTRU,{"CM_SIGA"    ,"N", 14,4})
aAdd(_aSTRU,{"QTDE_CALC"  ,"N", 14,2})
aAdd(_aSTRU,{"CSTQ_CALC"  ,"N", 20,2})
aAdd(_aSTRU,{"DIF_CST"    ,"N", 14,2})  //CUSTO - CST_SIGA
aAdd(_aSTRU,{"PVAR_CM"    ,"N", 14,2})  // % DE VARIACAO DO CUSTO MÉDIO(CMCALC) EM RELACAO AO HISTÓRICO(HIST_CM)

If Select("TEMPOES") <> 0
	TEMPOES->(DBCloseArea())
EndIf

_otemp := FWTemporaryTable():New( "TEMPOES", _aSTRU)

_otemp:AddIndex( "01", {"ARMAZ", "PRODUTO","DATASLD"} )
_otemp:Create()

_aSTRU:={}
aAdd(_aSTRU,{"ARMAZ"      ,"C", 02,0})
aAdd(_aSTRU,{"PRODUTO"    ,"C", 15,0})
aAdd(_aSTRU,{"TIPO"       ,"C", 02,0})
aAdd(_aSTRU,{"GRUPO"      ,"C", 02,0})
aAdd(_aSTRU,{"UNMED"      ,"C", 05,0})
aAdd(_aSTRU,{"DATAMOV"    ,"D", 08,0})
aAdd(_aSTRU,{"DOC"        ,"C", 09,0})
aAdd(_aSTRU,{"SIGA_CF"    ,"C", 03,0})
aAdd(_aSTRU,{"SIGA_TPMOV" ,"C", 03,0})
aAdd(_aSTRU,{"OP"         ,"C", 13,0})
aAdd(_aSTRU,{"QTDE"       ,"N", 12,2})
aAdd(_aSTRU,{"VLRSIGA"    ,"N", 12,2})
aAdd(_aSTRU,{"VLRCALC"    ,"N", 20,2})
aAdd(_aSTRU,{"CMCALC"     ,"N", 20,4})
aAdd(_aSTRU,{"PRIORIDADE" ,"C", 03,0})
aAdd(_aSTRU,{"TRANSACAO"  ,"C", 04,0})
aAdd(_aSTRU,{"NUMSEQ"     ,"C", 06,0})
aAdd(_aSTRU,{"SEQCALCULO" ,"C", 10,0})

aAdd(_aSTRU,{"ORIGEM"     ,"C", 03,0})
aAdd(_aSTRU,{"TIPONF"     ,"C", 01,0})
aAdd(_aSTRU,{"QTDACM"     ,"N", 14,2})
aAdd(_aSTRU,{"CSTACM"     ,"N", 24,2})
aAdd(_aSTRU,{"CMACM"      ,"N", 20,4})
aAdd(_aSTRU,{"TES"        ,"C",  3,0})
aAdd(_aSTRU,{"TES_PODER3" ,"C",  1,0})
aAdd(_aSTRU,{"IDENTB6"    ,"C",  6,0})
aAdd(_aSTRU,{"USUARIO"    ,"C", 15,0})  // USUÁRIO QUE EFETUOU O LANÇAMENTO (SD3)

If Select("TEMPO") <> 0
	TEMPO->(DBCloseArea())
EndIf

_otemp := FWTemporaryTable():New( "TEMPO", _aSTRU)

_otemp:AddIndex( "01", {"ARMAZ", "PRODUTO","DATAMOV","SEQCALCULO"} )
_otemp:AddIndex( "02", {"OP", "PRIORIDADE","DATAMOV","SEQCALCULO"} )
_otemp:AddIndex( "03", {"OP", "DATAMOV"} )
_otemp:Create()

MEST011B9(_oProcess)

_oProcess:IncRegua2("Notas de Entrada")
ProcessMessages()
MEST011D1(_oProcess)

_oProcess:IncRegua2("Movtos Internos") 
ProcessMessages()
MEST011D3(_oProcess)

_oProcess:IncRegua2("Notas de saída") 
ProcessMessages()
MEST011D2(_oProcess)

_oProcess:IncRegua2("Calculo 1/4") 
ProcessMessages()
MEST011PV(_oProcess)

_oProcess:IncRegua2("Calculo 2/4") 
ProcessMessages()
MEST011PV(_oProcess)

_oProcess:IncRegua2("Calculo 3/4") 
ProcessMessages()
MEST011PV(_oProcess)

_oProcess:IncRegua2("Calculo 4/4") 
ProcessMessages()
MEST011PV(_oProcess)

_oProcess:IncRegua2("Gera saldos finais") 
ProcessMessages()
MEST011GE(_oProcess)

If MV_PAR07==1
	_oProcess:IncRegua2("Limpando Armazens") 
	ProcessMessages()
	MEST011LA(_oProcess)
EndIf

//Gera arquivo de exportação
_oProcess:IncRegua2("Gerando planilhas") 
ProcessMessages()
MEST011GA(_cARQTMP,_cARQTMPES,_cHRINI,_oprocess)

//========================================================================
// Grava log de Geração planilhas de suporte ao fechamento de custo médio
//======================================================================== 
U_ITLOGACS('MEST011')

Return

/*
===============================================================================================================================
Programa----------: MEST011B9
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Carga de dados do SB9
Parametros--------: _oProcess - Objeto da tela principal
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011B9(_oProcess)

Local _dDtAux	:= MV_PAR01-1

SB1->(DBSetOrder(1))

DBSelectArea("SB9")
SB9->(DBSetOrder(3))

_oProcess:SetRegua1(SB9->(RecCount()))

SB9->(DBSeek(xFilial("SB9")+DToS(_dDtAux),.T.))

While (xFilial("SB9")+DToS(SB9->B9_DATA)==xFilial("SB9")+DToS(_dDtAux)) .And. (! Eof())

	_oProcess:IncRegua1("Data-Produto: " + DToC(SB9->B9_DATA) + "-" + SB9->B9_COD)//Incrementa primeira régua
	ProcessMessages()
	
	If (SB9->B9_DATA <> _dDtAux)
		DBSkip()
		Loop
	EndIf

	DBSelectArea("TEMPO")
	DBAppend()
	_FIELD->ARMAZ      := SB9->B9_LOCAL
	_FIELD->PRODUTO    := SB9->B9_COD
	_FIELD->TIPO       := RETFIELD("SB1",1,xFilial("SB1")+SB9->B9_COD,"SB1->B1_TIPO")
	_FIELD->GRUPO      := RETFIELD("SB1",1,xFilial("SB1")+SB9->B9_COD,"SB1->B1_GRUPO")
	_FIELD->UNMED      := RETFIELD("SB1",1,xFilial("SB1")+SB9->B9_COD,"SB1->B1_UM")
	_FIELD->DATAMOV    := SB9->B9_DATA
	_FIELD->DOC        := ""
	_FIELD->OP         := ""
	_FIELD->SIGA_CF    := ""
	_FIELD->SIGA_TPMOV := ""
	_FIELD->QTDE       := SB9->B9_QINI
	_FIELD->VLRSIGA    := SB9->B9_VINI1
	_FIELD->VLRCALC    := SB9->B9_VINI1
	_FIELD->CMCALC     := (VLRCALC/QTDE)
	_FIELD->PRIORIDADE := "100"
	_FIELD->TRANSACAO  := StrZero(1,4)   //4 DIGITOS
	_FIELD->NUMSEQ     := "000000"
	_FIELD->SEQCALCULO := _nSeqCalc
	_FIELD->ORIGEM     := "SB9"
	
	_nSeqCalc	:= StrZero( (Val(_nSeqCalc) + 1) ,10)
	
	SB9->(DBSkip())	
EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011D1
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Carga de dados do SD1
Parametros--------: _oProcess - Objeto da tela principal
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MEST011D1(_oProcess)

Local _aAREAD1 := {}
Local _aAREAD2 := {}
Local _nAREAANT := ""

SB1->(DBSetOrder(1))
SF4->(DBSetOrder(1))

DBSelectArea("SD1")
SD1->(DBSetOrder(6))

_oProcess:SETREGUA1(SD1->(RecCount()))

SD1->(DBSeek(xFilial("SD1")+DToS(MV_PAR01),.T.))

While (D1_FILIAL+DToS(D1_DTDIGIT)<=xFilial("SD1")+DToS(MV_PAR02)) .And. (! Eof())

	_oProcess:INCREGUA1("Data: "+DToC(D1_DTDIGIT))
	ProcessMessages()
	SF4->(DBSeek(xFilial("SF4")+SD1->D1_TES))

	If (SF4->F4_ESTOQUE<>"S") .Or. (RTrim(SD1->D1_COD)=="SERVICOS")
		SD1->(DBSkip())
		Loop
	EndIf

	DBSelectArea("TEMPO")
	DBAppend()
	_FIELD->ARMAZ      := SD1->D1_LOCAL
	_FIELD->PRODUTO    := SD1->D1_COD
	_FIELD->TIPO       := RETFIELD("SB1",1,xFilial("SB1")+SD1->D1_COD,"SB1->B1_TIPO")
	_FIELD->GRUPO      := RETFIELD("SB1",1,xFilial("SB1")+SD1->D1_COD,"SB1->B1_GRUPO")
	_FIELD->UNMED      := RETFIELD("SB1",1,xFilial("SB1")+SD1->D1_COD,"SB1->B1_UM")
	_FIELD->DATAMOV    := SD1->D1_DTDIGIT
	_FIELD->DOC        := SD1->D1_DOC
	_FIELD->OP         := ""
	_FIELD->SIGA_CF    := ""
	_FIELD->SIGA_TPMOV := ""
	_FIELD->QTDE       := SD1->D1_QUANT
	_FIELD->VLRSIGA    := SD1->D1_CUSTO

	If RTrim(SD1->D1_TIPO)=="D"

		_FIELD->VLRCALC   := SD1->D1_CUSTO  // Alterado para sempre pegar o custo do siga que é sempre igual ao da NF original.
		_FIELD->CMCALC    := (VLRCALC/QTDE) //      ||
		_FIELD->TRANSACAO := StrZero(300,4)   //4 DIGITOS
		
		If (VLRCALC==0)  //2010 07 01  QDO DEV E O CUSTO For ZERO VAI BUSCAR CUSTO MEDIO DA NF ORIGEM SE A MESMA EXISTIR NO SD2

			_nAREAANT	:=	SELECT()
			_aAREAD1	:=	SD1->(GETAREA())
			_aAREAD2	:=	SD2->(GETAREA())
			
			SD2->(DBSetOrder(3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
			SD2->(DBSeek(xFilial("SD2") + RTrim(SD1->D1_NFORI + SD1->D1_SERIORI + SD1->D1_FORNECE + SD1->D1_LOJA + SD1->D1_COD + SD1->D1_ITEMORI)))

			If SD2->D2_FILIAL + SD2->D2_DOC + SD2->D2_SERIE + SD2->D2_CLIENTE + SD2->D2_LOJA + SD2->D2_COD + SD2->D2_ITEM == ;
					xFilial("SD2") + RTrim(SD1->D1_NFORI + SD1->D1_SERIORI + SD1->D1_FORNECE + SD1->D1_LOJA + SD1->D1_COD + SD1->D1_ITEMORI)
				_FIELD->CMCALC    := SD2->(D2_CUSTO1/D2_QUANT)
				_FIELD->VLRCALC   := _FIELD->CMCALC * SD1->D1_QUANT
			EndIf

			FWRestArea(_aAREAD1)
			FWRestArea(_aAREAD2)
			
			DBSelectArea(_nAREAANT)

		EndIf
		
	Else

		_FIELD->VLRCALC   := SD1->D1_CUSTO
		_FIELD->CMCALC    := (_FIELD->VLRCALC / _FIELD->QTDE)
		_FIELD->TRANSACAO := StrZero(100,4)   //4 DIGITOS

	EndIf

	_FIELD->PRIORIDADE := "100"
	_FIELD->NUMSEQ     := SD1->D1_NUMSEQ
	_FIELD->SEQCALCULO := _nSeqCalc
	_FIELD->ORIGEM     := "SD1"
	_FIELD->TIPONF     := SD1->D1_TIPO
	
	_FIELD->TES        := SD1->D1_TES
	_FIELD->TES_PODER3 := SF4->F4_PODER3
	_FIELD->IDENTB6    := SD1->D1_IDENTB6
	
	_nSeqCalc	:= StrZero( (Val(_nSeqCalc) + 1) ,10)
	
	SD1->( DBSkip() )

EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011D3
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Carga de dados do SD3
Parametros--------: _oProcess - objeto da tela principal
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MEST011D3(_oProcess)

Local _cDocAce	:= "AC"+SubStr(DToS(MV_PAR02),3,4)
Local _cTmpVal		:= ""

SB1->(DBSetOrder(1))

DBSelectArea("SD3")
SD3->(DBSetOrder(6))

_oProcess:Setregua1(SD3->(RecCount()))

SD3->(DBSeek(xFilial("SD3") + DToS(MV_PAR01),.T.))

While (SD3->D3_FILIAL + DToS(SD3->D3_EMISSAO) <= xFilial("SD3") + DToS(MV_PAR02)) .And. (! Eof())

	_oProcess:INCREGUA1("Data: " + DToC(SD3->D3_EMISSAO))
	ProcessMessages()
	
	_cTmpVal := RETFIELD("SF5",1,xFilial("SF5") + SD3->D3_TM,"SF5->F5_VAL")
	
	If (SD3->D3_ESTORNO == "S") .Or. ( ( _cTmpVal == "S" .And. SD3->D3_QUANT == 0) .And. (MV_PAR05 == 2) )
		SD3->( DBSkip() )
		Loop
	EndIf
	
	DBSelectArea("TEMPO")
	DBAppend()
	_FIELD->ARMAZ     := SD3->D3_LOCAL
	_FIELD->PRODUTO   := SD3->D3_COD
	_FIELD->TIPO      := RETFIELD("SB1",1,xFilial("SB1") + SD3->D3_COD,"SB1->B1_TIPO")
	_FIELD->GRUPO     := RETFIELD("SB1",1,xFilial("SB1") + SD3->D3_COD,"SB1->B1_GRUPO")
	_FIELD->UNMED     := RETFIELD("SB1",1,xFilial("SB1") + SD3->D3_COD,"SB1->B1_UM")
	_FIELD->DATAMOV   := SD3->D3_EMISSAO
	_FIELD->DOC       := SD3->D3_DOC
	_FIELD->OP        := SD3->D3_OP
	_FIELD->SIGA_CF   := SD3->D3_CF
	_FIELD->SIGA_TPMOV:= SD3->D3_TM
	_FIELD->QTDE      := SD3->D3_QUANT
	_FIELD->VLRSIGA   := SD3->D3_CUSTO1
	
	
	If _cTmpVal == "S" .And. _FIELD->QTDE > 0
		_FIELD->VLRCALC   := SD3->D3_CUSTO1
		_FIELD->CMCALC    := (SD3->D3_CUSTO1 / SD3->D3_QUANT)
	ElseIf _cTmpVal == "S" .And. (MV_PAR05 == 1 .And. _FIELD->QTDE == 0) .And. RTrim(_FIELD->DOC) <> _cDocAce
		_FIELD->VLRCALC   := SD3->D3_CUSTO1
		_FIELD->CMCALC    := (SD3->D3_CUSTO1 / SD3->D3_QUANT)
	Else
		_FIELD->VLRCALC   := 0
		_FIELD->CMCALC    := 0
	EndIf
	
	If SubStr(_FIELD->SIGA_CF,1,2)=="RE" .And. ! Empty(_FIELD->OP)
		_FIELD->PRIORIDADE:="098"
	ElseIf SubStr(_FIELD->SIGA_CF,1,2)=="DE" .And. ! Empty(_FIELD->OP)
		_FIELD->PRIORIDADE:="099"
	Else
		_FIELD->PRIORIDADE:="100"
	EndIf
	
	_FIELD->TRANSACAO  := StrZero(100,4)
	_FIELD->NUMSEQ     := SD3->D3_NUMSEQ
	_FIELD->SEQCALCULO := _nSeqCalc
	_FIELD->ORIGEM     := "SD3"
	_FIELD->USUARIO    := SD3->D3_USUARIO
	
	_nSeqCalc:=StrZero( (Val(_nSeqCalc) + 1) ,10)

	SD3->(DBSkip())
EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011D2
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Carga de dados do SD2
Parametros--------: _oProcess - objeto da tela principal
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011D2(_oProcess)

Local _aDescarta	:= {}  //MATRIZ REF. MOVTOS QUE PROVAVELMENTE NÃO EFETUARAM MOVTO DE ESTOQUE NA ÉPOCA
Local _nRetAux	:= 0

aAdd(_aDescarta,"699812")
aAdd(_aDescarta,"699814")

aSort(_aDescarta)

SB1->(DBSetOrder(1))
SF4->(DBSetOrder(1))

DBSelectArea("SD2")
SD2->( DBSetOrder(5) )

_oProcess:Setregua1(SD2->(RecCount()))


SD2->(DBSeek(xFilial("SD2")+DToS(MV_PAR01),.T.))

While (SD2->D2_FILIAL + DToS(SD2->D2_EMISSAO) <= xFilial("SD2") + DToS(MV_PAR02)) .And. (!(SD2->(Eof())))

	SF4->(DBSeek(xFilial("SF4") + SD2->D2_TES))
	
	_oProcess:INCREGUA1("Data: " + DToC(SD2->D2_EMISSAO))
	ProcessMessages()
	_nRetAux:=aScan(_aDescarta,SD2->D2_NUMSEQ)

	If (SF4->F4_ESTOQUE<>"S") .Or. _nRetAux>0
		SD2->( DBSkip() )
		Loop
	EndIf
	
	DBSelectArea("TEMPO")
	DBAppend()
	_FIELD->ARMAZ      := SD2->D2_LOCAL
	_FIELD->PRODUTO    := SD2->D2_COD
	_FIELD->TIPO       := RETFIELD("SB1",1,xFilial("SB1") + SD2->D2_COD,"SB1->B1_TIPO")
	_FIELD->GRUPO      := RETFIELD("SB1",1,xFilial("SB1") + SD2->D2_COD,"SB1->B1_GRUPO")
	_FIELD->UNMED      := RETFIELD("SB1",1,xFilial("SB1") + SD2->D2_COD,"SB1->B1_UM")
	_FIELD->DATAMOV    := SD2->D2_EMISSAO
	_FIELD->DOC        := SD2->D2_DOC
	_FIELD->OP         := ""
	_FIELD->SIGA_CF    := ""
	_FIELD->SIGA_TPMOV := ""
	_FIELD->QTDE       := SD2->D2_QUANT
	_FIELD->VLRSIGA    := SD2->D2_CUSTO1
	_FIELD->VLRCALC    := 0
	_FIELD->CMCALC     := 0
	
	
	If RTrim(SD2->D2_TIPO)=="D"  //dev COMPRAS
		_FIELD->TRANSACAO :=StrZero(1000,4)   //4 DIGITOS
	Else
		_FIELD->TRANSACAO :=StrZero(1500,4)   //4 DIGITOS
	EndIf

	_FIELD->PRIORIDADE := "100"
	_FIELD->NUMSEQ     := SD2->D2_NUMSEQ
	_FIELD->SEQCALCULO := _nSeqCalc
	_FIELD->ORIGEM     := "SD2"
	_FIELD->TIPONF     := SD2->D2_TIPO
	
	_FIELD->TES        := SD2->D2_TES
	_FIELD->TES_PODER3 := SF4->F4_PODER3
	_FIELD->IDENTB6    := SD2->D2_IDENTB6
	
	_nSeqCalc := StrZero( (Val(_nSeqCalc) + 1) ,10)
	
	SD2->( DBSkip() )

EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011PV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Calculo de valorização
Parametros--------: _oProcess - objeto da tela principal					  
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011PV(_oProcess)

Local _aCstSiga	:=	{}
Local _aCstFixo	:=	{}   //MATRIZ PARA GUARDAR O CASO DE CUSTO FIXO   INFORMAR   { NUMSEQ , CM UNITÁRIO }
Local _cArmaz		:=	""
Local _cProd 		:= 	""
Local _nQtde 		:=	0
Local _nCST  		:=	0
Local _nCM   		:=	0
Local _nAcMaux	:= 	0
Local _cTmTipo	:= 	""
Local _cNumSeq 	:= 	""
Local _nVlrRE4 	:= 	0
Local _nRegAux 	:= 	0
Local _nOrdAux 	:= 	0

aAdd(_aCstSiga,"99HG3X")
aAdd(_aCstSiga,"99HG58")
aAdd(_aCstSiga,"99HG5D")
aAdd(_aCstSiga,"99HG5G")
aAdd(_aCstSiga,"99HCXQ")
aAdd(_aCstSiga,"99HCXR")
// FIM 2010 12

// INICIO 2011 03
aAdd(_aCstSiga,"99HWSW")
// FIM 2011 03

// INICIO 2011 04
aAdd(_aCstSiga,"99IBZB")
// FIM 2011 04

// INICIO 2013 11
aAdd(_aCstSiga,"9A8WFV")
// FIM 2013 11

aSort(_aCstSiga)
aSort(_aCstFixo,,,{|X,Y| X[1]<Y[1]})

DBSelectArea("TEMPO")
TEMPO->( DBSetOrder(2) )
TEMPO->( DBGoTop() )

_oProcess:SETREGUA1(RecCount())

_cArmaz:=	TEMPO->ARMAZ
_cProd :=	TEMPO->PRODUTO
_nQtde :=	0
_nCST  :=	0
_nCM   :=	0

While ! TEMPO->( Eof() )

	_oProcess:INCREGUA1("ARMAZ-PROD:" + TEMPO->ARMAZ + "-" + TEMPO->PRODUTO)
	ProcessMessages()
	
	If TEMPO->ORIGEM=="SB9" .Or. TEMPO->ORIGEM=="B9C"

		_FIELD->QTDACM := TEMPO->QTDE
		_FIELD->CSTACM := TEMPO->VLRCALC
		_nAcMaux := (TEMPO->VLRCALC / TEMPO->QTDE)

		If _nAcMaux > 99999999999.9999 .Or. _nAcMaux < -99999999999.9999
			_nAcMaux := 99999999999.9999
		EndIf

		_FIELD->CMACM := _nAcMaux
		
		_nQtde := _nQtde + TEMPO->QTDE
		_nCST  := _nCST + TEMPO->VLRCALC
		_nCM   := (_nCST / _nQtde)
		
		
	ElseIf (TEMPO->ORIGEM=="SD1")

		If (TEMPO->TIPONF == "N") .Or. (TEMPO->TIPONF == "C") .Or. (TEMPO->TIPONF == "D") 
			
			If (aScan(_aCstSiga,TEMPO->NUMSEQ)>0)
				_FIELD->VLRCALC := TEMPO->VLRSIGA
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			Else
				_nRetAux:=aScan(_aCstFixo,{|x| Upper(AllTrim(x[1])) == TEMPO->NUMSEQ})
				If _nRetAux>0
					_FIELD->CMCALC :=_aCstFixo[_nRetAux,2]
					_FIELD->VLRCALC:=(TEMPO->QTDE * TEMPO->CMCALC)
				EndIf
			EndIf
			
			_nQtde := _nQtde + TEMPO->QTDE
			_nCST  := _nCST + TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			_nCM  :=(_nCST / _nQtde)
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM :=_nCM

		Else

			If (aScan(_aCstSiga,TEMPO->NUMSEQ)>0)
				_FIELD->VLRCALC := TEMPO->VLRSIGA
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			Else
				_FIELD->VLRCALC := (TEMPO->QTDE * _nCM)
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			EndIf
			
			_nQtde := _nQtde + TEMPO->QTDE
			_nCST  := _nCST + TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			_nCM  :=(_nCST / _nQtde)
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			_FIELD->CMACM := _nCM
		EndIf

	ElseIf TEMPO->ORIGEM == "SD2"
		If (aScan(_aCstSiga, TEMPO->NUMSEQ) > 0)
			_FIELD->VLRCALC := TEMPO->VLRSIGA
			_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
		Else
			_nRetAux:=aScan(_aCstFixo,{|x| Upper(AllTrim(x[1])) == TEMPO->NUMSEQ})
			If _nRetAux > 0
				_FIELD->CMCALC  := _aCstFixo[_nRetAux,2]
				_FIELD->VLRCALC := (TEMPO->QTDE * TEMPO->CMCALC)
			Else
				_FIELD->VLRCALC := (TEMPO->QTDE *_nCM)
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			EndIf
		EndIf
		
		_nQtde := _nQtde - TEMPO->QTDE
		_nCST  := _nCST - TEMPO->VLRCALC
		
		// Custo acumulado nunca pode ficar negativo
		If _nCST < 0 .Or. _nQtde < 0
			_nCST := 0
		EndIf
		
		If _nQtde<>0    //Sempre que houve movimentação de quantidade deve atualizar o custo médio
			_nCM  :=(_nCST / _nQtde)
		EndIf
		
		_FIELD->QTDACM := _nQtde
		_FIELD->CSTACM := _nCST
		
		If _nCM > 99999999999.9999 .Or. _nCM <- 99999999999.9999
			_nCM := 99999999999.9999
		EndIf
		
		_FIELD->CMACM :=_nCM

	ElseIf TEMPO->ORIGEM == "SD3"
		_cTmpVal := RETFIELD("SF5",1,xFilial("SF5") + SIGA_TPMOV,"SF5->F5_VAL")
		_cTmTipo := RETFIELD("SF5",1,xFilial("SF5") + SIGA_TPMOV,"SF5->F5_TIPO")
		
		If _cTmpVal == "S" .And. _cTmTipo == "D" //ENTR VALORIZ COM QTDE  OU SEM QTDE DESDE QUE MV_PAR05==1
			_nQtde:=_nQtde + TEMPO->QTDE
			_nCST :=_nCST + TEMPO->VLRCALC
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			_nCM  :=(_nCST /_nQtde)
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			_FIELD->CMACM  := _nCM
			
		ElseIf _cTmpVal == "S" .And. _cTmTipo == "R"
			_nQtde := _nQtde - TEMPO->QTDE
			_nCST  := _nCST - TEMPO->VLRCALC
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			If _nQtde <> 0    //Sempre que houve movimentação de quantidade deve atualizar o custo médio
				_nCM  :=(_nCST / _nQtde)
			EndIf
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM := _nCM

		ElseIf TEMPO->SIGA_CF $ "RE0/RE1" //REQUISICAO - INVETARIO SAIDA
			If (aScan(_aCstSiga,TEMPO->NUMSEQ) > 0)
				_FIELD->VLRCALC := TEMPO->VLRSIGA
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			Else
				_FIELD->VLRCALC := (TEMPO->QTDE * _nCM)

				If _nCST <  _FIELD->VLRCALC        // Sendo uma saída, se o custo acumulado For menor que a saída, usar o valor acumulado
					_FIELD->VLRCALC := _nCST
				EndIf
				_FIELD->CMCALC :=(TEMPO->VLRCALC / TEMPO->QTDE)
			EndIf
			
			_nQtde := _nQtde - TEMPO->QTDE
			_nCST  := _nCST - TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			If _nQtde <> 0    //Sempre que houve movimentação de quantidade deve atualizar o custo médio
				_nCM  := (_nCST / _nQtde)
			EndIf
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM := _nCM
			
		ElseIf TEMPO->SIGA_CF $ "DE0/DE1"  //DEVOL REQUISICAO - INVENTARIO ENTR
			If (aScan(_aCstSiga,TEMPO->NUMSEQ) > 0)
				_FIELD->VLRCALC := TEMPO->VLRSIGA
				_FIELD->CMCALC := (TEMPO->VLRCALC / TEMPO->QTDE)
			Else
				_nRetAux:=aScan(_aCstFixo,{|x| Upper(AllTrim(x[1])) == TEMPO->NUMSEQ})
				If _nRetAux > 0
					_FIELD->CMCALC  := _aCstFixo[_nRetAux,2]
					_FIELD->VLRCALC := (TEMPO->QTDE * TEMPO->CMCALC)
				Else
					If _nCM <> 0
						_FIELD->VLRCALC:=(TEMPO->QTDE * _nCM)
					Else
						_FIELD->VLRCALC := TEMPO->VLRSIGA
					EndIf
					_FIELD->CMCALC :=(TEMPO->VLRCALC / TEMPO->QTDE)
				EndIf
			EndIf
			
			_nQtde := _nQtde + TEMPO->QTDE
			_nCST  := _nCST + TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			_nCM  :=(_nCST / _nQtde)
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM :=_nCM

		ElseIf TEMPO->SIGA_CF $ "RE4"
			If (aScan(_aCstSiga,TEMPO->NUMSEQ) > 0)
				_FIELD->VLRCALC := TEMPO->VLRSIGA
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			Else
				_FIELD->VLRCALC := (TEMPO->QTDE * _nCM)
				If _nCST < _FIELD->VLRCALC        // Sendo uma saída, se o custo acumulado For menor que a saída, usar o valor acumulado
					_FIELD->VLRCALC := _nCST
				EndIf
				_FIELD->CMCALC :=(TEMPO->VLRCALC / TEMPO->QTDE)
			EndIf
			
			_nQtde := _nQtde - TEMPO->QTDE
			_nCST  := _nCST - TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			If _nQtde <> 0    //Sempre que houve movimentação de quantidade deve atualizar o custo médio
				_nCM  := (_nCST / _nQtde)
			EndIf
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
		
			_FIELD->CMACM := _nCM

		ElseIf TEMPO->SIGA_CF $ "DE4"

			_cProdORI :=""
			_cNumSeq := TEMPO->NUMSEQ
			_nVlrRE4 := 0
			_nRegAux := Recno()
			_nOrdAux := INDEXORD()
			
			TEMPO->( DBSetOrder(1))
			TEMPO->( DBSeek(_cNumSeq))

			While TEMPO->NUMSEQ == _cNumSeq .And. ! TEMPO->(Eof())
				If TEMPO->SIGA_CF == "RE4"
					_cProdORI := TEMPO->PRODUTO
					_nVlrRE4  := TEMPO->VLRCALC
					Exit
				EndIf
				TEMPO->(DBSkip())
			EndDo
			
			TEMPO->(DBSetOrder(_nOrdAux))
			TEMPO->(DBGoTo(_nRegAux))
			
			_FIELD->VLRCALC := _nVlrRE4
			_FIELD->CMCALC := (TEMPO->VLRCALC / TEMPO->QTDE)
			
			_nQtde := _nQtde + TEMPO->QTDE
			_nCST  := _nCST + TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			_nCM  :=(_nCST / _nQtde)
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM := _nCM

		ElseIf TEMPO->SIGA_CF $ "PR0"
			If (aScan(_aCstSiga,TEMPO->NUMSEQ) > 0)
				_FIELD->VLRCALC := TEMPO->VLRSIGA
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			Else
				_FIELD->VLRCALC := MEST011CP(TEMPO->OP,TEMPO->DATAMOV,TEMPO->NUMSEQ)
				_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
			EndIf
			
			_nQtde := _nQtde + TEMPO->QTDE
			_nCST  := _nCST + TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			If _nQtde<>0    //Sempre que houve movimentação de quantidade deve atualizar o custo médio
				_nCM  :=(_nCST / _nQtde)
			EndIf
						
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM := _nCM
			
		// tratamento dos movimentos de desmembramento de lotes
		ElseIf TEMPO->SIGA_CF $ "RE7"
			
			_FIELD->VLRCALC := TEMPO->VLRSIGA
			_FIELD->CMCALC  := (TEMPO->VLRCALC / TEMPO->QTDE)
		
			_nQtde := _nQtde - TEMPO->QTDE
			_nCST  := _nCST - TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			If _nQtde<>0    //Sempre que houve movimentação de quantidade deve atualizar o custo médio
				_nCM  :=(_nCST / _nQtde)
			EndIf
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			_nCMAUX:=(_nCST / _nQtde)
			
			If _nCMAUX > 99999999999.9999 .Or. _nCMAUX < -99999999999.9999
				_nCMAUX = 99999999999.9999
			EndIf
			
			_FIELD->CMACM := _nCMAUX 
			
		ElseIf TEMPO->SIGA_CF $ "DE7"
			
			_FIELD->VLRCALC := TEMPO->VLRSIGA
			_FIELD->CMCALC  := (TEMPO->VLRCALC/TEMPO->QTDE)
			
			_nQtde := _nQtde + TEMPO->QTDE
			_nCST  := _nCST + TEMPO->VLRCALC
			
			// Custo acumulado nunca pode ficar negativo
			If _nCST < 0 .Or. _nQtde < 0
				_nCST := 0
			EndIf
			
			_nCM  :=(_nCST / _nQtde)
			
			_FIELD->QTDACM := _nQtde
			_FIELD->CSTACM := _nCST
			
			If _nCM > 99999999999.9999 .Or. _nCM < -99999999999.9999
				_nCM := 99999999999.9999
			EndIf
			
			_FIELD->CMACM := _nCM
			
			// fim tratamento dos movs. de desmembramento de lotes
		EndIf
	EndIf
	
	TEMPO->( DBSkip())
	
	If RTrim(_cArmaz + _cProd) <> RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO)
		_cArmaz := ARMAZ
		_cProd  := PRODUTO
		_nQtde  := 0
		_nCST   := 0
		_nCM    := 0
	EndIf
EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011CP
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: LEVANTAR O CUSTO DE REQUISICOES DE UMA PRODUÇÃO
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011CP(_cOP,_dDatPro,_cNumSeq)

Local _nRet		:= 0
Local _nAreaPr	:= SELECT()
Local _nOrdPr 	:= INDEXORD()
Local _nRegPr 	:= Recno()
Local _nOrdTmp	:= 0
Local _nRegTmp	:= 0 
Local _lAutom		:=.F.  //VERIFICA SE A REQUIS É AUTOMÁTICA
Local _lMovSd3	:=.T. // VERIFICA SE OS MOVTOS REF.OP ESTÃO NO MES ATUAL OU BUSCARÁ DO SD3 EM MESES ANTERIORES
Local _aMovD3 	:= {}
Local _nNiD3			:= 0

DBSelectArea("TEMPO")

_nOrdTmp:=INDEXORD()
_nRegTmp:=Recno()

TEMPO->( DBSetOrder(3))   ///OP+PRIORIDADE+DATAMOV
TEMPO->( DBGoTop() )

TEMPO->( DBSeek(_cOP))

While TEMPO->OP ==_cOP .And. ! TEMPO->( Eof() )
	If TEMPO->SIGA_CF $ "RE1/DE1" .And. SubStr(TEMPO->PRODUTO,1,3) <> "MOD"   // para nao considerar casos com re0 mp e re1 mod
		_lAutom:=.T.
	EndIf
	TEMPO->( DBSkip() )
EndDo

If _lAutom
	TEMPO->(DBGoTop())
	TEMPO->(DBSeek(_cOP))

	While TEMPO->OP == _cOP .And. ! TEMPO->( Eof() )
		If TEMPO->NUMSEQ == _cNumSeq
			If TEMPO->SIGA_CF == "RE1"
				_nRet := _nRet + TEMPO->VLRCALC
			EndIf
		EndIf
		TEMPO->(DBSkip())
	EndDo
Else

	_lMovSd3:=.T. // VERIFICA SE OS MOVTOS REF.OP ESTÃO NO MES ATUAL OU BUSCARÁ DO SD3 EM MESES ANTERIORES
	TEMPO->(DBSetOrder(4)) ///OP+DATA
	TEMPO->(DBSeek(_cOP))

	While RTrim(OP)==RTrim(_cOP) .And. TEMPO->(!Eof())
		If TEMPO->DATAMOV<=_dDatPro
			If SubStr(SIGA_CF,1,2)=="RE" .And. SubStr(PRODUTO,1,3)<>"MOD"
				_nRet:=_nRet+VLRCALC
				_lMovSd3:=.F.
			ElseIf SubStr(SIGA_CF,1,2)=="DE"
				_nRet:=_nRet-VLRCALC
			ElseIf (SubStr(SIGA_CF,1,2)=="PR") .And. (TEMPO->DATAMOV<>_dDatPro)
				_nRet:=0
			EndIf
		EndIf
		TEMPO->(DBSkip())
	EndDo

	If _nRet<=0 .And. _lMovSd3

		DBSelectArea("SD3")
		SD3->( DBSetOrder(1)) ///OP
		SD3->( DBSeek(xFilial("SD3")+_cOP))
		_aMovD3 := {}  // D3_COD,D3_LOCAL,D3_CF,D3_QUANT,D3_EMISSAO,D3_CUSTO1

		While SD3->D3_FILIAL + SD3->D3_OP == xFilial("SD3") + _cOP .And. ! SD3->( Eof() )
			If SD3->D3_EMISSAO <= _dDatPro
				aAdd(_aMovD3,{SD3->D3_COD,SD3->D3_LOCAL,SD3->D3_CF,SD3->D3_QUANT,SD3->D3_EMISSAO,SD3->D3_CUSTO1,SD3->D3_NUMSEQ})
			EndIf
			SD3->( DBSkip() )
		EndDo

		DBSelectArea("TEMPO")
		
		aSort(_aMovD3,,,{|x,y|DToS(X[5])+X[7]<DToS(y[5])+y[7]})
		
		For _nNiD3:=1 To Len(_aMovD3)
			If SubStr(_aMovD3[_nNiD3,3],1,2) == "RE"
				_nRet := _nRet +_aMovD3[_nNiD3,6]
			ElseIf SubStr(_aMovD3[_nNiD3,3],1,2) == "DE"
				_nRet := _nRet -_aMovD3[_nNiD3,6]
			ElseIf (SubStr(_aMovD3[_nNiD3,3],1,2) == "PR") .And. (_aMovD3[_nNiD3,5] <> _dDatPro)
				_nRet := 0
			EndIf

		Next _nNiD3
	EndIf
EndIf

SD3->( DBSetOrder(1) )
SD3->( DBGoTop())

DBSelectArea("TEMPO")
TEMPO->( DBSetOrder(_nOrdTmp) )
TEMPO->( DBGoTo(_nRegTmp) )

DBSelectArea(_nAreaPr)
_nAreaPr->(DBSetOrder(_nOrdPr))
_nAreaPr->(DBGoTo(_nRegPr) )

Return(_nRet)

/*
===============================================================================================================================
Programa----------: MEST011GE
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Gera Estoque na tabela temporária
Parametros--------: _oProcess - objeto da tela principal
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011GE(_oProcess)

Local _nI := 0

DBSelectArea("TEMPO")
TEMPO->( DBGoTop() )

_oProcess:SETREGUA1(RecCount())

While !(TEMPO->( Eof() ))

	_oProcess:INCREGUA1("ARMAZ-PROD:" + TEMPO->ARMAZ + "-" + TEMPO->PRODUTO)
	ProcessMessages()
	
	DBSelectArea("TEMPOES")
	TEMPOES->(DBSeek(TEMPO->(ARMAZ + PRODUTO) + DToS(MV_PAR02)))
	
	If !(TEMPOES->( FOUND() ))

		TEMPOES->( DBAppend() ) 
		_FIELD->ARMAZ    	:= TEMPO->ARMAZ
		_FIELD->PRODUTO  	:= TEMPO->PRODUTO
		_FIELD->TIPO     	:= RETFIELD("SB1",1,xFilial("SB1")+TEMPO->PRODUTO,"SB1->B1_TIPO")
		_FIELD->GRUPO    	:= RETFIELD("SB1",1,xFilial("SB1")+TEMPO->PRODUTO,"SB1->B1_GRUPO")
		_FIELD->UNMED    	:= RETFIELD("SB1",1,xFilial("SB1")+TEMPO->PRODUTO,"SB1->B1_UM")
		_FIELD->DATASLD  	:= MV_PAR02
		_FIELD->QTDE     	:= MEST011SF(TEMPO->ARMAZ,TEMPO->PRODUTO)
		_FIELD->CUSTO    	:= MEST011BU(TEMPO->ARMAZ,TEMPO->PRODUTO,MV_PAR02)
		
		If TEMPOES->PRODUTO="D2000002"
			_nI := 1
		EndIf
		
		If TEMPOES->CUSTO > 9999999999
			_FIELD->CUSTO := 9999999999
		ElseIf TEMPOES->CUSTO< -999999999
			_FIELD->CUSTO := -999999999
		EndIf
		
		_FIELD->CMCALC   := (TEMPOES->CUSTO / TEMPOES->QTDE)
		_FIELD->CST_SIGA := MEST011VF(TEMPOES->ARMAZ,TEMPOES->PRODUTO)
		_FIELD->CM_SIGA  := (TEMPOES->CST_SIGA / TEMPOES->QTDE)
		_FIELD->QTDE_CALC:= MEST011QF(TEMPOES->ARMAZ,TEMPOES->PRODUTO,MV_PAR02)
		_FIELD->CSTQ_CALC:= (TEMPOES->QTDE_CALC * TEMPOES->CMCALC)
		_FIELD->DIF_CST  := TEMPOES->CUSTO - TEMPOES->CST_SIGA
		
		SB2->(DBSetOrder(1))
		SB2->(DBSeek( xFilial("SB2")+TEMPO->(PRODUTO + ARMAZ) ))
	EndIf

	DBSelectArea("TEMPO")
	TEMPO->( DBSkip() )
EndDo

DBSelectArea("TEMPO")
TEMPO->( DBSetOrder(1) )

Return

/*
===============================================================================================================================
Programa----------: MEST011BU
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Busca Situação tributária
Parametros--------: 	_cArmaz - Armazém
						_cProduto - Produto
						_dDatPro - Data Produção
Retorno-----------: _nRet - Situação Tributária
===============================================================================================================================
*/

Static Function MEST011BU(_cArmaz,_cProduto,_dDatPro)

Local _nRet 		:= 0
Local _nAreaTmp 	:= SELECT()
Local _nOrdTmp	:= 0
Local _nRegTmp	:= 0

DBSelectArea("TEMPO")
_nOrdTmp	:= INDEXORD()
_nRegTmp	:= Recno()

TEMPO->(DBSetOrder(2))
TEMPO->(DBGoTop())
TEMPO->(DBSeek(_cArmaz+_cProduto+DToS(_dDatPro),.T.))

If (RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) == RTrim(_cArmaz + _cProduto)) .And. (TEMPO->DATAMOV <= _dDatPro)
	While (RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) == RTrim(_cArmaz + _cProduto)) .And. (TEMPO->DATAMOV <= _dDatPro) .And. ! TEMPO->(Eof())
		_nRet := TEMPO->CSTACM // CMCALC
		TEMPO->(DBSkip())
	EndDo
Else
	TEMPO->(DBSkip(-1))
	While (RTrim(TEMPO->ARMAZ + PRODUTO)==RTrim(_cArmaz + _cProduto)) .And. (TEMPO->DATAMOV <= _dDatPro) .And. ! TEMPO->(Eof())
		_nRet := TEMPO->CSTACM  //CMCALC
		TEMPO->(DBSkip())
	EndDo
EndIf

TEMPO->(DBSetOrder(_nOrdTmp))
TEMPO->(DBGoTo(_nRegTmp))

DBSelectArea(_nAreaTmp)

Return(_nRet)

/*
===============================================================================================================================
Programa----------: MEST011SF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Busca Saldo final do produto
Parametros--------: 	_cArmaz - Armazém
						_cProduto - Produto
Retorno-----------: _nRet - Saldo final do produto
===============================================================================================================================
*/
Static Function MEST011SF(_cArmaz,_cProduto)

Local _nRet		:= 0
Local _nAreaSF	:= SELECT()

If MV_PAR04 >= MV_PAR02
	DBSelectArea("SB9")
	SB9->(DBSetOrder(1))
	SB9->(DBGoTop())
	SB9->(DBSeek(xFilial("SB9")+_cProduto+_cArmaz+DToS(MV_PAR02)))
	_nRet := SB9->B9_QINI
ElseIf (MONTH(MV_PAR02) - MONTH(MV_PAR04)) <= 1
	DBSelectArea("SB2")
	SB2->(DBSetOrder(1))
	SB2->(DBGoTop())
	SB2->(DBSeek(xFilial("SB2")+_cProduto+_cArmaz))
	_nRet := SB2->B2_QFIM
ElseIf (MONTH(MV_PAR02) - MONTH(MV_PAR04)) > 1
	
	DBSelectArea("TEMPO")
	_nOrdTmp := TEMPO->(INDEXORD())
	_nRegTmp := TEMPO(RECNO())
	TEMPO->(DBSetOrder(2))
	TEMPO->(DBGoTop())
	TEMPO->(DBSeek(_cArmaz+_cProduto+DToS(MV_PAR02),.T.))
	
	If (RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) == RTrim(_cArmaz + _cProduto)) .And. (TEMPO->DATAMOV <= MV_PAR02)
		While (RTrim(TEMPO->ARMAZ + PRODUTO) == RTrim(_cArmaz + _cProduto)) .And. (TEMPO->DATAMOV <= MV_PAR02) .And. ! TEMPO->(Eof())
			_nRet := TEMPO->QTDACM // CMCALC
			TEMPO->(DBSkip())
		EndDo
	Else
		TEMPO->(DBSkip(-1))
		While (RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) == RTrim(_cArmaz + _cProduto)) .And. (TEMPO->DATAMOV <= MV_PAR02) .And. ! TEMPO->(Eof())
			_nRet := TEMPO->QTDACM  //CMCALC
			TEMPO->(DBSkip())
		EndDo
	EndIf
	TEMPO->(DBSetOrder(_nOrdTmp))
	TEMPO->(DBGoTo(_nRegTmp))
EndIf

DBSelectArea(_nAreaSF)

Return(_nRet)

/*
===============================================================================================================================
Programa----------: MEST011VF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Busca valor final do produto
Parametros--------: 	_cArmaz - Armazém
						_cProduto - Produto
Retorno-----------: _nRet - Valor final do produto
===============================================================================================================================
*/
Static Function MEST011VF(_cArmaz,_cProduto)

Local _nRet		:=0
Local _nAreaSF	:=SELECT()

If MV_PAR04 >= MV_PAR02
	DBSelectArea("SB9")
	SB9->(DBSetOrder(1))
	SB9->(DBGoTop())
	SB9->(DBSeek(xFilial("SB9")+_cProduto+_cArmaz+DToS(MV_PAR02)))
	_nRet := SB9->B9_VINI1
Else
	DBSelectArea("SB2")
	SB2->(DBSetOrder(1))
	SB2->(DBGoTop())
	SB2->(DBSeek(xFilial("SB2")+_cProduto+_cArmaz))
	_nRet := SB2->B2_VFIM1
EndIf

DBSelectArea(_nAreaSF)

Return(_nRet)

/*
===============================================================================================================================
Programa----------: MEST011LA
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Busca valor final do produto
Parametros--------: 	_oProcess - objeto da tela principal
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011LA(_oProcess)

DBSelectArea("TEMPO")
TEMPO->(DBGoTop())

_oProcess:SETREGUA1(RecCount())

While ! TEMPO->(Eof())
	_oProcess:INCREGUA1("1/3-Armz-Produto:" + TEMPO->ARMAZ + "-" + TEMPO->PRODUTO)
	ProcessMessages()
	If (TEMPO->ARMAZ == "05" .Or. TEMPO->ARMAZ >= "22") .And. (TEMPO->ARMAZ <> "90")
		TEMPO->(DBDELETE())
	EndIf
	TEMPO->(DBSkip())
EndDo

DBSelectArea("TEMPOES")
TEMPOES->(DBGoTop())
_oProcess:SETREGUA1(RecCount())

While ! TEMPOES->(Eof())
	_oProcess:INCREGUA1("3/3-Armz-Produto:" + TEMPOES->ARMAZ + "-" + TEMPOES->PRODUTO)
	ProcessMessages()

	If (TEMPOES->ARMAZ == "05" .Or. TEMPOES->ARMAZ >= "22") .And. (TEMPOES->ARMAZ <> "90")
		TEMPOES->(DBDELETE())
	EndIf
	TEMPOES->(DBSkip())
EndDo

Return

/*
===============================================================================================================================
Programa----------: MEST011QF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Retorna a ultima quantidade acumulada do armazem + produto
Parametros--------: 	_cArmaz - Armazém
						_cProduto - Produto
						_dDatPro - Data produção
Retorno-----------: _nret - Ultima quantidade acumulada
===============================================================================================================================
*/
Static Function MEST011QF(_cArmaz,_cProduto,_dDatPro)

Local _nRet := 0
Local _nAreaTmp := SELECT()

DBSelectArea("TEMPO")

_nOrdTmp := TEMPO->(INDEXORD())
_nRegTmp := TEMPO->(RECNO())

TEMPO->(DBSetOrder(2))
TEMPO->(DBGoTop())
TEMPO->(DBSeek(_cArmaz + _cProduto + DToS(_dDatPro),.T.))

If (RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) == RTrim(_cArmaz + _cProduto))
	While RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) + DToS(TEMPO->DATAMOV) <= RTrim(_cArmaz + _cProduto) + DToS(_dDatPro) .And. ! TEMPO->(Eof())
		_nRet := TEMPO->QTDACM
		TEMPO->(DBSkip())
	EndDo
Else
	TEMPO->(DBSkip(-1))
	If RTrim(TEMPO->ARMAZ + TEMPO->PRODUTO) == RTrim(_cArmaz + _cProduto)
		_nRet := TEMPO->QTDACM
	EndIf
EndIf

TEMPO->(DBSetOrder(_nOrdTmp))
TEMPO->(DBGoTo(_nRegTmp))

DBSelectArea(_nAreaTmp)

Return(_nRet)

/*
===============================================================================================================================
Programa----------: MEST011GA
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/12/2015
Descrição---------: Gera arquivo excel de exportação
Parametros--------: 	_cARQTMP - Arquivo principal de dados
						_cARQTMPES - Arquivo auxiliar de dados
						_cHRINI - Hora do inicio do processamento
						_oprocess - objeto da interface principal
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST011GA(_cARQTMP,_cARQTMPES,_cHRINI,_oprocess)

Local _cArqAux2  	:= ""
Local _cArqAux2E 	:= ""
Local _cHRFIM		:= Time()
Local _alinhas	:= {}
Local _alinhasE	:= {}
Local _nH			:= 0
Local _nHE			:= 0
Local _nI			:= 0
Local _cnome		:= ""

_oProcess:SetRegua1((TEMPO->(RecCount()) + TEMPOES->(RecCount())) * 2)

//trata nome do arquivo
If right(AllTrim(MV_PAR03),4) = ".XML" .Or. right(AllTrim(MV_PAR03),4) = ".xml"  
	_cnome := LEFT(AllTrim(MV_PAR03),( Len(AllTrim(MV_PAR03)) - 4))
Else
	_cnome := AllTrim(MV_PAR03)
EndIf

_cArqAux2  	:= _cnome + ".XML"
_cArqAux2E 	:= _cnome + "ES" + ".XML"

//===========================================================================
//Cria array do primeiro arquivo
//===========================================================================

aAdd(_aLinhas,{'<?xml version="1.0"?>'})
aAdd(_aLinhas,{'<?mso-application progid="Excel.Sheet"?>'})
aAdd(_aLinhas,{'<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'})
aAdd(_aLinhas,{' xmlns:o="urn:schemas-microsoft-com:office:office"'})
aAdd(_aLinhas,{' xmlns:x="urn:schemas-microsoft-com:office:excel"'})
aAdd(_aLinhas,{' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'})
aAdd(_aLinhas,{' xmlns:html="http://www.w3.org/TR/REC-html40">'})
aAdd(_aLinhas,{' <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'})
aAdd(_aLinhas,{'  <Created>2006-09-16T00:00:00Z</Created>'})
aAdd(_aLinhas,{'  <LastSaved>2015-12-29T17:57:05Z</LastSaved>'})
aAdd(_aLinhas,{'  <Version>15.00</Version>'})
aAdd(_aLinhas,{' </DocumentProperties>'})
aAdd(_aLinhas,{' <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">'})
aAdd(_aLinhas,{'  <AllowPNG/>'})
aAdd(_aLinhas,{'  <RemovePersonalInformation/>'})
aAdd(_aLinhas,{' </OfficeDocumentSettings>'})
aAdd(_aLinhas,{' <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'})
aAdd(_aLinhas,{'  <WindowHeight>0</WindowHeight>'})
aAdd(_aLinhas,{'  <WindowWidth>2370</WindowWidth>'})
aAdd(_aLinhas,{'  <WindowTopX>0</WindowTopX>'})
aAdd(_aLinhas,{'  <WindowTopY>0</WindowTopY>'})
aAdd(_aLinhas,{'  <ProtectStructure>False</ProtectStructure>'})
aAdd(_aLinhas,{'  <ProtectWindows>False</ProtectWindows>'})
aAdd(_aLinhas,{' </ExcelWorkbook>'})
aAdd(_aLinhas,{' <Styles>'})
aAdd(_aLinhas,{'  <Style ss:ID="Default" ss:Name="Normal">'})
aAdd(_aLinhas,{'   <Alignment ss:Vertical="Bottom"/>'})
aAdd(_aLinhas,{'   <Borders/>'})
aAdd(_aLinhas,{'   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'})
aAdd(_aLinhas,{'   <Interior/>'})
aAdd(_aLinhas,{'   <NumberFormat/>'})
aAdd(_aLinhas,{'   <Protection/>'})
aAdd(_aLinhas,{'  </Style>'})
aAdd(_aLinhas,{' </Styles>'})
aAdd(_aLinhas,{' <Worksheet ss:Name="Plan1">'})
aAdd(_aLinhas,{'  <Table ss:ExpandedColumnCount="999999" ss:ExpandedRowCount="999999" x:FullColumns="1"'})
aAdd(_aLinhas,{'   x:FullRows="1" ss:DefaultRowHeight="15">'})
aAdd(_aLinhas,{'   <Column ss:Width="54.75" ss:Span="19"/>'}) 

//==================================================================================
//Carrega dados do primeiro arquivo
//==================================================================================

DBSelectArea("TEMPOES")
TEMPO->( DBGoTop() )

While .not. TEMPO->( Eof() )

	aAdd(_aLinhas,{'   <Row ss:AutoFitHeight="0">'})
	
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->ARMAZ) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->PRODUTO) 										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->TIPO) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->GRUPO) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->UNMED) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + DToC(TEMPO->DATAMOV) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->DOC) 												+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->SIGA_CF) 										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->SIGA_TPMOV) 										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->OP) 												+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->QTDE, 	"999999999.99"))			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->VLRSIGA, 	"999999999.99"))			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->VLRCALC, 	"999999999.99"))			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->CMCALC, 	"999999999.99")) 			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->PRIORIDADE)										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->TRANSACAO)										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->NUMSEQ)	 										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->SEQCALCULO)										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->ORIGEM) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->TIPONF) 											+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->QTDACM, 	"999999999.99")) 			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->CSTACM, 	"999999999.99")) 			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPO->CMACM, 	"999999999.99")) 			+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->TES) 												+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->TES_PODER3) 										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->IDENTB6) 										+ '</Data></Cell>'})
	aAdd(_aLinhas,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPO->USUARIO) 										+ '</Data></Cell>'})
	
	aAdd(_aLinhas,{'   </Row>'})

	TEMPO->( DBSkip() )
	
	_oProcess:IncRegua1("Primeira planilha - " + AllTrim(TEMPO->ARMAZ) + " - " + AllTrim(TEMPO->PRODUTO) )//Incrementa primeira régua
	ProcessMessages()
EndDo

//=========================================================================================
//Fecha array do primeiro arquivo
//=========================================================================================

aAdd(_aLinhas,{'  </Table>'})
aAdd(_aLinhas,{'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'})
aAdd(_aLinhas,{'   <PageSetup>'})
aAdd(_aLinhas,{'    <Header x:Margin="0.3"/>'})
aAdd(_aLinhas,{'    <Footer x:Margin="0.3"/>'})
aAdd(_aLinhas,{'    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>'})
aAdd(_aLinhas,{'   </PageSetup>'})
aAdd(_aLinhas,{'   <Unsynced/>'})
aAdd(_aLinhas,{'   <Selected/>'})
aAdd(_aLinhas,{'   <Panes>'})
aAdd(_aLinhas,{'    <Pane>'})
aAdd(_aLinhas,{'     <Number>3</Number>'})
aAdd(_aLinhas,{'     <ActiveCol>1</ActiveCol>'})
aAdd(_aLinhas,{'    </Pane>'})
aAdd(_aLinhas,{'   </Panes>'})
aAdd(_aLinhas,{'   <ProtectObjects>False</ProtectObjects>'})
aAdd(_aLinhas,{'   <ProtectScenarios>False</ProtectScenarios>'})
aAdd(_aLinhas,{'  </WorksheetOptions>'})
aAdd(_aLinhas,{' </Worksheet>'})
aAdd(_aLinhas,{'</Workbook>'})

//=============================================================================
//Carrega array do segundo arquivo
//=============================================================================

aAdd(_aLinhasE,{'<?xml version="1.0"?>'})
aAdd(_aLinhasE,{'<?mso-application progid="Excel.Sheet"?>'})
aAdd(_aLinhasE,{'<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'})
aAdd(_aLinhasE,{' xmlns:o="urn:schemas-microsoft-com:office:office"'})
aAdd(_aLinhasE,{' xmlns:x="urn:schemas-microsoft-com:office:excel"'})
aAdd(_aLinhasE,{' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'})
aAdd(_aLinhasE,{' xmlns:html="http://www.w3.org/TR/REC-html40">'})
aAdd(_aLinhasE,{' <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'})
aAdd(_aLinhasE,{'  <Created>2006-09-16T00:00:00Z</Created>'})
aAdd(_aLinhasE,{'  <LastSaved>2015-12-29T17:57:05Z</LastSaved>'})
aAdd(_aLinhasE,{'  <Version>15.00</Version>'})
aAdd(_aLinhasE,{' </DocumentProperties>'})
aAdd(_aLinhasE,{' <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">'})
aAdd(_aLinhasE,{'  <AllowPNG/>'})
aAdd(_aLinhasE,{'  <RemovePersonalInformation/>'})
aAdd(_aLinhasE,{' </OfficeDocumentSettings>'})
aAdd(_aLinhasE,{' <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'})
aAdd(_aLinhasE,{'  <WindowHeight>0</WindowHeight>'})
aAdd(_aLinhasE,{'  <WindowWidth>2370</WindowWidth>'})
aAdd(_aLinhasE,{'  <WindowTopX>0</WindowTopX>'})
aAdd(_aLinhasE,{'  <WindowTopY>0</WindowTopY>'})
aAdd(_aLinhasE,{'  <ProtectStructure>False</ProtectStructure>'})
aAdd(_aLinhasE,{'  <ProtectWindows>False</ProtectWindows>'})
aAdd(_aLinhasE,{' </ExcelWorkbook>'})
aAdd(_aLinhasE,{' <Styles>'})
aAdd(_aLinhasE,{'  <Style ss:ID="Default" ss:Name="Normal">'})
aAdd(_aLinhasE,{'   <Alignment ss:Vertical="Bottom"/>'})
aAdd(_aLinhasE,{'   <Borders/>'})
aAdd(_aLinhasE,{'   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'})
aAdd(_aLinhasE,{'   <Interior/>'})
aAdd(_aLinhasE,{'   <NumberFormat/>'})
aAdd(_aLinhasE,{'   <Protection/>'})
aAdd(_aLinhasE,{'  </Style>'})
aAdd(_aLinhasE,{' </Styles>'})
aAdd(_aLinhasE,{' <Worksheet ss:Name="Plan1">'})
aAdd(_aLinhasE,{'  <Table ss:ExpandedColumnCount="99999" ss:ExpandedRowCount="999999" x:FullColumns="1"'})
aAdd(_aLinhasE,{'   x:FullRows="1" ss:DefaultRowHeight="15">'})
aAdd(_aLinhasE,{'   <Column ss:Width="54.75" ss:Span="19"/>'})

//======================================================================================
//Carrega dados do segundo arquivo
//======================================================================================

DBSelectArea("TEMPOES")
TEMPOES->( DBGoTop() )

While .not. TEMPOES->( Eof() )

	aAdd(_aLinhasE,{'   <Row ss:AutoFitHeight="0">'})
	
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPOES->ARMAZ) 											+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPOES->PRODUTO) 											+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPOES->TIPO) 											+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPOES->GRUPO) 											+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="String">' + AllTrim(TEMPOES->UNMED) 											+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="String">' + AllTrim(DToC(TEMPOES->DATASLD)) 									+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->QTDE, 			"999999999.99"))  	+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->CUSTO, 		"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->CMCALC, 		"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->CST_SIGA,		"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->CM_SIGA, 		"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->QTDE_CALC,	"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->CSTQ_CALC, 	"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->DIF_CST, 		"999999999.99"))		+ '</Data></Cell>'})
	aAdd(_aLinhasE,{'    <Cell><Data ss:Type="Number">' + AllTrim(TRANSFORM(TEMPOES->PVAR_CM, 		"999999999.99"))		+ '</Data></Cell>'})
	
	aAdd(_aLinhasE,{'   </Row>'})

	_oProcess:IncRegua1("Segunda planilha - " + AllTrim(TEMPOES->ARMAZ) + " - " + AllTrim(TEMPOES->PRODUTO) )//Incrementa primeira régua
	ProcessMessages()

	TEMPOES->( DBSkip() )
EndDo

//==========================================================================================
//Fecha array do segundo arquivo
//==========================================================================================

aAdd(_aLinhasE,{'  </Table>'})
aAdd(_aLinhasE,{'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'})
aAdd(_aLinhasE,{'   <PageSetup>'})
aAdd(_aLinhasE,{'    <Header x:Margin="0.3"/>'})
aAdd(_aLinhasE,{'    <Footer x:Margin="0.3"/>'})
aAdd(_aLinhasE,{'    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>'})
aAdd(_aLinhasE,{'   </PageSetup>'})
aAdd(_aLinhasE,{'   <Unsynced/>'})
aAdd(_aLinhasE,{'   <Selected/>'})
aAdd(_aLinhasE,{'   <Panes>'})
aAdd(_aLinhasE,{'    <Pane>'})
aAdd(_aLinhasE,{'     <Number>3</Number>'})
aAdd(_aLinhasE,{'     <ActiveCol>1</ActiveCol>'})
aAdd(_aLinhasE,{'    </Pane>'})
aAdd(_aLinhasE,{'   </Panes>'})
aAdd(_aLinhasE,{'   <ProtectObjects>False</ProtectObjects>'})
aAdd(_aLinhasE,{'   <ProtectScenarios>False</ProtectScenarios>'})
aAdd(_aLinhasE,{'  </WorksheetOptions>'})
aAdd(_aLinhasE,{' </Worksheet>'})
aAdd(_aLinhasE,{'</Workbook>'})

//===================================================================================
//Cria arquivos xml
//===================================================================================

_nH := FCreate(_cArqAux2) 
_nHE := FCreate(_cArqAux2E) 

If _nH == -1 
   MsgStop("Falha ao criar arquivo - " + _cArqAux2 + " - erro " + Str(ferror())) 
   Return 
EndIf 

If _nHE == -1 
   MsgStop("Falha ao criar arquivo - " + _cArqAux2E + " - erro " + Str(ferror())) 
   _oProcess:SaveLog( "Falha ao salvar planilhas - " + DToC(date()) + " - " + _cHrini + " - " + cUserName )
   Return 
EndIf 

_ninc := 0
_ctemp := ""

For _nI := 1 to Len(_aLinhas)
	_ninc++
	If _ninc = 5000 .Or. _nI == Len(_aLinhas)
		_ctemp += _aLinhas[_nI][1] + chr(13) + chr(10)
		FWrite(_nH, _ctemp )
		_oProcess:IncRegua1("Gravando " + _cArqAux2 + " - Linha " + StrZero(_nI,10) + " de " + StrZero(Len(_aLinhas),10))//Incrementa primeira régua
		ProcessMessages()
		
		_ninc := 0
		_ctemp := "" 
	Else
		_ctemp += _aLinhas[_nI][1] + chr(13) + chr(10)
	EndIf
Next

_ninc := 0
_nI := 1
_ctemp := ""

For _nI := 1 to Len(_aLinhasE)

	_ninc++
	
	If _ninc = 5000 .Or. _nI == Len(_aLinhasE)
		_ctemp += _aLinhasE[_nI][1] + chr(13) + chr(10)
		FWrite(_nHE,_ctemp )
		_oProcess:IncRegua1("Gravando " + _cArqAux2E + " - Linha " + StrZero(_nI,6) + " de " + StrZero(Len(_aLinhasE),6))//Incrementa primeira régua
		ProcessMessages()
		
		_ninc := 0
		_ctemp := "" 
	Else
		_ctemp += _aLinhasE[_nI][1] + chr(13) + chr(10)
	EndIf
Next _nI

FClose(_nH) 
FClose(_nHE)

ShellExecute("open", _cArqAux2, "", "c:\", 1)
ShellExecute("open", _cArqAux2E, "", "c:\", 1)

DBSelectArea("TEMPO")

TEMPO->(DBCloseArea())
FERASE((_cARQTMP+".DBF"))
FERASE((_cARQTMP+".CDX"))

DBSelectArea("TEMPOES")

TEMPOES->(DBCloseArea())
FERASE((_cARQTMPES+"ES.DBF"))
FERASE((_cARQTMPES+"ES.CDX"))

_cHRFIM := Time()

_oProcess:SaveLog( "Planilhas geradas com sucesso - " + DToC(date()) + " - " + _cHRFIM + " - " + cUserName )

MsgStop("Arquivos gerados " + 	chr(13)+;
									_cArqAux2+CHR(13)+;
									_cArqAux2E+CHR(13)+;
									CHR(13)+;
									"Inicio "+_cHRINI+CHR(13)+;
									"Fim    "+_cHRFIM)
									

Return
