/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |13/08/2024| Chamado 48152. Jerry. Acrescentado o envio XML da NFe Vendas p/ o RDC das Nf SEDEX e tb as Nf que não tem OC geradas no RDC.
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |20/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
======================================================================================================================================
*/

#Include "TOTVS.ch"
#Include "APWEBSRV.CH"  
#Include "TBICONN.CH"  

/*
===============================================================================================================================
Programa----------: MOMS033
Autor-------------: Julio de Paula Paz
Data da Criacao---: 21/10/2016
Descrição---------: Rotina de integração de Notas Fiscais, Italac <---> RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static _lScheduller :=.F.
User Function MOMS033()

If _lScheduller 
   MOMS033G("TIPO P")
   MOMS033G("TIPO O")
Else
   Processa( {|| MOMS033G("TIPO P")},"Processando TIPO P Hora Ini: "+Time()+", Aguarde...")
   Processa( {|| MOMS033G("TIPO O")},"Processando TIPO O Hora Ini: "+Time()+", Aguarde...")
EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: MOMS033G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 21/10/2016
Descrição---------: Rotina de integração de Notas Fiscais, Italac <---> RDC.
Parametros--------: _cTipo
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function MOMS033G(_cTipo)

Local _cQry
Local _dDataIntRDC := SuperGetMV("IT_DTINRDC",.T.,Ctod("01/01/2022"))
Local _cDirXML := SuperGetMV("IT_DIRXMLR",.T.,"\\wfteste.italac.com.br\TOTVS\Homologacao\Protheus_data\data\Italac\RDC\RW17")
Local _cNomeArq, _nHandle
Local _nTotRegs:=0
Local _cXmlNfe, _cProtNfe
Local _cXmlEnv, _cPart1Xml, _cPart2Xml, _nI, _nF       
Local _cFilHabilit := SuperGetMV('IT_FILINTW',.T.,'') // Filiais habilitadas na integracao Webservice Italac x RDC.  
Local _cListaFiliais
Local _cTimeIni:=Time()

If !_lScheduller .And. ! U_ITMsg("Confirma a integração de Notas Fiscais, Italac <---> RDC.?","Inicio de processamento "+_cTipo,,2,2,2) 
   Return .F.
EndIf

Begin Sequence 
   _cListaFiliais := AllTrim(_cFilHabilit)                             
   _cListaFiliais := StrTran(_cListaFiliais,";","','")                                                                                                      

   If !_lScheduller
      ProcRegua(0)
      IncProc("Lendo dados da SPED50/SF2...")
      IncProc("Lendo dados da SPED50/SF2...")   
   EndIf
   
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
If _cTipo == "TIPO P"

   _cQry := " SELECT SPED50.R_E_C_N_O_ NRECNO,  "
   _cQry += " SF2.R_E_C_N_O_ NRECSF2,  "
   _cQry += " SPED54.R_E_C_N_O_ NREC54,  "
   _cQry += " DAK.R_E_C_N_O_ NRECDAK  "
   _cQry += " FROM "+RetSqlName("SF2")+" SF2,  "
   _cQry += " SPED001 SPED01,  "
   _cQry += " SPED050 SPED50,  "
   _cQry += " SPED054 SPED54,  "
   _cQry += RetSqlName("DAK")+" DAK,  "
   _cQry += " SYS_COMPANY SM0  "
   If !totvs.framework.environment.type.get() == '1'//1-Produção, 2-Homologação,3-Desenvolvimento
      _cQry += " WHERE F2_EMISSAO >= '" + DToS(DATE()-120) + "' "//PARA TESTES
      _cQry += " AND F2_I_SITUA <> ' '  " //PARA TESTES
      _cDirXML := "\data\Italac\RDC\RW17\"//PARA TESTES
   Else//PARA TESTES
      _cQry += " WHERE F2_EMISSAO >= '" + DToS(_dDataIntRDC) + "' "
      _cQry += " AND F2_I_SITUA = ' '  "
   EndIf
   _cQry += " AND F2_ESPECIE = 'SPED'  "
   _cQry += " AND F2_CARGA  <>' '  "
   _cQry += " AND F2_CHVNFE <> ' '  "
   _cQry += " AND SF2.D_E_L_E_T_ = ' '  "
   _cQry += " AND DAK_FILIAL = F2_FILIAL  "
   _cQry += " AND DAK_COD = F2_CARGA  "
   _cQry += " AND DAK.D_E_L_E_T_ = ' '  "
   _cQry += " AND M0_CODIGO = '01'  "
   _cQry += " AND M0_CODFIL = F2_FILIAL  "
   _cQry += " AND SM0.D_E_L_E_T_ = ' '  "
   _cQry += " AND SPED01.CNPJ = SM0.M0_CGC  "
   _cQry += " AND SPED01.IE = SM0.M0_INSC  "
   _cQry += " AND SPED01.D_E_L_E_T_ = ' '  "
   _cQry += " AND SPED50.ID_ENT = SPED01.ID_ENT  "
   _cQry += " AND SPED50.NFE_ID = (F2_SERIE||F2_DOC)  "
   _cQry += " AND SPED50.STATUS = '6'  "
   _cQry += " AND SPED50.D_E_L_E_T_ = ' '  "
   _cQry += " AND SPED54.ID_ENT = SPED01.ID_ENT  "
   _cQry += " AND SPED54.NFE_ID = (F2_SERIE||F2_DOC)  "
   _cQry += " AND SPED54.CSTAT_SEFR = '100'  "
   _cQry += " AND SPED54.D_E_L_E_T_ = ' '  "

ElseIf _cTipo == "TIPO O"

   _cListaFiliais := StrTran(_cListaFiliais,"'","")

   _cQry := " SELECT SPED50.R_E_C_N_O_ NRECNO,  "
   _cQry += " SF2.R_E_C_N_O_ NRECSF2, "
   _cQry += " SPED54.R_E_C_N_O_ NREC54 "
   _cQry += " FROM "+RetSqlName("SF2")+" SF2, "
   _cQry += " SPED001 SPED01, "
   _cQry += " SPED050 SPED50, "
   _cQry += " SPED054 SPED54, "
   _cQry += RetSqlName("SC5")+" SC5,
   _cQry += " SYS_COMPANY SM0  "
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
      _cQry += " WHERE F2_EMISSAO >= '" + DToS(DATE()-180) + "' "//PARA TESTES
      _cDirXML := "\data\Italac\RDC\RW17\"//PARA TESTES
   Else
      _cQry += " WHERE F2_EMISSAO >= '20240601' "
   EndIf
   _cQry += " AND F2_FILIAL IN "+FormatIn(AllTrim(_cListaFiliais),",")
   _cQry += " AND F2_TIPO = 'N' "
   _cQry += " AND F2_I_SITUA NOT IN ('I','P','O')  "
   _cQry += " AND F2_ESPECIE = 'SPED'  "
   _cQry += " AND SC5.C5_TPFRETE <> 'F' "
   _cQry += " AND F2_CHVNFE <> ' '  "
   _cQry += " AND SF2.D_E_L_E_T_ = ' '  "
   _cQry += " AND M0_CODIGO = '01'  "
   _cQry += " AND M0_CODFIL = F2_FILIAL  "
   _cQry += " AND SM0.D_E_L_E_T_ = ' '  "
   _cQry += " AND SPED01.CNPJ = SM0.M0_CGC  "
   _cQry += " AND SPED01.IE = SM0.M0_INSC  "
   _cQry += " AND SPED01.D_E_L_E_T_ = ' '  "
   _cQry += " AND SPED50.ID_ENT = SPED01.ID_ENT  "
   _cQry += " AND SPED50.NFE_ID = (F2_SERIE||F2_DOC)  "
   _cQry += " AND SPED50.STATUS = '6'  "
   _cQry += " AND SPED50.D_E_L_E_T_ = ' '  "
   _cQry += " AND SPED54.ID_ENT = SPED01.ID_ENT  "
   _cQry += " AND SPED54.NFE_ID = (F2_SERIE||F2_DOC)  "
   _cQry += " AND SPED54.CSTAT_SEFR = '100'  "
   _cQry += " AND SPED54.D_E_L_E_T_ = ' '  "
   _cQry += " AND SC5.C5_FILIAL = SF2.F2_FILIAL "
   _cQry += " AND SC5.C5_NUM = SF2.F2_I_PEDID "
   _cQry += " AND ((SC5.C5_I_TRCNF = 'S' AND SC5.C5_I_PDFT = SC5.C5_NUM) OR SC5.C5_I_TRCNF = 'N') "
   _cQry += " AND SC5.C5_I_OPER IN ('01','12','15','24','25','26','31','42') "
   _cQry += " AND SC5.D_E_L_E_T_ = ' ' "
   _cQry += " AND NOT EXISTS (SELECT 'Y' FROM "+RetSqlName("DAK")+" DAK "
   _cQry += "                        WHERE D_E_L_E_T_ = ' ' AND DAK_FILIAL = SF2.F2_FILIAL AND "
   _cQry += "                                                       DAK_COD = SF2.F2_CARGA  AND DAK_I_CARG <> ' ') "

EndIf
   
   If Select("TRBSPED") > 0
      TRBSPED->( DBCloseArea() )
   EndIf

   DbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSPED" , .T., .F. )                            
                                                                                  
   COUNT TO _nTotRegs
   If !_lScheduller
      ProcRegua(_nTotRegs)
      _cTotal:=AllTrim(Str(_nTotRegs))
   EndIf
                          
   TRBSPED->(DBGoTop())
   
   u_itconout("MOMS033: Geracao de arquivos XML de NFE no diretório: "+_cDirXML )
   u_itconout("MOMS033: AMBIENTE: "+AllTrim(GETENVSERVER())+" Data: "+DToC(Date())+" Hora: "+Time())
   u_itconout("MOMS033: Total de registros a serem processados: "+Str(_nTotRegs,8))
   
   // Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
   If Select("SPED050") > 0
      SPED050->( DBCloseArea() )
   EndIf     
   
   USE SPED050 ALIAS SPED050 SHARED NEW VIA "TOPCONN" 
   
   If Select("SPED054") > 0
      SPED054->( DBCloseArea() )
   EndIf     
   
   USE SPED054 ALIAS SPED054 SHARED NEW VIA "TOPCONN" 
   
   // Inicia a leitura do arquivo de Sped para leitura dos XML e Envio para o RDC.
   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf   
   
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM                                                                                                                                                
   _nConta:=0
   _nEnviados:=0
   While !TRBSPED->(Eof()) 

      If !_lScheduller
         _nConta++
         IncProc("Registros Lidos: "+AllTrim(Str(_nConta))+" de "+_cTotal)   
      EndIf

      SF2->(DBGoTo(TRBSPED->NRECSF2))
      SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))

      _lok := .T.
      
      Begin Sequence

      If _cTipo == "TIPO P"
         
         DAK->(DBSeek(SF2->F2_FILIAL+SF2->F2_CARGA))

         If AllTrim(SC5->C5_TIPO) <> "N" // Diferente de um pedido normal.
            _lok := .F.
            Break
         EndIf

         If !(SF2->F2_FILIAL $ _cListaFiliais) // Ignora todas as filiais das notas fiscais que não estão no parâmetro e as filiais dos pedidos de origem da troca de nota que não estão no parâmetro.
            If Empty(SC5->C5_I_FLFNC) .Or. ! (SC5->C5_I_FLFNC $ _cListaFiliais) 
               _lok := .F.
               Break
            EndIf 
         EndIf
         
         If Empty(SC5->C5_I_FLFNC) // É um pedido de vendas normal. Não é um pedido de troca nota.
            // Validar a existência de cargas apenas para Pedidos de Vendas Normais.      
            If Empty(DAK->DAK_I_CARG)
               _lok := .F.
               Break
            EndIf
         EndIf
   
         If SC5->C5_I_TRCNF != "S" .And. Empty(DAK->DAK_I_CARG)  //Se não é troca nota e carga não foi montada pelo RDC 
               _lok := .F.
               Break
         EndIf

         If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDPR .And. Empty(DAK->DAK_I_CARG)  //Se é troca nota, pedido de carregamento e carga não foi montada pelo RDC 
            _lok := .F.
            Break
         EndIf

         If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDFT   //Se é troca nota, pedido de faturamento
         
         		_nSC5 := SC5->(Recno())
         		_nSF2 := SF2->(Recno())
         		_nDAK := DAK->(Recno())
         		
         		_lok := .F.
         		
         		If SC5->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_I_PDPR))
         		
         			If SF2->(DBSeek(SC5->C5_FILIAL+SC5->C5_NOTA))
         			
         				If DAK->(DBSeek(SF2->F2_FILIAL+SF2->F2_CARGA))
         				
         					If !Empty(DAK->DAK_I_CARG) //Se achou a carga de carregamento e foi gerada pelo rdc deixa enviar o xml
         					
         						_lok := .T.
         						
         					EndIf
         					
         				EndIf
         				
         			EndIf
         			
         		EndIf
         		
    	   	   SC5->(DBGoTo(_nSC5))
         		SF2->(DBGoTo(_nSF2))
         		DAK->(DBGoTo(_nDAK))
         		
         		
         		If !_lok
         		
         			Break
         			
         		EndIf
           
         EndIf

      EndIf
      
      SPED050->(DBGoTo(TRBSPED->NRECNO))
      
      End Sequence
      
      If _lok
      
        	SPED054->(DBGoTo(TRBSPED->NREC54))

        	_cNomeArq := AllTrim(SPED050->DOC_CHV) + ".XML"                                                      
      
        	// Monta XML para envio ao RDC
                        
        	_cXmlNfe := SPED050->XML_SIG
     
        	_cProtNfe := SPED054->XML_PROT                                                
     
        	_nI := AT( "<infNFe", _cXmlNfe ) 
        	_nF := AT( "</NFe>", _cXmlNfe ) 
        	_cPart1Xml := SubStr(_cXmlNfe,_nI,_nF - _nI)
                                                   
        	_nI := AT( "<protNFe", _cProtNfe ) 
        	_nF := AT( "</protNFe>", _cProtNfe ) 
        	_cPart2Xml := SubStr(_cProtNfe,_nI,_nF + 11)
     
        	_cXmlEnv := '<?xml version="1.0" encoding="UTF-8"?> <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="3.10"> <NFe>  '
        	_cXmlEnv := _cXmlEnv + _cPart1Xml + "</NFe>" + _cPart2Xml + '   </nfeProc> '
         
     
        	// Grava XML em Diretório para o RDC
        	_nHandle := FCreate(_cDirXML + _cNomeArq)
         If _nHandle <= 0
            u_itconout("MOMS033: Não foi possivel criar o arquivo XML de NFE: "+_cDirXML+ _cNomeArq )
            TRBSPED->(DBSkip())
            Loop
         Else
        	   FWrite(_nHandle,_cXmlEnv)
        	   FClose(_nHandle)
            u_itconout("MOMS033: Gravado o arquivo XML de NFE: "+_cDirXML+ _cNomeArq )
         EndIf
      
        	SF2->(RecLock("SF2",.F.))
         If _cTipo == "TIPO P"
        	   SF2->F2_I_SITUA := 'P'    
         ElseIf _cTipo == "TIPO O"
        	   SF2->F2_I_SITUA := 'O'    
         EndIf
        	SF2->F2_I_DTENV := Date()
        	SF2->F2_I_HRENV := Time()
        	SF2->(MSUnLock())
         _nEnviados++

      Else
      
      	SF2->(RecLock("SF2",.F.))
        	SF2->F2_I_SITUA := 'N'    
        	SF2->F2_I_DTENV := Date()
        	SF2->F2_I_HRENV := Time()
        	SF2->(MSUnLock())
      		
      EndIf
            
      TRBSPED->(DBSkip())
      
   EndDo

   _cTextoFim:="Notas Fiscais enviadas: "+AllTrim(Str(_nEnviados))+Chr(10)
   u_itconout("MOMS033: Termino da Integração de Notas Fiscais, Italac ---> RDC "+_cTextoFim)
   u_itconout("MOMS033: AMBIENTE: "+AllTrim(GETENVSERVER())+" Data: "+DToC(Date())+" Hora Inicial: "+_cTimeIni+" Hora Final: "+Time())
   If !_lScheduller
      U_ITMsg(">> Processamento concluído << "+Chr(10)+;
              "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim,;
              "Fim de processamento "+_cTipo,,2)
   EndIf
   
End Sequence

// Fecha as tabelas temporárias
If Select("TRBSPED") > 0
   TRBSPED->( DBCloseArea() )
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
Programa----------: MOMS033S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/03/2017
Descrição---------: Rotina para rodar a integração de Notas Fiscais, Italac <---> RDC, em Scheduller.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function MOMS033S()

Begin Sequence
   // Limpa o ambiente, liberando a licença e fechando as conexões
   RpcClearEnv() 
   RpcSetType(2)
     
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})

   cFilAnt := "01"
   
   _lScheduller :=.T.
   
   U_MOMS033() 
   
End Sequence

Return
