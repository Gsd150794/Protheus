/*  
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS -                             
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      | 28/02/2020 | Função em tela adicionado filtro por data de necessidade. Chamado 32057.                              
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      | 13/10/2020 | Reformulado o monitor de pedido de vendas. Chamado 34389.
-------------------------------------------------------------------------------------------------------------------------------
Jerry         | 27/10/2020 | Retirado provisoriamente a alteração do Tipo de Agendamento. Chamado 34389.
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      | 03/11/2020 | Ajuste na gravação da tabela ZY8 e ZY3. Chamado 34389.
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 19/11/2020 | Ajuste na gravação e controle de datas do Monitoramento. Chamado 34389
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 08/11/2020 | Novo layout do relatorio do e-mail do Monitoramento. Chamado 34389
-------------------------------------------------------------------------------------------------------------------------------
Jerry         | 08/11/2020 | Adicionado Campos da Lib. de Estoque. Chamado 34389
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 20/07/2021 | Ajustes para novas regras do Monitoramento. Chamado 36841 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 29/07/2021 | Ajustes para nova ordenação do Monitor. Chamado 36841 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 02/08/2021 | Ajustes para nova ordenação do Monitor e códigos de justificativa. Chamado 36841 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 16/08/2021 | Correção qdo a falta de produto For menor que 30% do pedido e busca de meso e microregiões. Chamado 36841 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 01/10/2021 | Ajustes para novas regras do Monitor. Chamado 36841 
-------------------------------------------------------------------------------------------------------------------------------
Jerry         | 05/01/2023 | Ajustes no calculo Transit Time. Chamado 42415
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  | 23/07/2025 | Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"
#DEFINE _ENTER CHR(13)+CHR(10)

/*
===============================================================================================================================
Programa--------: MOMS048
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 19/02/2020
===============================================================================================================================
Descrição-------: Schedule Monitor Pedido de Vendas
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOMS048()
	Local _aTabelas := {"SB1","SB2","SC5","SC6","ZG5","ZY1","ZY3","ZY5","ZY7","ZY8","ZP1"}
	Local _aStruct := {}
	Local _aParAux:={} , nI
	Local _aParRet:={}
	Local _LigaDesWS := ""

	Private _lTela   := !(Select('SX3') == 0)
	Private _cAlias := GetNextAlias()
	Private _oTable := Nil
	Private _aSB2   := {}
	Private _aPedidos    :={}
	Private _aPOGravados :={}
	Private _aItensSemEstoque := {}

	/*=============================
		Estrutura da tabela log
	===============================*/
	aAdd(_aStruct, {"Filial", "C",02, 0})
	aAdd(_aStruct, {"Pedido", "C",08, 0})
	aAdd(_aStruct, {"Produto","C",11, 0})
	aAdd(_aStruct, {"Qtdven", "N",18, 4})
	aAdd(_aStruct, {"QATU"  , "N",18, 4})
	aAdd(_aStruct, {"Reserva","N",18, 4})
	aAdd(_aStruct, {"Empen"  ,"N",18, 4})
	aAdd(_aStruct, {"Saldo"  ,"N",18, 4})
	aAdd(_aStruct, {"Corte"  ,"N",18, 4})
	aAdd(_aStruct, {"IniFim" ,"N",01, 0})
	aAdd(_aStruct, {"LocalA" ,"C",05, 0})

	If	!_lTela
	
		/*=============================
			Inicialização do abiente
		===============================*/
		RPCSetType( 3 )
		RpcSetEnv('01','01',,,,GetEnvServer(),_aTabelas)
		//====================================================================
   		// Liga ou Desliga Lista de Monitor de Pedido de Vendas
   		//====================================================================
   		_LigaDesWS := U_ITGETMV('IT_LIGAWFMN', .T.) 
   		If ! _LigaDesWS
      		Break 
   		EndIf 

		sleep( 5000 )

	    MV_PAR01 := Date()
  
	  Else

        MV_PAR01:=dDataBase
        MV_PAR02:=Space(200)
        
        aAdd( _aParAux , { 1 , "Data Ref."	          , MV_PAR01, "@D"	, ""	, ""		, "" , 060 , .T. } )
        aAdd( _aParAux , { 1 , "Filial"               , MV_PAR02, "@!"  , ""    ,"LSTFIL"   , "" , 060 , .T. } ) 
        
        For nI := 1 To Len( _aParAux )
            aAdd( _aParRet , _aParAux[nI][03] )
        Next 

        If !ParamBox( _aParAux , "Seleção de dados" , @_aParRet , {|| .T. } , , , , , , , .T. , .T. )
          Return .T.
        EndIf
                 
	    //If !MSGYESNO("CONFIRMA  ATUALIZAÇÃO DO MONITORAMENTO DOS PEDIDOS DE VENDAS ????")
	    //    Return .F.
	    //EndIf

	 EndIf
    
		_oTable := FwTemporaryTable():New(_cAlias, _aStruct)
		_oTable:AddIndex("Produto", {"Produto"})
		_oTable:AddIndex("Pedido", {"Pedido"})
		_oTable:Create()

		//===========================================================
		//Agrupador de tabelas que serão utilizadas no processamento
		//===========================================================
		DBSelectArea("ZY7")
		DBSelectArea("ZY3")
		ZY3->(DBSetOrder(2))
		DBSelectArea("ZY8")
		ZY8->(DBSetOrder(2))
		DBSelectArea("SC5")
	    SC5->(DBSetOrder(1))
		DBSelectArea("SC6")
	    SC6->(DBSetOrder(1))
		DBSelectArea("SB1")
		SB1->(DBSetOrder(1))
		DBSelectArea("ZG5")
		ZG5->(DBSetOrder(1))

	    If	_lTela
	   
	   	   Processa( {||  _aPedidos := MOMS48CP()  }, "Selecionando os Pedidos..." )
		   
		   If Len(_aPedidos) > 0 
		   	  Processa( {||  MOMS48PC(_aPedidos) }, "Processando os POs p/ gerar as justificativas: "+cValToChar(Len(_aPedidos)) )
		   	  //Gera o arquivo de log em \data\Italac\relatorios
		   	  Processa( {||   MOMS48AQ()  }, "Gerando \data\Italac\relatorios\MOMS048: "+cValToChar((_cAlias)->(LASTREC())) )
		   EndIf
	       If Len(_aPOGravados) > 0
			  Processa( {|| MOMS048I(_aPOGravados) }, 'Enviando WF: '+cValToChar(Len(_aPOGravados)))
		   EndIf
	    
		Else
		   _aPedidos := MOMS48CP()   //Selecionando os Pedidos
		   
		   If Len(_aPedidos) > 0
		   	  MOMS48PC(_aPedidos)
		   	  //Gera o arquivo de log em \data\Italac\relatorios
		   	  MOMS48AQ()
		   EndIf
	       If Len(_aPOGravados) > 0
		      MOMS048I(_aPOGravados) 
		   EndIf
		
		EndIf

		_oTable:Delete() 

	If	_lTela
        U_ITMsg("Finalizado o processamento.",'Atenção!',"Len(_aPedidos) = "+cValToChar(Len(_aPedidos))+" / "+"PO Gravados no ZY3 = "+cValToChar(Len(_aPOGravados)),2) 
	Else
		U_ITConOut("Finalizado schedule de processamento.")
		RpcClearEnv()
	EndIf

Return

/*
===============================================================================================================================
Programa--------: MOMS48CP
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 19/02/2020
===============================================================================================================================
Descrição-------: Pego os pedidos necessários para realizar a manutenção na tabela ZY3
===============================================================================================================================
Parametros------: oProc - objeto para o carregamento do FWMsgRun quando a tela estiver ativa.
===============================================================================================================================
Retorno---------: _aPedidos - Array contendo pedidos a ser processado.
===============================================================================================================================*/
Static Function MOMS48CP()
	Local _cQuery   := "" 
	Local _aPedidos := {}
	Local _cAlias2  := GetNextAlias()
	Local _lC9      := .F.
	Local _cFilPrc  := U_ITGetMV("IT_FILPROC",'01')
	Local _cTpOper  := U_ITGetMv("IT_TPOPER", '01;05')
	Local _dDataValida := DataValida( MV_PAR01 - 1 ) //só dias úteis
	Local _SeqZY3      := 0
	Local _dHoje := Date()
	Local _cTime :=Time()
    Local _cTamMicro := Space(TamSX3("Z25_MICRO")[1])
    Local _cTamMeso  := Space(TamSX3("Z25_MESO")[1])
    Local _cTamCMun  := Space(TamSX3("Z25_CODMUN")[1])
 

	Private aHeader		:= {}
Private aCols		:= {}

    aAdd(aheader,{1,"C6_ITEM"})
    aAdd(aheader,{2,"C6_PRODUTO"})
	aAdd(aheader,{3,"C6_LOCAL"})

 
	Private _cVinc  := DToS(_dHoje)+SubStr(_cTime,1,5)

	Private _aProd := {}	
	
	_cQuery := "SELECT C5.R_E_C_N_O_ C5REC, Z25_COD, Z25_PESO, C5_I_AGEND "
    _cQuery += "FROM " + RetSqlName("SC5") + " C5 "
    _cQuery += "	JOIN " + RetSqlName("SA1") + " SA1 ON C5_CLIENTE = A1_COD AND C5_LOJACLI = A1_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	_cQuery += "    JOIN " + RetSqlName("CC2") + " CC2 ON CC2_EST = A1_EST AND A1_COD_MUN = CC2_CODMUN AND CC2.D_E_L_E_T_ = ' ' "
	_cQuery += "    LEFT JOIN " + RetSqlName("Z25") + " Z25 ON ( (A1_EST = Z25_EST AND CC2_I_MESO = Z25_MESO AND CC2_I_MICR = Z25_MICRO AND A1_COD_MUN = Z25_CODMUN  AND Z25.D_E_L_E_T_ = ' ') "
	_cQuery += "						OR (A1_EST = Z25_EST AND CC2_I_MESO = Z25_MESO AND CC2_I_MICR = Z25_MICRO  AND Z25_CODMUN = '"+_cTamCMun+"' AND Z25.D_E_L_E_T_ = ' ') "
	_cQuery += "						OR (A1_EST = Z25_EST AND CC2_I_MESO = Z25_MESO AND Z25_MICRO = '"+_cTamMicro+"'  AND Z25_CODMUN = '"+_cTamCMun+"'  AND Z25.D_E_L_E_T_ = ' ' ) "
	_cQuery += "						OR (A1_EST = Z25_EST AND Z25_MESO = '"+_cTamMeso+"' AND Z25_MICRO = '"+_cTamMicro+"'  AND Z25_CODMUN = '"+_cTamCMun+"'  AND Z25.D_E_L_E_T_ = ' ') ) "
	_cQuery += "WHERE C5_TIPO = 'N' " 
	_cQuery += "AND C5_NOTA = ' ' "
	_cQuery += "AND C5_TPFRETE <> 'F' "
	_cQuery += "AND C5_I_AGEND NOT IN ('P','R','N') "
	If _lTela
       _cFilPrc:=MV_PAR02
	   _cQuery += "AND C5_FILIAL IN " + FormatIn(_cFilPrc, ";") + " " 
	Else
		_cQuery += "AND C5_FILIAL IN " + FormatIn(_cFilPrc, ";") + " " 
	EndIf

	_cQuery += "AND C5_I_OPER IN " + FormatIn(_cTpOper, ",") + " " 
	_cQuery += "AND C5.D_E_L_E_T_  = ' ' " 
    _cQuery += "AND EXISTS (SELECT 'y' FROM " +RetSqlName("SC6") +" C6, " + RetSqlName("SB1") + " B1 WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM AND B1.D_E_L_E_T_ = ' '  AND B1.B1_FILIAL = ' ' AND B1.B1_COD = C6.C6_PRODUTO AND B1_TIPO = 'PA' ) "	
	_cQuery += "AND NOT EXISTS (SELECT 'y' FROM " +RetSqlName("SC9")+" C9 WHERE C9.D_E_L_E_T_ = ' ' AND C9.C9_FILIAL = C5.C5_FILIAL AND C9.C9_PEDIDO = C5.C5_NUM AND C9.C9_CARGA <> ' ') "
	_cQuery += "ORDER BY  C5_FILIAL, "
	_cQuery += "Case WHEN C5_I_AGEND = 'M' THEN 1 Else Case WHEN C5_I_AGEND = 'A' THEN 2 Else Case WHEN Z25_COD IS NUll THEN 4 Else 3 END END END, "
	_cQuery += "C5_EMISSAO "
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias2 , .T. , .F. )

	(_cAlias2)->(DBGoTop())
	If(_cAlias2)->(Eof())
		U_ITConOut("MOMS048 - Não existe pedidos para processamento.")
		Return _aPedidos
	EndIf
	
	DBSelectArea("SC9")
	SC9->(DBSetOrder(13)) //C9_PEDIDO

	While (_cAlias2)->(!Eof())
		
		SC5->(DBGoTo((_cAlias2)->C5REC))
		acols := {}
    	SC6->(DBSetOrder(1))
    	SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		
    	While SC6->(!Eof()) .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM
    		aAdd(acols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
       		SC6->(DBSkip())
    	EndDo
			
        
		_lC9     := .F.
		_aProd   := {}
		_nDiasTT := 0
		//_nDiasOP := MOMS48Dias()// _nDiasTT PREENCHIDO AQUI
		_nDiasOP := U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,1,.F.,SC5->C5_FILIAL,SC5->C5_I_OPER,SC5->C5_I_TPVEN)
		// Muda tipo do agendamento para reagendar
		// provisoriamente desabilitado a alteração de tipo de agendamento
		// Processa direto os pedidos que já estavam liberados e gravam justificativa como falta de veículo.
		If !Empty(SC5->C5_LIBEROK).And.Empty(SC5->C5_NOTA).And. Empty(SC5->C5_BLQ) .And. (SC5->C5_I_BLOQ == ' ' .Or. SC5->C5_I_BLOQ == 'L') .And.;
			(SC5->C5_I_BLPRC == ' ' .Or. SC5->C5_I_BLPRC == 'L' .Or. SC5->C5_I_BLPRC == 'C') .And.;
			(SC5->C5_I_BLCRE == ' ' .Or. SC5->C5_I_BLCRE == 'L' .Or. SC5->C5_I_BLCRE == 'C') .And. SC5->C5_I_STATU <> '04' .And.;
			(SC5->C5_I_BLOG != 'S' .Or. !Empty(SC5->C5_LIBEROK)) .And. (SC5->C5_I_TRCNF <> 'S' .Or. SC5->C5_I_PDPR = SC5->C5_NUM  )

			_SeqZY3 := MOMS48ZY3("004", _dHoje, _cTime,_cVinc) 

			(_cAlias2)->(DBSkip())
			Loop
		EndIf
		
		If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
			While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
				aAdd(_aProd, SC6->(RECNO()))
				SC6->(DBSkip())
			EndDo
		EndIf

		//  Valida data de necessidade      _dDataValida
		If (SC5->C5_I_DTENT  - _nDiasTT) <= _dDataValida
			If SC9->(DBSeek(SC5->C5_NUM))
				While SC9->(!Eof()) .And. SC9->C9_PEDIDO == SC5->C5_NUM
					If SC9->C9_BLEST == '02' .Or. ( SC5->C5_I_AGEND <> "M" .And. SC9->C9_DATALIB < (Date()-2) )
						_lC9 := .T. //Indicador de estorno  de liberação de estoque
					EndIf
					SC9->(DBSkip())
				EndDo
			EndIf
			aAdd(_aPedidos, {(_cAlias2)->C5REC, _lC9, _aProd,(_cAlias2)->Z25_COD,(_cAlias2)->Z25_PESO,(_cAlias2)->C5_I_AGEND})
		EndIf
		(_cAlias2)->(DBSkip())
	EndDo

	(_cAlias2)->(DBCloseArea())
 
Return _aPedidos

/*
===============================================================================================================================
Programa--------: MOMS48B2
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 14/10/2020
===============================================================================================================================
Descrição-------: Monta o array com os valores atuais da SB2
===============================================================================================================================
Parametros------: _aPedidos
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS48B2(_aPedidos)
	Local _nX := 0
	Local _nY := 0
	Local _nPos := 0
	Local _aAux := {}

	DBSelectArea("SB2")
	SB2->(DBSetOrder(1)) //B2_FILIAL+B2_COD+B2_LOCAL

	//Clone da SB2
	For _nX := 1 TO Len(_aPedidos)
		For _nY := 1 TO Len(_aPedidos[_nX][3])
			SC6->(DBGoTo(_aPedidos[_nX][3][_nY]))
			If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO)) .And. (aScan(_aAux, {|x| x[1] == SB2->B2_FILIAL .And. x[2] == SB2->B2_COD .And. x[3] == SB2->B2_LOCAL})) == 0
				While SB2->(!Eof()) .And. SB2->B2_FILIAL == SC6->C6_FILIAL .And. SB2->B2_COD == SC6->C6_PRODUTO
					aAdd(_aAux, {SB2->B2_FILIAL,;
								 SB2->B2_COD,;
								 SB2->B2_LOCAL,;
								 SB2->B2_QATU,;
								 SB2->B2_RESERVA,;
								 SB2->B2_QEMP,;
								 SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP})
					SB2->(DBSkip())
				EndDo
			EndIf

		Next _nY
	Next _nX

	//Somatória dos saldos entre o armazem 20 e 22 para todos as filiais com exceção da filial 90
	For _nX :=  1 TO Len(_aAux)
		If _aAux[_nX][1] <> "90"
			If (_nPos:=aScan(_aSB2, {|x| x[1] == _aAux[_nX][1] .And. x[2] == _aAux[_nX][2] }) ) == 0
				aAdd(_aSB2, {_aAux[_nX][1],;
							 _aAux[_nX][2],;
							 _aAux[_nX][4],;
							 _aAux[_nX][5],;
							 _aAux[_nX][6],;
							 _aAux[_nX][7],;
							 "Geral"})
			Else
				If _aAux[_nX][3] $ "20|22"
					_aSB2[_nPos][3] += _aAux[_nX][4]
					_aSB2[_nPos][4] += _aAux[_nX][5]
					_aSB2[_nPos][5] += _aAux[_nX][6]
					_aSB2[_nPos][6] += _aAux[_nX][7]
				EndIf
			EndIf
		Else //Somatória dos armazéns diferentes
			If (_nPos:=aScan(_aSB2, {|x| x[1] == _aAux[_nX][1] .And. x[2] == _aAux[_nX][2] }) ) == 0
				aAdd(_aSB2, {_aAux[_nX][1],;
							 _aAux[_nX][2],;
							 _aAux[_nX][4],;
							 _aAux[_nX][5],;
							 _aAux[_nX][6],;
							 _aAux[_nX][7],;
							 IIf(_aAux[_nX][3] != "36","Geral",_aAux[_nX][3]) })
			Else
				Do Case
					Case _aAux[_nX][3] $ "20|22"
						_aSB2[_nPos][3] += _aAux[_nX][4]
						_aSB2[_nPos][4] += _aAux[_nX][5]
						_aSB2[_nPos][5] += _aAux[_nX][6]
						_aSB2[_nPos][6] += _aAux[_nX][7]

					Case _aAux[_nX][3] == "36"
						_aSB2[_nPos][3] += _aAux[_nX][4]
						_aSB2[_nPos][4] += _aAux[_nX][5]
						_aSB2[_nPos][5] += _aAux[_nX][6]
						_aSB2[_nPos][6] += _aAux[_nX][7]
				EndCase
			EndIf
		EndIf
	Next _nX

	MOMS48LG(,.T.,_aSB2) //Grava status inicial da SB2
	

	SB2->(DBCloseArea())
Return

/*
===============================================================================================================================
Programa--------: MOMS48PC
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 19/02/2020
===============================================================================================================================
Descrição-------: Processa os pedidos para gerar as justificativas
===============================================================================================================================
Parametros------: _aPedidos - Array contendo os pedidos a ser processado.
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS48PC(_aPedidos)
	Local _nX       := 0
	Local _nY       := 0
	Local _nDif     := 0 
	Local _lProduto := .F.
	Local _nPesCort := U_ITGetMv("IT_CORTEPES", 1000)
	Local _SeqZY3   := 0
	Local _dHoje    := Date()
	Local _cTime    := Time()
    Local _aZonaEnt := {}
    Local _cZonaEnt := ""
    Local _nPesoLim := 0
    Local _nFaltaPro := 0 
    Local _nTotPro  := 0
    Local _aTotCapac := {0,0}
    Local _nTotVol   := 0
    Local _aCapac    := 0
    Local _aItensPed := 0

	Private _nCorte := 0
	Private _nPos := 0
	Private _cVinc  := DToS(_dHoje)+SubStr(_cTime,1,5)

	//Estorna os bloqueios de estoque
	For _nX := 1 TO Len(_aPedidos)
        SC5->(DBGoTo(_aPedidos[_nX][1]))

		If _aPedidos[_nX][2]
			MOMS48EST() //Estorna bloqueio de estoque para cada item do pedido de vendas que tiver C9_BLEST
		EndIf

        _cZonaEnt := _aPedidos[_nX][4] //Z25->Z25_COD
        _nPesoLim := _aPedidos[_nX][5] //Z25->Z25_PESO

        aAdd(_aZonaEnt, {_cZonaEnt,_nPesoLim})

	Next _nX

    //Traz a capacidade das unidades
    _aCapac := MOMS48CAP()

	//Clona dados da SB2 para o processamento das justificativas
	MOMS48B2(_aPedidos)

	For _nX := 1 TO Len(_aPedidos)
		_lProduto := .F. 
		_nCalc := 0 
		_nCorte := 0 
        _nPeso := 0
        _aItensPed := {}

		SC5->(DBGoTo(_aPedidos[_nX][1]))
        
        _cZonaEnt := _aPedidos[_nX][4]
		
        For _nY := 1 TO Len(_aPedidos[_nX][3])
			SC6->(DBGoTo(_aPedidos[_nX][3][_nY]))
			//Realiza o consumo da SB2 para gerar justificativa
			//Alinhado com o Jerry que qualquer item do pedido que o corte For maior que 1000KG, gerar
			//ZY3 com a justifica falta de veiculo, os demais itens terão as justificativas na ZY8
			If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] $ "Geral|36" })) > 0 				

				If _aSB2[_nPos][3]  >= SC6->C6_QTDVEN
					_aSB2[_nPos][3] -= SC6->C6_QTDVEN
					_aSB2[_nPos][6] -= SC6->C6_QTDVEN
                    aAdd(_aItensPed,{SC6->C6_QTDVEN,SC6->C6_QTDVEN})
					_nCorte:=MOMS48KG(SC6->C6_QTDVEN)
				Else
					_nDif := SC6->C6_QTDVEN - _aSB2[_nPos][3]
                    
                    If (_nCorte:=MOMS48KG(_nDif)) >= _nPesCort
						_aSB2[_nPos][6] -= SC6->C6_QTDVEN
                        _nFaltaPro += MOMS48KG(_nDif)
						_SeqZY3:= MOMS48ZY3("005", _dHoje, _cTime,_cVinc) //FALTA DE PRODUTO
						MOMS48ZY8("005",_SeqZY3, _dHoje, _cTime,_cVinc) //FALTA DE PRODUTO
						_lProduto := .T.
                        aAdd(_aItensPed,{0,SC6->C6_QTDVEN})
					Else
						_nCorte := MOMS48KG(_nDif)
						_aSB2[_nPos][3] -= _aSB2[_nPos][3]
						_aSB2[_nPos][6] -= _nDif
						_nDif -= _aSB2[_nPos][3]
                        aAdd(_aItensPed,{_aSB2[_nPos][3],_nDif})
					EndIf
				EndIf
                _nTotPro += _nCorte
			EndIf

             
			MOMS48LG(.T.)//Grava Item de consumo da SB2
		Next _nY
        If !Empty(SC5->C5_I_PEVIN)
            SC6->(DBSetOrder(1))
            If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PEVIN))
                While (SC5->C5_FILIAL+SC5->C5_I_PEVIN == SC6->C6_FILIAL+SC6->C6_NUM)
                    If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] $ "Geral|36" })) > 0
                                
                        If _aSB2[_nPos][3]  >= SC6->C6_QTDVEN
        					_aSB2[_nPos][3] -= SC6->C6_QTDVEN
        					_aSB2[_nPos][6] -= SC6->C6_QTDVEN
                            aAdd(_aItensPed,{SC6->C6_QTDVEN,SC6->C6_QTDVEN})
        					_nCorte:=MOMS48KG(SC6->C6_QTDVEN)
        				Else
        					_nDif := SC6->C6_QTDVEN - _aSB2[_nPos][3]
                            
                            If (_nCorte:=MOMS48KG(_nDif)) >= _nPesCort
        						_aSB2[_nPos][6] -= SC6->C6_QTDVEN
                                _nFaltaPro += MOMS48KG(_nDif)
        						_SeqZY3:= MOMS48ZY3("005", _dHoje, _cTime,_cVinc) //FALTA DE PRODUTO
        						MOMS48ZY8("005",_SeqZY3, _dHoje, _cTime,_cVinc) //FALTA DE PRODUTO
        						_lProduto := .T.
                                aAdd(_aItensPed,{0,SC6->C6_QTDVEN})
        					Else
        						_nCorte := MOMS48KG(_nDif)
        						_aSB2[_nPos][3] -= _aSB2[_nPos][3]
        						_aSB2[_nPos][6] -= _nDif
        						_nDif -= _aSB2[_nPos][3]
                                aAdd(_aItensPed,{_aSB2[_nPos][3],_nDif})
        					EndIf
        				EndIf
                        _nTotPro += _nCorte
                    EndIf
                    SC6->(DBSkip())
                EndDo
                
            EndIf
        EndIf
        MOMS48LG(.T.)//Grava Item de consumo da SB2

		If !_lProduto

            If (SC5->C5_I_AGEND == "M" .Or. SC5->C5_I_AGEND == "A") .And. (_nPos := aScan(_aCapac,{|x| x[1]== SC5->C5_FILIAL .And. x[3]== 1 })) <> 0  
                _aTotCapac[1] += _nTotPro
                
                If _aTotCapac[1] <= _aCapac[_nPos][2] 
                    _SeqZY3 := MOMS48ZY3("003", _dHoje, _cTime,_cVinc) //FALTA DE CARREGAMENTO 
                Else
                    _SeqZY3 := MOMS48ZY3("022", _dHoje, _cTime,_cVinc) //FALTA DE CAPACIDADE
                EndIf

            ElseIf !Empty(AllTrim(_cZonaEnt)) .And. (_nPos := aScan(_aZonaEnt,{|E| E[1]==_cZonaEnt })) <> 0 
                _nTotVol += _nTotPro
                // Peso Atingido          Peso Limite
                If _nTotVol > _aZonaEnt[_nPos][2]
                    _SeqZY3 := MOMS48ZY3("021", _dHoje, _cTime,_cVinc) //SEM VOLUME
                    
                    //Estorna reserva
                    For _nY := 1 TO Len(_aPedidos[_nX][3])
                        SC6->(DBGoTo(_aPedidos[_nX][3][_nY]))
                        If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] $ "Geral|36" })) > 0 
                            _aSB2[_nPos][3] += _aItensPed[_nY,1]
				            _aSB2[_nPos][6] += _aItensPed[_nY,2]
                        EndIf
                    Next

                Else
                    _aTotCapac[2] += _nTotPro
                    _nPos := aScan(_aCapac,{|E| E[1]== SC5->C5_FILIAL .And. E[3]== 2 })

                    If _nPos > 0
                        If _aTotCapac[2] <= _aCapac[_nPos][2] 
                            _SeqZY3 := MOMS48ZY3("003", _dHoje, _cTime,_cVinc) //FALTA DE CARREGAMENTO 
                        Else
                            _SeqZY3 := MOMS48ZY3("022", _dHoje, _cTime,_cVinc) //FALTA DE CAPACIDADE
                        EndIf
                    Else
                        _SeqZY3 := MOMS48ZY3("022", _dHoje, _cTime,_cVinc) //FALTA DE CAPACIDADE
                    EndIf

                EndIf
            Else
                _aTotCapac[2] += _nTotPro
                _nPos := aScan(_aCapac,{|E| E[1]== SC5->C5_FILIAL .And. E[3]== 2 })
                If _nPos > 0
                    If _aTotCapac[1] <= _aCapac[_nPos][2] 
                        _SeqZY3 := MOMS48ZY3("003", _dHoje, _cTime,_cVinc) //FALTA DE CARREGAMENTO 
                    Else
                        _SeqZY3 := MOMS48ZY3("022", _dHoje, _cTime,_cVinc) //FALTA DE CAPACIDADE
                    EndIf
                Else
                    _SeqZY3 := MOMS48ZY3("022", _dHoje, _cTime,_cVinc) //FALTA DE CAPACIDADE
                EndIf
            EndIf
		EndIf
	Next _nX
Return

/*
===============================================================================================================================
Programa--------: MOMS48ZY3
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 20/02/2020
===============================================================================================================================
Descrição-------: Grava as informações necessárias na tabela ZY3
===============================================================================================================================
Parametros------: cCodJus - Código da justificativa
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS48ZY3(cCodjus, _dHoje, _cTime, _cVinc)
	Local _cSec := ""
	
	If ZY3->(DBSeek(SC5->C5_NUM))
		While  ZY3->(!Eof()) .And. ZY3->ZY3_NUMPV = SC5->C5_NUM
			If ZY3->ZY3_DTMONI = Date() .And. ZY3->ZY3_JUSCOD = cCodjus .And. ZY3->ZY3_CODUSR = IIf(_lTela, __cUserId, "000001")
				Return
			EndIf 
		    ZY3->(DBSkip())
		EndDo
	EndIf

	_nDiasTT := 0
	_nDiasOP := MOMS48Dias()// _nDiasTT PREENCHIDO AQUI

	_cSec := MOMS48SEC()

	ZY3->(RecLock("ZY3", .T.))
	ZY3->ZY3_FILIAL     := " "
	ZY3->ZY3_FILFT      := SC5->C5_FILIAL
	ZY3->ZY3_NUMPV      := SC5->C5_NUM
	ZY3->ZY3_SEQUEN     := _cSec
	ZY3->ZY3_DTMONI     := _dHoje
	ZY3->ZY3_HRMONI     := _cTime
	ZY3->ZY3_COMENT     := "Gerado via SCHEDULER"
	ZY3->ZY3_CODUSR     := IIf(_lTela, __cUserId, "000001")
	ZY3->ZY3_NOMUSR     := IIf(_lTela, UsrFullName(__cUserId), "SCHEDULER")
	ZY3->ZY3_ENVIAD     := " "
	ZY3->ZY3_ENCMON     := "N"
	ZY3->ZY3_DTNECE     := SC5->C5_I_DTNEC
	ZY3->ZY3_DTFAT      := DataValida(SC5->C5_I_DTENT + 1 - _nDiasOP )//SC5->C5_I_DTENT
	ZY3->ZY3_DTFOLD     := SC5->C5_I_DTENT
	ZY3->ZY3_JUSCOD     := cCodjus
	ZY3->ZY3_ORIGEM     := "MOMS048" 
	ZY3->ZY3_VNCZY8     := (SC5->C5_NUM + _cVinc)
	ZY3->(MSUnLock())

	aAdd(_aPOGravados,{SC5->(RECNO()),ZY3->(RECNO())})

Return _cSec

/*
===============================================================================================================================
Programa--------: MOMS48ZY8
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 20/02/2020
===============================================================================================================================
Descrição-------: Grava as informações necessárias na tabela ZY8 
===============================================================================================================================
Parametros------: cCodJus - Código da justificativa
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS48ZY8(cCodjus,_cSeq, _dHoje, _cTime, _cVinc)
	ZY8->(RecLock("ZY8", .T.))
	ZY8->ZY8_FILIAL := xFilial("ZY8")
	ZY8->ZY8_NUMPV  := SC6->C6_NUM
	ZY8->ZY8_SEQUEN := _cSeq//ZY8->ZY8_SEQUEN := SC6->C6_ITEM
	ZY8->ZY8_DTMONI := _dHoje
	ZY8->ZY8_HRMONI := _cTime
	ZY8->ZY8_CODUSR := If(_lTela, __cUserId, "000001")
	ZY8->ZY8_NOMUSR := If(_lTela, UsrFullName(__cUserId), "SCHEDULER")
	ZY8->ZY8_CODPRD := SC6->C6_PRODUTO
	ZY8->ZY8_DSCPRD := SC6->C6_DESCRI 
	ZY8->ZY8_UNSVEN := SC6->C6_UNSVEN
	ZY8->ZY8_SEGUM  := SC6->C6_SEGUM
	ZY8->ZY8_QTDVEN := SC6->C6_QTDVEN
	ZY8->ZY8_UM     := SC6->C6_UM
	ZY8->ZY8_FILFT  := SC6->C6_FILIAL
	ZY8->ZY8_JUSCOD := cCodjus
	ZY8->ZY8_ORIGEM := "MOMS048" 
	ZY8->ZY8_VNCZY3     := (SC6->C6_NUM +  _cVinc)
	aAdd(_aItensSemEstoque,{SC6->C6_FILIAL,SC6->C6_NUM,SC6->C6_PRODUTO,SC6->C6_PEDCLI})
	ZY8->(MSUnLock())
Return

/*
===============================================================================================================================
Programa--------: MOMS48SEC
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 15/10/2020
===============================================================================================================================
Descrição-------: Retorna sequencia da ZY3 ou ZY8
===============================================================================================================================
Parametros------: _
===============================================================================================================================
Retorno---------: lOk
===============================================================================================================================*/
Static Function MOMS48SEC(lZY3)
	Local _cSec := "0001" 
	DEFAULT lZY3 := .T.

	If lZY3
		If ZY3->(DBSeek(SC5->C5_NUM))
			While ZY3->(!Eof()) .And. ZY3->ZY3_NUMPV == SC5->C5_NUM
				If ZY3->ZY3_SEQUEN >= _cSec
					_cSec := StrZero(Val(ZY3->ZY3_SEQUEN)+1,4)
				EndIf
				ZY3->(DBSkip())
			EndDo
		EndIf
	Else
		If ZY8->(DBSeek(SC6->C6_NUM))
			While ZY8->(!Eof()) .And. ZY8->ZY8_NUMPV = SC6->C6_NUM
				If ZY8->ZY8_SEQUEN >= _cSec
					_cSec := StrZero(Val(ZY8->ZY8_SEQUEN)+1,4)
				EndIf
				ZY8->(DBSkip())
			EndDo
		EndIf
	EndIf

Return _cSec

/*
===============================================================================================================================
Função------------: MOMS48EST
Autor-------------: Jonathan Torioni
Data da Criacao---: 15/10/2020
===============================================================================================================================
Descrição---------: Estorna o bloqueio de estoque para o item de pedido de vendas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: True or False
===============================================================================================================================
*/
Static Function MOMS48EST()
	Local _lRet := .T.
	Local _aSaveArea := FWGetArea()

	SC6->(DBSetOrder(1))
	SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

	//Se tiver liberação válida para todos os itens desfaz liberação

	While !(SC6->(Eof())) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->C5_FILIAL+SC5->C5_NUM
		SC9->(DBSetOrder(1))
		If (SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM)))
			SC9->(_lRet:=A460Estorna()) // estorna a liberação
		EndIf
		SC6->(DBSkip())
	EndDo

	SC9->(DBSetOrder(1))
	If !SC9->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		SC5->(RecLock("SC5",.F.))
		SC5->C5_LIBEROK := "  "
		SC5->C5_I_STATU := "01"
		SC5->(MSUnLock())
	EndIf

	MSUnLockAll()
	SC6->(MSUnLockALL())
	SC6->(MSUnLock())
	SB2->(MSUnLockALL())
	SB2->(MSUnLock())
	SC5->(MSUnLockALL())

	FWRestArea(_aSaveArea)

Return _lRet

/*
===============================================================================================================================
Função------------: MOMS48KG
Autor-------------: Jonathan Torioni
Data da Criacao---: 15/10/2020
===============================================================================================================================
Descrição---------:  Retorna peso da quantidade informada.
===============================================================================================================================
Parametros--------: _nQtde
===============================================================================================================================
Retorno-----------: _nCorte
===============================================================================================================================
*/
Static Function MOMS48KG(_nQtde)
	Local _nPeso := 0

	If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
		_nPeso :=  _nQtde * SB1->B1_PESBRU
	EndIf
Return _nPeso

/*
===============================================================================================================================
Função------------: MOMS48LG
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/10/2020
===============================================================================================================================
Descrição---------:  Grava movimentação da SB2 na _oTable
===============================================================================================================================
Parametros--------: _lPedido - Indica se gravará registro do pedido ou status
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/

Static Function MOMS48LG(_lPedido, _lIni, aSb2)
	Local _nX := 0
	DEFAULT _lPedido := .F.
	DEFAULT _lIni := .F.

	If !_lPedido .And. _lIni .And. Len(aSb2) > 0
		For _nX := 1 TO Len(aSb2)
			//RecLock(_cAlias, .T.)
			(_cAlias)->(DBAPPEND())
			(_cAlias)->Filial  := SC6->C6_FILIAL
			(_cAlias)->Produto := _aSB2[_nX][2]
			(_cAlias)->QATU    := _aSB2[_nX][3]
			(_cAlias)->Reserva := _aSB2[_nX][4]
			(_cAlias)->Empen   := _aSB2[_nX][5]
			(_cAlias)->Saldo   := _aSB2[_nX][6]
			(_cAlias)->IniFim  := 0
			(_cAlias)->LocalA   := _aSB2[_nX][7]
			//(_cAlias)->(MSUnLock())
		Next
	Else
//		RecLock(_cAlias, .T.)
		(_cAlias)->(DBAPPEND())
		(_cAlias)->Filial  := SC6->C6_FILIAL
		(_cAlias)->Pedido  := SC6->C6_NUM
		(_cAlias)->Produto := SC6->C6_PRODUTO
		(_cAlias)->Qtdven  := SC6->C6_QTDVEN
		(_cAlias)->QATU    := _aSB2[_nPos][3]
		(_cAlias)->Reserva := _aSB2[_nPos][4]
		(_cAlias)->Empen   := _aSB2[_nPos][5]
		(_cAlias)->Saldo   := _aSB2[_nPos][6]
		(_cAlias)->Corte   := _nCorte //Peso do corte
		(_cAlias)->LocalA  := _aSB2[_nPos][7]
		//(_cAlias)->(MSUnLock())

	EndIf
Return

/*
===============================================================================================================================
Função------------: MOMS48AQ
Autor-------------: Jonathan Torioni
Data da Criacao---: 16/10/2020
===============================================================================================================================
Descrição---------:  Grava em txt a movimentação da SB2
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
Static Function MOMS48AQ()
	Local _cNomArq := "\data\Italac\relatorios\MOMS048_" + StrTran(alltochar(date()), "/","") + "_" + StrTran(Alltochar(Time()),":","") + ".csv"
	Local _nHandle
	Local _cLin := ""
	Local _aHeader := {}
	Local _aCols := {}
	Local _nX := 0
	Local _nY := 0
	Local _nA := 0

	_nHandle := FCreate(_cNomArq )

	If _nHandle = -1
		U_ITConOut("MOMS048 - Falha ao gerar o arquivo " + _cNomArq + " Erro: " + Str(Ferror()) )
		Return
	Else
		(_cAlias)->(DBGoTop())
		While (_cAlias)->(!Eof())
			aAdd( IIf(Empty((_cAlias)->Pedido), _aHeader, _aCols), {(_cAlias)->Filial,;
				(_cAlias)->Pedido,;
				(_cAlias)->Produto,;
				(_cAlias)->Qtdven,;
				(_cAlias)->QATU,;
				(_cAlias)->Reserva,;
				(_cAlias)->Empen,;
				(_cAlias)->Saldo,;
				(_cAlias)->Corte,;
				(_cAlias)->LocalA})

			(_cAlias)->(DBSkip())
		EndDo

		aSort(_aHeader, , , { |x,y| x[1] > y[1] .And. x[3] > y[3] } )

		_cLin := "Filial;Pedido;Produto;Qtdven;QATU;Reserva;Empen;Saldo;Peso Avaliado(KG);Local"
		FWrite(_nHandle, _cLin +_ENTER)

		For _nX := 1 TO Len(_aHeader)
			_cLin := ""
			//Monta linha do _aHeader
			For _nA := 1 TO Len(_aHeader[_nX])
				_cLin += AllTrim(Alltochar(_aHeader[_nX][_nA])) + IIf(!(_nA == Len(_aHeader[_nX])), ";", "")
			Next _nA
			FWrite(_nHandle, _cLin +_ENTER)
			_cLin := ""
			//Monta linha de _aCols
			For _nY := 1 TO Len(_aCols)
				_cLin := ""
				If _aCols[_nY][1] == _aHeader[_nX][1] .And. _aCols[_nY][3] == _aHeader[_nX][3] .And. _aCols[_nY][10] == _aHeader[_nX][10]
					For _nA :=  1 TO Len(_aCols[_nY])
						_cLin += AllTrim(Alltochar(_aCols[_nY][_nA])) + IIf( !(_nA == Len(_aCols[_nY])), ";","")
					Next _nA
					FWrite(_nHandle, _cLin +_ENTER)
				EndIf
			Next _nY
			FWrite(_nHandle, _ENTER)
		Next _nX

		FClose(_nHandle)
	EndIf

Return



/*
===============================================================================================================================
Programa----------: MOMS048I
Autor-------------: Alex Wallauer
Data da Criacao---: 18/11/2019
===============================================================================================================================
Descrição---------: Gera os dados do relatório em Excel para envio por e-mail.
===============================================================================================================================
Parametros--------: _aPOGravados =  Pedidos gravados no ZY3
===============================================================================================================================
Retorno-----------: Nenhum  //       Processa( {|| MOMS048I(_aPOGravados) }, 'Enviando WF ...' , 'Aguarde!')
===============================================================================================================================
*/
Static Function MOMS048I(_aPOGravados)
	Local _aCabec , P , C
	Local _cDirExcel := "\spool"
	Local _cDataHora
	Local _cNomeArq
	Local _cTitulo 
	Local _aLista 
	Local _dReserva :=""
	Local cGetPara  := SuperGetMV("IT_EMAILMO",.F.,"sistema@italac.com.br")
	Local cGetCc    := ""
	Local cGetAssun := "Schedule - Monitor Pedido de Vendas"
	Local _cHtml    :='<b>Prezado Sr(a),</b>'

	_cHtml += '<br><br>'
	_cHtml += '&nbsp;&nbsp;&nbsp;Segue anexo o relatório do Monitor Pedido de Vendas. '+'.<br>'
	_cHtml += '<br>'
	_cHtml += '<b>Observação: </b>O arquivo em anexo deve ser aberto com o Microsoft Excel.'
	_cHtml += '<br>'
	_cHtml += '<br>' 
	_cHtml += '<br>'
	_cHtml += '<p><span class="negrito">Ambiente: </span></br> ['+ GETENVSERVER() +']'
	_cHtml += '<span class="negrito"> / Fonte:    </span></br> [MOMS048] </p>'

	If _lTela
		cGetCc:= "sistema@italac.com.br"
		cGetAssun := "Tela - Monitor Pedido de Vendas"
	EndIf

	Begin Sequence
		//=============================================================================
		// Obtem Cabeçalho do Relatório
		//=============================================================================
		_aCabec := {} // Array com o cabeçalho das colunas do relatório.
		// Alinhamento( 1-Left,2-Center,3-Right )
		// Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
		//                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		aAdd(_aCabec,{"Filial"                 ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Nr.Pedido"              ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Pedido do cliente"      ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Operacao"               ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Data Monitoramento"     ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Tipo de agenda"         ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Peso Bruto"             ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Valor Pedido"           ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Dt Emissao"             ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Data Entrega"           ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Data Operacional"       ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Data Lib.Estoque"       ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Qntos dias na Carteira" ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Tempo Transit time"     ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Tempo Operacional"      ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Gerente"                ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Coordenador"            ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Vendedor"               ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Nome Cliente"           ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Nome Rede"              ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Nome Fantasia"          ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Loja Cliente"           ,1           ,1         ,.F.})
		aAdd(_aCabec,{"CNPJ Cliente"           ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Produtos"               ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Estado"                 ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Municipio"              ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Codigo Justificativa"   ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Descricao Justificativa",1           ,1         ,.F.})
		aAdd(_aCabec,{"Sequencia"              ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Hora Monitoramento"     ,1           ,1         ,.F.})
		aAdd(_aCabec,{"Origem"                 ,1           ,1         ,.F.})

		_aLista := {}

		If _lTela
			ProcRegua(Len(_aPOGravados))
		EndIf
		If Len(_aItensSemEstoque) > 0
			aSort(_aItensSemEstoque, , ,{|x,y| x[1] + x[2] < y[1] + y[2] }) //ORDEM FILIAL + PEDIDO
		EndIf
		SA1->(DBSetOrder(1))

		For P := 1 TO Len(_aPOGravados)

			If _lTela
				IncProc("Montando o relatório...")
			EndIf
			SC5->(DBGoTo(_aPOGravados[P,1]))
			ZY3->(DBGoTo(_aPOGravados[P,2]))
			_dReserva := ""
			_cProds   := ""
			_cPedsCli := ""

			_nDiasTT := 0
			_nDiasOP := MOMS48Dias()// _nDiasTT PREENCHIDO AQUI

			_nTotalPedido  := MOMS48Valor(SC5->C5_FILIAL,SC5->C5_NUM )
			If !Empty(SC5->C5_LIBEROK)
				If SC9->(DBSeek(AllTrim(SC5->C5_FILIAL)+AllTrim(SC5->C5_NUM))) .And. SC9->C9_FILIAL == AllTrim(SC5->C5_FILIAL) .And. SC9->C9_PEDIDO == AllTrim(SC5->C5_NUM)
					_dReserva := SC9->C9_DATALIB
				EndIf
			EndIf

			If (_nPos:=aScan(_aItensSemEstoque,{|E| E[1]+E[2]==SC5->C5_FILIAL+SC5->C5_NUM  })) <> 0

				For C := _nPos TO Len(_aItensSemEstoque)
					If _aItensSemEstoque[C,1]+_aItensSemEstoque[C,2] == SC5->C5_FILIAL+SC5->C5_NUM
						_cProds  +=_aItensSemEstoque[C,3]+"-"+AllTrim(Posicione('SB1', 1, xFilial('SB1') + _aItensSemEstoque[C,3], 'B1_DESC'))+_ENTER
						If !_aItensSemEstoque[C,4] $ _cPedsCli
							_cPedsCli+=_aItensSemEstoque[C,4]+_ENTER
						EndIf
					Else
						Exit
					EndIf
				Next

			EndIf

			SA1->(DBSeek(xFilial()+SC5->C5_CLIENTE+SC5->C5_LOJACLI))

			aAdd(_aLista, {SC5->C5_FILIAL,;           // - Filial
			SC5->C5_NUM,;              // - Nr.Pedido
			_cPedsCli,;                // - Pedido do cliente
			SC5->C5_I_OPER,;           // - Operação
			ZY3->ZY3_DTMONI,;          // - Data Monitoramento
			SC5->C5_I_AGEND,;          // - Tipo de agenda
			SC5->C5_I_PESBR,;          // - Peso Bruto do Pedido
			_nTotalPedido,;            // - Valor Total do Pedido
			SC5->C5_EMISSAO,;          // - Dt Digitacao pedido
			SC5->C5_I_DTENT,;          // - Data Entrega
			ZY3->ZY3_DTFAT,;           // - Data Operacional
			_dReserva,;				 // - Data de Liberação de Estoque
			(Date() -SC5->C5_EMISSAO),;// - Qntos dias na Carteira - Dias na Carteira Data de hj (-) Data de Emissão
			_nDiasTT,;                 // - Tempo Transit time
			_nDiasOP,;                 // - Tempo Operacional
			SC5->C5_I_V3NOM,;          // - Gerente
			SC5->C5_I_V2NOM,;          // - Coordenador
			SC5->C5_I_V1NOM,;          // - Vendedor
			SA1->A1_NOME,;             // - Nome Cliente
			SC5->C5_I_NOME,;           // - Nome Rede
			SA1->A1_NREDUZ,;           // - Nome Fantasia
			SC5->C5_LOJACLI,;          // - Loja cliente
			SA1->A1_CGC,;              // - CNPJ Cliente
			_cProds,;                  // - Produtos
			SC5->C5_I_EST,;            // - Estado
			SC5->C5_I_MUN,;            // - Municipio
			ZY3->ZY3_JUSCOD,;          // - Codigo Justificativa
			Posicione("ZY5",1,xFilial("ZY5")+ZY3->ZY3_JUSCOD,"ZY5_DESCR"),;// - Descrição Justificativa
			ZY3->ZY3_SEQUEN,;          // - Sequencia
			ZY3->ZY3_HRMONI,;          // - Hora Monitoramento
			ZY3->ZY3_ORIGEM})          // - Origem
		Next

		If Len(_aLista) > 0

			IncProc("Montando o relatório...")

			_cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
			_cNomeArq  := "MONITOR_PV_" +  _cDataHora + ".xls"
			_cTitulo   := "Relatório do Monitor Pedido de Vendas"
			//===============================================================
			// Gerando relatório em Excel para envio de e-mail
			//===============================================================
			U_ITGEREXCEL(_cNomeArq,_cDirExcel,_cTitulo,_cTitulo,_aCabec,_aLista,.F.,,,.T.)

			If File(_cDirExcel+"\"+_cNomeArq) .And. U_MOMS048F(_cDirExcel+"\"+_cNomeArq)

				If _lTela
					If U_ITMsg("Arquivo: " + _cDirExcel + "\" + _cNomeArq + ", gerado com sucesso!",'Atenção!',"DESEJA ENVIAR O E-MAIL",2,2,3,,"CONFIRMA","SAIR") // OK
						IncProc("Enviando por e-mail...")
						U_MOMS048D(cGetPara, cGetCc, cGetAssun, _cHtml, _cDirExcel+"\"+_cNomeArq)
					EndIf
				Else
					U_ItConOut("Arquivo: " + _cDirExcel + "\" + _cNomeArq + ", gerado com sucesso!" )
					U_MOMS048D(cGetPara, cGetCc, cGetAssun, _cHtml, _cDirExcel+"\"+_cNomeArq)
				EndIf

			Else
				If _lTela
					U_ITMsg("Falha na Geração do Arquivo: " + _cDirExcel + "\" + _cNomeArq + "." ,'Atenção!',,1)
				Else
					U_ItConOut("Falha na Geração do Arquivo: " + _cDirExcel + "\" + _cNomeArq + "." )
				EndIf
			EndIf
		Else
			U_ITMsg("Não há dados para geração do relatório e envio do e-mail.", "Atenção", ,1)
		EndIf

	End Sequence


Return

/*
===============================================================================================================================
Programa----------: MOMS048D
Autor-------------: Alex Wallauer
Data da Criacao---: 18/11/2019
===============================================================================================================================
Descrição---------: Rotina de envio de relatório em Excel por e-mail da Gestão de carteira de pedidos.
===============================================================================================================================
Parametros--------: _cEmail      = E-mail de destino
                    _cEmailCC    = E-mail em cópia
                    _cAssunto    = Assunto do e-mail
                    _cHtml       = Conteúdo do e-mail
                    _cArqEnv     = Diretório + Nome do arquivo a ser enviado.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS048D(_cEmail, _cEmailCC , _cAssunto, _cHtml , _cArqEnv)
	Local _aConfig	:= U_ITCFGEML('') // Configurações do servidor de envio de e-mail.
	Local _cEmlLog := ""

	Begin Sequence

		U_ITENVMAIL( "workflow@italac.com.br", _cEmail, _cEmailCC ,, _cAssunto, _cHtml     , _cArqEnv, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

		_cEmlLog := Upper(_cEmlLog)

		If !Empty( _cEmlLog ) .And. "SUCESSO" $ _cEmlLog
			If _lTela
				U_ITMsg("E-mail enviado com SUCESSO PARA: "+_cEmail+","+_cEmailCC,'Atenção!',_cEmlLog,2) // OK
			Else
				U_ItConOut("Envio de e-mail Relatório do Relatorio Gestão de Carteira de Pedidos de Vendas.")
				U_ItConOut(_cEmail+" " + _cAssunto )
				U_ItConOut(_cEmlLog)
			EndIf
		Else
			If _lTela
				U_ITMsg("E-mail NAO ENVIADO PARA: "+_cEmail,'Atenção!',_cEmlLog,1)
			Else
				U_ItConOut("Falha no envio de e-mail do Relatório Gestão de Carteira de Pedidos de Vendas.")
				U_ItConOut(_cEmail+" " + _cAssunto )
				U_ItConOut(_cEmlLog)
			EndIf
		EndIf

	End Sequence

Return


/*
===============================================================================================================================
Programa----------: MOMS048F
Autor-------------: Alex Wallauer
Data da Criacao---: 18/11/2019
===============================================================================================================================
Descrição---------: Realiza uma pausa e tenta abrir o arquivo passado por parâmetro para ver se já está disponível 
                    para ser enviado por e-mail.
===============================================================================================================================
Parametros--------: _cArqRelat = Arquivo de relatório a ser testado.
===============================================================================================================================
Retorno-----------: _lRet = .T. - arquivo aberto com sucesso.
                            .F. - não conseguiu abrir o arquivo.
===============================================================================================================================
*/
User Function MOMS048F(_cArqRelat)
	Local _lRet := .F.
	Local _nHandle
	Local _nTempo := 0 , _nTempoTot := 30000

	Begin Sequence
		While _nTempo <= _nTempoTot
			// Abre o arquivon
			_nHandle := FT_FUse(_cArqRelat)

			If _nHandle <> -1
				_lRet := .T.
				Break
			EndIf

			_nTempo += 1000
			Sleep(1000)  // Faz uma pausa de 1 segundo.
		EndDo

	End Sequence

// Fecha o Arquivo
	FT_FUSE()

Return _lRet


/*
===============================================================================================================================
Programa----------: MOMS48Dias()
Autor-------------: Alex Wallauer
Data da Criacao---: 08/12/2020
===============================================================================================================================
Descrição---------: Busca  tempo Transit time
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _nDiasOP - tempo Transit time
===============================================================================================================================
*/
Static Function MOMS48Dias()
	Local _cTpVen    := ""
	Local _cfilft    := ""
	Local _cLocal    := ""
	Local _cMesoReg  := ""
	Local _cMicroReg := ""
	Local _cCodMunic := ""
	Local _cEstado   := ""
	Local _lBusca_2  := .F.
	Local _lAchou    := .F.
	Local _cRegra    := ""
	Local _nDiasTrTi := 0


	_nDiasOP := 0
	_nDiasTT := 0

	SA1->(DBSeek(_cfilft + SC5->C5_CLIENTE + SC5->C5_LOJACLI))

	_cTpVen    := SC5->C5_I_TPVEN
	_cfilft    := xFilial("SC5")
	_cLocal    := SC6->C6_LOCAL
	_cMesoReg  := "" //Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MESO")
	_cMicroReg := "" //Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MICR")
	_cCodMunic := SA1->A1_COD_MUN
	_cEstado   := SA1->A1_EST
	_lBusca_2  := .F.
	_lAchou    := .F.
	_cRegra    := ""

	If !Empty(_cLocal)

		ZG5->(DBSetOrder(3))
		If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
			_lAchou   := .T.
			_lBusca_2 := .F.
			//_cRegra   := "Regra Armazem/Estado/Mesoregiao/Microregiao/Municipio""
		ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg))
			_lAchou   := .T.
			_lBusca_2 := .F.
			//_cRegra   := "Regra Armazem/Estado/Mesoregiao/Microregiao"
		ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg))
			_lAchou   := .T.
			_lBusca_2 := .F.
			//_cRegra   := "Regra Armazem/Estado/Mesoregiao"
		ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado))
			_lAchou   := .T.
			_lBusca_2 := .F.
			//_cRegra   := "Regra Armazem/Estado"
		Else
			_lBusca_2 := .T.
		EndIf

	Else

		_lBusca_2 := .T.

	EndIf

	If _lBusca_2

		ZG5->(DBSetOrder(2))
		If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
			_lAchou := .T.
			//_cRegra := "Regra Estado/Mesoregiao/Microregiao/Municipio"
		ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg))
			_lAchou := .T.
			//_cRegra := "Regra Estado/Mesoregiao/Microregiao"
		ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg))
			_lAchou := .T.
			//_cRegra := "Regra Estado/Mesoregiao"
		ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado))
			_lAchou := .T.
			//_cRegra := "Regra Estado"
		Else
			_lAchou := .F.
		EndIf

	EndIf

	If _lAchou

		_nDiasTrTi := IIf(_cTpVen == "F", ZG5->ZG5_DIAS , IIf(ZG5->ZG5_FRDIAS >0,ZG5->ZG5_FRDIAS,ZG5->ZG5_DIAS))

		_nDiasOP := ZG5->ZG5_TMPOPE
		_nDiasTT := _nDiasTrTi

	Else

		_nDiasOP := 0
		_nDiasTT := 0

	EndIf

Return _nDiasOP

/*
===============================================================================================================================
Programa----------: MOMS48Valor()
Autor-------------: Jerry
Data da Criacao---: 11/12/2020
===============================================================================================================================
Descrição---------: Busca Valor total do Pedido 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _nValor - Valor Total do Pedido 
===============================================================================================================================
*/
Static Function MOMS48Valor(_cFilial, _cNum )
	_nTotalPedido := 0

	If SC6->(DBSeek(_cFilial+_cNum))
		While SC6->(!Eof()) .And. SC6->C6_FILIAL == AllTrim(_cFilial) .And. SC6->C6_NUM == AllTrim(_cNum)
			_nTotalPedido := _nTotalPedido + (SC6->C6_QTDVEN * SC6->C6_PRCVEN )
			SC6->(DBSkip())
		EndDo
	EndIf

Return _nTotalPedido


/*
===============================================================================================================================
Programa--------: MOMS48CAP
Autor-----------: Igor Melgaço
Data da Criacao-: 19/02/2020
===============================================================================================================================
Descrição-------: Retorna a capacidade da unidade
===============================================================================================================================
Parametros------: oProc - objeto para o carregamento do FWMsgRun quando a tela estiver ativa.
===============================================================================================================================
Retorno---------: _aTotais - Array contendo a capacidade da unidade.
===============================================================================================================================*/
Static Function MOMS48CAP()
	Local _cQuery   := ""
	Local _aTotais  := {}
	Local _cAlias2  := GetNextAlias()
	Local _cFilPrc  := U_ITGetMV("IT_FILPROC",'01')
	Local _cTpOper  := U_ITGetMv("IT_TPOPER", '01;05')
	Local _dHoje     := Date()
    Local _dDataValida := DataValida( _dHoje - 1 ) //só dias úteis
	Local _cTime     := Time()
    Local _cTamMicro := Space(TamSX3("Z25_MICRO")[1])
    Local _cTamMeso  := Space(TamSX3("Z25_MESO")[1])
    Local _cTamCMun  := Space(TamSX3("Z25_CODMUN")[1])

	Private _cVinc  := DToS(_dHoje)+SubStr(_cTime,1,5)

	Private _aProd := {}	
	
	_cQuery := "SELECT C5_FILIAL, SUM(C6_QTDVEN) TOTAL, (Case WHEN C5_I_AGEND = 'M' THEN 1 Else Case WHEN C5_I_AGEND = 'A' THEN 1 Else Case WHEN Z25_COD IS NUll THEN 2 Else 2 END END END) TIPO "
    _cQuery += "FROM " + RetSqlName("SC5") + " C5 "
    _cQuery += "	JOIN " + RetSqlName("SC6") + " SC6 ON C6_FILIAL = C5_FILIAL AND C6_NUM = C5_NUM AND SC6.D_E_L_E_T_ = ' ' "
	_cQuery += "	JOIN " + RetSqlName("SD2") + " SD2 ON D2_FILIAL = C6_FILIAL AND D2_PEDIDO = C6_NUM AND D2_ITEMPV = C6_ITEM AND SD2.D_E_L_E_T_ = ' ' "
    _cQuery += "	JOIN " + RetSqlName("SA1") + " SA1 ON C5_CLIENTE = A1_COD AND C5_LOJACLI = A1_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	_cQuery += "    JOIN " + RetSqlName("CC2") + " CC2 ON CC2_EST = A1_EST AND A1_COD_MUN = CC2_CODMUN AND CC2.D_E_L_E_T_ = ' ' "
	_cQuery += "    LEFT JOIN " + RetSqlName("Z25") + " Z25 ON ( (A1_EST = Z25_EST AND CC2_I_MESO = Z25_MESO AND CC2_I_MICR = Z25_MICRO AND A1_COD_MUN = Z25_CODMUN  AND Z25.D_E_L_E_T_ = ' ') "
	_cQuery += "						OR (A1_EST = Z25_EST AND CC2_I_MESO = Z25_MESO AND CC2_I_MICR = Z25_MICRO  AND Z25_CODMUN = '"+_cTamCMun+"' AND Z25.D_E_L_E_T_ = ' ') "
	_cQuery += "						OR (A1_EST = Z25_EST AND CC2_I_MESO = Z25_MESO AND Z25_MICRO = '"+_cTamMicro+"'  AND Z25_CODMUN = '"+_cTamCMun+"'  AND Z25.D_E_L_E_T_ = ' ' ) "
	_cQuery += "						OR (A1_EST = Z25_EST AND Z25_MESO = '"+_cTamMeso+"' AND Z25_MICRO = '"+_cTamMicro+"'  AND Z25_CODMUN = '"+_cTamCMun+"'  AND Z25.D_E_L_E_T_ = ' ') ) "
    _cQuery += "WHERE C5_TIPO = 'N' " 
	_cQuery += "AND C5_NOTA <> ' ' "
	_cQuery += "AND C5_TPFRETE <> 'F' "
	_cQuery += "AND C5_I_AGEND NOT IN ('P','R','N') "
    _cQuery += "AND D2_EMISSAO = '"+DToS(_dDataValida)+"' "

	If _lTela
       _cFilPrc:=MV_PAR02
	   _cQuery += "AND C5_FILIAL IN " + FormatIn(_cFilPrc, ";") + " " 
	Else
		_cQuery += "AND C5_FILIAL IN " + FormatIn(_cFilPrc, ";") + " " 
	EndIf

	_cQuery += "AND C5_I_OPER IN " + FormatIn(_cTpOper, ",") + " " 
	_cQuery += "AND C5.D_E_L_E_T_  = ' ' " 
    _cQuery += "AND EXISTS (SELECT 'y' FROM " +RetSqlName("SC6") +" C6, " + RetSqlName("SB1") + " B1 WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM AND B1.D_E_L_E_T_ = ' '  AND B1.B1_FILIAL = ' ' AND B1.B1_COD = C6.C6_PRODUTO AND B1_TIPO = 'PA' ) "	
    _cQuery += "GROUP BY  C5_FILIAL,Case WHEN C5_I_AGEND = 'M' THEN 1 Else Case WHEN C5_I_AGEND = 'A' THEN 1 Else Case WHEN Z25_COD IS NUll THEN 2 Else 2 END END END "
	_cQuery += "ORDER BY C5_FILIAL " 
    
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias2 , .T. , .F. )

	(_cAlias2)->(DBGoTop())
	If(_cAlias2)->(Eof())
		U_ITConOut("MOMS048 - Não existe pedidos para processamento.")
		Return _aTotais
	EndIf
	
	While (_cAlias2)->(!Eof())
		
		aAdd(_aTotais, {(_cAlias2)->C5_FILIAL, (_cAlias2)->TOTAL, (_cAlias2)->TIPO})
		
		(_cAlias2)->(DBSkip())
	EndDo

	(_cAlias2)->(DBCloseArea())
 
Return _aTotais
