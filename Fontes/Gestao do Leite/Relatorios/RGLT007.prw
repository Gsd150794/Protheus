/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/02/2020| Chamado 32081. Corrigido error.log ao cancelar o relatório.
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT007
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 12/11/2019
Descrição---------: Relatório Autorização de Desconto Financeiro Frestista. Chamado 31174
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT007()

Local cDesc1	:= "Este programa tem como objetivo imprimir uma  "
Local cDesc2	:= "autorização de Desconto Financeiro de débitos do   "
Local cDesc3	:= "Fretista."
Local _cTitulo	:= "Autorização de Desconto Financeiro Frestista"
Local aOrd		:= {}
Local cTamanho	:= "P"
Local NomeProg	:= "RGLT007"
Local nTipo		:= 18
Local wnrel		:= "RGLT007" // Coloque aqui o nome do arquivo usado para impressao em disco
Local _cPerg	:= "RGLT007"
Private aReturn	:= { "Zebrado", 1, "Administracao", 2, 2, 1, "", 1}
Private m_pag	:= 01 // Contador de Paginas
Private nLastKey:= 0 // Controla o cancelamento da SetPrint e SetDefault
Private lEnd	:= .F.// Controle de cancelamento do relatorio

Pergunte(_cPerg,.F.)

// Monta a interface padrao com o usuario...                           ³
wnrel := SetPrint("",NomeProg,_cPerg,@_cTitulo,cDesc1,cDesc2,cDesc3,.T.,aOrd,.T.,cTamanho,,.T.)

If nLastKey == 27
	Return
EndIf

SetDefault(aReturn,"")

If nLastKey == 27
   Return
EndIf

nTipo := If(aReturn[4]==1,15,18)

RptStatus({|lEnd|RGLT007P(@lEnd) },_cTitulo)

Return

/*
===============================================================================================================================
Programa----------: RGLT007P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 24/05/2019
Descrição---------: Processa relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT007P(lEnd)

Local nL			:= 0
Local nCount		:= 0

Local oFont18BU	:= TFont():New("Arial",,18/*nHeight*/,,.T./*lBold*/,,,,,.T./*lUnderline*/,.F./*lItalic*/)
Local oFont14B	:= TFont():New("Arial",,14/*nHeight*/,,.T./*lBold*/,,,,,.F./*lUnderline*/,.F./*lItalic*/)
Local oFont14BU	:= TFont():New("Arial",,14/*nHeight*/,,.T./*lBold*/,,,,,.T./*lUnderline*/,.F./*lItalic*/)
Local oFont14	:= TFont():New("Arial",,14/*nHeight*/,,.F./*lBold*/,,,,,.F./*lUnderline*/,.F./*lItalic*/)

Local cRaizServer	:= If(issrvunix(), "/", "\")
Local nQtdReg		:= 0
Local _cAlias		:= GetNextAlias()
Local _cFiltro		:= "%"
Local _cTransp		:= ""
Local _aSelFil		:= {}
Local _aArea		:= SM0->(GetArea())
Local _lNovo 		:= .T.
Local _cCidade		:= ""
Local _cNome		:= ""
Local _nTotal		:= 0
Local _cData		:= ""

// Objeto de impressao grafica
oPrint:= TMSPrinter():New( "Relatorio de Grafico" )
oPrint:SetPortrait() 
oPrint:Setup()
oPrint:SetPaperSize(9)//DMPAPER_A4 9

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLF")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

_cFiltro += " AND ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR03) .Or. Empty(MV_PAR03) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR03) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR04)
	_cFiltro += " AND ZLF_LINROT IN " + FormatIn(AllTrim(MV_PAR04),";")
EndIf

_cFiltro+= "%"
// Obtem dados de impressao
BeginSql alias _cAlias
	SELECT ZLF_FILIAL, ZLF_DTFIM, A2_COD, A2_LOJA, A2_NOME, ZLF_SETOR, A2_CGC, ZL8_DESCRI, SUM(ZLF_TOTAL) ZLF_TOTAL
	  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SA2% SA2
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND ZL8.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZLF_FILIAL = ZL8_FILIAL
	   AND ZLF_EVENTO = ZL8_COD
	   AND ZLF_A2COD = A2_COD
	   AND ZLF_A2LOJA = A2_LOJA
	   AND ZLF_DEBCRE = 'D'
	   AND SubStr(ZLF_A2COD,1,1) = 'G'
	   %exp:_cFiltro%
	   AND ZLF_CODZLE = %exp:MV_PAR02%
	   AND ZLF_A2COD BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	   AND ZLF_A2LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	GROUP BY ZLF_FILIAL, ZLF_DTFIM, A2_COD, A2_LOJA, A2_NOME, ZLF_SETOR, A2_CGC, ZL8_DESCRI
	 ORDER BY ZLF_FILIAL, ZLF_SETOR, A2_COD, A2_LOJA
EndSql
Count to nQtdReg

ProcRegua(nQtdReg)

(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())
	If lEnd
		@ Prow()+1,001 PSay "CANCELADO PELO OPERADOR"
		Exit
	EndIf
	nCount++                   
	IncProc((_cAlias)->A2_COD)

	If (_cAlias)->(A2_COD+A2_LOJA) <> _cTransp .And. !_lNovo
		oPrint:Say(nL,100,"Total de Débitos: ",oFont14B)
		oPrint:Say(nL,1900,"R$ "+Transform(_nTotal,GetSx3Cache("ZLF_TOTAL","X3_PICTURE")),oFont14B,/*nWidth*/,/*nClrText*/,,1/*nAlign*/)
		nL += 250
		oPrint:Say(nL,100,_cCidade+", "+SubStr(_cData,7,2)+" de "+MesExtenso(SToD(_cData))+" de "+SubStr(_cData,1,4)+".",oFont14)
		nL += 250
		oPrint:Say(nL,800,_cNome,oFont14)	
		oPrint:FillRect({nL,300,nL+1,2100},TBrush():New("",0)) 
		oPrint:EndPage()
		_lNovo := .T.
		_nTotal := 0
	EndIf
	
	If (_cAlias)->(A2_COD+A2_LOJA) <> _cTransp
		_cTransp := (_cAlias)->(A2_COD+A2_LOJA)
		SM0->(DBSeek(cEmpAnt + (_cAlias)->ZLF_FILIAL))
		_cCidade := AllTrim(SM0->M0_CIDENT)
		_cNome := (_cAlias)->A2_NOME
		_cData := (_cAlias)->ZLF_DTFIM
	    oPrint:StartPage()
	    
		nL := 50
	   	oPrint:SayBitmap(nL+20,100,cRaizServer + "system/lgrl01.bmp",250,100)
		nL += 60
		oPrint:Say(nL,600,"AUTORIZAÇÃO DE DESCONTO FINANCEIRO",oFont18BU)
		nL += 300

		oPrint:Say(nL,100,"Transportadora:",oFont14B) 
		oPrint:Say(nL,500,(_cAlias)->A2_NOME,oFont14) 
		oPrint:Say(nL,1600,"CNPJ:",oFont14B)
		oPrint:Say(nL,1750,Transform((_cAlias)->A2_CGC,"@R! NN.NNN.NNN/NNNN-99"),oFont14)
		nL += 250
		
		oPrint:Say(nL,100,'Conforme pactuado no "CONTRATO DE PRESTAÇÃO DE SERVIÇOS DE COLETA E TRANS-',oFont14)
		nL += 50
		oPrint:Say(nL,100,'PORTE  DE  LEITE  A GRANEL"  e  as "NORMAS E PROCEDIMENTOS  PARA A  COLETA DE',oFont14)
		nL += 50
		oPrint:Say(nL,100,'LEITE A GRANEL", a  transportadora  CONTRATADA  autoriza o desconto dos débitos proveni-',oFont14)
		nL += 50		
		oPrint:Say(nL,100,'ente de convênios, empréstimos, adiantamentos, seguros diversos, do fornecimento de equipa-',oFont14)
		nL += 50
		oPrint:Say(nL,100,'mentos, de manutenção de  tanque rodoviário e telemetria,  bem como da falta de leite ou pelo',oFont14)
		nL += 50
		oPrint:Say(nL,100,'descarte parcial ou  integral da carga,  ressarcindo o prejuízo causado à CONTRATANTE, reco-',oFont14)
		nL += 50
		oPrint:Say(nL,100,'nhecendo que as não conformidades encontradas no leite coletado através de análises labora-',oFont14)
		nL += 50
		oPrint:Say(nL,100,'toriais ou diferenças de volumes ocasionadas por erro de marcação, foram decorrentes do não',oFont14)
		nL += 50
		oPrint:Say(nL,100,'cumprimento dos procedimentos estabelecidos e repassados às transportadoras e seus agentes',oFont14)
		nL += 50
		oPrint:Say(nL,100,'de coletas através de treinamentos específicos, referente à ocorrência registrada. O valor total',oFont14)
		nL += 50
		oPrint:Say(nL,100,'será descontado no pagamento do frete que a CONTRATANTE efetuará à CONTRATADA, refe-',oFont14)
		nL += 50
		oPrint:Say(nL,100,'rente ao transporte de leite efetuado no mês de '+MesExtenso(SToD(_cData))+' de '+SubStr(_cData,1,4)+'.',oFont14)
		nL += 150

		oPrint:Say(nL,100,"Descrição dos Débitos",oFont14BU)
		nL += 100
		_lNovo := .F.
	EndIf

	oPrint:Say(nL,100,AllTrim((_cAlias)->ZL8_DESCRI)+": ",oFont14)
	oPrint:Say(nL,1900,"R$ "+Transform((_cAlias)->ZLF_TOTAL,GetSx3Cache("ZLF_TOTAL","X3_PICTURE")),oFont14,/*nWidth*/,/*nClrText*/,,1/*nAlign*/)
	_nTotal += (_cAlias)->ZLF_TOTAL
	nL += 50

	(_cAlias)->(DBSkip())
	
EndDo

//Total da ùltima página
oPrint:Say(nL,100,"Total de Débitos: ",oFont14B)
oPrint:Say(nL,1900,"R$ "+Transform(_nTotal,GetSx3Cache("ZLF_TOTAL","X3_PICTURE")),oFont14B,/*nWidth*/,/*nClrText*/,,1/*nAlign*/)
nL += 250
oPrint:Say(nL,100,_cCidade+", "+SubStr(_cData,7,2)+" de "+MesExtenso(SToD(_cData))+" de "+SubStr(_cData,1,4)+".",oFont14)
nL += 250
oPrint:Say(nL,800,_cNome,oFont14)	
oPrint:FillRect({nL,300,nL+1,2100},TBrush():New("",0)) 
oPrint:EndPage()

(_cAlias)->(DBCloseArea())
	
oPrint:Preview()

FWRestArea(_aArea)

Return
