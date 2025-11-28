/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |03/01/2020| Chamado 31147 - Nova coluna de SALDO para NCC. 
Igor Melgaço  |06/05/2022| Chamado 39987 - Adição do campo E1_EMIS1 referente a NCC. 
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "report.ch"

#Define TITULO	"Relatório DCI a Compensar"

/*
===============================================================================================================================
Programa--------: RFIN015
Autor-----------: Alex Wallauer
Data da Criacao-: 28/02/2018
Descrição-------: Relatório DCI a Compensar. CHAMADO: 21103
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function RFIN015()

Local _cPerg:="RFIN015"
Private _cAlias:=GetNextAlias()

Pergunte( _cPerg , .T. )

oReport:=RFIN015RUN(_cPerg)

Return

/*
===============================================================================================================================
Programa----------: RFIN015RUN
Autor-------------: Alex Wallauer
Data da Criacao---: 02/02/2018
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN015RUN(_cPerg)

Local oReport	:= Nil
Local oSecEntr_1:= Nil

oReport := TReport():New( "RFIN015" , TITULO,_cPerg , {|oReport| RFIN015PRT( oReport ) } , TITULO , .T. )

// Seta Padrao de impressao como Paisagem
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 45 // Define a altura da linha.

DEFINE Section oSecEntr_1 OF oReport TITLE "DCI a Compensar" TABLES "SE1"

  TRCell():New(oSecEntr_1,"E1_FILIAL" ,"SE1","Filial DCI"  ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_PREFIXO","SE1","Prefixo DCI" ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_TIPO"   ,"SE1","Tipo DCI"    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_NUM"    ,"SE1","Num DCI"     ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_CLIENTE","SE1",/*Titulo*/    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_LOJA"   ,"SE1",/*Titulo*/    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_NOMCLI" ,"SE1",/*Titulo*/    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_VALOR"  ,"SE1","Valor DCI"   ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_SALDO"  ,"SE1","Saldo DCI"   ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_EMISSAO","SE1","Dt Emiss DCI",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"COMPENSANA","SE1","COMPENSA NA" ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"E1_I_CHDCI","SE1",/*Titulo*/    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"NC_TIPO"   ,"SE1","Tipo NCC"    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"NC_NUM"    ,"SE1","Num NCC"     ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"NC_PREFIXO","SE1","Prefixo NCC" ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"NC_EMIS1"  ,"SE1","Data Cont."  ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  
  TRCell():New(oSecEntr_1,"NC_VALOR"  ,"SE1","Valor NCC"   ,PesqPict('SE1','E1_VALOR'),/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"NC_SALDO"  ,"SE1","Saldo NCC"   ,PesqPict('SE1','E1_SALDO'),/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

  TRCell():New(oSecEntr_1,"DCT_TIPO"   ,"SE1","Tipo DCT"   ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"DCT_NUM"    ,"SE1","Num DCT"    ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"DCT_PREFIXO","SE1","Prefixo DCT",/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
  TRCell():New(oSecEntr_1,"DCT_VALOR"  ,"SE1","Valor DCT"  ,PesqPict('SE1','E1_VALOR'),/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)

  oSecEntr_1:Disable()
  oReport:PrintDialog()

Return( oReport )

/*
===============================================================================================================================
Programa--------: RFIN015PRT
Autor-----------: Alex Wallauer
Data da Criacao-: 02/02/2018
Descrição-------: Função para consulta e preparação dos dados do relatório
Parametros------: oReport 
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function RFIN015PRT( oReport )

Local _cQuery	:= ''
Local _nTotReg	:= 0
Local oSection1	:= oReport:Section(1)

oSection1:Enable()

oReport:SetMeter(4)

oSection1:BeginQuery()

oReport:IncMeter()

_cQuery := " SELECT R_E_C_N_O_ SE1_REC "
_cQuery += " FROM  "+ RETSQLNAME('SE1') +" SE1 "
_cQuery += " WHERE SE1.D_E_L_E_T_ = ' '"
// Filtra Filial
MV_PAR01:=AllTrim(MV_PAR01)
If !Empty(MV_PAR01)
   If Len(MV_PAR01) < 4
      MV_PAR01:=LEFT(MV_PAR01,2)
      _cQuery += " AND E1_FILIAL = '" + MV_PAR01 + "' "
   Else
	  _cQuery += " AND E1_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
   EndIf
EndIf
// Filtra Emissão
If Empty( MV_PAR03 ) .And. !Empty( MV_PAR02 )
   _cQuery += " AND E1_EMISSAO >= '" + DToS( MV_PAR02 ) + "' "
ElseIf DToS( MV_PAR02 ) == DToS( MV_PAR03 ) .And. !Empty( MV_PAR02 )
   _cQuery += " AND E1_EMISSAO = '" + DToS( MV_PAR02 ) + "' "
ElseIf !Empty( MV_PAR03 )
   _cQuery += " AND E1_EMISSAO BETWEEN '" + DToS( MV_PAR02 ) + "' AND '" + DToS( MV_PAR03 ) + "' "
EndIf
// Filtra Cliente + LOJA
If Empty(MV_PAR06) .And. !Empty(MV_PAR04)
   _cQuery += " AND E1_CLIENTE >= '" + MV_PAR04 + "' "
   If !Empty(MV_PAR05)
      _cQuery += " AND E1_LOJA >= '" + MV_PAR05 + "' "
   EndIf
ElseIf  MV_PAR04 == MV_PAR06  .And. !Empty(MV_PAR04)
   _cQuery += " AND E1_CLIENTE = '" + MV_PAR04 + "' "
   If MV_PAR05 == MV_PAR07  .And. !Empty(MV_PAR05)
      _cQuery += " AND E1_LOJA = '" + MV_PAR05 + "' "
   ElseIf !Empty(MV_PAR07)
      _cQuery += " AND E1_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "' "
   EndIf
ElseIf !Empty(MV_PAR06)
   _cQuery += " AND E1_CLIENTE BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "' "
   If !Empty(MV_PAR07)
      _cQuery += " AND E1_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "' "
   EndIf
EndIf

_cQuery += " AND E1_PREFIXO = 'DCI' "
_cQuery += " AND E1_SALDO > 0 "
_cQuery += " AND E1_I_CHDCI <> ' ' "

_cQuery += " ORDER BY E1_FILIAL, E1_NUM, E1_PARCELA, E1_CLIENTE, E1_LOJA "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

oReport:IncMeter()

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

oSection1:EndQuery()

oReport:IncMeter()

COUNT TO _nTotReg

oReport:IncMeter()

//oSection:Init()
oSection1:Init()

oReport:SetMeter(_nTotReg)       

(_cAlias)->(DBGoTop())

SE1->( DBSetOrder(2) )//E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM                  +E1_PARCELA   +E1_TIPO
SD1->( DBSetOrder(1) )

While !oReport:Cancel() .And. (_cAlias)->( !Eof() )

    oReport:IncMeter()

	SE1->(DBGoTo( (_cAlias)->SE1_REC) )
	
	_nVlrNCI:=SE1->E1_VALOR
	_cNumTit:=LEFT(SE1->E1_I_CHDCI,Len(SE1->E1_NUM))//SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO+If(Empty(F1_FORMUL),"N",F1_FORMUL))
	_cSerie :=SubStr( SE1->E1_I_CHDCI , Len(SE1->E1_NUM)+1 , Len(SF1->F1_SERIE))
	
	//SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+E1_PREFIXO+E1_NUM  +E1_PARCELA+E1_TIPO
	_cChave :=SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+_cSerie   +_cNumTit//+"01"      +"NCC"
	If SE1->(DBSeek(_cChave))
		oSection1:Cell("NC_PREFIXO"):SetValue(SE1->E1_PREFIXO)
		oSection1:Cell("NC_TIPO"   ):SetValue(SE1->E1_TIPO   )
		oSection1:Cell("NC_NUM"    ):SetValue(SE1->E1_NUM    )
		oSection1:Cell("NC_EMIS1"  ):SetValue(DToC(SE1->E1_EMIS1))
		oSection1:Cell("NC_VALOR"  ):SetValue(SE1->E1_VALOR  )
		oSection1:Cell("NC_SALDO"  ):SetValue(SE1->E1_SALDO  )
	Else
		oSection1:Cell("NC_PREFIXO"):SetValue("")
		oSection1:Cell("NC_TIPO"   ):SetValue("")
		oSection1:Cell("NC_NUM"    ):SetValue("Não Achou")
		oSection1:Cell("NC_EMIS1"  ):SetValue("")
		oSection1:Cell("NC_VALOR"  ):SetValue(0)
		oSection1:Cell("NC_SALDO"  ):SetValue(0)
	    SE1->(DBGoTo( (_cAlias)->SE1_REC) )
	EndIf
	
	_nVlrDCT:=0
	oSection1:Cell("DCT_PREFIXO"):SetValue("")
	oSection1:Cell("DCT_TIPO"   ):SetValue("")
	oSection1:Cell("DCT_VALOR"  ):SetValue(0)
	If !SD1->( DBSeek( SE1->E1_FILIAL+_cNumTit+_cSerie+SE1->E1_CLIENTE+SE1->E1_LOJA))
	   oSection1:Cell("DCT_NUM"):SetValue("Não Achou NF")
	ElseIf Empty( SD1->D1_NFORI )
	   oSection1:Cell("DCT_NUM"):SetValue("Sem NF Origem")
	Else
		_cNumTit:=SD1->D1_NFORI
		_cSerie :="DCT"
		_cChave :=SE1->E1_FILIAL+SE1->E1_CLIENTE+SE1->E1_LOJA+_cSerie+_cNumTit//+"01"+"NCC"
		If SE1->(DBSeek(_cChave))
			oSection1:Cell("DCT_PREFIXO"):SetValue(SE1->E1_PREFIXO)
			oSection1:Cell("DCT_TIPO"   ):SetValue(SE1->E1_TIPO   )
			oSection1:Cell("DCT_NUM"    ):SetValue(SE1->E1_NUM    )
			oSection1:Cell("DCT_VALOR"  ):SetValue(SE1->E1_VALOR  )
			_nVlrDCT:=SE1->E1_VALOR
		Else
			oSection1:Cell("DCT_TIPO"   ):SetValue("Não Achou DCT")
			oSection1:Cell("DCT_NUM"    ):SetValue(SD1->D1_NFORI)
			oSection1:Cell("DCT_PREFIXO"):SetValue(SD1->D1_SERIORI)
		EndIf
	EndIf
	
	SE1->(DBGoTo( (_cAlias)->SE1_REC) )//Volta para DCI
	
	If RIGHT(AllTrim(SE1->E1_I_CHDCI),1) = "S"
		oSection1:Cell("COMPENSANA"):SetValue("DCT")
	ElseIf (_nVlrNCI-_nVlrDCT) > -0.02 .And. (_nVlrNCI-_nVlrDCT) < 0.02
		oSection1:Cell("COMPENSANA"):SetValue("VERIFICAR")
	Else
		oSection1:Cell("COMPENSANA"):SetValue("NCC")
	EndIf
	
	oSection1:PrintLine()
	
	(_cAlias)->( DBSkip() )
	
EndDo

oSection1:Finish()

Return .T.
