/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |30/07/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |09/02/2021| Chamado 35569. Corrigido error.log quando não há registros a serem exibidos
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT036
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Resumo de Rendimentos do exercicio anual de um determinado produtor.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT036

Private _cPerg  	:= "RGLT036"
Private _oFont11b	:= Nil
Private _oPrint		:= Nil
Private _nLinha		:= 1
Private _nSalto		:= 60
 
Define Font _oFont11b Name "Courier New" Size 0,-09 Bold  // Tamanho 10 Negrito

If !Pergunte( _cPerg , .T. )
	Return
EndIf 

_oPrint := TMSPrinter():New("Rendimentos Anuais por Produtor")
_oPrint:SetPortrait() 	// Retrato
_oPrint:SetPaperSize(9)	// Seta para papel A4 
_oPrint:Setup()

_nLinha := 0100
// startando a impressora
_oPrint:Say( 0 , 0 , " " , _oFont11b , 100 )

Processa({|| RGLT036DAD() })

_oPrint:EndPage()	// Finaliza a Pagina.
_oPrint:Preview()	// Visualiza antes de Imprimir.

Return

/*
===============================================================================================================================
Programa----------: RGLT036CAB
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 08/12/2009
Descrição---------: Imprime cabeçalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT036CAB

Local _cRaizServer := If(issrvunix(), "/", "\")
Local _nColuna   := 0
Local _nColIni   := 0
Local _nColFin   := 0
Local _cTitulo   :=""

_oPrint:SayBitmap(_nLinha,0100,_cRaizServer + "system/lgrl01.bmp",250,100)   
_nLinha+=(_nSalto * 3) 
_oPrint:Line(_nLinha,0100,_nLinha,2380)    
	
_nLinha+=_nSalto - 30
//DADOS DA EMPRESA
_oPrint:Say (_nLinha,0100,SM0->M0_NOMECOM,_oFont11b)
_oPrint:Say (_nLinha,1250,"C.N.P.J.: " + Transform(SM0->M0_CGC, IIf(Len(AllTrim(SM0->M0_CGC))>11,'@R! NN.NNN.NNN/NNNN-99','@R 999.999.999-99')) ,_oFont11b) // Picture "@R! NN.NNN.NNN/NNNN-99"
_nLinha+=_nSalto
	
_oPrint:Say (_nLinha,0100,AllTrim(SM0->M0_ENDCOB),_oFont11b)
_oPrint:Say (_nLinha,1250,"Insc.: " + AllTrim(SM0->M0_INSC),_oFont11b)
_nLinha+=_nSalto

_oPrint:Say (_nLinha,0100,AllTrim(SM0->M0_CIDCOB) + " - " + AllTrim(SM0->M0_ESTCOB),_oFont11b)
_oPrint:Say (_nLinha,1250,"CEP: " + SubStr(AllTrim(SM0->M0_CEPCOB),1,2) + "." + SubStr(AllTrim(SM0->M0_CEPCOB),3,3) + "-" + SubStr(AllTrim(SM0->M0_CEPCOB),6,3),_oFont11b)
_nLinha+=_nSalto
//FIM DADOS DA EMPRESA
_oPrint:Line(_nLinha,0100,_nLinha,2380) 
_nLinha+=_nSalto

//====================================================================================================
//TITULO DO RELATORIO COM O PERIODO INFORMADO PELO USUARIO
//====================================================================================================
_nColIni	:= 0100
_nColFin	:= 2380
_cTitulo:="Resumo Anual de Rendimentos por produtor"

//====================================================================================================
// Calculo para que o nome fica alinhado no centro coluna INSS
// O valor 17.7 eh o valor que cada caractere ocupa
//====================================================================================================
_nColuna:=_nColIni + Int(((_nColFin-_nColIni) - (Len(_cTitulo)* 17.7))/2)
	
_oPrint:Say (_nLinha,_nColuna,_cTitulo,_oFont11b)
_nLinha+=_nSalto

_cTitulo:="Período: " + DToC(MV_PAR01) + " à " + DToC(MV_PAR02)

//====================================================================================================
// Calculo para que o nome fica alinhado no centro coluna INSS   
// O valor 17.7 eh o valor que cada caractere ocupa
//====================================================================================================
_nColuna:=_nColIni + Int(((_nColFin-_nColIni) - (Len(_cTitulo)* 17.7))/2)

_oPrint:Say (_nLinha,_nColuna,_cTitulo,_oFont11b)
_nLinha+=_nSalto
_nLinha+=_nSalto

Return

/*
===============================================================================================================================
Programa----------: RGLT036DAD
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 08/12/2009
Descrição---------: Processa relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT036DAD

Local _nCountRec		:= 0
Local _aDadosProd	:= {}
Local _cCodProdut	:= ""
Local _cCodLjProd	:= ""
Local _cFiltro		:= "%"
Local _cAlias		:= GetNextAlias()

If !Empty(MV_PAR07)
	_cFiltro+=" AND SA2.A2_EST = '" + MV_PAR07 + "'"
EndIf

If !Empty(MV_PAR08)
	_cFiltro+=" AND SA2.A2_COD_MUN IN " + FormatIn(AllTrim(MV_PAR08),";")
EndIf

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR09) .Or. Empty(MV_PAR09) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLF.ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR09) , ';' )
EndIf

_cFiltro += "%"

ProcRegua(0)
IncProc("Consultando registros no Banco de Dados")

BeginSql alias _cAlias
	SELECT ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZLF.ZLF_DTINI, ZLF.ZLF_EVENTO, ZLF.ZLF_DEBCRE,
	       SUM(ZLF.ZLF_QTDBOM) QTDBOM, SUM(ZLF.ZLF_TOTAL) TOTAL, SUM(ZLF.ZLF_VLRPAG) AS VLRPAG
	  FROM %Table:ZLF% ZLF, %Table:SA2% SA2
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND ZLF.ZLF_A2COD = SA2.A2_COD
	   AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
	   AND ZLF.ZLF_TP_MIX = 'L'
	   %exp:_cFiltro%
	   AND ZLF.ZLF_DTINI BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	   AND ZLF.ZLF_A2COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
	   AND ZLF.ZLF_A2LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
	 GROUP BY ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZLF.ZLF_DTINI, ZLF.ZLF_EVENTO, ZLF.ZLF_DEBCRE
	 ORDER BY ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZLF.ZLF_DTINI, ZLF.ZLF_EVENTO, ZLF.ZLF_DEBCRE
EndSql

Count To _nCountRec
(_cAlias)->(DBGoTop())
ProcRegua(_nCountRec)
	
While (_cAlias)->(!Eof())

	IncProc("Imprimindo")

	If (_cAlias)->ZLF_A2COD <> _cCodProdut

		//Caso nao seja o primeiro registro
		If !Empty(_cCodProdut)
			_oPrint:StartPage()//Inicia uma nova pagina a cada novo produtor  
			_nLinha:=0100
			RGLT036CAB()//Imprime Cabecalho	da PAGINA
			RGLT036PROD(_cCodProdut,_cCodLjProd)//Cabecalho Produtor

			RGLT036REN(_aDadosProd)//Monta os redimentos do produtor e sua loja 
			_aDadosProd:={}//Seta o vetor que contem os dados do produtor que acabou de imprimir os rendimentos
			_oPrint:EndPage()
		EndIf
		//armazena os dados do primeiro registro do produtor
		aAdd(_aDadosProd,{(_cAlias)->ZLF_A2COD,(_cAlias)->ZLF_A2LOJA,(_cAlias)->zlf_dtini,(_cAlias)->zlf_evento,(_cAlias)->zlf_debcre,(_cAlias)->QTDBOM,(_cAlias)->TOTAL,(_cAlias)->VLRPAG})
		//Seta as variaveis codigo e loja do produtor para comparacao
		_cCodProdut:=(_cAlias)->ZLF_A2COD
		_cCodLjProd:=(_cAlias)->ZLF_A2LOJA

	Else
		If (_cAlias)->ZLF_A2LOJA <> _cCodLjProd
			_oPrint:StartPage()//Inicia uma nova pagina a cada novo produtor  
			_nLinha:=0100       
			RGLT036CAB()//Imprime Cabecalho	da PAGINA
			RGLT036PROD(_cCodProdut,_cCodLjProd)//Cabecalho Produtor

			RGLT036REN(_aDadosProd)//Monta os redimentos do produtor e sua loja 
			_aDadosProd:={}//Seta o vetor que contem os dados do produtor que acabou de imprimir os rendimentos
			_oPrint:EndPage()

			//Seta as variaveis codigo e loja do produtor para comparacao
			_cCodLjProd:=(_cAlias)->ZLF_A2LOJA
		EndIf
	aAdd(_aDadosProd,{(_cAlias)->ZLF_A2COD,(_cAlias)->ZLF_A2LOJA,(_cAlias)->zlf_dtini,(_cAlias)->zlf_evento,(_cAlias)->zlf_debcre,(_cAlias)->QTDBOM,(_cAlias)->TOTAL,(_cAlias)->VLRPAG})
	EndIf
		 
	(_cAlias)->(DBSkip())
EndDo

If _nCountRec > 0
	//imprime os dados do ultimo produtor
	_nLinha:=0100
	RGLT036CAB()//Imprime Cabecalho	da PAGINA
	RGLT036PROD(_cCodProdut,_cCodLjProd)//Cabecalho Produtor
	RGLT036REN(_aDadosProd)
	_aDadosProd := {}
EndIf
(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: RGLT036PROD
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 08/12/2009
Descrição---------: Processa relatório
Parametros--------: _cAlias
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT036PROD(_cCodProdut,_cCodLjProd)

DBSelectArea("SA2")
SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2") + _cCodProdut + _cCodLjProd))

_oPrint:Say(_nLinha,0100,"PRODUTOR: " + SA2->A2_COD + " - " + SA2->A2_LOJA + "  " + SA2->A2_NOME,_oFont11b) 
_nLinha+=_nSalto

_oPrint:Say(_nLinha,0100,"CPF/CNPJ: "  + Transform(SA2->A2_CGC,IIf(Len(AllTrim(SA2->A2_CGC))>11,'@R! NN.NNN.NNN/NNNN-99','@R 999.999.999-99')),_oFont11b)
_oPrint:Say(_nLinha,1250,"INSCRIÇÃO: " + SA2->A2_INSCR ,_oFont11b)
_nLinha+=_nSalto

_oPrint:Say(_nLinha,0100,"FAZENDA.: "  + SA2->A2_L_FAZEN,_oFont11b) 
_oPrint:Say(_nLinha,1250,"MUNICIPIO: " + SA2->A2_MUN,_oFont11b) 

Return

/*
===============================================================================================================================
Programa----------: RGLT036REN
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 08/12/2009
Descrição---------: Trabalhar as informacoes do produtor de sua respectiva fazenda dividindo ela por mes, para posteriormente a
					isso desenhar o quadro que comtem as informacoes por mes.
Parametros--------: aDadosRend -> 
					1 - Codigo do produtor
					2 - loja do produto
					3 - data inicial do mix
					4 - codigo do evento 
					5 - se o evento eh de debito ou credito (C/D) 
					6 - somatorio de leite que entrou
					7 - total
					8 - valor total pago
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT036REN(aDadosRend)

//mes,litragem, tributaveis, funrural, fundepec
Local _aDadosMesR:= {{"01",0,0,0,0},{"02",0,0,0,0},{"03",0,0,0,0},{"04",0,0,0,0},{"05",0,0,0,0},{"06",0,0,0,0},;
					{"07",0,0,0,0},{"08",0,0,0,0},{"09",0,0,0,0},{"10",0,0,0,0},{"11",0,0,0,0},{"12",0,0,0,0}}
Local _nPos			:= 0
Local _nCont		:= 1
Local _nLinhaIni 	:= 0
Local _nTotalLitr	:= 0
Local _nTotalFund	:= 0
Local _nTotalInss	:= 0
Local _nTotalRend	:= 0
Local _aMes      	:={"Janeiro","Feveiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
Local _lInss     	:= .F.
Local _cCodLtCota	:= AllTrim(SuperGetMV("IT_EVECOTA",.F.,"000001"))
Local _cCodLtINSS	:= AllTrim(SuperGetMV("LT_EVEINSS",.F.,"000013/000016/000019"))
Local _cCodLtFund	:= AllTrim(SuperGetMV("LT_EVEFUND",.F.,"000014"))
Local _cCabecINSS	:= ""
Local _cCabecFund	:= ""
Local _nColuna   	:= 0
Local _nColIni   	:= 0
Local _nColFin   	:= 0

While _nCont <= Len(aDadosRend)

	//Verifica se o mes ja foi lancado
	_nPos:=aScan(_aDadosMesR,{|x| x[1] == SubStr(aDadosRend[_nCont,3],5,2)})

	//Seta todo calculo de Inss como falso
	_lInss := .F.

	//Pega se o evento desconta INSS
	If Posicione("ZL8",1,xFilial("ZL8") + aDadosRend[_nCont,4],"ZL8->ZL8_BASINS") == "S"
		_lInss:=.T.
	EndIf

	If _nPos > 0

		Do Case
			//Checa os eventos	
			Case aDadosRend[_nCont,4] $ _cCodLtCota //Quantidade de litros de leite que entrou no mes
				_aDadosMesR[_nPos,2]:= aDadosRend[_nCont,6]
			Case aDadosRend[_nCont,4] $ _cCodLtINSS //INSS
				_aDadosMesR[_nPos,4]+= aDadosRend[_nCont,8]
			Case aDadosRend[_nCont,4] == _cCodLtFund //FUNDEPEC
				_aDadosMesR[_nPos,5]:= aDadosRend[_nCont,8] 
		EndCase

		If _lInss .And. aDadosRend[_nCont,5] == 'C'	//Rendimento tributaveis se no cadastro de eventos estiver como gera INSS e o evento For de credito
			_aDadosMesR[_nPos,3]+= aDadosRend[_nCont,7]//Rendimentos Tributaveis 	
	EndIf

	EndIf

++_nCont
EndDo

_nLinha+=_nSalto
_nLinha+=_nSalto
_nLinhaIni := _nLinha //Usada para a linha inicial do box

_oPrint:Say(_nLinha,0120,"Mês de Referência",_oFont11b)
_oPrint:Say(_nLinha,0770,"Litragem ",_oFont11b)
_oPrint:Say(_nLinha,1230,"Rendimentos",_oFont11b)
_oPrint:Say(_nLinha,1900,"Descontos ",_oFont11b)

_nLinha+=_nSalto
_oPrint:Line(_nLinha,1080,_nLinha,2380)
_oPrint:Say(_nLinha,1230,"Tributaveis" ,_oFont11b)

//Pega a descricao reduzida do evento para que seja visualizada no cabecalho do relatorio
_cCabecINSS:= "INSS"
_cCabecFund:= "FUNDEPEC"

_nColIni:=1590
_nColFin:=2070 
//Calculo para que o nome fica alinhado no centro coluna INSS
//O valor 17.7 eh o valor que cada caractere ocupa
_nColuna:=_nColIni + Int(((_nColFin-_nColIni) - (Len(_cCabecINSS)* 17.7))/2)

_oPrint:Say(_nLinha,_nColuna,_cCabecINSS,_oFont11b)

_nColIni:=2090
_nColFin:=2370 
//Calculo para que o nome fica alinhado no centro coluna INSS
//O valor 17.7 eh o valor que cada caractere ocupa
_nColuna:=_nColIni + Int(((_nColFin-_nColIni) - (Len(_cCabecFund)* 17.7))/2)

_oPrint:Say(_nLinha,_nColuna,_cCabecFund,_oFont11b)
_nLinha+=_nSalto

_oPrint:Line(_nLinha,0100,_nLinha,2380)
_nLinha+=_nSalto

_nCont:=1
While _nCont <= Len(_aDadosMesR)

	_oPrint:Say(_nLinha,0150,_aDadosMesR[_nCont,1] + " - "+ _aMes[Val(_aDadosMesR[_nCont,1])],_oFont11b) //Mes
	_oPrint:Say(_nLinha,0850,transform(_aDadosMesR[_nCont,2],"@E 999,999,999"),_oFont11b) //Litragem
	_oPrint:Say(_nLinha,1310,transform(_aDadosMesR[_nCont,3],"@E 99,999,999.99"),_oFont11b) //Tributaveis
	_oPrint:Say(_nLinha,1840,transform(_aDadosMesR[_nCont,4],"@E 9,999,999.99"),_oFont11b) //Funrural - INSS
	_oPrint:Say(_nLinha,2140,transform(_aDadosMesR[_nCont,5],"@E 9,999,999.99"),_oFont11b) //Fundepec
	_oPrint:Line(_nLinha,0100,_nLinha,2380)
	_nLinha+=_nSalto

	//Somatorio para totalizadores
	_nTotalLitr+= _aDadosMesR[_nCont,2]
	_nTotalRend+= _aDadosMesR[_nCont,3]
	_nTotalInss+= _aDadosMesR[_nCont,4]
	_nTotalFund+= _aDadosMesR[_nCont,5]

++_nCont
EndDo

//Imprime totalizadores
_oPrint:Line(_nLinha,0100,_nLinha,2380)
_nLinha+=_nSalto
_oPrint:Line(_nLinha,0100,_nLinha,2380)

_oPrint:Say(_nLinha,0120,"Totais do Exercicio",_oFont11b)
_oPrint:Say(_nLinha,0850,transform(_nTotalLitr,"@E 999,999,999"),_oFont11b)
_oPrint:Say(_nLinha,1310,transform(_nTotalRend,"@E 99,999,999.99"),_oFont11b)
_oPrint:Say(_nLinha,1840,transform(_nTotalInss,"@E 9,999,999.99"),_oFont11b)
_oPrint:Say(_nLinha,2140,transform(_nTotalFund,"@E 9,999,999.99"),_oFont11b)
_nLinha+=_nSalto

_oPrint:Box(_nLinhaIni,0100,_nLinha,2380)
_oPrint:Line(_nLinhaIni,0630,_nLinha,0630)//Litragem
_oPrint:Line(_nLinhaIni,1080,_nLinha,1080)//Tributaveis
_oPrint:Line(_nLinhaIni,1580,_nLinha,1580)//Funrural - INSS
_oPrint:Line(_nLinhaIni+60,2080,_nLinha,2080)//Fundepec

Return
