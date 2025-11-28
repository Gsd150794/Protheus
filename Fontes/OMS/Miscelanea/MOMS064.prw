/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |08/07/2024| Chamado 47783. Ajustes para melhoria de performance.
Alex Wallauer |05/08/2024| Chamado 48099. Correção de error.log: Escrito errado SPECE().
Lucas Borges  |09/10/2024| Chamado 48465. Retirada da função de conout
=====================================================================================================================================
*/

#Include "TOTVS.ch"      
#Include "APWEBSRV.CH"    
#Include "TBICONN.CH" 

Static _lScheduller := FWGetRunSchedule() .Or. SELECT("SX3") <= 0

/*
===============================================================================================================================
Programa--------: MOMS064
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/04/2022
Descrição-------: Rotina de Comissão e Análise Gerencial. Chamado 38767.
Parametros------: _lScheduller = .T. = Rotina chamada via Scheduller
                                 .F. = Rotina chamada via menu
Retorno---------: Nenhum
===============================================================================================================================
*/  
User Function MOMS064(_nRecnoZC9)  
Local _cDataF // := ZC9->ZC9_COMP  // Data do fechamento posicionado // mm/aaaa
Local _nMes   // := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nAno   // := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))

Private _dFechamen := Ctod("  /  /  ")
Private _nSequen 
Private _lGravouZBK := .F.
Private _lLeuTdSA3  := .F.

Begin Sequence 

   If _lScheduller
	  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06401"/*cMsgId*/, "MOMS06401 - Inicio da gravação dos dados gerenciais de comissão na tabela ZBK."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Else // Deve estar posicionado no registro da tabela ZC9 correspondente.
      If ! U_ITMsg("Confirma o processamento da rotina de geração e gravação dos dados de comissão para análise gerencial? "+;
         " Esta rotina tem o objetivo de alimentar a tabela de valores gerenciais da comissão." + ;
         " É executada mensalmente pela equipe de comissão. ", "Atenção", "",2,2,2) 
         Break
      EndIf 
   EndIf

   ZC9->(DBGoTo(_nRecnoZC9)) 

   _cDataF := ZC9->ZC9_COMP  // Data do fechamento posicionado // mm/aaaa  

   _nMes   := Val(SubStr(_cDataF,1,2)) 
   _nAno   := Val(SubStr(_cDataF,4,4)) 

   _dFechamen := Ctod("01/"+StrZero(_nMes,2)+"/"+StrZero(_nAno,4))
   
   _nSequen := U_MOMS064S(_dFechamen) // Retorna a ultima versão gravada para o período informado.

   If _nSequen == 0
      _nSequen += 1
   EndIf 

   ZBK->(DBSetOrder(1)) // ZBK_FILIAL+DToS(ZBK_DTFECH)+ZBK_VERSAO
   If ZBK->(MsSeek(xFilial("ZBK")+DToS(_dFechamen)+StrZero(_nSequen,3) ))

      If _lScheduller
		 FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06402"/*cMsgId*/, "MOMS06402 - O calclulo deste período já foi iniciado uma vez. Calculando o período com uma nova sequencia."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Else
         If ! U_ITMsg("O período informado já foi calculado anteriormente pelo usuário(a) "+ AllTrim(ZBK->ZBK_USRNMI) + ". " + ;
                      "Caso confirme os dados anteriores serão substituídos por novos registros " + ;
                      "e caso tenha ocorrido algum recalculo nas comissões após o fechamento desta data, " + ; 
                      "podem ocorrer diferenças entre os valores apontados apontados anteriormente e agora! " + ;
                      "Deseja prosseguir com o recalculo? " , "Atenção", "",2,2,2) 
            Break
	     EndIf  
	  EndIf 
	  
	  _nSequen += 1

   EndIf 

   If _lScheduller
      U_MOMS064P(Nil,_cDataF) // Processando rotina de Geração e Gravação de Dados de Comissão para Análise Gerencial.. "
   Else
      FWMsgRun(,{|oProc|  U_MOMS064P(oProc,_cDataF)   } ,'Aguarde processamento...','Lendo dados...')
   EndIf 

   If _lGravouZBK .And. _lLeuTdSA3 // Se gravou dados na tabela ZBK e Leu to"Aguarde...", "Processando rotina de Geração e Gravação de Dados de Comissão para Análise Gerencial.. "da a tabela SA3, muda o status.
      ZC9->(RecLock("ZC9"), .F.)
      ZC9->ZC9_STATUS := "4" // Indica que a gravação dos dados na tabela ZBK foram concluidos para o período informado.
      ZC9->(MSUnLock())
   EndIf 

End Sequence 

If _lScheduller
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06403"/*cMsgId*/, "MOMS06403 - Processamento da rotina Rotina de Comissão e Análise Gerencial concluido."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
Else 
   U_ITMsg("Processamento da rotina Rotina de Comissão e Análise Gerencial concluido.","Atenção",,1)
EndIf 

Return 

/*
===============================================================================================================================
Programa----------: MOMS064P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 26/04/2022
Descrição---------: Rotina de Geração dos dados de Comissão e Análise Gerencial
Parametros--------: _cDataf - Data de fechamento da Comissão.
                    _lScheduller - .T. = Rotina rodada via Scheduller
					               .F. = Rotina chamada via menu.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS064P(oProc,_cDataf)

Local _nMes        := month(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _nAno        := year(SToD(SubStr(_cDataf,4,4)+SubStr(_cDataf,1,2)+'01'))
Local _cQry        := ""

Default oProc := Nil

Private _cPeriodo  := ""
Private _cVendedor := ""
Private _cNomeVend := Space(40)        // ZBK_NOMVEN	C	40	0	Nome Vend.
Private _cCoordena := ""
Private _cSupervis := ""
Private _cGerente  := ""
Private _cGerenNac := ""
Private _cTipoVend := Space(15)        // ZBK_TIPVEN	C	15	0	Tipo Vended
Private _aDados    := {}

Begin Sequence 
   
   _cPeriodo := StrZero(_nAno,4)+StrZero(_nMes,2) // Periodo para gravação dos dados.

   If Select("TRBSA3") > 0
      TRBSA3->( DBCloseArea() )
   EndIf

	_cQry += " SELECT CODVEND "
	_cQry += " FROM( "
	_cQry += "	SELECT CODVEND "
	_cQry += "	FROM ( "
	_cQry += "		SELECT E3.CODVEND, SA3.A3_NOME, SA3.A3_SUPER, A3_GEREN  "
	_cQry += "		FROM ( "
	_cQry += "			SELECT E3.E3_VEND CODVEND "
	_cQry += "			FROM  "+ RetSqlName('SE3') +" E3 "
	_cQry += "			WHERE E3.D_E_L_E_T_ = ' ' "
	_cQry += "				AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+_cPeriodo+"'  "
	_cQry += "			GROUP BY E3.E3_VEND "
				
	_cQry += "			UNION ALL  "
				
	_cQry += "			SELECT E3.E3_VEND "
	_cQry += "			FROM ( "
	_cQry += "				SELECT SF2.F2_VEND1        AS E3_VEND   		 "
	_cQry += "				FROM  "+ RetSqlName('SF2') +" SF2  "
	_cQry += "				     JOIN  "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL  " 
	_cQry += "				     JOIN  "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD AND SB1.B1_FILIAL = '  ' "
	_cQry += "				     JOIN  "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO  "
	_cQry += "				     JOIN  "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF  "
	_cQry += "				WHERE SF2.D_E_L_E_T_ = ' '  "
	_cQry += "				     AND SD2.D_E_L_E_T_ = ' ' " 
	_cQry += "				     AND SB1.D_E_L_E_T_ = ' '  "
	_cQry += "				     AND SF4.D_E_L_E_T_ = ' '  "
	_cQry += "				     AND ZAY.D_E_L_E_T_ = ' '  "
	_cQry += "				     AND SB1.B1_TIPO    = 'PA'  "
	_cQry += "				     AND ZAY.ZAY_TPOPER	= 'B' "
	_cQry += "				     AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+_cPeriodo+"' "
	_cQry += "				GROUP BY SF2.F2_VEND1 "
	_cQry += "			) E3 "
				
	_cQry += "		) E3 "
	_cQry += "		LEFT JOIN  "+ RetSqlName('SA3') +" SA3 ON E3.CODVEND = SA3.A3_COD  "
	_cQry += "		GROUP BY E3.CODVEND, SA3.A3_NOME,A3_SUPER, A3_GEREN "
	_cQry += "	) E3 "
		
	_cQry += "	UNION ALL "
		
	_cQry += "	SELECT A3_SUPER AS CODVEN "
	_cQry += "	FROM ( "
	_cQry += "		SELECT E3.CODVEND, SA3.A3_NOME, SA3.A3_SUPER, A3_GEREN "
	_cQry += "		FROM ( "
	_cQry += "				SELECT E3.E3_VEND CODVEND "
	_cQry += "				FROM  "+ RetSqlName('SE3') +" E3 "
	_cQry += "				WHERE "
	_cQry += "					E3.D_E_L_E_T_ = ' ' "
	_cQry += "					AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+_cPeriodo+"'  "
	_cQry += "				GROUP BY E3.E3_VEND "
					
	_cQry += "				UNION ALL  "
					
	_cQry += "				SELECT E3.E3_VEND "
	_cQry += "				FROM ( "
	_cQry += "						SELECT SF2.F2_VEND1        AS E3_VEND   		 "
	_cQry += "						FROM  "+ RetSqlName('SF2') +" SF2  "
	_cQry += "						     JOIN  "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL  "
	_cQry += "						     JOIN  "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD AND SB1.B1_FILIAL = '  ' "
	_cQry += "						     JOIN  "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO  "
	_cQry += "						     JOIN  "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF  "
	_cQry += "						WHERE SF2.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND SD2.D_E_L_E_T_ = ' ' " 
	_cQry += "						     AND SB1.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND SF4.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND ZAY.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND SB1.B1_TIPO    = 'PA'  "
	_cQry += "						     AND ZAY.ZAY_TPOPER	= 'B' "
	_cQry += "						     AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+_cPeriodo+"' "
	_cQry += "						GROUP BY SF2.F2_VEND1 "
	_cQry += "				) E3 "
	_cQry += "		) E3 "
	_cQry += "		LEFT JOIN  "+ RetSqlName('SA3') +" SA3 ON E3.CODVEND = SA3.A3_COD  "
	_cQry += "		GROUP BY E3.CODVEND, SA3.A3_NOME,A3_SUPER, A3_GEREN "
	_cQry += "	) E3 "
		
	_cQry += "	UNION ALL "
		
	_cQry += "	SELECT A3_GEREN AS CODVEN "
	_cQry += "	FROM ( "
	_cQry += "		SELECT E3.CODVEND, SA3.A3_NOME, SA3.A3_SUPER, A3_GEREN "
	_cQry += "		FROM ( "
	_cQry += "				SELECT E3.E3_VEND CODVEND "
	_cQry += "				FROM  "+ RetSqlName('SE3') +" E3 "
	_cQry += "				WHERE "
	_cQry += "					E3.D_E_L_E_T_ = ' ' "
	_cQry += "					AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+_cPeriodo+"'  "
	_cQry += "				GROUP BY E3.E3_VEND "
					
	_cQry += "				UNION ALL  "
					
	_cQry += "				SELECT E3.E3_VEND "
	_cQry += "				FROM ( "
	_cQry += "						SELECT SF2.F2_VEND1        AS E3_VEND   		 "
	_cQry += "						FROM  "+ RetSqlName('SF2') +" SF2  "
	_cQry += "						     JOIN  "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL  "
	_cQry += "						     JOIN  "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD 	AND SB1.B1_FILIAL 	= '  ' "
	_cQry += "						     JOIN  "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO  "
	_cQry += "						     JOIN  "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF  "
	_cQry += "						WHERE SF2.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND SD2.D_E_L_E_T_ = ' ' " 
	_cQry += "						     AND SB1.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND SF4.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND ZAY.D_E_L_E_T_ = ' '  "
	_cQry += "						     AND SB1.B1_TIPO    = 'PA'  "
	_cQry += "						     AND ZAY.ZAY_TPOPER	= 'B' "
	_cQry += "						     AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+_cPeriodo+"' "
	_cQry += "						GROUP BY SF2.F2_VEND1 "
	_cQry += "				) E3 "
	_cQry += "		) E3 "
	_cQry += "		LEFT JOIN  "+ RetSqlName('SA3') +" SA3 ON E3.CODVEND = SA3.A3_COD  "
	_cQry += "		GROUP BY E3.CODVEND, SA3.A3_NOME,A3_SUPER, A3_GEREN "
	_cQry += "	) E3 "
	_cQry += ") TEMP "
	_cQry += "WHERE CODVEND <> '      ' "
	_cQry += "GROUP BY CODVEND "
	_cQry += "ORDER BY CODVEND "

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBSA3" , .T. , .F. )

	TRBSA3->(DBGoTop())
	Count to _nTotRegs

   SA3->(DBSetOrder(1)) 	  
   
   _lLeuTdSA3 := .F.
   _nI := 0
   TRBSA3->(DBGoTop())
   While ! TRBSA3->(Eof())
      _nI++
      SA3->(DBSetOrder(1))
      //SA3->(DBGoTo(TRBSA3->NRRECNO))
      SA3->(DBSeek(xFilial("SA3")+TRBSA3->CODVEND))

      If _lScheduller 
		 FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06404"/*cMsgId*/, "MOMS06404 - Processando Vendedor: "+ SA3->A3_COD +"-"+ SA3->A3_NOME/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Else
         oProc:cCaption := ("Proc. Vend.: "+ SA3->A3_COD +"-"+ Subs(SA3->A3_NOME,1,30) + Space(3)+ AllTrim(Str(_nI))+" de "+AllTrim(Str(_nTotRegs)))
         ProcessMessages()
      EndIf 

      _cVendedor := SA3->A3_COD
      _cNomeVend := SA3->A3_NOME 

      If SA3->A3_TIPO == "I" // I=Interno;E=Externo;P=Parceiro
         _cTipoVend := "CLT"  
      ElseIf SA3->A3_TIPO == "E"
         _cTipoVend := "PESSOA JURIDICA"
      Else 
         _cTipoVend := ""
      EndIf  

      U_MOMS064G(oProc)

      TRBSA3->(DBSkip())
   EndDo

   If ! Empty(_aDados)  
      If !_lScheduller
         oProc:cCaption += ("Gravando dados na tabela... ")
         ProcessMessages()
      EndIf 

      U_MOMS064T(oProc,_aDados)

      _aDados := {} 

   EndIf 

   _lLeuTdSA3 := .T. // Indica que a rotina não foi interrompida. Conseguiu ler todo o cadastro SA3.

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: MOMS064G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 26/04/2022
Descrição---------: Gera os dados de comissão para o vendedor posicionado na tabela SA3.
Parametros--------: _lScheduller = .T. = Indica que a rotina foi chamada via Scheduller.
                                   .F. = Indica que a rotina foi chamada via menu.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS064G(oProc)
Local _nI, _nJ, _nX 

Default oProc := Nil

Private _aLinha    := {}
Private _dDtEmiss  := Ctod("  /  /  ") // ZBK_EMISSA	D	8	0	Dt.Emissao
Private _dDtBaixa  := Ctod("  /  /  ") // ZBK_BAIXA	D	8	0	Dt.Baixa
Private _cDocto    := Space(9)         // ZBK_DOCTO	C	9	0	Nr.Documento
Private _cSerie    := Space(3)         // ZBK_SERIE	C	3	0	Serie Docto.
Private _cCodPro   := Space(15)        // ZBK_CODPRO	C	15	0	Codigo Prod.
Private _cDescPro  := Space(100)       // ZBK_DSCPRD	C	100	0	Desc.Produto
Private _cGrupoPro := Space(4)         // ZBK_GRPPRD	C	4	0	Grupo Produt
Private _cMisBI    := Space(2)         // ZBK_BIMIX	C	2	0	Mix BI
Private _nBaseCom  := 0                // ZBK_BASECM	N	17	2	Base Comiss
Private _nPerConV  := 0                // ZBK_PERCVD	N	7	3	% Comissao V
Private _nComisVe  := 0                // ZBK_COMVEN	N	14	2	Comissao Ven
Private _cNomeSup  := Space(40)        // ZBK_NOMSUP	C	40	0	Nome Superv
Private _nPerSuper := 0                // ZBK_PERSUP	N	7	3	% Com.Super
Private _nComSuper := 0                // ZBK_COMSUP	N	14	2	Comissao Sup
Private _nNomCoord := Space(40)        // ZBK_NOMCOO	C	40	0	Nome Coord
Private _nPerCoord := 0                // ZBK_PERCOO	N	7	3	% Com.Coord
Private _nComCoord := 0                // ZBK_COMCOO	N	14	2	Comissao Coo
Private _cNomeGer  := Space(40)        // ZBK_NOMGER	C	40	0	Nome Gerente
Private _nPerGer   := 0                // ZBK_PERGER	N	7	3	% Com.Gerent
Private _nComGer   := 0                // ZBK_COMGER	N	14	2	Comissao Ger
Private _cNomGNac  := Space(40)        // ZBK_NOMGNC	C	40	0	Nome Ger.Nac
Private _nPerGNac  := 0                // ZBK_PERGNC	N	7	3	%Com.Ger.Nac
Private _nComGNac  := 0                // ZBK_COMGNC	N	14	2	Comis.Ger.Na
Private _cAlias  := GetNextAlias()
Private _cAlias2 := GetNextAlias()

Begin Sequence 

   If Select(_cAlias) > 0
      (_cAlias)->(DBCloseArea())    
   EndIf 

   If Select(_cAlias2) > 0
      (_cAlias2)->(DBCloseArea())    
   EndIf 

   U_MOMS064QRY( _cAlias , 1 )  // "Filtrando dados das comissões... "
   
   _nTotReg := 0 		
   DBSelectArea(_cAlias)
   (_cAlias)->( DBGoTop() )
   (_cAlias)->( DBEval( {|| _nTotReg++ } ) )
   (_cAlias)->( DBGoTop() )

   SF2->(DBSetOrder(1))

   _nJ := 1
   While ! (_cAlias)->(Eof())
      
      If _lScheduller   
		 FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06405"/*cMsgId*/, "MOMS06405 - Processando dos dados comissão: " + StrZero(_nJ,6)+ " / " + StrZero(_nTotReg,6)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      EndIf 

      _nJ += 1

      //================================================
      // Inicializa Variáveis
      //================================================
      _dDtEmiss  := Ctod("  /  /  ") // ZBK_EMISSA	D	8	0	Dt.Emissao
      _dDtBaixa  := Ctod("  /  /  ") // ZBK_BAIXA	D	8	0	Dt.Baixa
      _cDocto    := Space(9)         // ZBK_DOCTO	C	9	0	Nr.Documento
      _cSerie    := Space(3)         // ZBK_SERIE	C	3	0	Serie Docto.
      _cCodPro   := Space(15)        // ZBK_CODPRO	C	15	0	Codigo Prod.
      _cDescPro  := Space(100)       // ZBK_DSCPRD	C	100	0	Desc.Produto
      _cGrupoPro := Space(4)         // ZBK_GRPPRD	C	4	0	Grupo Produt
      _cMisBI    := Space(2)         // ZBK_BIMIX	C	2	0	Mix BI
      _nBaseCom  := 0                // ZBK_BASECM	N	17	2	Base Comiss
      _nPerConV  := 0                // ZBK_PERCVD	N	7	3	% Comissao V
      _nComisVe  := 0                // ZBK_COMVEN	N	14	2	Comissao Ven
      _cSupervis := Space(6)         // ZBK_SUPERV	C	6	0	Supervisor
      _cNomeSup  := Space(40)        // ZBK_NOMSUP	C	40	0	Nome Superv
      _nPerSuper := 0                // ZBK_PERSUP	N	7	3	% Com.Super
      _nComSuper := 0                // ZBK_COMSUP	N	14	2	Comissao Sup
      _cCoordena := Space(6)         // ZBK_COORDE	C	6	0	Coordenador
      _nNomCoord := Space(40)        // ZBK_NOMCOO	C	40	0	Nome Coord
      _nPerCoord := 0                // ZBK_PERCOO	N	7	3	% Com.Coord
      _nComCoord := 0                // ZBK_COMCOO	N	14	2	Comissao Coo
      _cGerente  := Space(6)         // ZBK_GERENT	C	6	0	Gerente
      _cNomeGer  := Space(40)        // ZBK_NOMGER	C	40	0	Nome Gerente
      _nPerGer   := 0                // ZBK_PERGER	N	7	3	% Com.Gerent
      _nComGer   := 0                // ZBK_COMGER	N	14	2	Comissao Ger
      _cGerenNac := Space(6)         // ZBK_GERNAC	C	6	0	Gerente Nac
      _cNomGNac  := Space(40)        // ZBK_NOMGNC	C	40	0	Nome Ger.Nac
      _nPerGNac  := 0                // ZBK_PERGNC	N	7	3	%Com.Ger.Nac
      _nComGNac  := 0                // ZBK_COMGNC	N	14	2	Comis.Ger.Na

      //================================================
      // Busca dados adicionais
      //================================================
      SA3->(DBSetOrder(1))
      If SF2->(DBSeek((_cAlias)->FILIAL+(_cAlias)->NUMERO)) .And. AllTrim((_cAlias)->CODCLI) == AllTrim(SF2->F2_CLIENTE) 
         _cSupervis  := SF2->F2_VEND4
         _cNomeSup   := IIf(SA3->(DBSeek(xFilial("SA3")+_cSupervis)),SA3->A3_NOME," ")
         _cCoordena  := SF2->F2_VEND2
         _nNomCoord  := IIf(SA3->(DBSeek(xFilial("SA3")+_cCoordena)),SA3->A3_NOME," ")
         _cGerente   := SF2->F2_VEND3
         _cNomeGer   := IIf(SA3->(DBSeek(xFilial("SA3")+_cGerente)),SA3->A3_NOME," ")

         _cGerenNac  := SF2->F2_VEND5
         _cNomGNac   := IIf(SA3->(DBSeek(xFilial("SA3")+_cGerenNac)),SA3->A3_NOME," ")
         _lachou     := .T.
      Else
         _cSupervis  := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_SUPE")
         _cNomeSup   := IIf(SA3->(DBSeek(xFilial("SA3")+_cSupervis)),SA3->A3_NOME," ")
         _cCoordena  := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_SUPER")
         _nNomCoord  := IIf(SA3->(DBSeek(xFilial("SA3")+_cCoordena)),SA3->A3_NOME," ")
         _cGerente   := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_GEREN")
         _cNomeGer   := IIf(SA3->(DBSeek(xFilial("SA3")+_cGerente)),SA3->A3_NOME," ")

         _cGerenNac  := Posicione("SA3",1,xFilial("SA3")+(_cAlias)->CODVEND,"A3_I_GERNC")
         _cNomGNac   := IIf(SA3->(DBSeek(xFilial("SA3")+_cGerenNac)),SA3->A3_NOME," ")
      EndIf

      _nComisVe   := 0 // Comissao Ven
      _nComSuper  := 0 // Comissao Sup
      _nComCoord  := 0 // Comissao Coo
      _nComGer    := 0 // Comissao Ger
      _nComGNac   := 0 // Comis.Ger.Na

      SE3->(DBSetOrder(1))
      If SE3->(DBSeek((_cAlias)->FILIAL+(_cAlias)->PREFIXO+(_cAlias)->E3NUMORI+(_cAlias)->PARCELA+(_cAlias)->SEQ))
         While SE3->E3_FILIAL == (_cAlias)->FILIAL .And. ;
      	   SE3->E3_PREFIXO == (_cAlias)->PREFIXO .And. ;
      	   SE3->E3_NUM == (_cAlias)->E3NUMORI .And. ;
      	   SE3->E3_PARCELA == (_cAlias)->PARCELA .And. ;
      	   SE3->E3_SEQ == (_cAlias)->SEQ .And. SE3->(!Eof())
                  
            If SE3->E3_VEND == _cVendedor //Representante
              _nComisVe := Round(_nComisVe + SE3->E3_COMIS ,3)
            EndIf

            If SE3->E3_VEND == _cSupervis  //Supervisor
              _nComSuper := Round(_nComSuper + SE3->E3_COMIS ,3)
            EndIf
               
            If SE3->E3_VEND == _cCoordena  //Coordenador
              _nComCoord := Round(_nComCoord + SE3->E3_COMIS ,3)
            EndIf

            If SE3->E3_VEND == _cGerente  //Gerente
              _nComGer := Round( _nComGer + SE3->E3_COMIS ,3)
            EndIf 

            If SE3->E3_VEND == _cGerenNac  //Gerente Nacional
              _nComGNac := Round(_nComGNac + SE3->E3_COMIS ,3)
            EndIf

            If _lScheduller
			   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06406"/*cMsgId*/, "MOMS06406 - Processando Percentuais do Titulo: " + SE3->E3_FILIAL + " | "+ SE3->E3_PREFIXO + " | " + SE3->E3_NUM + " | " + SE3->E3_PARCELA + " | "+ SE3->E3_SEQ/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
            EndIf 
 
            SE3->(DBSkip())
         EndDo
      EndIf

      _nPerConV := Round(_nComisVe/(_cAlias)->BASECOMIS*100,3)
      _nPerConV := IIf(_nPerConV < 0,-1*_nPerConV,_nPerConV)
      	
      _nBaseCom := IIf((_cAlias)->COMISSAO < 0 ,-1*(_cAlias)->BASECOMIS,(_cAlias)->BASECOMIS)
      		
      _nPerSuper := Round(_nComSuper/(_cAlias)->BASECOMIS*100,3)
      _nPerSuper := IIf(_nPerSuper < 0,-1*_nPerSuper,_nPerSuper)
      		
      _nPerCoord := Round(_nComCoord/(_cAlias)->BASECOMIS*100,3)
      _nPerCoord := IIf(_nPerCoord < 0,-1* _nPerCoord,_nPerCoord)
      		
      _nPerGer := Round(_nComGer/(_cAlias)->BASECOMIS*100,3)
      _nPerGer := IIf(_nPerGer < 0 ,-1 * _nPerGer, _nPerGer)   

      _nPerGNac := Round(_nComGNac/(_cAlias)->BASECOMIS*100,3)
      _nPerGNac := IIf(_nPerGNac<0,-1*_nPerGNac,_nPerGNac)   

      _dDtEmiss := IIf(!Empty((_cAlias)->DTEMISSAO),SToD((_cAlias)->DTEMISSAO),Ctod("  /  /  "))
      _dDtBaixa := IIf(!Empty((_cAlias)->DTBAIXA),SToD((_cAlias)->DTBAIXA),Ctod("  /  /  "))
      	

      _npl :=  aScan(_aDados,{|_vAux| _vAux[1] == (_cAlias)->FILIAL .And. ;      // 1
      							 _vAux[2] == (_cAlias)->TIPO .And. ;        // 2
      							 _vAux[3] == _dDtEmiss .And. ;              // 3
      							 _vAux[4] == _dDtBaixa .And. ;              // 4 
      							 _vAux[5] == (_cAlias)->NUMERO .And. ;      // 5
      							 _vAux[6] == (_cAlias)->PARCELA .And. ;     // 6 
      							 _vAux[7] == (_cAlias)->CODCLI .And. ;      // 7
      							 _vAux[8] == (_cAlias)->LOJA .And. ;        // 8 
      							 _vAux[9] == (_cAlias)->SEQ})               // 9

      If _npl == 0 //Só incrementa se não tiver no array
         //===============================================
         // Incrementa array para geração de excel
         //===============================================		  	
         _aLinha := {(_cAlias)->FILIAL,; 	             			 //01
   	     		(_cAlias)->TIPO,;										    //02
   		 		_dDtEmiss,;											       //03
   		 		_dDtBaixa,;											       //04
   		 		(_cAlias)->NUMERO,;									    //05
   				(_cAlias)->PARCELA,;									    //06
   				(_cAlias)->CODCLI,;								    	 //07
   				(_cAlias)->LOJA,;										    //08
               (_cAlias)->SEQ,;                                 //09
   				(_cAlias)->VLRTITULO,;                           //10
   				(_cAlias)->COMPENSACAO,;                         //11
   				(_cAlias)->DESCONTO,;	                         //12
   				(_cAlias)->BAIXASANT,;                           //13
   				_nBaseCom,;	 // ZBK_BASECM	N	17	2	Base Comiss  //14
               _cVendedor,; // ZBK_VEND	C	6	0	Vendedor     //15 
               _cNomeVend,; // ZBK_NOMVEN	C	40	0	Nome Vend.   //16
               _cTipoVend,; // ZBK_TIPVEN	C	15	0	Tipo Vended  //17
               _nPerConV,;  // ZBK_PERCVD	N	7	3	% Comissao V //18
               _nComisVe,;  // ZBK_COMVEN	N	14	2	Comissao Ven //19
               _cSupervis,; // ZBK_SUPERV	C	6	0	Supervisor   //20
               _cNomeSup,;  // ZBK_NOMSUP	C	40	0	Nome Superv  //21
               _nPerSuper,; // ZBK_PERSUP	N	7	3	% Com.Super  //22
               _nComSuper,; // ZBK_COMSUP	N	14	2	Comissao Sup //23
               _cCoordena,; // ZBK_COORDE	C	6	0	Coordenador  //24¸
               _nNomCoord,; // ZBK_NOMCOO	C	40	0	Nome Coord   //25
               _nPerCoord,; // ZBK_PERCOO	N	7	3	% Com.Coord  //26
               _nComCoord,; // ZBK_COMCOO	N	14	2	Comissao Coo //27
               _cGerente,;  // ZBK_GERENT	C	6	0	Gerente      //28
               _cNomeGer,;  // ZBK_NOMGER	C	40	0	Nome Gerente //29
               _nPerGer,;   // ZBK_PERGER	N	7	3	% Com.Gerent //30
               _nComGer,;   // ZBK_COMGER	N	14	2	Comissao Ger //31
               _cGerenNac,; // ZBK_GERNAC	C	6	0	Gerente Nac  //32
               _cNomGNac,;  // ZBK_NOMGNC	C	40	0	Nome Ger.Nac //33
               _nPerGNac,;  // ZBK_PERGNC	N	7	3	%Com.Ger.Nac //34
               _nComGNac}   // ZBK_COMGNC	N	14	2	Comis.Ger.Na //35

   	 //_aRegDados := MOMS064D(_aLinha, (_cAlias)->FILIAL, (_cAlias)->NUMERO, (_cAlias)->SERIE, (_cAlias)->CODCLI, (_cAlias)->LOJA,(_cAlias)->TIPO)
         _aRegDados := U_MOMS064D(_aLinha, (_cAlias)->FILIAL, (_cAlias)->NUMERO, (_cAlias)->SERIE, (_cAlias)->CODCLI, (_cAlias)->LOJA,(_cAlias)->TIPO)
            
         For _nI := 1 To Len(_aRegDados)
            aAdd(_aDados, AClone(_aRegDados[_nI]))
         Next

   	   _aLinha :=  {}	

      EndIf 

      (_cAlias)->(DBSkip())
   EndDo 

   //===============================================
   // Obtem os dados das bonificações.
   //===============================================	

   U_MOMS064QRY( _cAlias2 , 2 )

   _nTotReg := 0 		
   DBSelectArea(_cAlias2)
   (_cAlias2)->( DBGoTop() )
   (_cAlias2)->( DBEval( {|| _nTotReg++ } ) )
   (_cAlias2)->( DBGoTop() )
             
   If _nTotReg > 0

      //ProcRegua(0) //ProcRegua(_nTotReg)

      _nX := 1

      While (_cAlias2)->( !Eof() )

         If _lScheduller
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06407"/*cMsgId*/, "MOMS06407 - Processando bonificações: "+ StrZero(_nX, 6) + "/" + StrZero(_nTotReg, 6)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         EndIf 

         _nX += 1

         _cRazaoCli := Posicione("SA1",1,xFilial("SA1")+(_CALIAS2)->F2_CLIENTE+(_CALIAS2)->F2_LOJA,"A1_NOME")
         _cSupervis :=  (_CALIAS2)->F2_VEND4
         _cNomeSup  := IIf(SA3->(DBSeek(xFilial("SA3")+_cSupervis)),SA3->A3_NOME," ")
         _cCoordena := (_CALIAS2)->F2_VEND2
         _nNomCoord := IIf(SA3->(DBSeek(xFilial("SA3")+_cCoordena)),SA3->A3_NOME," ")
         _cGerente  := (_CALIAS2)->F2_VEND3
         _cNomeGer  := IIf(SA3->(DBSeek(xFilial("SA3")+_cGerente)),SA3->A3_NOME," ")

         _cGerenNac := (_CALIAS2)->F2_VEND5
         _cNomGNac  := IIf(SA3->(DBSeek(xFilial("SA3")+_cGerenNac)),SA3->A3_NOME," ")
            
         If aScan(_aDados, {|_vAux| _vAux[1]==(_cAlias2)->F2_FILIAL .And. _vAux[2]=="BON" .And. _vAux[5]==(_cAlias2)->F2_DOC}) ==  0
            _aLinha :=  {(_CALIAS2)->F2_FILIAL	,;					                                              // 01
         			 "BON",;							         					                          // 02
         			 SToD((_CALIAS2)->F2_EMISSAO),;					                                          // 03
         			 Ctod("  /  /  "),;													                      // 04
         			 (_CALIAS2)->F2_DOC,;									                                  // 05
         				   "  ",;													                          // 06
         			 (_CALIAS2)->F2_CLIENTE,;								                                  // 07
         			 (_CALIAS2)->F2_LOJA,;									                                  // 08
         			 "  ",;                                                                                   // 09  // Sequencia
         			 (_CALIAS2)->VALTOT,;									                                  // 10  // Valor titulo.
         			 0,;													                                  // 11  // Compenssação
         			 0,;                                								                      // 12  // Desconto
         			 0,;													                                  // 13  // Baixa Ant.
         			 (_CALIAS2)->VALTOT*-1,;							                                      // 14  // Base Comissão
         			 _cVendedor,;												                              // 15
         			 _cNomeVend,;                                         	                                  // 16
         			 _cTipoVend,;                                                                             // 17  // ZBK_TIPVEN	C	15	0	Tipo Vended 
         			 Round((_CALIAS2)->COMIS1/-100,3),;	                                    				  // 18 
         			 Round((_CALIAS2)->COMIS1/(_CALIAS2)->VALTOT,3),;	                                      // 19 
         			 _cSupervis,;												                              // 20
         			 _cNomeSup,;												                              // 21
         			 Round((_CALIAS2)->COMIS4/-100,3),;					                                      // 22 "Vlr Com Sup"
         			 Round((_CALIAS2)->COMIS4/(_CALIAS2)->VALTOT,3),;	                                      // 23 "% Com Sup"	
         				 _cCoordena,;											                                  // 24
         			 _nNomCoord,;											                                  // 25
         			 Round((_CALIAS2)->COMIS2/-100,3),;					                                      // 26 "Vlr Com Cood"
         			 Round((_CALIAS2)->COMIS2/(_CALIAS2)->VALTOT,3),;	                                      // 27 "% Com Cood"
         			 _cGerente,;												                              // 28
         			 _cNomeGer,;												                              // 29
         			 Round((_CALIAS2)->COMIS3/-100,3),;					                                      // 30 "Vlr Com Ger"
         			 Round((_CALIAS2)->COMIS3/(_CALIAS2)->VALTOT,3),;	                                      // 31 "% Com Ger"	
                         _cGerenNac,;                                                                             // 32
                         _cNomGNac,;                                                                              // 33 
         			 Round((_CALIAS2)->COMIS5/-100,3),;					                                      // 34 "Vlr Com Ger Nac"
         			 Round((_CALIAS2)->COMIS5/(_CALIAS2)->VALTOT,3)}	                                   	  // 35 "% Com Ger Nac"	

            _aRegDados := U_MOMS064D(_aLinha, (_CALIAS2)->F2_FILIAL, (_CALIAS2)->F2_DOC, (_CALIAS2)->F2_SERIE, (_CALIAS2)->F2_CLIENTE, (_CALIAS2)->F2_LOJA,"BON")
            
            For _nI := 1 To Len(_aRegDados)
               aAdd(_aDados, AClone(_aRegDados[_nI]))
            Next

            _aLinha :=  {}	
            
         EndIf

         (_cAlias2)->( DBSkip() )

      EndDo
      
  EndIf 

End Sequence 

If Select(_cAlias) > 0
   (_cAlias)->(DBCloseArea())    
EndIf 

If Select(_cAlias2) > 0
   (_cAlias2)->(DBCloseArea())    
EndIf 

Return 

/*
===============================================================================================================================
Programa--------: MOMS064QRY
Autor-----------: Julio de Paula Paz
Data da Criacao-: 26/04/2022
Descrição-------: Funcao de monta e realiza as consultas de dados do relatório
Parametros------: _cAlias - Alias que será instanciado pela consulta
----------------: _nOpcao - Opção de consulta que será processada
Retorno---------: Nenhum
===============================================================================================================================
*/                                    
User Function MOMS064QRY( _cAlias , _nOpcao )

Local _cFiltro		:= "%"
Local _cFiltEmis	:= "%"
Local _cFilVeCoo	:= "%"
Local _cFilCooVe	:= "%"
Local _cFilTRONC	:= "" //"%" 
Local _cfiltrobon   := ""

//====================================================================================================
// Filtra geracao da comissao
//====================================================================================================
If !Empty( _cPeriodo )
   _cFiltro	   += " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ _cPeriodo +"'"
   _cFiltEmis	+= " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ _cPeriodo +"'"
   _cFilCooVe	+= " AND SubStr( E3_EMISSAO , 1 , 6 ) = '"+ _cPeriodo +"'"
   _cFiltrobon	+= " AND SubStr( F2_EMISSAO , 1 , 6 ) = '"+ _cPeriodo +"'"
EndIf

//====================================================================================================
// Vendedor
//====================================================================================================
If !Empty(_cVendedor )
    
	_cFiltro    += " AND F2.F2_VEND1 = '"+ _cVendedor +"' "
	_cFilVeCoo  += " AND F2.F2_VEND1 = '"+ _cVendedor +"' "
	_cFilCooVe  += " AND A3.A3_COD   = '"+ _cVendedor +"' "
	_cFiltronc	+= " OR E3.E3_VEND   = '"+ _cVendedor +"' "
	_cFiltroBON += " AND F2_VEND1    = '"+ _cVendedor +"' "
   // _cFilSemBaixa += " AND F2_VEND1  = '"+ _cVendedor +"' "

EndIf

_cFiltro	+= "%"
_cFiltEmis	+= "%"
_cFilVeCoo	+= "%"
_cFilCooVe	+= "%"

If !Empty(_cFiltronc) .And. AllTrim(_cFiltronc) <> "%"
   _cFiltronc := "% AND (" + SubStr(_cFiltronc,4,Len(_cFiltronc)) + ") %" 
ElseIf Empty(_cFiltronc) .Or.  AllTrim(_cFiltronc) == "%"
   _cFiltronc := "% %" 
EndIf

//_cFilTRONC	+= "%" 

Do Case
   //====================================================================================================
   // Seleciona dados para o relatorio do tipo analitico, para as comissoes de credito e debito
   //====================================================================================================
	
   Case _nOpcao == 1   // Query Principal das comissões.
	       
		BeginSql alias _cAlias
		
		SELECT
			E3.E3_FILIAL	AS FILIAL,
			E1.E1_EMISSAO	AS DTEMISSAO,
			E3.E3_EMISSAO	AS DTBAIXA,
			E3.E3_TIPO		AS TIPO,
			E3.E3_NUM		AS NUMERO,
			E3.E3_SERIE		AS SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	AS PARCELA,
			E3.E3_CODCLI	AS CODCLI,
			E3.E3_LOJA		AS LOJA,
			E1.E1_NOMCLI	AS NOMCLI,
			E1.E1_VALOR		AS VLRTITULO,
			E3.E3_BASE		AS BASECOMIS,
			E3.E3_COMIS		AS COMISSAO,
			E3.E3_VEND		AS CODVEND,
			A3.A3_NOME		AS NOMEVEND,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX     = 'CMP'
				AND E5.E5_RECPAG    = 'R' ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
												FROM %Table:SE5% E5
												WHERE
													E1.E1_FILIAL    = E5.E5_FILIAL
												AND E1.E1_PREFIXO   = E5.E5_PREFIXO
												AND E1.E1_TIPO      = E5.E5_TIPO
												AND E1.E1_NUM       = E5.E5_NUMERO
												AND E1.E1_PARCELA   = E5.E5_PARCELA
												AND E1.E1_CLIENTE   = E5.E5_CLIENTE
												AND E1.E1_LOJA      = E5.E5_LOJA
												AND E5.D_E_L_E_T_   = ' '
												AND E5.E5_TIPO     IN ('NF ','ICM')
												AND E5.E5_TIPODOC   = 'ES'
												AND E5.E5_SITUACA  <> 'C'
												AND E5.E5_MOTBX     = 'CMP'
												AND E5.E5_RECPAG    = 'P' ) COMPENSACAO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' ' 
				AND E5.E5_SITUACA  <> 'C'
				AND ( (		E5.E5_TIPO     = 'NF '
						AND E5.E5_TIPODOC <> 'ES'
						AND E5.E5_MOTBX   IN ('DCT','VBC')
						AND E5.E5_NATUREZ IN ('231002','231017','231019','231013','231014','231015','231016','233004','111001')
						AND E5.E5_RECPAG   = 'R')
					OR (	E5_TIPODOC     = 'DC' ) ) ) DESCONTO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '   
				AND E5.E5_TIPODOC  <> 'ES'   
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX    IN ('NOR','DAC','FAT','LQ ')
				AND E5.E5_RECPAG    = 'R'
				AND E5.E5_DATA      < E3.E3_EMISSAO ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
															FROM %Table:SE5% E5
															WHERE
																E1.E1_FILIAL        = E5.E5_FILIAL
															AND E1.E1_PREFIXO   = E5.E5_PREFIXO
															AND E1.E1_TIPO      = E5.E5_TIPO
															AND E1.E1_NUM       = E5.E5_NUMERO
															AND E1.E1_PARCELA   = E5.E5_PARCELA
															AND E1.E1_CLIENTE   = E5.E5_CLIENTE
															AND E1.E1_LOJA      = E5.E5_LOJA
															AND E5.D_E_L_E_T_   = ' '
															AND E5.E5_TIPO      = 'NF '
															AND E5.E5_TIPODOC   = 'ES'
															AND E5.E5_SITUACA  <> 'C'
															AND E5.E5_MOTBX    IN ( 'NOR' , 'DAC' , 'FAT' , 'LQ ' )
															AND E5.E5_RECPAG    = 'P' ) BAIXASANT,
      		'C' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI
		FROM %Table:SE3% E3
		
		JOIN %Table:SE1% E1 
   		ON
   			E1.E1_FILIAL  = E3.E3_FILIAL
   		AND E1.E1_TIPO    = E3.E3_TIPO
   		AND E1.E1_PREFIXO = E3.E3_PREFIXO
   		AND E1.E1_NUM     = E3.E3_NUM  
   		AND E1.E1_SERIE   = E3.E3_SERIE
   		AND E1.E1_PARCELA = E3.E3_PARCELA
   		AND E1.E1_CLIENTE = E3.E3_CODCLI
   		AND E1.E1_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SF2% F2
   		ON
   			F2.F2_FILIAL  = E3.E3_FILIAL
   		AND F2.F2_DOC     = E3.E3_NUM
   		AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
   		AND F2.F2_CLIENTE = E3.E3_CODCLI
   		AND F2.F2_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SA3% A3 ON A3.A3_COD = E3.E3_VEND
		
		WHERE
			E3.D_E_L_E_T_ = ' '
   		AND E1.D_E_L_E_T_ = ' '
   		AND F2.D_E_L_E_T_ = ' '
   		AND A3.D_E_L_E_T_ = ' '
   		AND E3.E3_COMIS   > 0
   		AND E1.E1_ORIGEM NOT IN ( 'FINA460' , 'FINA280' )
   		
		%exp:_cFiltro%
		
	UNION ALL
		
		SELECT
			E3.E3_FILIAL FILIAL,
			E1.E1_EMISSAO DTEMISSAO,
			E3.E3_EMISSAO DTBAIXA,
			E3.E3_TIPO TIPO,
			E3.E3_NUM NUMERO,
			E3.E3_SERIE		AS SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	AS PARCELA,
			E3.E3_CODCLI CODCLI,
			E3.E3_LOJA LOJA,
			E1.E1_NOMCLI NOMCLI,
			E1.E1_VALOR VLRTITULO,
			E3.E3_BASE BASECOMIS,
			E3.E3_COMIS COMISSAO,
			E3.E3_VEND CODVEND,
			A3.A3_NOME NOMEVEND,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX     = 'CMP'
				AND E5.E5_RECPAG    = 'R' ) - (	SELECT COALESCE(SUM(E5.E5_VALOR),0)
												FROM %Table:SE5% E5
												WHERE
													E1.E1_FILIAL    = E5.E5_FILIAL
												AND E1.E1_PREFIXO   = E5.E5_PREFIXO
												AND E1.E1_TIPO      = E5.E5_TIPO
												AND E1.E1_NUM       = E5.E5_NUMERO
												AND E1.E1_PARCELA   = E5.E5_PARCELA
												AND E1.E1_CLIENTE   = E5.E5_CLIENTE
												AND E1.E1_LOJA      = E5.E5_LOJA
												AND E5.D_E_L_E_T_   = ' '
												AND E5.E5_TIPO     IN ('NF ','ICM')
												AND E5.E5_TIPODOC   = 'ES'
												AND E5.E5_SITUACA  <> 'C'
												AND E5.E5_MOTBX     = 'CMP'
												AND E5.E5_RECPAG    = 'P' ) COMPENSACAO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_SITUACA  <> 'C'
				AND ( (		E5.E5_TIPO      = 'NF '
						AND E5.E5_TIPODOC  <> 'ES'
						AND E5.E5_MOTBX    IN ('DCT','VBC')
						AND E5.E5_NATUREZ  IN ('231002','231017','231019','231013','231014','231015','231016','233004','111001')
						AND E5.E5_RECPAG    = 'R' )
					OR ( E5_TIPODOC = 'DC' ) ) ) DESCONTO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX    IN ( 'NOR' , 'DAC' , 'FAT' , 'LQ ' )
				AND E5.E5_RECPAG    = 'R'
				AND E5.E5_DATA      < E3.E3_EMISSAO ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
															FROM %Table:SE5% E5
															WHERE
																E1.E1_FILIAL    = E5.E5_FILIAL
															AND E1.E1_PREFIXO   = E5.E5_PREFIXO
															AND E1.E1_TIPO      = E5.E5_TIPO
															AND E1.E1_NUM       = E5.E5_NUMERO
															AND E1.E1_PARCELA   = E5.E5_PARCELA
															AND E1.E1_CLIENTE   = E5.E5_CLIENTE
															AND E1.E1_LOJA      = E5.E5_LOJA
															AND E5.D_E_L_E_T_   = ' '
															AND E5.E5_TIPO      = 'NF '
															AND E5.E5_TIPODOC   = 'ES'
															AND E5.E5_SITUACA  <> 'C'
															AND E5.E5_MOTBX    IN ( 'NOR' , 'DAC' , 'FAT' , 'LQ ' )
															AND E5.E5_RECPAG    = 'P' ) BAIXASANT,
			'C' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI
		FROM %Table:SE3% E3
		
		JOIN %Table:SE1% E1
        ON
        	E1.E1_FILIAL  = E3.E3_FILIAL
        AND E1.E1_TIPO    = E3.E3_TIPO
        AND E1.E1_PREFIXO = E3.E3_PREFIXO
        AND E1.E1_NUM     = E3.E3_NUM
        AND E1.E1_SERIE   = E3.E3_SERIE
        AND E1.E1_PARCELA = E3.E3_PARCELA
        AND E1.E1_CLIENTE = E3.E3_CODCLI
        AND E1.E1_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SA3% A3 ON A3.A3_COD = E3.E3_VEND
		
		JOIN %Table:SF2% F2
		ON
			F2.F2_FILIAL  = E3.E3_FILIAL
		AND F2.F2_DOC     = E3.E3_NUM
		AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
		AND F2.F2_CLIENTE = E3.E3_CODCLI
		AND F2.F2_LOJA    = E3.E3_LOJA
		
		
		WHERE
			E3.D_E_L_E_T_ = ' '
	    AND E1.D_E_L_E_T_ = ' '
	    AND A3.D_E_L_E_T_ = ' '
	    AND E1.E1_NUM    IN (	SELECT SE1.E1_FATURA
								FROM %Table:SE1% SE1
								JOIN %Table:SF2% F2
								ON
									F2.F2_FILIAL   = SE1.E1_FILIAL
								AND F2.F2_DOC      = SE1.E1_NUM
								AND (F2.F2_SERIE    = SE1.E1_SERIE OR SE1.E1_SERIE = 'R')
								AND F2.F2_CLIENTE  = SE1.E1_CLIENTE
								AND F2.F2_LOJA     = SE1.E1_LOJA
								WHERE
									SE1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_  = ' '
								AND SE1.E1_FATPREF = E1.E1_PREFIXO
								AND SE1.E1_FATURA  = E1.E1_NUM
								AND SE1.E1_FILIAL  = E1.E1_FILIAL
								AND F2.F2_FILIAL   = E1.E1_FILIAL
								AND SE1.E1_FATURA <> ' '
								%exp:_cFilVeCoo% )
		%exp:_cFiltEmis%
		AND E3.E3_COMIS  > 0
		AND E1.E1_ORIGEM = 'FINA280'
		%exp:_cFiltro%
				
	UNION ALL
	    
		SELECT
			E3.E3_FILIAL FILIAL,
			E1.E1_EMISSAO DTEMISSAO,
			E3.E3_EMISSAO DTBAIXA,
			E3.E3_TIPO TIPO,
			E3.E3_NUM NUMERO,
			E3.E3_SERIE		AS SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	AS PARCELA,
			E3.E3_CODCLI CODCLI,
			E3.E3_LOJA LOJA,
			E1.E1_NOMCLI NOMCLI,
			E1.E1_VALOR VLRTITULO,
			E3.E3_BASE BASECOMIS,
			E3.E3_COMIS COMISSAO,
			E3.E3_VEND CODVEND,
			A3.A3_NOME NOMEVEND,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE 
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX     = 'CMP'
				AND E5.E5_RECPAG    = 'R' ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
												FROM %Table:SE5% E5
												WHERE
													E1.E1_FILIAL    = E5.E5_FILIAL   
												AND E1.E1_PREFIXO   = E5.E5_PREFIXO
												AND E1.E1_TIPO      = E5.E5_TIPO
												AND E1.E1_NUM       = E5.E5_NUMERO
												AND E1.E1_PARCELA   = E5.E5_PARCELA
												AND E1.E1_CLIENTE   = E5.E5_CLIENTE
												AND E1.E1_LOJA      = E5.E5_LOJA
												AND E5.D_E_L_E_T_   = ' '
												AND E5.E5_TIPO     IN ('NF ','ICM')   
												AND E5.E5_TIPODOC   = 'ES'   
												AND E5.E5_SITUACA  <> 'C'
												AND E5.E5_MOTBX     = 'CMP'
												AND E5.E5_RECPAG    = 'P' ) COMPENSACAO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL   
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' ' 
				AND E5.E5_SITUACA  <> 'C'
				AND ( (		E5.E5_TIPO     = 'NF '
						AND E5.E5_TIPODOC <> 'ES'
						AND E5.E5_MOTBX   IN ('DCT','VBC')
						AND E5.E5_NATUREZ IN ('231002','231017','231019','231013','231014','231015','231016','233004','111001')
						AND E5.E5_RECPAG   = 'R')
					OR(		E5_TIPODOC     = 'DC' ) ) ) DESCONTO,
			(	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
				FROM %Table:SE5% E5
				WHERE
					E1.E1_FILIAL    = E5.E5_FILIAL
				AND E1.E1_PREFIXO   = E5.E5_PREFIXO
				AND E1.E1_TIPO      = E5.E5_TIPO
				AND E1.E1_NUM       = E5.E5_NUMERO
				AND E1.E1_PARCELA   = E5.E5_PARCELA
				AND E1.E1_CLIENTE   = E5.E5_CLIENTE
				AND E1.E1_LOJA      = E5.E5_LOJA
				AND E5.D_E_L_E_T_   = ' '
				AND E5.E5_TIPO      = 'NF '
				AND E5.E5_TIPODOC  <> 'ES'
				AND E5.E5_SITUACA  <> 'C'
				AND E5.E5_MOTBX    IN ('NOR','DAC','FAT','LQ ')
				AND E5.E5_RECPAG    = 'R'
				AND E5.E5_DATA      < E3.E3_EMISSAO ) - (	SELECT COALESCE( SUM( E5.E5_VALOR ) , 0 )
															FROM %Table:SE5% E5
															WHERE 
																E1.E1_FILIAL    = E5.E5_FILIAL
															AND E1.E1_PREFIXO   = E5.E5_PREFIXO
															AND E1.E1_TIPO      = E5.E5_TIPO
															AND E1.E1_NUM       = E5.E5_NUMERO
															AND E1.E1_PARCELA   = E5.E5_PARCELA
															AND E1.E1_CLIENTE   = E5.E5_CLIENTE
															AND E1.E1_LOJA      = E5.E5_LOJA
															AND E5.D_E_L_E_T_   = ' '
															AND E5.E5_TIPO      = 'NF '
															AND E5.E5_TIPODOC   = 'ES'
															AND E5.E5_SITUACA  <> 'C'
															AND E5.E5_MOTBX    IN ('NOR','DAC','FAT','LQ ')
															AND E5.E5_RECPAG    = 'P' ) BAIXASANT,
			'C' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI
		FROM %Table:SE3% E3
		JOIN %Table:SE1% E1
		ON
			E1.E1_FILIAL  = E3.E3_FILIAL
		AND E1.E1_TIPO    = E3.E3_TIPO
		AND E1.E1_PREFIXO = E3.E3_PREFIXO
		AND E1.E1_NUM     = E3.E3_NUM
		AND E1.E1_SERIE   = E3.E3_SERIE
		AND E1.E1_PARCELA = E3.E3_PARCELA
		AND E1.E1_CLIENTE = E3.E3_CODCLI
		AND E1.E1_LOJA    = E3.E3_LOJA
		
		JOIN %Table:SA3% A3 ON A3.A3_COD = E3.E3_VEND
		
		JOIN %Table:SF2% F2
		ON
			F2.F2_FILIAL  = E3.E3_FILIAL
		AND F2.F2_DOC     = E3.E3_NUM
		AND (F2.F2_SERIE   = E3.E3_PREFIXO OR E3.E3_PREFIXO = 'R')
		AND F2.F2_CLIENTE = E3.E3_CODCLI
		AND F2.F2_LOJA    = E3.E3_LOJA
		
		
		WHERE
			E3.D_E_L_E_T_ = ' '
		AND E1.D_E_L_E_T_ = ' '
		AND A3.D_E_L_E_T_ = ' '
		AND E1.E1_NUMLIQ IN (	SELECT SE5.E5_DOCUMEN
								FROM %Table:SE5% SE5
								JOIN %Table:SF2% F2
								ON
									F2.F2_FILIAL  = SE5.E5_FILIAL
								AND F2.F2_DOC     = SE5.E5_NUMERO
								AND (F2.F2_SERIE   = SE5.E5_PREFIXO OR SE5.E5_PREFIXO = 'R')
								AND F2.F2_CLIENTE = SE5.E5_CLIFOR
								AND F2.F2_LOJA    = SE5.E5_LOJA
								WHERE
									SE5.D_E_L_E_T_  = ' '
								AND F2.D_E_L_E_T_   = ' '
								AND SE5.E5_DOCUMEN  = E1.E1_NUMLIQ
								AND SE5.E5_FILIAL   = E1.E1_FILIAL
								AND F2.F2_FILIAL    = E1.E1_FILIAL
								AND SE5.E5_DOCUMEN <> ' '
								%exp:_cFilVeCoo% )
		AND E3.E3_COMIS > 0
		%exp:_cFiltEmis%
		AND E1.E1_ORIGEM = 'FINA460'
		%exp:_cFiltro%
				
	UNION ALL
		
		SELECT
			E3.E3_FILIAL FILIAL,
			E3.E3_EMISSAO DTEMISSAO,
			E3.E3_EMISSAO DTBAIXA,
			E3.E3_TIPO TIPO,
			(	SELECT F2.F2_DOC FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
								AND E3.E3_FILIAL  = D1.D1_FILIAL 
								AND E3.E3_NUM     = D1.D1_DOC
								AND E3.E3_SERIE   = D1.D1_SERIE
								AND E3.E3_CODCLI  = D1.D1_FORNECE 
								AND E3.E3_LOJA    = D1.D1_LOJA
								AND F2.F2_FILIAL  = D1.D1_FILIAL
								AND F2.F2_DOC     = D1.D1_NFORI
								AND F2.F2_SERIE   = D1.D1_SERIORI
								AND F2.F2_CLIENTE = D1.D1_FORNECE 
								AND F2.F2_LOJA    = D1.D1_LOJA
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) NUMERO,
				(	SELECT F2.F2_SERIE FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
								AND E3.E3_FILIAL  = D1.D1_FILIAL 
								AND E3.E3_NUM     = D1.D1_DOC
								AND E3.E3_SERIE   = D1.D1_SERIE
								AND E3.E3_CODCLI  = D1.D1_FORNECE 
								AND E3.E3_LOJA    = D1.D1_LOJA
								AND F2.F2_FILIAL  = D1.D1_FILIAL
								AND F2.F2_DOC     = D1.D1_NFORI
								AND F2.F2_SERIE   = D1.D1_SERIORI
								AND F2.F2_CLIENTE = D1.D1_FORNECE 
								AND F2.F2_LOJA    = D1.D1_LOJA
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA PARCELA,
			E3.E3_CODCLI CODCLI,
			E3.E3_LOJA LOJA,
			A1.A1_NREDUZ NOMCLI,
			TO_NUMBER(NULL) VLRTITULO,
			E3.E3_BASE BASECOMIS,
			E3.E3_COMIS COMISSAO,
			E3.E3_VEND CODVEND,
			A3.A3_NOME NOMEVEND,
			TO_NUMBER(NULL) COMPENSACAO,
			TO_NUMBER(NULL) DESCONTO,
			TO_NUMBER(NULL) BAIXASANT,
			'D' ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI
		FROM %Table:SE3% E3
		JOIN %Table:SA3% A3 ON E3.E3_VEND = A3.A3_COD
		JOIN %Table:SA1% A1 ON A1.A1_COD = E3.E3_CODCLI AND A1.A1_LOJA = E3.E3_LOJA
		WHERE
			E3.D_E_L_E_T_ = ' '
		AND A3.D_E_L_E_T_ = ' ' 
		%exp:_cFiltronc%  
		AND A1.D_E_L_E_T_ = ' '
		AND E3.E3_TIPO    = 'NCC'
		%exp:_cFiltEmis%
		
		AND E3.E3_NUM    IN (	SELECT D1.D1_DOC FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
								AND E3.E3_FILIAL  = D1.D1_FILIAL 
								AND E3.E3_NUM     = D1.D1_DOC
								AND E3.E3_SERIE   = D1.D1_SERIE
								AND E3.E3_CODCLI  = D1.D1_FORNECE 
								AND E3.E3_LOJA    = D1.D1_LOJA
								AND F2.F2_FILIAL  = D1.D1_FILIAL
								AND F2.F2_DOC     = D1.D1_NFORI
								AND F2.F2_SERIE   = D1.D1_SERIORI
								AND F2.F2_CLIENTE = D1.D1_FORNECE 
								AND F2.F2_LOJA    = D1.D1_LOJA
								%exp:_cFilVeCoo% )
		
	UNION ALL
		
		SELECT
			E3.E3_FILIAL	FILIAL,
			E3.E3_EMISSAO	DTEMISSAO,
			E3.E3_EMISSAO	DTBAIXA,
			E3.E3_TIPO		TIPO,
				(	SELECT F2.F2_DOC FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
								AND E3.E3_FILIAL  = D1.D1_FILIAL 
								AND E3.E3_NUM     = D1.D1_DOC
								AND E3.E3_SERIE   = D1.D1_SERIE
								AND E3.E3_CODCLI  = D1.D1_FORNECE 
								AND E3.E3_LOJA    = D1.D1_LOJA
								AND F2.F2_FILIAL  = D1.D1_FILIAL
								AND F2.F2_DOC     = D1.D1_NFORI
								AND F2.F2_SERIE   = D1.D1_SERIORI
								AND F2.F2_CLIENTE = D1.D1_FORNECE 
								AND F2.F2_LOJA    = D1.D1_LOJA
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) NUMERO,
				(	SELECT F2.F2_SERIE FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
								AND E3.E3_FILIAL  = D1.D1_FILIAL 
								AND E3.E3_NUM     = D1.D1_DOC
								AND E3.E3_SERIE   = D1.D1_SERIE
								AND E3.E3_CODCLI  = D1.D1_FORNECE 
								AND E3.E3_LOJA    = D1.D1_LOJA
								AND F2.F2_FILIAL  = D1.D1_FILIAL
								AND F2.F2_DOC     = D1.D1_NFORI
								AND F2.F2_SERIE   = D1.D1_SERIORI
								AND F2.F2_CLIENTE = D1.D1_FORNECE 
								AND F2.F2_LOJA    = D1.D1_LOJA
								AND ROWNUM = 1
								%exp:_cFilVeCoo% ) SERIE,
			E3.E3_PREFIXO	AS PREFIXO,
			E3.E3_SEQ		AS SEQ,
			E3.E3_PARCELA	PARCELA,
			E3.E3_CODCLI	CODCLI,
			E3.E3_LOJA		LOJA,
			A1.A1_NREDUZ	NOMCLI,
			TO_NUMBER(NULL)	VLRTITULO,
			E3.E3_BASE		BASECOMIS,
			E3.E3_COMIS		COMISSAO,
			E3.E3_VEND		CODVEND,
			A3.A3_NOME		NOMEVEND,
			TO_NUMBER(NULL) COMPENSACAO,
			TO_NUMBER(NULL) DESCONTO,
			TO_NUMBER(NULL) BAIXASANT,
			'D'				ORDENADACAO, E3.E3_NUM E3NUMORI,E3.E3_SERIE E3SERORI
		FROM %Table:SE3% E3
		JOIN %Table:SA3% A3 ON E3.E3_VEND = A3.A3_COD
		JOIN %Table:SA1% A1 ON A1.A1_COD = E3.E3_CODCLI AND A1.A1_LOJA = E3.E3_LOJA
		WHERE
			E3.D_E_L_E_T_  = ' '
		AND A3.D_E_L_E_T_  = ' '
		AND A1.D_E_L_E_T_  = ' '
		AND E3.E3_TIPO     = 'NCC' 
		%exp:_cFiltronc%  
		AND A3.A3_SUPER   <> ' '
		%exp:_cFilCooVe%
		AND E3.E3_NUM NOT IN (	SELECT D1.D1_DOC
								FROM %Table:SD1% D1,%table:SF2% F2
								WHERE
									D1.D_E_L_E_T_ = ' '
								AND F2.D_E_L_E_T_ = ' '
								AND E3.E3_FILIAL  = D1.D1_FILIAL
								AND E3.E3_NUM     = D1.D1_DOC
								AND E3.E3_SERIE   = D1.D1_SERIE
								AND E3.E3_CODCLI  = D1.D1_FORNECE
								AND E3.E3_LOJA    = D1.D1_LOJA
								AND F2.F2_FILIAL  = D1.D1_FILIAL
								AND F2.F2_DOC     = D1.D1_NFORI
								AND F2.F2_SERIE   = D1.D1_SERIORI
								AND F2.F2_CLIENTE = D1.D1_FORNECE
								AND F2.F2_LOJA    = D1.D1_LOJA 
								%exp:_cFilVeCoo% )
		ORDER BY CODVEND, ORDENADACAO, FILIAL, DTBAIXA, NUMERO, PARCELA
		
		EndSql

   Case _nopcao == 2 // Bonificação
	
		_cQuery := " SELECT "
		_cQuery += "    SF2.F2_FILIAL       AS F2_FILIAL   		, "
		_cQuery += "    SF2.F2_DOC          AS F2_DOC 		  	, "
		_cQuery += "    SF2.F2_SERIE        AS F2_SERIE   		, "
		_cQuery += "    SF2.F2_EMISSAO      AS F2_EMISSAO  		, "
		_cQuery += "    SF2.F2_CLIENTE      AS F2_CLIENTE   	, "
		_cQuery += "    SF2.F2_LOJA         AS F2_LOJA   		, "
		_cQuery += "    SF2.F2_VEND1        AS F2_VEND1   		, "
		_cQuery += "    SF2.F2_VEND2        AS F2_VEND2   		, "
		_cQuery += "    SF2.F2_VEND3        AS F2_VEND3   		, "
		_cQuery += "    SF2.F2_VEND4        AS F2_VEND4   		, "
		_cQuery += "    SF2.F2_VEND5        AS F2_VEND5   		, " 
		_cQuery += "    SUM((SD2.D2_VALBRUT-SD2.D2_VALDEV)) AS VALTOT           , "
		_cQuery += "    SUM(SD2.D2_COMIS1*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS1           , "
		_cQuery += "    SUM(SD2.D2_COMIS2*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS2           , "
		_cQuery += "    SUM(SD2.D2_COMIS3*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS3           , "
		_cQuery += "    SUM(SD2.D2_COMIS4*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS4           , "
		_cQuery += "    SUM(SD2.D2_COMIS5*(SD2.D2_VALBRUT-SD2.D2_VALDEV))  AS COMIS5            "  
		_cQuery += " FROM "+ RetSqlName('SF2') +" SF2 "
		_cQuery += " JOIN "+ RetSqlName('SD2') +" SD2 ON SD2.D2_DOC		= SF2.F2_DOC	AND SD2.D2_SERIE	= SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
		_cQuery += " JOIN "+ RetSqlName('SB1') +" SB1 ON SD2.D2_COD		= SB1.B1_COD AND SB1.B1_FILIAL = '  '"
		_cQuery += " JOIN "+ RetSqlName('SF4') +" SF4 ON SD2.D2_FILIAL	= SF4.F4_FILIAL	AND SD2.D2_TES		= SF4.F4_CODIGO "
		_cQuery += " JOIN "+ RetSqlName('ZAY') +" ZAY ON ZAY.ZAY_CF     = SD2.D2_CF "
		_cQuery += " WHERE "
		_cQuery += "     SF2.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SF4.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZAY.D_E_L_E_T_ = ' ' "
		_cQuery += " AND SB1.B1_TIPO    = 'PA' "
		_cQuery += " AND ZAY.ZAY_TPOPER	= 'B' "
      //_cQuery += " AND (SD2.D2_VALBRUT-SD2.D2_VALDEV) > 0"  
		_cQuery +=   _cfiltrobon
		_cQuery += " GROUP BY SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE,SF2.F2_EMISSAO, SF2.F2_CLIENTE,SF2.F2_LOJA,SF2.F2_VEND1, SF2.F2_VEND2, SF2.F2_VEND3, SF2.F2_VEND4, SF2.F2_VEND5 " 
		_cQuery += " ORDER BY SF2.F2_FILIAL,SF2.F2_DOC,SF2.F2_SERIE "
   
      If Select(_cAlias) > 0
			(_cAlias)->( DBCloseArea() )
		EndIf

		DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

End Case
		
Return 

/*
===============================================================================================================================
Programa--------: MOMS064B
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/04/2022
Descrição-------: Retornar os valores dos percentuais de comissões gravados na tabela SD2.
Parametros------: _cFilialNF = Codigo da filial
                  _cNRNF     = Nr da nota fiscal
                  _cSerieNf  = Serie da nota fiscal
                  _cCodCli   = Codigo do cliente
                  _cLojaCli  = Loja do cliente
                  _cProd     = Codigo do produto
Retorno---------: _aRet = {Comissão 1, Comissão 2, Comissão 3, Comissao 4, Valor Total SF2, Valor Total Item, Comissão 5}
===============================================================================================================================
*/
User Function MOMS064B(_cFilialNF,_cNRNF,_cSerieNf,_cCodCli,_cLojaCli,_cProd)
Local _aRet     
Local _aOrd     := SaveOrd({"SD2","SF2"})
Local _nRegSD2  := SD2->(Recno())
Local _nRegSF2  := SF2->(Recno())
Local _nVTotSF2 := 0

Begin Sequence
   _aRet := {0,0,0,0, _nVTotSF2,0 }
   
   SF2->(DBSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
   If SF2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
      _nVTotSF2 := SF2->F2_VALMERC
   EndIf
   
   SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
   If SD2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
      While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")
         If SD2->D2_COD == U_ItKey(_cProd,"D2_COD")
            _aRet := {SD2->D2_COMIS1, SD2->D2_COMIS2, SD2->D2_COMIS3, SD2->D2_COMIS4, _nVTotSF2, SD2->D2_TOTAL, SD2->D2_COMIS5}
         EndIf   
         
         SD2->(DBSkip())   
      EndDo
   EndIf      
     
End Sequence

RestOrd(_aOrd)
SD2->(DBGoTo(_nRegSD2))
SF2->(DBGoTo(_nRegSF2))

Return _aRet

/*
===============================================================================================================================
Programa--------: MOMS064D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/04/2022
Descrição-------: Le e retorna os dados dos itens das notas fiscais.
Parametros------: _aDadosRel = Array com os dados do relatório.
                  _cFilialNF = Filial da nota.
                  _cNRNF     = Numero da nota.
                  _cSerieNf  = Serie da nota.
                  _cCodCli   = Codigo do Cliente.
                  _cLojaCli  = Loja do Cliente.
                  _cTipoDoc  = Tipo de Documento: NF, NCC.
Retorno---------: aRet = Array com os dados do relatório mais os dados dos itens da nota fiscal.
===============================================================================================================================
*/                          //1            2       3       4         5        6         7      
User Function MOMS064D(_aDadosRel, _cFilialNF,_cNRNF,_cSerieNf,_cCodCli,_cLojaCli,_cTipoDoc)
Local _aRet := {}
Local _aLinhaNF := {}
Local _aOrd := SaveOrd({"SD1","SD2","SE1","SF1","SF2"})
Local _nI
Local _cDescPrd
Local _aComiss
Local _nComisVend 
Local _nComisSuper
Local _nComisCoord
Local _nComisGer
Local _nComisGNac
Local _nValTotMerc := 1 // Inicializado com um para divisão.
Local _nTotNF := 0
Local _nPercItem := 0
Local _nFatorBas //, _nComisItem
Local _nMedSisVd, _nMedSisSp, _nMedSisCo, _nMedSisGe, _nMedSisGN
Local _nPerSisVd, _nPerSisSp, _nPerSisCo, _nPerSisGe, _nPerSisGN
Local _nValTotItem
Local _cBIMIX

Begin Sequence
   //==========================================================================
   // Nota Fiscal de Devolução - Deve-se localizar a nota fiscal de origem.
   //==========================================================================
   If AllTrim(_cTipoDoc) == "NCC"   // DEVOLUÇÃO
      SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM                                                                                                     
      If SD1->(DBSeek(U_ItKey(_cFilialNF,"D1_FILIAL")+U_ItKey(_cNRNF,"D1_DOC")+U_ItKey(_cSerieNf,"D1_SERIE")+U_ItKey(_cCodCli,"D1_FORNECE")+U_ItKey(_cLojaCli,"D1_LOJA")))
	     SF1->(DBSetOrder(1)) // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO

         While ! SD1->(Eof()) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == U_ItKey(_cFilialNF,"D1_FILIAL")+U_ItKey(_cNRNF,"D1_DOC")+U_ItKey(_cSerieNf,"D1_SERIE")+U_ItKey(_cCodCli,"D1_FORNECE")+U_ItKey(_cLojaCli,"D1_LOJA")
            SF1->(DBSeek(SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA)))
            _nTotNF := SF1->F1_VALMERC
            _nPercItem := SD1->D1_TOTAL / SF1->F1_VALMERC

            _aLinhaNF := {}
            For _nI := 1 To Len(_aDadosRel)
                aAdd(_aLinhaNF, _aDadosRel[_nI])
            Next

            _aComiss     := U_MOMS064B(SD1->D1_FILIAL,SD1->D1_DOC,SD1->D1_SERIE,SD1->D1_FORNECE,SD1->D1_LOJA,SD1->D1_COD)
            _nComisVend  := _aComiss[1] // % Comissão Vendedor            - D2_COMIS1
            _nComisCoord := _aComiss[2] // % Comissão Coordenador         - D2_COMIS2
            _nComisGer   := _aComiss[3] // % Comissão Gerente             - D2_COMIS3
            _nComisSuper := _aComiss[4] // % Comissão Supervidor          - D2_COMIS4
            _nValTotMerc := _aComiss[5] // Valor total mercadoria SF2     - F2_VALMERC
            _nValTotItem := _aComiss[6] // Valor Total do item Tabela SD2 - D2_TOTAL
            _nComisGNac  := _aComiss[7] // % Comissão Gerente Nacional    - D2_COMIS5

            If _nValTotMerc == 0
               _nValTotMerc := 1 // Inicializado com 1 para divisão. 
            EndIf

            _nTotNF := _nValTotMerc //SF2->F2_VALMERC 

            _nFatorBas := _aDadosRel[10] / _nTotNF

            _nPercItem := _nValTotItem / _nTotNF 

            _nMedSisVd := (_nValTotItem * _nComisVend  * _nFatorBas) / 100
            _nMedSisSp := (_nValTotItem * _nComisSuper * _nFatorBas) / 100
            _nMedSisCo := (_nValTotItem * _nComisCoord * _nFatorBas) / 100
            _nMedSisGe := (_nValTotItem * _nComisGer   * _nFatorBas) / 100
            _nMedSisGN := (_nValTotItem * _nComisGNac   * _nFatorBas) / 100
            _nPerSisVd := (_nMedSisVd / _nValTotItem / _nFatorBas) * 100
            _nPerSisSp := (_nMedSisSp / _nValTotItem / _nFatorBas) * 100
            _nPerSisCo := (_nMedSisCo / _nValTotItem / _nFatorBas) * 100
            _nPerSisGe := (_nMedSisGe / _nValTotItem / _nFatorBas) * 100
            _nPerSisGN := (_nMedSisGN / _nValTotItem / _nFatorBas) * 100

            _aLinhaNF[10] := _aLinhaNF[10] * _nPercItem                // SD1->D1_TOTAL // 12   Valor total do item.	
            _aLinhaNF[11] := (_cAlias)->COMPENSACA * _nPercItem        // (SD1->D1_TOTAL/_nValTotMerc)  // 13   Compensação  
            _aLinhaNF[12] := (_cAlias)->DESCONTO  * _nPercItem         // 14 Desconto do item.	SD1->D1_DESC 						
            _aLinhaNF[13] := (_cAlias)->BAIXASANT * _nPercItem         // 15 (SD1->D1_TOTAL/_nValTotMerc)             // 15   
            _aLinhaNF[14] := _aLinhaNF[14] * _nPercItem                // 16 _nbasecomis * _nPercItem        // (SD1->D1_TOTAL/_nValTotMerc)                      // 16   

            _aLinhaNF[19] := _aLinhaNF[14] * (_nComisVend / 100)       // 25 -- > 27 
            _aLinhaNF[18] := _nComisVend                               // 26 -- > 28  

            _aLinhaNF[23] := _aLinhaNF[14] * (_nComisSuper / 100)      // 29 --> 31 // "Vlr Com Sup"
            _aLinhaNF[22] := _nComisSuper	                          // 30 --> 32 // "% Com Sup"

            _aLinhaNF[27] := _aLinhaNF[14] * (_nComisCoord / 100)	  // "Vlr Com Cood" 33 --> 35  
            _aLinhaNF[26] := _nComisCoord	                          // "% Com Cood"   34 --> 36  

            _aLinhaNF[31] := _aLinhaNF[14]  * (_nComisGer / 100)	      // "Vlr Com Ger"  37 -->39
            _aLinhaNF[30] := _nComisGer                                // "% Com Ger"    38 -->40

            _aLinhaNF[35] := _aLinhaNF[14]  * (_nComisGNac / 100)	  // "Vlr Com Ger Nac"  
            _aLinhaNF[34] := _nComisGNac                               // "% Com Ger Nac"    
            
            SB1->(DBSetOrder(1)) 
            SB1->(DBSeek(xFilial("SB1")+SD1->D1_COD))
            //_cDescPrd := Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC")     // Desc. Prod.
            //_cBIMIX   := Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_I_BIMIX")  // Mix BI
            _cDescPrd := SB1->B1_DESC     // Desc. Prod.
            _cBIMIX   := SB1->B1_I_BIMIX  // Mix BI

            aAdd(_aLinhaNF, _cBIMIX        )    // Mix BI
            aAdd(_aLinhaNF, SD1->D1_ITEM   )    // "Item"           
            aAdd(_aLinhaNF, SD1->D1_COD    )    // "Produto"           
            aAdd(_aLinhaNF, _cDescPrd      )    // "Descrição"        
            aAdd(_aLinhaNF, SD1->D1_PICM   )    // "Aliq.%"           
            aAdd(_aLinhaNF, SD1->D1_QUANT  )    // "Qtde"             
            aAdd(_aLinhaNF, SD1->D1_UM     )    // "U.M."               
            aAdd(_aLinhaNF, SD1->D1_QTSEGUM)    // "Qtde 2a U.M."  
            aAdd(_aLinhaNF, SD1->D1_SEGUM  )    // "2a U.M."         
            aAdd(_aLinhaNF, SD1->D1_VUNIT  )    // "Vlr.Uni."        
            aAdd(_aLinhaNF, SD1->D1_TOTAL  )    // "Valor Total"     

            aAdd(_aLinhaNF, SD1->D1_NFORI  )    // "NF.Origem"       
            aAdd(_aLinhaNF, SD1->D1_SERIORI)    // "Serie Origem"  

            aAdd(_aRet, AClone(_aLinhaNF))
            
            SD1->(DBSkip())
         EndDo
      Else
         _aLinhaNF := {}
         For _nI := 1 To Len(_aDadosRel)
             aAdd(_aLinhaNF, _aDadosRel[_nI])
         Next
         
         //SE1->(DBSetOrder(31)) // 31 - V - E1_FILIAL+E1_NUM+E1_SERIE+E1_CLIENTE+E1_LOJA    
         SE1->(DBSetOrder(2)) // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO    
         
         If SE1->(DBSeek(U_ItKey(_cFilialNF,"E1_FILIAL")+U_ItKey(_cCodCli,"E1_CLIENTE")+U_ItKey(_cLojaCli,"E1_LOJA")+U_ItKey("DCT","E1_PREFIXO")+U_ItKey(_cNRNF,"E1_NUM")  ))
            While ! SE1->(Eof()) .And. SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM) == U_ItKey(_cFilialNF,"E1_FILIAL")+U_ItKey(_cCodCli,"E1_CLIENTE")+U_ItKey(_cLojaCli,"E1_LOJA")+U_ItKey("DCT","E1_PREFIXO")+U_ItKey(_cNRNF,"E1_NUM")
               If AllTrim(SE1->E1_TIPO) == "NCC" .And. AllTrim(SE1->E1_PREFIXO) == "DCT"
                  _aLinhaNF[2] := "DCT"
                  Exit
               EndIf
               
               SE1->(DBSkip())
            EndDo
         EndIf
         
         aAdd(_aLinhaNF, "" )  // Mix BI
         aAdd(_aLinhaNF, "" )  // "Item"           
         aAdd(_aLinhaNF, "" )  // "Produto"           
         aAdd(_aLinhaNF, "" )  // "Descrição"        
         aAdd(_aLinhaNF, 0)    // "Aliq.%"           
         aAdd(_aLinhaNF, 0)    // "Qtde"             
         aAdd(_aLinhaNF, "" )  // "U.M."               
         aAdd(_aLinhaNF, 0  )  // "Qtde 2a U.M."  
         aAdd(_aLinhaNF, "" )  // "2a U.M."         
         aAdd(_aLinhaNF, 0)    // "Vlr.Uni."        
         aAdd(_aLinhaNF, 0)    // "Valor Total"     
         aAdd(_aLinhaNF, "" )  // "NF.Origem"       
         aAdd(_aLinhaNF, "" )  // "Serie Origem"  
            
         aAdd(_aRet, AClone(_aLinhaNF))
             
      EndIf

      Break
   EndIf   

   //==========================================================================
   //  Nota fiscal de venda.
   //==========================================================================
   If AllTrim(_cTipoDoc) <> "NCC" // Venda
      _nValTotMerc := 1 // Inicializado com um para divisão.
     
      _nRegSF2 := SF2->(Recno())
       
      SF2->(DBSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
      If SF2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
         _nValTotMerc := SF2->F2_VALMERC
      EndIf
      
      SF2->(DBGoTo(_nRegSF2))
       
	  _nTotNF := _nValTotMerc //SF2->F2_VALMERC 

      _nFatorBas := _aDadosRel[14] / _nTotNF  // _aDadosRel[16]

      SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
      If SD2->(DBSeek(U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")))
         While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA) == U_ItKey(_cFilialNF,"D2_FILIAL")+U_ItKey(_cNRNF,"D2_DOC")+U_ItKey(_cSerieNf,"D2_SERIE")+U_ItKey(_cCodCli,"D2_CLIENTE")+U_ItKey(_cLojaCli,"D2_LOJA")
            _aLinhaNF := {}
            For _nI := 1 To Len(_aDadosRel)
                aAdd(_aLinhaNF, _aDadosRel[_nI])
            Next

            If AllTrim(_cTipoDoc ) == "BON"
               _aLinhaNF[02] := "BON"
            EndIf
            
            //_nComisItem := (SD2->D2_TOTAL * SD2->D2_COMIS1 * _nFatorBas) / 100

            _nPercItem := SD2->D2_TOTAL / _nTotNF 

            _nMedSisVd := (SD2->D2_TOTAL * SD2->D2_COMIS1 * _nFatorBas) / 100
            _nMedSisSp := (SD2->D2_TOTAL * SD2->D2_COMIS4 * _nFatorBas) / 100
            _nMedSisCo := (SD2->D2_TOTAL * SD2->D2_COMIS2 * _nFatorBas) / 100
            _nMedSisGe := (SD2->D2_TOTAL * SD2->D2_COMIS3 * _nFatorBas) / 100 
            _nMedSisGN := (SD2->D2_TOTAL * SD2->D2_COMIS5 * _nFatorBas) / 100 
            _nPerSisVd := (_nMedSisVd / SD2->D2_TOTAL / _nFatorBas) * 100
            _nPerSisSp := (_nMedSisSp / SD2->D2_TOTAL / _nFatorBas) * 100
            _nPerSisCo := (_nMedSisCo / SD2->D2_TOTAL / _nFatorBas) * 100
            _nPerSisGe := (_nMedSisGe / SD2->D2_TOTAL / _nFatorBas) * 100
            _nPerSisGN := (_nMedSisGN / SD2->D2_TOTAL / _nFatorBas) * 100

            _aLinhaNF[10] := _aLinhaNF[10] * _nPercItem                    // (_cAlias)->VLRTITULO,;   //10
            _aLinhaNF[11] := (_cAlias)->COMPENSACA * _nPercItem            // 11   ( (_cAlias)->COMPENSACA * (SD2->D2_TOTAL/_nValTotMerc)
            _aLinhaNF[12] := (_cAlias)->DESCONTO  * _nPercItem             // 12   SD2->D2_DESC    = Desconto do item.							
            _aLinhaNF[13] := (_cAlias)->BAIXASANT * _nPercItem             // 15   ( (_cAlias)->BAIXASANT * (SD2->D2_TOTAL/_nValTotMerc)
         //If AllTrim(_aLinhaNF[02]) == "BON"
			   _aLinhaNF[14] := _aLinhaNF[14] * _nPercItem                 // * -1 //_nbasecomis * _nPercItem * -1                                // 16   Bonificação não gera comissão. O Valor é negativo.  
			//Else
			//   _aLinhaNF[14] := _aLinhaNF[14] * _nPercItem                 // _nbasecomis * _nPercItem                                     // 16   ( _nbasecomis * (SD2->D2_TOTAL/(_cAlias)->VLRTITULO))
			//EndIf

            _aLinhaNF[19] := _aLinhaNF[14] * (SD2->D2_COMIS1 / 100)        // 25-->27   Percentual comissão 1 - Vendedor
            _aLinhaNF[18] := SD2->D2_COMIS1                                // 26-->28   comissão 1 - Vendedor 

            _aLinhaNF[23] := _aLinhaNF[14] * (SD2->D2_COMIS4 / 100)        // "Vlr Com Sup"             29-->31 
            _aLinhaNF[22] := SD2->D2_COMIS4	                              // "% Com Sup"	           30-->32 

            _aLinhaNF[27] := _aLinhaNF[14] * (SD2->D2_COMIS2 / 100)		  // "Vlr Com Cood"            33-->35
            _aLinhaNF[26] := SD2->D2_COMIS2	                              // "% Com Cood"	           34-->36 

            _aLinhaNF[31] := _aLinhaNF[14]  * (SD2->D2_COMIS3 / 100)	      // "Vlr Com Ger"             37-->39
            _aLinhaNF[30] := SD2->D2_COMIS3                                // "% Com Ger"	           38-->40

            _aLinhaNF[35] := _aLinhaNF[14]  * (SD2->D2_COMIS5 / 100)	      // "Vlr Com Ger Nac"
            _aLinhaNF[34] := SD2->D2_COMIS5                                // "% Com Ger Nac"

            SB1->(DBSetOrder(1)) 
            SB1->(DBSeek(xFilial("SB1")+SD2->D2_COD))
            //_cDescPrd := Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC")    // Desc. Prod.
            //_cBIMIX   := Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_I_BIMIX") // Mix BIMOMS064
            _cDescPrd := SB1->B1_DESC     // Desc. Prod.
            _cBIMIX   := SB1->B1_I_BIMIX  // Mix BI

            aAdd(_aLinhaNF, _cBIMIX        )                                        // "Mix BI"           
            aAdd(_aLinhaNF, SD2->D2_ITEM   )                                        // "Item"           
            aAdd(_aLinhaNF, SD2->D2_COD    )                                        // "Produto"           
            aAdd(_aLinhaNF, _cDescPrd      )                                        // "Descrição"   
            aAdd(_aLinhaNF, SD2->D2_PICM   )                                        // "Aliq.%"           
            aAdd(_aLinhaNF, SD2->D2_QUANT  )                                        // "Qtde"             
            aAdd(_aLinhaNF, SD2->D2_UM     )                                        // "U.M."               
            aAdd(_aLinhaNF, SD2->D2_QTSEGUM)                                        // "Qtde 2a U.M."  
            aAdd(_aLinhaNF, SD2->D2_SEGUM  )                                        // "2a U.M."         
            aAdd(_aLinhaNF, SD2->D2_PRCVEN )                                        // "Vlr.Uni."        
            aAdd(_aLinhaNF, SD2->D2_TOTAL  )                                        // "Valor Total"     
            aAdd(_aLinhaNF, SD2->D2_NFORI  )                                        // "NF.Origem"       
            aAdd(_aLinhaNF, SD2->D2_SERIORI)                                        // "Serie Origem"  

            aAdd(_aRet, AClone(_aLinhaNF))
                        
            SD2->(DBSkip())
            
         EndDo
      EndIf   
   Else
      _aLinhaNF := {}
      For _nI := 1 To Len(_aDadosRel)
          aAdd(_aLinhaNF, _aDadosRel[_nI])
      Next
      
      aAdd(_aLinhaNF, "" )  // Mix BI
      aAdd(_aLinhaNF, "" )  // "Item"           
      aAdd(_aLinhaNF, "" )  // "Produto"           
      aAdd(_aLinhaNF, "" )  // "Descrição"        
      aAdd(_aLinhaNF, 0  )  // "Aliq.%"           
      aAdd(_aLinhaNF, 0  )  // "Qtde"             
      aAdd(_aLinhaNF, "" )  // "U.M."               
      aAdd(_aLinhaNF, 0  )  // "Qtde 2a U.M."  
      aAdd(_aLinhaNF, "" )  // "2a U.M."         
      aAdd(_aLinhaNF, 0  )  // "Vlr.Uni."        
      aAdd(_aLinhaNF, 0  )  // "Valor Total"     
      aAdd(_aLinhaNF, "" )  // "NF.Origem"       
      aAdd(_aLinhaNF, "" )  // "Serie Origem"  
           
      aAdd(_aRet, AClone(_aLinhaNF))
             
   EndIf
  
End Sequence'

RestOrd(_aOrd)

Return _aRet

/*
===============================================================================================================================
Programa--------: U_MOMS064I
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/11/2019
Descrição-------: Retorna valores numéricos passados por parâmentro formatado ou não.
Parametros------: _nValorDado = Valor do dado numérico passado por parâmetro.
                  _cPicture   = Picture de formatação.
                  _lFormataN  = Formata Numero.
Retorno---------: _xRet = valor numerico sem formatação, ou
                        = valor alfanumérico sem formatação.                                             
===============================================================================================================================
*/
User Function MOMS064I(_nValorDado,_cPicture,_lFormataN)
Local _xRet := 0

Default _lFormataN := .F. 
Default _cPicture  := "@E 999,999,999.99"

Begin Sequence
   If _lFormataN
      _xRet := Transform(_nValorDado,_cPicture)
   Else
      _xRet := _nValorDado
   EndIf

End Sequence

Return _xRet

/*
===============================================================================================================================
Programa--------: MOMS064S
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/11/2019
Descrição-------: Retorna valores numéricos passados por parâmentro formatado ou não.
Parametros------: _dDtFecham = Data de fechamento
Retorno---------: _nRet = Retorna a ultima sequencia gravada para o perído informado.
===============================================================================================================================
*/
User Function MOMS064S(_dDtFecham)
Local _nRet := 0
Local _cQry 

Begin Sequence 

   _cQry := " SELECT Max(ZBK_VERSAO) VERSAO "
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZBK_DTFECH = '" + DToS(_dDtFecham) +"' "   
   
   If Select("TRBZBK") > 0
      TRBZBK->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBZBK" , .T. , .F. )

   If ! TRBZBK->(Eof()) .And. ! TRBZBK->(Bof())
      _nRet := Val(TRBZBK->VERSAO)
   Else 
      _nRet := 0 
   EndIf 

End Sequence 

Return _nRet 

/*
===============================================================================================================================
Programa----------: MOMS064T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/05/2022
Descrição---------: Grava os dados das comissões na tabela ZBK.
Parametros--------: _aDados = Dados das comissões.
                    _lScheduller = .T. = Rotina chamada via Scheduller
					               .F. = Rotina chamada via menu
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS064T(oProc,_aDados)
Local _nI
Local _cSeq 
Local _nTotRegs 
Local _cNomeUser //:= UsrFullName(__cUserId)
Local _cGrpProd

Default oProc := Nil

Begin Sequence 

   If Type("__cUserId") = "C" .And. ! Empty(__cUserId)
      _cNomeUser := UsrFullName(__cUserId)
   Else 
      _cNomeUser := "VIA SCHEDULE"  
   EndIf 

   SA1->(DBSetOrder(1))

   _cSeq := StrZero(_nSequen , 3)
   
   _nTotRegs := Len(_aDados)

   For _nI := 1 To _nTotRegs
       
      If _lScheduller
		  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06408"/*cMsgId*/, "MOMS06408 - Gravando registro: " + StrZero(_nI, 6) + "/" + StrZero(_nTotRegs,6)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      EndIf 

      _cCliente := _aDados[_nI,07]  // "Cliente"				//07
      _cLoja    := _aDados[_nI,08]  // "Loja"					//08

	   SA1->(MsSeek(xFilial("SA1")+_cCliente+_cLoja)) 

      ZBK->(RecLock("ZBK",.T.))
      ZBK->ZBK_FILIAL    := xFilial("ZBK") 
      ZBK->ZBK_DTFECH    := _dFechamen
      ZBK->ZBK_VERSAO    := _cSeq
      ZBK->ZBK_FILDOC    := _aDados[_nI,01]  // "Filial"                //01
      ZBK->ZBK_TIPO      := _aDados[_nI,02]  // "Tipo"                  //02
      ZBK->ZBK_EMISSA	 := _aDados[_nI,03]  // "Dt. Emissão"           //03
      ZBK->ZBK_BAIXA     := _aDados[_nI,04]  // "Dt. Baixa"             //04
      ZBK->ZBK_DOCTO     := _aDados[_nI,05]  // "Documento"             //05
      ZBK->ZBK_SERIE     := _aDados[_nI,06]  // "Parcela"               //06
      ZBK->ZBK_CLIENT	 := _aDados[_nI,07]  // "Cliente"               //07
      ZBK->ZBK_LOJA      := _aDados[_nI,08]  // "Loja"                  //08
      ZBK->ZBK_SEQUEN	 := _aDados[_nI,09]  // "Sequencia"             //09
      ZBK->ZBK_VLORIG    := _aDados[_nI,10]  // "Valor Original"        //10
      ZBK->ZBK_COMPEN    := _aDados[_nI,11]  // "Vlr Compensado"        //11
      ZBK->ZBK_DESCON    := _aDados[_nI,12]  // "Vlr Desconto"          //12
      ZBK->ZBK_VLBXAN    := _aDados[_nI,13]  // "Vlr Baixas Ant"        //13
      ZBK->ZBK_BASECM    := _aDados[_nI,14]  //  "Base Comissão"        //14
      ZBK->ZBK_VEND      := _aDados[_nI,15]  // "Representante"         //15
      ZBK->ZBK_NOMVEN	 := _aDados[_nI,16]  //  "Nome rep."            //16
      ZBK->ZBK_TIPVEN	 := _aDados[_nI,17]  // "Tipo Repres"           //17
      ZBK->ZBK_PERCVD	 := _aDados[_nI,18]  // "% Com.Repres"          //18
      ZBK->ZBK_COMVEN	 := _aDados[_nI,19]  // "Comiss.Repres"         //19
      ZBK->ZBK_SUPERV	 := _aDados[_nI,20]  // "Supervisor"            //20
      ZBK->ZBK_NOMSUP	 := _aDados[_nI,21]  // "Nome sup."             //21
      ZBK->ZBK_PERSUP	 := _aDados[_nI,22]  // "% Com.Super"           //22
      ZBK->ZBK_COMSUP	 := _aDados[_nI,23]  // "Comiss.Seper"          //23
      ZBK->ZBK_COORDE    := _aDados[_nI,24]  // "Coordenador"           //24
      ZBK->ZBK_NOMCOO    := _aDados[_nI,25]  // "Nome Coord."           //25
      ZBK->ZBK_PERCOO	 := _aDados[_nI,26]  // "% Com.Coord"           //26
      ZBK->ZBK_COMCOO	 := _aDados[_nI,27]  // "Comiss.Coord"          //27
      ZBK->ZBK_GERENT    := _aDados[_nI,28]  // "Gerente"               //28
      ZBK->ZBK_NOMGER    := _aDados[_nI,29]  // "Nome Ger."             //29
      ZBK->ZBK_PERGER	 := _aDados[_nI,30]  // "% Com.Geren"           //30
      ZBK->ZBK_COMGER	 := _aDados[_nI,31]  // "Comiss.Geren"          //31
      ZBK->ZBK_GERNAC	 := _aDados[_nI,32]  // "Gerente Nacional"      //32
      ZBK->ZBK_NOMGNC    := _aDados[_nI,33]  // "Nome Ger.Nac."         //33 
      ZBK->ZBK_PERGNC	 := _aDados[_nI,34]  // "% Com.Ger.Nac"         //34
      ZBK->ZBK_COMGNC	 := _aDados[_nI,35]  // "Comiss.Ger.Nac"        //35 
      //------------------------------------------------------------------//
      ZBK->ZBK_CODPRO	 := _aDados[_nI,38]  // Codigo do Produto
      ZBK->ZBK_DSCPRD    := _aDados[_nI,39]  // Descrição do Produto
      _cGrpProd          := Posicione("SB1",1,xFilial("SB1")+_aDados[_nI,38],"B1_GRUPO")    // Grupo do Produto
      ZBK->ZBK_GRPPRD	 := _cGrpProd   
      ZBK->ZBK_GRPDSC    := Posicione("SBM",1,xFilial("SBM")+_cGrpProd,"BM_DESC")  // Descrição Grupo do Produto
      ZBK->ZBK_BIMIX	    := _aDados[_nI,36]  // Mix BI
      ZBK->ZBK_USRNMI    := _cNomeUser 
      //------------------------------------------------------------------//
      ZBK->ZBK_GRPVEN	 := SA1->A1_GRPVEN  // Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLoja,"A1_GRPVEN")  // C	6	0	Rede	Grupo de Vendas (Rede)
      ZBK->ZBK_DSCRED	 := SA1->A1_I_NGRPC // Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLoja,"A1_I_NGRPC") // C	30	0	Desc.Rede	Descrição Grupo Vendas (Rede)
      ZBK->ZBK_NOMECL	 := SA1->A1_NOME    // Posicione("SA1",1,xFilial("SA1")+_cCliente+_cLoja,"A1_NOME")    // C	60	0	Nome Cliente	Nome do cliente
      //------------------------------------------------------------------//
      ZBK->(MSUnLock())
	   
	   _lGravouZBK := .T.
      //------------------------------------------------------------------//
      /*
      _aDados[]    // Mix BI          // 36
      _aDados[]    // "Item"          // 37
      _aDados[]    // "Produto"       // 38
      _aDados[]    // "Descrição"     // 39
      _aDados[]    // "Aliq.%"        // 40
      _aDados[]    // "Qtde"          // 41
      _aDados[]    // "U.M."          // 42
      _aDados[]    // "Qtde 2a U.M."  // 43
      _aDados[]    // "2a U.M."       // 44
      _aDados[]    // "Vlr.Uni."      // 45
      _aDados[]    // "Valor Total"   // 46
      _aDados[]    // "NF.Origem"     // 47
      _aDados[]    // "Serie Origem"  // 48
      */
   Next 

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: MOMS064A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/05/2022
Descrição---------: Rotina agendada/Scheduller de processamento dos dados gerenciais de comissões.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS064A()
Local _cQry 

_lScheduller := FWGetRunSchedule() .Or. SELECT("SX3") <= 0

Begin Sequence 

   If _lScheduller
      
      //=============================================================================
      // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
      //=============================================================================
      RpcClearEnv() 
      RpcSetType(3)
      
      //===========================================================================================
      // Preparando o ambiente com a filial da carga recebida
      //===========================================================================================
      PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01" ; //USER 'Administrador' PASSWORD '' ;
                  TABLES 'ZBK', 'SA1', 'SA3', 'SF2', 'SD2', 'SD1', 'SF1', 'SE1', 'SE3','SE5' , 'ZC9' MODULO 'OMS'
       
      Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
     
      cFilAnt := "01" 

	  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06409"/*cMsgId*/, "MOMS06409 - Iniciando a integração, calculo e gravação dos dados gerenciais de comissões nas tabelas. Data: " + DToC(Date()) + " - Hora: " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

   EndIf

   _cQry := " SELECT ZC9_STATUS, ZC9.R_E_C_N_O_ ZC9REG "
   _cQry += " FROM "+ RetSqlName('ZC9') +" ZC9 "
   _cQry += " WHERE "
   _cQry += "     ZC9.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZC9_STATUS = '3' "
   
   If Select("TRBZC9") > 0
      TRBZC9->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBZC9" , .T. , .F. )

   If ! TRBZC9->(Eof()) .And. ! TRBZC9->(Bof())

      U_MOMS064(TRBZC9->ZC9REG) // Rotina principal de integração dos dados de comissões gerenciais.

   EndIf 

   If Select("TRBZC9") > 0
      TRBZC9->( DBCloseArea() )
   EndIf

   If _lScheduller
	  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS064"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS06410"/*cMsgId*/, "MOMS06410 - Finalizando a integração, calculo e gravação dos dados gerenciais de comissões nas tabelas."  + DToC(Date()) + " - Hora: " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      
      //============================================================
      //Limpa o ambiente, liberando a licença e fechando as conexoes
      //============================================================
      RpcClearEnv() 
   EndIf

End Sequence

Return 
