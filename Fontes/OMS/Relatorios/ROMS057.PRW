/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
Lucas Borges  	  | 23/07/2025 | Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Alex     - Igor Melgaço  - 02/05/25 - 06/05/25 -  50525  - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
==============================================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//===================================================================================================
#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "TBICONN.CH"
#Include "FONT.CH"
#Include 'totvs.ch'

/*
===============================================================================================================================
Programa----------: ROMS057
Autor-------------: Josué Danich Prestes
Data da Criacao---: 27/12/2018
===============================================================================================================================
Descrição---------: Rotina responsável por emitir fatura de transporte - Chamado 29372
===============================================================================================================================
Parametros--------: _omodel - modelo da tela de ctr
					_cfatura2 - numero da fatura no financeiro
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS057(_omodel,_cfatura2)

Local _aArea	:= FWGetArea()
Local _oModelMAS := _oModel:GetModel('ZZNMASTER')
Default _cfatura2 := _oModelMAS:GetValue("ZZN_FATFIN")

//Posiciona SE2 na fatura
SE2->( DBSetOrder(1) )
If SE2->( DBSeek( cfilant + "MAN" + _cfatura2  + '01' + "FT " +;
								 _oModelMAS:GetValue( 'ZZN_FTRANS') + _oModelMAS:GetValue( 'ZZN_LOJAFT') ) )

	//Posiciona ZZN
	ZZN->(DBSetOrder(1))
	If ZZN->(DBSeek(cfilant + _oModelMAS:GetValue("ZZN_FATURA") + _oModelMAS:GetValue( 'ZZN_FTRANS') + _oModelMAS:GetValue( 'ZZN_LOJAFT')))

		FWMsgRun(,{|| U_ROMS057E()},,"Aguarde, gerando documento de fatura...")

	Else
		U_ITMsg("Falha na localização da fatura do transportador!","Atenção",,1)

	EndIf

Else

	U_ITMsg("Fatura do transportador não possui fatura gerada no financeiro!","Atenção",,1)

EndIf

FWRestArea(_aArea)
Return


/*
===============================================================================================================================
Programa----------: ROMS057E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
===============================================================================================================================
Descrição---------: Rotina responsável por emitir nota de débito em PDF por e-mail
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS057E()
Local _aArea		:= FWGetArea()
Local _cAnexo		:= ""
Local _cEmail		:= ""
Local _cCc			:= ""
Local _cAssunto		:= ""
Local _cMens		:= ""
Local cPathSrvJ		:= GETMV("MV_RELT")

Local nLinIni		:= 10		// Linha Lateral (inicial) Esquerda
Local nColMax		:= 0590		// Para implementar layout A4
Local nCont			:= 0

Local cNReduz		:= ""
Local cCidUni		:= ""
Local cNomUsr		:= ""
Local lPagina		:= .T.
Local _cFilial      := cfilant

Local cMailCom		:= ""

Private oPrint		:= Nil
Private nLinAux		:= 0
Private nColIni		:= 10		// Coluna Lateral (inicial) Esquerda
Private ltemmil		:= .F.
//============================
//º Define fontes do Relatorio
//============================
Private oFont10		:= TFont():New("Arial",,10,,.T.,,,,,.F.,.F.)
Private oFont14		:= TFont():New("Arial",,14,,.F.,,,,,.F.,.F.)
Private oFont14b	:= TFont():New("Arial",,14,,.T.,,,,,.F.,.F.)
Private oFont04		:= TFont():New("Arial",,04,,.F.,,,,,.F.,.F.)
Private oFont08		:= TFont():New("Arial",,08,,.F.,,,,,.F.,.F.)
Private oFont08B	:= TFont():New("Arial",,08,,.T.,,,,,.F.,.F.)
Private oFont06		:= TFont():New("Arial",,06,,.F.,,,,,.F.,.F.)
Private oFont16b	:= TFont():New("Arial",,16,,.T.,,,,,.F.,.F.)

lImpObs := .F.                                                              


cFileName := "fatura_" + AllTrim(SE2->E2_NUM) + "_" + AllTrim(SE2->E2_FILIAL)+"_" + AllTrim(SE2->E2_FORNECE) + ".pdf"

//==========================
// Cria Arquivo do Relatorio
//==========================
oPrint := FWMSPrinter():New( cFileName , IMP_PDF , .F. , cPathSrvJ , .T. ,,,, .T. )

//=====================================
// Configura modo Retrato de Impressao
//=====================================
oPrint:SetPortrait()

//=============================
// Define impressao em papel A4
//=============================
oPrint:SetPaperSize(9)
oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior
	
//=========================================================
// Se enviar por e-mail nao abre o arquivo apos a impressao
//=========================================================
oPrint:SetViewPDF(.F.)
oPrint:cPathPDF := cPathSrvJ	// Caso seja utilizada impressão em IMP_PDF

oPrint:StartPage()

//==================================
// Chama função para desenhar o grid
//==================================
ROMS057G()

nLinIni	:= 005
nColIni	:= 000
nCont++
 
If nLinAux > (nLinIni+590)
	lPagina := .T.
	oPrint:EndPage()
	oPrint:StartPage()
	ROMS057G()

	nLinIni	:= 005
	nColIni	:= 000
	nCont++
EndIf

_cchaven := ZZN->ZZN_FILIAL + ZZN->ZZN_FATURA + ZZN->ZZN_FTRANS + ZZN->ZZN_LOJAFT
ZZN->(DBSetOrder(1))
ZZN->(DBSeek(_cchaven))

_ntot := 0
_nvaltot := 0
_ndesctot := 0
_aimp := {}

//Conta itens para dividir páginas
While _cchaven == ZZN->ZZN_FILIAL + ZZN->ZZN_FATURA + ZZN->ZZN_FTRANS + ZZN->ZZN_LOJAFT

	_ntot++
	_nvaltot += ZZN->ZZN_VLRCTR
	_ndesctot += ZZN->ZZN_DESCONT

	//Guarda totais de cada ctr para impressão
	_nk := aScan(_aimp, {|x| x[1] = ZZN->ZZN_CTRANS})

	If  _nk == 0

		aAdd(_aimp, {ZZN->ZZN_CTRANS, ZZN->ZZN_VLRCTR, ZZN->ZZN_DESCONT, 0})

	Else

		_aimp[_nk][2] += ZZN->ZZN_VLRCTR
		_aimp[_nk][3] += ZZN->ZZN_DESCONT

	EndIf

	ZZN->(DBSkip())

EndDo

ZZN->(DBSetOrder(1))
ZZN->(DBSeek(_cchaven))

_ntpags := noround((_ntot)/73,0) + 1
_npag := 1

oPrint:Say( (nLinIni+025) , (nColIni+210) , "FATURA "  + SE2->E2_NUM  , oFont14b )
oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) + "/" + StrZero(_ntpags,3)  , oFont14 )
oPrint:Say( (nLinIni+045) , (nColIni+210) , Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ") , oFont14b )


oPrint:Say( (nLinIni+065) , (nColIni+020) , Posicione("ZZM",1,xFilial("ZZM")+cfilant,"ZZM_DESCRI") , oFont14b )		
oPrint:Say( (nLinIni+080) , (nColIni+020) , "R$ " + transform(SE2->E2_VALOR,"@E 999,999.99") , oFont14b )
oPrint:Say( (nLinIni+095) , (nColIni+020) , "Emissão: " + DToC(SE2->E2_EMISSAO) , oFont14b )
oPrint:Say( (nLinIni+110) , (nColIni+020) , "Vencimento: " + DToC(SE2->E2_VENCTO) , oFont14b )
oPrint:Say( (nLinIni+125) , (nColIni+020) , "Lib.: " + SubStr(AllTrim(UsrFullName(SE2->E2_I_CLIB)),1,10) , oFont14b )
oPrint:Say( (nLinIni+140) , (nColIni+020) , "Conf.: ___________________" , oFont14b )

SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2") + SE2->E2_FORNECE+SE2->E2_LOJA))

oPrint:Say( (nLinIni+070) , (nColIni+210) , "FATURA DE ORIGEM: " + AllTrim(ZZN->ZZN_FATURA) , oFont08 )		
oPrint:Say( (nLinIni+080) , (nColIni+210) , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont08 )
oPrint:Say( (nLinIni+090) , (nColIni+210) ,  AllTrim(SA2->A2_END) , oFont08 )
oPrint:Say( (nLinIni+100) , (nColIni+210) , "CEP: " + SubStr(AllTrim(SA2->A2_CEP),1,2) + "." + SubStr(AllTrim(SA2->A2_CEP),3,3) + "-" + SubStr(AllTrim(SA2->A2_CEP),6,3) + " - " + AllTrim(SA2->A2_MUN) + " - " + SA2->A2_EST , oFont08 )
oPrint:Say( (nLinIni+110) , (nColIni+210) , "TEL:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_TEL),1,4) + "-" + SubStr(AllTrim(SA2->A2_TEL),5,4) + " - " + "FAX:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_FAX),1,4) + "-" + SubStr(AllTrim(SA2->A2_FAX),5,4) , oFont08 )
oPrint:Say( (nLinIni+120) , (nColIni+210) , "CNPJ/CPF: " + ROMS057CN(SA2->A2_CGC) + " - I.E:" + SA2->A2_INSCR , oFont08 )
oPrint:Say( (nLinIni+130) , (nColIni+210) , "BANCO: " + SA2->A2_BANCO + " - AGENCIA: " + SA2->A2_AGENCIA	 + " - CONTA: " + SA2->A2_NUMCON , oFont08B )
		
nLinAux := nLinIni + 130

oPrint:Say( (nLinAux+030) , (nColIni+020) ,  "   Item      CTR                      Data de emissão             Valor Principal          Desconto              Valor a Pagar", oFont14b )

_npos := 0
_ntot := 0

_natual :=0
ZZN->(DBSetOrder(1))
ZZN->(DBSeek(_cchaven))

While _cchaven == ZZN->ZZN_FILIAL + ZZN->ZZN_FATURA + ZZN->ZZN_FTRANS + ZZN->ZZN_LOJAFT

	//Impede impressão duplicada
	_nk := aScan(_aimp, {|x| x[1] = ZZN->ZZN_CTRANS})

	If _aimp[_nk][4] == 0

		_nvalor := _aimp[_nk][2]
		_ndesconto := _aimp[_nk][3]
		_aimp[_nk][4] := 1

	Else

		ZZN->(DBSkip())
		Loop
	
	EndIf

	oPrint:SayAlign( (nLinAux+040) , (nColIni-10) ,  StrZero(_npos,3) , oFont08, 55, 14, CLR_BLACK, 1, 0 )
	oPrint:SayAlign( (nLinAux+040) , (nColIni+40) ,  AllTrim(StrZero(Val(ZZN->ZZN_CTRANS),9)) + "/" + AllTrim(ZZN->ZZN_SERCTR) , oFont08, 55, 14, CLR_BLACK, 1, 0 )
	oPrint:Say( (nLinAux+047) , (nColIni+180) , DToC(ZZN->ZZN_DTDIGT), oFont08 )
	oPrint:SayAlign( (nLinAux+040) , (nColIni+300) , (transform(_nvalor,"@E 999,999,999.99")), oFont08, 55, 14, CLR_BLACK, 1, 0 )
	oPrint:SayAlign( (nLinAux+040) , (nColIni+380) , (transform(_ndesconto,"@E 999,999,999.99")), oFont08, 55, 14, CLR_BLACK, 1, 0 )
	oPrint:SayAlign( (nLinAux+040) ,(nColIni+490) ,  Transform(_nvalor-_ndesconto,"@E 999,999,999.99") , oFont08, 55, 14, CLR_BLACK, 1, 0 )

	oPrint:Line( nLinAux + 49 , nColIni + 010 , nLinAux + 049 , nColMax	)
	
	nlinAux += 10
	_npos++
	_natual++

	//Quebra de página
	If (_natual == 63 .And. _npag == 1) .Or. (_npag > 1 .And. _natual == 73)

		_natual := 0
		_npag++
		oPrint:EndPage()
		oPrint:StartPage()

		//==================================
		// Chama função para desenhar o grid
		//==================================
		ROMS057G(1)

		nLinIni	:= 005
		nColIni	:= 000
		nLinAux := nLinIni + 040 
		nCont++

		oPrint:Say( (nLinIni+025) , (nColIni+210) , "FATURA "  + SE2->E2_NUM  , oFont14b )
		oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) + "/" + StrZero(_ntpags,3)  , oFont14 )
		oPrint:Say( (nLinIni+045) , (nColIni+210) , Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ") , oFont14b )

		oPrint:Say( (nLinAux+030) , (nColIni+020) ,  "   Item      CTR                      Data de emissão             Valor Principal          Desconto              Valor a Pagar", oFont14b )


	EndIf

	ZZN->(DBSkip())

EndDo

	nlinAux += 20

	oPrint:Say( (nLinAux+047) , (nColIni+020) ,  "TOTAIS:  " , oFont08B,,,,1 )
	
	oPrint:Say( (nLinAux+047) , (nColIni+320) , (transform(_nvaltot,"@E 999,999,999.99")), oFont08,,,,1 )
	oPrint:Say( (nLinAux+047) , (nColIni+400) , (transform(_ndesctot,"@E 999,999,999.99")), oFont08,,,,1 )
	oPrint:Say(    (nLinAux+047) , (nColIni+510) , transform(_nvaltot-_ndesctot,"@E 999,999,999.99")     , oFont08, 55, 14, CLR_BLACK, 1, 0 )


_cEmail := SuperGetMV("IT_WFFATFI",.F.,"sistema@italac.com.br" )

oPrint:EndPage()
oPrint:lViewPDF := .F.
oPrint:Preview()
FreeObj(oPrint)

If File(cPathSrvJ + cFileName)
	_cAnexo := cPathSrvJ + cFileName
EndIf

cNreduz := AllTrim(Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ"))

_cAssunto := "Fatura de transporte - " + SE2->E2_FILIAL + "/" + SE2->E2_NUM + " do transportador " + cNReduz + Space(30)

//=================================
// Chama a função da tela de E-mail
//=================================
_cCc := Lower(AllTrim(UsrRetMail(RetCodUsr())))
ROMS057M(_cAnexo,@_cEmail,@_cCc,@_cAssunto,@_cMens,cMailCom,cNReduz,_cFilial,SE2->E2_NUM,cCidUni,cNomUsr)

//========================================================
// Chama a função para exclusão do arquivo PDF do servidor
//========================================================
ROMS057D(cPathSrvJ + cFileName)

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ROMS057G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
===============================================================================================================================
Descrição---------: Rotina responsável por criar o layout de impressão
===============================================================================================================================
Parametros--------: _nopc - 1 para segunda página em diante
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS057G(_nopc)
Local nLinIni		:= 0		// Linha Lateral (inicial) Esquerda
Local nColIni		:= 0		// Coluna Lateral (inicial) Esquerda
Local nLinMax		:= 0835		// Para implementar layout A4
Local nColMax		:= 0590		// Para implementar layout A4
Local cPathImg		:= GetSrvProfString("Startpath","")
Local cFileImg		:= ""

Default _nopc := 0

nLinIni	:= 005
nColIni	:= 000

cFileImg := cPathImg + "LGRL01.BMP"

//==============
// Box Principal
//==============
oPrint:Box( nLinIni + 008, nColIni + 010, nLinMax, nColMax, "-4")

//=========
// Logotipo
//=========
oPrint:SayBitmap( nLinIni + 010 , nColIni + 018 , cFileImg , 170 , 058 )


If _nopc == 0

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
	oPrint:Line( nLinIni + 145 , nColIni + 010 , nLinIni + 145 , nColMax	)

	//=================
	// Linha Horizontal
	//=================
	oPrint:Line( nLinIni + 170 , nColIni + 010 , nLinIni + 170 , nColMax	)

Else

	//===============
	// Linha Vertical
	//===============
	
	oPrint:Line( nLinIni + 008 , nColIni + 200 , nLinIni + 60 , nColIni + 200	)

	//=================
	// Linha Horizontal
	//=================
	oPrint:Line( nLinIni + 60 , nColIni + 010 , nLinIni + 60 , nColMax	)

	//=================
	// Linha Horizontal
	//=================
	oPrint:Line( nLinIni + 80 , nColIni + 010 , nLinIni + 80 , nColMax	)

EndIf

Return


/*
===============================================================================================================================
Programa----------: ROMS057M
Autor-------------: Josué Danich Prestes
Data da Criacao---: 04/02/2018
===============================================================================================================================
Descrição---------: Função responsável por exibir a janela para a digitação dos endereços de email, assunto, mensagem
===============================================================================================================================
Parametros--------: _cAnexo		- Endereço do arquivo da nota de débito em PDF
------------------: _cEmail		- Endereço de E-mail para qual será enviado a nota de débito
------------------: _cCc		- Endereço de E-mail que está no campo Com Cópia
------------------: _cAssunto	- Assunto do E-mail
------------------: _cMens		- Mensagem de texto para o corpo do E-mail
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS057M(_cAnexo,_cEmail,_cCc,_cAssunto,_cMens,cMailCom,cNReduz,_cFilial,_cNumPC,cCidUni,cNomUsr)
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
Local cPathSrvJ	 := GETMV("MV_RELT")
Local cPathLocal := GetTempPath()
Local cGetAnxl   := StrTran( cGetAnx, cPathSrvJ, cPathLocal ) 
Local cGetAssun	:= _cAssunto
Local cGetCc	:= _cCc + Space(80)
Local cGetMens	:= ""
Local cGetPara	:= _cEmail + Space(80)

Private oDlgMail

//Copia anexo para estação local
CpyS2T(cGetAnx,cPathLocal)

If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador

	_csetor	:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
   
EndIf


If Empty(AllTrim(_csetor))
 
 	_csetor := "Logistica"
 	
EndIf

cHtml := 'Ao departamento financeiro,'
cHtml += '<br><br>'
cHtml += '&nbsp;&nbsp;&nbsp;Segue anexo Fatura de transporte - ' + SE2->E2_FILIAL + "/"  + SE2->E2_NUM + ' do transportador ' + Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ") + '.<br>'
cHtml += '&nbsp;&nbsp;&nbsp;Favor confirmar o recebimento, retornando com o seu CIENTE!'
cHtml += '<br><br>'
cHtml += '<font color="#FF0000"><b><u>Título: ' + SE2->E2_NUM + ' no valor de ' + transform(SE2->E2_VALOR-SE2->E2_DECRESC,"@E 999,999.99") + ' com vencimento em ' + DToC(SE2->E2_VENCTO) +'. </u></b><br><br></font>'
cHtml += '<br><br>'


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
	_oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
	_oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
	
	_oScrAux:Load( cHtml )
	
	@ 189, 154 BUTTON oButEnv PROMPT "&Visualizar"	SIZE 037, 012 OF oDlgMail ACTION ( ShellExecute("open", cGetAnxl, "", cPathLocal, 1) ) PIXEL
	@ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
	@ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If nOpcA == 1
	cGetMens := ROMS057TT(cGetMens)
	//====================================
	// Chama a função para envio do e-mail
	//====================================
	U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, cMailCom, cGetAssun, cHtml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

Else
	U_ITMsg( 'Envio de e-mail cancelado pelo usuário.' , 'Atenção!' , ,1 )
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS057D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/02/2018
===============================================================================================================================
Descrição---------: Função responsável pela exclusão do arquivo pdf gerado no servidor
===============================================================================================================================
Parametros--------: cFile	- Caminho + nome do arquivo pdf
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS057D(cFile)
Local nRet := 0

If File(cFile)
	nRet := fErase(cFile)
	If nRet <> 0
		u_itconout("Erro ao excluir o arquivo: " + cFile + " - Erro: " + Str(FError()))
	Else
		u_itconout("Arquivo: " + cFile + " foi excluído com sucesso.")
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS057CN
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/01/2018                                      
===============================================================================================================================
Descrição---------: Função criada para formatar CPF/CNPJ
===============================================================================================================================
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
===============================================================================================================================
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function ROMS057CN(cCPFCNPJ)
Local cCampFormat := ""	//Armazena o CPF ou CNPJ formatado
   
If Len(AllTrim(cCPFCNPJ)) == 11			//CPF
	cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2) 
Else									//CNPJ
	cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
EndIf
	
Return cCampFormat

/*
===============================================================================================================================
Programa----------: ROMS057TT
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 12/02/2018
===============================================================================================================================
Descrição---------: Função criada para fazer a quebra de linha na mensagem digitada pelo usuário
===============================================================================================================================
Parametros--------: ExpC1	- Texto da mensagem
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS057TT(cGetMens)
Local aTexto	:= StrTokArr( cGetMens, chr(10)+chr(13) )
Local cRet		:= ""
Local nI		:= 0

For nI := 1 To Len(aTexto)
	cRet += aTexto[nI] + "<br>"
Next

Return(cRet)
