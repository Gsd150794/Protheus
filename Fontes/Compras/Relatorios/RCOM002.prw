/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
Alex Wallauer |09/06/2025| Chamado 50934. Ajuste no tratamento da descrição do corpo do e-mail.
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Igor Melgaço  |30/10/2025| Chamado 52779. Ajuste no corpo do e-mail para inclusão de comunicado sobre Reforma Tributária.
Igor Melgaço  |31/10/2025| Chamado 52779. Ajuste no corpo do e-mail nas clausulas de atenção 5 e 6.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "FONT.CH"
#Include "FWPrintSetup.ch"

/*
===============================================================================================================================
Programa----------: RCOM002
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 04/02/2016
Descrição---------: Rotina responsável por emitir pedido de compras em PDF por e-mail, apenas chama a rotina principal com
------------------: timer para que o usuário possa ver que o sistema está rodando e não está parado.
Parametros--------: _cAlias		- Alias da Tabela
------------------: _nRecno		- R_E_C_N_O_ do Registro Posicionado
------------------: _nOpc		- Opção selecionada no menu aRotina
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM002

Private _aArea:= SC7->(GetArea())//Private pq uso para restaurar o SC7 para imprimir o rodape
Private cPathSrv:=GETMV("MV_RELT")

//Grava log de utilização
u_itlogacs()

If SC7->C7_CONAPRO == "L" .Or. IsInCallStack("U_RCOM006")
	FWMsgRun(,{|oProc| RCOM002E(oProc)},,"Aguarde, gerando arquivo PDF...")
Else
	U_ITMsg("PC não autorizado para envio de e-mail ao Fornecedor. Pedido não liberado.","Pedido Inválido",,1)
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: RCOM002E
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 04/02/2016
Descrição---------: Rotina responsável por emitir pedido de compras em PDF por e-mail
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002E(oProc)
Local _aArea2  := FWGetArea()
Local _cNumPC  := SC7->C7_NUM  , nI
Local _aParRet :={}
Local _aParAux :={} 

Private _cFilial	:= SC7->C7_FILIAL
//Define fontes do Relatorio
Private oFont10		:= TFont():New("Arial",,10,,.T.,,,,,.F.,.F.)
Private oFont14		:= TFont():New("Arial",,14,,.T.,,,,,.F.,.F.)
Private oFont08		:= TFont():New("Arial",,08,,.F.,,,,,.F.,.F.)
Private oFont08N	:= TFont():New("Arial",,08,,.T.,,,,,.F.,.F.)

lImpObs := .F.                                                              
MV_PAR01:=SC7->C7_NUM
MV_PAR02:=SC7->C7_NUM

If IsInCallStack("U_RCOM006")
	lImpObs := .T.
	//Pode: BRANCO E BRANCO , PREENCHIDO E BRANCO , PREENCHIDO E PREENCHIDO
	
	aAdd( _aParAux , { 1 , "No. PC de" , MV_PAR01, "@!"  , ""    , ""        , "" , 060 , .F. } )
	aAdd( _aParAux , { 1 , "No. PC ate", MV_PAR02, "@!"  , ""    , ""        , "" , 060 , .F. } )
	
	For nI := 1 To Len( _aParAux )
		aAdd( _aParRet , _aParAux[nI][03] )
	Next nI
   While .T.

      If !ParamBox( _aParAux , "Seleção de dados do Relação de Titulos CLAIMs" , @_aParRet ,)
         Return .T.
       EndIf

	   //Pode: BRANCO E BRANCO , PREENCHIDO E BRANCO , PREENCHIDO E PREENCHIDO
	   //NÃO Pode: BRANCO E PREENCHIDO E O PRIMEIRO > SEGUNDO
	   If  !Empty(MV_PAR02) .And. (MV_PAR01 > MV_PAR02)
           U_ITMsg("Intervalo INVALIDO",'No. Titulo ' ,"Tente novamente com um Intervalo Valido",3)
           Loop
       ElseIf Empty(MV_PAR01) .And. !Empty(MV_PAR02)
           U_ITMsg("Intervalo INVALIDO",'No. Titulo ' ,'Quando preencher campo "No. PC ate" obrigatoriamente deve se preencher o campo "No. PC de" ',3)
           Loop
       EndIf
       Exit
   EndDo

   If Empty(MV_PAR01) .And. Empty(MV_PAR02)
	  MV_PAR01:=SC7->C7_NUM
	  MV_PAR02:=SC7->C7_NUM
	  _cNumPC :=SC7->C7_NUM
   EndIf	  

ElseIf MsgYesNo("Deseja Imprimir OBSERVAÇÃO para o FORNECEDOR ?")   
   lImpObs := .T.
EndIf  

cFileName := "pedido_compras_" + Lower(MV_PAR01) + "_" + _cFilial + ".pdf"

If IsInCallStack("U_RCOM006")//cFilePrintert,[nDevice],lAdjustToLegacy, cPathInServer, lDisabeSetup,lTReport,@oPrintSetup,cPrinter],lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] 
	oPrint := FWMSPrinter():New( cFileName   , IMP_PDF , .F.           , cPathSrv     , .F.         ,        ,            ,         , .F.    , )
	If !(oPrint:nModalResult == PD_OK)
		oPrint:Deactivate() 
		Return
	EndIf
EndIf

If MV_PAR01 == MV_PAR02
	
   RCOM002Imp(oProc,MV_PAR01)
	
Else

	cQry := "SELECT DISTINCT C7_NUM  "
	cQry += "FROM " + RetSqlName("SC7") + " "
	cQry += "WHERE C7_FILIAL = '" + _cFilial + "' "
	If !Empty(MV_PAR02)
		cQry += " AND C7_NUM BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'"
	ElseIf !Empty(MV_PAR01)
		cQry += " AND C7_NUM >= '" + MV_PAR01 + "'"
	EndIf
	cQry += "  AND D_E_L_E_T_ = ' ' "
	cQry := ChangeQuery(cQry)
	_cAlias := GetNextAlias()
	MPSysOpenQuery( cQry , _cAlias )
	
	(_cAlias)->(DBGoTop())

	nConta:=0
	While !(_cAlias)->(Eof())
		If nConta >= 50
           U_ITMsg("Limite de Geração de PDF atingido: "+AllTrim(Str(nConta)),'Atenção!',;
                    "Utilize / Limpe os PFDs ["+cPathSrv+"] gerados e entre novamente e continue o intervalo de onde parou",3)
		   Exit
		EndIf
		nConta++
		RCOM002Imp(oProc,(_cAlias)->C7_NUM)
		
		(_cAlias)->(DBSkip())
		
	EndDo
	
EndIf

FWRestArea(_aArea2)

Return .T.

/*
===============================================================================================================================
Programa----------: RCOM002Imp
Autor-------------: Alex Wallauer
Data da Criacao---: 21/10/2019
Descrição---------: Rotina responsável por emitir pedido de compras em PDF e/ou por e-mail
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002Imp(oProc,_cNumPC)

Local _cAnexo		:= ""
Local _cEmail		:= ""
Local _cCc			:= ""
Local _cAssunto		:= ""
Local _cMens		:= ""
Local nLinIni		:= 10		// Linha Lateral (inicial) Esquerda
Local nColMax		:= 0835		// Para implementar layout A4
Local nCont			:= 0
Local nTotDesc		:= 0
Local nTotal		:= 0
Local nTotMerc		:= 0
Local nTotIpi		:= 0
Local nTotIcms		:= 0
Local nTotDesp		:= 0
Local nTotFrete		:= 0
Local nTotSeguro	:= 0
Local aValIVA		:= {}
Local cFiltro		:= ""
Local cFrete		:= ""
Local cCodTra		:= ""
Local cLojTra		:= ""
Local cTpFrt		:= ""
Local cNReduz		:= ""
Local cCidUni		:= ""
Local cNomUsr		:= ""
Local lPagina		:= .T.
Local dEmissao		:= CtoD("//")
Local cCompra		:= ""
Local cCond			:= ""
Local cMailCom		:= ""
Local cDescPro      := ""           
Local cObs          := ""
Local cObsAp		:= ""
Local nConta 		:= 0
Local _nBASEICM  	:= 0
Local _nALIQICM  	:= 0
Local _nVALORICMS	:= 0
Local _nVALORIPI 	:= 0
Local _bGetUsr		:= {|x| UsrFullName(x)}
Local _cUser		:= RetCodUsr()

Private oPrint		:= Nil
Private nLinAux		:= 0
Private nColIni		:= 10		// Coluna Lateral (inicial) Esquerda
Private ltemmil		:= .F.

cFileName := "pedido_compras_" + Lower(_cNumPC) + "_" + _cFilial + ".pdf"
//==========================
// Cria Arquivo do Relatorio
//==========================
oPrint := FWMSPrinter():New( cFileName   , IMP_PDF , .F.           , cPathSrv     , .T.         ,        ,            ,         , .T. )

//=====================================
// Configura modo Paisagem de Impressao
//=====================================
oPrint:SetLandscape()

//=============================
// Define impressao em papel A4
//=============================
oPrint:SetPaperSize(9)
oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior
	
//=========================================================
// Se enviar por e-mail nao abre o arquivo apos a impressao
//=========================================================
oPrint:SetViewPDF(.F.)
oPrint:cPathPDF := cPathSrv	// Caso seja utilizada impressão em IMP_PDF

oPrint:StartPage()

//==================================
// Chama função para desenhar o grid
//==================================
RCOM002G()

MaFisEnd()
R002FIniPC(_cNumPC,,,cFiltro,_cFilial,oProc)

DBSelectArea("SC7")
SC7->(DBSetOrder(1))
SC7->(DBSeek(_cFilial + _cNumPC))

ltemmil		:= .F. //zera flag de produto grupo 1000-servicos

While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC

	If Posicione("SB1",1,xFilial("SB1")+SC7->C7_PRODUTO,'B1_GRUPO') == '1000' .And. SC7->C7_FILIAL = '01'
		ltemmil := .T.
	EndIf
	
	oProc:cCaption := ("2-Lendo Item: "+SC7->C7_PRODUTO)
	ProcessMessages()
	
	If SC7->C7_RESIDUO <> "S"

	   nConta ++

		nLinIni	:= 005
		nColIni	:= 000
		nCont++
		
		If nLinAux > (nLinIni+590)
			lPagina := .T.
			oPrint:EndPage()
			oPrint:StartPage()
			RCOM002G()
			
			nLinIni	:= 005
			nColIni	:= 000
			nCont++
		EndIf
		
		If nCont = 1 .Or. lPagina

           lPagina := .F.			
		   RCOM002Cab(_cNumPC,_cFilial,nLinIni,nColIni)
			
			If nCont == 1
				cFrete		:= SC7->C7_TPFRETE
				cObsAp		:= AllTrim(SC7->C7_I_OBSAP)
				cCodTra		:= SC7->C7_I_CDTRA
				cLojTra		:= SC7->C7_I_LJTRA
				cTpFrt		:= SC7->C7_I_TPFRT
				_cEmail		:= Posicione("SA2",1,xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA, "A2_EMAIL")
				cNReduz		:= Posicione("SA2",1,xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA, "A2_NREDUZ")
				cCidUni		:= SubStr(AllTrim(SM0->M0_CIDCOB),1,50)
				dEmissao	:= SC7->C7_EMISSAO
				cCompra		:= SubStr(Eval(_bGetUsr,SC7->C7_USER), 1, At(" ", Eval(_bGetUsr,SC7->C7_USER))-1)
				cNomUsr		:= AllTrim(Eval(_bGetUsr,SC7->C7_USER))
				cCond		:= AllTrim(Posicione("SE4",1,xFilial("SE4") + SC7->C7_COND,"E4_DESCRI"))
				If _cUser == SC7->C7_USER
				   cMailCom:= AllTrim(UsrRetMail(SC7->C7_USER))
				Else
				   cMailCom:= AllTrim(UsrRetMail(SC7->C7_USER)) + "," + AllTrim(UsrRetMail(_cUser))
				EndIf
			EndIf
			
		EndIf

  		If lImpObs
			cObs += AllTrim(SC7->C7_OBS)+" "
		Else
			cObs := ""
		EndIf  
		
		oPrint:Say( (nLinAux) , (nColIni+020) , SC7->C7_ITEM				, oFont08 )
		oPrint:Say( (nLinAux) , (nColIni+045) , SC7->C7_PRODUTO				, oFont08 )
		
		If AllTrim(SC7->C7_I_DESCD) $ AllTrim(SC7->C7_DESCRI)
			cDescPro := SubStr(AllTrim(SC7->C7_DESCRI),1,70)
		Else
			cDescPro := AllTrim(SC7->C7_DESCRI) + " " + AllTrim(SC7->C7_I_DESCD)
		EndIf
		
		oPrint:Say( (nLinAux) , (nColIni+400) , SC7->C7_UM					, oFont08 )
		
		oPrint:SayAlign( (nLinAux-8),(nColIni+435),Transform(SC7->C7_QUANT, PesqPict("SC7","C7_QUANT"))		,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		
		_cValor:=MCOM002Totais(SC7->C7_MOEDA,0,SC7->C7_PRECO,.F.)
		oPrint:SayAlign( (nLinAux-8),(nColIni+495),_cValor			,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		//	oPrint:SayAlign( (nLinAux-8),(nColIni+495),Transform(SC7->C7_PRECO, "@E 999,999,999.99999")			,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		_cValor:=MCOM002Totais(SC7->C7_MOEDA,0,SC7->C7_VLDESC,.F.)
		oPrint:SayAlign( (nLinAux-8),(nColIni+545),_cValor	,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		//	oPrint:SayAlign( (nLinAux-8),(nColIni+545),Transform(SC7->C7_VLDESC, PesqPict("SC7","C7_VLDESC"))	,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		_cValor:=MCOM002Totais(SC7->C7_MOEDA,0,SC7->C7_TOTAL,.F.)
		oPrint:SayAlign( (nLinAux-8),(nColIni+595),_cValor		,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		//	oPrint:SayAlign( (nLinAux-8),(nColIni+595),Transform(SC7->C7_TOTAL, PesqPict("SC7","C7_TOTAL"))		,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		_cValor:=MCOM002Totais(SC7->C7_MOEDA,0,SC7->C7_VALIPI,.F.)
		oPrint:SayAlign( (nLinAux-8),(nColIni+645),_cValor	,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		//	oPrint:SayAlign( (nLinAux-8),(nColIni+645),Transform(SC7->C7_VALIPI, PesqPict("SC7","C7_VALIPI"))	,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		_cValor:=MCOM002Totais(SC7->C7_MOEDA,0,SC7->C7_ICMSRET,.F.)
		oPrint:SayAlign( (nLinAux-8),(nColIni+695),_cValor	,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		//	oPrint:SayAlign( (nLinAux-8),(nColIni+695),Transform(SC7->C7_ICMSRET, PesqPict("SC7","C7_ICMSRET"))	,oFont08, 55, 14, CLR_BLACK, 1, 0 )
		
		oPrint:Say( (nLinAux) , (nColIni+770) , DToC(SC7->C7_DATPRF)	, oFont08 )
		
		If (Len(AllTrim(cDescPro))) > 70
			RCOM002A(cDescPro)//Descricao do produto
		Else
			oPrint:Say( (nLinAux) , (nColIni+100) , AllTrim(cDescPro), oFont08 )
		EndIf

		nLinAux := nLinAux + 010
		
		nTotDesc	+= SC7->C7_VLDESC
		
		nTotal		:= nTotal + SC7->C7_TOTAL
		
	   nTotMerc	   := MaFisRet(,'NF_TOTAL')
	   //nTotIpi   := MaFisRet(,'NF_VALIPI')
	   _nVALORIPI  := MaFisRet(nConta,"IT_VALIPI")
	   _nVALORICMS := MaFisRet(nConta,"IT_VALICM")
	   If SB1->(DBSeek( xFilial("SB1")+SC7->C7_PRODUTO)) 
	   	  If SB1->B1_TIPO = "SV"
	   	  	 nTotIpi += 0
	   	  	 nTotIcms+= 0

	   		 MaFisLoad("IT_VALIPI",0,nConta)
	   		 MaFisLoad("IT_VALICM",0,nConta)
	   	  ElseIf !SB1->B1_TIPO $ "IN/EM/PA" .And. _nVALORIPI <> 0
	           
	   		_nBASEICM  := MaFisRet(nConta,"IT_BASEICM")
	   		_nALIQICM  := MaFisRet(nConta,"IT_ALIQICM")	   		
	   		_nVALORICMS:= Round((_nVALORIPI+_nBASEICM)*(_nALIQICM/100),2)
   
	   		nTotIpi    += _nVALORIPI 
	   		nTotIcms   += _nVALORICMS 
	           
	   		MaFisLoad("IT_BASEICM",(_nVALORIPI+_nBASEICM),nConta)
	   		MaFisLoad("IT_VALICM" ,_nVALORICMS,nConta)

	   	  Else
	   	  	nTotIpi    += _nVALORIPI
	   	  	nTotIcms   += _nVALORICMS
	   	  EndIf
	   Else
	   	  nTotIcms	:= MaFisRet(,'NF_VALICM')
	   	  nTotDesp	:= MaFisRet(,'NF_DESPESA')
	   EndIf
	   nTotFrete	:= MaFisRet(,'NF_FRETE')
	   nTotSeguro	:= MaFisRet(,'NF_SEGURO')
	   aValIVA		:= MaFisRet(,"NF_VALIMP")
	EndIf

	SC7->(DBSkip())

EndDo

SC7->(DBSeek(_cFilial + _cNumPC))//volta para o PC 
nTam:=185
If !Empty(cObs)
	oPrint:Say((nLinAux),(nColIni+020),"OBSERVAÇÕES DOS ITENS:" ,oFont08N)
    nLinAux+= 10
EndIf   
While !Empty(cObs) .And. !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC
	
	oProc:cCaption := ("2-Lendo Item: "+SC7->C7_PRODUTO)
	ProcessMessages()
	
	If SC7->C7_RESIDUO <> "S"

		nLinIni	:= 005
		nColIni	:= 000
		nCont++
		
		If nLinAux > (nLinIni+590)
			lPagina := .T.
			oPrint:EndPage()
			oPrint:StartPage()
			RCOM002G()
			
			nLinIni	:= 005
			nColIni	:= 000
			nCont++
		EndIf
		
		If nCont = 1 .Or. lPagina
           lPagina := .F.			
		   RCOM002Cab(_cNumPC,_cFilial,nLinIni,nColIni)
		EndIf
		
        If !Empty(SC7->C7_OBS)
		   oPrint:Say((nLinAux),(nColIni+020),SC7->C7_ITEM,oFont08 )
		   If Len(AllTrim(SC7->C7_OBS)) > nTam
	          oPrint:Say((nLinAux),(nColIni+045),+MEMOLINE(AllTrim(SC7->C7_OBS),nTam,1),oFont08)
	          nLinAux+= 10
	          oPrint:Say((nLinAux),(nColIni+045),+MEMOLINE(AllTrim(SC7->C7_OBS),nTam,2),oFont08)
	       Else
	          oPrint:Say((nLinAux),(nColIni+045),+AllTrim(SC7->C7_OBS),oFont08)
	       EndIf
	       nLinAux+= 10
	    EndIf   
		
	EndIf

	SC7->(DBSkip())

EndDo
SC7->(DBSeek(_cFilial + _cNumPC))//volta para o PC 


oProc:cCaption := ("3-Imprimindo Dados...")
ProcessMessages()

If nLinAux > (nLinIni+472)
	lPagina := .T.
	oPrint:EndPage()
	oPrint:StartPage()
	RCOM002G()

    RCOM002Cab(_cNumPC,_cFilial,nLinIni,nColIni)

	//=======================================
	// Chama função para impressão dos totais
	//=======================================
	RCOM002T(nColMax, nLinIni, nColIni, cTpFrt, cFrete, cObsAp, cCodTra, cLojTra, nTotal, nTotMerc, nTotDesc, nTotIpi, nTotFrete, nTotIcms, nTotDesp, nTotSeguro, dEmissao, cCompra, cCond, cObs,oProc)
Else
	//=======================================
	// Chama função para impressão dos totais
	//=======================================
	RCOM002T(nColMax, nLinIni, nColIni, cTpFrt, cFrete, cObsAp, cCodTra, cLojTra, nTotal, nTotMerc, nTotDesc, nTotIpi, nTotFrete, nTotIcms, nTotDesp, nTotSeguro, dEmissao, cCompra, cCond, cObs,oProc)
EndIf

PRIVATe	_cOrigem :=oPrint:cPathPDF+cFileName

oProc:cCaption := ("5-Gravando PDF: "+_cOrigem)
ProcessMessages()

oPrint:EndPage()

If IsInCallStack("U_RCOM006")
   oPrint:lViewPDF := .F.
Else
   oPrint:lViewPDF := .F.
EndIf   

LjMsgRun( "Gravando PDF: "+_cOrigem , "Aguarde!" , {|| oPrint:Preview() } )//Visualiza antes de imprimir

FreeObj(oPrint)

If !IsInCallStack("U_RCOM006")

    _cAnexo1  :=_cOrigem
	If FILE(_cOrigem) 
	   _cDestino:=AllTrim(GETMV("MV_RELT",,"\SPOOL\"))
	   If !_cDestino $ _cOrigem//sENÃO Esta no \SPOOL\ senão deixa
	      CPYT2S(_cOrigem,_cDestino,.F.) // Terminal To Server
	   EndIf
	   _cAnexo1  :=_cDestino+cFileName
	EndIf
    _cAnexo:=_cAnexo1+";\workflow\htm\aviso_importante.pdf;\workflow\htm\comunicado_reforma_tributaria.pdf"
	
	_cAssunto := "PC - " + _cNumPC + " - " + SubStr(AllTrim(SM0->M0_CIDCOB),1,50) + " - " + AllTrim(SM0->M0_ESTCOB) + ":" + cNReduz + Space(30)
	
	//=================================
	// Chama a função da tela de E-mail
	//=================================
	RCOM002M(_cAnexo,@_cEmail,@_cCc,@_cAssunto,@_cMens,cMailCom,cNReduz,_cFilial,_cNumPC,cCidUni,cNomUsr)

    RCOM002D(cPathSrv +cFileName)
    RCOM002D(_cAnexo1)

Else

	cGetAnx := cPathSrv +cFileName///spool
	_cPathLocal:=GetTempPath()
	If File(cGetAnx)
		//Copia arquivo da spool para estação local
		If !CpyS2T(cGetAnx,_cPathLocal)
			U_ITMsg("Não foi possivel copiar o arquivo "+cGetAnx+" para "+_cPathLocal,'Atenção!',"Feche o arquivo "+cGetAnx+", caso aberto,e tente novamente",1)
		Else

            _cOrigem2:=StrTran( _cOrigem, cPathSrv,_cPathLocal ) 
	        
	        ShellExecute("open", _cOrigem2, "", _cPathLocal, 1) 

   	        U_ITMsg("O arquivo  "+Upper(cFileName)+"  foi gerado na PASTA: "+CHR(13)+CHR(10)+_cPathLocal,'Atenção!',,2)

		EndIf

	Else	
	    U_ITMsg("Não foi possivel copiar o arquivo "+cGetAnx+" para "+_cPathLocal,'Atenção!',"Arquivo "+cGetAnx+" não existe.",1)
	EndIf

EndIf

Return

/*
===============================================================================================================================
Programa----------: RCOM002G
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 04/02/2016
Descrição---------: Rotina responsável por criar o layout de impressão
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002G

Local nLinIni		:= 0		// Linha Lateral (inicial) Esquerda
Local nColIni		:= 0		// Coluna Lateral (inicial) Esquerda
Local nLinMax		:= 0600		// Para implementar layout A4
Local nColMax		:= 0835		// Para implementar layout A4
Local cPathImg		:= GetSrvProfString("Startpath","")
Local cFileImg		:= ""

nLinIni	:= 005
nColIni	:= 000

cFileImg := cPathImg + "logoboleto.BMP"

//==============
// Box Principal
//==============
oPrint:Box( nLinIni + 008, nColIni + 010, nLinMax, nColMax, "-4")

//=========
// Logotipo
//=========
_nLinLogo:=nLinIni+9
oPrint:SayBitmap( _nLinLogo , nColIni + 018 , cFileImg , 170 , 058 )
//oPrint:SayBitmap( nLinIni + 010 , nColIni + 018 , cFileImg ,  100 , 020)//170 , 058 )

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 145 , nColIni + 010 , nLinIni + 145 , nColMax	)

//===============
// Linha Vertical
//===============
oPrint:Line( nLinIni + 008 , nColIni + 200 , nLinIni + 145 , nColIni + 200	)

//===============
// Linha Vertical
//===============
oPrint:Line( nLinIni + 008 , nColIni + 650 , nLinIni + 145 , nColIni + 650	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 050 , nColIni + 200 , nLinIni + 050 , nColIni + 650	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 165 , nColIni + 010 , nLinIni + 165 , nColMax	)

Return

/*
===============================================================================================================================
Programa----------: RCOM002T
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 04/02/2016
Descrição---------: Função responsável pela impressão dos totais e seu layout
Parametros--------: _cAnexo		- Endereço do arquivo do Pedido de Compras em PDF
------------------: _cEmail		- Endereço de E-mail para qual será enviado o Pedido de Compras
------------------: _cCc		- Endereço de E-mail que está no campo Com Cópia
------------------: _cAssunto	- Assunto do E-mail
------------------: _cMens		- Mensagem de texto para o corpo do E-mail
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002T(nColMax, nLinIni, nColIni, cTpFrt, cFrete, cObsAp, cCodTra, cLojTra, nTotal, nTotMerc, nTotDesc, nTotIpi, nTotFrete, nTotIcms, nTotDesp, nTotSeguro, dEmissao, cCompra, cCond, cObs,oProc)

Local cTpFrete	:= ""
Local nLinMax	:= 0600		// Para implementar layout A4

oProc:cCaption := ("4-Imprimindo totais...")
ProcessMessages()

oPrint:Say( (nLinIni+490) , (nColIni+020) , "Condição de Pagamento: "													, oFont08 )
oPrint:Say( (nLinIni+499) , (nColIni+020) , cCond																		, oFont08 )

If SC7->C7_MOEDA <> 1
	oPrint:Say( (nLinIni+511) , (nColIni+020) ,"Valores do Pedido em : "+Upper(AllTrim(GETMV("MV_MOEDA"+AllTrim(Str(SC7->C7_MOEDA))))), oFont08 )
	oPrint:Say( (nLinIni+520) , (nColIni+020) ,"Data da Taxa : "+DToC(SC7->C7_EMISSAO)										, oFont08 )
	oPrint:Say( (nLinIni+529) , (nColIni+020) ,"Taxa : "+AllTrim(Transform(SC7->C7_TXMOEDA,PesqPict("SC7","C7_TXMOEDA"))), oFont08 )
EndIf

oPrint:Say( (nLinIni+490) , (nColIni+180) , "Comprador:"																, oFont08 )
oPrint:Say( (nLinIni+499) , (nColIni+180) , cCompra																		, oFont08 )
oPrint:Say( (nLinIni+490) , (nColIni+300) , "Data de Emissão:"															, oFont08 )
oPrint:Say( (nLinIni+499) , (nColIni+300) , DToC(dEmissao)																, oFont08 )

oPrint:Say( (nLinIni+490) , (nColIni+440) , "Total das Mercadorias:"													, oFont08 )
oPrint:Say( (nLinIni+500) , (nColIni+440) , "Total com Impostos:"														, oFont08 )
oPrint:Say( (nLinIni+510) , (nColIni+440) , "Total de Descontos:"														, oFont08 )

oPrint:Say( (nLinIni+520) , (nColIni+440) , "IPI:"																		, oFont08 )
oPrint:Say( (nLinIni+530) , (nColIni+440) , "Frete:"																	, oFont08 )

oPrint:Say( (nLinIni+540) , (nColIni+440) , "ICMS:"																		, oFont08 )
oPrint:Say( (nLinIni+550) , (nColIni+440) , "Despesas:"																	, oFont08 )
oPrint:Say( (nLinIni+560) , (nColIni+440) , "Seguro:"																	, oFont08 )

oPrint:Say( (nLinIni+580) , (nColIni+550) , "Total Geral:"																, oFont10 )

oPrint:Say( (nLinIni+540) , (nColIni+020) , "Transportadora:"															, oFont08 )

If cFrete == "C"
	cTpFrete := "CIF"
ElseIf cFrete == "F"
	cTpFrete := "FOB"
ElseIf cFrete == "T"
	cTpFrete := "TERCEIROS"
ElseIf cFrete == "S"
	cTpFrete := "SEM FRETE"
EndIf

oPrint:Say( (nLinIni+530) , (nColIni+520) , cTpFrete , oFont08 )

If !Empty(cCodTra) .And. !Empty(cLojTra)

	oPrint:Say( (nLinIni+540) , (nColIni+080) , "Código: " + cCodTra + " Loja: " + cLojTra , oFont08 )
	oPrint:Say( (nLinIni+550) , (nColIni+020) , "Razão Social: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra,"A2_NOME"),1,30)) , oFont08 )
	oPrint:Say( (nLinIni+560) , (nColIni+020) , "Nome Fantasia: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_NREDUZ"),1,30)) , oFont08 )
	oPrint:Say( (nLinIni+570) , (nColIni+020) , "CNPJ: " + Transform(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_CGC"), PesqPict("SA2","A2_CGC")) , oFont08 )
	oPrint:Say( (nLinIni+580) , (nColIni+020) , "Ins. Estad.: " + Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_INSCR") , oFont08 )

	oPrint:Say( (nLinIni+540) , (nColIni+275) , "Bairro: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_BAIRRO"),1,25)) , oFont08 )
	oPrint:Say( (nLinIni+550) , (nColIni+275) , "Cidade: " + AllTrim(SubStr(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_MUN"),1,30)) + " - " + "Estado: " + Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_EST") , oFont08 )
	oPrint:Say( (nLinIni+560) , (nColIni+275) , "Telefone: (" + AllTrim(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_DDD")) + ")" + SubStr(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_TEL"),1,4) + "-" + SubStr(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_TEL"),5,4) , oFont08 )
	oPrint:Say( (nLinIni+570) , (nColIni+275) , "Contato: " + AllTrim(Posicione("SA2", 1, xFilial("SA2")+cCodTra+cLojTra, "A2_CONTATO")) , oFont08 )
	oPrint:Say( (nLinIni+580) , (nColIni+275) , "Obs. Frete: " + If(cTpFrt == "1","Entregar na Transportadora","Solicitar Coleta pela Transportadora" ) , oFont08 )

EndIf

FWRestArea(_aArea)//volta SC7 de quando entro no programa
nLarg:=99
nCol1:=730
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotal,.F.)
oPrint:SayAlign( (nLinIni+482),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotal+nTotIpi,.F.)
oPrint:SayAlign( (nLinIni+492),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotDesc,.F.)
oPrint:SayAlign( (nLinIni+502),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotIpi,.F.)
oPrint:SayAlign( (nLinIni+512),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotFrete,.F.)
oPrint:SayAlign( (nLinIni+522),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotIcms,.F.)
oPrint:SayAlign( (nLinIni+532),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotDesp,.F.)
oPrint:SayAlign( (nLinIni+542),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,nTotSeguro,.F.)
oPrint:SayAlign( (nLinIni+552),(nColIni+nCol1),_cTotais,oFont08, nLarg, 14, CLR_BLACK, 1, 0 )
_cTotais:=MCOM002Totais(SC7->C7_MOEDA,SC7->C7_TXMOEDA,(nTotMerc),.F.)
oPrint:SayAlign( (nLinIni+572),(nColIni+700),_cTotais,oFont10, 99, 16, CLR_BLACK, 1, 0 ) 

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 482 , nColIni + 010 , nLinIni + 482 , nColMax	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 532 , nColIni + 010 , nLinIni + 532 , nColMax	)

//===============
// Linha Vertical
//===============
oPrint:Line( nLinIni + 482 , nColIni + 438 , nLinMax , nColIni + 438	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 492 , nColIni + 438 , nLinIni + 492 , nColMax	)

//=================
// Linha Horizontal
//=================
If SC7->C7_MOEDA <> 1
   oPrint:Line( nLinIni + 502 , nColIni + 010 , nLinIni + 502 , nColMax	)
Else
   oPrint:Line( nLinIni + 502 , nColIni + 438 , nLinIni + 502 , nColMax	)
EndIf

//===============
// Linha Vertical
//===============
oPrint:Line( nLinIni + 482 , nColIni + 175 , nLinIni + 532 , nColIni + 175	)

//===============
// Linha Vertical
//===============
oPrint:Line( nLinIni + 482 , nColIni + 295 , nLinIni + 532 , nColIni + 295	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 512 , nColIni + 438 , nLinIni + 512 , nColMax	)//438

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 522 , nColIni + 438 , nLinIni + 522 , nColMax	)//438

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 542 , nColIni + 438 , nLinIni + 542 , nColMax	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 552 , nColIni + 438 , nLinIni + 552 , nColMax	)

//=================
// Linha Horizontal
//=================
oPrint:Line( nLinIni + 562 , nColIni + 438 , nLinIni + 562 , nColMax	)

//===============
// Linha Vertical
//===============
oPrint:Line( nLinIni + 482 , nColIni + 660 , nLinIni + 562 , nColIni + 660	)

Return

/*
===============================================================================================================================
Programa----------: RCOM002M
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 04/02/2016
Descrição---------: Função responsável por exibir a janela para a digitação dos endereços de email, assunto, mensagem
Parametros--------: _cAnexo		- Endereço do arquivo do Pedido de Compras em PDF
------------------: _cEmail		- Endereço de E-mail para qual será enviado o Pedido de Compras
------------------: _cCc		- Endereço de E-mail que está no campo Com Cópia
------------------: _cAssunto	- Assunto do E-mail
------------------: _cMens		- Mensagem de texto para o corpo do E-mail
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002M(_cAnexo,_cEmail,_cCc,_cAssunto,_cMens,cMailCom,cNReduz,_cFilial,_cNumPC,cCidUni,cNomUsr)

Local oAnexo
Local oAssunto
Local oButCan
Local oButEnv
Local oCc
Local oGetAnx
Local oGetAssun
Local oGetCc
Local oGetPara
Local oMens
Local oPara
Local _csetor := ""
Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local cHtml		:= ""
Local nOpcA		:= 2
Local cGetAnx	:= _cAnexo
Local cGetAssun	:= _cAssunto
Local cGetCc	:= Space(100)
Local cGetPara	:= _cEmail + Space(80)

Private oDlgMail


If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador
	_csetor	:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
EndIf


If Empty(AllTrim(_csetor))
 	_csetor := "Suprimentos"
EndIf

cHtml := 'À '+ cNReduz +','
cHtml += '<br><br>'
cHtml += '&nbsp;&nbsp;&nbsp;Segue anexo Pedido de Compra PC-' + _cNumPC + ' para nossa Unidade Industrial '+ cCidUni +' conforme negociado.<br>'
cHtml += '&nbsp;&nbsp;&nbsp;Favor confirmar o recebimento, retornando com o seu CIENTE!'
cHtml += '<br><br>'
cHtml += '<font color="#FF0000"><b><u>OBSERVAÇÕES IMPORTANTES:</u></b><br><br></font>'
cHtml += '<font color="#FF0000"><b>1)</b>É obrigatória a inclusão das informações do <b>pedido de compra</b> na estrutura do XML (arquivo da nota fiscal eletrônica), nos campos: (i) Tag e (ii) Tag , bem como no campo de dados adicionais.;</font>'
cHtml += '<br><br>'
cHtml += '<font color="#FF0000"><b>2)</b> É obrigatório anexar a Nota Fiscal ao <b>Boleto Bancário</b> de Pagamento;</font>'
cHtml += '<br><br>'
cHtml += '<font color="#FF0000"><b>3)</b> Ao emitir a <b>NFe</b>(Nota Fiscal Eletrônica) para o pedido <b>é obrigatório</b> o envio do <b>arquivo XML da NFe</b> para o e-mail: </font>'
cHtml += '<b><a href="mailto:nfe@italac.com.br">nfe@italac.com.br</a> - ESTA OBRIGAÇÃO FISCAL FICA SOB PENA DO NÃO RECEBIMENTO DA MERCADORIA ATÉ O SEU CUMPRIMENTO!</b>'
cHtml += '<br><br>'
cHtml += '<font color="#FF0000"><b>4)</b> A Italac <b>não autoriza</b> os descontos do(s) título(s) gerados em nossa operação comercial, oportunidade em que estes '
cHtml += 'não devem ser oferecidos a cessão/descontos/negociações perante qualquer terceiro, sejam eles instituição financeiras/factoring ou não. '
cHtml += 'Fica ressalvado ainda que, na ocorrência da indevida cessão/descontos/negociação dos mesmos, estes terão sua recusa formalizada.</font>'
cHtml += '<br><br>'

//Se tem produto grupo 1000 adiciona mensagem de retenção de iss
If ltemmil		
	cHtml += '<font color="#FF0000"><b>5)</b> É obrigatório informar nos documentos que <b>o Local da retenção/incidência do ISSQN</b> dar-se-á no Município de Corumbaíba-GO, a alíquota '
	cHtml += 'a ser aplicada de 3,00%. Em ato contínuo, iremos promover as referidas retenções, direcionando estes recolhimentos aos cofres do referido Município. Os fornecedores'
	cHtml += 'optantes pelo regime Simples Nacional deverão informar no próprio documento fiscal o percentual de ISS para a faixa de receita bruta que estiver sujeito'
	cHtml += 'no mês anterior ao da prestação, para nossa retenção do percentual correspondente. Caso não informado será aplicado a alíquota Local de 3,00%</font>'
	cHtml += '<br><br>'

	cHtml += '<font color="#FF0000"><b>6)</b> <b>ATENÇÃO:</b> A Reforma Tributária terá início em 1º de janeiro de 2026. Segue anexo comunicado importante. '
	cHtml += '<br><br>'
Else
	cHtml += '<font color="#FF0000"><b>5)</b> <b>ATENÇÃO:</b> A Reforma Tributária terá início em 1º de janeiro de 2026. Segue anexo comunicado importante. '
	cHtml += '<br><br>'
EndIf

cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
cHtml += '<br><br>'


cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml += '<tr>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( RetCodUsr() ) ) ) +'</span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=     '</td>'
cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + Posicione("SY1",3,xFilial("SY1") + RetCodUsr(),"Y1_TEL") + '</span>'
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=         '</table>'
cHtml +=     '</td>'
cHtml += '</tr>'
cHtml += '</table>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
cHtml +=             '</span>
cHtml +=             '</p>'
cHtml +=         '</td>'
cHtml +=     '</tr>'
cHtml += '</table>'
cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
cHtml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [ROCOM002] </BR>'
cHtml +=             '</span>'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
cHtml +=         '</td>'
cHtml +=     '</tr>
cHtml += '</table>'

DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  TO 415, 584 COLORS 0, 16777215 PIXEL

	//======
	// Para:
	//======
	@ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//===========
	// Com cópia:
	//===========
	@ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//=========
	// Assunto:
	//=========
	@ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL

	//======
	// Anexo
	//======
	@ 053, 006 Say oAnexo PROMPT "Anexo:" SIZE 019, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ 053, 030 MSGET oGetAnx VAR cGetAnx SIZE 256, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 READONLY PIXEL

	//==========
	// Mensagem:
	//==========
	@ 069, 006 Say oMens PROMPT "Mensagem:" SIZE 030, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
//	_oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
	_oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
    _cHtml:=cHtml
	_oScrAux:Load( cHtml )
	_cPathLocal:=GetTempPath()
	If File(_cOrigem)


		//Copia anexo para estação local
		If !CpyS2T(_cOrigem,_cPathLocal)
		    _cPathLocal:=""
			U_ITMsg("Não foi possivel copiar o arquivo "+_cOrigem+" para "+_cPathLocal,'Atenção!',"Feche o arquivo "+_cOrigem+", caso aberto, tente novamente",1)
		EndIf
	Else	
	    U_ITMsg("Não foi possivel copiar o arquivo "+_cOrigem+" para "+_cPathLocal,'Atenção!',"Arquivo "+_cOrigem+" não existe.",1)
	EndIf

    _cOrigem2:=StrTran( _cOrigem, cPathSrv, _cPathLocal ) 
	
    If !Empty(_cPathLocal)
	   @ 189, 156 BUTTON oButEnv PROMPT "&Visualizar"	SIZE 037, 012 OF oDlgMail ACTION ( ShellExecute("open", _cOrigem2, "", _cPathLocal, 1) ) PIXEL
	EndIf
	@ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
	@ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If nOpcA == 1
   If Empty(cHtml) .Or. cHtml = NIL
      cHtml:=_cHtml
   EndIf
	//====================================
	// Chama a função para envio do e-mail
	//====================================
	cGetPara:=StrTran( cGetPara, ";", "," )
	cGetCc  :=StrTran( cGetCc  , ";", "," )

	U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, cMailCom, cGetAssun, cHtml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

	If !Empty( _cEmlLog )
		//=====================================================================
		// Chama função para gravação do campo de envio de e-mail na tabela SC7
		//=====================================================================
		If !IsInCallStack("U_RCOM006") .And. "SUCESSO" $ Upper(_cEmlLog)
		   RCOM002I(_cFilial, _cNumPC)
		EndIf   

		U_ITMsg( _cEmlLog+CHR(13)+CHR(10)+"E-mail para: "+AllTrim(cGetPara)+CHR(13)+CHR(10)+"CC: "+cGetCc , 'Término do processamento!' , ,3 )
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: RCOM002D
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 11/02/2016
Descrição---------: Função responsável pela exclusão do arquivo pdf gerado no servidor
Parametros--------: cFile	- Caminho + nome do arquivo pdf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002D(cFile)

Local nRet := 0

If File(cFile)
	nRet := fErase(cFile)
	If nRet <> 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "RCOM002"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RCOM00201"/*cMsgId*/, "RCOM00201 - Erro ao excluir o arquivo: " + cFile + " - Erro: " + Str(FError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "RCOM002"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RCOM00202"/*cMsgId*/, "RCOM00202 - Arquivo: " + cFile + " foi excluído com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: formCPFCNPJ
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2016                                      
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function formCPFCNPJ(cCPFCNPJ)

Local cCampFormat := ""	//Armazena o CPF ou CNPJ formatado
   
If Len(AllTrim(cCPFCNPJ)) == 11			//CPF
	cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2) 
Else									//CNPJ
	cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
EndIf
	
Return cCampFormat

/*
===============================================================================================================================
Programa----------: R002FIniPC
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2016
Descrição---------: Inicializa as funções Fiscais com o Pedido de Compras
Parametros--------: ExpC1	- Número do Pedido
				  : ExpC2	- Item do Pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function R002FIniPC(cPedido,cItem,cSequen,cFiltro,cFilScr,oProc)

Local aArea		:= FWGetArea() , D
Local aAreaSC7	:= SC7->(GetArea())
Local cValid	:= ""
Local nPosRef	:= 0
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= ''

Default cSequen	:= ""

_aSC7 := SC7->(DBSTRUCT())

DBSelectArea("SC7")
SC7->(DBSetOrder(1))
If SC7->(DBSeek(xFilial("SC7")+cPedido+cItemDe+AllTrim(cSequen)))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .And. SC7->C7_FILIAL+SC7->C7_NUM == xFilial("SC7")+cPedido .And. ;
			SC7->C7_ITEM <= cItemAte .And. (Empty(cSequen) .Or. cSequen == SC7->C7_SEQUEN)

        oProc:cCaption := ("1-Lendo Item: "+SC7->C7_ITEM)
        ProcessMessages()
		//==============================================================
		// Nao processar os Impostos se o item possuir residuo eliminado
		//==============================================================  
		If  SC7->C7_RESIDUO = "S"		
			DBSelectArea('SC7')
			DBSkip()
			Loop
		EndIf
            
		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)

		For D := 1 TO Len(_aSC7)
		    _cCampo := _aSC7[D][1]
			cValid	:= StrTran(Upper(Getsx3cache(_cCampo,"X3_VALID") )," ","")
			cValid	:= StrTran(cValid,"'",'"')
			If "MAFISREF" $ cValid
				nPosRef  := AT('MAFISREF("',cValid) + 10
				cRefCols := SubStr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )
				// Carrega os valores direto do SC7.           
				MaFisLoad(cRefCols,&("SC7->"+_cCampo),nItem)
			EndIf
		Next D

		MaFisEndLoad(nItem,2)
		DBSelectArea('SC7')
		DBSkip()
	End
EndIf

FWRestArea(aAreaSC7)
FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: RCOM002I
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 16/02/2016
Descrição---------: Função criada para fazer a gravação do campo de envio de e-mail
Parametros--------: ExpC1	- Filial
------------------: ExpC2	- Número do PC
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM002I(_cFilial, _cNumPC)

Local aArea	:= FWGetArea()  

DBSelectArea("SC7")
SC7->(DBSetOrder(1))
SC7->(DBSeek(_cFilial + _cNumPC))

While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cNumPC

	RecLock("SC7", .F.)
		Replace SC7->C7_I_ENVIO With Soma1(SC7->C7_I_ENVIO)
	MSUnLock()

	SC7->(DBSkip())
End

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: RCOM002A
Autor-------------: Jerry 
Data da Criacao---: 23/03/2016
Descrição---------: Função criada para fazer a quebra da Descrição do Produto
Parametros--------: ExpC1	- Descrição do Produto
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function RCOM002A(cTexto)    

Local nCont        := 1        
Local cTextoQbr   := "" 

cTexto:=StrTran( AllTrim(cTexto) , CHR(13)+CHR(10), " ")
             
While nCont <= Len(cTexto)              
	                            
	cTextoQbr:= AllTrim(SubStr(cTexto,nCont,65))
	If !Empty(cTextoQbr)
	   oPrint:Say((nLinAux),(nColIni+100),cTextoQbr,oFont08)
	   nLinAux+= 10
	EndIf
	nCont+= 65

EndDo                    

Return 

/*
===============================================================================================================================
Programa----------: MCOM002Totais()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/09/2019
Descrição---------: RETORNA A DESCRIÇÃO DAS MOEDAS
Parametros--------: _nMoedaSC7,_nTxMoeSC7
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM002Totais(_nMoedaSC7,_nTxMoeSC7,nTotMerc,_lSimbolo)

Static _aAllmoedas:= {}
Default _lSimbolo:=.T.

If Len(_aAllmoedas) = 0 .And. _nMoedaSC7 > 1
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB1")) )
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB2")) )
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB3")) )
   aAdd(_aAllmoedas, "€" )//AllTrim(GETMV("MV_SIMB4"))
   aAdd(_aAllmoedas, AllTrim(GETMV("MV_SIMB5")) )
EndIf   

If _nMoedaSC7 > 1 .And. _nMoedaSC7 < 6
   If _nTxMoeSC7 <> 0// NA MOEDA / EM REAL
      Return  _aAllmoedas[_nMoedaSC7]+" "+AllTrim(Transform(nTotMerc,PesqPict("SC7","C7_TOTAL")))+" / R$ "+AllTrim(Transform( (nTotMerc*_nTxMoeSC7) ,PesqPict("SC7","C7_TOTAL")))
   Else//SÓ NA MOEDA
       If ValType(nTotMerc) = "N"
          Return _aAllmoedas[_nMoedaSC7]+" "+AllTrim(Transform(nTotMerc,PesqPict("SC7","C7_TOTAL")))// NA MOEDA
       Else
          Return _aAllmoedas[_nMoedaSC7]+" "+AllTrim(nTotMerc)// NA MOEDA
       EndIf   
   EndIf   
Else//EM REAL
   If ValType(nTotMerc) = "N"
      Return If(_lSimbolo,"R$ ","")+AllTrim(Transform( nTotMerc ,PesqPict("SC7","C7_TOTAL")))//EM REAL
   Else   
      Return If(_lSimbolo,"R$ ","")+AllTrim(nTotMerc)
   EndIf   
EndIf

Return

/*
===============================================================================================================================
Programa----------: RCOM002Cab()
Autor-------------: Alex Wallauer
Data da Criacao---: 01/10/2019
Descrição---------: RETORNA A DESCRIÇÃO DA MOEDA NA OBS
Parametros--------: _cNumPC , _cFilial
etorno-----------: .T.
===============================================================================================================================
*/
Static Function RCOM002Cab(_cNumPC,_cFilial,nLinIni,nColIni)

If SC7->C7_I_APLIC == "I"
   oPrint:Say( (nLinIni+030) , (nColIni+300) , "PEDIDO DE COMPRAS ** INVESTIMENTO **" , oFont14 )
   oPrint:Say( (nLinIni+045) , (nColIni+300) , AllTrim(Posicione("ZZI",1,xFilial("ZZI")+SC7->C7_I_CDINV, "ZZI_DESINV")) , oFont08 )
ElseIf SC7->(FIELDPOS("C7_I_CLAIM")) <> 0 .And. SC7->C7_I_CLAIM = "1"
   oPrint:Say( (nLinIni+035) , (nColIni+375) , "PEDIDO DE COMPRAS ** CLAIM **" , oFont14 )
Else
   oPrint:Say( (nLinIni+035) , (nColIni+375) , "PEDIDO DE COMPRAS" , oFont14 )
EndIf

oPrint:Say( (nLinIni+050) , (nColIni+730) , "Nº" , oFont14 )
oPrint:Say( (nLinIni+070) , (nColIni+715) , _cNumPC , oFont14 )

SM0->(DBSetOrder(1))
SM0->(DBSeek(cEmpAnt + _cFilial))

oPrint:Say( (nLinIni+080) , (nColIni+020) , AllTrim(SM0->M0_NOMECOM) , oFont08 )
oPrint:Say( (nLinIni+090) , (nColIni+020) , AllTrim(SM0->M0_ENDCOB) , oFont08 )
oPrint:Say( (nLinIni+100) , (nColIni+020) , "CEP: " + SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3) + " - " + SubStr(AllTrim(SM0->M0_CIDCOB),1,50) + " - " + AllTrim(SM0->M0_ESTCOB) , oFont08 )
oPrint:Say( (nLinIni+110) , (nColIni+020) , 'TEL:(' + SubStr(SM0->M0_TEL,4,2) + ')' + SubStr(SM0->M0_TEL,7,4) + '-' +SubStr(SM0->M0_TEL,11,4) + " - " + 'FAX:(' + SubStr(SM0->M0_FAX,4,2) + ')' + SubStr(SM0->M0_FAX,7,4) + '-' +SubStr(SM0->M0_FAX,11,4), oFont08 )
oPrint:Say( (nLinIni+120) , (nColIni+020) , "CNPJ/CPF:" + formCPFCNPJ(SM0->M0_CGC) , oFont08 )
oPrint:Say( (nLinIni+130) , (nColIni+020) , "I.E:" + AllTrim(SM0->M0_INSC) , oFont08 )

SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2") + SC7->C7_FORNECE + SC7->C7_LOJA))

oPrint:Say( (nLinIni+080) , (nColIni+260) , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont08 )
oPrint:Say( (nLinIni+090) , (nColIni+260) ,  AllTrim(SA2->A2_END) , oFont08 )
oPrint:Say( (nLinIni+100) , (nColIni+260) , "CEP: " + SubStr(AllTrim(SA2->A2_CEP),1,2) + "." + SubStr(AllTrim(SA2->A2_CEP),3,3) + "-" + SubStr(AllTrim(SA2->A2_CEP),6,3) + " - " + AllTrim(SA2->A2_MUN) + " - " + SA2->A2_EST , oFont08 )
oPrint:Say( (nLinIni+110) , (nColIni+260) , "TEL:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_TEL),1,4) + "-" + SubStr(AllTrim(SA2->A2_TEL),5,4) + " - " + "FAX:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_FAX),1,4) + "-" + SubStr(AllTrim(SA2->A2_FAX),5,4) , oFont08 )
oPrint:Say( (nLinIni+120) , (nColIni+260) , "CNPJ/CPF: " + formCPFCNPJ(SA2->A2_CGC) + " - I.E:" + SA2->A2_INSCR , oFont08 )
oPrint:Say( (nLinIni+130) , (nColIni+260) ,  AllTrim(SC7->C7_CONTATO) , oFont08 )

oPrint:Say( (nLinIni+160) , (nColIni+020) , "Item"			, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+045) , "Produto"		, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+100) , "Descrição"		, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+400) , "UM"			, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+450) , "Quantidade"	, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+525) , "Vlr.Unit."		, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+570) , "Vlr.Desc."		, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+622) , "Vlr.Total"		, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+690) , "IPI"			, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+721) , "ICMS ST"		, oFont08 )
oPrint:Say( (nLinIni+160) , (nColIni+770) , "Dt.Entrega"	, oFont08 )

nLinAux := nLinIni + 180

Return .T.
