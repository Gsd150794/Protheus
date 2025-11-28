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
Programa--------: RFIN018
Autor-----------: Alex Wallauer
Data da Criacao-: 22/10/2019
Descrição-------: Relação de CLAIMs - Chamado 29718
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function RFIN018()
Local _aParRet :={}
Local _aParAux :={} , nI 
Local _bOK1    :={|| If(MV_PAR04 >= MV_PAR03,.T.,(U_ITMsg("Periodo INVALIDO",'Dt Emissão'    ,"Tente novamente com um periodo Valido"  ,3),.F.) ) }
Local _bOK2    :={|| If(MV_PAR06 >= MV_PAR05,.T.,(U_ITMsg("Periodo INVALIDO",'Dt Vencto Real',"Tente novamente com um periodo Valido"  ,3),.F.) ) }
Local _bOK3    :={|| If(MV_PAR08 >= MV_PAR07,.T.,(U_ITMsg("Periodo INVALIDO",'Dt Liberação ' ,"Tente novamente com um periodo Valido"  ,3),.F.) ) }
Local _bOK4    :={|| If(MV_PAR10 >= MV_PAR09,.T.,(U_ITMsg("Intervalo INVALIDO",'No. Titulo ' ,"Tente novamente com um Intervalo Valido",3),.F.) ) }

Private aLog := {}
Private _cFecham	:= ""

_aOpca:={}
aAdd( _aOpca , "1-Sim  ")
aAdd( _aOpca , "2-Nao  ")
aAdd( _aOpca , "3-Ambos")

MV_PAR01:=Space(200)
MV_PAR02:="1–Sim  "
MV_PAR03:=dDataBase
MV_PAR04:=dDataBase
MV_PAR05:=dDataBase
MV_PAR06:=dDataBase
MV_PAR07:=dDataBase
MV_PAR08:=dDataBase
MV_PAR09:=Space(Len(SE2->E2_NUM))
MV_PAR10:=Space(Len(SE2->E2_NUM))

aAdd( _aParAux , { 1 , "Filial"               , MV_PAR01, "@!"  , ""    ,"LSTFIL"   , "" , 060 , .F. } ) 
aAdd( _aParAux , { 2 , "CLAIM"                , MV_PAR02, _aOpca                         , 060 ,".T.",.F.}) 
aAdd( _aParAux , { 1 , "Dt Emissão de"	      , MV_PAR03, "@D"	, ""	, ""		, "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Dt Emissão ate"       , MV_PAR04, "@D"	, ""	, ""		, "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Dt Vencto Real de"	  , MV_PAR05, "@D"	, ""	, ""		, "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Dt Vencto Real ate"   , MV_PAR06, "@D"	, ""	, ""		, "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Dt Liberação de"	  , MV_PAR07, "@D"	, ""	, ""		, "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Dt Liberação ate"     , MV_PAR08, "@D"	, ""	, ""		, "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "No. Titulo de"        , MV_PAR09, "@!"  , ""    , ""        , "" , 060 , .F. } ) 
aAdd( _aParAux , { 1 , "No. Titulo ate"       , MV_PAR10, "@!"  , ""    , ""        , "" , 060 , .F. } ) 

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

   lSair:=.T.
   
   If !ParamBox( _aParAux , "Seleção de dados do Relação de Titulos CLAIMs" , @_aParRet ,{|| ( EVAL(_bOK1) .And. EVAL(_bOK2) .And. EVAL(_bOK3) .And. EVAL(_bOK4) )} )
      Return .T.
   EndIf

   FWMsgRun( ,{|oproc| lSair:=RFIN018INI(oproc) } , "Processando..." , "Iniciando o processamento..." )

   If lSair
      Exit
   EndIf

EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: RFIN018INI
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 29/07/2019
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function RFIN018INI(oproc)

Local _cQuery	:= ""
Local _aDados	:= {}
Private cAliasAux	:= GetNextAli8as()

//Grava Log de execução da rotina
U_ITLOGACS( "RFIN018" )

oproc:cCaption := ("Lendo dados...")
ProcessMessages()

_cQuery := " SELECT  SE2.R_E_C_N_O_ REC_SE2 , SD1.R_E_C_N_O_ REC_SD1 "
_cQuery += " FROM " +RETSQLNAME("SE2") + " SE2 
_cQuery += " INNER JOIN " +RETSQLNAME("SD1") + " SD1 ON SE2.E2_FILIAL	= SD1.D1_FILIAL	 AND "
_cQuery += " 											SE2.E2_FORNECE 	= SD1.D1_FORNECE AND "
_cQuery += " 											SE2.E2_LOJA 	= SD1.D1_LOJA	 AND "
_cQuery += " 											SE2.E2_NUM		= SD1.D1_DOC         "
_cQuery += " WHERE  "
_cQuery += " SE2.E2_FILIAL IN "+ FormatIn(AllTrim(MV_PAR01), ";" )
If !Empty(MV_PAR04)
   _cQuery += " AND E2_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "'"
ElseIf !Empty(MV_PAR03) 
   _cQuery += " AND E2_EMISSAO >= '" + DToS(MV_PAR03) + "'"
EndIf
If !Empty(MV_PAR06)
   _cQuery += " AND E2_VENCREA BETWEEN '" + DToS(MV_PAR05) + "' AND '" + DToS(MV_PAR06) + "'"
ElseIf !Empty(MV_PAR05) 
   _cQuery += " AND E2_VENCREA >= '" + DToS(MV_PAR05) + "'"
EndIf
If !Empty(MV_PAR08)
   _cQuery += " AND E2_DATALIB BETWEEN '" + DToS(MV_PAR07) + "' AND '" + DToS(MV_PAR08) + "'"
ElseIf !Empty(MV_PAR07) 
   _cQuery += " AND E2_DATALIB >= '" + DToS(MV_PAR07) + "'"
EndIf
If !Empty(MV_PAR10)
   _cQuery += " AND E2_NUM BETWEEN '" + DToS(MV_PAR09) + "' AND '" + DToS(MV_PAR10) + "'"
ElseIf !Empty(MV_PAR09) 
   _cQuery += " AND E2_NUM >= '" + DToS(MV_PAR09) + "'"
EndIf
If MV_PAR02 = "1"
   _cQuery += " AND E2_I_CLAIM = '1' "
ElseIf MV_PAR02 = "2"
   _cQuery += " AND E2_I_CLAIM = '2' "
Else
   _cQuery += " AND E2_I_CLAIM <> ' ' "
EndIf
_cQuery += "  AND SE2.D_E_L_E_T_ = ' ' " 
_cQuery += "  AND SD1.D_E_L_E_T_ = ' ' " 
_cQuery += " ORDER BY SE2.E2_I_CLAIM , SE2.E2_NUM "
	
MPSysOpenQuery( _cQuery , cAliasAux ) 

oProc:cCaption := ("Contando os dados lidos...")
ProcessMessages()
DBSelectArea(cAliasAux)
(cAliasAux)->(DBGoTop())
_cTot := 0
COUNT TO _cTot
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
(cAliasAux)->(DBGoTop())
_npv:=0

While (cAliasAux)->(!Eof())

    SE2->(DBGoTo((cAliasAux)->REC_SE2))
    SD1->(DBGoTo((cAliasAux)->REC_SD1))
	_npv++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()

    _aItens:={}
	aAdd(_aItens,If(SE2->E2_I_CLAIM="1","Sim","Não"))
	aAdd(_aItens,SE2->E2_FILIAL)
	aAdd(_aItens,SE2->E2_PREFIXO)
	aAdd(_aItens,SE2->E2_NUM)
	aAdd(_aItens,SE2->E2_PARCELA)
	aAdd(_aItens,DToC(SE2->E2_EMISSAO))
	aAdd(_aItens,DToC(SE2->E2_VENCREA))
	aAdd(_aItens,DToC(SE2->E2_DATALIB))
	aAdd(_aItens,SD1->D1_PEDIDO)
	aAdd(_aItens,SD1->D1_COD)
	aAdd(_aItens,Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_I_DESCD"))	
	aAdd(_aItens,Transform(SD1->D1_QUANT,PesqPict("SD1","D1_QUANT")) )
	aAdd(_aItens,Transform(SD1->D1_VUNIT,PesqPict("SD1","D1_VUNIT")) )
	aAdd(_aItens,Transform(SD1->D1_TOTAL,PesqPict("SD1","D1_TOTAL")) )
	aAdd(_aDados,_aItens)

    (cAliasAux)->(DBSkip())
 
EndDo

(cAliasAux)->( DBCloseArea() )


//Monta _aCab
aTitCol:={}
_aSizes:={}
aAdd(aTitCol,"CLAIM")
aAdd(_aSizes,30)
aAdd(aTitCol,"Filial")
aAdd(_aSizes,30)
aAdd(aTitCol,"Prefixo")
aAdd(_aSizes,30)
aAdd(aTitCol,"No Titulo")
aAdd(_aSizes,40)
aAdd(aTitCol,"Parcela")
aAdd(_aSizes,30)
aAdd(aTitCol,"Dt Emisaão")
aAdd(_aSizes,40)
aAdd(aTitCol,"Dt Vencto Real")
aAdd(_aSizes,45)
aAdd(aTitCol,"Dt Liberação")
aAdd(_aSizes,40)
aAdd(aTitCol,"Pedido")
aAdd(_aSizes,40)
aAdd(aTitCol,"Produto")
aAdd(_aSizes,40)
aAdd(aTitCol,"Descrição do Produto")
aAdd(_aSizes,100)
aAdd(aTitCol,"Quantidade")
aAdd(_aSizes,40)
aAdd(aTitCol,"Vlr Unitário")
aAdd(_aSizes,40)
aAdd(aTitCol,"Vlr Total Prod.")
aAdd(_aSizes,50)

If Len(_aDados) > 0
   _cTitulo:="Relação Titulos a Pagar de CLAIMs"
   _cMsgTop:=_cTitulo
//    ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX(_cTitulo, aTitCol  , _aDados   , .T.      , 1      ,_cMsgTop  ,          , _aSizes )
Else
	U_ITMsg("Nenhum registro gerado!","Atenção",,1)
EndIf

Return .F.
