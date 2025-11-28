/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função U_ITEncode por FWHttpEncode
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
=============================================================================================================================================================================================
Jerry    - Julio Paz     - 29/09/25 - 05/11/25 - 52216   - Alterar a rotina para encerrar o processamento quanto não existirem dados de pedidos do portal para liberação e para o workflow.
=============================================================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MOMS057
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/12/2020
Descrição---------: Rotina que lista pedidos de vendas do portal pendentes de aprovação e envia por e-mail via Workflow,
                    para coordenadores ou gerentes. Chamado 33098.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS057()
Local lWFHTML		:= .T.
Local _aTables		:= {"SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1","SZW"}
Local _cQry, _aDados, _cCodVend, _nI 
Local _cCodSup, _cEmailSup, _aDadosEnv
Local _cNomeSup, _LigaDesWS 
Local _nDiaEnvWF, _cEmailAdi
Local _cHora //, _aData
Local _cCoord, _cNomeCoord

Private _cHostWF	:= ""
Private _dDtIni		:= ""
Private cLogo		:= ""

Begin Sequence
  
   //====================
   //Nao consome licensas
   //====================
   RPCSetType(2)

   //==========================================
   //seta o ambiente com a empresa 01 filial 01
   //==========================================   	 
   RpcSetEnv("01","01",,,,"SCHEDULE_WF_PEDIDOS_VENDAS_PORTAL ",_aTables)

   //====================================================================
   // Liga ou Desliga a integração Workflow Pedidos Vendas do Portal.
   //====================================================================
   _LigaDesWS := SuperGetMV('IT_LIGAWFP',.F.,.T.) 
   If ! _LigaDesWS
      Break 
   EndIf 

   _cHostWF := SuperGetMV("IT_WFHOSTS",.T.,"http://wfteste.italac.com.br:4034/")
   cLogo	 := _cHostWF + "htm/logo_novo.jpg"

   _cEmailCopia:=""
   _cMV_WFMLBOX:= AllTrim(GetMV('MV_WFMLBOX'))
   lWFHTML	    := GetMv("MV_WFHTML")

   PutMV("MV_WFHTML",.T.)   
   
   _nDiaEnvWF := SuperGetMV('IT_DIASWFV',.F.,2) 

   _cQry := " SELECT DISTINCT ZW_FILIAL, ZW_IDPED, ZW_VEND1, ZW_ENVWF, ZW_EMISSAO, ZW_TIMEEMI "
   _cQry += " FROM " + RetSqlName("SZW") + " SZW "
   _cQry += " WHERE SZW.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZW_STATUS <> 'R' "
   _cQry += " AND ZW_NUMPED = ' ' "
   _cQry += " AND ZW_I_HTML <> ' ' "
   _cQry += " AND ZW_BLOPRC = 'B' "  
   _cQry += " AND ZW_DTENVIO <= '" + DToS(Date() - _nDiaEnvWF) + "' " // _nDiaEnvWF
   _cQry += " ORDER BY ZW_ENVWF, ZW_VEND1 "

   If Select("TRBSZW") <> 0
	  TRBSZW->(DBCloseArea())
   EndIf

   _cQry := ChangeQuery(_cQry)
   MPSysOpenQuery(_cQry,"TRBSZW")
   
   _aDados   := {}
   _cTipoEnv := ""
   
   If ! TRBSZW->(Eof())
      _cTipoEnv := TRBSZW->ZW_ENVWF 
   EndIf 

   While !TRBSZW->(Eof())
      _cHora := U_MOMS057H(AllTrim(TRBSZW->ZW_TIMEEMI))

      //            //       1                 2               3               4             5   6   7         8                    9          10           11 
      aAdd(_aDados,{TRBSZW->ZW_FILIAL, TRBSZW->ZW_IDPED, TRBSZW->ZW_VEND1, TRBSZW->ZW_ENVWF, "", "", "",SToD(TRBSZW->ZW_EMISSAO),_cHora,TRBSZW->ZW_EMISSAO, ""})
	
	   TRBSZW->(DBSkip())
   EndDo

   SA3->(DBSetOrder(1)) // A3_FILIAL+A3_COD 

   For _nI := 1 To Len(_aDados)
  
       _cCodVend := U_ITKEY(_aDados[_nI,3],"A3_COD")
       
       If _aDados[_nI,4] == "C"
          _cCodSup := Posicione("SA3", 1, xFilial("SA3") + _cCodVend, "A3_SUPER")
       Else
          _cCodSup := Posicione("SA3", 1, xFilial("SA3") + _cCodVend, "A3_GEREN")
       EndIf 

       _cCoord     := Posicione("SA3", 1, xFilial("SA3") + _cCodVend, "A3_SUPER")
       _cNomeCoord := Posicione("SA3", 1, xFilial("SA3") + _cCoord  , "A3_NOME")

       _cEmailSup := Posicione("SA3", 1, xFilial("SA3") + _cCodSup , "A3_EMAIL")
       _cNomeSup  := Posicione("SA3", 1, xFilial("SA3") + _cCodSup , "A3_NOME")
       
       _cEmailAdi := Posicione("SA3", 1, xFilial("SA3") + _cCodSup , "A3_I_EMWF")
       If ! Empty(_cEmailAdi)
          If ! Empty(_cEmailSup)
             _cEmailSup := AllTrim(_cEmailSup) +"; "+ AllTrim(_cEmailAdi)
          Else
             _cEmailSup := AllTrim(_cEmailAdi)
          EndIf
       EndIf 
   
       _aDados[_nI,5]  := _cCodSup
       _aDados[_nI,6]  := _cEmailSup
       _aDados[_nI,7]  := _cNomeSup  
       _aDados[_nI,11] := _cNomeCoord

   Next 

   If Empty(_aDados)  
      Break
   EndIf 

   aSort(_aDados, , , { | x,y | x[5]+x[10]+x[9] < y[5]+y[10]+y[9] } )

   _cCodVend := _aDados[1,5]

   _aDadosEnv := {}

   For _nI := 1 To Len(_aDados)
      If _cCodVend <> _aDados[_nI,5]
         U_MOMS057E(_aDadosEnv)
		   _cCodVend  := _aDados[_nI,5]
		   _aDadosEnv := {}
	   EndIf 

      aAdd(_aDadosEnv , aClone(_aDados[_nI]))
   
   Next 

   If Len(_aDadosEnv) > 0
      U_MOMS057E(_aDadosEnv)
   EndIf 

 	//============================================================
	//Limpa o ambiente, liberando a licença e fechando as conexoes
	//============================================================
	RpcClearEnv()  
	
End Sequence 

If Select("TRBSZW") <> 0
   TRBSZW->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS057E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/12/2020
Descrição---------: Rotina de envio de e-mail via Workflow para coordenadores ou gerentes.
Parametros--------: _aDadosEnv {Filial do pedido, Id do pedido, Código vendedor}
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS057E(_aDadosEnv)

Local _aTotais, _nI 
Local _cCliente
Local _cDestino 
Local _cNomeDest := " "

Begin Sequence
   
   //====================================
   // Codigo do processo cadastrado no CFG
   //====================================
   _cCodProce := "PEDIDO"
      
   //======================================================================
   // Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
   //======================================================================
   _oProcess := TWFProcess():New(_cCodProce,"Aprovação de Pedido de Vendas Portal")

	_oProcess:NewTask("LINK", "\workflow\htm\pv_lista.htm")

	_cMailID	:= _oProcess:fProcessId
	_cTaskID	:= _oProcess:fTaskID

	chtmlfile	:= _cMailID + ".htm"
	
   cMailTo		:= _aDadosEnv[1,6]  
  
	chtmltexto	:= wfloadfile("\workflow\emp01\" + chtmlfile )//Carrega o arquivo 
	chtmltexto	:= StrTran( chtmltexto, cmailto, "WFHTTPRET.APL" )//Procura e troca a string
	wfsavefile("\workflow\emp"+cEmpAnt+"\" + chtmlfile, chtmltexto)//Grava o arquivo de volta
			
	RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1001", "Lista de Pedidos de Vendas do Portal Pendente Aprovação", "")
   
   SZW->(DBSetOrder(1)) // ZW_FILIAL+ZW_IDPED 

   _cDestino := ""

   For _nI := 1 To Len(_aDadosEnv)
       If Empty(_cDestino)
          If _aDadosEnv[_nI,4] == "C"
             _cDestino := "Coordenador: " +_aDadosEnv[_nI,5] + " - " + _aDadosEnv[_nI,7]
             _cNomeDest := _aDadosEnv[_nI,7]
          Else
             _cDestino := "Gerente: " +_aDadosEnv[_nI,5] + " - " + _aDadosEnv[_nI,7]
             _cNomeDest := _aDadosEnv[_nI,7]
          EndIf 
       EndIf 

       _cNomeVend  := Posicione("SA3", 1, xFilial("SA3") + _aDadosEnv[_nI,3] , "A3_NOME") // _aDadosEnv[_nI,7]

       SZW->(MsSeek(U_ITKEY(_aDadosEnv[_nI,1],"ZW_FILIAL") + U_ITKEY(_aDadosEnv[_nI,2],"ZW_IDPED")))
     
       _aTotais :=  U_MOMS057T(_aDadosEnv[_nI,1],_aDadosEnv[_nI,2])

       _cCliente := AllTrim(Posicione("SA1", 1, xFilial("SA1") + SZW->(ZW_CLIENTE + ZW_LOJACLI), "A1_NOME"))

       aAdd( _oProcess:oHtml:ValByName("itens.COORDENA")	, _aDadosEnv[_nI,11]	) // aAdd( _oProcess:oHtml:ValByName("itens.COORDENA")	, _aDadosEnv[_nI,7]	) 
	    aAdd( _oProcess:oHtml:ValByName("itens.PEDIDO")	, _aDadosEnv[_nI,2]	)
		 aAdd( _oProcess:oHtml:ValByName("itens.VENDEDOR")	, _cNomeVend)
		 aAdd( _oProcess:oHtml:ValByName("itens.EMISSAO")	, DToC(SZW->ZW_EMISSAO) + "  " + _aDadosEnv[_nI,9] )
		 aAdd( _oProcess:oHtml:ValByName("itens.CLIENTE")	, _cCliente )
       aAdd( _oProcess:oHtml:ValByName("itens.LINK")	   , SZW->ZW_I_HTML )
       aAdd( _oProcess:oHtml:ValByName("itens.cTxtLnk")	, "Clique Aqui!"	)

   Next 

   _oProcess:oHtml:ValByName("AprNom"  , AllTrim(_cNomeDest))
	_oProcess:oHtml:ValByName("cLogo"	, cLogo		 )

	_cAssunto := "Lista de Pedidos de Vendas do Portal Pendente Aprovação. " + _cDestino
   
	//====================================================
	// Informamos o destinatário do email contendo o link.  
	//====================================================
	_oProcess:cTo  :=  cMailTo //02 - lista de PC's por Aprovador 

	//===============================
	// Informamos o assunto do email.  
	//===============================
	_oProcess:cSubject	:= FWHttpEncode(_cAssunto)

	_cMailID	:= _oProcess:fProcessId
	_cTaskID	:= _oProcess:fTaskID
	RastreiaWF(_cMailID + '.' + _cTaskID , _oProcess:fProcCode, "1004", "Lista de Pedidos de Vendas do Portal Pendente Aprovação", "")

	//=======================================================
	// Iniciamos a tarefa e enviamos o email ao destinatário.
	//=======================================================
	_oProcess:Start()


End Sequence

Return

/*
===============================================================================================================================
Programa----------: MOMS057T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/12/2020
Descrição---------: Calcula os tatais dos pedidos de vendas do portal.
Parametros--------: _cCodFilial = Filial do pedido
                    _cIdPedidoV = Id do pedido
Retorno-----------: _aRet = {Valor total, Peso total}
===============================================================================================================================
*/
User Function MOMS057T(_cCodFilial, _cIdPedidoV)

Local _aRet := {0,0}
Local _nRecAtu := SZW->(Recno())

Begin Sequence
   SB1->(DBSetOrder(1)) // B1_FILIAL+B1_COD

   SZW->(DBSetOrder(1)) // ZW_FILIAL+ZW_IDPED 

   SZW->(MsSeek(_cCodFilial + _cIdPedidoV))

   _nVlrTot	  := 0
   _nPesoTot  := 0

   While ! SZW->(Eof()) .And. SZW->(ZW_FILIAL+ZW_IDPED) == _cCodFilial + _cIdPedidoV
      SB1->(MsSeek(xFilial("SB1")+SZW->ZW_PRODUTO))

      _nVlrTot	  += (SZW->ZW_QTDVEN * SZW->ZW_PRCVEN)
      _nPesoTot  += (SZW->ZW_QTDVEN * SB1->B1_PESBRU)   

      SZW->(DBSkip())
   EndDo
   
   _aRet := {_nVlrTot, _nPesoTot}

End Sequence

SZW->(DBGoTo(_nRecAtu))

Return _aRet

/*
===============================================================================================================================
Programa----------: MOMS057H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/12/2020
Descrição---------: Calcular e retornar a hora de campos do tipo datetime, gerados pela função FWTimeStamp().
                    A função FWDateTimeToLocal() que retorna um array com a data e a hora deste tipo de campo não está 
                    funcionando. Estava sempre retornando a Hora atual.
Parametros--------: _cDataHora = gerado pela função FWTimeStamp().
Retorno-----------: _cHora = A hora do campo.
===============================================================================================================================
*/
User Function MOMS057H(_cDataHora)

Local _cHora := "00:00"
Local _nFator1 := 60
Local _nFator2 := 60
Local _nFator3 := 24  
Local _nResultado
Local _nHora 
Local _nMinuto 
Local _nDataHora
Local _nHorario 

Begin Sequence
   If Empty(_cDataHora)
      Break 
   EndIf 

   _nDatahora := Val(_cDataHora)
   If _nDatahora == 0
      Break 
   EndIf 

   _nResultado := _nDatahora / _nFator1 / _nFator2 / _nFator3 
   _nHorario   := _nResultado - Int(_nResultado)
   _nHora      := _nHorario * 24 
   _nMinuto    := (_nHora - Int(_nHora)) * 60
   _nHora      := Int(_nHora) - 3
   
   If _nHora < 0
      _nHora := _nHora + 24
   EndIf 

   _cHora      := StrZero(Int(_nHora),2) + ":" + StrZero(Int(_nMinuto),2)

End Sequence 

Return _cHora
