/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |21/05/2021| Chamado 36589. Incluída gravação do custo de frete indivdualmente.
Lucas Borges  |12/12/2021| Chamado 38597. Migração da classe de impressão para FWMSPrinter.
Lucas Borges  |18/03/2023| Chamado 46654. Tramento do diretório de impressão do FWMSPrinter até a TOTVS resolver a questão.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWPrintSetup.ch" 
#Include "RPTDEF.CH"
#DEFINE _oFontT 	TFont():New( "Verdana", 09, 09, , .T., , , , .T., .F. )//Titulo
#DEFINE _oFontC 	TFont():New( "Verdana", 09, 09, , .T., , , , .T., .F. )//Cabeçalho
#DEFINE _oFontL 	TFont():New( "Verdana", 07, 07, , .F., , , , .T., .F. )//Linhas
#DEFINE ALIGN_H_LEFT   	0
#DEFINE ALIGN_H_RIGHT  	1
#DEFINE ALIGN_H_CENTER 	2
#DEFINE ALIGN_H_JUST 	3

/*
===============================================================================================================================
Programa----------: RGLT023
Autor-------------: Abrahao P. Santos
Data da Criacao---: 29/01/2009
Descrição---------: Relatório de Tickets
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT023

Local _oProfile			:= Nil
Local _oPrinter			:= Nil
Local _oSetup			:= Nil
Local _nDestination		:= 1//1-SERVER - 2-CLIENT
Local _aMargRel			:= {0,0,0,0} //nEsquerda, nSuperior, nDireita, nInferior
Local _cPerg			:= "RGLT023"
Local _nPrintType		:= 6 //FwMsPrinter só aceita 2-SPOOL (IMP_SPOOL) ou 6-PDF (IMP_PDF)
Local _cValueType		:= "c:\"
Local _cPathInServer	:= __RelDir
Local _aOrdem			:= {"Por Filial+Ticket+Recepção"} 
Local _nFlags			:= PD_ISTOTVSPRINTER+PD_DISABLEORIENTATION+PD_DISABLEPAPERSIZE+PD_DISABLEMARGIN//PD_ISTOTVSPRINTER=1,PD_DISABLEDESTINATION=2,PD_DISABLEORIENTATION=4,PD_DISABLEPAPERSIZE=8,PD_DISABLEPREVIEW=16,PD_DISABLEMARGIN=32
Local _cFilePrint		:= "RGLT023"//+DToS(MSDate())+StrTran(Time(),":","")
Local _nOrientation		:= 1 //1-PORTRAIT - 2-LANDSCAPE
Local _cTitulo			:= "RGLT023 - Relação de Tickets"
Local _nPaperSize		:= 2//1-"Letter 8 1/2 x 11 in" / 2-"A4 210 x 297 mm" / 3-"A3 297 x 420 mm"/ 4-"Executive 7 1/4 x 10 1/2 in" / 5-"Tabloid 11 x 17 in"
Local _nOrdem			:= 1
Local _lPreview			:= .F.
//Busca configurações de impressão no Profile do usuário
_oProfile:= FWProfile():New()
_oProfile:SetUser(RetCodUsr())
_oProfile:SetProgram("RGLT023")
_oProfile:SetTask("PRINTER")
_oProfile:SetType("PRINTTYPE")
_oProfile:Load()
_nPrintType := IIf(Empty(_oProfile:LoadStrProfile()),_nPrintType,Val(_oProfile:LoadStrProfile()))
_oProfile:SetType("ORIENTATIO")
_oProfile:Load()
_nOrientation := IIf(Empty(_oProfile:LoadStrProfile()),_nOrientation,Val(_oProfile:LoadStrProfile()))
_oProfile:SetType("DESTINATIO")
_oProfile:Load()
_nDestination := IIf(Empty(_oProfile:LoadStrProfile()),_nDestination,Val(_oProfile:LoadStrProfile()))
_oProfile:SetType("PAPERSIZE")
_oProfile:Load()
_nPaperSize := IIf(Empty(_oProfile:LoadStrProfile()),_nPaperSize,Val(_oProfile:LoadStrProfile()))
_oProfile:SetType("VALUETYPE")
_oProfile:Load()
_cValueType := IIf(Empty(_oProfile:LoadStrProfile()),_cValueType,_oProfile:LoadStrProfile())

//Monta tela de seleção de impressora
_oSetup := FWPrintSetup():New(_nFlags, _cTitulo)
_oSetup:SetUserParms( {|| Pergunte(_cPerg, .T.) } ) 
_oSetup:SetPropert(PD_PRINTTYPE   , _nPrintType)//2
_oSetup:SetPropert(PD_ORIENTATION , _nOrientation)//3
_oSetup:SetPropert(PD_DESTINATION , _nDestination)//1
_oSetup:SetPropert(PD_MARGIN      , {_aMargRel[1],_aMargRel[2],_aMargRel[3],_aMargRel[4]})//7
_oSetup:SetPropert(PD_PAPERSIZE   , _nPaperSize)//4
_oSetup:aOptions[PD_VALUETYPE] := _cValueType//6
_oSetup:SetPropert(PD_PREVIEW,.T.)//5
_oSetup:SetOrderParms(_aOrdem,@_nOrdem)

// Cria Arquivo do Relatorio
_oPrinter := FWMSPrinter():New(_cFilePrint/*_cFilePrint*/,_nPrintType/*nDevice*/,.F./*lAdjustToLegacy*/,_cPathInServer/*_cPathInServer*/,.F./*lDisabeSetup*/,;
								/*lTReport*/,_oSetup/*oPrintSetup*/,/*cPrinter*/,/*lServer*/,/*lPDFAsPNG*/,.F./*lRaw*/,.T./*lViewPDF*/,/*nQtdCopy*/ )

//Fecha caso o usuário cancele a tela de configuração
If !(_oSetup:Activate() == PD_OK)//Exibe tela de Impressão
	_oPrinter:Deactivate() 
	Return
EndIf
//Atualiza classe FWMSPrinter com os parâmetros informado pelo usuário
_oPrinter:SetDevice(_oSetup:GetProperty(PD_PRINTTYPE))
If _oSetup:GetProperty(PD_ORIENTATION) == 2//paisagem
	_oPrinter:SetLandscape()
Else
	_oPrinter:SetPortrait()
EndIf
_oPrinter:lServer := _oSetup:GetProperty(PD_DESTINATION) == 1//SERVER
_oPrinter:SetResolution(75)
_oPrinter:SetMargin(_oSetup:GetProperty(PD_MARGIN)[1],_oSetup:GetProperty(PD_MARGIN)[2],_oSetup:GetProperty(PD_MARGIN)[3],_oSetup:GetProperty(PD_MARGIN)[4])
_oPrinter:SetPaperSize(_oSetup:GetProperty(PD_PAPERSIZE))
If _oSetup:GetProperty(PD_PRINTTYPE) == 2 //Spool
	_oPrinter:cPrinter := _oSetup:aOptions[PD_VALUETYPE]
ElseIf _oSetup:GetProperty(PD_PRINTTYPE) == 6//PDF
	_oPrinter:cPathPDF := Lower(_oSetup:aOptions[PD_VALUETYPE])
EndIf

//Salva configurações no Profile do usuário
_oProfile:SetType("PRINTTYPE")
_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_PRINTTYPE)))
_oProfile:Save()
_oProfile:SetType("ORIENTATIO")
_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_ORIENTATION)))
_oProfile:Save()
_oProfile:SetType("DESTINATIO")
_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_DESTINATION)))
_oProfile:Save()
_oProfile:SetType("PAPERSIZE")
_oProfile:SetStringProfile(cValToChar(_oSetup:GetProperty(PD_PAPERSIZE)))
_oProfile:Save()
_oProfile:SetType("VALUETYPE")
_oProfile:SetStringProfile(_oSetup:GetProperty(PD_VALUETYPE))
_oProfile:Save()

Pergunte( _cPerg , .F. )

Processa({||RGLT023I(_oPrinter,_cPerg,@_lPreview)} , "Aguarde!" , "Selecionando registros das recepções..." )
If _lPreview
	_oPrinter:Preview()//Envia o relatório para a impressão
Else
	MsgInfo("Não foram encontrados registros de acordo com o parâmetro informado","RGLT02301")
	_oPrinter:Deactivate()  
EndIf

Return

/*
===============================================================================================================================
Programa----------: RGLT023I
Autor-------------: Abrahao P. Santos
Data da Criacao---: 29/01/2009
Descrição---------: Rotina de processamento e impressão do relatório
Parametros--------: _oPrinter,_cPerg,_lPreview
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT023I(_oPrinter,_cPerg,_lPreview)

Local _nQtdReg		:= 0
Local _cUltTicket	:= ""
Local _cUltCodRec	:= ""
Local _cAlias		:= GetNextAlias()
Local _cTabela		:= "%"
Local _cFiltro		:= "%"
Local _cOrder		:= "%"
Local _cCampos		:= "%"
Local _nLin			:= 0
Local _cString		:= "ZLD"
Local _aCol			:= {010,060,190,240,310,340,450,510}
Local _nSizePage 	:= 0 //Largura da página em cm dividido pelo fator horizontal, retorna tamanho da página em pixels

Private _aCalcFretes:={}

Static _nSubVol		:= 0
Static _nSubCol		:= 0
Static _nTotVol		:= 0
Static _nTotCol		:= 0
Static _nSubFret     := 0

_cCampos += _cString+"_TICKET, " + _cString+"_CODREC, " + _cString+"_KM," + _cString +"_QTDBOM," + _cString+"_LINROT, "
_cCampos += _cString+"_FRETIS, " + _cString+"_LJFRET, " + _cString+"_VEICUL," + _cString +"_RETIRO," + _cString+"_RETILJ, "
_cCampos += _cString+"_DTCOLE, " + _cString+"_TOTBOM, " + _cString+"_ATENDI"

_cTabela += RetSqlName(_cString)

_cFiltro += " AND "+ _cString +"_DTCOLE BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"' "
_cFiltro += " AND "+ _cString +"_SETOR = '"+ MV_PAR03 + "'"
_cFiltro += " AND "+ _cString +"_RETIRO BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "
_cFiltro += " AND "+ _cString +"_TICKET BETWEEN '"+ MV_PAR06 +"' AND '"+ MV_PAR07 +"' " 
_cFiltro += " AND "+ _cString +"_FRETIS BETWEEN '"+ MV_PAR08 +"' AND '"+ MV_PAR10 +"' " 
_cFiltro += " AND "+ _cString +"_LJFRET BETWEEN '"+ MV_PAR09 +"' AND '"+ MV_PAR11 +"' "      
_cFiltro += " AND "+ _cString +"_LINROT BETWEEN '"+ MV_PAR12 +"' AND '"+ MV_PAR13 +"' "      
_cFiltro += " AND "+ _cString +"_FILIAL = '" + xFilial(_cString) + "'"

If _cString = "ZLD" .And. (!Empty(MV_PAR15) .Or. !Empty(MV_PAR16))
   _cFiltro += " AND ZLD_TICKET IN (SELECT ZLJ_VIAGEM FROM "+RetSqlName("ZLJ") +" ZLJ WHERE ZLJ_DTCRIA BETWEEN '"+DToS(MV_PAR15)+"' AND '"+ DToS(MV_PAR16)+"')"
EndIf
_cOrder += _cString +"_FILIAL,"+ _cString +"_TICKET,"+ _cString +"_CODREC"

_cCampos += "%"
_cTabela += "%"
_cFiltro += "%"
_cOrder += "%"

BeginSql alias _cAlias
	SELECT %exp:_cCampos%
	FROM %exp:_cTabela%
	WHERE D_E_L_E_T_ = ' '
	%exp:_cFiltro%
	ORDER BY %exp:_cOrder%
EndSql

COUNT TO _nQtdReg
(_cAlias)->( DBGoTop() )
ProcRegua(_nQtdReg)
If _nQtdReg > 0
	_lPreview:= .T.
EndIf

While (_cAlias)->( !Eof() )
	IncProc()
	If (_nPos:=aScan(_aCalcFretes,{|V| V[1]==(_cAlias)->&(_cString+"_TICKET")+(_cAlias)->&(_cString+"_CODREC") })) = 0
	   aAdd(_aCalcFretes,{ (_cAlias)->&(_cString+"_TICKET")+(_cAlias)->&(_cString+"_CODREC") ,;
	                       (_cAlias)->&(_cString+"_KM")     ,;
	                       (_cAlias)->&(_cString+"_QTDBOM") ,;
	                       (_cAlias)->&(_cString+"_LINROT") })
    Else
       If !Empty((_cAlias)->&(_cString+"_KM"))
          _aCalcFretes[_nPos,2]:=(_cAlias)->&(_cString+"_KM")
          _aCalcFretes[_nPos,4]:=(_cAlias)->&(_cString+"_LINROT")
       EndIf
       _aCalcFretes[_nPos,3]+=(_cAlias)->&(_cString+"_QTDBOM")
    EndIf
    (_cAlias)->( DBSkip() )
EndDo

ProcRegua(_nQtdReg)

(_cAlias)->( DBGoTop() )

ZL3->( DBSetOrder(1) )
ZFF->( DBSetOrder(1) )

_oPrinter:StartPage()
_nSizePage 	:= (_oPrinter:nPageWidth/_oPrinter:nFactorHor)
Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.F.)

U_ImpParam(_oPrinter,_nLin,_cPerg,_aCol,_oFontL)// Imprime página de parâmetros

_oPrinter:StartPage()
Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)

While (_cAlias)->( !Eof() )

	IncProc()

	If _nLin > 600 // Salto de Página
		_oPrinter:EndPage()
		_oPrinter:StartPage()
		Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
	EndIf

	If _cUltTicket != (_cAlias)->&(_cString+"_TICKET")
		If _nSubCol > 0
			showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)
		    _oPrinter:EndPage()
			_oPrinter:StartPage()
			Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
		EndIf

		_oPrinter:SayAlign(_nLin,_aCol[1],"Ticket: "+(_cAlias)->&(_cString+"_TICKET")+ " - Setor: "+MV_PAR03+" - Tipo do Leite: "+If(_cString="ZLD","Produtores - Data de Entrada do Estoque: "+BuscaDtEstoque(_cAlias,_cString),"Cooperativas"),_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 20

	EndIf
	
	_cUltTicket := (_cAlias)->&(_cString+"_TICKET")
	
	If _cUltCodRec != AllTrim( (_cAlias)->&(_cString+"_CODREC") )
		CalcFrete(_oPrinter,@_nLin,_cAlias,_cString,_aCol,_nSizePage)
		_oPrinter:SayAlign(_nLin,_aCol[1], (_cAlias)->&(_cString+"_FRETIS") +"-"+ (_cAlias)->&(_cString+"_LJFRET"),_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[2], LEFT(Posicione("SA2",1,xFilial("SA2")+(_cAlias)->&(_cString+"_FRETIS")+(_cAlias)->&(_cString+"_LJFRET"),"A2_NOME"),20)+" - "+;
		"Km Rodado: "+ AllTrim(Transform( (_cAlias)->&(_cString+"_KM") , "@E 999,999,999" ))+" - Veiculo: "+(_cAlias)->&(_cString+"_VEICUL")+" - Placa: "+Posicione("ZL1",1,xFilial("ZL1")+(_cAlias)->&(_cString+"_VEICUL"),"ZL1_PLACA"),_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 20
	EndIf
	
	_cUltCodRec := AllTrim( (_cAlias)->&(_cString+"_CODREC") )
	_oPrinter:SayAlign(_nLin,_aCol[1], (_cAlias)->&(_cString+"_RETIRO") +"-"+ (_cAlias)->&(_cString+"_RETILJ"),_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[2], LEFT(Posicione("SA2",1,xFilial("SA2")+(_cAlias)->&(_cString+"_RETIRO")+(_cAlias)->&(_cString+"_RETILJ"),"A2_NOME"),25),_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[3], DToC(SToD((_cAlias)->&(_cString+"_DTCOLE"))),_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[4], transform((_cAlias)->&(_cString+"_QTDBOM"),"@E 999,999,999"),_oFontL,500,100,ALIGN_H_RIGHT)
	_oPrinter:SayAlign(_nLin,_aCol[5], (_cAlias)->&(_cString+"_LINROT")+"-",_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[6], LEFT(Posicione("ZL3",1,xFilial("ZL3")+(_cAlias)->&(_cString+"_LINROT"),"ZL3_DESCRI"),20),_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[7], (_cAlias)->&(_cString+"_CODREC"),_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[8], (_cAlias)->&(_cString+"_ATENDI"),_oFontL,500,100,ALIGN_H_LEFT)
	_nLin+= 10

	_nSubVol := (_cAlias)->&(_cString+"_TOTBOM")
	_nSubCol += (_cAlias)->&(_cString+"_QTDBOM")

(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)

Return

/*
===============================================================================================================================
Programa----------: showSubTot
Autor-------------: Abrahao P. Santos
Data da Criacao---: 29/01/2009
Descrição---------: Relatório de Tickets
Parametros--------: _oPrinter,_nLin,_aCol,_nSizePage
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function showSubTot(_oPrinter,_nLin,_aCol,_nSizePage)

_nLin += 10
_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
_nLin += 3

_oPrinter:SayAlign(_nLin,_aCol[1], "Total da Coleta  "   + AllTrim( Transform( _nSubCol				, "@E 999,999,999" ) ),_oFontL,500,100,ALIGN_H_RIGHT)
_oPrinter:SayAlign(_nLin,_aCol[3], "Volume no Veiculo: " + AllTrim( Transform( _nSubVol				, "@E 999,999,999" ) ),_oFontL,500,100,ALIGN_H_RIGHT)
_oPrinter:SayAlign(_nLin,_aCol[5], "Pro/Contra: "        + AllTrim( Transform( _nSubVol - _nSubCol	, "@E 999,999,999" ) ),_oFontL,500,100,ALIGN_H_RIGHT)
_oPrinter:SayAlign(_nLin,_aCol[7], "Total Frete: "       + AllTrim( Transform( _nSubFret            	, "@E 999,999,999,999.99" ) ),_oFontL,500,100,ALIGN_H_RIGHT)

_nSubVol := 0
_nSubCol := 0
_nSubFret:= 0

_nLin += 17

_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
_nLin += 3

Return

/*
===============================================================================================================================
Programa----------: BuscaDtEstoque()
Autor-------------: Alex Wallauer
Data da Criacao---: 12/01/2018
Descrição---------: Busca a data de entrega do estoque 
Parametros--------: _cAlias
Retorno-----------: Retorna a data de entrega do estoque 
===============================================================================================================================
*/
Static Function BuscaDtEstoque(_cAlias,_cString)

Local  _cDtEstoqueSD3:=""

_cDtEstoqueSD3:=DToC( Posicione("ZLJ",2,xFilial("ZLJ")+(_cAlias)->&(_cString+"_TICKET"),"ZLJ_DTCRIA"))

Return _cDtEstoqueSD3 

/*
===============================================================================================================================
Programa----------: CalcFrete()
Autor-------------: Alex Wallauer
Data da Criacao---: 24/07/2018
Descrição---------: Imprimi dados dos frete
Parametros--------: _nLin,_cAlias,_cString
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function CalcFrete(_oPrinter,_nLin,_cAlias,_cString,_aCol,_nSizePage)

Local _nValor_Frete		:= 0
Local _cPRCEXE   		:= ""
Local _PRCLTR    		:= ""
Local _cTabFrete 		:= ""
Local _lImp      		:= .F.
Local _nPos       		:=  aScan(_aCalcFretes,{|V| V[1]= ( (_cAlias)->&(_cString+"_TICKET")+(_cAlias)->&(_cString+"_CODREC") )  })
Private _cVeiculo		:=  (_cAlias)->&(_cString+"_VEICUL")//Variavel usada NA FUNCAO U_CalFrete()
Private _nMultiplicador	:= 0//Variavel PREENCHIDA NA FUNCAO U_CalFrete()	

_cTabFrete:=Posicione("ZL1",1,xFilial("ZL1")+_cVeiculo,"ZL1_TABFRE")

If !Empty(_cTabFrete) .And. _nPos <> 0 .AND.;
    ZL3->(DBSeek(xFilial("ZL3")+ _aCalcFretes[_nPos,4] )) .AND.;
    ZFF->(DBSeek(xFilial("ZFF")+_cTabFrete))

	_cPRCEXE:=ZL3->ZL3_PRCEXE
	_PRCLTR :=ZL3->ZL3_PRCLTR

	If _PRCLTR = "1"
		_nValor_Frete:=U_CalFrete("LITRO",0,_cVeiculo,_aCalcFretes[_nPos,3])
		_lImp:=.T.
	ElseIf _cPRCEXE $ "1,2"
		_nValor_Frete:=U_CalFrete("KM"   ,_aCalcFretes[_nPos,2],_cVeiculo)
		_lImp:=.T.
	EndIf
	_nSubFret+=_nValor_Frete
	_nLin += 10
	_oPrinter:SayAlign(_nLin,_aCol[1], "Tabela Frete: "+AllTrim(ZFF->ZFF_DESCRI)+;
	               " - Frete p/ Litro: "+If(_PRCLTR ="1","Sim","Nao")+;
	               " - Frete p/ KM: "   +If(_cPRCEXE="1","Tab. Faixas",If(_cPRCEXE="2","Excecao","Nao"))+;
	      If(_lImp," - Fator: "      +AllTrim(Transform( _nMultiplicador, "@E 999,999,999,999.99" ))+;
	               " - Valor Frete: "+AllTrim(Transform( _nValor_Frete  , "@E 999,999,999,999.99" )),""),_oFontL,500,100,ALIGN_H_LEFT)

EndIf

_nLin += 10

Return .T.

/*
===============================================================================================================================
Programa----------: Cabec
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/09/2021
Descrição---------: Imprimi cabeçalho do relatório
Parametros--------: _oPrinter,_nLin,_aCol,_nSizePage,lCab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Cabec(_oPrinter,_nLin,_aCol,_nSizePage,_lCab)

Default _lCab := .T.
_nLin			:= 10

_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
If File( "LGRL01.BMP" )
	_oPrinter:SayBitmap(_nLin+2,0,"LGRL01.BMP",100,020)
EndIf
_nLin += 20
_oPrinter:SayAlign(_nLin-10,0,RptFolha + cValToChar(_oPrinter:nPageCount),_oFontL,_nSizePage-050,100,,ALIGN_H_RIGHT)
_oPrinter:SayAlign(_nLin,0,"Relação de Tickets",_oFontT,_nSizePage-050,100,,ALIGN_H_CENTER)
_oPrinter:SayAlign(_nLin,_aCol[1],GetEnvServer()+"\"+Upper(_oPrinter:cFileName)+"/v."+cVersao,_oFontL,_nSizePage-050,100,,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,0,RptDtRef + DToC(dDataBase),_oFontL,_nSizePage-050,100,,ALIGN_H_RIGHT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],RptHora+ Time(),_oFontL,_nSizePage-050,100,,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,0,RptEmiss + DToC(Date()),_oFontL,_nSizePage-050,100,,ALIGN_H_RIGHT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],"Grupo de Empresa: "+FWEmpName(cEmpAnt)+"/ Filial: "+FWFilName(cEmpAnt,cFilAnt),_oFontL,_nSizePage-050,100,,ALIGN_H_LEFT)
_nLin += 10
If _lCab
	_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
	_nLin += 3
	_oPrinter:SayAlign(_nLin,_aCol[1],"Produtor",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[3],"Dt Coleta",_oFontC,150,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[4],"Volume",_oFontC,500,100,ALIGN_H_RIGHT)
	_oPrinter:SayAlign(_nLin,_aCol[5],"Linha",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[7],"Recepção",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[8],"Atendimento",_oFontC,500,100,ALIGN_H_LEFT)
	_nLin += 15
EndIf
_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
_nLin += 10

Return
