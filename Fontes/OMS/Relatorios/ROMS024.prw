/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
 Alexandre V. | 06/10/2014 | Feita tratativa para a correta impressão das observações do conteúdo de 'Serviços Prestados' para
              |            | casos que hajam quebras de linha (ENTER) antes do fim da linha. Chamado 7623
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer| 17/10/2016 | Inclusão do valor do pedágio no RPA - Chamado 17222
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 01/08/2019 | Revisão do fonte. Help 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "rwmake.ch"
#Include "topconn.ch" 
#Include "TBICONN.CH" 

/*
===============================================================================================================================
Programa----------: ROMS024
Autor-------------: Fabiano Dias
Data da Criacao---: 27/12/2010
===============================================================================================================================
Descrição---------: Relatório para emissão de RPA Avulso
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS024(cTipo,_cCodInRPA,_cCodFiRPA,_cSetores)

Local _cFiltro	:= "%"
Local _cPerg	:= "ROMS024"

//Verifica se esta chamando a rotina de impressao de dentro da rotina de impressao de RPA
If cTipo == 0
	_cFiltro += " AND ZZA.ZZA_RPA BETWEEN '" + _cCodInRPA + "' AND '" + _cCodFiRPA + "' "
ElseIf cTipo == 1
    //Caso contratio chama a tela de parametros para o usuario
	If !Pergunte (_cPerg,.T.)
		Return
	Else
		_cFiltro += " AND ZZA.ZZA_RPA BETWEEN '" +MV_PAR01+ "' AND '" +MV_PAR02+ "' "
	EndIf

ElseIf cTipo == 2
	_cFiltro += " AND ZZA.ZZA_SETOR IN "+ FormatIn(_cSetores,';')
	_cFiltro += " AND ZZA.ZZA_DTEMIS BETWEEN '" + DToS(date()) + "' AND '" + DToS(date()) + "'"
EndIf
_cFiltro += "%"
Processa( {|| MontaRel(_cFiltro) } , "Aguarde efetuando a impressão do RPA..." )

Return

/*
===============================================================================================================================
Programa----------: MontaRel
Autor-------------: Tiago Correa Castro
Data da Criacao---: 27/12/2010
===============================================================================================================================
Descrição---------: Montagem do Relatorio de Emissao de RPA
===============================================================================================================================
Parametros--------: _cFiltro
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MontaRel(_cFiltro)

Local _cAlias	:= GetNextAlias()
Local _cAlias2	:= ""
Local _nCountRec:= 0           
Local _nX		:= 0
Local _lErro	:= .F.
Local _aItens	:= {}
Local _cItens	:= ""
Private oPrint 
Private oFont8 := TFont():New("Arial",9,6 ,.T.,.F.,5,.T.,5,.T.,.F.)

// Inicializacao da impressao
oPrint:= TMSPrinter():New( "Recibo de prestacao de servico" )     
oPrint:SetPaperSize(9)	// Seta para papel A4 
oPrint:SetPortrait() // ou SetLandscape()   
	
/// startando a impressora
oPrint:Say(0,0," ",oFont8,100)   
	
oPrint:StartPage()   // Inicia uma nova página  
			
BeginSql alias _cAlias
	SELECT ZZA.ZZA_RPA, ZZA.ZZA_SEST, ZZA.ZZA_INSS, ZZA.ZZA_IRRF, ZZA.ZZA_VLRBRT, ZZA.R_E_C_N_O_ RECZZA, SA2.A2_NOME,
	       MIN(SA2.A2_COD) A2_COD, SA2.A2_END, SA2.A2_MUN, SA2.A2_BAIRRO, SA2.A2_CEP, SA2.A2_CGC, SRA.RA_PIS,
	       SA2.A2_INSCR, ZZA.ZZA_CODRPA, ZZA.ZZA_ORIGEM
	  FROM %Table:ZZA% ZZA, %Table:SA2% SA2, %Table:SRA% SRA
	 WHERE ZZA.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND SRA.D_E_L_E_T_ = ' '
	   AND ZZA.ZZA_FILIAL = %xFilial:ZZA%
	   %exp:_cFiltro%
	   AND (ZZA.ZZA_CODAUT = SA2.A2_I_AUTAV
	   OR ZZA.ZZA_CODAUT = SA2.A2_I_AUT)
	   AND ZZA.ZZA_CODAUT = SRA.RA_MAT
	 GROUP BY ZZA.ZZA_RPA, ZZA.ZZA_SEST, ZZA.ZZA_INSS, ZZA.ZZA_IRRF, ZZA.ZZA_VLRBRT, ZZA.R_E_C_N_O_, SA2.A2_NOME, SA2.A2_END, 
	          SA2.A2_MUN, SA2.A2_BAIRRO, SA2.A2_CEP, SA2.A2_CGC, SRA.RA_PIS, SA2.A2_INSCR, ZZA.ZZA_CODRPA, ZZA.ZZA_ORIGEM
	 ORDER BY ZZA.ZZA_CODRPA
EndSql

Count To _nCountRec //Contabiliza o numero de registros encontrados pela query
(_cAlias)->(DBGoTop())
ProcRegua(_nCountRec)

DBSelectArea("ZZA")
ZZA->(DBSetOrder(1))

While (_cAlias)->(!Eof())

	IncProc("Favor Aguardar... Recibo corrente: " + AllTrim((_cAlias)->ZZA_RPA))
    _lErro := .F.
	//Comparação da ZZA com SE2
	If FunName() <> 'MGLT011'
		_cAlias2 := GetNextAlias()
		BeginSql alias _cAlias2
			SELECT COUNT(1) QTD
			  FROM %Table:ZZA% ZZA
			 WHERE ZZA.D_E_L_E_T_ = ' '
			   AND ZZA_RPA = %exp:(_cAlias)->ZZA_RPA%
			   AND ZZA_FILIAL = %xFilial:ZZA%
			   AND ZZA_VLRBRT - ZZA_SEST - ZZA_INSS <>
			       NVL((SELECT SUM(E2_VALOR)
			             FROM %Table:SE2% SE2
			            WHERE SE2.D_E_L_E_T_ = ' '
			              AND ZZA_FILIAL = E2_FILIAL
			              AND ZZA_RPA = E2_NUM
			              AND ZZA_DTEMIS = E2_EMISSAO
			              AND E2_PREFIXO = 'AUT'
			              AND E2_ORIGEM IN ('GERAZZ3', 'AOMS042')),0)
		EndSql
		If (_cAlias2)->QTD > 0
			aAdd(_aItens,{(_cAlias)->ZZA_RPA," VALOR SEST/SENAT e/ou VALOR INSS e/ou VALOR IRRF "})
			_lErro := .T.
		EndIf
		(_cAlias2)->(DBCloseArea())
	EndIf
	If !_lErro
		//Pega o conteudo do campo observacao
		ZZA->(DBSeek(xFilial("ZZA") + (_cAlias)->ZZA_CODRPA))
	
		// Trata a leitura do campo Memo
	    _cObserv := StrTran( ZZA->ZZA_OBSERV	, Chr(13)			, ';' )
	    _cObserv := StrTran( _cObserv			, Chr(10)			, ';' )
	    _cObserv := StrTran( _cObserv			, Chr(10)+Chr(13)	, ';' )
	    _cObserv := StrTran( _cObserv			, Chr(13)+Chr(10)	, ';' )
	
		Impress(oPrint,(_cAlias)->ZZA_RPA,(_cAlias)->ZZA_SEST,(_cAlias)->ZZA_INSS,(_cAlias)->ZZA_IRRF,;
				(_cAlias)->ZZA_VLRBRT,(_cAlias)->A2_NOME,(_cAlias)->A2_COD,(_cAlias)->A2_END,;
				(_cAlias)->A2_MUN,(_cAlias)->A2_BAIRRO,(_cAlias)->A2_CEP,(_cAlias)->A2_CGC,(_cAlias)->RA_PIS,;
				(_cAlias)->A2_INSCR,'1',_cObserv,(_cAlias)->ZZA_ORIGEM,ZZA->ZZA_VRPEDA)
	EndIf
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())
    
If !Empty(_aItens) //Verifica se houve algum erro durante as impressões
	For _nX := 1 To Len(_aItens)
		_cItens += _aItens[_nX][1]+", "
	Next _nX
		
	MsgStop("Ocorreram divergência de valores na impressão do RPA "+_cItens+" Entre em contato com o Suporte.","ROMS02401")
EndIf

oPrint:EndPage()     // Finaliza a página
oPrint:Preview()     // Visualiza antes de imprimir

Return 

/*
===============================================================================================================================
Programa----------: Impress
Autor-------------: Tiago Correa Castro
Data da Criacao---: 27/12/2010
===============================================================================================================================
Descrição---------: Montagem do Relatorio de Emissao de RPA
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Impress(oPrint,cRecibo,nSEST,nINSS,nIRRF,nTOTAL,cA2_NOME,cA2_COD,cA2_END,cA2_MUN,cA2_BAIRRO,cA2_CEP,;
					    cA2_CGC,cRA_PIS,cA2_INSCR,cTipAut,cObs,cOrigemRPA,nPedagio)


Local oFont10n	:= TFont():New("Courier New",9,08,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont12	:= TFont():New("Courier New",9,10,.T.,.F.,5,.T.,5,.T.,.F.)	
Local oFont12n	:= TFont():New("Courier New",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
Local oFont16n	:= TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
Local _nX		:= 0
Local _nI		:= 0
Local _aParc 	:= {}
Local _nAvista 	:= 0
Local _nAPrazo 	:= 0
Local _cTxtAux	:= ''
Local _cTxtImp	:= ''
Local _cAlias	:= GetNextAlias()
Local _nLinhas  := 0 
Local _nLin		:= 0

BeginSql alias _cAlias
SELECT E2_EMISSAO, E2_VENCTO, E2_VENCREA, E2_VALOR
  FROM %Table:SE2%
 WHERE D_E_L_E_T_ = ' '
   AND E2_FILIAL = %xFilial:SE2%
   AND E2_PREFIXO = 'AUT'
   AND E2_TIPO = 'RPA'
   AND E2_NUM = %exp:cRecibo%
   AND E2_ORIGEM IN ('GERAZZ3', 'AOMS042')
EndSql

While (_cAlias)->(!Eof())
	aAdd(_aParc,{(_cAlias)->E2_VENCREA,(_cAlias)->E2_VALOR})

	If (_cAlias)->E2_EMISSAO == (_cAlias)->E2_VENCTO
		_nAvista += (_cAlias)->E2_VALOR
	Else
		_nAPrazo += (_cAlias)->E2_VALOR
	EndIf
			
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())
		
oPrint:StartPage()   // Inicia uma nova página
oPrint:Say(84,0100,"RECIBO DE PRESTAÇÃO DE SERVIÇOS - Número : " + cRecibo,oFont16n )

//Dados do autonomo
oPrint:Box (150,0100,420,2300)
oPrint:Say  (150,0120,"Nome....: "			,oFont12 )
oPrint:Say  (150,0370,AllTrim(cA2_NOME)		,oFont12n)
oPrint:Say  (150,1700,"Cod.....: "			,oFont12 )
oPrint:Say  (150,2000,AllTrim(cA2_COD)		,oFont12 )
oPrint:Say  (200,0120,"Endereco: "			,oFont12 )
oPrint:Say  (200,0370,AllTrim(cA2_END)		,oFont12 )
oPrint:Say  (250,0120,"Cidade..: "			,oFont12 )
oPrint:Say  (250,0370,AllTrim(cA2_MUN)		,oFont12 )
oPrint:Say  (300,0120,"Bairro..: "			,oFont12 )
oPrint:Say  (300,0370,AllTrim(cA2_BAIRRO)	,oFont12 )
oPrint:Say  (300,1700,"CEP.....: "			,oFont12 )
oPrint:Say  (300,2000,AllTrim(cA2_CEP)		,oFont12 )
If cTipAut == "1"
	oPrint:Say  (350,0120,"CPF.....: "		,oFont12 )
	oPrint:Say  (350,0370,AllTrim(cA2_CGC)	,oFont12 )
	oPrint:Say  (350,1700,"PIS.....: "		,oFont12 )
	oPrint:Say  (350,2000,AllTrim(cRA_PIS)	,oFont12 )
Else
	oPrint:Say  (350,0120,"CGC.....: "		,oFont12 )
	oPrint:Say  (350,0370,AllTrim(cA2_CGC)	,oFont12 )
	oPrint:Say  (350,1700,"Inscric.: "		,oFont12 )
	oPrint:Say  (350,2000,AllTrim(cA2_INSCR),oFont12 )
EndIf

//Dados das notas fiscais
oPrint:Box (460,0100,1560,2300)
oPrint:Say (460,0120,"SERVIÇO PRESTADO:",oFont12n )

_nLin	:=	560

_nLinhas := MlCount( cObs , 95 )

For _nX := 1 To _nLinhas
	_cTxtAux := MemoLine( cObs , 95 , _nX )
	_cTxtImp := ''
	For _nI := 1 To Len( _cTxtAux )
		If SubStr(_cTxtAux,_nI,1) == ';' .Or. _nI == Len( _cTxtAux )
			If SubStr(_cTxtAux,_nI,1) <> ';' .And. _nI == Len( _cTxtAux )
				_cTxtImp += SubStr(_cTxtAux,_nI,1)
			EndIf
			oPrint:Say( _nLin , 0120 , _cTxtImp , oFont12 )
			_nLin		+= 50
			_cTxtImp	:= ''
		Else
			_cTxtImp += SubStr(_cTxtAux,_nI,1)
		EndIf
	Next _nI
			
	_nLin += 50

Next _nX

//Dados dos impostos
_nTDesc	:=	nSEST + nINSS + nIRRF
_nTLiq 	:=	nTOTAL - _nTDesc

_nLin:=1850

oPrint:Box (1600,0100,_nLin+50,1130)
oPrint:Box (1600,1170,_nLin+50,2300)
	
oPrint:Say  (1600,0120,"(+) Valor dos servicos: ",oFont12 )
oPrint:Say  (1600,0740,transform((nTOTAL-nPedagio),'@re 999,999,999.99'),oFont12n )
oPrint:Say  (1650,0120,"(+) Valor dos pedagios: ",oFont12 )
oPrint:Say  (1650,0740,transform(nPedagio,'@re 999,999,999.99'),oFont12n )
oPrint:Say  (1700,0120,"(-) Desc.SEST/SENAT: ",oFont12 )
oPrint:Say  (1700,0740,transform(nSEST,'@re 999,999,999.99') ,oFont12n )
oPrint:Say  (1750,0120,"(-) Contribuicoes INSS: ",oFont12 )
oPrint:Say  (1750,0740,transform(nINSS,'@re 999,999,999.99'),oFont12n )
oPrint:Say  (1800,0120,"(-) Desconto IRRF:  ",oFont12 )
oPrint:Say  (1800,0740,transform(nIRRF,'@re 999,999,999.99'),oFont12n )	
oPrint:Say  (_nLin,0120,"(=) Total Liquido: ",oFont12 )
oPrint:Say  (_nLin,0740,transform(_nTLiq,'@re 999,999,999.99'),oFont12n )

oPrint:Say  (1600,1210,"Total de Proventos: ",oFont12 )
oPrint:Say  (1600,1920,transform(nTOTAL,'@re 999,999,999.99'),oFont12n )
oPrint:Say  (1750,1210,"Descontos: ",oFont12 )
oPrint:Say  (1750,1920,transform(_nTDesc,'@re 999,999,999.99'),oFont12n )
oPrint:Say  (_nLin,1210,"Total Liquido: ",oFont12 )
oPrint:Say  (_nLin,1920,transform(_nTLiq,'@re 999,999,999.99'),oFont12n )
		
oPrint:Box 	(_nLin+90,0100,_nLin+240,2300)
oPrint:Say  (_nLin+140,0120,PadC("("+AllTrim(Extenso(_nTLiq))+")",100," "),oFont10n )

// Impressao da condicao de pagto    
If cOrigemRPA <> '2' //Se For diferente da rotina de fechamento do leite
 	oPrint:Box 	(_nLin+260,0100,_nLin+450,2300)
  	oPrint:Say  (_nlin+265,0120,"Condição de Pagamento:",oFont12n )
	oPrint:Say  (_nlin+305,0120,"Valor pago á Vista:",oFont12 )
	oPrint:Say  (_nlin+305,1920,transform(_nAvista,'@re 999,999,999.99'),oFont12n )
	oPrint:Say  (_nlin+345,0120,"Valor pago á Prazo:",oFont12 )
	oPrint:Say  (_nlin+345,1920,transform(_nAPrazo,'@re 999,999,999.99'),oFont12n )
EndIf
	oPrint:Box 	(_nLin+480,0100,_nLin+880,2300)
	oPrint:Say  (_nLin+480,0120,"Recebi de ",oFont12 )
	oPrint:Say  (_nLin+480,0520,AllTrim(SM0->M0_NOMECOM),oFont12n )
	oPrint:Say  (_nLin+530,0120,"Razão Social: ",oFont12 )
	oPrint:Say  (_nLin+530,0520,AllTrim(SM0->M0_NOMECOM),oFont12 )
	oPrint:Say  (_nLin+580,0120,"Estabelicida à ",oFont12 )
	oPrint:Say  (_nLin+580,0520,AllTrim(SM0->M0_ENDENT),oFont12 )
	oPrint:Say  (_nLin+630,0120,"Cidade de ",oFont12 )
	oPrint:Say  (_nLin+630,0520,AllTrim(SM0->M0_CIDENT)+"    Estado: "+SM0->M0_ESTENT,oFont12 )
	oPrint:Say  (_nLin+680,0120,"CNPJ ",oFont12 )
	oPrint:Say  (_nLin+680,0520,AllTrim(SM0->M0_CGC)+"    Inscrição Estadual: "+AllTrim(SM0->M0_INSC),oFont12 )
	oPrint:Say  (_nLin+780,0120,"A importância acima discriminada com os descontos de lei, referente ao serviço prestado.",oFont12 )

	oPrint:Box 	(_nLin+0920,0480,_nLin+1160,2300)
	oPrint:Line (_nLin+1100,1170,_nLin+1100,2200)
	oPrint:Say  (_nLin+0920,0500,"Para maior clareza, firmo o presente",oFont12 )
	oPrint:Say  (_nLin+0970,0500,AllTrim(SM0->M0_CIDENT)+" - "+SM0->M0_ESTENT+", "+StrZero(Day(dDataBase),2)+" de "+AllTrim(MesExtenso(Month(dDataBase)))+" de "+StrZero(Year(dDataBase),4),oFont12 )
	oPrint:Say  (_nLin+1100,1585,"Assinatura",oFont12 )
	oPrint:Say  (_nLin+1470,1980,"Pagina:"+StrZero(1,2)+"/"+StrZero(1,2),oFont12 )
	oPrint:EndPage() // Finaliza a página
Return
