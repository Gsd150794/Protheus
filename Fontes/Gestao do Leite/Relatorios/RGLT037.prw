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
Programa----------: RGLT037
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Resumo de Rendimentos do exercicio anual de um determinado municipio
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT037()

Private _cPerg		:= "RGLT037"
Private _oFont11b	:= Nil
Private _oPrint		:= Nil
Private _nLinha		:= 1
Private _nSalto		:= 60

Define Font _oFont11b Name "Courier New" Size 0,-09 Bold  // Tamanho 10 Negrito

If !Pergunte( _cPerg , .T. )
	Return
EndIf

_oPrint := TMSPrinter():New( "Resumo de Rendimentos por Município")
_oPrint:SetPortrait() 	//Retrato
_oPrint:SetPaperSize(9)	//Seta para papel A4
_oPrint:Setup()

_nLinha := 0100
// startando a impressora
_oPrint:Say( 0 , 0 , " " , _oFont11b , 100 )

Processa( {|| RGLT037DAD() } )

_oPrint:EndPage()	// Finaliza a Pagina.
_oPrint:Preview()	// Visualiza antes de Imprimir.

Return

/*
===============================================================================================================================
Programa----------: RGLT037CAB
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Impressão do cabeçalho padrão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT037CAB

Local _cRaizServer	:= If(issrvunix(), "/", "\")
Local _nColuna   	:= 0
Local _nColIni   	:= 0
Local _nColFin   	:= 0
Local _cTitulo   	:= ""

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
_cTitulo	:= "Resumo Anual de Rendimentos por município"

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
Programa----------: RGLT037DAD
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Processa os dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT037DAD

Local _aDadMun	:= {}
Local _cEstado	:= ""
Local _cCodMun	:= ""  //Codigo do Municipio
Local _cAlias	:= GetNextAlias()
Local _cFiltro	:= '%'

If !Empty( MV_PAR03 )
	_cFiltro += " And SA2.A2_EST = '"+ MV_PAR03 +"' "
EndIf

If !Empty(MV_PAR04)
	_cFiltro += " And SA2.A2_COD_MUN IN "+ FormatIn( AllTrim( MV_PAR04 ) , ";" )
EndIf

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR05) .Or. Empty(MV_PAR05) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLF.ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR05) , ';' )
EndIf

_cFiltro += "%"

ProcRegua(0)
IncProc("Consultando registros no Banco de Dados")

BeginSql alias _cAlias
	SELECT SA2.A2_EST, SA2.A2_COD_MUN, ZLF.ZLF_DTINI, ZLF.ZLF_EVENTO, ZLF.ZLF_DEBCRE,
	       SUM(ZLF.ZLF_QTDBOM) QTDBOM, SUM(ZLF.ZLF_TOTAL) TOTAL, SUM(ZLF.ZLF_VLRPAG) VLRPAG
	  FROM %Table:ZLF% ZLF, %Table:ZLE% ZLE, %Table:SA2% SA2
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND ZLE.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND ZLE.ZLE_FILIAL = %xFilial:ZLE% 
	   AND ZLF.ZLF_CODZLE = ZLE.ZLE_COD
	   AND ZLF.ZLF_A2COD = SA2.A2_COD
	   AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
	   AND ZLF.ZLF_TP_MIX = 'L'
	   AND ZLE.ZLE_STATUS <> 'B'
	   %exp:_cFiltro%
	   And ZLF.ZLF_DTINI BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	 GROUP BY SA2.A2_EST, SA2.A2_COD_MUN, ZLF.ZLF_DTINI, ZLF.ZLF_EVENTO, ZLF.ZLF_DEBCRE
	 ORDER BY SA2.A2_EST, SA2.A2_COD_MUN, ZLF.ZLF_DTINI, ZLF.ZLF_EVENTO, ZLF.ZLF_DEBCRE
EndSql

Count To nCountRec
(_cAlias)->(DBGoTop())
ProcRegua(nCountRec)

While (_cAlias)->(!Eof())

	IncProc("Imprimindo")

	If ( (_cAlias)->A2_EST <> _cEstado )

		// Caso nao seja o primeiro registro
		If !Empty( _cEstado )
			_oPrint:StartPage()				//Inicia uma nova pagina a cada novo produtor
			_nLinha := 0100
			RGLT037CAB()					//Imprime Cabecalho	da PAGINA
			RGLT037MUN( _cEstado , _cCodMun ) //Cabecalho do Municipio
			RGLT037REN( _aDadMun )			//Monta os redimentos do municipio dentro do estado
			_aDadMun := {}					//Seta com vazio o vetor que contem os dados do municipio que acabou de imprimir os rendimentos
			_oPrint:EndPage()
		EndIf

		// Armazena os dados do primeiro registro do produtor
		aAdd( _aDadMun , { (_cAlias)->A2_EST , (_cAlias)->A2_COD_MUN , (_cAlias)->ZLF_DTINI , (_cAlias)->ZLF_EVENTO , (_cAlias)->ZLF_DEBCRE , (_cAlias)->QTDBOM , (_cAlias)->TOTAL , (_cAlias)->VLRPAG } )

		// Seta as variaveis codigo e loja do produtor para comparacao
		_cEstado := (_cAlias)->A2_EST
		_cCodMun := (_cAlias)->A2_COD_MUN

	Else
		If (_cAlias)->A2_COD_MUN <> _cCodMun
			_oPrint:StartPage()				//Inicia uma nova pagina a cada novo produtor  
			_nLinha := 0100
			RGLT037CAB()					//Imprime Cabecalho	da PAGINA
			RGLT037MUN( _cEstado , _cCodMun )	//Cabecalho Produtor

			RGLT037REN( _aDadMun )			//Monta os redimentos do produtor e sua loja 
			_aDadMun := {}					//Seta o vetor que contem os dados do produtor que acabou de imprimir os rendimentos
			_oPrint:EndPage()
			_cCodMun := (_cAlias)->A2_COD_MUN
		EndIf
		aAdd( _aDadMun , { (_cAlias)->A2_EST , (_cAlias)->A2_COD_MUN , (_cAlias)->ZLF_DTINI , (_cAlias)->ZLF_EVENTO , (_cAlias)->ZLF_DEBCRE , (_cAlias)->QTDBOM , (_cAlias)->TOTAL , (_cAlias)->VLRPAG } )	    
	EndIf

	(_cAlias)->( DBSkip() )
EndDo

If nCountRec > 0
	//imprime os dados do ultimo produtor
	_nLinha := 0100
	RGLT037CAB()//Imprime Cabecalho	da PAGINA
	RGLT037MUN(_cEstado,_cCodMun)//Cabecalho Produtor
	RGLT037REN(_aDadMun)
	_aDadMun := {}
EndIf
(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: RGLT037MUN
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Processa os dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT037MUN( _cEstado , _cCodMun )

DBSelectArea( "CC2" )
CC2->( DBSetOrder(1) )
CC2->( DBSeek( xFilial("CC2") + _cEstado + _cCodMun ) )

_oPrint:Say( _nLinha , 0100 , "MUNICÍPIO: "+ CC2->CC2_CODMUN +" - "+ AllTrim(CC2->CC2_MUN) +" - "+ CC2->CC2_EST , _oFont11b )
_nLinha += _nSalto

Return

/*
===============================================================================================================================
Programa----------: RGLT037REN
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Retorna as informacoes do produtor de sua respectiva fazenda dividindo ela por mes
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT037REN( _aDadRen )

Local _aDadMes	:= { {"01",0,0,0,0} , {"02",0,0,0,0} , {"03",0,0,0,0} , {"04",0,0,0,0} , {"05",0,0,0,0} , {"06",0,0,0,0} ,;
					 {"07",0,0,0,0} , {"08",0,0,0,0} , {"09",0,0,0,0} , {"10",0,0,0,0} , {"11",0,0,0,0} , {"12",0,0,0,0}  }
Local _nPos		:= 0
Local _nCont	:= 1
Local _nLinIni	:= 0
Local _nTotLit	:= 0
Local _nTotRen	:= 0
Local _nTotIns	:= 0
Local _nTotFun	:= 0
Local _aMes		:= { "Janeiro" , "Feveiro" , "Março" , "Abril" , "Maio" , "Junho" , "Julho" , "Agosto" , "Setembro" , "Outubro" , "Novembro" , "Dezembro" }
Local _lInss	:= .F.
Local _cCodCot	:= AllTrim(SuperGetMV("IT_EVECOTA",.F.,"000001"))
Local _cCodINS	:= AllTrim(SuperGetMV("LT_EVEINSS",.F.,"000013/000016/000019"))
Local _cCodFun	:= AllTrim(SuperGetMV("LT_EVEFUND",.F.,"000014"))
Local _cIncProd	:= AllTrim(SuperGetMV("LT_INCPROD",.F.,"000121"))
Local _cCabINS	:= ""
Local _cCabFun	:= ""
Local _nColuna	:= 0
Local _nColIni	:= 0
Local _nColFin	:= 0
  
While _nCont <= Len( _aDadRen )

	//====================================================================================================
	// Verifica se o mes ja foi lancado
	//====================================================================================================
	_nPos := aScan( _aDadMes , {|x| x[1] == SubStr( _aDadRen[_nCont][3] , 5 , 2 ) } )
	
	//====================================================================================================
	// Seta todo calculo de Inss como falso
	//====================================================================================================
	_lInss := .F.
	
	//====================================================================================================
	// Pega se o evento desconta INSS
	//====================================================================================================
	If Posicione( "ZL8" , 1 , xFilial("ZL8") + _aDadRen[_nCont][4] , "ZL8_BASINS" ) == "S"
		 _lInss := .T.
	EndIf
	
	If _nPos > 0
	
		//====================================================================================================
		// Checa os eventos
		//====================================================================================================
		Do Case
		
			Case _aDadRen[_nCont,4] $ _cCodCot	; _aDadMes[_nPos][2] := _aDadRen[_nCont][6] //Quantidade de litros de leite que entrou no mes
			Case _aDadRen[_nCont,4] $ _cCodINS	; _aDadMes[_nPos][4] += _aDadRen[_nCont][8] //INSS
			Case _aDadRen[_nCont,4] == _cCodFun	; _aDadMes[_nPos][5] := _aDadRen[_nCont][8] //FUNDEPEC
		
		EndCase
		
		//====================================================================================================
		// Rendimento tributaveis se no cadastro de eventos estiver como gera INSS e o evento For de credito
		//====================================================================================================
		If (_lInss .And. _aDadRen[_nCont,5] == 'C') .Or. _aDadRen[_nCont,4] == _cIncProd
			_aDadMes[_nPos][3]+= _aDadRen[_nCont][7]//Rendimentos Tributaveis
		EndIf
	
	EndIf

_nCont++
EndDo

_nLinha		+= ( _nSalto * 2 )
_nLinIni	:= _nLinha //Usada para a linha inicial do box

_oPrint:Say( _nLinha , 0120 , "Mês de Referência"	, _oFont11b )
_oPrint:Say( _nLinha , 0770 , "Litragem"			, _oFont11b )
_oPrint:Say( _nLinha , 1230 , "Rendimentos"			, _oFont11b )
_oPrint:Say( _nLinha , 1900 , "Descontos"			, _oFont11b )

_nLinha += _nSalto

_oPrint:Line( _nLinha , 1080 , _nLinha				, 2380		)
_oPrint:Say(  _nLinha , 1230 , "Tributaveis"		, _oFont11b	)

//====================================================================================================
// Pega a descricao reduzida do evento para que seja visualizada no cabecalho do relatorio
//====================================================================================================
_cCabINS := "INSS"
_cCabFun := "FUNDEPEC"

_nColIni := 1590
_nColFin := 2070

//====================================================================================================
// Calculo para que o nome fica alinhado no centro coluna INSS
// O valor 17.7 eh o valor que cada caractere ocupa
//====================================================================================================
_nColuna := _nColIni + Int( ( ( _nColFin - _nColIni ) - ( Len( _cCabINS ) * 17.7 ) ) / 2 )

_oPrint:Say( _nLinha , _nColuna , _cCabINS , _oFont11b )

_nColIni := 2090
_nColFin := 2370

//====================================================================================================
// Calculo para que o nome fica alinhado no centro coluna INSS
// O valor 17.7 eh o valor que cada caractere ocupa
//====================================================================================================
_nColuna := _nColIni + Int( ( ( _nColFin - _nColIni ) - ( Len( _cCabFun ) * 17.7 ) ) / 2 )

_oPrint:Say( _nLinha , _nColuna , _cCabFun , _oFont11b )
_nLinha += _nSalto

_oPrint:Line( _nLinha , 0100 , _nLinha , 2380 )
_nLinha += _nSalto

_nCont := 1

While _nCont <= Len( _aDadMes )

	_oPrint:Say(  _nLinha , 0150 , _aDadMes[_nCont][1] +" - "+ _aMes[ Val( _aDadMes[_nCont][1] ) ]	, _oFont11b ) //Mes
	_oPrint:Say(  _nLinha , 0850 , Transform( _aDadMes[_nCont][2] , "@E 999,999,999"	)			, _oFont11b ) //Litragem
	_oPrint:Say(  _nLinha , 1310 , Transform( _aDadMes[_nCont][3] , "@E 99,999,999.99"	)			, _oFont11b ) //Tributaveis
	_oPrint:Say(  _nLinha , 1840 , Transform( _aDadMes[_nCont][4] , "@E 9,999,999.99"	)			, _oFont11b ) //Funrural - INSS
	_oPrint:Say(  _nLinha , 2140 , Transform( _aDadMes[_nCont][5] , "@E 9,999,999.99"	)			, _oFont11b ) //Fundepec
	_oPrint:Line( _nLinha , 0100 , _nLinha , 2380 )

	_nLinha += _nSalto

	//====================================================================================================
	// Somatorio para totalizadores
	//====================================================================================================
	_nTotLit += _aDadMes[_nCont][2]
	_nTotRen += _aDadMes[_nCont][3]
	_nTotIns += _aDadMes[_nCont][4]
	_nTotFun += _aDadMes[_nCont][5]

_nCont++
EndDo

//====================================================================================================
// Imprime totalizadores
//====================================================================================================
_oPrint:Line( _nLinha , 0100 , _nLinha , 2380 )
_nLinha += _nSalto
_oPrint:Line( _nLinha , 0100 , _nLinha , 2380 )

_oPrint:Say( _nLinha , 0120 , "Totais do Exercicio"							, _oFont11b )
_oPrint:Say( _nLinha , 0850 , Transform( _nTotLit , "@E 999,999,999"	)	, _oFont11b )
_oPrint:Say( _nLinha , 1310 , Transform( _nTotRen , "@E 99,999,999.99"	)	, _oFont11b )
_oPrint:Say( _nLinha , 1840 , Transform( _nTotIns , "@E 9,999,999.99"	)	, _oFont11b )
_oPrint:Say( _nLinha , 2140 , Transform( _nTotFun , "@E 9,999,999.99"	)	, _oFont11b )

_nLinha += _nSalto

_oPrint:Box(  _nLinIni		, 0100 , _nLinha , 2380 )
_oPrint:Line( _nLinIni		, 0630 , _nLinha , 0630 ) //Litragem
_oPrint:Line( _nLinIni		, 1080 , _nLinha , 1080 ) //Tributaveis
_oPrint:Line( _nLinIni		, 1580 , _nLinha , 1580 ) //Funrural - INSS
_oPrint:Line( _nLinIni +60	, 2080 , _nLinha , 2080 ) //Fundepec

Return
