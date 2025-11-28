/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "APWEBSRV.CH"
#Include "TOTVS.ch"  
#Include "TBICONN.CH"  

/*
===============================================================================================================================
Programa----------: AOMS092
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/02/2017
Descrição---------: Rotina de consulta da integração de Carga, para as cargas incluídas manualmente pelo usuário.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS092()

Local _aCores := {}
Private aRotina := {}
Private cCadastro 

//Grava Log de execução da rotina
U_ITLOGACS()

Begin Sequence
   cCadastro := "Integração de Carga de Pedidos(Incluidas Manualmente no Protheus) Via Webservice: Italac <---> RDC"
   aAdd(aRotina,{"Pesquisar"            ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"           ,"AxVisual"   ,0,2})
   aAdd(aRotina,{"Integracao Webservice","U_AOMS092I" ,0,4})   
   aAdd(aRotina,{"Reenviar Carga"       ,"U_AOMS092N" ,0,4})   
   aAdd(aRotina,{"Legenda"              ,"U_AOMS092L" ,0,6})
   
   aAdd(_aCores,{"ZG4_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZG4_SITUAC == 'P'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZG4_SITUAC == 'R'" ,"BR_AMARELO" })
   aAdd(_aCores,{"ZFQ_SITUAC == 'O'" ,"BR_CANCEL" })
   aAdd(_aCores,{"ZFQ_SITUAC == 'P'" ,"BR_LARANJA" })

   DBSelectArea("ZG4")
   ZG4->(DBSetOrder(1)) 
   ZG4->(DBGoTop())
   MBrowse(6,1,22,75,"ZG4", , , , , , _aCores)
   
End Sequence

Return    

/*
===============================================================================================================================
Programa----------: AOMS092L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/02/2017
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS092L       

Local _aLegenda := {}

   aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
   aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })
   aAdd(_aLegenda,{"BR_CANCEL"   ,"Obsoleto" })   
   aAdd(_aLegenda,{"BR_LARANJA"  ,"Validado Pelo Fiscal RDC" })   
   
   BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return   

/*
===============================================================================================================================
Função------------: AOMS092I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/02/2017
Descrição---------: Rotina de integração e envio de dados das Cargas de Pedidos(Incluidas Manualmente no Protheus) 
                    via webservice, para o sistema RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS092I()

Local _lRet := .F.
Local _aStrucZG4
Local _aOrd := SaveOrd({"SX3","ZG4"})
Local _aCmpZG4 := {}
Local _aButtons := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgInt, _nI
Local _otemp

Private _oMarkZG4, _cMarcaZG4 := GetMark() 
Private _cArqZG4
Private aHeader := {} , aCols := {}

Begin Sequence
   // Cria as estruturas das tabelas temporárias
   _aStrucZG4 := ZG4->(DbStruct())
   aAdd(_aStrucZG4,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZG4,{"WKRECNO", "N", 10,0})
   
   // Abre o arquivo TRBZFQ criado dentro do protheus.
   _otemp := FWTemporaryTable():New( "TRBZG4",  _aStrucZG4)
   
   // Cria os indices para o arquivo.
   _otemp:AddIndex( "01", {"ZG4_DATA"} )
   _otemp:Create()   
   
   DBSelectArea("TRBZG4")
  
   // Montagem do aheader                                                        
   FillGetDados(1,"ZG4",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
   
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFQ 
   aAdd( _aCmpZG4 , { "WK_OK"		,    , "Marca"                                          ,"@!"})
   
   For _nI := 1 To Len(aHeader)
       If !X3USO( aHeader[_nI,7] ) .Or. aHeader[_nI,10] == 'V' .Or. (AllTrim(aHeader[_nI,2]) $ "ZG4_ALI_WT/ZG4_REC_WT")
          Loop
       EndIf
       
       aAdd( _aCmpZG4 , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
   Next 
                                                                                
   // Carrega os dados da tabela ZG4
   Processa( {|| U_AOMS092D()(  ) } , 'Aguarde!' , 'Lendo dados a serem integrados...' )

   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}
   aAdd(_aButtons,{"",{|| U_AOMS092M("T") },"Marc/Des" ,"Marca/Desmarca Todos"})
                                          
  _cTitulo := "Integração de Carga de Pedidos(Manual) Via WebService"
   // Monta a tela de dados com MSSELECT.
   Define MsDialog _oDlgInt Title _cTitulo From 9,0 To 200,80 Of oMainWnd 
             
      _oMarkZG4 := MsSelect():New("TRBZG4","WK_OK","",_aCmpZG4,@_lInverte, @_cMarcaZG4,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
      _oMarkZG4:bAval := {|| U_AOMS092M("P")}
      _oDlgInt:lMaximized:=.T.
      
   Activate MsDialog _oDlgInt On Init (EnchoiceBar(_oDlgInt,_bOk,_bCancel,,_aButtons), _oMarkZG4:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkZG4:oBrowse:Refresh() )
   
   If _lRet
      Processa( {|| U_AOMS092W(  ) } , 'Aguarde!' , 'Integrando Dados das Cargas...' )
   EndIf

End Sequence

// Fecha e exclui as tabelas temporárias
If Select("TRBZG4") > 0
   TRBZG4->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Função----------: AOMS092M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/02/2017
Descrição-------: Função para marcar e desmarcar todas as Carga de (Pedidos) que serão integrados via Webservice.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.                                           
Retorno---------: Nenhum                  
===============================================================================================================================
*/
User Function AOMS092M(_cTipoMarca)

Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZG4->(Recno()) 

Begin Sequence          
   If Empty(TRBZG4->WK_OK )
      _cSimboloMarca := _cMarcaZG4
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZG4->(RecLock("TRBZG4",.F.))
      TRBZG4->WK_OK := _cSimboloMarca 
      TRBZG4->(MSUnLock())
   Else
      TRBZG4->(DBGoTop())
      While ! TRBZG4->(Eof())
         TRBZG4->(RecLock("TRBZG4",.F.))
         TRBZG4->WK_OK := _cSimboloMarca 
         TRBZG4->(MSUnLock()) 
         
         TRBZG4->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZG4->(DBGoTo(_nRegAtu)) 
_oMarkZG4:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Função------------: AOMS092W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/02/2017
Descrição---------: Gera os dados XML com base nas Cargas de Pedidos selecionadas e integra via webservice.
Parametros--------: _lScheduler = .T. indica rotina em Scheduler; .F. indica rotina manual
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS092W(_lScheduler)             

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cDetXML := ""
Local _cRodXML := "" 
Local _lItemSelect := .F.
Local _aOrd := SaveOrd({"ZG4"})
Local _cXML 
Local _cResult := ""
Local _cResposta, _cSituacao
Local _cEmpWebService := SuperGetMV('IT_EMPWEBSE',.T.,'000001')

Default _lScheduler := .F.

Begin Sequence
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   If ! _lScheduler
      ProcRegua(8)
      IncProc("Verificando itens selecionados...")
   Else
      u_itconout("Verificando itens selecionados para integração de Cargas de Pedidos.")
   EndIf                    
   
   TRBZG4->(DBGoTop())                                                                   
   While ! TRBZG4->(Eof())
      If ! Empty(TRBZG4->WK_OK)   
         _cEmpWebService := TRBZG4->ZG4_CODEMP                         
         _lItemSelect := .T. 
         Exit
      EndIf                 
      
      TRBZG4->(DBSkip())
   EndDo 
     
   If ! _lItemSelect 
      If ! _lScheduler
         MsgInfo("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.","Atenção")
      Else
         u_itconout("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.")
      EndIf                                                                                                                         
      
      Break   
   EndIf              
   
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   If ! _lScheduler
      IncProc("Identificando diretório dos XML...")                    
   Else
      u_itconout("Identificando diretório dos XML...") 
   EndIf                                           
   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else            
      If ! _lScheduler
         MsgInfo("Empresa WebService para envio dos dados não localizada.","Atenção")
      Else
         u_itconout("Empresa WebService para envio dos dados não localizada.")
      EndIf
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If ! _lScheduler
         MsgInfo("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção")
      Else
         u_itconout("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
      EndIf
      
      Break                                     
   EndIf
      
   _cDirXML := AllTrim(_cDirXML)
   If Right(_cDirXML,1) <> "\"
      _cDirXML := _cDirXML + "\"
   EndIf

   // Lê os arquivos modelo XML e os transforma em String.
   If ! _lScheduler
      IncProc("Lendo arquivo XML Modelo de Cabeçalho...")                      
   Else
      u_itconout("Lendo arquivo XML Modelo de Cabeçalho...")
   EndIf                                                
   
   _cCabXML := U_AOMS092X(_cDirXML+"Cab_OrdemTransporte.txt") 
   If Empty(_cCabXML)
      If ! _lScheduler
         MsgInfo("Erro na leitura do arquivo XML modelo do cabeçalho de envio de Ordem de Transporte(Carga). ","Atenção")
      Else
         u_itconout("Erro na leitura do arquivo XML modelo do cabeçalho de envio de Ordem de Transporte(Carga). ")
      EndIf
      
      Break
   EndIf
   
   If ! _lScheduler
      IncProc("Lendo arquivo XML Modelo de Detalhe ...")
   Else
      u_itconout("Lendo arquivo XML Modelo de Detalhe ...")
   EndIf                                               
   
   _cDetXML := U_AOMS092X(_cDirXML+"Det_OrdemTransporte.txt")
   If Empty(_cDetXML)
      If ! _lScheduler
         MsgInfo("Erro na leitura do arquivo XML modelo do detalhe de envio de Ordem de Transporte(Carga).","Atenção")
      Else
         u_itconout("Erro na leitura do arquivo XML modelo do detalhe de envio de Ordem de Transporte(Carga).")
      EndIf
      
      Break
   EndIf            
   
   If ! _lScheduler  
      IncProc("Lendo arquivo XML Modelo de Rodapé...")
   Else
      u_itconout("Lendo arquivo XML Modelo de Rodapé...")
   EndIf                                             
   
   _cRodXML := U_AOMS092X(_cDirXML+"Rodape_OrdemTransporte.txt")
   If Empty(_cRodXML)
      If ! _lScheduler
         MsgInfo("Erro na leitura do arquivo XML modelo do rodapé de envio de Ordem de Transporte(Carga).","Atenção")
      Else
         u_itconout("Erro na leitura do arquivo XML modelo do rodapé de envio de Ordem de Transporte(Carga).")
      EndIf    
      
      Break
   EndIf
   
   // Ativa a classe de envio de dados.
   If ! _lScheduler                  
      IncProc("Montando dados de envio...")
   Else
      u_itconout("Montando dados de envio...")
   EndIf

   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.  
   oWsdl:nTimeout := 10          // Timeout de 10 segundos   
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                                                                           
   
   //oWsdl:ParseURL( "http://10.3.0.201/wsitf18/Service.svc?wsdl") // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.   
   oWsdl:SetOperation("OrdemTransporte") // Define qual operação será realizada.   
   
   _aresult := {}
   
   TRBZG4->(DBGoTop())                                                                   
   While ! TRBZG4->(Eof())
          
      If ! Empty(TRBZG4->WK_OK)   
         ZG4->(DBGoTo(TRBZG4->WKRECNO))
                     
         Begin Transaction     
            // Realiza a integração dos pedidos de vendas (Envio de XML) via WebService.
                     
 		    //Monta XML
 		    _cXML := _cCabXML + &(_cDetXML) + _cRodXML  // Monta o XML de envio.
 		    
 		    //Limpa & da string
 		    _cXML := StrTran(_cXML,"&"," ")

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
               _cSituacao := "R" 
            ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta)       	
 		       _cSituacao := "R"
 		    EndIf

 		    //grava resultado 
            ZG4->(RecLock("ZG4",.F.))
            ZG4->ZG4_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
            ZG4->ZG4_USUARI  := __cUserId
            ZG4->ZG4_DATAAL  := Date()
            ZG4->ZG4_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZG4,dizendo que deu certo ou não.
            ZG4->ZG4_XML     := _cXML 
            ZG4->(MSUnLock()) 
                    
            aAdd(_aresult,{ZG4->ZG4_NRORDE,ZG4->ZG4_CNPJFA,ZG4->ZG4_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
            Sleep(100) //Espera para não travar a comunicação com o webservice da RDC
            
            If ! _lScheduler  
               IncProc(ZG4->ZG4_NRORDE+ " - "  + ZG4->ZG4_RETORN)
            Else
               u_itconout(ZG4->ZG4_NRORDE+ " - "  + ZG4->ZG4_RETORN)
            EndIf
            
            // Em caso de rejeição, envia e-mail avisando a rejeição.
            If _cSituacao == "R" 
               _cAssunto := ZG4->ZG4_FILIAL + "-" + AllTrim( Posicione('SM0',1,cEmpAnt+ZG4->ZG4_FILIAL,'M0_FILIAL') ) + " Carga Incluída Manualmente de Numero: "+ZG4->ZG4_NRORDE + " - REJEITADA PELO RDC "
            
               _cNomeFilial := ZG4->ZG4_FILIAL + "-" + AllTrim( Posicione('SM0',1,cEmpAnt+ZG4->ZG4_FILIAL,'M0_FILIAL') )
                                                                 
               _aDadosCarga := {}
			   aAdd(_aDadosCarga,Transform(ZG4->ZG4_CNPJFA,"@R! NN.NNN.NNN/NNNN-99")) // CNPJ Fornecedor/Fabricante
			   aAdd(_aDadosCarga,ZG4->ZG4_NRORDE) // Numero da Carga
               aAdd(_aDadosCarga,ZG4->ZG4_CODCAV) // Placa do Veiculo
               aAdd(_aDadosCarga,ZG4->ZG4_CODCAR) // Placa do Semi-reboque 
               aAdd(_aDadosCarga,ZG4->ZG4_CODMOT) // CPF do Motorista
               aAdd(_aDadosCarga,Transform(ZG4->ZG4_CODFRT,"@R! NN.NNN.NNN/NNNN-99"))  // CNPJ da Transportadora
               aAdd(_aDadosCarga,_cNomeFilial)     // Cod.Filial - Nome Filial
             
               U_AOMS092E(ZG4->ZG4_FILIAL,ZG4->ZG4_NRORDE ,_aDadosCarga,_cAssunto,_cResposta,.T.)
            EndIf
            
            
         End Transaction
      EndIf       
                
      TRBZG4->(DBSkip())
         
   EndDo 
   
   If ! _lScheduler  
      _aCabecalho := {}
      aAdd(_aCabecalho,"CARGA") 
      aAdd(_aCabecalho,"CNPJ") 
      aAdd(_aCabecalho,"RETORNO") 
             
      _cTitulo := "Resultados da integração"
      
      If Len(_aresult) > 0
      
  	     u_ITListBox( _cTitulo , _aCabecalho , _aresult  ) // Exibe uma tela de resultado.
  	  
  	  EndIf
   Else
      u_itconout(_cResult)
   EndIf   
    
End Sequence

RestOrd(_aOrd)

Return   

/*
===============================================================================================================================
Função-------------: AOMS092X
Aut2or-------------: Julio de Paula Paz
Data da Criacao---: 13/02/2017
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS092X(_cArq)

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
=================================================================================================================================
Programa--------: AOMS092R(_lScheduler,_cChamada)
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/02/2017
Descrição-------: Grava os dados das cargas(Tabela DAK) na Tabela de muro ZG4, para serem integrados via webservice, para o 
                  sistema RDC.
Parametros------: _cChamada = ponto de chamada da rotina, podendo ser: "I" = Ponto de entrada de Inclusão da carga.
                                                                       "E" = Ponto de entrada do estorno da carga.
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS092R(_cChamada)

Local _aOrd := SaveOrd({"DAK","DAI","ZG4","DA3","SA1","SA2","SC5"})
Local _cCodEmpWS := SuperGetMV('IT_EMPWEBSE',.T.,'000001')
Local _cPlaca,_cPlacaVagao, _cCpfMotorista
Local _aUF, _cCodMunOri, _cCodMunDes, _cCnpjTransp
Local _cCodOrdem, _nTamNRORDE

Begin Sequence 
   u_itconout("Gravando dados das cargas (Tabela DAk) nas Tabelas de Muro ZG4 para integração RDC.")
   
   // Posiciona no registro do cadastro de fornecedores e clientes para a leitura
   // do código do municipio.
   SA2->(DBSetOrder(3)) 
   DAI->(DBSetOrder(1))
   SC5->(DBSetOrder(1))
   ZG4->(DBSetOrder(3)) // ZG4_FILIAL+ZG4_NRORDE+ZG4_SITUAC
   // Monta array dos estados

   _aUF := {}
   aAdd(_aUF,{"RO","11"})
   aAdd(_aUF,{"AC","12"})
   aAdd(_aUF,{"AM","13"})
   aAdd(_aUF,{"RR","14"})
   aAdd(_aUF,{"PA","15"})
   aAdd(_aUF,{"AP","16"})
   aAdd(_aUF,{"TO","17"})
   aAdd(_aUF,{"MA","21"})
   aAdd(_aUF,{"PI","22"})
   aAdd(_aUF,{"CE","23"})
   aAdd(_aUF,{"RN","24"})
   aAdd(_aUF,{"PB","25"})
   aAdd(_aUF,{"PE","26"})
   aAdd(_aUF,{"AL","27"})	
   aAdd(_aUF,{"MG","31"})
   aAdd(_aUF,{"ES","32"})
   aAdd(_aUF,{"RJ","33"})
   aAdd(_aUF,{"SP","35"})
   aAdd(_aUF,{"PR","41"})
   aAdd(_aUF,{"SC","42"})
   aAdd(_aUF,{"RS","43"})
   aAdd(_aUF,{"MS","50"})
   aAdd(_aUF,{"MT","51"})
   aAdd(_aUF,{"GO","52"})
   aAdd(_aUF,{"DF","53"})
   aAdd(_aUF,{"SE","28"})
   aAdd(_aUF,{"BA","29"})
   aAdd(_aUF,{"EX","99"})

   SA2->(DBSeek(xFilial("SA2")+SM0->M0_CGC))
   _cCodMunOri := _aUF[aScan(_aUF,{|x| x[1] == SA2->A2_EST})][02] + SA2->A2_COD_MUN
   
   _cCodMunDes := ""
   If DAI->(DBSeek(xFilial("DAI")+DAK->DAK_COD+DAK->DAK_SEQCAR))
      If SC5->(DBSeek(xFilial("DAI")+DAI->DAI_PEDIDO))
         _cCodMunDes := _aUF[aScan(_aUF,{|x| x[1] == SC5->C5_I_EST})][02] + SC5->C5_I_CMUN
      EndIf
   EndIf     
   _cPlaca := "" 
   _cPlacaVagao := "9999999"
   DA3->(DBSetOrder(1)) // DA3_FILIAL+DA3_COD      
   If DA3->(DBSeek(xFilial("DA3")+DAK->DAK_CAMINH))                                                                                                                                        
      If DA3->DA3_I_TPVC == "2" .Or. DA3->DA3_I_TPVC == "4"  // 1=CARRETA;2=CAMINHAO;3=BI-TREM;4=UTILITARIO;5=RODO-TREM    
         _cPlaca := DA3->DA3_PLACA
         _cPlacaVagao := "9999999" //DA3->DA3_I_PLCV
      Else
         _cPlaca := DA3->DA3_I_PLCV
         _cPlacaVagao := DA3->DA3_PLACA
      EndIf 
   EndIf

   _cCnpjTransp   := ""
   _cCpfMotorista := ""
      
   DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD
   If DA4->(DBSeek(xFilial("DA4")+DAK->DAK_MOTORI))
      _cCpfMotorista := DA4->DA4_CGC     
      SA2->(DBSeek(xFilial("SA2")+DA4->DA4_FORNEC+DA4->DA4_LOJA))
      _cCnpjTransp := Posicione("SA2",1,xFilial("SA2")+DA4->DA4_FORNEC+DA4->DA4_LOJA,"A2_CGC")
   EndIf              
   
   _nTamNRORDE := TamSX3("ZG4_NRORDE")[1]
   _cCodOrdem  := PadR(DAK->DAK_COD,_nTamNRORDE," ")
   
   If _cChamada == "I"
      If ZG4->(DBSeek(xFilial("ZG4")+_cCodOrdem+"P")) 
         ZG4->(RecLock("ZG4",.F.))
         ZG4->ZG4_SITUAC	:= "O"
         ZG4->(MSUnLock())
      EndIf
   Else
      If ZG4->(DBSeek(xFilial("ZG4")+_cCodOrdem+"N")) 
         _cCodMunDes := ZG4->ZG4_CDMUDE  // Codigo IBGE Municipio de Destino  
      ElseIf ZG4->(DBSeek(xFilial("ZG4")+_cCodOrdem+"R")) 
         _cCodMunDes := ZG4->ZG4_CDMUDE  // Codigo IBGE Municipio de Destino        
      EndIf
   EndIf
   
   ZG4->(RecLock("ZG4",.T.))
   ZG4->ZG4_FILIAL	:= xFilial("ZG4") 
   ZG4->ZG4_DATA    := Date() 
   ZG4->ZG4_HORA    := Time()
   ZG4->ZG4_CNPJFA	:= SM0->M0_CGC     // C	14	Fabrica		
   ZG4->ZG4_NRORDE	:= DAK->DAK_COD	   // C	12	Ordem de Carregamento		
   ZG4->ZG4_CODCAV	:= _cPlaca 	       // DAK_CAMINH // C	7	Placa		
   ZG4->ZG4_CODCAR	:= _cPlacaVagao    // DAK_CAMINH // C	7	Semi-Reboque	"9999999"	
   ZG4->ZG4_CODMOT	:= _cCpfMotorista  // DAK_MOTORI // C	6	Motorista		
   ZG4->ZG4_CODFRT	:= _cCnpjTransp    // C	14	Transportadora		// DAK->DAK_TRANSP este é um campo padrão não utilizado na Italac, Pegar transportadora no cadastro de motorista.
   ZG4->ZG4_CDMUOR  := _cCodMunOri     // Codigo IBGE Municipio de Origem
   ZG4->ZG4_CDMUDE  := _cCodMunDes     // Codigo IBGE Municipio de Destino
   ZG4->ZG4_TPOPER	:= "10"            // C	4	Tipo de Operação		10=Operacao de Carregamento;11=Operacao de Descarregamento
   ZG4->ZG4_SITOPE	:= If(_cChamada=="I","2","5")	// C	1	Situação da Operação	2=Inclusao;5=Exclusao
   ZG4->ZG4_USUARI	:= __cUserId       // C	6	Codigo do Usuário	
   ZG4->ZG4_DATAAL	:= Date() 	       // D	8	Data de Alteração	
   ZG4->ZG4_HORAAL  := Time()          // C 8   Hora da Alteração
   ZG4->ZG4_SITUAC	:= "N" 	           // C	1	Situação do Registro	“N”
   ZG4->ZG4_CODEMP	:= _cCodEmpWS      // C	6	Codigo Empresa WebServer	
   ZG4->(MSUnLock())
   
End Sequence

RestOrd(_aOrd,.T.) // Volta a ordem os indices das tabelas para ordem anterior e volta os ponteiros de registros das tabelas

Return           

/*
===============================================================================================================================
Função------------: AOMS084D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/02/2017
Descrição---------: Grava em tabela temporária os dados a serem integrados via webservice.
Parametros--------: _lScheduler = .T. rotina em scheduler; .F. rotina manual.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS092D(_lScheduler)

Local _lRet := .F.,_nI

Default _lScheduler := .F.

Begin Sequence
   ProcRegua(0)
   ZG4->(DBSetOrder(2)) 
   ZG4->(DBSeek(xFilial("ZG4")+"N"))
   While ! ZG4->(Eof()) .And. ZG4->(ZG4_FILIAL+ZG4_SITUAC) == xFilial("ZG4")+"N"
      If ! _lScheduler
         IncProc("Lendo registros...")
      EndIf
      
      TRBZG4->(RecLock("TRBZG4",.T.))
      For _nI := 1 To TRBZG4->(FCount())                  
          If ! AllTrim(TRBZG4->(FieldName(_nI))) $ "WK_OK/WKRECNO/ZG4_XML"
             &("TRBZG4->"+TRBZG4->(FieldName(_nI))) :=  &("ZG4->"+ZG4->(FieldName(_nI)))
          EndIf
      Next            
      If _lScheduler                
         TRBZG4->WK_OK := _cMarcaZG4
      EndIf
      TRBZG4->WKRECNO := ZG4->(Recno())
      TRBZG4->(MSUnLock())
      
      _lRet := .T.
      
      ZG4->(DBSkip())
       
   EndDo
   TRBZG4->(DBGoTop())

End Sequence

Return _lRet

/*
===============================================================================================================================
Função----------: AOMS092A
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/02/2017
Descrição-------: Função para rodar a rotina de integração Envio de carga manual para o RDC de forma agendada (Scheduller).
Parametros------: Nenhum
Retorno---------: Nenhum                  
===============================================================================================================================
*/
User Function AOMS092A()             

Local _aOrd 
Local _otemp

Private _cArqZG4
Private _cMarcaZG4
Private aHeader := {} , aCols := {}

Begin Sequence
   // Limpa o ambiente, liberando a licença e fechando as conexões
   RpcClearEnv() 
   RpcSetType(2)

   // Prepara ambiente abrindo tabelas e incializando variaveis.
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","ZG4","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})

   cFilAnt := "01"

   _aOrd := SaveOrd({"ZG4"})
   _cMarcaZG4 := GetMark()
   
   // Cria as estruturas das tabelas temporárias
   _aStrucZG4 := ZG4->(DbStruct())
   aAdd(_aStrucZG4,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZG4,{"WKRECNO", "N", 10,0})
   
   // Abre o arquivo TRBZFQ criado dentro do protheus.
   _otemp := FWTemporaryTable():New( "TRBZG4",  _aStrucZG4)
   
   // Cria os indices para o arquivo.
   _otemp:AddIndex( "01", {"ZG4_DATA"} )
   _otemp:Create()   
   
   DBSelectArea("TRBZG4")
   
   // Grava os dados das tabelas de muro em tabela temporária para serem processados
   // via scheduller.
   U_AOMS092D(.T.)

   // Gera os dados dos XML e integra via webservices.
   U_AOMS092W(.T.)             

End Sequence

// Fecha e exclui as tabelas temporárias
If Select("TRBZG4") > 0
   TRBZG4->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Função------------: AOMS092E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/02/2017
Descrição---------: Função de Envio de Email da rejeição da integração de carga.
Parametros--------: _cFilial     = Filial de envio.
                    _cNrCarga    = Numero da Carga
                    _aDadosCarga = Array com alguns dados da Carga: _aDadosCarga[1] // CNPJ Fornecedor/Fabricante
			                                                        _aDadosCarga[2] // Numero da Carga
                                                                    _aDadosCarga[3] // Placa do Veiculo
                                                                    _aDadosCarga[4] // Placa do Semi-reboque 
                                                                    _aDadosCarga[5] // CPF do Motorista
                                                                    _aDadosCarga[6] // CNPJ da Transportadora
                                                                    _aDadosCarga[7] // Nome da Filial                    
                    _cAssunto    = Assunto do E-mail.
                    _cObsEmail   = Mensagem enviada no e-mail.
                    _lAutomatico = .T. Rotina enviada de forma agendada / .F. Rotina chamada manualmente.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS092E(_cFilial,_cNrCarga,_aDadosCarga,_cAssunto,_cObsEmail,_lAutomatico)

Local _cEmail	   := AllTrim(SuperGetMV("IT_EMAILCT",.T.,""))
Local _cEmailCC    := AllTrim(SuperGetMV("IT_MAILCCT",.T.,"")) 
Local _aConfig	   := U_ITCFGEML('')
Local _cMsgEml	   := ''
Local _cNomeFilial := ""
Local _cMailUser   := ""  
Local _cCnpjForFabric, _cPlacaVeic, _cPlacaReboque, _cCpfMotorista
                    
Default _lAutomatico := .T.

Begin Sequence
   If Empty( _cEmail )
      If ! _lAutomatico
         MsgInfo("Nenhum e-mail de envio foi informado.","Atenção")
      Else
         u_itconout("Nenhum e-mail de envio foi informado.")
      EndIf	
      Break
   Else
      _cCnpjForFabric  := _aDadosCarga[1] // CNPJ Fornecedor/Fabricante
      _cPlacaVeic      := _aDadosCarga[3] // Placa do Veiculo
      _cPlacaReboque   := _aDadosCarga[4] // Placa do Semi-reboque 
      _cCpfMotorista   := _aDadosCarga[5] // CPF do Motorista
      _cCNPJ_Transport := _aDadosCarga[6] // CNPJ da Transportadora
      _cNomeFilial     := _aDadosCarga[7] // Cod.Filial + Nome Filial
      
      _cMsgEml := '<html>'
      _cMsgEml += '<head><title>Integração de Envio de XML Ordem de Carregamento(Manual) da Italac para RDC</title></head>'
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
      _cMsgEml += '	     <td class="titulos"><center>'+"XML DA CARGA(Manual) - REJEITADO PELO SISTEMA RDC"+'</center></td>'
      _cMsgEml += '	 </tr>'
      _cMsgEml += '</table>'
      _cMsgEml += '<br>'
      _cMsgEml += '<table class="bordasimples" width="600">'
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td align="center" colspan="2" class="grupos">Numero da Carga <b>'+ _cNrCarga +'</b></td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Enviado por </b></td>'
      _cMsgEml += '      <td class="itens" >'+"Rotina de Integração Carga(Manual)"+'</td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cNomeFilial +'</td>'
      _cMsgEml += '    </tr>'                                          
      
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>CNPJ Fabricante</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cCnpjForFabric +'</td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Transportador</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cCNPJ_Transport +'</td>'
      _cMsgEml += '    </tr>'
                          
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Placa Veiculo </b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cPlacaVeic +'</td>'
      _cMsgEml += '    </tr>'
   
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Placa Semi-Reboque</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cPlacaReboque +'</td>'
      _cMsgEml += '    </tr>'

      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="30%"><b>CPF Motorista</b></td>'
      _cMsgEml += '      <td class="itens" >'+ _cCpfMotorista +'</td>'
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
            MsgInfo("Falha no envio de e-mail na integração Webservice Italac x RDC: " + _cEmlLog + ". E-mail para: "+_cEmail +". Com Copia: "+_cEmailCC)	
         EndIf
      EndIf
   EndIf

End Sequence

Return .T.

/*
===============================================================================================================================
Função----------: AOMS092N
Autor-----------: Julio de Paula Paz
Data da Criacao-: 17/02/2017
Descrição-------: Altera o campo Situação do registro de integração de carga posicionado, para permitir que a carga posicionada
                  seja novamente integrada para o sistema RDC.
Parametros------: Nenhum
Retorno---------: Nenhum                  
===============================================================================================================================
*/
User Function AOMS092N()

Begin Sequence           
   If !MsgYesNo("Confirma a alteração da situação desta carga para 'Não Processado', diponibilizando-a para ser novamente integrada Via WebSercice?","Atenção")
      Break
   EndIf

   If ZG4->ZG4_SITUAC == "N"
      MsgInfo("A carga: '"+ZG4->ZG4_NRORDE+"' já se encontra disponível para integração WebService. Não há necessidade de alterar sua situação de integração.","Atenção")
      Break
   EndIf           
            
   ZG4->(RecLock("ZG4",.F.))
   ZG4->ZG4_SITUAC := "N"     
   ZG4->ZG4_USUARI := __cUserId  // Codigo do Usuário	
   ZG4->ZG4_DATAAL := Date()	 // Data de Alteração
   ZG4->ZG4_HORAAL := Time()     // Hora da Alteração
   ZG4->(MSUnLock())             
   
End Sequence

Return
