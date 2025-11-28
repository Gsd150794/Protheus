/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/06/2025| Chamado 45229. Desenvolvimento do novo webservice OMS-Protheus x TMS-Multiembarcador.
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.Ch"

/*
===============================================================================================================================
Função------------: AOMS146A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de Envio de Notas Fiscais e Vinculação de Pedidos de Vendas com Notas Fiscais para Pedidos de 
                    Vendas do Tipo Troca Nota Fiscal. Chamado 46163.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146A(_lScheduller)

Local _cFilHabil := SuperGetMV('IT_FILINTW',.F.,'') // Filiais habilitadas na integracao Webservice Italac x TMS Multi-Embarcador
Local _cQry        := ""
Local _dDtAtvTms := Ctod(SuperGetMV( 'IT_DTATTMS',.F.,'01/10/2023'))
Local _nRegAtu := 0
Local _nTotRegs
Local _lSC5_PEDPA   := .F.
Local _cSC5_I_CDTMS := ""

Begin Sequence 
 
   If !_lScheduller .And. ! U_ITMsg("Confirma a gravação de dados de XML das notas fiscais dos pedidos de vendas troca nota, para envio para o TMS MultiEmbarcador? ","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146A] - Inicio gravação dos dados de XML das notas fiscais dos pedidos de vendas troca nota, para envio para o TMS MultiEmbarcador.")      
   EndIf
   
   //=================================================================
   // Query para gerar registros na tabela ZFK com ZFK_TIPOI = '7' 
   //=================================================================
   _cQry := " SELECT DISTINCT DAK.DAK_FILIAL, " 
   _cQry += " DAK.DAK_COD, " 
   _cQry += " DAI.DAI_NFISCA, " 
   _cQry += " ZFQ_CARTMS, " 
   _cQry += " ZFQ_PEDIDO, " 
   _cQry += " ZFQ_RASTMS, " 
   _cQry += " SPED50.R_E_C_N_O_     NREC50, " 
   _cQry += " SF2.R_E_C_N_O_        NRECSF2, " 
   _cQry += " SPED54.R_E_C_N_O_     NREC54, " 
   _cQry += " DAK.R_E_C_N_O_        NRECDAK " 
   _cQry += " FROM "+RetSqlName("DAK") + " DAK, "
   _cQry +=          RetSqlName("DAI") + " DAI, "
   _cQry +=          RetSqlName("ZFQ") + " ZFQ, " 
   _cQry +=          RetSqlName("SF2") + " SF2, "
   _cQry +=         " SPED050 SPED50, " 
   _cQry +=         " SPED054 SPED54 " 
   _cQry += " WHERE  DAK.DAK_FILIAL IN " + FormatIn(_cFilHabil,";") // Filiais do parâmetro IT_WEBSTMS
   _cQry += " AND DAK.DAK_DATA >= '" + DToS(_dDtAtvTms) +"' "
   _cQry += " AND DAK.DAK_I_TRNF IN ('C', 'F') "
   _cQry += " AND DAK.D_E_L_E_T_ = ' '  "
   _cQry += " AND DAI.DAI_FILIAL = DAK.DAK_FILIAL " 
   _cQry += " AND DAI.DAI_COD = DAK.DAK_COD "
   _cQry += " AND DAI.D_E_L_E_T_ = ' ' "
   _cQry += " AND SF2.F2_FILIAL = DAI.DAI_FILIAL "
   _cQry += " AND SF2.F2_DOC = DAI.DAI_NFISCA "
   _cQry += " AND SF2.F2_SERIE = DAI.DAI_SERIE "
   _cQry += " AND SF2.D_E_L_E_T_ = ' ' "
   _cQry += " AND DOC_CHV = F2_CHVNFE "
   _cQry += " AND NFE_CHV = F2_CHVNFE "
   _cQry += " AND SPED50.STATUS = '6' "
   _cQry += " AND SPED54.CSTAT_SEFR = '100' "
   _cQry += " AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += " AND SPED54.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZFQ.ZFQ_FILIAL = DAK.DAK_FILIAL "
   _cQry += " AND ZFQ.ZFQ_NCARGA = DAK.DAK_COD "
   _cQry += " AND ZFQ.ZFQ_NUMNFE = DAI.DAI_NFISCA "
   _cQry += " AND ZFQ.ZFQ_SERINF = DAI.DAI_SERIE "
   _cQry += " AND ZFQ.ZFQ_SITUAC = 'P' "
   _cQry += " AND ZFQ.D_E_L_E_T_ = ' ' "
   _cQry += " AND NVL ( "
   _cQry += " (SELECT COUNT (1) "
   _cQry += " FROM " + RETSQLNAME("DAI") + " DAIC "
   _cQry += " WHERE DAIC.DAI_FILIAL = DAK.DAK_FILIAL "
   _cQry += " AND DAIC.DAI_COD = DAK.DAK_COD "
   _cQry += " AND DAIC.D_E_L_E_T_ = ' '), "
   _cQry += " 0) = "
   _cQry += " NVL ( "
   _cQry += " (SELECT COUNT (1) "
   _cQry += " FROM " + RETSQLNAME("DAI") + " DAIC, "
   _cQry += RETSQLNAME("SF2") + " SF2B, "
   _cQry += " SPED050 SPED50, "
   _cQry += " SPED054 SPED54 "
   _cQry += " WHERE DAIC.DAI_FILIAL = DAK.DAK_FILIAL "
   _cQry += " AND DAIC.DAI_COD = DAK.DAK_COD "
   _cQry += " AND DAIC.D_E_L_E_T_ = ' ' "
   _cQry += " AND SF2B.F2_FILIAL = DAIC.DAI_FILIAL "
   _cQry += " AND SF2B.F2_DOC = DAIC.DAI_NFISCA "
   _cQry += " AND SF2B.F2_SERIE = DAIC.DAI_SERIE "
   _cQry += " AND SF2B.F2_I_PRTMS <> ' ' "
   _cQry += " AND SF2B.D_E_L_E_T_ = ' ' "
   _cQry += " AND DOC_CHV = F2_CHVNFE "
   _cQry += " AND NFE_CHV = SF2B.F2_CHVNFE "
   _cQry += " AND SPED50.STATUS = '6' "
   _cQry += " AND SPED54.CSTAT_SEFR = '100' "
   _cQry += " AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += " AND SPED54.D_E_L_E_T_ = ' '), "
   _cQry += " 0) "
   _cQry += " AND EXISTS "
   _cQry += " (SELECT 'x' "
   _cQry += " FROM " + RETSQLNAME("ZFQ") + " ZFQF "
   _cQry += " WHERE ZFQF.ZFQ_FILIAL = DAK.DAK_FILIAL "
   _cQry += " AND ZFQF.ZFQ_NCARGA = DAK.DAK_COD "
   _cQry += " AND ZFQF.ZFQ_SITUAC = 'E' "
   _cQry += " AND ZFQF.D_E_L_E_T_ = ' ') "
   _cQry += " AND NOT EXISTS "
   _cQry += " (SELECT 'X' "
   _cQry += " FROM " + RETSQLNAME("ZFK") + " ZFK "
   _cQry += " WHERE ZFK.ZFK_FILIAL = DAI.DAI_FILIAL "
   _cQry += " AND ZFK.ZFK_PEDIDO = DAI.DAI_PEDIDO "
   _cQry += " AND ZFK.ZFK_TIPOI = '7' "
   _cQry += " AND ZFK.D_E_L_E_T_ = ' ') "
   _cQry += " ORDER BY ZFQ_CARTMS, ZFQ_RASTMS "

   _cQry := ChangeQuery(_cQry)         

   If Select("NFETNF") > 0
      NFETNF->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"NFETNF")
   
   DBSelectArea("NFETNF")                                                                               
   COUNT To _nTotRegs

   If !_lScheduller 
      ProcRegua(_nTotRegs)
   EndIf

   NFETNF->(DBGoTop())
   
   If _nTotRegs == 0
      Break 
   EndIf 
   
   //===================================================================================================
   // Abre o arquivo de Sped para leitura dos XML e Envio para o TMS MultiEmbarcador.
   //===================================================================================================
   If Select("SPED050") > 0
      SPED050->( DBCloseArea() )
   EndIf     
         
   USE SPED050 ALIAS SPED050 SHARED NEW VIA "TOPCONN" 
         
   If Select("SPED054") > 0
      SPED054->( DBCloseArea() )
   EndIf     
         
   USE SPED054 ALIAS SPED054 SHARED NEW VIA "TOPCONN" 
         
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM

   _nRegAtu := 0

   While ! NFETNF->(Eof()) 

      _nRegAtu++

      If !_lScheduller 
         IncProc("Lendo dados Notas Fiscais-Pedidos V.Troca Nota: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      Else
         U_ITCONOUT("[AOMS146A] - Lendo dados Notas Fiscais-Pedidos V.Troca Nota: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))
      EndIf

      SF2->(DBGoTo(NFETNF->NRECSF2)) 
      DAK->(DBGoTo(NFETNF->NRECDAK))
      SPED054->(DBGoTo(NFETNF->NREC54))
      SPED050->(DBGoTo(NFETNF->NREC50))

      If SC5->( DBSeek( SF2->F2_FILIAL + SF2->F2_I_PEDID ) )
         _lSC5_PEDPA   := (SC5->C5_I_PEDPA == "S")
         _cSC5_I_CDTMS := SC5->C5_I_CDTMS
      Else
         _lSC5_PEDPA   := .F.
         _cSC5_I_CDTMS := ""
      EndIf

      If Empty(_cSC5_I_CDTMS) // Pedido de Vendas não integrado para o TMS MultiEmbarcador.
         NFETNF->(DBSkip())
         Loop
      EndIf 

      //===================================================================================================
      // Monta XML para envio ao TMS MultiEmbarcador.
      //===================================================================================================   
                                 
      _cXmlNfe := SPED050->XML_SIG
            
      _cProtNfe := SPED054->XML_PROT
                                                         
      _nIni := AT( "<infNFe", _cXmlNfe ) 
      _nFim := AT( "</NFe>", _cXmlNfe ) 
      _cPart1Xml := SubStr(_cXmlNfe,_nIni,_nFim - _nIni)
                                                          
      _nIni := AT( "<protNFe", _cProtNfe ) 
      _nFim := AT( "</protNFe>", _cProtNfe ) 
      _cPart2Xml := SubStr(_cProtNfe,_nIni,_nFim + 11)
            
      _cXmlEnv := '<?xml version="1.0" encoding="UTF-8"?> <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="3.10"> <NFe>  '
      _cXmlEnv := _cXmlEnv + _cPart1Xml + "</NFe>" + _cPart2Xml + '   </nfeProc> '
                  
      _cXML_Nfe := _cXmlEnv

      ZFK->(RecLock("ZFK",.T.))
      ZFK->ZFK_FILIAL := SF2->F2_FILIAL
      ZFK->ZFK_CARGA  := DAK->DAK_COD
      ZFK->ZFK_CARTMS := DAK->DAK_I_PTMS // DAK->DAK_I_RECR 
      ZFK->ZFK_PRTPED := NFETNF->ZFQ_RASTMS //_cSC5_I_CDTMS 
      ZFK->ZFK_DATA   := Date()  
      ZFK->ZFK_HORA   := Time()
      ZFK->ZFK_TIPOI  := "7"
      ZFK->ZFK_CHVNFE := SF2->F2_CHVNFE
      ZFK->ZFK_PEDPAL := IIf(_lSC5_PEDPA ,"S","N") 
      ZFK->ZFK_NRPPAL := IIf(_lSC5_PEDPA ,SF2->F2_I_PEDID ,"")    
      ZFK->ZFK_CGC    := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_CGC") 
      ZFK->ZFK_PEDIDO := NFETNF->ZFQ_PEDIDO // SC5->C5_NUM 
      ZFK->ZFK_COD	  := SF2->F2_CLIENTE    
      ZFK->ZFK_LOJA   := SF2->F2_LOJA       
      ZFK->ZFK_NOME   := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME") 
      ZFK->ZFK_USUARI := __cUserId
      ZFK->ZFK_SITUAC := "N" 
      ZFK->ZFK_XML    := _cXML_Nfe
      ZFK->(MSUnLock())

      NFETNF->(DBSkip())
   EndDo

End Sequence

If !_lScheduller 
   U_ITMsg("Termino da gravação dos dados das notas fiscais Pedidos de Vendas Troca NF - Protheus x TMS MultiEmbarcador.","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146A] - Termino da gravação dos dados das notas fiscais Pedidos de Vendas Troca NF - Protheus x TMS MultiEmbarcador.")
EndIf

If Select("NFETNF") > 0
   NFETNF->( DBCloseArea() )
EndIf

If Select("SPED050") > 0
   SPED050->( DBCloseArea() )
EndIf     

If Select("SPED054") > 0
   SPED054->( DBCloseArea() )
EndIf  

Return 

/*
===============================================================================================================================
Função------------: AOMS146B
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de transmissão de dados de Notas Fiscais e Vinculação de Pedidos de Vendas com Notas Fiscais para 
                    Pedidos de Vendas do Tipo Troca Nota Fiscal. Chamado 46163.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146B(_lScheduller) 

Local _cQry      := ""
Local _cFilHabil := SuperGetMV('IT_FILINTW',.F.,'')
Local _cCanPXML
Local _cDirXML
Local _cLink
Local _cCodEmpWS
Local _cXML
Local _lOk           := .F.
Local _cResult       := ""
Local _cProtocolo    := ""
Local oWsdl

Private _cToken

Begin Sequence 
   
   If !_lScheduller .And. ! U_ITMsg("Confirma envio de arquivos XML das Notas Fiscais para Pedidos de Vendas Troca Nota Fiscal, para o Sistema TMS MultiEmbarcador?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146B] Inicio do envio de arquivos XML das Notas Fiscais para Pedidos de Vendas Troca Nota Fiscal, para o Sistema TMS MultiEmbarcador.")   
   EndIf

   //=====================================================================
   // Obtem o token de acesso ao sistema multi embarcador.
   //=====================================================================
   _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

   //================================================================================
   // Retorna Codigo Empresa WebService TMS-MULTI EMBARCADOR.
   //================================================================================                    
   _cCodEmpWS := SuperGetMV('IT_EMPTMSM',.F.,"000005")
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cCodEmpWS))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK02)  // Link de envio dos dados da nota fiscal.
   Else
      If ! _lScheduller
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146B] Empresa WebService para envio dos dados não localizada.")
      EndIf
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lExibeTela
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146B] Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      EndIf
      
      Break                                     
   EndIf
      
   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo XML e os transforma em String.
   //================================================================================
   _cCanPXML := U_AOMS146X(_cDirXML+"enviararquivoxmlnfe_tms.txt") 
   
   If Empty(_cCanPXML)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo XML modelo de Envio de Arquivo XML NFE, para pedidos de vendas Troca Nota Fiscal. ","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146B] Erro na leitura do arquivo XML modelo de Envio de Arquivo XML NFE, para pedidos de vendas Troca Nota Fiscal. ")
      EndIf
      Break
   EndIf
 
   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.R_E_C_N_O_ NRREG "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '7' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR  ZFK_SITUAC = 'R') "
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabil),";")

   _cQry := ChangeQuery(_cQry)          

   If Select("ZFKTNF") > 0
      ZFKTNF->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKTNF")
   
   DBSelectArea("ZFKTNF")                                                                                  
   COUNT To _nTotRegs

   If !_lScheduller
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   ZFKTNF->(DBGoTop())
   
   _nRegAtu := 0

   While !ZFKTNF->(Eof()) 

      _nRegAtu++

      If !_lScheduller 
         IncProc("Enviando dados das Notas Fiscais-Pedidos Troca Nota para Envio ao TMS: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      Else
         U_ITCONOUT("[AOMS146B] - Enviando dados das Notas Fiscais-Pedidos Troca Nota para Envio ao TMS: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))
      EndIf

      ZFK->(DBGoTo(ZFKTNF->NRREG))

      _cXML_Nfe := ZFK->ZFK_XML // Variável do modelo XML

      _cXMLEnv := &(_cCanPXML)

      _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
      _nLimCarre := 100 // Número Máximo de Registros Lidos.

      oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
      oWsdl:nTimeout := 10          // Timeout de 10 segundos 
      oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

      oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
      oWsdl:SetOperation( "EnviarArquivoXMLNFe") // Define qual operação será realizada.

      // Envia para o servidor
      _lOk := oWsdl:SendSoapMsg(_cXMLEnv) // Este comando pega o XML e envia para o servidor da TMS MultiEmbarcador.  

      _cProtocolo := ""
      _cStatus    := ""         

      If _lOk 
         _cResult := oWsdl:GetSoapResponse()

         cError   := ""
         cWarning := ""

         _oXml := XmlParser(_cResult, "_", @cError, @cWarning )

         _cProtocolo := _oxml:_s_Envelope:_s_Body:_EnviarArquivoXMLNFeResponse:_EnviarArquivoXMLNFeResult:_a_Objeto:text
      Else
         _cResult := oWsdl:cError
         _cProtocolo := ""
      EndIf   

      If _lOk  .And. ! Empty(_cProtocolo)
         SF2->(RecLock("SF2",.F.))
         SF2->F2_I_DTENV := Date()
         SF2->F2_I_HRENV := Time()
         SF2->F2_I_PRTMS := _cProtocolo      //Protocolo TMS
         SF2->(MSUnLock())
      EndIf 

      ZFK->(RecLock("ZFK",.F.))
      ZFK->ZFK_DATA   := Date()  
      ZFK->ZFK_HORA   := Time()
      ZFK->ZFK_SITUAC := IIf(_lOk,"P","R")
      ZFK->ZFK_CODEMP := _cCodEmpWS
      ZFK->ZFK_RETORN := _cResult
      ZFK->ZFK_PRTMS  := _cProtocolo
      If _lOk
         ZFK->ZFK_XML    := _cXML
      EndIf
      ZFK->(MSUnLock())

      If ValType(oWSDL) == "O"
         FreeObj(oWsdl)
      EndIf 
      oWsdl := Nil
      
      ZFKTNF->(DBSkip())
   EndDo

End Sequence

If !_lScheduller 
   U_ITMsg("Termino do envio das Notas Fiscais-Pedidos Troca Nota para Envio ao TMS - Protheus x TMS MultiEmbarcador. ","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146B] - Termino do envio das Notas Fiscais-Pedidos Troca Nota para Envio ao TMS - Protheus x TMS MultiEmbarcador.  ")
EndIf

If Select("ZFKTNF") > 0
   ZFKTNF->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Função-------------: AOMS146X
Aut2or-------------: Julio de Paula Paz
Data da Criacao----: 01/08/2024
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: _cRet
===============================================================================================================================
*/  
User Function AOMS146X(_cArq)

Local _cRet := ""
Local _nStatusArq 
Local _cLine 

Begin Sequence
   _nStatusArq := FT_FUse(_cArq)
      
   // Se houver erro de abertura abandona processamento
   If _nStatusArq = -1  
      Break
   EndIf
   
   // Posiciona na primeria linha
   FT_FGoTop()

  
   While !FT_FEof()   
      _cLine  := FT_FReadLn() 
      
      _cRet +=  _cLine
   
      FT_FSKIP()
   End

   // Fecha o Arquivo
   FT_FUSE()

End Sequence

Return _cRet

/*
===============================================================================================================================
Função------------: AOMS146C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de Gravação dos Dados de Vinculação de Notas Fiscais com Pedidos de Vendas, para pedidos de 
                    Vendas Troca Nota Fiscal.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146C(_lScheduller )

Local _cQry
Local _nTotRegs 

Begin Sequence

   If !_lScheduller .And. ! U_ITMsg("Confirma a Gravação dos Dados de Vinculação de Pedidos de Vendas com Notas Fiscais, para Pedidos de Vendas Troca Nota Fiscal integrados para o TMS MultiEmbarcador?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146C] - Inicio gravação dos dados de Vinculação Pedido Vendas com NFE - Protheus x TMS MultiEmbarcador. ")      
   EndIf

   _cQry := " SELECT ZFK.R_E_C_N_O_ NRREG "  
   _cQry += " FROM " + RETSQLNAME("ZFK") + " ZFK "
   _cQry += " WHERE     ZFK_TIPOI = '7' "
   _cQry += " AND ZFK.D_E_L_E_T_ = ' ' "
   _cQry += " AND NVL ( "
   _cQry += " (SELECT COUNT (1) "
   _cQry += " FROM " + RETSQLNAME("DAI")  + " DAI "
   _cQry += " WHERE DAI.DAI_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += " AND DAI.DAI_COD = ZFK.ZFK_CARGA "
   _cQry += " AND DAI.D_E_L_E_T_ = ' '), "
   _cQry += " 0) = "
   _cQry += " NVL ( "
   _cQry += " (SELECT COUNT (1) "
   _cQry += " FROM " + RETSQLNAME("ZFK") + " ZFKB "
   _cQry += " WHERE ZFKB.ZFK_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += " AND ZFKB.ZFK_CARGA = ZFK.ZFK_CARGA "
   _cQry += " AND ZFKB.ZFK_TIPOI = '7' "
   _cQry += " AND ZFKB.ZFK_SITUAC = 'P' "
   _cQry += " AND ZFKB.D_E_L_E_T_ = ' '), "
   _cQry += " 0) "
   _cQry += " AND NOT EXISTS "
   _cQry += " (SELECT 'X' "
   _cQry += " FROM " + RETSQLNAME("ZFK") + " ZFKT "
   _cQry += " WHERE ZFKT.ZFK_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += " AND ZFKT.ZFK_PEDIDO = ZFK.ZFK_PEDIDO "
   _cQry += " AND ZFKT.ZFK_TIPOI = '8' "
   _cQry += " AND ZFKT.ZFK_SITUAC = 'P' "
   _cQry += " AND ZFKT.D_E_L_E_T_ = ' ') "
   _cQry += " ORDER BY ZFK.ZFK_CARGA, ZFK.ZFK_PEDIDO "

   _cQry := ChangeQuery(_cQry)

   If Select("ZFKVPV") > 0
      ZFKVPV->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKVPV")

   DBSelectArea("ZFKVPV")
   Count To _nTotRegs

   If !_lScheduller 
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   ZFKVPV->(DBGoTop())
   
   _nRegAtu := 0

   While ZFKVPV->(!Eof())
      _nRegAtu++

      If !_lScheduller 
         IncProc("Gravando dados de Vinculação Pedido Vendas com NFE: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))  
      Else
         U_ITCONOUT("[AOMS146C] Gravando dados de Vinculação Pedido Vendas com NFE: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))
      EndIf
      
      ZFK->(DBGoTo(ZFKVPV->NRREG))

      M->ZFK_FILIAL := ZFK->ZFK_FILIAL
      M->ZFK_CARGA  := ZFK->ZFK_CARGA 
      M->ZFK_CARTMS := ZFK->ZFK_CARTMS
      M->ZFK_PRTPED := ZFK->ZFK_PRTPED
      M->ZFK_DATA   := ZFK->ZFK_DATA  // Gravar Data Atual
      M->ZFK_HORA   := ZFK->ZFK_HORA  
      M->ZFK_TIPOI  := ZFK->ZFK_TIPOI // = "8"
      M->ZFK_CHVNFE := ZFK->ZFK_CHVNFE
      M->ZFK_PEDPAL := ZFK->ZFK_PEDPAL
      M->ZFK_NRPPAL := ZFK->ZFK_NRPPAL
      M->ZFK_CGC    := ZFK->ZFK_CGC   
      M->ZFK_PEDIDO := ZFK->ZFK_PEDIDO
      M->ZFK_COD	  := ZFK->ZFK_COD
      M->ZFK_LOJA   := ZFK->ZFK_LOJA  
      M->ZFK_NOME   := ZFK->ZFK_NOME  
      M->ZFK_USUARI := ZFK->ZFK_USUARI
      M->ZFK_SITUAC := "N" // ZFK->ZFK_SITUAC
      M->ZFK_XML    := ZFK->ZFK_XML   
      M->ZFK_PRTMS  := ZFK->ZFK_PRTMS   

      ZFK->(RecLock("ZFK",.T.))   
      ZFK->ZFK_FILIAL := M->ZFK_FILIAL 
      ZFK->ZFK_CARGA  := M->ZFK_CARGA   
      ZFK->ZFK_CARTMS := M->ZFK_CARTMS  
      ZFK->ZFK_PRTPED := M->ZFK_PRTPED
      ZFK->ZFK_DATA   := Date() 
      ZFK->ZFK_HORA   := Time() 
      ZFK->ZFK_TIPOI  := "8"
      ZFK->ZFK_CHVNFE := M->ZFK_CHVNFE
      ZFK->ZFK_PEDPAL := M->ZFK_PEDPAL  
      ZFK->ZFK_NRPPAL := M->ZFK_NRPPAL 
      ZFK->ZFK_CGC    := M->ZFK_CGC        
      ZFK->ZFK_PEDIDO := M->ZFK_PEDIDO  
      ZFK->ZFK_COD    := M->ZFK_COD	   
      ZFK->ZFK_LOJA   := M->ZFK_LOJA      
      ZFK->ZFK_NOME   := M->ZFK_NOME     
      ZFK->ZFK_USUARI := __cUserId // Codigo do Usuário
      ZFK->ZFK_DATAAL := Date()
      ZFK->ZFK_PRTMS  := M->ZFK_PRTMS
      ZFK->ZFK_SITUAC := "N"  
      ZFK->(MSUnLock()) 

      ZFKVPV->(DBSkip())
   EndDo

End Sequence

If !_lScheduller
   U_ITMsg("Termino da gravação dos dados de Vinculação Pedido Vendas com NFE - Protheus x TMS MultiEmbarcador. ","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146C] - Termino da gravação dos dados de Vinculação Pedido Vendas com NFE - Protheus x TMS MultiEmbarcador. ")      
EndIf 

If Select("ZFKVPV") > 0
   ZFKVPV->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Função------------: AOMS146D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de transmissão de dados de Vinculação de Notas Fiscais com Pedidos de Vendas Troca NF.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146D(_lScheduller)

Local _cQry      := ""
Local _cFilHabil := SuperGetMV('IT_FILINTW',.F.,'')
Local _cDirXML
Local _cLink
Local _cCodEmpWS
Local _lOk           := .F.
Local _cResult       := ""
Local oWsdl

Private _cToken

Begin Sequence 
   
   If !_lScheduller .And. ! U_ITMsg("Confirma envio de dados de vinculação de pedidos de vendas Troca NF com Notas Fiscais, para o Sistema TMS MultiEmbarcador?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146D] Inicio do envio de dados de vinculação de pedidos de vendas Troca NF com Notas Fiscais, para o Sistema TMS MultiEmbarcador")   
   EndIf

   //=====================================================================
   // Obtem o token de acesso ao sistema multi embarcador.
   //=====================================================================
   _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

   //================================================================================
   // Retorna Codigo Empresa WebService TMS-MULTI EMBARCADOR.
   //================================================================================                    
   _cCodEmpWS := SuperGetMV('IT_EMPTMSM',.F.,"000005")
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cCodEmpWS))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK02)  // Link de envio dos dados da nota fiscal.
   Else
      If ! _lScheduller
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146D] Empresa WebService para envio dos dados não localizada.")
      EndIf
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lExibeTela
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146D] Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      EndIf
      
      Break                                     
   EndIf
      
   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo XML e os transforma em String.
   //================================================================================
   _cVincPVXML := U_AOMS146X(_cDirXML+"Vincular_Pedidos_Vendas_Troca_NF_com_Notas_Fiscais_TMS.txt") 
   
   If Empty(_cVincPVXML)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo XML modelo de Envio de dados de vinculação de Pedidos de Vendas Troca NF com as Notas Fiscais - Protheus x TMS MultiEmbarcador.  ","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146D] Erro na leitura do arquivo XML modelo de Envio de dados de vinculação de Pedidos de Vendas Troca NF com as Notas Fiscais - Protheus x TMS MultiEmbarcador.  ")
      EndIf
      Break
   EndIf
 
   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.R_E_C_N_O_ NRREG "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '8' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR  ZFK_SITUAC = 'R') "
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabil),";")

   _cQry := ChangeQuery(_cQry)          

   If Select("ZFKVTNF") > 0
      ZFKVTNF->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKVTNF")
   
   DBSelectArea("ZFKVTNF")                                                                                  
   COUNT To _nTotRegs

   If !_lScheduller
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   ZFKVTNF->(DBGoTop())
   
   _nRegAtu := 0

   _aEnvioTMS := {} // Controle de Cargas Enviadas para o TMS
   _aCargaLid := {} // Controle de cargas lidas.

   While !ZFKVTNF->(Eof()) 

      _nRegAtu++

      If !_lScheduller 
         IncProc("Enviando dados de vinculação de Pedidos de Vendas Troca NF com as Notas Fiscais: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      Else
         U_ITCONOUT("[AOMS146D] - Enviando dados de vinculação de Pedidos de Vendas Troca NF com as Notas Fiscais: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))
      EndIf

      ZFK->(DBGoTo(ZFKVTNF->NRREG))

      _cXMLEnv := &(_cVincPVXML)

      _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
      _nLimCarre := 100 // Número Máximo de Registros Lidos.

      oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
      oWsdl:nTimeout := 10          // Timeout de 10 segundos 
      oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

      oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
      oWsdl:SetOperation( "IntegrarNotasFiscais") // Define qual operação será realizada.

      // Envia para o servidor
      _lOk := oWsdl:SendSoapMsg(_cXMLEnv) // Este comando pega o XML e envia para o servidor da TMS MultiEmbarcador.  

      _cEnvioOK := "S"
      _cCodMsg  := "400" 
      _cMsg     := ""
      If _lOk 
         _cResult := oWsdl:GetSoapResponse()

         cError   := ""
         cWarning := ""

         _oXml := XmlParser(_cResult, "_", @cError, @cWarning )
         _cCodMsg  := _oxml:_s_Envelope:_s_Body:_IntegrarNotasFiscaisResponse:_IntegrarNotasFiscaisResult:_a_CodigoMensagem:text
         _cMsg     := _oxml:_s_Envelope:_s_Body:_IntegrarNotasFiscaisResponse:_IntegrarNotasFiscaisResult:_a_Mensagem:text
        
         If _cCodMsg <> "200"
            _cEnvioOK := "N"
         EndIf 
      Else
         _cResult := oWsdl:cError
         _cEnvioOK := "N"
      EndIf   
      
      ZFK->(RecLock("ZFK",.F.))
      ZFK->ZFK_DATA   := Date()  
      ZFK->ZFK_HORA   := Time()
      ZFK->ZFK_CODEMP := _cCodEmpWS
      ZFK->ZFK_RETORN := "Retorno: " + _cCodMsg + "-" + _cMsg + " - Retorno WebService: " + AllTrim(_cResult) 
      ZFK->ZFK_XML    := _cXMLEnv
      If _cEnvioOK == "N"
         ZFK->ZFK_SITUAC := "R"
      Else
         ZFK->ZFK_SITUAC := "P"
      EndIf 

      ZFK->(MSUnLock())

      If ValType(oWSDL) == "O"
         FreeObj(oWsdl)
      EndIf 
      oWsdl := Nil
      
      ZFKVTNF->(DBSkip())
   EndDo

End Sequence

If !_lScheduller 
   U_ITMsg("Termino do envio de dados de Vinculação de Pedidos de Vendas Troca NF com as Notas Fiscais - Protheus x TMS MultiEmbarcador.","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146D] - Termino do envio de dados de Vinculação de Pedidos de Vendas Troca NF com as Notas Fiscais - Protheus x TMS MultiEmbarcador. ")
EndIf

If Select("ZFKVTNF") > 0
   ZFKVTNF->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS146E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina Scheduller para leitura, gravação e Transmissão  dos dados de notas fiscais para 
                    Pedidos de Vendas Troca Nota Fiscal.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS146E

Begin Sequence

   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
      
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"ZFK","SA2","SF2","DAK","DAI","SC5","SC6","ZP1"})

   cFilAnt := "01"

   //================================================================================
   // Grava os dados das notas fiscais para pedidos de vendas Troca nota fiscal.
   //================================================================================    
   U_AOMS146A(.T.) 
   
   //================================================================================
   // Envia para o TMS MultiEmbarcador os dados das notas fiscais para 
   // Pedidos de Vendas Troca Nota Fiscal.
   //================================================================================    
   U_AOMS146B(.T.)

End Sequence

Return 

/*
===============================================================================================================================
Programa----------: AOMS146F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina Scheduller para leitura, gravação e Transmissão  dos dados de vinculação de notas fiscais  
                    com Pedidos de Vendas Troca Nota Fiscal.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS146F

Begin Sequence

   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
      
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"ZFK","SA2","SF2","DAK","DAI","SC5","SC6","ZP1"})

   cFilAnt := "01"

   //================================================================================
   // Grava os dados de vinculação de Pedidos de Vendas Troca Nota fiscal 
   // com as notas fiscais.
   //================================================================================    
   U_AOMS146C(.T.)  
   
   //================================================================================
   // Envia para o TMS MultiEmbarcador os dados de vinculação das notas fiscais  
   // com os Pedidos de Vendas Troca Nota Fiscal.
   //================================================================================    
   U_AOMS146D(.T.)

End Sequence

Return 

/*
===============================================================================================================================
Programa----------: AOMS146G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de solicitação de mudança da carga para pedidos do tipo Troca Nota Fiscal 
                    para próxima fase no TMS (LiberarEmissaoSemNFe).
Parametros--------: _lScheduller = .T./.F. = Determina se a rotina está sendo rodada em modo automático/Scheduller ou manual.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS146G(_lScheduller)

Local _cQry
Local _nTotRegs 
Local _aRet 
Local _cFilHabil := SuperGetMV('IT_FILINTW',.F.,'')

Begin Sequence

   If !_lScheduller .And. ! U_ITMsg("Deseja rodar a rotina de mudança de pedidos de vendas do tipo Troca Nota Fiscal para a próxima fase?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146G] - Inicio da rotina de mudança de pedidos de vendas do tipo Troca Nota Fiscal para a próxima fase - Protheus x TMS MultiEmbarcador. ")      
   EndIf

   _cQry := " SELECT ZFK.R_E_C_N_O_ NRREG "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = 'A' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR  ZFK_SITUAC = 'R') "
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabil),";")
   _cQry := ChangeQuery(_cQry)

   If Select("ZFKPROF") > 0
      ZFKPROF->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKPROF")

   DBSelectArea("ZFKPROF")
   Count To _nTotRegs

   If !_lScheduller 
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   ZFKPROF->(DBGoTop())

   DAK->(DBSetOrder(1)) 

   _nRegAtu := 0
   _aCargas := {}

   While ZFKPROF->(!Eof())
      _nRegAtu++

      If !_lScheduller 
         IncProc("Integrando Solicitação de Mudança de PV Troca NF para Próxima Fase: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))  
      Else
         U_ITCONOUT("[AOMS146C] Integrando Solicitação de Mudança de PV Troca NF para Próxima Fase: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))
      EndIf

      ZFK->(DBGoTo(ZFKPROF->NRREG))
      
      If ! DAK->(MsSeek(ZFK->ZFK_FILIAL+ZFK->ZFK_CARGA)) 
         ZFKPROF->(DBSkip())
         Loop 
      EndIf
      
      //==============================================================================
      // _aRet :=  {1=True/False, // sucesso na integração / falha na integração
      //            2=Codigo da Mensagem de Retorno,
      //            3=Código e Mensagem de Retorno, 
      //            4=Xml de Retorno, 
      //            5=Xml de Envio}
      //==============================================================================
      _aRet := U_AOMS140D() // Chama a rotina de integração Webservice de mudanção da carga para próxima fase. 

      If _aRet[1] 
         ZFK->(RecLock("ZFK",.F.))
         ZFK->ZFK_SITUAC := "P"
         ZFK->ZFK_RETORN := _aRet[3] // Mensagem de REtorno
         ZFK->ZFK_XML    := _aRet[5] // XML de envio
         ZFK->(MSUnLock())   
      Else
         ZFK->(RecLock("ZFK",.F.))
         ZFK->ZFK_RETORN := _aRet[3] // Mensagem de REtorno
         ZFK->ZFK_XML    := _aRet[5] // XML de envio
         ZFK->(MSUnLock())   
      EndIf 
      
      ZFKPROF->(DBSkip())
   EndDo

End Sequence

If !_lScheduller
   U_ITMsg("Termino da Integração de Solicitação de Mudança de Pedidos de Vendas Troca Nota Fiscal para próxima fase. ","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146G] - Termino da Integração de Solicitação de Mudança de Pedidos de Vendas Troca Nota Fiscal para próxima fase. ")      
EndIf  

If Select("ZFKPROF") > 0
   ZFKPROF->( DBCloseArea() )
EndIf

Return 

/*
===============================================================================================================================
Programa----------: AOMS146H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina Scheduller para Solicitação de mudança da carga para a próxima fase (encerramento). 
                    Para pedidos de vendas do tipo troca nota fiscal.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS146H()

Begin Sequence

   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
      
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"ZFK","SA2","SF2","DAK","DAI","SC5","SC6","ZP1"})

   cFilAnt := "01"
 
   //================================================================================
   // Gravação dos dados para solicitação de mudança da carga para a próxima fase.
   // Para pedidos de vendas do tipo Troca Nota Fiscal.
   //================================================================================
   U_AOMS146L(.T.) 

   //================================================================================
   // Envia para o TMS MultiEmbarcador uma solicitação de mudanção da carga para 
   // a próxima fase(Encerramento), para pedidos de vendas do tipo troca nota fiscal. 
   //================================================================================    
   U_AOMS146G(.T.)

End Sequence

Return 

/*
===============================================================================================================================
Função------------: AOMS146I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de Gravação dos Dados de integração do Vale Pedágio, para pedidos de vendas  
                    do tipo troca nota fiscal para o TMS MultiEmbarcador.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146I(_lScheduller )

Local _cQry
Local _nTotRegs 

Begin Sequence

   If !_lScheduller .And. ! U_ITMsg("Confirma a Gravação dos Dados de integração do Vale Pedágio, para Pedidos de Vendas do Tipo Troca Nota Fiscal, para o TMS MultiEmbarcador?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146I] - Iniciando a Gravação dos Dados para a integração do Vale Pedágio, para Pedidos de Vendas do Tipo Troca Nota Fiscal, Para o TMS MultiEmbarcador. ")      
   EndIf

   _cQry := "SELECT DISTINCT ZFK_FILIAL, "
   _cQry += "  ZFK_TIPOI, "
   _cQry += "  ZFK_CARGA, "
   _cQry += "  ZFK_CARTMS "
   //_cQry += "  ZFK.R_E_C_N_O_ NRREG  // Utilizar índice orderm 3
   _cQry += "  FROM " + RETSQLNAME("ZFK") + " ZFK "
   _cQry += "  WHERE  ZFK_TIPOI = '8' "
   _cQry += "  AND ZFK_SITUAC = 'P' "
   _cQry += "  AND ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "  AND NOT EXISTS "
   _cQry += "  (SELECT 'X' "
   _cQry += "  FROM " + RETSQLNAME("ZFK") + " ZFKB "
   _cQry += "  WHERE ZFKB.ZFK_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += "  AND ZFKB.ZFK_TIPOI = ZFK.ZFK_TIPOI "
   _cQry += "  AND ZFKB.ZFK_CARGA = ZFK.ZFK_CARGA "
   _cQry += "  AND ZFKB.ZFK_CARTMS = ZFK.ZFK_CARTMS "
   _cQry += "  AND ZFKB.ZFK_SITUAC <> 'P' "
   _cQry += "  AND ZFKB.D_E_L_E_T_ = ' ') "
   _cQry += "  AND NOT EXISTS "
   _cQry += "  (SELECT 'X' "
   _cQry += "  FROM " + RETSQLNAME("ZFK") + " ZFKC "
   _cQry += "  WHERE ZFKC.ZFK_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += "  AND ZFKC.ZFK_CARGA = ZFK.ZFK_CARGA "
   _cQry += "  AND ZFKC.ZFK_CARTMS = ZFK.ZFK_CARTMS "
   _cQry += "  AND ZFKC.ZFK_TIPOI = '9' "
   _cQry += "  AND ZFKC.D_E_L_E_T_ = ' ') "
 
   _cQry := ChangeQuery(_cQry)

   If Select("ZFKVAL") > 0
      ZFKVAL->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKVAL")

   DBSelectArea("ZFKVAL")
   Count To _nTotRegs

   If !_lScheduller 
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   DAK->(DBSetOrder(1))
   ZFK->(DBSetOrder(3))

   ZFKVAL->(DBGoTop())
   
   _nRegAtu := 0

   While ZFKVAL->(!Eof())
      _nRegAtu++

      If !_lScheduller 
         IncProc("Gravando dados de Geração do Vale Pedágio para Pedidos de Vendas do Tipo Troca Nota Fiscal: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))  
      Else
         U_ITCONOUT("[AOMS146I] Gravando dados de Geração do Vale Pedágio para Pedidos de Vendas do Tipo Troca Nota Fiscal: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))
      EndIf
     
      If ZFK->(MsSeek(ZFKVAL->ZFK_FILIAL+ZFKVAL->ZFK_CARGA+ZFKVAL->ZFK_TIPOI+"P"))  // ZFK_FILIAL+ZFK_CARGA+ZFK_TIPOI+ZFK_SITUAC
         M->ZFK_FILIAL := ZFK->ZFK_FILIAL
         M->ZFK_CARGA  := ZFK->ZFK_CARGA 
         M->ZFK_CARTMS := ZFK->ZFK_CARTMS
         M->ZFK_PRTPED := ZFK->ZFK_PRTPED
         M->ZFK_DATA   := ZFK->ZFK_DATA  // Gravar Data Atual
         M->ZFK_HORA   := ZFK->ZFK_HORA  
         M->ZFK_TIPOI  := ZFK->ZFK_TIPOI // = "8"
         M->ZFK_CHVNFE := ZFK->ZFK_CHVNFE
         M->ZFK_PEDPAL := ZFK->ZFK_PEDPAL
         M->ZFK_NRPPAL := ZFK->ZFK_NRPPAL
         M->ZFK_CGC    := ZFK->ZFK_CGC   
         M->ZFK_PEDIDO := ZFK->ZFK_PEDIDO
         M->ZFK_COD	  := ZFK->ZFK_COD
         M->ZFK_LOJA   := ZFK->ZFK_LOJA  
         M->ZFK_NOME   := ZFK->ZFK_NOME  
         M->ZFK_USUARI := ZFK->ZFK_USUARI
         M->ZFK_SITUAC := "N" // ZFK->ZFK_SITUAC
         M->ZFK_XML    := ZFK->ZFK_XML   
         M->ZFK_PRTMS  := ZFK->ZFK_PRTMS   

         DAK->(MsSeek(ZFK->ZFK_FILIAL+ZFK->ZFK_CARGA))

         ZFK->(RecLock("ZFK",.T.))   
         ZFK->ZFK_FILIAL := M->ZFK_FILIAL 
         ZFK->ZFK_CARGA  := M->ZFK_CARGA   
         ZFK->ZFK_CARTMS := M->ZFK_CARTMS  
         ZFK->ZFK_PRTPED := M->ZFK_PRTPED
         ZFK->ZFK_DATA   := Date() 
         ZFK->ZFK_HORA   := Time() 
         ZFK->ZFK_TIPOI  := "9"
         ZFK->ZFK_CHVNFE := M->ZFK_CHVNFE
         ZFK->ZFK_PEDPAL := M->ZFK_PEDPAL  
         ZFK->ZFK_NRPPAL := M->ZFK_NRPPAL 
         ZFK->ZFK_PEDIDO := M->ZFK_PEDIDO  
         ZFK->ZFK_COD    := M->ZFK_COD	   
         ZFK->ZFK_LOJA   := M->ZFK_LOJA      
         ZFK->ZFK_NOME   := M->ZFK_NOME     
         ZFK->ZFK_USUARI := __cUserId // Codigo do Usuário
         ZFK->ZFK_DATAAL := Date()
         ZFK->ZFK_PRTMS  := M->ZFK_PRTMS
      
         If AllTrim(Upper(DAK->DAK_I_INVP)) ==  "PAMCARD" // 'Pamcard' = , se For 'Repom' = 65697260000103, senão branco
            ZFK->ZFK_CGC := "12815827000132" 
         ElseIf AllTrim(Upper(DAK->DAK_I_INVP)) ==  "REPOM" // DAK->DAK_I_INVP // Integradora do Vale Pedágio 
            ZFK->ZFK_CGC := "65697260000103"
         EndIf 

         ZFK->ZFK_NRVALP := DAK->DAK_I_VPED // Numero do Vale Pedágio
         ZFK->ZFK_VLVALP := DAK->DAK_I_VRVP // = Valor Rateado do Pedágio // DAK_I_VALP = Valor do Vale Pedágio 
         ZFK->ZFK_SITUAC := "N"  
         ZFK->(MSUnLock()) 
      EndIf 

      ZFKVAL->(DBSkip())
   EndDo

End Sequence

If !_lScheduller
   U_ITMsg("Termino da gravação dos dados de Geração do Vale Pedágio para Pedidos de Vendas do Tipo Troca Nota Fiscal.","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146I] - Termino da gravação dos dados de Geração do Vale Pedágio para Pedidos de Vendas do Tipo Troca Nota Fiscal.")      
EndIf 

If Select("ZFKVAL") > 0
   ZFKVAL->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Função------------: AOMS146J
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de integração/transmissão de dados de vale pedágio, para pedidos de vendas do tipo troca nota fiscal
                    para o TMS Multiembarcador.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146J(_lScheduller)

Local _cQry      := ""
Local _cFilHabil := SuperGetMV('IT_FILINTW',.F.,'')
Local _cDirXML
Local _cLink
Local _cCodEmpWS
Local _lOk           := .F.
Local _cResult       := ""
Local oWsdl

Private _cToken

Begin Sequence 
   
   If !_lScheduller .And. ! U_ITMsg("Confirma envio de dados de integração vale pedágio, para pedidos de vendas do tipo troca nota fiscal, para o Sistema TMS MultiEmbarcador ?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146J] Inicio do envio de dados de integração vale pedágio, para de vendas do tipo Troca Notas Fiscais, para o Sistema TMS MultiEmbarcador.")   
   EndIf

   //=====================================================================
   // Obtem o token de acesso ao sistema multi embarcador.
   //=====================================================================
   _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

   //================================================================================
   // Retorna Codigo Empresa WebService TMS-MULTI EMBARCADOR.
   //================================================================================                    
   _cCodEmpWS := SuperGetMV('IT_EMPTMSM',.F.,"000005")
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cCodEmpWS))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK06)  // Link de integração vele pedágio.
   Else
      If ! _lScheduller
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146J] Empresa WebService para envio dos dados não localizada.")
      EndIf
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lExibeTela
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146J] Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      EndIf
      
      Break                                     
   EndIf
      
   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf

   //================================================================================
   // Lê os arquivos modelo XML e os transforma em String.
   //================================================================================
   _cValePXML := U_AOMS146X(_cDirXML+"Integrar_Vale_Pedagio_TMS.txt") 

   If Empty(_cValePXML)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo XML modelo de Integração Vale Pedágio, com o TMS MultiEmbarcador.  ","Atenção",,1)
      Else
         U_ITCONOUT("[AOMS146J] Erro na leitura do arquivo XML modelo de Integração Vale Pedágio, com o TMS MultiEmbarcador.  ")
      EndIf
      Break
   EndIf
 
   //===================================================================================================
   // Montagem de query com os numeros de registros de integração Vale Pedágio com o TMS Multiembardador
   //===================================================================================================
   _cQry := " SELECT ZFK.R_E_C_N_O_ NRREG "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '9' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR  ZFK_SITUAC = 'R') "
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabil),";")

   _cQry := ChangeQuery(_cQry)          

   If Select("ZFKINTVL") > 0
      ZFKINTVL->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKINTVL")
   
   DBSelectArea("ZFKINTVL")                                                                                  
   COUNT To _nTotRegs

   If !_lScheduller
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   ZFKINTVL->(DBGoTop())
   
   _nRegAtu := 0

   _aEnvioTMS := {} // Controle de Cargas Enviadas para o TMS
   _aCargaLid := {} // Controle de cargas lidas.

   While !ZFKINTVL->(Eof()) 

      _nRegAtu++

      If !_lScheduller 
         IncProc("Enviando dados de integração vale pedágio para Pedidos de Vendas Troca Fiscais: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      Else
         U_ITCONOUT("[AOMS146J] - Enviando dados de integração vale pedágio para Pedidos de Vendas Troca Fiscais: " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))
      EndIf

      ZFK->(DBGoTo(ZFKINTVL->NRREG))

      _cXMLEnv := &(_cValePXML)

      _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
      _nLimCarre := 100 // Número Máximo de Registros Lidos.

      oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
      oWsdl:nTimeout := 10          // Timeout de 10 segundos 
      oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

      oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
      oWsdl:SetOperation("IntegrarValePedagio") // Define qual operação será realizada. // "IntegrarValePedagio"
                          
      // Envia para o servidor
      _lOk := oWsdl:SendSoapMsg(_cXMLEnv) // Este comando pega o XML e envia para o servidor da TMS MultiEmbarcador.  

      _cEnvioOK := "S"
      _cCodMsg  := "400" 
      _cMsg     := ""
      If _lOk 
         _cResult := oWsdl:GetSoapResponse()

         cError   := ""
         cWarning := ""

         _oXml := XmlParser(_cResult, "_", @cError, @cWarning )
         _cCodMsg  := _oxml:_s_Envelope:_s_Body:_IntegrarValePedagioResponse:_IntegrarValePedagioResult:_a_CodigoMensagem:text
         _cMsg     := _oxml:_s_Envelope:_s_Body:_IntegrarValePedagioResponse:_IntegrarValePedagioResult:_a_Mensagem:text
        
         If _cCodMsg <> "200"
            _cEnvioOK := "N"
         EndIf 
      Else
         _cResult := oWsdl:cError
         _cEnvioOK := "N"
      EndIf   
      
      ZFK->(RecLock("ZFK",.F.))
      ZFK->ZFK_DATA   := Date()  
      ZFK->ZFK_HORA   := Time()
      ZFK->ZFK_CODEMP := _cCodEmpWS
      ZFK->ZFK_RETORN := "Retorno: " + _cCodMsg + "-" + _cMsg + " - Retorno WebService: " + AllTrim(_cResult) 
      ZFK->ZFK_XML    := _cXMLEnv
      If _cEnvioOK == "N"
         ZFK->ZFK_SITUAC := "R"
      Else
         ZFK->ZFK_SITUAC := "P"
      EndIf 

      ZFK->(MSUnLock())

      If ValType(oWSDL) == "O"
         FreeObj(oWsdl)
      EndIf 
      oWsdl := Nil
      
      ZFKINTVL->(DBSkip())
   EndDo

End Sequence

If !_lScheduller 
   U_ITMsg("Termino do envio da integração vale pedágio para pedidos de vendas tipo troca nota fiscal, para o TMS Multi Embarcador.","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146J] - Termino do envio da integração vale pedágio para pedidos de vendas tipo troca nota fiscal, para o TMS Multi Embarcador.")
EndIf

If Select("ZFKINTVL") > 0
   ZFKINTVL->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS146K
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/08/2024
Descrição---------: Rotina Scheduller para gravação dos dados de geração de Vale Pedágio e realizar a integração Webservice
                    com TMS MultiEmbarcador para a geração do Vale Pedágio. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS146K

Begin Sequence

   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
      
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"ZFK","SA2","SF2","DAK","DAI","SC5","SC6","ZP1"})

   cFilAnt := "01"
 
   //================================================================================
   // Inicia a rotina de gravação de dados para integração do vale pedágio com o
   // TMS-Multiembarcador.
   //================================================================================    
   U_AOMS146I(.T.) 

   //================================================================================
   // Inicia a rotina de integração / Transmissão dos dados do vale pedágio com o
   // TMS-Multiembarcador.
   //================================================================================    
   U_AOMS146J(.T.)

End Sequence

Return 

/*
===============================================================================================================================
Função------------: AOMS146L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/08/2024
Descrição---------: Rotina de Gravação dos Dados de mudança de carga para próxima fase, para pedidos de vendas  
                    do tipo troca nota fiscal para o TMS MultiEmbarcador.
Parametros--------: _lScheduller = .T./.F. = Rotina chamada Via Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS146L(_lScheduller )

Local _cQry
Local _nTotRegs 

Begin Sequence

   If !_lScheduller .And. ! U_ITMsg("Confirma a Gravação dos Dados de solicitação de mudança de carga para próxma fase, para Pedidos de Vendas do Tipo Troca Nota Fiscal, para o TMS MultiEmbarcador?","Atenção",,4,2,2) 
      Break
   Else
      U_ITCONOUT("[AOMS146L] - Iniciando a Gravação dos Dados de solicitação de mudança de carga para próxima fase, para Pedidos de Vendas do Tipo Troca Nota Fiscal, Para o TMS MultiEmbarcador. ")      
   EndIf

   _cQry := "SELECT ZFK_FILIAL, "
   _cQry += "  ZFK_TIPOI, "
   _cQry += "  ZFK_CARGA, "
   _cQry += "  ZFK_CARTMS, "
   _cQry += "  ZFK.R_E_C_N_O_ NRREG "
   _cQry += "  FROM " + RETSQLNAME("ZFK") + " ZFK "
   _cQry += "  WHERE  ZFK_TIPOI = '9' " // ZFK_TIPOI = '8' "
   _cQry += "  AND ZFK_SITUAC = 'P' "
   _cQry += "  AND ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "  AND NOT EXISTS "
   _cQry += "  (SELECT 'X' "
   _cQry += "  FROM " + RETSQLNAME("ZFK") + " ZFKB "
   _cQry += "  WHERE ZFKB.ZFK_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += "  AND ZFKB.ZFK_TIPOI = ZFK.ZFK_TIPOI "
   _cQry += "  AND ZFKB.ZFK_CARGA = ZFK.ZFK_CARGA "
   _cQry += "  AND ZFKB.ZFK_CARTMS = ZFK.ZFK_CARTMS "
   _cQry += "  AND ZFKB.ZFK_SITUAC <> 'P' "
   _cQry += "  AND ZFKB.D_E_L_E_T_ = ' ') "
   _cQry += "  AND NOT EXISTS "
   _cQry += "  (SELECT 'X' "
   _cQry += "  FROM " + RETSQLNAME("ZFK") + " ZFKC "
   _cQry += "  WHERE ZFKC.ZFK_FILIAL = ZFK.ZFK_FILIAL "
   _cQry += "  AND ZFKC.ZFK_CARGA = ZFK.ZFK_CARGA "
   _cQry += "  AND ZFKC.ZFK_CARTMS = ZFK.ZFK_CARTMS "
   _cQry += "  AND ZFKC.ZFK_TIPOI = 'A' "
   _cQry += "  AND ZFKC.D_E_L_E_T_ = ' ') "
 
   _cQry := ChangeQuery(_cQry)

   If Select("ZFKVAL") > 0
      ZFKVAL->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"ZFKVAL")

   DBSelectArea("ZFKVAL")
   Count To _nTotRegs

   If !_lScheduller 
      ProcRegua(_nTotRegs)
   EndIf

   If _nTotRegs == 0
      Break 
   EndIf 

   ZFKVAL->(DBGoTop())
   
   _nRegAtu := 0

   While ZFKVAL->(!Eof())
      _nRegAtu++

      If !_lScheduller 
         IncProc("Gravando dados de solicitação de mudança de carga para a próxima fase para Pedidos de Vendas do Tipo Troca Nota Fiscal: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))  
      Else
         U_ITCONOUT("[AOMS146L] Gravando dados de solicitação de mudança de carga para a próxima fase para Pedidos de Vendas do Tipo Troca Nota Fiscal: " + AllTrim(Str(_nRegAtu,10)) + " de " + AllTrim(Str(_nTotRegs,10)))
      EndIf
      
      ZFK->(DBGoTo(ZFKVAL->NRREG))

      M->ZFK_FILIAL := ZFK->ZFK_FILIAL
      M->ZFK_CARGA  := ZFK->ZFK_CARGA 
      M->ZFK_CARTMS := ZFK->ZFK_CARTMS
      M->ZFK_PRTPED := ZFK->ZFK_PRTPED
      M->ZFK_DATA   := ZFK->ZFK_DATA  // Gravar Data Atual
      M->ZFK_HORA   := ZFK->ZFK_HORA  
      M->ZFK_TIPOI  := ZFK->ZFK_TIPOI // = "8"
      M->ZFK_CHVNFE := ZFK->ZFK_CHVNFE
      M->ZFK_PEDPAL := ZFK->ZFK_PEDPAL
      M->ZFK_NRPPAL := ZFK->ZFK_NRPPAL
      M->ZFK_CGC    := ZFK->ZFK_CGC   
      M->ZFK_PEDIDO := ZFK->ZFK_PEDIDO
      M->ZFK_COD	  := ZFK->ZFK_COD
      M->ZFK_LOJA   := ZFK->ZFK_LOJA  
      M->ZFK_NOME   := ZFK->ZFK_NOME  
      M->ZFK_USUARI := ZFK->ZFK_USUARI
      M->ZFK_SITUAC := "N" // ZFK->ZFK_SITUAC
      M->ZFK_XML    := ZFK->ZFK_XML   
      M->ZFK_PRTMS  := ZFK->ZFK_PRTMS   
      M->ZFK_INTVPD := ZFK->ZFK_INTVPD
      M->ZFK_NRVALP := ZFK->ZFK_NRVALP 
      M->ZFK_VLVALP := ZFK->ZFK_VLVALP

      ZFK->(RecLock("ZFK",.T.))   
      ZFK->ZFK_FILIAL := M->ZFK_FILIAL 
      ZFK->ZFK_CARGA  := M->ZFK_CARGA   
      ZFK->ZFK_CARTMS := M->ZFK_CARTMS  
      ZFK->ZFK_PRTPED := M->ZFK_PRTPED
      ZFK->ZFK_DATA   := Date() 
      ZFK->ZFK_HORA   := Time() 
      ZFK->ZFK_TIPOI  := "A"
      ZFK->ZFK_CHVNFE := M->ZFK_CHVNFE
      ZFK->ZFK_PEDPAL := M->ZFK_PEDPAL  
      ZFK->ZFK_NRPPAL := M->ZFK_NRPPAL 
      ZFK->ZFK_CGC    := M->ZFK_CGC        
      ZFK->ZFK_PEDIDO := M->ZFK_PEDIDO  
      ZFK->ZFK_COD    := M->ZFK_COD	   
      ZFK->ZFK_LOJA   := M->ZFK_LOJA      
      ZFK->ZFK_NOME   := M->ZFK_NOME     
      ZFK->ZFK_USUARI := __cUserId // Codigo do Usuário
      ZFK->ZFK_DATAAL := Date()
      ZFK->ZFK_PRTMS  := M->ZFK_PRTMS
      ZFK->ZFK_SITUAC := "N"  
      ZFK->(MSUnLock()) 

      ZFKVAL->(DBSkip())
   EndDo

End Sequence

If !_lScheduller
   U_ITMsg("Termino da gravação dos dados de solicitação de mudança da carga para a proxima fase, para Pedidos de Vendas do Tipo Troca Nota Fiscal.","Atenção",,2)
Else
   U_ITCONOUT("[AOMS146L] - Termino da gravação dos dados de solicitação de mudança da carga para a próxima fase, para Pedidos de Vendas do Tipo Troca Nota Fiscal.")      
EndIf 

If Select("ZFKVAL") > 0
   ZFKVAL->( DBCloseArea() )
EndIf

Return
