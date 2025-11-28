/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
====================================================================================================================================
 Analista     - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração
=======================================================================================================================================================================
Jerry         - Julio Paz    - 17/09/25 -          - 52165   - Alterar a rotina de processamento de CTE para ler e processar os dados do novo XML de CTE Simplificado.
=======================================================================================================================================================================
*/

#Include "APWEBSRV.CH"
#Include "TOTVS.ch"  
#Include "TBICONN.CH"  

/*
===============================================================================================================================
Programa----------: AOMS091
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/10/2016
Descrição---------: Rotina de consulta da integração de dados CTE Conhecimento de Transporte Eletrônico;
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091()
Local _aCores := {}
Private aRotina := {}
Private cCadastro 

//Grava log de utilização
u_itlogacs()

   cCadastro := "Integração dos Dados CTE(Conhecimento de Transporte Eletrônico) Via Webservice: Italac <---> RDC"
   aAdd(aRotina,{"Pesquisar"   ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"  ,"AxVisual"   ,0,2})
   aAdd(aRotina,{"Legenda"     ,"U_AOMS091L" ,0,2})
   aAdd(aRotina,{"Reenviar CTE","U_AOMS091R" ,0,4})
   aAdd(aRotina,{"Processa CTEs","U_AOMS091F" ,0,4})
   aAdd(aRotina,{"Envia XML p/RDC","U_AOMS091G" ,0,4})

    
   aAdd(_aCores,{"ZG0_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZG0_SITUAC == 'P'.And. ZG0_STATUS <> '1'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZG0_SITUAC == 'R'" ,"BR_AMARELO" })
   aAdd(_aCores,{"ZG0_SITUAC == 'E'" ,"BR_AZUL" })
   aAdd(_aCores,{"ZG0_SITUAC == 'P' .And. ZG0_STATUS == '1' " ,"BR_LARANJA" })
   
   DBSelectArea("ZG0")
   ZG0->(DBSetOrder(1)) 
   ZG0->(DBGoTop())
   MBrowse(6,1,22,75,"ZG0", , , , , , _aCores)
   
Return    

/*
===============================================================================================================================
Programa----------: AOMS091L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091L       

Local _aLegenda := {}

   aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
   aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })
   aAdd(_aLegenda,{"BR_AZUL"     ,"Enviado RDC" })
   aAdd(_aLegenda,{"BR_LARANJA"  ,"Validado Pelo Fiscal RDC" })

   BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return   

/*
===============================================================================================================================
Programa----------: AOMS091C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/02/2017
Descrição---------: Rotina de leitura dos XML da tabela CKO e grava na tabela de Muro ZG0.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091C()  

Local _cQry
Local _cCodEmpWS
Local _cChave
Local _nI                                                
Local _aDadosForn
Local _nTamFil
Local _nTamChave
Local _cError    := ""
Local _cWarning  := ""
Local _oXml      := Nil
Local _dDtIntCTE
Local _cFilHabilit // Filiais habilitadas na integracao Webservice Italac x RDC.   
Local _lIntCteManual // Integração de dados CTE manual (True), ou Integração de dados via Scheduller(False).
Local _cListaFiliais
Local _cInfoNFE, _nQtdNFE, _cChaveNFE, _lEnviadoRDC
Local _cXmlDeNFE 
Local _cNroNFE
Local _cXmlCKO, _nJ 
Local _lCTEComplemento := .F.

Local _lPreparaAmbiente 
Default oproc := nil

//Detecta se tela está montada, se não estiver marca para montar ambiente
If !(isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV"))
	_lPreparaAmbiente := .T.
Else
	_lPreparaAmbiente := .F.
EndIf 

Begin Sequence              
   If _lIntCteManual // Integração de dados CTE manual (True), ou Integração de dados via Scheduller(False).
      ProcRegua(0)

      _lPreparaAmbiente := .F. 
      If ! U_ITMsg("Confirma a gravação dos dados dos CTEs nas tabelas de muro, para depois serem integrados ao sistema RDC?","Inicio de processamento",,2,2,2) 
         Break
      EndIf
   EndIf
  
   If _lPreparaAmbiente
   		u_itconout("Inicio da Integração dos XML CTE para a tabela de muro ZG0.")            
   	Else
   		IncProc("Inicio da Integração dos XML CTE para a tabela de muro ZG0.")
   	EndIf
   
   If _lPreparaAmbiente
      // Limpa o ambiente, liberando a licença e fechando as conexões
      RpcClearEnv() 
      RpcSetType(2)

      // Prepara ambiente abrindo tabelas e incializando variaveis.
      RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6"})

      cFilAnt := "01"
   EndIf

   _dDtIntCTE     := SuperGetMV('IT_DTINTCT',.T., Ctod('01/01/2017') )                                             
   _cFilHabilit   := SuperGetMV('IT_FILINTW',.T.,'') // Filiais habilitadas na integracao Webservice Italac x RDC.   
   _lIntCteManual := SuperGetMV('IT_INTCTEM',.T.,.T.) // Integração de dados CTE manual (True), ou Integração de dados via Scheduller(False).

   _cCodEmpWS     := SuperGetMV('IT_EMPWEBSE',.T.,'000001')
   _cListaFiliais := AllTrim(_cFilHabilit)                                   
   _cListaFiliais := StrTran(_cListaFiliais,";","','")
   // Monta e roda a query de seleção de dados

   _cQry := " SELECT R_E_C_N_O_ AS NRRECNO FROM "+RETSQLNAME("CKO")+" CKO "
   _cQry += " WHERE CKO.D_E_L_E_T_ = ' ' AND CKO_CODEDI = '214' AND CKO_I_RDC <> 'S' "
   _cQry += " AND CKO_DT_RET >= '"+DToS(_dDtIntCTE)+"' AND CKO_FILPRO IN ('"+_cListaFiliais+"') "
   _cQry += " ORDER BY CKO_DT_RET DESC"
   
   If Select("QRYCKO") > 0
      QRYCKO->(DBCloseArea())
   EndIf
   
   
   If _lPreparaAmbiente
   	u_itconout("Rodando Query de leitura dos dados.")       
   Else
   	IncProc("Rodando Query de leitura dos dados.")
   EndIf
           
   _cQry := ChangeQuery(_cQry) 
   //DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYCKO", .F., .T.)
   MPSysOpenQuery( _cQry , "QRYCKO")
   DBSelectArea("QRYCKO")
   
   If QRYCKO->(Eof()) .Or. QRYCKO->(Bof())
      If !(_lPreparaAmbiente)
         U_ITMsg("Nenhum resgistro encontrado",;
                 "Fim de processamento",,2)
      EndIf
      _lRet := .F.
      Break
   EndIf         
   
   DBSelectArea("QRYCKO")
   
   COUNT TO _ntotal
   
   QRYCKO->(DBGoTop())
   
   If _lPreparaAmbiente
   
   	u_itconout("Iniciando gravação dos XML CTE na tabela de muro ZG0.")        
   		
   Else
   	
      IncProc("Iniciando gravação dos XML CTE na tabela de muro ZG0.")

   EndIf
   
   SF1->(DBSetOrder(8))  // F1_FILIAL+F1_CHVNFE 
   SF2->(DbOrderNickName("IT_CHVNF2") ) // F2_CHVNFE (Ordem J no dicionario)
   
   _nTamFil   := TamSX3('F1_FILIAL')[1]
   _nTamChave := TamSX3('F1_CHVNFE')[1]    
   _nconta := 1          
   
   While ! QRYCKO->(Eof())    
   
   	  _lgravacko := .T.
   
   	  If _lPreparaAmbiente
   
   		  u_itconout("Gravando muros do registro " + StrZero(_nconta,8) + " de " + StrZero(_ntotal,8))       
   		
   	  Else
   	
           IncProc("Gravando muros do registro " + StrZero(_nconta,8) + " de " + StrZero(_ntotal,8))

   		  _nconta++
   	
   	  EndIf   	
      
      CKO->(DBGoTo(QRYCKO->NRRECNO)) 
      
      //Gera o Objeto XML
      _cXmlCKO := AllTrim(CKO->CKO_XMLRET) 

      // Remover a TAG CDATA do XML do CTE a ser enviado para o sistema RDC. 
      _cXmlCKO := StrTran(_cXmlCKO,"<xObs><![CDATA[","<xObs>")
      
      _cXmlCKO := StrTran(_cXmlCKO,"<xObs><![cdata[","<xObs>")
      
      _cXmlCKO := StrTran(_cXmlCKO,"<xObs><![cData[","<xObs>")
      
      _cXmlCKO := StrTran(_cXmlCKO,"<xObs><![CData[","<xObs>")
      
      _cXmlCKO := StrTran(_cXmlCKO,"<xObs><![Cdata[","<xObs>")
          
      _cXmlCKO := StrTran(_cXmlCKO,"]]></xObs>","</xObs>")
      
      _nI := At("<",_cXmlCKO)
      If _nI > 1 //.And. SubStr(_cXmlCKO,1,1) == "?" 
         _nJ := Len(_cXmlCKO)
         _cXmlCKO := SubStr(_cXmlCKO,_nI,_nJ) // Alguns XML possuem caracteres ? antes da primeira Tag. Esta instrução remove os caracteres ? antes da primeira tag. 
      EndIf
      
      _oXml := XmlParser(_cXmlCKO, "_", @_cError, @_cWarning ) 
      
      If (_oXml == NIL )
	     u_itconout("Falha ao gerar Objeto XML : "+SubStr(_cError,1,10000)+" / "+SubStr(_cWarning,1,10000))	
	     _lgravacko := .F.
      EndIf       

      //=======================================================
      // Trecho exclusivo para leitura de XML de CTE Normal
      //=======================================================
      If "CTEPROC" $ Upper(_cXmlCKO) // CTE Normal

         If _lgravacko .and. (_lCTEComplemento := ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE,"_INFCTECOMP")) = "O") 
            If ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTECOMP,"_CHAVE")) = "O"
               _cChave := AllTrim(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTECOMP:_CHAVE:TEXT)
            ElseIf ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTECOMP,"_CHCTE")) = "O"
               _cChave := AllTrim(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTECOMP:_CHCTE:TEXT)
            Else
		 			//Se o complemento não tem 
			      //referencia valida grava para não ler mais
               CKO->(Reclock("CKO",.F.))
               CKO->CKO_I_RDC  := 'S'
               CKO->(MsUnLock())
		 
               QRYCKO->(DbSkip())
               Loop
            EndIf

            //procura se cte vinculado existe na ZG0
            ZG0->(DBSetOrder(4))  // ZG0_CHAVE                                                                                                                                                       
            _lAchouCTEOri:=ZG0->(DBSeek(_cChave))
  
            If !_lAchouCTEOri
         
         	   //Se o complemento tem mais de 30 dias sem referência válida marca para não ler cko mais
         	   If CKO->CKO_DT_RET < (Date()-30)
         	
         		   CKO->(Reclock("CKO",.F.))
         		   CKO->CKO_I_RDC  := 'S'
         		   CKO->(MsUnLock())
         		
         	   EndIf
	     
               QRYCKO->(DbSkip())
               Loop
            EndIf
         EndIf

	      If _lgravacko
	  
            _cChave      := AllTrim(_oXml:_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:Text)
            _cNrCTE      := AllTrim(_oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_NCT:Text)
            _cNrCTE      := StrZero(Val(_cNrCTE),9) 
            _cSerieCTE   := _oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_SERIE:Text
            _cEmissaoCTE := Substr(_oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_DHEMI:Text,1,10)
            _cEmissaoCTE := AllTrim(StrTran(_cEmissaoCTE,"-",""))
            _cCnpjTransp := _oXml:_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:Text
            _cRazaoTrans := _oXml:_CTEPROC:_CTE:_INFCTE:_EMIT:_XNOME:Text

         EndIf
      
	      If !_lCTEComplemento .and. _lgravacko

            _cChave := AllTrim(_oXml:_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:Text)
        
            // Verifica se as notas fiscais de saída que deram origem ao CTE já foram
            // integradas ao RDC.
            _cXmlDeNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE,"_INFCTENORM")
 
            If _lgravacko .and. ValType(_cXmlDeNFE) <> "O" 
               //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
	            _lgravacko := .F.
	         EndIf   
           
            If _lgravacko .and. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "O" .And. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "A"
               //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
   	         _lgravacko := .F.                                             
            EndIf
      
            If _lgravacko 
               _cXmlDeNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC,"_INFNFE")
            EndIf
      
            If _lgravacko .and.  ValType(_cXmlDeNFE) <> "O" .And. ValType(_cXmlDeNFE) <> "A"
              // u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
	            _lgravacko := .F.
            EndIf

            //Se não tem vínculo válido com nfe marca o cko como lido mas não gera nada
            If .not. _lgravacko
               CKO->(Reclock("CKO",.F.))
               CKO->CKO_I_RDC  := 'S'
               CKO->(MsUnLock())
            
               QRYCKO->(DbSkip())
               Loop
            EndIf

            _cInfoNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE
            _nQtdNFE := 1
            If ValType(_cInfoNFE) == "A"
               _nQtdNFE := Len(_cInfoNFE)
            EndIf
      
            _lEnviadoRDC := .F.
            _lEncerraCKO := .T.
      
            _anotas := {}
            _cnump := "  "
            _cchavep := "  "
      
            For _nI := 1 To _nQtdNFE
      
        	       _cnump := "  "
      	       _cchavep := "  "
      
                If _nQtdNFE == 1                                          
                   _cNroNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE,"_CHAVE")
                   _cnump := _cNroNFE
             
                   If ValType(_cNroNFE) <> "O" .And. ValType(_cNroNFE) <> "A"
                      If ValType(_cInfoNFE:TEXT) == "C"
                         _cChaveNFE := _cInfoNFE:TEXT
                         _cchavep := _cChaveNFE
                      Else
                         _lgravacko := .F.
                      EndIf
                   Else
                      _cChaveNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE:_CHAVE:TEXT
                      _cchavep := _cChaveNFE
                   EndIf
                Else
                   _cChaveNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE[_nI]:_CHAVE:TEXT   
                   _cchavep := _cChaveNFE          
                EndIf         
           
                If _lgravacko
                   SF2->(DbOrderNickName("IT_CHVNF2") )      
                   If ! SF2->(DBSeek(PadR(_cChaveNFE,_nTamChave," ")))
                      _lEnviadoRDC := .F.
                   Else
                      If _lEncerraCKO .And. SF2->F2_I_SITUA <> 'N' .And. SF2->F2_CARGA <> ' ' .And. SF2->F2_I_SITUAC <> 'O'
                         _lEncerraCKO := .F.
                      EndIf
                      If (SF2->F2_I_SITUA <> 'P' .And. SF2->F2_I_SITUA <> 'I') .Or. Empty(SF2->F2_CARGA)
                         _lEnviadoRDC := .F.
                      ElseIf (SF2->F2_I_SITUA == 'P' .OR. SF2->F2_I_SITUA == 'I') .And. ! Empty(SF2->F2_CARGA) 
                         _lEnviadoRDC := .T.   //Se foi enviado para o RDC pode criar ZG0 e marcar o CKO para não rodar mais	
                      EndIf
                   EndIf   
          
                   aAdd(_anotas,{_cnump,_cchavep})
		          EndIf
            Next 
          
            If ! _lEnviadoRDC
               //u_itconout("As Notas Fiscais de saída do CTE: "+_cNrCTE+"-"+_cSerieCTE+", ainda não foram integradas para o sistema RDC.")	
	            _lgravacko := .F.
       
               //Se o complemento tem mais de 30 dias sem ser enviado marca para não ler cko mais
               //Se for carga não enviada para o rdc também marca para não ler mais
               If CKO->CKO_DT_RET < (Date()-30) .OR. _lEncerraCKO
         		   CKO->(Reclock("CKO",.F.))
         		   CKO->CKO_I_RDC  := 'S'
         		   CKO->(MsUnLock())
               EndIf
            EndIf
         EndIf
      
      //===========================================================
      // Trecho exclusivo para leitura de XML de CTE Simplificado
      //===========================================================
      Else 
	      If _lgravacko
	  
            _cChave      := AllTrim(_oXml:_CTESIMPPROC:_PROTCTE:_INFPROT:_CHCTE:Text)
            _cNrCTE      := AllTrim(_oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_IDE:_NCT:Text)
            _cNrCTE      := StrZero(Val(_cNrCTE),9) 
            _cSerieCTE   := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_IDE:_SERIE:Text
            _cEmissaoCTE := Substr(_oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_IDE:_DHEMI:Text,1,10)
            _cEmissaoCTE := AllTrim(StrTran(_cEmissaoCTE,"-",""))
            _cCnpjTransp := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_EMIT:_CNPJ:Text
            _cRazaoTrans := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_EMIT:_XNOME:Text
        
            // Verifica se as notas fiscais de saída que deram origem ao CTE já foram
            // integradas ao RDC.
            _cXmlDeNFE := XmlChildEx(_oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET,"_INFNFE")
 
            If _lgravacko .and. (ValType(_cXmlDeNFE) <> "O" .AND. ValType(_cXmlDeNFE) <> "A" )
               //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
	            _lgravacko := .F.
	         EndIf   
           
            //If _lgravacko .and. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "O" .And. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "A"
            If _lgravacko 
               If ValType(_cXmlDeNFE) == "O" .And. ValType(XmlChildEx(_oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE,"_CHNFE")) <> "O" 
                  //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
   	            _lgravacko := .F.
               ElseIf  ValType(_cXmlDeNFE) == "A" .And.  ValType(XmlChildEx(_oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE[1],"_CHNFE")) <> "O"                                             
                  _lgravacko := .F.
               EndIf 
            EndIf
      
           // If _lgravacko .and.  ValType(_cXmlDeNFE) <> "O" .And. ValType(_cXmlDeNFE) <> "A"
               //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
	        //    _lgravacko := .F.
           // EndIf

            //Se não tem vínculo válido com nfe marca o cko como lido mas não gera nada
            If .not. _lgravacko
               CKO->(Reclock("CKO",.F.))
               CKO->CKO_I_RDC  := 'S'
               CKO->(MsUnLock())
            
               QRYCKO->(DbSkip())
               Loop
            EndIf

            _cInfoNFE := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE 
            _nQtdNFE := 1
            If ValType(_cInfoNFE) == "A"
               _nQtdNFE := Len(_cInfoNFE)
            EndIf
      
            _lEnviadoRDC := .F.
            _lEncerraCKO := .T.
      
            _anotas := {}
            _cnump := "  "
            _cchavep := "  "
      
            For _nI := 1 To _nQtdNFE
        	       _cnump := "  "
      	       _cchavep := "  "
      
                If _nQtdNFE == 1                                          
                   _cNroNFE := XmlChildEx(_oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE,"_CHNFE")
                   _cnump := _cNroNFE
             
                   If ValType(_cNroNFE) <> "O" .And. ValType(_cNroNFE) <> "A"
                      If ValType(_cInfoNFE:TEXT) == "C"
                         _cChaveNFE := _cInfoNFE:TEXT
                         _cchavep := _cChaveNFE
                      Else
                         _lgravacko := .F.
                      EndIf
                   Else
                      If ValType(_cNroNFE) == "A" 
                         _cChaveNFE := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE[1]:_CHNFE:TEXT //_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE:_CHAVE:TEXT
                         _cchavep := _cChaveNFE
                      Else 
                         _cChaveNFE := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE:_CHNFE:TEXT //_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE:_CHAVE:TEXT
                         _cchavep := _cChaveNFE
                      EndIf 
                   EndIf
                Else
                   _cChaveNFE := _oXml:_CTESIMPPROC:_CTESIMP:_INFCTE:_DET:_INFNFE[_nI]:_CHNFE:TEXT //_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE[_nI]:_CHAVE:TEXT   
                   _cchavep := _cChaveNFE          
                EndIf         
           
                If _lgravacko
                   SF2->(DbOrderNickName("IT_CHVNF2") )      
                   If ! SF2->(DBSeek(PadR(_cChaveNFE,_nTamChave," ")))
                      _lEnviadoRDC := .F.
                   Else
                      If _lEncerraCKO .And. SF2->F2_I_SITUA <> 'N' .And. SF2->F2_CARGA <> ' ' .And. SF2->F2_I_SITUAC <> 'O'
                         _lEncerraCKO := .F.
                      EndIf
                      If (SF2->F2_I_SITUA <> 'P' .And. SF2->F2_I_SITUA <> 'I') .Or. Empty(SF2->F2_CARGA)
                         _lEnviadoRDC := .F.
                      ElseIf (SF2->F2_I_SITUA == 'P' .OR. SF2->F2_I_SITUA == 'I') .And. ! Empty(SF2->F2_CARGA) 
                         _lEnviadoRDC := .T.   //Se foi enviado para o RDC pode criar ZG0 e marcar o CKO para não rodar mais	
                      EndIf
                   EndIf   
          
                   aAdd(_anotas,{_cnump,_cchavep})
		          EndIf
            Next 
          
            If ! _lEnviadoRDC
               //u_itconout("As Notas Fiscais de saída do CTE: "+_cNrCTE+"-"+_cSerieCTE+", ainda não foram integradas para o sistema RDC.")	
	            _lgravacko := .F.
       
               //Se o complemento tem mais de 30 dias sem ser enviado marca para não ler cko mais
               //Se for carga não enviada para o rdc também marca para não ler mais
               If CKO->CKO_DT_RET < (Date()-30) .OR. _lEncerraCKO
         		   CKO->(Reclock("CKO",.F.))
         		   CKO->CKO_I_RDC  := 'S'
         		   CKO->(MsUnLock())
               EndIf
            EndIf
         EndIf

      EndIf 

      // Caso já exista nota fiscal de entrada, grava os dados da nota fiscal de entrada
      // na tabela de muro ZG0.
      If SF1->(DBSeek(PadR(CKO->CKO_FILPRO,_nTamFil," ") + PadR(_cChave,_nTamChave," ")))
                         //   Filial    ,Nota fiscal   Serie         Fornecedor       Loja forn.
         _aDadosForn := {PadR(CKO->CKO_FILPRO,_nTamFil," "),SF1->F1_DOC ,SF1->F1_SERIE ,SF1->F1_FORNECE ,SF1->F1_LOJA}    	 	                                                                                                                       
      Else
         _aDadosForn := {PadR(CKO->CKO_FILPRO,_nTamFil," "),"" ,"" ,"" ,""}
      EndIf
      
      // Grava Tabela de Muro com o XML do CTE.
      //Só grava se não existir registro com a mesma chave de CTE
      //Para evitar regravação em reconstruções da CKO
      ZG0->(DBSetOrder(4))
      If !(ZG0->(DBSeek(_cChave))) .And. _lgravacko 
            
      	ZG0->(RecLock("ZG0",.T.))
      	ZG0->ZG0_FILIAL   := PadR(CKO->CKO_FILPRO,_nTamFil," ")	// Filial do Sistema
      	ZG0->ZG0_HORA     := Time()             // Hora de inclusão do registro na tabela de muro.
      	ZG0->ZG0_DATA	    := Date()             // Data de Emissão
      	ZG0->ZG0_XMLCTE   := _cXmlCKO // CKO->CKO_XMLRET	  // XML do CTE
      	ZG0->ZG0_CHAVE    := _cChave            // Chave do CTE
      	ZG0->ZG0_NOTAEN	:= _aDadosForn[2]     //C	Nota Fiscal Transporte
      	ZG0->ZG0_SERIE	:= _aDadosForn[3]     //C	Serie Nota Fiscal Transp.
      	ZG0->ZG0_FORNEC	:= _aDadosForn[4]     //C	Fornecedor Nota Fiscal
      	ZG0->ZG0_LOJAFO	:= _aDadosForn[5]     //C	Loja do Fornecedor NF.
      	ZG0->ZG0_EMICTE   := SToD(_cEmissaoCTE) // DATA EMISSAO CTE
      	ZG0->ZG0_NUMCTE   := _cNrCTE            // NUMERO CTE
      	ZG0->ZG0_SERCTE   := _cSerieCTE         // SERIE CTE 
      	ZG0->ZG0_TRACTE   := _cRazaoTrans       // TRANSPORTADORA CTE
      	ZG0->ZG0_CGCCTE   := _cCnpjTransp       // CNPJ TRANSP. CTE
      	ZG0->ZG0_USUARI   := __cUserId          // Codigo do Usuário	
      	ZG0->ZG0_DATAAL   := Date()	          // Data de Alteração
      	ZG0->ZG0_SITUAC   := "N"	              // Situação do Registro
      	ZG0->ZG0_CODEMP   := _cCodEmpWS         // Codigo Empresa WebServer
        ZG0->ZG0_RETORN   := "CTE "+If(_lCTEComplemento,"COMPLEMENTAR","NORMAL")//Marca o tipo do CTE para analise
        ZG0->ZG0_A00001   := "CTE "+If(_lCTEComplemento,"COMPLEMENTAR","NORMAL")//Marca o tipo do CTE para analise
      	ZG0->ZG0_FLUXO    := "1"                // Fluxo da Integração
      	ZG0->(MSUnLock())

      ElseIf _lgravacko 
      
      		//Se ia gravar mas já tem gravado só marca para não gravar mais
           	CKO->(RecLock("CKO",.F.))
         	CKO->CKO_I_RDC  := 'S'
         	CKO->(MSUnLock())
      
      Else
      
           	//Se o complemento tem mais de 30 dias sem referência válida marca para não ler cko mais
         	If CKO->CKO_DT_RET < (Date()-30)
         	
         		CKO->(RecLock("CKO",.F.))
         		CKO->CKO_I_RDC  := 'S'
         		CKO->(MSUnLock())
         		
         	EndIf
      
      EndIf
      
  
      If !_lCTEComplemento .And. _lgravacko

         For _nI := 1 to Len(_anotas)
      
        	ZGC->(DBSetOrder(2))
      	
        	If !(ZGC->(DBSeek(_cChave+_anotas[_nI][2])))  //Só grava se não tiver registro com mesma chave de cte + chave de nota vinculada
      
      	     	// Grava tabela de cubo de dados de ctes recebidas
        		ZGC->(RecLock("ZGC",.T.))
        		ZGC->ZGC_FILIAL   := PadR(CKO->CKO_FILPRO,_nTamFil," ")	// Filial do Sistema
        		ZGC->ZGC_HORA     := Time()             // Hora de inclusão do registro na tabela de muro.
        		ZGC->ZGC_DATA	    := Date()             // Data de Emissão
        		ZGC->ZGC_CHAVE    := _cChave            // Chave do CTE
        		ZGC->ZGC_NOTAEN	:= _aDadosForn[2]     //C	Nota Fiscal Transporte
        		ZGC->ZGC_SERIE	:= _aDadosForn[3]     //C	Serie Nota Fiscal Transp.
        		ZGC->ZGC_FORNEC	:= _aDadosForn[4]     //C	Fornecedor Nota Fiscal
        		ZGC->ZGC_LOJAFO	:= _aDadosForn[5]     //C	Loja do Fornecedor NF.
        		ZGC->ZGC_EMICTE   := SToD(_cEmissaoCTE) // DATA EMISSAO CTE
        		ZGC->ZGC_NUMCTE   := _cNrCTE            // NUMERO CTE
        		ZGC->ZGC_SERCTE   := _cSerieCTE         // SERIE CTE 
        		ZGC->ZGC_TRACTE   := _cRazaoTrans       // TRANSPORTADORA CTE
        		ZGC->ZGC_CGCCTE   := _cCnpjTransp       // CNPJ TRANSP. CTE
        		ZGC->ZGC_USUARI   := __cUserId          // Codigo do Usuário	
        		ZGC->ZGC_DATAAL   := Date()	          // Data de Alteração
        		ZGC->ZGC_RCKOL	:= AllTrim(Str(CKO->(Recno())))	  // Vinculo com CKO
      		
        		ZGC->ZGC_A00004 := _anotas[_nI][2]
      
        		If _lEnviadoRDC //Se achou sf2 e foi enviado para o rdc grava pelo menos um vinculo com a sf2
      
        			ZGC->ZGC_RSF2		:= AllTrim(Str(SF2->(Recno())))	  // Vinculo com SF2
      	
        		EndIf
      
        		ZGC->(MSUnLock())
      		
        	EndIf
      	
         Next

      EndIf
 
      // Grava flag na tabela CKO para informar que o XML já foi para tabela de muro.
      // Só não grava se For cte de nota válida mas ainda não enviada para o RDC
      If _lEnviadoRDC
      	CKO->(RecLock("CKO",.F.))
      	CKO->CKO_I_RDC  := 'S'
      	CKO->(MSUnLock())
      EndIf
       
      QRYCKO->(DBSkip())
      
      // DelClassIntf() = Este comando elimina da memória do computador todos os objetos criados na Thred.
      _oXml := Nil 
      _cXmlDeNFE := Nil

      DelClassIntf()
      
   EndDo

End Sequence

u_itconout("Termino da Integração dos XML CTE para a tabela de muro ZG0.")

If Select("QRYCKO") > 0
   QRYCKO->(DBCloseArea())
EndIf

If _lIntCteManual // Integração de dados CTE manual (True), ou Integração de dados via Scheduller(False).

     U_ITMsg("Processamento concluído","Fim de processamento",,2) 

EndIf


Return    

/*
===============================================================================================================================
Programa----------: AOMS091Z(_lPreparaAmbiente,_oProc)
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/02/2017
Descrição---------: Rotina de leitura dos XML da tabela de muro ZG0 e integra para o sistema RDC
Parametros--------: _lPreparaAmbiente =  .T. = Preparar ambiente antes de rodar a rotina.
                                         .F. = Não preparar ambiente antes de rodar a rotina.
                    
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091Z(_lPreparaAmbiente)

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cDet_XML := ""
Local _cRodXML := "" 
Local _cXML 
Local _cResult := ""
Local _nI
Local _cResposta, _cSituacao
Local _cCodEmpWS
Local _cQry
Local _cAssunto
Local _aDadosForn
Local _lIntCteManual := SuperGetMV('IT_INTCTEM',.T.,.T.) // Integração de dados CTE manual (True), ou Integração de dados via Scheduller(False).
Local _lReguaProgres := .F., _nTotRegs, _nNrRegAtu

Default _lPreparaAmbiente := .T.

Begin Sequence             
   If _lIntCteManual // Integração de dados CTE manual (True), ou Integração de dados via Scheduller(False).
      ProcRegua(0)

      _lPreparaAmbiente := .F. 
      If !U_ITMsg("Confirma a o envio dos XML do CTE para o Sistema RDC?","Confirmação de envio",,2,2,2) 
         Break
      EndIf
   EndIf
  
   u_itconout("Inicio da Integração dos XML CTE para da tabela de muro ZG0, para o sistema RDC.")            
   
   If _lPreparaAmbiente
      // Limpa o ambiente, liberando a licença e fechando as conexões
      RpcClearEnv() 
      RpcSetType(2)

      // Prepara ambiente abrindo tabelas e incializando variaveis.
      RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6"})

      cFilAnt := "01"
   EndIf
                      
   _cCodEmpWS := SuperGetMV('IT_EMPWEBSE',.T.,'000001')
   
   // Determina se será atualizado a a regua de progresso, através da função FWMsgRun
   If ! _lPreparaAmbiente //ValType(_oProc) <> "U"
      _lReguaProgres := .T.   
   EndIf          
   
   // Monta e roda a query de contagem de dados
   If _lReguaProgres   
      _cQryC := " SELECT COUNT(*) AS NTOTREG FROM "+RETSQLNAME("ZG0")+" ZG0 "
      _cQryC += " WHERE ZG0.D_E_L_E_T_ = ' ' AND ZG0_SITUAC = 'N' "
   
      If Select("QRYZG0C") > 0
         QRYZG0C->(DBCloseArea())
      EndIf
   
      u_itconout("Rodando Query de contagem de dados.")
           
      _cQryC := ChangeQuery(_cQryC) 
      //DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQryC), "QRYZG0C", .F., .T.)
      MPSysOpenQuery( _cQryC , "QRYZG0C")
      DBSelectArea("QRYZG0C")
   
      If QRYZG0C->(Eof()) .Or. QRYZG0C->(Bof())
         Break
      EndIf
      
      _nTotRegs  := QRYZG0C->NTOTREG
      _nNrRegAtu := 1 
   EndIf
   
   // Monta e roda a query de seleção de dados
   _cQry := " SELECT R_E_C_N_O_ AS NRRECNO FROM "+RETSQLNAME("ZG0")+" ZG0 "
   _cQry += " WHERE ZG0.D_E_L_E_T_ = ' ' AND ZG0_SITUAC = 'N' "
   
   If Select("QRYZG0") > 0
      QRYZG0->(DBCloseArea())
   EndIf
   
   u_itconout("Rodando Query de leitura dos dados.")
           
   _cQry := ChangeQuery(_cQry) 
   //DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYZG0", .F., .T.)
   MPSysOpenQuery( _cQry , "QRYZG0")
   DBSelectArea("QRYZG0")
   
   If QRYZG0->(Eof()) .Or. QRYZG0->(Bof())
      Break
   EndIf         

   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   u_itconout("Identificando diretório dos XML...")                    
   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cCodEmpWS))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else            
      u_itconout("Empresa WebService para envio dos dados não localizada.")
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      u_itconout("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      Break                                     
   EndIf
      
   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf

   // Lê os arquivos modelo XML e os transforma em String.
   u_itconout("Lendo arquivo XML Modelo de Cabeçalho...")                      
   
   _cCabXML := U_AOMS091X(_cDirXML+"Cab_EnviaCTE.txt") 
   If Empty(_cCabXML)
      u_itconout("Erro na leitura do arquivo XML modelo do cabeçalho de envio da chave do CTE(Conhecimento de Transporte Eletrônico). ")
      Break
   EndIf
   
   u_itconout("Lendo arquivo XML Modelo de Detalhe ...")
   
   _cDet_XML := U_AOMS091X(_cDirXML+"Det_EnviaCTE.txt")
   If Empty(_cDet_XML)
      u_itconout("Erro na leitura do arquivo XML modelo do detalhe de envio da chave do CTE(Conhecimento de Transporte Eletrônico).")
      Break
   EndIf            
   
   u_itconout("Lendo arquivo XML Modelo de Rodapé...")
   
   _cRodXML := U_AOMS091X(_cDirXML+"Rodape_EnviaCTE.txt")
   If Empty(_cRodXML)
      u_itconout("Erro na leitura do arquivo XML modelo do rodapé de envio da chave do CTE(Conhecimento de Transporte Eletrônico).")
      Break
   EndIf
     
   // Ativa a classe de envio de dados.
   u_itconout("Montando dados de envio...")

   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
   oWsdl:nTimeout := 60          // Timeout de 10 segundos                                                               
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                               
   
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
   oWsdl:SetOperation("EnviaCte") // Define qual operação será realizada.
   
   SF1->(DBSetOrder(8)) // F1_FILIAL+F1_CHVNFE 
   
   While ! QRYZG0->(Eof())
      // Exibe e atualiza Regua de progresso de envio dos dados para o Sistema RDC.
      If _lReguaProgres
 
         IncProc("Enviando Registro " + StrZero(_nNrRegAtu,8) + " de " + StrZero(_nTotRegs,8))
         
         _nNrRegAtu++
      EndIf
      
      // Inicio da integração e envio de dados.
      ZG0->(DBGoTo(QRYZG0->NRRECNO)) 
   
      For _nI := 1 To ZG0->(FCount())
          &("M->"+ZG0->(FieldName(_nI))) := &("ZG0->"+ZG0->(FieldName(_nI)))
      Next
   
      // Realiza a integração dos CTEs (Envio de XML) via WebService.
                     
      //Monta XML
      _cXMLCTE:=&(_cDet_XML)
      If (nPosIni:=AT("<QRCODCTE><![CDATA",Upper(_cXMLCTE))) > 0//se tiver essa TAG com a TAG ![CDATA[]]
         If (nPosFim:=AT("</QRCODCTE>",Upper(_cXMLCTE))) > 0
            nPosIni:=nPosIni+Len("<QRCODCTE")
//Estou retirando esses dados dos XLM: <![CDATA[https://dfe-portal.svrs.rs.gov.br/cte/qrCode?chCTe=52190803176032000726570200000005121000005129&tpAmb=1]]>
//De dentro da TAG <qrCodCTe></qrCodCTe> PQ não pode ter a TAG ![CDATA[]] dentro de outra TAG ![CDATA[]]
            _cXMLCTE:=SubStr(_cXMLCTE,1, nPosIni)+SubStr(_cXMLCTE,nPosFim)
         EndIf
      EndIf
      
      _cXML := _cCabXML + _cXMLCTE + _cRodXML  // Monta o XML de envio.

      // Remover a TAG CDATA do XML do CTE a ser enviado para o sistema RDC. 
      _cXML := StrTran(_cXML,"<xObs><![CDATA[","<xObs>")  
      
      _cXML := StrTran(_cXML,"<xObs><![cdata[","<xObs>")
      
      _cXML := StrTran(_cXML,"<xObs><![cData[","<xObs>")
      
      _cXML := StrTran(_cXML,"<xObs><![CData[","<xObs>")
      
      _cXML := StrTran(_cXML,"<xObs><![Cdata[","<xObs>")
          
      _cXML := StrTran(_cXML,"]]></xObs>","</xObs>")
 		    
      // Envia para o servidor
      _cOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
            
      If _cOk 
         _cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.
      Else
         _cResult := oWsdl:cError
      EndIf 
            
      _cResposta := AllTrim(StrTran(_cResult,Chr(10)," "))
      _cResposta := Upper(_cResposta)
            
      // "Importado Com Sucesso"
      _cSituacao := "P"
                           
      If ! _cOk             
         _cSituacao := "N" 
      ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta)       	
         _cSituacao := "N"
      EndIf
               
      // Caso já exista nota fiscal de entrada, grava os dados da nota fiscal de entrada
      // na tabela de muro ZG0.
      If SF1->(DBSeek(ZG0->ZG0_FILIAL+ZG0->ZG0_CHAVE))
                     //   Filial        ,Nota fiscal  Serie   Fornecedor  Loja forn.
         _aDadosForn := {ZG0->ZG0_FILIAL,SF1->F1_DOC ,SF1->F1_SERIE ,SF1->F1_FORNECE ,SF1->F1_LOJA}    	 	                                                                                                                       
      Else
         _aDadosForn := {ZG0->ZG0_FILIAL,"" ,"" ,"" ,""}
      EndIf

      // Grava resultado // sempre como processado
      ZG0->(RecLock("ZG0",.F.))  
      If ! Empty(_aDadosForn[2])                                       
         M->ZG0_NOTAEN	:= _aDadosForn[2] //C	Nota Fiscal Transporte
         M->ZG0_SERIE	:= _aDadosForn[3] //C	Serie Nota Fiscal Transp.
         M->ZG0_FORNEC	:= _aDadosForn[4] //C	Fornecedor Nota Fiscal
         M->ZG0_LOJAFO	:= _aDadosForn[5] //C	Loja do Fornecedor NF.
         ZG0->ZG0_NOTAEN	:= _aDadosForn[2] //C	Nota Fiscal Transporte
         ZG0->ZG0_SERIE	:= _aDadosForn[3] //C	Serie Nota Fiscal Transp.
         ZG0->ZG0_FORNEC	:= _aDadosForn[4] //C	Fornecedor Nota Fiscal
         ZG0->ZG0_LOJAFO	:= _aDadosForn[5] //C	Loja do Fornecedor NF.
      EndIf
         
      ZG0->ZG0_FLUXO   := If(_cSituacao == "P","2","1") // "2"
      ZG0->ZG0_SITUAC  := If(_cSituacao == "P","E","N") // If(_cSituacao == "P","E","P")  // "E" = Indica que foi enviado para a RDC e aguarda XML de Retorno. // "N" = Houve rejeição e este registro será reenviado. Um novo registro será criado para histórico.
      ZG0->ZG0_USUARI  := __cUserId
      ZG0->ZG0_DATAAL  := Date()
      ZG0->ZG0_RETORN  := _cResposta // grava o resultado da integração na tabela ZFQ,dizendo que deu certo ou não.
      ZG0->ZG0_XML     := _cXML
      ZG0->(MSUnLock()) 
         
      If _cSituacao == "N"      
         ZG0->(RecLock("ZG0",.T.))           
         For _nI := 1 To ZG0->(FCount())
             &("ZG0->"+ZG0->(FieldName(_nI))) := &("M->"+ZG0->(FieldName(_nI))) 
         Next   
         ZG0->ZG0_FLUXO   := "2" // "1"
         ZG0->ZG0_SITUAC  := "R" // Rejeitado e aguardando reenvio.
         ZG0->ZG0_USUARI  := __cUserId
         ZG0->ZG0_DATAAL  := Date()
         ZG0->ZG0_RETORN  := _cResposta // grava o resultado da integração na tabela ZFQ,dizendo que deu certo ou não. 
         ZG0->ZG0_XML     := _cXML
         ZG0->(MSUnLock())      
         // Enviar e-mail avisando a rejeição.
         _cAssunto := ZG0->ZG0_FILIAL + "-" + AllTrim( Posicione('SM0',1,cEmpAnt+ZG0->ZG0_FILIAL,'M0_FILIAL') ) + " XML do CTE de Chave: "+ZG0->ZG0_CHAVE + " - REJEITADO PELO RDC - "+ZG0->ZG0_TRACTE
            
         _cNomeFilial:= ZG0->ZG0_FILIAL + "-" + AllTrim( Posicione('SM0',1,cEmpAnt+ZG0->ZG0_FILIAL,'M0_FILIAL') )
                                                              
         _aDadosCTE := {}
         aAdd(_aDadosCTE,ZG0->ZG0_EMICTE)  // DATA EMISSAO CTE
         aAdd(_aDadosCTE,ZG0->ZG0_NUMCTE)  // NUMERO CTE
         aAdd(_aDadosCTE,ZG0->ZG0_SERCTE)  // SERIE CTE 
         aAdd(_aDadosCTE,ZG0->ZG0_TRACTE)  // TRANSPORTADORA CTE
         aAdd(_aDadosCTE,ZG0->ZG0_CGCCTE)  // CNPJ TRANSP. CTE
         aAdd(_aDadosCTE,_cNomeFilial)     // Cod.Filial - Nome Filial
             
         U_AOMS091E(ZG0->ZG0_FILIAL,ZG0->ZG0_CHAVE ,_aDadosCTE,_cAssunto,_cResposta,.T.)
      EndIf   
            
      Sleep(100) //Espera para não travar a comunicação com o webservice da RDC

      QRYZG0->(DBSkip())
   
   EndDo

   // DelClassIntf() = Este comando elimina da memória do computador todos os objetos criados na Thred.
   oWSDL := Nil
   DelClassIntf()
 
End Sequence

If Select("QRYZG0") > 0
   QRYZG0->(DBCloseArea())
EndIf

If Select("QRYZG0C") > 0
   QRYZG0C->(DBCloseArea())
EndIf

Return 
          
/*
===============================================================================================================================
Programa----------: AOMS091S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/02/2017
Descrição---------: Rotina para agendamento no Scheduller da integrações CTE.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091S()

 u_itconout("AOMS019S - Inicio ." + time())

Begin Sequence 
   // Limpa o ambiente, liberando a licença e fechando as conexões
   RpcClearEnv() 
   RpcSetType(2)

   // Prepara ambiente abrindo tabelas e incializando variaveis.
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6"})

   cFilAnt := "01"
   
   // Grava dados do CTE nas tabelas de muro.
   u_itconout("Gravando dados dos CTE nas tabela de muro.")
   U_AOMS091C()  
   
   Sleep(1000) // Espera para não travar a comunicação com o webservice da RDC          
   
   // Lê os dados das tabelas de muro e integra os dados do CTE para o sistema RDC.
   u_itconout("Lendo dados dos CTE das tabelas de muro e Integrado para RDC via WebService.")
   U_AOMS091Z(.F.)

End Sequence

Return

/*
===============================================================================================================================
Função-------------: AOMS091X
Aut2or-------------: Julio de Paula Paz
Data da Criacao----: 01/02/2017
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091X(_cArq)
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

   While !FT_FEOF()   
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
Função------------: AOMS091E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/02/2017
Descrição---------: Função de Envio de Email da integração CTE
Parametros--------: _cFilial = Filial de envio.
                    _cChaveCTE = Chave do arquivo XML enviado. 
                    _aDadosCTE = Array com alguns dados do CTE: _aDadosCTE[1]  // DATA EMISSAO CTE
                                                                _aDadosCTE[2]  // NUMERO CTE
                                                                _aDadosCTE[3]  // SERIE CTE 
                                                                _aDadosCTE[4]  // TRANSPORTADORA CTE
                                                                _aDadosCTE[5]  // CNPJ TRANSP. CTE  
                                                                _aDadosCTE[6]  // Cod.Filial + Nome Filial
                    _cAssunto    = Assunto do E-mail.
                    _cObsEmail   = Mensagem enviada no e-mail.
                    _lAutomatico = .T. Rotina enviada de forma agendada / .F. Rotina chamada manualmente.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS091E(_cFilial,_cChaveCTE,_aDadosCTE,_cAssunto,_cObsEmail,_lAutomatico)

Local _cEmail	   := AllTrim(SuperGetMV("IT_EMAILCTE",.T.,""))
Local _cEmailCC    := AllTrim(SuperGetMV("IT_MAILCCTE",.T.,"")) 
Local _aConfig	   := U_ITCFGEML('')
Local _cMsgEml	   := ''
Local _cData       := DToC( Date() )
Local _cNomeFilial := ""
Local _cMailUser   := ""
                    
Default _lAutomatico := .T.

Begin Sequence
   If Empty( _cEmail )
      If ! _lAutomatico
         U_ITMsg("Nenhum e-mail de envio foi informado.","Atenção",,1)
      Else
         u_itconout("Nenhum e-mail de envio foi informado.")
      EndIf	
      Break
   Else
      _cCTE_Emissao    := _aDadosCTE[2] + " " + _aDadosCTE[3] + " - " + DToC(_aDadosCTE[1])  // Nr_CTE Serie /  DD/MM/AA
      _cCNPJ_Transport := Transform(_aDadosCTE[5],"@R! NN.NNN.NNN/NNNN-999") + " - " +  _aDadosCTE[4]
      _cNomeFilial :=  _aDadosCTE[6]  // Cod.Filial + Nome Filial
      
      _cMsgEml := '<html>'
      _cMsgEml += '<head><title>Integração de Envio de XML CTE da Italac para RDC</title></head>'
      _cMsgEml += '<body>'
      _cMsgEml += '<style Type="text/css"><!--'
      _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
      _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
      _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
      _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
      _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
      _cMsgEml += '--></style>'
      _cMsgEml += '<center>'
      _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
      _cMsgEml += '<table class="bordasimples" width="600">'
      _cMsgEml += '    <tr>'
      _cMsgEml += '	     <td class="titulos"><center>'+"XML DO CTE - REJEITADO PELO SISTEMA RDC"+'</center></td>'
      _cMsgEml += '	 </tr>'
      _cMsgEml += '</table>'
      _cMsgEml += '<br>'
      _cMsgEml += '<table class="bordasimples" width="600">'
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td align="center" colspan="2" class="grupos">Chave CTE <b>'+ _cChaveCTE +'</b></td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Enviado por </b></td>'
      _cMsgEml += '      <td class="itens" >'+"Rotina de Integração CTE Automatico"+'</td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cNomeFilial +'</td>'
      _cMsgEml += '    </tr>'      
   
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Transportador</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cCNPJ_Transport +'</td>'
      _cMsgEml += '    </tr>'
                          
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>CTE / Emissao </b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cCTE_Emissao +'</td>'
      _cMsgEml += '    </tr>'
   
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Data Integração CTE:</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cData +'</td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Observações:</b></td>'
      _cMsgEml += '      <td class="itens" >#OBS#</td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '	<tr>'
      _cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
      _cMsgEml += '    </tr>'
      _cMsgEml += '</table>'
	
      _cMsgEml += '<br>'

      _cMsgEml += '</center>'
   
      If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
         _cMsgEml += '    <tr>'
         _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
         _cMsgEml += '      <td class="itens" align="left" > ['+ GetEnvServer() +'] </td>'
         _cMsgEml += '    </tr>'
      EndIf
   
      _cMsgEml += '</body>'
      _cMsgEml += '</html>'
      _cEmlLog := ''
    
      _cMsgEml:=StrTran(_cMsgEml,"#OBS#",_cObsEmail)
    
      // U_ITENVMAIL(cFrom         ,cEmailTo ,cEmailCo  ,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
      U_ITENVMAIL( _aConfig[01] , _cEmail ,_cMailUser,_cEmailCC,_cAssunto, _cMsgEml,          ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
	   
      If !Empty( _cEmlLog ) 
         If _lAutomatico
	        u_itconout("Falha no envio de e-mail na integração Webservice Italac x RDC:")
	        u_itconout(_cEmlLog)
	        u_itconout(" E-mail para: "+_cEmail)
            u_itconout(" Com Copia: "+_cEmailCC)	
         Else
            U_ITMsg("Falha no envio de e-mail na integração Webservice Italac x RDC: " + _cEmlLog + ". E-mail para: "+_cEmail +". Com Copia: "+_cEmailCC,"Falha processo",,1)	
         EndIf
      EndIf
   EndIf

End Sequence

Return .T.

/*
===============================================================================================================================
Função-------------: AOMS091R
Autor-------------: Julio de Paula Paz
Data da Criacao----: 14/03/2017
Descrição----------: Muda a situação do CTE posicionado de Processado ou Rejeitado, para Não Processado, permitindo o reenvio
                     do CTE.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091R()    

Begin Sequence               
   If ! U_ITMsg("Confirma a mudança da Situação do CTE Posicionado para não processado, permitindo o reenvio do CTE para o sistema RDC?","Atenção",,2,2,2)
      Break
   EndIf

   If ZG0->ZG0_SITUAC <> "P" .And. ZG0->ZG0_SITUAC <> "R"
      U_ITMsg("Este CTE não está com situação Processado ou situação Rejeitado. Portanto não pode ter sua situação alterada.","Atenção",1)
      Break
   EndIf
   
   If Empty(ZG0->ZG0_XMLCTE)
      U_ITMsg("Não há XML de CTE vinculado a este registro. Este registro é apenas de histórico da integração.","Validação XML",;
       			"Posicione o cursor sobre um registro que possui um CTE a ser reenviado.",1)
      Break
   EndIf
   
   ZG0->(RecLock("ZG0",.F.))
   ZG0->ZG0_USUARI   := __cUserId   // Codigo do Usuário	
   ZG0->ZG0_DATAAL   := Date()	    // Data de Alteração
   ZG0->ZG0_SITUAC   := "N"	        // Situação do Registro
   ZG0->ZG0_FLUXO    := "1"         // Fluxo da Integração  // 1=Totvs Colaboracao-->Italac;2=Italac-->RDC;3=RDC-->Italac
   ZG0->(MSUnLock())

End Sequence

Return

/*
===============================================================================================================================
Função-------------: AOMS091F
Aut2or-------------: Julio de Paula Paz
Data da Criacao----: 23/07/2021
Descrição----------: Processa CTEs. Grava os XMLs dos CTEs nas Tabelas de Muro para Envio ao RDC.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091F()  

Begin Sequence
   Processa({|| U_AOMS091C()},'Aguarde processamento...','Gravando XMLs CTEs nas Tabelas de Muro...')
End Sequence

Return

/*
===============================================================================================================================
Função-------------: AOMS091G
Aut2or-------------: Julio de Paula Paz
Data da Criacao----: 23/07/2021
Descrição----------: Envia XML p/RDC. Faz a leitura das tabelas de Muro e envio dos XMLs para o sistema RDC.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function AOMS091G()  
   
   Begin Sequence
      Processa({|| U_AOMS091Z(.F.)},'Aguarde processamento...','Enviando XMLs CTEs para o RDC...')
   End Sequence

Return
