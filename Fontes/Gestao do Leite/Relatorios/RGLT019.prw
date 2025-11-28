/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/04/2023| Chamado 43587. Imprimir o Informativo de qualidade independente da quantidade de análise
Lucas Borges  |05/05/2025| Chamado 50600. Criada exceção para o evento 000229, prefixo GLA devido indefinição da diretoria
Lucas Borges  |01/10/2025| Chamado 52141. Incluido filtro para fornecedore Pessoa Física/Jurídica
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT019
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------: Demonstrativo do Produtor - Gestão do Leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT019()

Static cpMix	:= "" As Character
Static cpSetor	:= "" As Character
Static cpPrdIni	:= "" As Character
Static cpPrdFim	:= "" As Character
Static cpLjIni	:= "" As Character
Static cpLjFim	:= "" As Character
Static cpLinIni	:= "" As Character
Static cpLinFim	:= "" As Character
Static dpDtIni	:= SToD("") As Date
Static dpDtFim	:= SToD("") As Date

Private cPerg	:= "RGLT019" As Character

If !Pergunte( cPerg , .T. )
	Return
EndIf

//================================================================================
// Obtem parametros
//================================================================================
cpMix		:= MV_PAR01
cpSetor		:= MV_PAR02
cpPrdIni	:= MV_PAR03
cpLjIni		:= MV_PAR04
cpPrdFim	:= MV_PAR05
cpLjFim		:= MV_PAR06
cpLinIni	:= MV_PAR07
cpLinFim	:= MV_PAR08
dpDtIni		:= Posicione("ZLE",1,xFilial("ZLE")+cpMix,"ZLE_DTINI")
dpDtFim		:= Posicione("ZLE",1,xFilial("ZLE")+cpMix,"ZLE_DTFIM")

Processa({|| RGLT019RUN() })

Return

/*
===============================================================================================================================
Programa----------: RGLT019RUN
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------: Demonstrativo do Produtor - Gestão do Leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGLT019RUN()

Local nCount		:= 0 As Numeric
Local nPos4			:= 1800 As Numeric
Local nTab01		:= 100 As Numeric
Local nTab02		:= 800 As Numeric
Local nTab03		:= 1200 As Numeric
Local nTab04		:= 1600 As Numeric
Local nTab05		:= 2000 As Numeric
Local nTab11		:= 100 As Numeric
Local nTab12		:= 400 As Numeric
Local nTab13		:= 700 As Numeric
Local nTab14		:= 1000 As Numeric
Local nTab15		:= 1300 As Numeric
Local nTab16		:= 1700 As Numeric
Local nTotCre		:= 0 As Numeric
Local nTotDeb		:= 0 As Numeric
Local nTotVol		:= 0 As Numeric
Local nUltDia		:= 0 As Numeric
Local nTotQual		:= 0 As Numeric
Local dQual1		:= SToD("") As Date
Local dQual2		:= SToD("") As Date
Local dQual3		:= SToD("") As Date
Local nOk			:= 0 As Numeric
Local aMensagem		:= {} As Array
Local lmostra		:= .T. As Logical
Local nVolProd		:= 0 As Numeric
Local _cAliasZLF	:= GetNextAlias() As Character
Local _cAliasPRD	:= "" As Character
Local nReg			:= 0 As Numeric
Local nTotPend		:= 0 As Numeric                                               
Local cCodLinRota	:= "" As Character
Local _cMesAno		:= "" As Character
Local _cDescEven	:= "" As Character
Local _nTotal		:= 0 As Numeric
Local _nVlrPag		:= 0 As Numeric
Local _cCampo		:= "" As Character
Local _cFiltro		:= "% %" As Character
Local _nX			:= 0 As Numeric
Local _aClass 		:= RetSX3Box(GetSX3Cache("A2_L_CLASS","X3_CBOX"),,,1) As Array
Local _cBonif		:= "" As Character
Local _nInfQual		:= 0 As Numeric
Local _cMenAux		:= "" As Character
Private nL			:= 0 As Numeric
Private nPos1		:= 100 As Numeric
Private nPos2		:= 350 As Numeric
Private nPos3		:= 1500 As Numeric
Private oFontTitulo	:= TFont():New("Arial",09,10,.T.,.T.,5,.T.,5,.T.,.F.) As Object
Private oFontRotulo	:= TFont():New("Arial",09,09,.T.,.T.,5,.T.,5,.T.,.F.) As Object
Private oFontNormal	:= TFont():New("Arial",09,08,.T.,.T.,5,.T.,5,.T.,.F.) As Object
Private cRaizServer	:= If(issrvunix(), "/", "\") As Character
Private _nBase		:= 0 As Array//varivável declarada como Private para poder ser lida por macroexecução (ZL8_FORMUL)

OpenSm0(cEmpAnt, .F.)// Cadatro de Filial
SM0->(DBSeek(cEmpAnt + cFilAnt))
// Objeto de impressao grafica
oPrint:= TMSPrinter():New( "Relatorio de Grafico" )
oPrint:SetPortrait() 
oPrint:Setup()
    
//Verifico qual evento deve ser usado na exceção de Jaru
If cFilAnt == "10"
	_cBonif:= "000095"
ElseIf cFilAnt == "11"
	_cBonif:= "000080"
EndIf

If MV_PAR11 == 1 //Pessoa Física
	_cFiltro := "% AND A2_TIPO  = 'F' %"
ElseIf MV_PAR11 == 2 //Pessoa Jurídica
	_cFiltro := "% AND A2_TIPO  = 'J' %"
EndIf

// Obtem dados de impressao
BeginSql alias _cAliasZLF
	SELECT ZLF_SETOR,ZLF_RETIRO,ZLF_RETILJ,ZLF_LINROT
	FROM %Table:ZLF% ZLF, %Table:SA2% SA2
	WHERE ZLF.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND ZLF_FILIAL = %xFilial:ZLF%
	AND ZLF_CODZLE = %exp:cpMix%
	AND ZLF_SETOR = %exp:cpSetor%
	AND ZLF_RETIRO = A2_COD
	AND ZLF_RETILJ = A2_LOJA
	AND ZLF_RETIRO != ' '
	%exp:_cFiltro%
	AND ZLF_LINROT BETWEEN %exp:cpLinIni% AND %exp:cpLinFim%
	AND ZLF_RETIRO BETWEEN %exp:cpPrdIni% AND %exp:cpPrdFim%
	AND ZLF_RETILJ BETWEEN %exp:cpLjIni% AND %exp:cpLjFim%
	GROUP BY ZLF_SETOR,ZLF_RETIRO,ZLF_RETILJ,ZLF_LINROT
	ORDER BY ZLF_LINROT,ZLF_RETIRO,ZLF_RETILJ
EndSql
Count to nQtdReg

ProcRegua(nQtdReg)

(_cAliasZLF)->(DBGoTop())
While !(_cAliasZLF)->(Eof())
	nCount++                   

	cCodLinRota:=(_cAliasZLF)->ZLF_LINROT
	IncProc((_cAliasZLF)->ZLF_RETIRO)

    oPrint:StartPage()
    
	ImpCab()
		
	//===================================================================
	// Início dos dados do Produtor
	//===================================================================
		
	// Posiciona no Produtor
	DBSelectArea("SA2")
	SA2->(DBSetOrder(1))
	SA2->(DBSeek(xFilial("SA2")+(_cAliasZLF)->(ZLF_RETIRO+ZLF_RETILJ)))
	DBSelectArea("ZL3")
	ZL3->(DBSetOrder(1))
	ZL3->(DBSeek(xFilial("ZL3")+(_cAliasZLF)->ZLF_LINROT))
		
	nL += 50
	oPrint:Say(nL,nPos1,"PRODUTOR:",oFontRotulo) 
	oPrint:Say(nL,nPos2,SA2->A2_COD+"/"+SA2->A2_LOJA+" - "+SA2->A2_NOME,oFontNormal) 
	oPrint:Say(nL,nPos3,"CPF:",oFontRotulo)
	oPrint:Say(nL,nPos4,SA2->A2_CGC,oFontNormal)

	nL += 50
	oPrint:Say(nL,nPos1,"FAZENDA:",oFontRotulo) 
	oPrint:Say(nL,nPos2,SA2->A2_L_FAZEN,oFontNormal) 
	oPrint:Say(nL,nPos3,"INSCRICAO:",oFontRotulo)
	oPrint:Say(nL,nPos4,SA2->A2_INSCR,oFontNormal)
		
	nL += 50
	oPrint:Say(nL,nPos1,"MUNICIPIO:",oFontRotulo) 
	oPrint:Say(nL,nPos2,SA2->A2_MUN,oFontNormal) 
	oPrint:Say(nL,nPos3,"SIGSIF:",oFontRotulo)
	oPrint:Say(nL,nPos4,SA2->A2_L_SIGSI,oFontNormal)

	nL += 50
	oPrint:Say(nL,nPos1,"LINHA:",oFontRotulo) 
	oPrint:Say(nL,nPos2,(_cAliasZLF)->ZLF_LINROT+" - "+ZL3->ZL3_DESCRI,oFontNormal) 
	oPrint:Say(nL,nPos3,"NIRF:",oFontRotulo)
	oPrint:Say(nL,nPos4,SA2->A2_L_NIRF,oFontNormal)

	nL += 50
	If !Empty(SA2->A2_L_NATRA)
		oPrint:Say(nL,nPos3,"ATRAVESSADOR:",oFontRotulo)
		oPrint:Say(nL,nPos4,SA2->A2_L_NATRA,oFontNormal)
	EndIf
	oPrint:Say(nL,nPos1,"FRETISTA:",oFontRotulo)
		

	SA2->(DBSeek(xFilial("SA2")+ZL3->(ZL3_FRETIS+ZL3_FRETLJ)))
		
	oPrint:Say(nL,nPos2, ZL3->ZL3_FRETIS +'/'+ ZL3->ZL3_FRETLJ +" - "+ SA2->A2_NOME , oFontNormal ) //Ajuste para considerar a Loja no posicionamento e exibição [Chamado-6851]
	oPrint:Say(nL,nPos3,"",oFontRotulo)
	oPrint:Say(nL,nPos4,"",oFontNormal)
		
	SA2->(DBSeek(xFilial("SA2")+(_cAliasZLF)->(ZLF_RETIRO+ZLF_RETILJ)))
	SA2->(DBSeek(xFilial("SA2")+SA2->(A2_L_TANQ + A2_L_TANLJ)))
	nL += 50
	oPrint:Say(nL,nPos1,"RESP.TANQUE:",oFontRotulo) 
	oPrint:Say(nL,nPos2,SA2->A2_COD +'/'+ SA2->A2_LOJA +" - "+ SA2->A2_NOME , oFontNormal ) //Ajuste para considerar a Loja no posicionamento e exibição [Chamado-6851]
		
	SA2->(DBSeek(xFilial("SA2")+(_cAliasZLF)->(ZLF_RETIRO+ZLF_RETILJ)))
	oPrint:Say(nL,nPos3,"CLASS.TANQUE:",oFontRotulo)
	oPrint:Say(nL,nPos4,_aClass[aScan(_aClass,{|x| x[2] == SA2->A2_L_CLASS})][3],oFontNormal) 

	nL += 50
	oPrint:Say(nL,nPos1,"BANCO:",oFontRotulo) 
	oPrint:Say(nL,nPos2,SA2->A2_BANCO+" AG:"+SA2->A2_AGENCIA+" CC:"+SA2->A2_NUMCON,oFontNormal) 

	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	//===================================================================
	// Fim dos dados do Produtor
	//===================================================================

	//===================================================================
	// Início dos eventos do Produtor na ZLF
	//===================================================================
	If MV_PAR09 != 2 //Default ou por produtor
		nL += 50
		oPrint:Say(nL,900,"DEMONSTRATIVO DE PAGAMENTO DE LEITE",oFontRotulo)
		nL += 50
		oPrint:Say(nL,900,"PERIODO DE "+DToC(dpDtIni)+" A "+DToC(dpDtFim),oFontRotulo)
		nL += 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
		oPrint:Say(nL,nTab01,"Eventos       ",oFontRotulo)
		oPrint:Say(nL,nTab02,"Litros        ",oFontRotulo)
		oPrint:Say(nL,nTab03,"Vlr Unit.(R$) ",oFontRotulo)
		oPrint:Say(nL,nTab04,"Ganhos (R$)   ",oFontRotulo)
		oPrint:Say(nL,nTab05,"Descontos (R$)",oFontRotulo)
		nL += 50
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 

		nL += 10

		// Obtem Eventos lancados ao produtor corrente
		_cCampo := "% "
		_cFiltro:= "% "
		If cpMix == "000118" .And. cFilAnt $ "10/11"
			_cCampo += " SUM (Case WHEN ZLF_EVENTO = '000002' THEN ZLF_TOTAL "
			_cCampo += " + NVL((SELECT SUM(ZLF_TOTAL)
			_cCampo += " FROM "+RetSqlName("ZLF")+" B "
			_cCampo += " WHERE B.D_E_L_E_T_ = ' '"
			_cCampo += " AND B.ZLF_FILIAL = ZLF.ZLF_FILIAL"
			_cCampo += " AND B.ZLF_CODZLE = '"+cpMix+"' "
			_cCampo += " AND B.ZLF_SETOR = ZLF.ZLF_SETOR"
			_cCampo += " AND B.ZLF_RETIRO = ZLF.ZLF_RETIRO"
			_cCampo += " AND B.ZLF_RETILJ = ZLF.ZLF_RETILJ"
			_cCampo += " AND B.ZLF_LINROT = ZLF.ZLF_LINROT"
			_cCampo += " AND B.ZLF_TP_MIX = 'L'"
			_cCampo += " AND B.ZLF_EVENTO = '"+_cBonif+"'),0)"
			_cCampo += " Else ZLF_TOTAL"
			_cCampo += " END) AS TOTAL, "
			_cCampo += " SUM (Case WHEN ZLF_EVENTO = '000002' THEN ZLF_VLRPAG "
			_cCampo += " + NVL((SELECT SUM(ZLF_VLRPAG)
			_cCampo += " FROM "+RetSqlName("ZLF")+" B "
			_cCampo += " WHERE B.D_E_L_E_T_ = ' '"
			_cCampo += " AND B.ZLF_FILIAL = ZLF.ZLF_FILIAL"
			_cCampo += " AND B.ZLF_CODZLE = '"+cpMix+"' "
			_cCampo += " AND B.ZLF_SETOR = ZLF.ZLF_SETOR"
			_cCampo += " AND B.ZLF_RETIRO = ZLF.ZLF_RETIRO"
			_cCampo += " AND B.ZLF_RETILJ = ZLF.ZLF_RETILJ"
			_cCampo += " AND B.ZLF_LINROT = ZLF.ZLF_LINROT"
			_cCampo += " AND B.ZLF_TP_MIX = 'L'"
			_cCampo += " AND B.ZLF_EVENTO = '"+_cBonif+"'),0)"
			_cCampo += " Else ZLF_VLRPAG"
			_cCampo += " END) AS VLRPAG, "
		Else
			_cCampo += " SUM(ZLF_TOTAL) AS TOTAL,SUM(ZLF_VLRPAG) AS VLRPAG,"
		EndIf
		If cpMix $ ("000118/000119") .And. cFilAnt $ "10/11"
			_cCampo += " SUM(NVL((SELECT SUM(ZLF_TOTAL)
			_cCampo += " FROM "+RetSqlName("ZLF")+" A "
			_cCampo += " WHERE A.D_E_L_E_T_ = ' '"
			_cCampo += " AND A.ZLF_FILIAL = ZLF.ZLF_FILIAL"
			_cCampo += " AND A.ZLF_CODZLE = '000119'
			_cCampo += " AND A.ZLF_SETOR = ZLF.ZLF_SETOR"
			_cCampo += " AND A.ZLF_RETIRO = ZLF.ZLF_RETIRO"
			_cCampo += " AND A.ZLF_RETILJ = ZLF.ZLF_RETILJ"
			_cCampo += " AND A.ZLF_LINROT = ZLF.ZLF_LINROT"
			_cCampo += " AND A.ZLF_TP_MIX = 'L'"
			_cCampo += " AND A.ZLF_EVENTO = '000035'),0)) ADTO_TOTAL,"

			_cCampo += " SUM(NVL((SELECT SUM(ZLF_VLRPAG)
			_cCampo += " FROM "+RetSqlName("ZLF")+" A "
			_cCampo += " WHERE A.D_E_L_E_T_ = ' '"
			_cCampo += " AND A.ZLF_FILIAL = ZLF.ZLF_FILIAL"
			_cCampo += " AND A.ZLF_CODZLE = '000119' "
			_cCampo += " AND A.ZLF_SETOR = ZLF.ZLF_SETOR"
			_cCampo += " AND A.ZLF_RETIRO = ZLF.ZLF_RETIRO"
			_cCampo += " AND A.ZLF_RETILJ = ZLF.ZLF_RETILJ"
			_cCampo += " AND A.ZLF_LINROT = ZLF.ZLF_LINROT"
			_cCampo += " AND A.ZLF_TP_MIX = 'L'"
			_cCampo += " AND A.ZLF_EVENTO = '000035'),0)) ADTO_VLRPAG, "
		EndIf
		_cCampo += " %"
		
		If cpMix == "000118" .And. cFilAnt $ "10/11"
			_cFiltro += " AND ZLF_EVENTO NOT IN('"+_cBonif+"')"
		ElseIf cpMix == "000119" .And. cFilAnt $ "10/11"
			_cFiltro += " AND ZLF_EVENTO NOT IN ('000035','000036') "
		EndIf
		_cFiltro += " %"

		_cAliasPRD:= GetNextAlias()
		BeginSql alias _cAliasPRD 
			SELECT  ZLF_SETOR, ZLF_EVENTO EVENTO,ZLF_DEBCRE DEBCRE,MAX(ZLF_QTDBOM) QTDBOM, %exp:_cCampo% MAX(ZLF_SEEKCO) SEEKCOMPL
			FROM %Table:ZLF% ZLF
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = %xFilial:ZLF%
			AND ZLF_CODZLE = %exp:cpMix%
			AND ZLF_SETOR = %exp:cpSetor%
			AND ZLF_RETIRO = %exp:(_cAliasZLF)->ZLF_RETIRO%
			AND ZLF_RETILJ = %exp:(_cAliasZLF)->ZLF_RETILJ%
			AND ZLF_LINROT = %exp:(_cAliasZLF)->ZLF_LINROT%
			AND ZLF_TP_MIX = 'L'
			%exp:_cFiltro%
			GROUP BY ZLF_SETOR, ZLF_EVENTO,ZLF_DEBCRE
			ORDER BY ZLF_SETOR, ZLF_DEBCRE,ZLF_EVENTO
		EndSql

		DBSelectArea("ZL8")
		ZL8->( DBSetOrder(1) )
		DBSelectArea("ZL2")
		ZL2->( DBSetOrder(1) )
		
		While !(_cAliasPRD)->(Eof())
			_nInfQual:= 0
			_nTotal := (_cAliasPRD)->TOTAL
			_nVlrPag := (_cAliasPRD)->VLRPAG
			If cpMix $ ("000118/000119") .And. cFilAnt $ "10/11"
				_nBase	:= (_cAliasPRD)->ADTO_TOTAL
			EndIf
			ZL8->(DBSeek(xFilial("ZL8")+(_cAliasPRD)->EVENTO) )
			ZL2->(DBSeek(xFilial("ZL2")+(_cAliasPRD)->ZLF_SETOR) )

			If cpMix == "000118" .And. cFilAnt $ "10/11" .And. (_cAliasPRD)->EVENTO == "000002"
				_nTotal += (_cAliasPRD)->ADTO_TOTAL
				_nVlrPag := (_cAliasPRD)->ADTO_VLRPAG
			ElseIf cpMix == "000118" .And. cFilAnt $ "10/11" .And. (_cAliasPRD)->EVENTO $ "000013/000016/000019" .And. _nBase > 0
				_nVlrPag += &(ZL8->ZL8_FORMUL)
			ElseIf cpMix == "000119" .And. cFilAnt $ "10/11" .And. (_cAliasPRD)->EVENTO $ "000013/000016/000019" .And. _nBase > 0
				_nVlrPag -= &(ZL8->ZL8_FORMUL)
			EndIf
			
			If ZL8->ZL8_RECIBO == "S"
				lmostra:=.T.
			Else
				lmostra:=.F.
			EndIf       
			    
			If lmostra  
			
				_cMesAno  := ""  
				_cDescEven:= Posicione("ZL8",1,xFilial("ZL8")+(_cAliasPRD)->EVENTO,"ZL8_DESCRI")
			          			    				
				//=============================================================
				// Verifica se o evento gerado eh de complemento de pagamento. 
				//=============================================================
				If Len(AllTrim((_cAliasPRD)->SEEKCOMPL)) > 0
					_cMesAno:= RGLT019D((_cAliasPRD)->SEEKCOMPL) 
					_cDescEven:= SubStr(AllTrim(_cDescEven),1,26) +'-'+ _cMesAno            
				EndIf
				
				oPrint:Say(nL,nTab01,SubStr(_cDescEven,1,32),oFontRotulo)								
				
				If (_cAliasPRD)->QTDBOM > 0
					oPrint:Say(nL,nTab02,Transform((_cAliasPRD)->QTDBOM,"@E 999,999,999"),oFontNormal)
				EndIf
				If (_cAliasPRD)->DEBCRE == "C"
					oPrint:Say(nL,nTab03,transform(_nTotal/(_cAliasPRD)->QTDBOM,"@E 9,999,999.9999"),oFontNormal)
					oPrint:Say(nL,nTab04,transform(_nTotal,"@E 999,999,999.99"),oFontNormal)
					nTotCre+=_nTotal
				Else
					oPrint:Say(nL,nTab03,transform(_nVlrPag/(_cAliasPRD)->QTDBOM,"@E 9,999,999.9999"),oFontNormal)
					oPrint:Say(nL,nTab05,transform(_nVlrPag,"@E 999,999,999.99"),oFontNormal)
					nTotDeb+=_nVlrPag
				EndIf
				nL += 50 
			EndIf
			(_cAliasPRD)->(DBSkip())
		EndDo
		(_cAliasPRD)->(DBCloseArea())
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 

		nL += 10
		oPrint:Say(nL,nTab01,"TOTAL",oFontRotulo)
		nVolProd:=U_VolLeite(xFilial("ZLF"),dpDtIni,dpDtFim,cpSetor,(_cAliasZLF)->ZLF_LINROT,(_cAliasZLF)->ZLF_RETIRO,(_cAliasZLF)->ZLF_RETILJ)
		oPrint:Say(nL,nTab02,transform(nVolProd,"@E 999,999,999.99"),oFontRotulo)
		If !(cpMix $ "000118/000119" .And. cFilAnt $ "10/11")
			oPrint:Say(nL,nTab03,transform((nTotCre/nVolProd),"@E 999,999,999.9999"),oFontRotulo)
		EndIf
		oPrint:Say(nL,nTab04,transform(nTotCre,"@E 999,999,999.99"),oFontRotulo)
		oPrint:Say(nL,nTab05,transform(nTotDeb,"@E 999,999,999.99"),oFontRotulo)
		nL += 50
		oPrint:Say(nL,nTab04,"TOTAL A RECEBER-->",oFontRotulo)
		oPrint:Say(nL,nTab05,transform(nTotCre-nTotDeb,"@E 999,999,999.99"),oFontRotulo)
		
		nTotDeb:=0
		nTotCre:=0
	EndIf
	//===================================================================
	// Fim dos eventos do Produtor na ZLF
	//===================================================================

	//===================================================================
	// Início da recepção diária do Leite
	//===================================================================
	nL += 100
	oPrint:Say(nL,900,"VOLUME DE LEITE PRODUZIDO",oFontRotulo)
	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 10

	// Primeira Quinzena
	oPrint:Say(nL,nPos1,"Dia",oFontRotulo)		
	For _nX:=1 To 15
		oPrint:Say(nL,200+(_nX*120),Space(11-Len(AllTrim(Str(_nX))))+AllTrim(Str(_nX)),oFontRotulo)
	Next _nX
	nL += 50
	oPrint:Say(nL,nPos1,"Volume",oFontRotulo)
	For _nX:=1 To 15
		nAux:=RGLT019O((_cAliasZLF)->ZLF_RETIRO,(_cAliasZLF)->ZLF_RETILJ,SubStr(DToS(dpDtIni),1,6)+StrZero(_nX,2),(_cAliasZLF)->ZLF_LINROT)
		oPrint:Say(nL,200+(_nX*120),Transform(nAux,"@E 999,999,999"),oFontNormal)
		nTotVol+=nAux
	Next _nX
	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 

    // Segunda  Quinzena
	oPrint:Say(nL,nPos1,"Dia",oFontRotulo)	
	nUltDia:=Val(SubStr(DToS(dpDtFim),7,2)) // ultimo dia do mes
	For _nX:=16 To nUltDia
		oPrint:Say(nL,200+((_nX-15)*120),Space(11-Len(AllTrim(Str(_nX))))+AllTrim(Str(_nX)),oFontRotulo)
	Next _nX
	nL += 50
	oPrint:Say(nL,nPos1,"Volume",oFontRotulo)
	For _nX:=16 To nUltDia
		//oPrint:Say(nL,200+(n*120),transform(99999,"@E 999,999,999"),oFontNormal)
		nAux:=RGLT019O((_cAliasZLF)->ZLF_RETIRO,(_cAliasZLF)->ZLF_RETILJ,SubStr(DToS(dpDtIni),1,6)+StrZero(_nX,2),(_cAliasZLF)->ZLF_LINROT)
		oPrint:Say(nL,200+((_nX-15)*120),Transform(nAux,"@E 999,999,999"),oFontNormal)
		nTotVol+=nAux
	Next _nX
	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 10
	oPrint:Say(nL,nPos1,"Total:",oFontRotulo)		
	oPrint:Say(nL,nPos2,transform(nTotVol,"@E 999,999,999")+" Litros",oFontNormal)		
	oPrint:Say(nL,nPos3,"Media Diária:",oFontRotulo)		
	oPrint:Say(nL,nPos4,transform(nTotVol/nUltDia,"@E 999,999,999")+" Litros",oFontNormal)		

	nTotVol:=0
	//===================================================================
	// Fim da recepção diária do Leite
	//===================================================================
	
	//===================================================================
	// Início do pagamento por qualidade
	//===================================================================
	// Obtem Data das ultimas 3 analises
	dQual1:= ""  
	dQual2:= ""
	dQual3:= ""
		
	aAux:= RGLT019N((_cAliasZLF)->ZLF_RETIRO,dpDtFim,(_cAliasZLF)->ZLF_RETILJ) 
	
	If Len(aAux)>=3
		dQual1:=aAux[3]
		dQual2:=aAux[2]
		dQual3:=aAux[1]
	EndIf
	If Len(aAux)==2
		dQual1:=aAux[2]
		dQual2:=aAux[1]
	EndIf
	If Len(aAux)==1
		dQual1:=aAux[1]
	EndIf
		
	nL += 100
	oPrint:Say(nL,900,"TABELA DE ANALISES",oFontRotulo)
	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 10
	oPrint:Say(nL,nTab11,"Análise",oFontRotulo)		
	oPrint:Say(nL,nTab12,"Referencia",oFontRotulo)		
	If !Empty(dQual1)
		oPrint:Say(nL,nTab13,DToC(dQual1),oFontRotulo)		
	EndIf
	If !Empty(dQual2)
		oPrint:Say(nL,nTab14,DToC(dQual2),oFontRotulo)		
	EndIf
	If !Empty(dQual3)
		oPrint:Say(nL,nTab15,DToC(dQual3),oFontRotulo)		
	EndIf
	oPrint:Say(nL,nTab16,"Media Arit/Geom.",oFontRotulo)
	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 10
		
	DBSelectArea("ZL9")
	ZL9->(DBSetOrder(1))
	ZL9->(DBSeek(xFilial("ZL9")))
	While !ZL9->(Eof()) .And. xFilial("ZL9")==ZL9->ZL9_FILIAL
		If ZL9->ZL9_TIPO = "Q"   
			oPrint:Say(nL,nTab11,ZL9->ZL9_DESCRI,oFontRotulo)		
			oPrint:Say(nL,nTab12,ZL9->ZL9_REFERE,oFontRotulo)		

			// Verifica tipo de media a ser calculada: Aritmetica ou Geometrica
			IIf(ZL9->ZL9_MEDIA=="G",nTotQual:=1,nTotQual:=0)				                     
			// Obtem valor da primeira Data
			If !Empty(dQual1)
				nAux:=RGLT019V((_cAliasZLF)->ZLF_RETIRO,(_cAliasZLF)->ZLF_RETILJ,dQual1,ZL9->ZL9_COD)
				//Define qual Informativo de qualidade deve ser impresso
				//0-Nenhum 1-CCS 2-CBT 3-CCS+CBT
				If ZL9->ZL9_COD == '000006' .And. nAux > 500//CCS
					_nInfQual := IIf(_nInfQual==0,1,3)
				ElseIf ZL9->ZL9_COD == '000007' .And. nAux > 300//CBT
					_nInfQual := IIf(_nInfQual==0,2,3)
				EndIf
				IIf(ZL9->ZL9_MEDIA=="G",IIf(nAux != 0,nTotQual*=nAux,),nTotQual+=nAux)
				IIf(nAux != 0,nOk++,)
				oPrint:Say(nL,nTab13,Transform(nAux,"@E 9,999,999.99"),oFontNormal)
			EndIf
				
			// Obtem valor da segunda Data
			If !Empty(dQual2)
				nAux:=RGLT019V((_cAliasZLF)->ZLF_RETIRO,(_cAliasZLF)->ZLF_RETILJ,dQual2,ZL9->ZL9_COD)
				//Define qual Informativo de qualidade deve ser impresso
				//0-Nenhum 1-CCS 2-CBT 3-CCS+CBT
				If ZL9->ZL9_COD == '000006' .And. nAux > 500//CCS
					_nInfQual := IIf(_nInfQual==0,1,3)
				ElseIf ZL9->ZL9_COD == '000007' .And. nAux > 300//CBT
					_nInfQual := IIf(_nInfQual==0,2,3)
				EndIf
				IIf(ZL9->ZL9_MEDIA=="G",IIf(nAux != 0,nTotQual*=nAux,),nTotQual+=nAux)
				IIf(nAux != 0,nOk++,)
				oPrint:Say(nL,nTab14,Transform(nAux,"@E 9,999,999.99"),oFontNormal)
			EndIf
				
			// Obtem valor da terceira Data
			If !Empty(dQual3)
				nAux:=RGLT019V((_cAliasZLF)->ZLF_RETIRO,(_cAliasZLF)->ZLF_RETILJ,dQual3,ZL9->ZL9_COD)
				//Define qual Informativo de qualidade deve ser impresso
				//0-Nenhum 1-CCS 2-CBT 3-CCS+CBT
				If ZL9->ZL9_COD == '000006' .And. nAux > 500//CCS
					_nInfQual := IIf(_nInfQual==0,1,3)
				ElseIf ZL9->ZL9_COD == '000007' .And. nAux > 300//CBT
					_nInfQual := IIf(_nInfQual==0,2,3)
				EndIf
				IIf(ZL9->ZL9_MEDIA=="G",IIf(nAux != 0,nTotQual*=nAux,),nTotQual+=nAux)
				IIf(nAux != 0,nOk++,)
				oPrint:Say(nL,nTab15,Transform(nAux,"@E 9,999,999.99"),oFontNormal)
			EndIf
				
			// Media
			If ZL9->ZL9_MEDIA=="G"
				nTotQual:=nTotQual^(1/nOk)
			Else
				nTotQual:=nTotQual/nOk
			EndIf
			
			oPrint:Say(nL,nTab16,Transform(nTotQual,"@E 9,999,999.99")+" "+ZL9->ZL9_MEDIA,oFontNormal)
			nTotQual:=0
			nOk:=0
				
			nL += 50
			nTotQual:=0
		EndIf
		ZL9->(DBSkip())
	EndDo

	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 100
	//===================================================================
	// Fim do pagamento por qualidade
	//===================================================================
		
	//===================================================================
	// Início dos débitos futuros
	//===================================================================
	//Incluída exceção para prefixo GLA na filial 04 porque a diretoria não conseguiu se decidir sobre esse evento
	_cAliasSE2 := GetNextAlias()
	BeginSql alias _cAliasSE2
		SELECT ZL8_COD, ZL8_DESCRI, SUM(E2_SALDO + E2_SDACRES) AS SALDO
		FROM %Table:SE2% SE2, %Table:ZL8% ZL8
		WHERE SE2.D_E_L_E_T_ = ' ' 
		AND ZL8.D_E_L_E_T_ = ' '
		AND E2_PREFIXO = ZL8_PREFIX 
		AND E2_FILIAL = ZL8_FILIAL
		AND E2_TIPO = 'NDF'
		AND ((E2_PREFIXO <> 'GLA' AND E2_FILIAL = '04') OR (E2_FILIAL <> '04'))
		AND E2_SALDO   > 0  
		AND E2_FORNECE = %exp:(_cAliasZLF)->ZLF_RETIRO%
		AND E2_LOJA    = %exp:(_cAliasZLF)->ZLF_RETILJ%
		GROUP BY ZL8_COD,ZL8_DESCRI
	EndSql
        
	Count to nReg
	(_cAliasSE2)->(DBGoTop())
	If nReg > 0
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
		oPrint:Say(nL,900,"DEBITOS FUTUROS",oFontRotulo)
		nL += 50
		nTotPend:=0
		oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
		nL += 10
    EndIf               
	                             
	While (_cAliasSE2)->(!Eof())
		oPrint:Say(nL,nPos1,(_cAliasSE2)->ZL8_COD,oFontRotulo)
		oPrint:Say(nL,nPos2,(_cAliasSE2)->ZL8_DESCRI,oFontRotulo)
		oPrint:Say(nL,nPos3,transform((_cAliasSE2)->SALDO,"@E 999,999.99"),oFontRotulo) 
		nL += 50
		
		nTotPend+=(_cAliasSE2)->SALDO
		
		(_cAliasSE2)->(DBSkip())
	EndDo
	(_cAliasSE2)->(DBCloseArea())

	If nReg > 0
		oPrint:Say(nL,nPos1,"Valor Total Pendente ------>",oFontRotulo)
		oPrint:Say(nL,nPos3,transform(nTotPend,"@E 999,999.99"),oFontRotulo)
		nL += 50
	EndIf
	//===================================================================
	// Fim dos débitos futuros
	//===================================================================
		
	//===================================================================
	// Início do rodapé
	//===================================================================
	nL += 50 
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 10
	oPrint:Say(nL,800,"I N F O R M A T I V O      A O     P R O D U T O R ",oFontRotulo)
	nL += 50
	oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
	nL += 10

	aMensagem := u_showMemo(Posicione("ZLP",2,xFilial("ZLP")+cpMix+"1"+cpSetor,"ZLP_MENSAG"),120)
	For _nX:=1 To Len(aMensagem)
		If _nX <= 7 // Max. de Linhas
			oPrint:Say(nL,nPos1,aMensagem[_nX],oFontNormal)
			nL += 50 
		EndIf
	Next _nX
	//===================================================================
	// Fim do rodapé
	//===================================================================
	
	oPrint:EndPage()
	//===================================================================
	// Início do Informativo de Qualidade
	//===================================================================
	If _nInfQual > 0 .And. MV_PAR10 == 1

	    oPrint:StartPage()

	    ImpCab()
		nL += 50
		oPrint:Say(nL,900,"INFORMATIVO DE QUALIDADE INDIVIDUAL",oFontTitulo)
		nL += 100
		oPrint:Say(nL,nPos1,"Prezado (a) "+ AllTrim(SA2->A2_NOME)+",",oFontTitulo)
		nL += 100
		
		_cMenAux:= "O leite fornecido (a) pela sua propriedade rural a ITALAC se encontra fora dos padrões definidos pelas Instruções Normativas 76 e 77 "
		_cMenAux+= "(preconizadas pelo Ministério da Agricultura, Pecuária e Abastecimento) devido à alta taxa de "
		If _nInfQual == 1
			_cMenAux += "Contagem de Células Somáticas - CCS (também chamado de indicador de mastite)."
		ElseIf _nInfQual == 2
			_cMenAux += "Contagem Bacteriana Total - CBT (também chamado de indicador de Higiene)."
		Else
			_cMenAux += "Contagem Bacteriana Total - CBT (também chamado de indicador de Higiene) "
			_cMenAux += "e alta taxa de Contagem de Células Somáticas (também chamado de indicador de mastite)."
		EndIf
		impTexto(_cMenAux)
		If _nInfQual == 1
			oPrint:Say(nL,nPos1,"LOGO, SEGUE ABAIXO ALGUMAS INSTRUÇÕES DE COMO MELHORAR A TAXA DE CCS: ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"1.	DETECÇÃO DOS CASOS DE MASTITE ATRAVÉS DO USO DO TESTE DA CANECA DE FUNDO ESCURO (O LEITE QUE APRESENTAR GRUMOS, O(A) SENHOR(A) ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"DEVE SEPARAR ESTE ANIMAL PARA O FINAL DA ORDENHA E ESTE LEITE NÃO DEVE SER COLOCADO JUNTO AO LEITE FORNECIDO PARA O LATICÍNIO) ",oFontTitulo); nL += 100
			oPrint:Say(nL,nPos1,"2.	USO DO PÓS-DIPPING (EXEMPLO: IODO, ÁCIDO LÁCTICO, ENTRE OUTROS) APÓS A ORDENHA: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Cerca de 50% das Mastites é controlado com o uso diário do Pós Dipping ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"3.	APÓS A ORDENHA FORNECER ALIMENTAÇÃO PARA OS ANIMAIS, PARA QUE OS MESMOS NÃO DEITEM, POIS O TETO DO ANIMAL SE ENCONTRA ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"ABERTO ",oFontTitulo); nL += 100
			oPrint:Say(nL,nPos1,"4.	TRATAMENTO DOS CASOS DE MASTITE – CLÍNICA ",oFontTitulo); nL += 100
			oPrint:Say(nL,nPos1,"5.	CORRETA SECAGEM DOS ANIMAIS: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Uso do “antibiótico vaca-seca” para controle de Mastite no período seco ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Não ultrapassar o tempo de 10 meses de Lactação ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"6.	CUIDADOS NO PRÉ - PARTO: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	O Local do pré - parto tem que ser o mais adequado (evitar locais com acúmulo de “barro”) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Se o animal já começou a soltar leite antes da parição, o mesmo deve passar pela ordenha para realização do Pós Dipping ",oFontRotulo); nL += 100
		ElseIf _nInfQual == 2
			oPrint:Say(nL,nPos1,"LOGO, SEGUE ABAIXO ALGUMAS INSTRUÇÕES DE COMO MELHORAR A TAXA DE CBT: ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"1.	REALIZAÇÃO DE UMA ORDENHA HIGIÊNICA: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Realizar a desinfecção dos tetos antes do inicio da ordenha (chamado de Pré-dipping) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Secar os tetos com papel toalha ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"c.	Após o término da ordenha utilizar o Pós-dipping (exemplo: iodo, ácido láctico, entre outros) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"d.	Utilização do coador/filtro adequado a ordenha ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"e.	Caso use ordenha “balde ao pé”, levar o leite para o tanque quando o latão atingir metade de sua capacidade ou, o mais rápido possível ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"2.	HIGIENIZAÇÃO DO EQUIPAMENTO DE ORDENHA: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Após o término da ordenha, circular água morna no sistema até a água sair completamente limpa ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Passagem do detergente alcalino clorado, em água com temperatura de 70 a 75º C (esta água deve circular de 08 a 10 minutos, não deixando ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"a água sair fria (menor que 45º C)) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"d.	Passagem do detergente ácido, em água a temperatura “ambiente” 01 ou mais vezes por semana ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"e.	Realizar a inspeção da ordenha a cada 07 dias, para verificar se não existe o acumulo de resíduo na ordenhadeira (caso exista realizar ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"a limpeza manual) ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"3.	HIGIENIZAÇÃO DO TANQUE DE EXPANSÃO OU LATÃO: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	A lavagem dos latões e do tanque tem que ser realizada com detergente alcalino clorado, juntamente com uma escova adequada ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Retirar toda a água com detergente ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"c.	Passagem do detergente ácido, em água a temperatura “ambiente” 01 vez por semana ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"d.	Verificar a limpeza do tanque, quando ele estiver seco, com o auxílio de uma lanterna ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"4.	MANUTENÇÃO DO TERMÔMETRO DO TANQUE: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Verifique junto ao transportador de seu leite, se a temperatura do seu leite analisada pelo termômetro do transportador é igual a temperatura ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"marcada pelo tanque (caso apareça diferença, contate um técnico para a realização da manutenção do seu tanque) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b. A temperatura máxima de estocagem e de coleta do seu leite deve ser de 4º C ou menos ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"A Contagem Bacteriana de seu leite é determinada pela Higiene durante o processo de ordenha e pela refrigeração rápida do leite, logo as ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"instruções acima vão indicar qual caminho seguir ",oFontRotulo); nL += 50
		Else
			oPrint:Say(nL,nPos1,"LOGO, SEGUE ABAIXO ALGUMAS INSTRUÇÕES DE COMO MELHORAR AS TAXAS DE CBT e CCS: ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"1.	REALIZAÇÃO DE UMA ORDENHA HIGIÊNICA: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Detecção dos casos de mastite através do uso do teste da caneca de fundo escuro (o leite que apresentar grumos, o(a) senhor(a) ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1," deve separar este animal para o final da ordenha e este leite não deve ser colocado junto ao leite fornecido para o laticínio) ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Após, realizar a desinfecção dos tetos (chamado de Pré-dipping) e a secagem com papel toalha ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"c.	Ao término da ordenha nos animais, utilizar o Pós-dipping (exemplo: iodo, ácido láctico, entre outros) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"d.	Cerca de 50% das Mastites é controlado com o uso diário do Pós Dipping ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"e.	Utilização do coador/filtro adequado a ordenha e caso use ordenha “balde ao pé”, levar o leite para o tanque quando o latão atingir metade ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"de sua capacidade ou, o mais rápido possível ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"2.	APÓS A ORDENHA FORNECER ALIMENTAÇÃO PARA OS ANIMAIS, PARA QUE OS MESMOS NÃO DEITEM, POIS O TETO DO ANIMAL SE ENCONTRA ABERTO ",oFontTitulo); nL += 100
			oPrint:Say(nL,nPos1,"3.	TRATAMENTO DOS CASOS DE MASTITE – CLÍNICA ",oFontTitulo); nL += 100
			oPrint:Say(nL,nPos1,"4.	CORRETA SECAGEM DOS ANIMAIS: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Uso do “antibiótico vaca-seca” para controle de Mastite no período seco ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Não ultrapassar o tempo de 10 meses de Lactação ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"5.	HIGIENIZAÇÃO DO EQUIPAMENTO DE ORDENHA: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Após o término da ordenha, circular água morna no sistema até a água sair completamente limpa ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Passagem do detergente alcalino clorado, em água com temperatura de 70 a 75º C (esta água deve circular de 08 a 10 minutos, não deixando ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"a água sair fria (menor que 45º C)) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"c.	Passagem do detergente ácido, em água a temperatura “ambiente” 01 ou mais vezes por semana ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"d.	Realizar a inspeção da ordenha a cada 07 dias, para verificar se não existe o acumulo de resíduo na ordenhadeira (caso exista realizar ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"a limpeza manual) ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"6.	HIGIENIZAÇÃO DO TANQUE DE EXPANSÃO OU LATÃO: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	A lavagem dos latões e do tanque tem que ser realizada com detergente alcalino, juntamente com uma escova adequada ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b.	Passagem do detergente ácido, em água a temperatura “ambiente” 01 ou mais vezes por semana ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"c.	Verificar a limpeza do tanque, quando ele estiver seco, com o auxílio de uma lanterna ",oFontRotulo); nL += 100
			oPrint:Say(nL,nPos1,"7.	MANUTENÇÃO DO TERMÔMETRO DO TANQUE: ",oFontTitulo); nL += 50
			oPrint:Say(nL,nPos1,"a.	Verifique junto ao transportador de seu leite, se a temperatura do seu leite analisada pelo termômetro do transportador é igual a temperatura ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"marcada pelo tanque (caso apareça diferença, contate um técnico para a realização da manutenção do seu tanque) ",oFontRotulo); nL += 50
			oPrint:Say(nL,nPos1,"b. A temperatura máxima de estocagem e de coleta do seu leite deve ser de 4ºC ou menos ",oFontRotulo); nL += 100
		EndIf
		
		nL += 100
		oPrint:Say(nL,nPos1,"Segue abaixo os padrões das Instruções Normativas 76 e 77:",oFontRotulo)
		nL += 100
		oPrint:FillRect({nL,500,nL+1,2000},TBrush():New("",0))
		nL += 10
		oPrint:Say(nL,nTab13,"CBT",oFontRotulo)
		oPrint:Say(nL,nTab14,"CCS",oFontRotulo)
		oPrint:Say(nL,nTab15,"GORDURA",oFontRotulo)
		oPrint:Say(nL,nTab16,"PROTEINA",oFontRotulo)
		nL += 50
		oPrint:FillRect({nL,500,nL+1,2000},TBrush():New("",0))
		nL += 10
		oPrint:Say(nL,nTab13,"Máximo de 300",oFontRotulo)
		oPrint:Say(nL,nTab14,"Máximo de 500 ",oFontRotulo)
		oPrint:Say(nL,nTab15,"Mínimo de 3,0 %",oFontRotulo)
		oPrint:Say(nL,nTab16,"Mínimo de 2,9%",oFontRotulo)
		nL += 50
		oPrint:Say(nL,nTab13,"(x 1.000 UFC/ml)",oFontNormal)
		oPrint:Say(nL,nTab14,"(x 1.000 CCS/ml)",oFontNormal)
		nL += 50
		oPrint:FillRect({nL,500,nL+1,2000},TBrush():New("",0)) 
		
		nL += 100
		oPrint:Say(nL,nPos1,"Qualquer dúvida, estamos à disposição para marcarmos visitas técnicas na melhoria da qualidade do seu leite.",oFontRotulo)
		nL += 10
		
		oPrint:EndPage()
	EndIf
	//===================================================================
	// Fim do Informativo de Qualidade
	//===================================================================
	(_cAliasZLF)->(DBSkip())
	
EndDo
(_cAliasZLF)->(DBCloseArea())
	
oPrint:Preview()

Return

/*
===============================================================================================================================
Programa----------: RGLT019N
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------:Obtem datas das ultimas tres analises
Parametros--------: cpCodPrd - código do produtor
					dpData - database
					cLojaProd - loja do produtor
Retorno-----------: aret - array com datas das últimas análises
===============================================================================================================================
*/
Static Function RGLT019N(cpCodPrd As Character,dpData As Date,cLojaProd As Character) As Array

Local aArea		:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local aRet		:={} As Array
Local nQtd		:=0 As Numeric
Local _nAno		:= Val( SubStr( DToS( dpData ) , 1 , 4 ) ) As Numeric
Local _nMes		:= Val( SubStr( DToS( dpData ) , 5 , 2 ) ) As Numeric
Local _sDtInic	:= "" As Character
Local _sDtFinal	:= DToS(dpData) As Character

//===================================================================
// Define os ultimos tres meses a serem considerados para obter      
// as analises de qualidade, isto de acordo com o mes de fechamento. 
//===================================================================
If _nMes - 2 == 0 
	_sDtInic:= AllTrim(Str(_nAno - 1)) + '1201'
ElseIf _nMes - 2 == -1 
	_sDtInic:= AllTrim(Str(_nAno - 1)) + '1101'
Else   
	_sDtInic:= AllTrim(Str(_nAno)) + AllTrim(StrZero(_nMes - 2,2)) + '01' //HEDER - 05/04/12 - Corrigido para considerar dois digitos no mes
EndIf

// Obtem Data das analise
BeginSql alias _cAlias 
	SELECT ZLB_DATA
	FROM %Table:ZLB%
	WHERE D_E_L_E_T_ = ' '
	AND ZLB_FILIAL = %xFilial:ZLB%
	AND ZLB_RETIRO = %exp:cpCodPrd%
	AND ZLB_RETILJ = %exp:cLojaProd%
	AND ZLB_DATA BETWEEN %exp:_sDtInic% AND %exp:_sDtFinal%
	GROUP BY ZLB_DATA
	ORDER BY ZLB_DATA DESC
EndSql

While !(_cAlias)->(Eof()) .And. nQtd<=2
	nQtd++
	aAdd(aRet,SToD((_cAlias)->ZLB_DATA))
	(_cAlias)->(DBSkip())
EndDo          

(_cAlias)->(DBCloseArea())

FWRestArea(aArea)
Return aRet

/*
===============================================================================================================================
Programa----------: RGLT019V
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------:Obtem valor analises
Parametros--------: cpCodPrd - código do produtor
					dpData - data da análise
					cLojaProd - loja do produtor
					cpTipoFx - tipo da análise
Retorno-----------: nret - valor da análise
===============================================================================================================================
*/
Static Function RGLT019V(cpCodPrd As Character,cpLj As Character,dpData As Date,cpTipoFx As Character) As Numeric

Local _cAlias	:= GetNextAlias() As Character
Local _aArea	:= FWGetArea() As Array
Local _nRet		:=0 As Numeric

If Empty(dpData)
	Return 0
EndIf                            

// Obtem valor da analise na data referida
BeginSql Alias _cAlias
	SELECT ZLB_VLRFX
	FROM %Table:ZLB% ZLB
	WHERE D_E_L_E_T_ = ' '
	AND ZLB_FILIAL = %xFilial:ZLB%
	AND ZLB_DATA   = %exp:dpData%
	AND ZLB_TIPOFX = %exp:cpTipoFx%
	AND ZLB_RETIRO = %exp:cpCodPrd%
	AND ZLB_RETILJ = %exp:cpLj%
EndSql

_nRet := (_cAlias)->ZLB_VLRFX

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return _nRet

/*
===============================================================================================================================
Programa----------: RGLT019O
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------: Retorna volume por dia/produtor
Parametros--------: cpCodPrd - código do produtor
					cpdia - data da doleta
					cpLj - loja do produtor
					clinrota - linha da coleta
Retorno-----------: nret - volume coletado
===============================================================================================================================
*/
Static Function RGLT019O(cpCodPrd As Character,cpLj As Character,cpDia As Character,cLinRota As Character) As Numeric

Local _cAlias	:= GetNextAlias() As Character
Local _aArea	:= FWGetArea() As Array
Local _nRet		:=0 As  Numeric

// Obtem Volume do dia 
BeginSql alias _cAlias
	SELECT SUM(ZLD_QTDBOM) VOLUME
	FROM %Table:ZLD% ZLD
	WHERE D_E_L_E_T_ = ' '
	AND ZLD_FILIAL = %xFilial:ZLD%
	AND ZLD_RETIRO = %exp:cpCodPrd%
	AND ZLD_RETILJ = %exp:cpLj%
	AND ZLD_DTCOLE = %exp:cpDia%
	AND ZLD_LINROT = %exp:cLinRota%
EndSql

_nRet:=(_cAlias)->VOLUME

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return _nRet

/*
===============================================================================================================================
Programa----------: RGLT019O
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------: Retorna data do complemento
Parametros--------: _cSeekComp - código do complemento
Retorno-----------: _cMesAno - data do complemento
===============================================================================================================================
*/
Static Function RGLT019D(_cSeekComp As Character) As Character

Local _cAlias := GetNextAlias() As Character
Local _cMesAno:= "" As Character
Local _cFiltro:= "%" As Character

//===============================================================
// Complemento de pagamento gerado para ser pago no proximo Mix. 
//===============================================================
If 'MGLT026' $ _cSeekComp   

	_cFiltro += " AND ZZD.ZZD_CODIGO = '" + SubStr(_cSeekComp,1,6)+ "'"
	_cFiltro += "%"
     
	BeginSql alias _cAlias
		SELECT SubStr(ZLE.ZLE_DTINI,1,6) anoMes
		FROM %Table:ZZD% ZZD, %Table:ZLE% ZLE 		      
		WHERE ZZD.D_E_L_E_T_ = ' '
		AND ZLE.D_E_L_E_T_ = ' '
		AND ZLE.ZLE_COD = ZZD.ZZD_MIXORI
		%exp:_cFiltro%
	EndSql  
	_cMesAno:= SubStr((_cAlias)->anoMes,5,2) + '/' + SubStr((_cAlias)->anoMes,1,4) 

//==============================================================
// Complemento de pagamento gerado para ser pagao no mix atual  
// fechamento gerar financeiro.                                 
//==============================================================
ElseIf 'MGLT027' $ _cSeekComp
	
	_cFiltro += " AND ZZE.ZZE_CODIGO = '" + SubStr(_cSeekComp,1,9)+ "'"
	_cFiltro += "%"
	
	BeginSql alias _cAlias 
		SELECT SubStr(ZLE.ZLE_DTINI,1,6) anoMes
		FROM %Table:ZZE% ZZE, %Table:ZLE% ZLE
		WHERE ZZE.D_E_L_E_T_ = ' '
		AND ZLE.D_E_L_E_T_ = ' '
		AND ZLE.ZLE_COD = ZZE.ZZE_MIXORI
		%exp:_cFiltro%
	EndSql
	_cMesAno:= SubStr((_cAlias)->anoMes,5,2) + '/' + SubStr((_cAlias)->anoMes,1,4) 

EndIf     
(_cAlias)->(DBCloseArea())   

Return _cMesAno

/*
===============================================================================================================================
Programa----------: ImpCab()
Autor-------------: Abrahao P. Santos
Data da Criacao---: 24/01/2009
Descrição---------: Faz a impressão do cabeçalho do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ImpCab()

//===================================================================
// Início Cabecalho
//===================================================================
nL := 50
oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0))
oPrint:SayBitmap(nL+20,100,cRaizServer + "system/lgrl01.bmp",250,100)
nL += 10
oPrint:Say(nL,2000,"Emissão:"+DToC(DDataBase),oFontNormal)
nL += 50

If MV_PAR09 != 2 //Default ou por produtor
	oPrint:Say(nL,1000,"Demonstrativo do Produtor",oFontTitulo)
Else
	oPrint:Say(nL,1000,"Demonstrativo do Leite",oFontTitulo)
EndIf
oPrint:Say(nL,2000,"Paginas: 1/1 ",oFontNormal)
nL += 50
oPrint:Say(nL,2000,"Hora:"+time(),oFontNormal)
nL += 50
oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0)) 
nL += 10
//===================================================================
// Fim Cabecalho
//===================================================================

//===================================================================
// Início dos dados da Empresa
//===================================================================
oPrint:Say(nL,nPos1,AllTrim(SM0->M0_NOME)+"-"+AllTrim(SM0->M0_FILIAL)+"-"+SM0->M0_NOMECOM,oFontRotulo)
oPrint:Say(nL,nPos3,"CNPJ:"+SM0->M0_CGC,oFontRotulo)
nL += 50
oPrint:Say(nL,nPos1,AllTrim(SM0->M0_ENDENT)+"-"+AllTrim(SM0->M0_CIDENT)+"-"+AllTrim(SM0->M0_ESTENT),oFontRotulo)
nL += 50
oPrint:FillRect({nL,2300,nL+1,100},TBrush():New("",0))
nL += 10
//===================================================================
// Fim dos dados da Empresa
//===================================================================
Return

/*
===============================================================================================================================
Programa--------: impTexto
Autor-----------: Fabiano Dias
Data da Criacao-: 05/09/2011
Descrição-------: Funçãoo para realizar a formataçãoo, ou seja, justificar o texto para que o mesmo fique melhor disposto no
				  corpo da página.
Parametros------: _cTexto -> Texto a ser formatado de forma justificada
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function impTexto(_cTexto As Character)

Local _aTexto   := Separa(_cTexto," ",.F.) As Array//Quebro o texto em palavras
Local _nNumCarac:= 131 As Numeric//Numero maximo de caracteres por linha

Local _cLinImpr := "" As Character//Texto de impressao inicial do array
Local _nPosInic := 1 As Numeric//Posicao inicial do array que comecou uma linha     
Local _nNumEspac:= 0 As Numeric//Numero de espacos vazios necessario para justificar o texto
Local _nNumPalav:= 0 As Numeric

Local _lEntrou  := .F. As Logical
Local _nVlrDiv  := 0 As Numeric
Local _nEspacame:= 0 As Numeric

Local _nEspcAdic:= 0 As Numeric     
Local _nVlrEspac:= 0 As Numeric
Local _nK		:= 0 As Numeric
Local _nX		:= 0 As Numeric

//Para que todo inicio de nova linha seja impresa como um paragrafo
_aTexto[1]:= "       "  + _aTexto[1]                           

//Percorre todas as palavras quebradas por espaco do texto passado como parametro
For _nX:=1 to Len(_aTexto)

	_lEntrou  := .F. 
	_nNumPalav++                     	  	                     	

	//Verifica se eh a primeira palavra a ser inserida
	If Len(_cLinImpr) == 0
		_cLinImpr := _aTexto[_nX]
 	Else				
	  	If Len(_cLinImpr + " " + _aTexto[_nX]) <= _nNumCarac
			_cLinImpr += " " + _aTexto[_nX]
		ElseIf Len(_cLinImpr) < _nNumCarac 
			//Numero de espacos em branco a complementar					                                                    					
			_nNumEspac:= _nNumCarac - Len(_cLinImpr) 	
			_cLinImpr := ""					 					 					                  					
					
			//Se numero de caracteres For possivel de se distribuir os espacos em branco entre os numero de palavras
			If _nNumEspac < _nNumPalav - 2												
				For _nK:=_nPosInic to _nX-1  
					If Len(_cLinImpr) == 0
						_cLinImpr := _aTexto[_nK]
					Else
						If _nNumEspac > 0   
							_cLinImpr += "  " + _aTexto[_nK]
							_nNumEspac-= 1
						Else
							_cLinImpr += " " +_aTexto[_nK]
						EndIf   
					EndIf					                                						   							
				Next _nK
			                    			                
			//==================================================================
			//Caso o numero de espacos em branco a complementar a linha atual
			//seja maior que o numero de palavras da linha atual
			//==================================================================
			Else          			                	               
				_nEspcAdic:= 0
			    _nNumPalav:= _nNumPalav - 2//Numero de palavras a serem consideradas para insercao dos espacos em branco			                		
			    _nVlrDiv  := Mod(_nNumEspac,_nNumPalav)//Divisao para constatar se o numero de espacos em branco dividido pelo numero de palavras eh multiplo									    
				_nEspacame:= Int(_nNumEspac / _nNumPalav)
				
				//Contabiliza o numero de caracteres restantes entre o multiplo da divisao para ser valores adicionais
				If _nVlrDiv != 0 
					_nEspcAdic:= _nNumEspac - (_nNumPalav * _nEspacame)
				EndIf 
									    
				For _nK:=_nPosInic to _nX-1  
					If Len(_cLinImpr) == 0
						_cLinImpr := _aTexto[_nK]
					Else			  
						If _nEspcAdic > 0
							_nEspcAdic-- 																			
							_nVlrEspac:= _nEspacame + 2
						Else
							_nVlrEspac:= _nEspacame + 1
						EndIf
						_cLinImpr += Space(_nVlrEspac) + _aTexto[_nK]
					EndIf
				Next _nK
		  	EndIf    	                 	                	                	                

		    _nPosInic:= _nX
            //Para que a palavra que nao foi impressa neste Loop seja impressa na proxima execucao
            _nX:= _nX-1
            _lEntrou:= .T.     
		EndIf 	
	EndIf         		

	//Imprime de acordo com o numero maximo de caracteres montados a linha formatada anteriormente
	If Len(_cLinImpr) == _nNumCarac
	  
		oPrint:Say (nL + 10,nPos1,_cLinImpr,oFontRotulo) 
		nL+=50
		
		_cLinImpr:= ""     
		_nNumPalav:= 0
		            
		If !_lEntrou
			_nPosInic:= _nX + 1
		EndIf
	
	EndIf

Next _nX

//Imprime a ultima parte da mensagem que eh menor do que o numero de caracteres estipulado por linha
If Len(_cLinImpr) < _nNumCarac 
	oPrint:Say (nL + 10,nPos1,_cLinImpr,oFontRotulo)
	nL+=50
EndIf

Return
