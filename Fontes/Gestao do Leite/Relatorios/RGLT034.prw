/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |12/12/2021| Chamado 38597. Migração da classe de impressão para FWMSPrinter.
Lucas Borges  |16/12/2021| Chamado 38649. Criado pergunte para informar o título do relatório.
Lucas Borges  |18/03/2023| Chamado 46654. Tramento do diretório de impressão do FWMSPrinter até a TOTVS resolver a questão.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWPrintSetup.ch" 
#Include "RPTDEF.CH"
#DEFINE _oFontT		TFont():New( "Verdana", 09, 09, , .T., , , , .T., .F. )//Titulo
#DEFINE _oFontC 	TFont():New( "Verdana", 09, 09, , .T., , , , .T., .F. )//Cabeçalho
#DEFINE _oFontL 	TFont():New( "Verdana", 07, 07, , .F., , , , .T., .F. )//Linhas
#DEFINE ALIGN_H_LEFT   	0
#DEFINE ALIGN_H_RIGHT  	1
#DEFINE ALIGN_H_CENTER 	2
#DEFINE ALIGN_H_JUST 	3
/*
===============================================================================================================================
Programa----------: RGLT034
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/04/2009
Descrição---------: Relacao de Pagamento por Banco x Produtores com seus valores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT034

Local _oProfile			:= Nil
Local _oPrinter			:= Nil
Local _oSetup			:= Nil
Local _nDestination		:= 1//1-SERVER - 2-CLIENT
Local _aMargRel			:= {0,0,0,0} //nEsquerda, nSuperior, nDireita, nInferior
Local _cPerg			:= "RGLT034"
Local _nPrintType		:= 6 //FwMsPrinter só aceita 2-SPOOL (IMP_SPOOL) ou 6-PDF (IMP_PDF)
Local _cValueType		:= "c:\"
Local _cPathInServer	:= __RelDir
Local _aOrdem			:= {"Ordem 1"} 
Local _nFlags			:= PD_ISTOTVSPRINTER+PD_DISABLEORIENTATION+PD_DISABLEPAPERSIZE+PD_DISABLEMARGIN//PD_ISTOTVSPRINTER=1,PD_DISABLEDESTINATION=2,PD_DISABLEORIENTATION=4,PD_DISABLEPAPERSIZE=8,PD_DISABLEPREVIEW=16,PD_DISABLEMARGIN=32
Local _cFilePrint		:= "RGLT034"//+DToS(MSDate())+StrTran(Time(),":","")
Local _nOrientation		:= 1 //1-PORTRAIT - 2-LANDSCAPE
Local _cTitulo			:= "RGLT034 - Pagto Banco"
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

Processa({||RGLT034I(_oPrinter,_cPerg,@_lPreview)} , "Aguarde!" , "Selecionando registros das recepções..." )
If _lPreview
	_oPrinter:Preview()//Envia o relatório para a impressão
Else
	MsgInfo("Não foram encontrados registros de acordo com o parâmetro informado","RGLT03401")
	_oPrinter:Deactivate()  
EndIf

Return

/*
===============================================================================================================================
Programa----------: RUNREPORT
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Funcao auxiliar chamada pela RPTSTATUS. A funcao RPTSTATUS monta a janela com a regua de processamento.
Parametros--------: _oPrinter,_cPerg,_lPreview
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT034I(_oPrinter,_cPerg,_lPreview)

Local _aCol			:= {010,050,080,240,310,340}//{010,060,190,240,310,340,450,510}
Local _nSizePage 	:= 0 //Largura da página em cm dividido pelo fator horizontal, retorna tamanho da página em pixels
Local _nLin			:= 0
Local _nqtdregs		:= 0
Local _nVlrPagto	:= 0
Local _cLinha		:= ""
Local _nX			:= 0
Local _cCampos		:= "%"
Local _cGroup		:= "%" 
Local _cOrder		:= "%" 
Local _cAlias		:= GetNextAlias()

Private _cUltBanc	:= ""
Private _nSubTot	:= 0
Private _nNunProd	:= 0
Private _nTotal		:= 0
Private _aResumo	:= {}
Private _aCC		:= {}
Private _cBancos	:= "CHQ/001/341"
Private _nTedDoc	:= 0

_nSubTotal := 0

If MV_PAR12 == 1
	_cCampos+= " ZLF_FILIAL, ZLF_LINROT, "
	_cCampos+= " (SELECT ZL3_DESCRI FROM "+ RetSqlName('ZL3') +" ZL3 WHERE ZL3.D_E_L_E_T_ = ' ' AND ZL3_FILIAL = ZLF_FILIAL AND ZL3_COD = ZLF_LINROT) DESCLINHA, %"
	_cGroup += " ZLF_FILIAL, ZLF_LINROT, %"
	_cOrder += " ZLF_FILIAL, ZLF_LINROT, %"
EndIf

BeginSql alias _cAlias
	SELECT A2_L_TPPAG, A2_COD, A2_LOJA, A2_NOME, A2_CGC, A2_BANCO, A2_AGENCIA, A2_NUMCON, %exp:_cCampos%
	       SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else 0 END) CREDITO,
	       SUM(Case WHEN ZLF_DEBCRE = 'D' THEN ZLF_TOTAL Else 0 END) DEBITO,
	       MIN(Case WHEN A2_L_TPPAG = 'B' THEN A2_BANCO Else ' ' END) XBANCO
	  FROM %Table:ZLF% ZLF, %Table:SA2% SA2
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND SA2.A2_FILIAL = %xFilial:SA2%
	   AND SA2.A2_COD = ZLF.ZLF_A2COD
	   AND SA2.A2_LOJA = ZLF.ZLF_A2LOJA
	   AND ZLF.ZLF_SETOR = %exp:AllTrim(MV_PAR01)%
	   AND ZLF.ZLF_LINROT BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR11%
	   AND ZLF.ZLF_CODZLE = %exp:MV_PAR02%
	   AND ZLF.ZLF_A2COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
	   AND ZLF.ZLF_A2LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
	   AND SA2.A2_BANCO BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	 GROUP BY %exp:_cGroup% A2_L_TPPAG, A2_BANCO, A2_AGENCIA, A2_NUMCON, A2_COD, A2_LOJA, A2_NOME, A2_CGC, A2_L_TANQ, A2_L_TANLJ
	 ORDER BY %exp:_cOrder% XBANCO, A2_BANCO, A2_AGENCIA, A2_L_TANQ, A2_L_TANLJ, A2_COD, A2_LOJA, A2_NUMCON
EndSql

COUNT To _nqtdregs
ProcRegua(_nqtdregs)
If _nqtdregs > 0
	_lPreview:= .T.
EndIf
(_cAlias)->(DBGoTop())

_oPrinter:StartPage()
_nSizePage 	:= (_oPrinter:nPageWidth/_oPrinter:nFactorHor)
Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.F.)

U_ImpParam(_oPrinter,_nLin,_cPerg,_aCol,_oFontL)// Imprime página de parâmetros

_oPrinter:StartPage()
Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
//====================================
//Caso nao For quebra por Linha/Rota
//====================================
If MV_PAR12 == 2
	While (_cAlias)->(!Eof())
		IncProc()

	    If _nLin > 750 // Salto de Página
	   		_oPrinter:EndPage()
			_oPrinter:StartPage()
			Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
		EndIf

		//Mostra cabeçalho (Linha e Fretista)
		If _cUltBanc != (_cAlias)->XBANCO+"-"+(_cAlias)->A2_AGENCIA
			// Mostra subtotal da linha
			If _cUltBanc != ""
				showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)
				_oPrinter:EndPage()
				_oPrinter:StartPage()
				Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
			EndIf

			If !Empty(AllTrim((_cAlias)->XBANCO))
				_oPrinter:SayAlign(_nLin,_aCol[1],"BANCO: "+(_cAlias)->XBANCO,_oFontL,500,100,ALIGN_H_LEFT)
				_oPrinter:SayAlign(_nLin,_aCol[3],"AGENCIA:"+(_cAlias)->A2_AGENCIA+"  "+getBcoName((_cAlias)->XBANCO),_oFontL,500,100,ALIGN_H_LEFT)
			Else
				_oPrinter:SayAlign(_nLin,_aCol[1],"CHEQUE/DINHEIRO",_oFontL,500,100,ALIGN_H_LEFT)
			EndIf
			_nLin += 10

		EndIf
		_cUltBanc:=(_cAlias)->XBANCO+"-"+(_cAlias)->A2_AGENCIA
		// Acha valor liquido a pagar
		_nVlrPagto:=(_cAlias)->(CREDITO-DEBITO)
		// MOSTRA PRODUTOR E SEUS RESPECTIVOS VALORES
		_oPrinter:SayAlign(_nLin,_aCol[1],(_cAlias)->A2_COD,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[2],(_cAlias)->A2_LOJA,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[3],LEFT((_cAlias)->A2_NOME,24),_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[4],(_cAlias)->A2_CGC,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[5],(_cAlias)->A2_NUMCON,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[6],transform(_nVlrPagto,"@E 9,999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
	 	_nLin += 10

		_nSubTot+=_nVlrPagto
		_nTotal+=_nVlrPagto
		_nNunProd++

		(_cAlias)->(DBSkip())
	EndDo
	(_cAlias)->(DBCloseArea())

	//====================================
	// Mostra SubTotal da ultima linha
	//====================================
	showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)
	_oPrinter:EndPage()
	_oPrinter:StartPage()
	Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)

	_oPrinter:SayAlign(_nLin,_aCol[1],"Resumo Por Bancos",_oFontL,500,100,ALIGN_H_LEFT)
	_nLin += 10

	_nSubTotal:=0
	_cUltBanc:=""
	_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		For _nX := 1 to Len(_aResumo)
			// Mostra Subtotal
			If _cUltBanc != Left(_aResumo[_nX,1],3) .And. _cUltBanc != ""
				_oPrinter:SayAlign(_nLin,_aCol[1],_cUltBanc,_oFontL,500,100,ALIGN_H_LEFT)
				_oPrinter:SayAlign(_nLin,_aCol[2],getBcoName(_cUltBanc),_oFontL,500,100,ALIGN_H_LEFT)
				_oPrinter:SayAlign(_nLin,_aCol[4]-50,TransForm(_nSubTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
				_nLin += 10
				_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
				_nLin += 10
				If _cUltBanc $ _cBancos
					aAdd(_aCC,{_cUltBanc,_nSubTotal})
				Else
					_nTedDoc+=_nSubTotal
				EndIf
				_nSubTotal:=0
			EndIf
			_cUltBanc:=left(_aResumo[_nX,1],3)
			_nSubTotal+=_aResumo[_nX,3]

	        If _nLin > 750 // Salto de Página
				_oPrinter:EndPage()
				_oPrinter:StartPage()
				Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
			EndIf

		Next _nX
		_oPrinter:SayAlign(_nLin,_aCol[1],_cUltBanc,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[2],getBcoName(_cUltBanc),_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[4]-50,TransForm(_nSubTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
		//_oPrinter:SayAlign(_nLin,_aCol[4]-50,TransForm(_nSubTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10

		If _cUltBanc $ _cBancos
			aAdd(_aCC,{_cUltBanc,_nSubTotal})
		Else
			_nTedDoc+=_nSubTotal
		EndIf

		_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10

		// Lista bancos com pagto credito em CC
		For _nX:=1 to Len(_aCC)
			_oPrinter:SayAlign(_nLin,_aCol[1],_aCC[_nX,1],_oFontL,500,100,ALIGN_H_LEFT)
			_oPrinter:SayAlign(_nLin,_aCol[2],getBcoName(_aCC[_nX,1]),_oFontL,500,100,ALIGN_H_LEFT)
			_oPrinter:SayAlign(_nLin,_aCol[4]-50,Transform(_aCC[_nX,2],"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
			_nLin += 10
			_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
			_nLin += 10
		Next _nX
		_oPrinter:SayAlign(_nLin,_aCol[1],"TED/DOC",_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[4]-50,Transform(_nTedDoc,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],"Total Geral",_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[4]-50,Transform(_nTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],"Setor: '"+MV_PAR01 + "' - "+Posicione("ZL2",1,xFilial("ZL2")+MV_PAR01,"ZL2_DESCRI"),_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],"Linha: '" + MV_PAR10 + "' Ate '"+ MV_PAR11 + "'",_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],"Mix:   '"+MV_PAR02 + "' - Versao: 1",_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],"Fornecedor: '"+MV_PAR03 + "' ao '" + MV_PAR05 + "'",_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],"Banco: '" + MV_PAR07 + "' ao '" + MV_PAR08 + "'",_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 20
		_oPrinter:SayAlign(_nLin,_aCol[1],"Dia do Pagto: "+DToC(MV_PAR09)+"   Ass: _____________________________",_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10

		_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
		_nLin += 10

//====================================
//Quebra por Linha/Rota
//====================================
Else
	While (_cAlias)->(!Eof())
		IncProc()
		If _nLin > 750 // Salto de Página
			_oPrinter:EndPage()
			_oPrinter:StartPage()
			Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
		EndIf

		//====================================
		//Quebra por Linha/Rota
		//====================================
		If _cLinha <> (_cAlias)->ZLF_LINROT
			//================================================================
			//A cada nova linha encontrada devera comecar em uma nova pagina
			//================================================================
			If Len(AllTrim(_cLinha)) > 0 
 				//====================================
				// Mostra SubTotal da ultima linha
				//====================================
				showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)
				//Imprime o resumo geral da Linha
				resGeral(_oPrinter,@_nLin,_aCol,_nSizePage)

				_oPrinter:EndPage()
				_oPrinter:StartPage()
				Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
			EndIf

			_oPrinter:SayAlign(_nLin,_aCol[1],"LINHA/ROTA: " + (_cAlias)->ZLF_LINROT + ' - ' + (_cAlias)->DESCLINHA,_oFontL,500,100,ALIGN_H_LEFT)
			_nLin += 10
			_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
			_nLin += 10
			//====================================
			//Seta variavel de controle da linha
			//====================================
			_cLinha  := (_cAlias)->ZLF_LINROT
			_cUltBanc := ""
			_aResumo  := {}
			_aCC      := {}
			_nTotal   := 0
		EndIf

		// Mostra Cabeçalho (Linha e Fretista)
		If _cUltBanc != (_cAlias)->XBANCO+"-"+(_cAlias)->A2_AGENCIA

			// Mostra subtotal da linha
			If _cUltBanc != ""
				showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)
			EndIf

			If !Empty(AllTrim((_cAlias)->XBANCO))
				_oPrinter:SayAlign(_nLin,_aCol[1],"BANCO: "+(_cAlias)->XBANCO,_oFontL,500,100,ALIGN_H_LEFT)
				_oPrinter:SayAlign(_nLin,_aCol[3],"AGENCIA:"+(_cAlias)->A2_AGENCIA+"  "+getBcoName((_cAlias)->XBANCO),_oFontL,500,100,ALIGN_H_LEFT)
			Else
				_oPrinter:SayAlign(_nLin,_aCol[1],"CHEQUE/DINHEIRO",_oFontL,500,100,ALIGN_H_LEFT)
			EndIf
			_nLin += 10

		EndIf
		_cUltBanc:=(_cAlias)->XBANCO+"-"+(_cAlias)->A2_AGENCIA
		//Acha valor liquido a pagar
		_nVlrPagto:=(_cAlias)->(CREDITO-DEBITO)

		//Mostra Produtor e seus respectivos valores
		_oPrinter:SayAlign(_nLin,_aCol[1],(_cAlias)->A2_COD,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[2],(_cAlias)->A2_LOJA,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[3],LEFT((_cAlias)->A2_NOME,24),_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[4],(_cAlias)->A2_CGC,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[5],(_cAlias)->A2_NUMCON,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[6],transform(_nVlrPagto,"@E 9,999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
		_nLin += 10

		_nSubTot+=_nVlrPagto
		_nTotal+=_nVlrPagto
		_nNunProd++

		(_cAlias)->(DBSkip())
	EndDo
	(_cAlias)->(DBCloseArea())

	//==================================
	//Mostra SubTotal da ultima linha
	//==================================
	showSubTot(_oPrinter,@_nLin,_aCol,_nSizePage)

	//Imprime o resumo geral da Linha
	resGeral(_oPrinter,@_nLin,_aCol,_nSizePage)
EndIf

Return

/*
===============================================================================================================================
Programa----------: getStruct
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Retorna campos dinamicos que estao na ZLF
Parametros--------: _oPrinter,_nLin,_aCol,_nSizePage
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function showSubTot(_oPrinter,_nLin,_aCol,_nSizePage)

Local _cAux := ""
_oPrinter:SayAlign(_nLin,_aCol[1], "SubTotal -------->		Total de Produtores: " + AllTrim(Str(_nNunProd)),_oFontL,500,100,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,_aCol[6], Transform(_nSubTot,"@E 9,999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
_nLin += 10

IIf(Empty(AllTrim(Left(_cUltBanc,3))),_cAux:="CHQ",_cAux:=_cUltBanc)              

aAdd(_aResumo,{_cAux,"",_nSubTot})
    
_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
_nLin += 10

_nSubTot  :=0
_nNunProd:=0

Return

/*
===============================================================================================================================
Programa----------: GETBCONAME
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Obtem nome do Banco
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function getBcoName(cCod)

Local _cRet := ""
Local _aRet := {}

cCod:=Left(cCod,3)
_cRet:=Posicione("SA6",1,xFilial("SA6")+cCod,"A6_NOME")
_aRet:=StrTokArr(_cRet,"-")
If Len(_aRet) > 0
	_cRet:=Left(_aRet[1],20)
EndIf

Return _cRet

/*
===============================================================================================================================
Programa----------: resGeral
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/12/2008
Descrição---------: Imprime resumo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function resGeral(_oPrinter,_nLin,_aCol,_nSizePage)

Local _nX := 0

_oPrinter:SayAlign(_nLin,_aCol[1],"Resumo Por Bancos",_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

_nSubTotal:=0  
_nTedDoc  := 0
_cUltBanc :=""

_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

For _nX :=1 To Len(_aResumo)
	// Mostra Subtotal
	If _cUltBanc != Left(_aResumo[_nX,1],3) .And. _cUltBanc != ""
		_oPrinter:SayAlign(_nLin,_aCol[1],_cUltBanc,_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[2],getBcoName(_cUltBanc),_oFontL,500,100,ALIGN_H_LEFT)
		_oPrinter:SayAlign(_nLin,_aCol[4]-50,TransForm(_nSubTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
		_nLin += 10
		_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
		_nLin += 10
		If _cUltBanc $ _cBancos
			aAdd(_aCC,{_cUltBanc,_nSubTotal})
		Else
			_nTedDoc+=_nSubTotal
		EndIf

		_nSubTotal:=0

	EndIf

	_cUltBanc:=Left(_aResumo[_nX,1],3)

	_nSubTotal+=_aResumo[_nX,3]

	If _nLin > 750 // Salto de Página
		_oPrinter:EndPage()
		_oPrinter:StartPage()
		Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
	EndIf

Next _nX

_oPrinter:SayAlign(_nLin,_aCol[1],_cUltBanc,_oFontL,500,100,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,_aCol[2],getBcoName(_cUltBanc),_oFontL,500,100,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,_aCol[4]-50,TransForm(_nSubTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
_nLin += 10

If _cUltBanc $ _cBancos
	aAdd(_aCC,{_cUltBanc,_nSubTotal})
Else
	_nTedDoc+=_nSubTotal
EndIf

_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

_oPrinter:SayAlign(_nLin,_aCol[1],"Bordero para CNAB" ,_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

// Lista bancos com pagto credito em CC
For _nX := 1 To Len(_aCC)
	_oPrinter:SayAlign(_nLin,_aCol[1],_aCC[_nX,1],_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[2],getBcoName(_aCC[_nX,1]),_oFontL,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[4]-50,TransForm(_aCC[_nX,2],"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
	_nLin += 10
	_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
	_nLin += 10
	If _nLin > 750 // Salto de Página
		_oPrinter:EndPage()
		_oPrinter:StartPage()
		Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
	EndIf
Next _nX

If _nLin > 750-120 // Salto de Página - testo para ver se consigo imprimir o último bloco inteiro
	_oPrinter:EndPage()
	_oPrinter:StartPage()
	Cabec(_oPrinter,@_nLin,_aCol,_nSizePage,.T.)
EndIf
_oPrinter:SayAlign(_nLin,_aCol[1],"TED/DOC",_oFontL,500,100,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,_aCol[4]-50,Transform(_nTedDoc,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

_oPrinter:SayAlign(_nLin,_aCol[1],"Total Geral",_oFontL,500,100,ALIGN_H_LEFT)
_oPrinter:SayAlign(_nLin,_aCol[4]-50,Transform(_nTotal,"@E 999,999,999.99"),_oFontL,500,100,ALIGN_H_RIGHT)
_nLin += 10

_oPrinter:SayAlign(_nLin,_aCol[1],Replicate("-",60) ,_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 20

_oPrinter:SayAlign(_nLin,_aCol[1],"Setor: '"+MV_PAR01 + "' - "+Posicione("ZL2",1,xFilial("ZL2")+MV_PAR01,"ZL2_DESCRI"),_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],"Linha: '" + MV_PAR10 + "' Ate '"+ MV_PAR11 + "'",_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],"Mix:   '"+MV_PAR02 + "' - Versao: 1",_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],"Fornecedor: '"+MV_PAR03 + "' ao '" + MV_PAR05 + "'",_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10
_oPrinter:SayAlign(_nLin,_aCol[1],"Banco: '" + MV_PAR07 + "' ao '" + MV_PAR08 + "'",_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 20
_oPrinter:SayAlign(_nLin,_aCol[1],"Dia do Pagto: "+DToC(MV_PAR09)+"   Ass: _____________________________",_oFontL,500,100,ALIGN_H_LEFT)
_nLin += 10

_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
_nLin += 10

Return

/*
===============================================================================================================================
Programa----------: Cabec
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/09/2021
Descrição---------: Imprimi cabeçalho do relatório
Parametros--------: _oPrinter,_nLin,_aCol,_nSizePage,_lCab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Cabec(_oPrinter,_nLin,_aCol,_nSizePage,_lCab)

Default _lCab := .T.
_nLin := 10


_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
If File( "LGRL01.BMP" )
	_oPrinter:SayBitmap(_nLin+2,0,"LGRL01.BMP",100,020)
EndIf
_nLin += 20
_oPrinter:SayAlign(_nLin-10,0,RptFolha + cValToChar(_oPrinter:nPageCount),_oFontL,_nSizePage-050,100,,ALIGN_H_RIGHT)
_oPrinter:SayAlign(_nLin,0,AllTrim(MV_PAR13),_oFontT,_nSizePage-050,100,,ALIGN_H_CENTER)
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
	_oPrinter:SayAlign(_nLin,_aCol[1],"Código",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[2],"Loja",_oFontC,150,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[3],"Produtor",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[4],"CNPJ/CPF",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[5],"Conta",_oFontC,500,100,ALIGN_H_LEFT)
	_oPrinter:SayAlign(_nLin,_aCol[6]+40,"Valor",_oFontC,500,100,ALIGN_H_RIGHT)
	_nLin += 15
EndIf
_oPrinter:Line(_nLin,_aCol[1],_nLin,_nSizePage-050,,"-4")
_nLin += 10

Return
