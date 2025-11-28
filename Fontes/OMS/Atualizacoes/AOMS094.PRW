/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |06/06/2025| Chamado 39201. Ajuste na rotina de retorno de pedidos de vendas do sistema RDC.
Alex Wallauer |10/06/2025| Chamado 45229. Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP").
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "APWEBSRV.CH"
#Include "TOTVS.ch"  
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: AOMS094
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/03/2017
Descrição---------: Rotina de consulta da integração de dados Cancelamento de Pedidos.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS094

Local _aCores := {}
Private aRotina := {}
Private cCadastro 

//Log de utilização
u_itlogacs()

cCadastro := "Integração dos Dados Cancelamento de Pedido de Vendas Via Webservice: Italac <---> RDC"
aAdd(aRotina,{"Pesquisar"  ,"AxPesqui"   ,0 ,1})
aAdd(aRotina,{"Visualizar" ,"AxVisual"   ,0 ,2})
aAdd(aRotina,{"Legenda"    ,"U_AOMS094L" ,0 ,3})

aAdd(_aCores,{"ZFL_SITUAC == 'N'" ,"BR_VERDE" })
aAdd(_aCores,{"ZFL_SITUAC == 'P'" ,"BR_VERMELHO" })
aAdd(_aCores,{"ZFL_SITUAC == 'R'" ,"BR_AMARELO" })

DBSelectArea("ZFL")
ZFL->(DBSetOrder(1)) 
ZFL->(DBGoTop())
MBrowse(6,1,22,75,"ZFL", , , , , , _aCores)

Return    

/*
===============================================================================================================================
Programa----------: AOMS094L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 01/03/2017
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS094L       

Local _aLegenda := {}

aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })

BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return

/*
===============================================================================================================================
Função------------: AOMS094E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/11/2016
Descrição---------: Gera os dados XML de cancelamento com base no Pedido de Venda selecionado e integra via webservice.
Parametros--------: oproc - objeto de barra de progresso
                    _lExibeTela - .T. = Exibe as mensagens na tela. / .F. = Exibe as mensagens no console.
Retorno-----------: True = integração bem sucedida / False = falha na integração.
===============================================================================================================================
*/  
User Function AOMS094E(oproc,_lExibeTela)             

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cDetXML := ""
Local _cCodEmpWS := SuperGetMV('IT_EMPWEBS',.F.,'000001')
Local _cRodXML := "" 
Local _aOrd := SaveOrd({"ZZM","SA2","ZFM"})
Local _cXML 
Local _cResult := ""
Local _cResposta, _cSituacao
Local _lRet := .F.
Local _nTentativas := SuperGetMV('IT_TENT410',.F.,3)
Local _nI := 0

Default oproc := nil, _lExibeTela := .T.

//Se estiver no webservice não executa
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
	Return
EndIf

Begin Sequence

   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   If ValType(oproc) = "O"

      	oproc:cCaption := ("Identificando diretório dos XML...")
   		ProcessMessages()
 
   EndIf

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cCodEmpWS))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else
      If _lExibeTela
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lExibeTela
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
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
   If ValType(oproc) = "O"
      oproc:cCaption := ("Lendo arquivo XML Modelo de Cabeçalho...")
      ProcessMessages()
   EndIf
    
   _cCabXML := U_AOMS084X(_cDirXML+"Cab_CancelaPedido.txt") 
   
   If Empty(_cCabXML)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo XML modelo do cabeçalho de envio Pedido de Vendas. ","Atenção",,1)
      EndIf
      Break
   EndIf

   If ValType(oproc) = "O"
      oproc:cCaption := ("Lendo arquivo XML Modelo de Detalhe A...")
      ProcessMessages()
   EndIf
   
   _cDetXML := U_AOMS084X(_cDirXML+"DET_CancelaPedido.txt")
   
   If Empty(_cDetXML)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe A de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break
   EndIf            

   If ValType(oproc) = "O"
      oproc:cCaption := ("Lendo arquivo XML Modelo de Rodapé...")
      ProcessMessages()
   EndIf
   
   _cRodXML := U_AOMS084X(_cDirXML+"Rodape_CancelaPedido.txt")
   
   If Empty(_cRodXML)
      If _lExibeTela
         U_ITMsg("Erro na leitura do arquivo XML modelo do rodapé de envio Pedido de Vendas.","Atenção",,1)
      EndIf
      Break
   EndIf
   
   ZZM->(DBSetOrder(1))
   SA2->(DBSetOrder(3)) 
   ZZM->(DBSeek(xFilial("ZZM")+SC5->C5_FILIAL))
   SA2->(DBSeek(xFilial("SA2")+ZZM->ZZM_CGC))   
   
   //================================================================================
   // Concatena os Pedidos de Vendas selecionados e monta array de XML com os dados.
   //================================================================================                       
   If ValType(oproc) = "O"
      oproc:cCaption := ("Montando dados de envio...")
      ProcessMessages()
   EndIf
   
   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
   oWsdl:nTimeout := 120         // Timeout de 120 segundos. Tempo padrão (Default) da classe: tWSDLManager() = 120 segundos. 
   oWsdl:lSSLInsecure := .T.     //   Acessa com certificado anônimo                                                                    
   
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
   oWsdl:SetOperation( "CancelaPedido") // Define qual operação será realizada.
   
   _aresult := {}
   
   Begin Transaction     
      //-----------------------------------------------------------------------------------------
      // Realiza a integração dos pedidos de vendas (Envio de XML) via WebService.
      //-----------------------------------------------------------------------------------------
      //Monta XML
      _cXML := _cCabXML + &(_cDetXML) + _cRodXML  // Monta o XML de envio.
      
      For _nI := 1 To _nTentativas         

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
         _cSituacao := "R"
         _lRet := .F.
         
         If ("IMPORTADO COM SUCESSO" $ _cResposta) 
            _cSituacao := "P"
            _lRet := .T.
         ElseIf ("PEDIDO NAO ENCONTRADO" $ _cResposta) .Or. ("PEDIDO NÃ£O ENCONTRADO" $ _cResposta)  
            _cSituacao := "P"
            _lRet := .T.
         EndIf
          	
         //Ajusta resposta de pedido em carga para incluir o número da viagem
         If " VINCULADO NA CARGA" $ _cResposta
            _cErro := _cResposta
         	DAI->(DBSetOrder(4))
         	If DAI->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
         
         		DAK->(DBSetOrder(1))
         		If DAK->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_COD))
         		
         			_cresposta := SubStr(AllTrim(_cresposta),1,Len(AllTrim(_cresposta))-1) + " VIAGEM: "+ AllTrim(DAK->DAK_I_CARG) + " )"
         			
         		EndIf
         	EndIf
         
         EndIf

         If ("IMPORTADO COM SUCESSO" $ _cResposta) .Or. ("PEDIDO NAO ENCONTRADO" $ _cResposta) .Or. ("VINCULADO NA CARGA" $ _cResposta)
            Exit
         EndIf
         
      Next       		    
      //================================================================================
      // Grava na tabela de muro um log da integração.
      //================================================================================                       
      ZFL->(RecLock("ZFL",.T.))
      ZFL->ZFL_FILIAL  := SC5->C5_FILIAL
      ZFL->ZFL_HORA    := Time() // Grava a hora de inclusão do registro na tabela de muro.
      ZFL->ZFL_DATA    := Date()
      ZFL->ZFL_CGC     := ZZM->ZZM_CGC
      ZFL->ZFL_NUM     := SC5->C5_NUM
      ZFL->ZFL_COD     := SA2->A2_COD
      ZFL->ZFL_LOJA    := SA2->A2_LOJA
      ZFL->ZFL_NOME     := SA2->A2_NOME
      ZFL->ZFL_EMISSA  := Date()
      ZFL->ZFL_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
      ZFL->ZFL_USUARI  := __cUserId
      ZFL->ZFL_DATAAL  := Date()
      ZFL->ZFL_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFL,dizendo que deu certo ou não.
      ZFL->ZFL_XML     := _cXML
      ZFL->(MSUnLock()) 
                               
      //================================================================================
      // Integração de cancelamento de pedido realizado com sucesso. Disponibiliza
      // pedido para alteração e aprovação.
      //================================================================================                       
 
       If _cSituacao == "P"  
         SC5->(RecLock("SC5",.F.))
         SC5->C5_I_ENVRD := "R"  // Situação R = Integração de Pedido de Vendas Retornado para o Protheus, ou seja, cancelado no sistema RDC.    
         SC5->C5_I_DTRET := Date() // Data de retorno do pedido de vendas do RDC para o Protheus
         SC5->C5_I_HRRET := Time() // Hora de retorno do pedidod e vendas do RDC para o Protheus
         SC5->(MSUnLock())
      EndIf
        
      aAdd(_aresult,{SC5->C5_NUM,ZZM->ZZM_CGC,_cResposta }) // adicona em um array para fazer um item list, exibir os resultados.
      
      Sleep(100) //Espera para não travar a comunicação com o webservice da RDC
      
      If ValType(oproc) = "O"

         oProc:cCaption := (SC5->C5_NUM+" - "+ ZFQ->ZFQ_CNPJEM + " - "  + _cResposta)
         ProcessMessages()

      EndIf
       
   End Transaction
   
   _aCabecalho := {}
   aAdd(_aCabecalho,"PEDIDO" ) 
   aAdd(_aCabecalho,"CNPJ") 
   aAdd(_aCabecalho,"RETORNO") 
             
   _cTitulo := "Resultados da Integração"
 
   If !(FWIsInCallStack("U_AOMS108"))  .And. !(FWIsInCallStack("U_AOMS109"))   .And. !(FWIsInCallStack("U_MOMS066"))  //Não mostra mensagem se veio da exclusão multipla de PV ou central de logistica 
    
     If _cSituacao <> "P" 
        If _lExibeTela 
      	   U_ITMsg("Não foi possível realizar o cancelamento de Pedidos de Vendas no Sistema RDC.","Atenção",,1)
      	EndIf
      
      	If Len(_aResult) > 0 .And. _lExibeTela
      		U_ITListBox( _cTitulo , _aCabecalho , _aResult  ) // Exibe uma tela de resultado.
      	EndIf                 
      Else
         If _lExibeTela
      	    U_ITMsg("Cancelamento do pedido de vendas no sistema RDC realizado com sucesso.","Atenção",,2)
      	 EndIf
      EndIf
    
   EndIf
    
End Sequence

RestOrd(_aOrd)

Return _lRet   
