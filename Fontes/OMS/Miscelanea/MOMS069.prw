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

#Include "TOTVS.ch" 
#Include "TBICONN.CH"
 
/*
===============================================================================================================================
Função-------------: MOMS069
Autor--------------: Julio de Paula Paz
Data da Criacao----: 27/03/2023
Descrição----------: Rotina de integração WebService Italac x Broker (Target Sistemas). Chamado 43431.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS069(_lScheduller)

Local _lRecebCli  := .T.
Local _lRecebPv   := .T.
Local _lEnviaPv   := .T.
Local _lVisPvApr  := .T.
Local _lVisPvRej  := .T.
Local _lVisualRej := .T.
Local _lVisualApr := .T.

Default _lScheduller := .F.

Begin Sequence 

   // Recebe os dados dos clientes e grava no cadastro de Prospect.
   If ! _lScheduller
      If ! U_ITMsg("Confirma o recebimento dos dados dos Clientes e grava no cadastro de Prospect?","Atenção" , , ,2, 2)
         _lRecebCli := .F.
      EndIf 
   Else  
      U_ItConOut("[MOMS069] Recebendo dados dos Clientes e gravando no cadastro de Prospect.")
   EndIf 

   If ! _lScheduller
      If _lRecebCli
         ProcRegua(0)
         
         Processa( {|| U_MOMS069C(_lScheduller,"P") } , 'Aguarde!' , 'Recebendo dados dos Clientes...' )

         U_ITMsg("Recebimento dos dados dos clientes do Broker concluido.","Atenção",,2)
      EndIf 
   Else  
      U_MOMS069C(_lScheduller,"P")

      U_ItConOut("[MOMS069] - Recebimento dos dados dos clientes do Broker concluído.")
   EndIf 

   // Recebe os dados dos pedidos de vendas e grava no portal.
   If ! _lScheduller
      If ! U_ITMsg("Confirma o recebimento dos dados dos Pedidos de Vendas e grava no cadastro de Portal do Representante?","Atenção" , , ,2, 2)
         _lRecebPv := .F.
      EndIf 
   Else  
      U_ItConOut("[MOMS069] - Recebendo dados dos Pedidos de Vendas e gravando no Portal do Representante.")
   EndIf 

   If ! _lScheduller
      If _lRecebPv
         ProcRegua(0)
         
         Processa( {|| U_MOMS069R(_lScheduller) } , 'Aguarde!' , 'Recebendo dados dos Pedidos de Vendas e Gravando no Portal de Representantes...' )

         U_ITMsg("Recebimento dos dados dos Pedidos de Vendas do Broker e gravando no portal de representantes.","Atenção",,2)
      EndIf 
   Else  
      U_MOMS069R(_lScheduller)

      U_ItConOut("[MOMS069] - Recebimento dos dados dos pedidos de vendas e gravando portal de representantes.")
   EndIf 

   // Envia dados das notas fiscais para o Broker.
   If ! _lScheduller
      If ! U_ITMsg("Confirma o envio dos dados das Notas Fiscais para o Broker?","Atenção" , , ,2, 2)
         _lEnviaPv := .F.
      EndIf 
   Else  
      U_ItConOut("[MOMS069] - Enviando os dados das notas fiscais para o Broker.")
   EndIf 

   If ! _lScheduller
      If _lEnviaPv
         ProcRegua(0)
         
         Processa( {|| U_MOMS069E(_lScheduller) } , 'Aguarde!' , 'Enviando dados das Notas fiscais para o Broker...' )

         U_ITMsg("Envio dos dados das Notas Fiscais para o Broker concluido.","Atenção",,2)
      EndIf 
   Else  
      U_MOMS069E(_lScheduller)

      U_ItConOut("[MOMS069] - Envio dos dados das Notas Fiscais para o Broker concluido.")
   EndIf 

   // Visualizar clientes rejeitados na Integração Broker
   If ! _lScheduller
      If ! U_ITMsg("Confirma a visualização dos Clientes rejeitados na integração com o Broker?","Atenção" , , ,2, 2)
         _lVisualRej := .F.
      EndIf 
   EndIf 

   If ! _lScheduller
      If _lVisualRej
         U_MOMS069F("R")
      EndIf 
   EndIf 

   // Visualizar clientes aceitos na Integração Broker
   If ! _lScheduller
      If ! U_ITMsg("Confirma a visualização dos Clientes aceitos na integração com o Broker?","Atenção" , , ,2, 2)
         _lVisualApr := .F.
      EndIf 
   
      If _lVisualApr
         U_MOMS069F("A")
      EndIf 
   EndIf 

   // Visualizar pedidos de vendas rejeitados na Integração Broker
   If ! _lScheduller
      If ! U_ITMsg("Confirma a visualização dos pedidos de vendas rejeitados na integração com o Broker?","Atenção" , , ,2, 2)
         _lVisPvRej := .F.
      EndIf 

      If _lVisPvRej
         U_MOMS069H("R")
      EndIf 
   EndIf 

   // Visualizar pedidos de vendas aceitos na Integração Broker
   If ! _lScheduller
      If ! U_ITMsg("Confirma a visualização dos pedidos de vendas aceitos na integração com o Broker?","Atenção" , , ,2, 2)
         _lVisPvApr := .F.
      EndIf 

      If _lVisPvApr
         U_MOMS069H("A")
      EndIf 
   EndIf 

End Sequence 

Return 

/*
===============================================================================================================================
Função-------------: MOMS069C
Autor--------------: Julio de Paula Paz
Data da Criacao----: 27/03/2023
Descrição----------: Rotina de Recebimento de dados dos Clientes do Broker via WebService da Target Sistemas.
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
                    _cTipo    = "P" = Página
                    _cCodigo  = "C" = Código Cliente
Retorno------------: _lRet    = .T. = Gravou Prospect.
                              = .F. = Não gravou Prospect.
===============================================================================================================================
*/  
User Function MOMS069C(_cChamada, _cTipo, _cCodigo)

Local _cEmpWebSe := SuperGetMV('IT_CODWSBR',.T.,"000004") 
Local _cDirJSon, _cLinkWS
Local _cKey
Local _cCodVend := ""
Local _cPagina  := ""
Local _cLinkEnv := ""
Local _nI, _nJ  
Local _lPagCompl := .T.
Local _nTotRegs 
Local _lRet := .F.
Local _cJSonRet
Local _oRetCli, _cJSonCli, _cMotivoCli
Local _cVencL, _dVencL
Local _cGrupoVen 

Default _cTipo := "P"

Begin Sequence 

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebSe))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      
      If _cTipo == "C"
         _cLinkWS  := AllTrim(ZFM->ZFM_LINK02) // Link de Leitura dos Dados dos Clientes do Broker.  
      Else 
         _cLinkWS  := AllTrim(ZFM->ZFM_LINK04) // Link de Leitura dos Dados dos Clientes do Broker por página.  
      EndIf 

      _cCodVend := AllTrim(ZFM->ZFM_AUX01)    // Código do Vendedor do Broker.
      _cPagina  := AllTrim(ZFM->ZFM_AUX02)    // Numero da ultima página de cliente lida.
   Else 
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Empresa WebService para envio dos dados não localizada.")
      EndIf 

      Break
   EndIf

   If Empty(_cPagina) .And. _cTipo == "P"
      _cPagina := "1"
   EndIf 
    
   While .T. 
      _cKey := U_MOMS069T(_cChamada, _cEmpWebSe) // Obtem o Token de acesso. 

      If Empty(_cKey)
         If _cChamada == "M" // Chamada via menu.   
            U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Clientes Broker cancelada.","Atenção",,1)
         Else // Chamada via Scheduller
            U_ItConOut("[MOMS069] - Erro ao na obtenção do Token. Rotina de Integração de Clientes Broker cancelada.")
         EndIf

         Break
      EndIf 

      If _cTipo == "P" // Integração de clientes por página.
         _cLinkEnv := _cLinkWS  + "/" + _cPagina 
      Else // Integração de clientes por código.
         _cLinkEnv := _cLinkWS  + "/" + AllTrim(Str(_cCodigo,16)) 
      EndIf 

      _aHeadOut := {}              
   
      aAdd(_aHeadOut,'accept: application/json')
      aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil 
      _nTimOut	 	:= 120
      _cGetParms  := ""   
      _cRetHttp   := ''
      _oJSonRet   := ""
      _oRetJSonC   := ""
     
      _cRetHttp := AllTrim(HttpGet( _cLinkEnv , _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   
      _cRetHttp := U_ITSUBCHR(_cRetHttp,{{"\n", ""}})

      If ! Empty(_cRetHttp)
         varinfo("WebPage-http ret.", _cRetHttp)
      Else
         Break // Não há mais dados de retonro para clientes disponíveis no WebService do Broker.  
      EndIf

      FWJSonDeserialize(_cRetHttp,@_oRetJSonC)  

      If ValType(_oRetJSonC) <> "O" .And. ValType(_oRetJSonC) <> "A"
         Break // Não foi possível obter dados dos clientes para inserção no Prospect.
      EndIf 

      // As novas funções Totvs para arquivos JSon não estão funcionando com os JSons
      // retornados pelo Broker. Devido ao Conteúdo muito grande.
      // Usando como alternativa a função descontinuada da Totvs: FWJSonDeserialize() 

      DBSelectArea("SZX")
      SZX->(DBSetOrder(1)) // ZX_FILIAL+ZX_CGC  
      
      If Len(_oRetJSonC) < 100 .And. _cTipo == "P" // A ultima página possui quantidade de registros menor que 100. Deve ser linda novamente na próxima integração.
         _lPagCompl := .F.
      EndIf 

      _nTotRegs := Len(_oRetJSonC)

      ProcRegua(_nTotRegs)

      For _nI := 1 To _nTotRegs // Len(_oRetJSonC)

          If _nI > 15 // JPP TESTE
             Break 
          EndIf 

          IncProc("Processando registro: " + AllTrim(Str(_nI,10)) + " de " + AllTrim(Str(_nTotRegs,10))) 

          _oRetCli  := _oRetJSonC[_nI]
          _cJSonCli := FwJsonSerialize(_oRetCli)

          _cCnpj          := _oRetJSonC[_nI]:CnpjCpf       // CNPJ           // cnpj                       
          _cRazaosocial   := _oRetJSonC[_nI]:RazaoSocial   // RAZAOSOCIAL    // razao_social           
          _cNomefantasia  := _oRetJSonC[_nI]:NomeFantasia  // NOMEFANTASIA   // nome_fantasia  
          _cInsestadual   := ""
          _cInsmunicipal  := ""

          If _oRetJSonC[_nI]:TipoInscricao == "E"        
             _cInsestadual   := _oRetJSonC[_nI]:Inscricao  // INSESTADUAL    // inscricao_estadual    
          ElseIf _oRetJSonC[_nI]:TipoInscricao == "M"         
             _cInsmunicipal  := _oRetJSonC[_nI]:Inscricao  // INSMUNICIPAL   // inscricao_municipal    
          ElseIf _oRetJSonC[_nI]:TipoInscricao == "I"   
            _cInsestadual   := "ISENTO"
            _cInsmunicipal  := "ISENTO"
          EndIf 

          _cTipo           := "R"                         // TIPO           // tipo                       
          _cSegmento       := "31"                        // SEGMENTO       // Segmento               
          _cVendedor       := _cCodVend                   // CODIGOVENDEDOR // Código Vendedor   
          _cFisicajuridica := _oRetJSonC[_nI]:TipoPessoa       
          _cEmail          := _oRetJSonC[_nI]:Email        // EMAIL          // email_nfe 
          _cDdd            := _oRetJSonC[_nI]:DDD          // DDD            //                        
          _cTelefone       := _oRetJSonC[_nI]:Telefone     // TELEFONE       // telefone_geral_1       
          
          _cNumero       := ""
          _cCep          := ""
          _cEndereco     := ""
          _cBairro       := ""
          _cComplemento  := ""
          _cEstado       := ""
          _cCodmunicipio := ""
          _cSegmento     := "" 
                     
          For _nJ := 1 To Len(_oRetJSonC[_nI]:clienteendereco) 
              
              If _oRetJSonC[_nI]:clienteendereco[_nJ]:tpend == "EN"  // "CO" = Endereço de Cobrança // "FA" = Endereço de Faturamento
                               
                 _cNumero       := _oRetJSonC[_nI]:clienteendereco[_nJ]:Numero
                 If Empty(_cNumero)
                    _cNumero := ""
                 EndIf

                 _cCep          := Str(_oRetJSonC[_nI]:clienteendereco[_nJ]:CEP,8)                    // CEP            // endereco_cep               
                 _cEndereco     := _oRetJSonC[_nI]:clienteendereco[_nJ]:Logradouro
                 If Empty(_cEndereco)
                    _cEndereco := ""
                 EndIf 

                 _cEndereco := _cEndereco + ", " + _cNumero  // ENDERECO       // endereco_rua           

                 _cBairro       := _oRetJSonC[_nI]:clienteendereco[_nJ]:Bairro                        // BAIRRO         // endereco_bairro        
                 _cComplemento  := _oRetJSonC[_nI]:clienteendereco[_nJ]:Complemento                   // COMPLEMENTO    // endereco_complemento   
                 _cEstado       := _oRetJSonC[_nI]:clienteendereco[_nJ]:UF                            // ESTADO         // estado_codigo_ibge     
                 
                 _cCodmunicipio := _oRetJSonC[_nI]:clienteendereco[_nJ]:CodigoMunicipio        // CODMUNICIPIO   // municipio_codigo_ibge        
                 If Empty(_cCodmunicipio) .Or. ValType(_cCodmunicipio) == "U"
                    _cCodmunicipio := "" 
                 ElseIf ValType(_cCodmunicipio) == "N"
                    _cCodmunicipio := Str(_cCodmunicipio,7)
                 EndIf 

                 _cCodmunicipio := SubStr(_cCodmunicipio,3,5) // Vem o código completo do município: UF+CODIGO MUNICÍPIO. Gravar apenas as ultimas 5 posições.

                 _cPais         := "105"  // _oRetJSonC[_nI]:clienteendereco[_nJ]:tpend:"105"  
                 _cContato      := ""     //_oRetJSonC[_nI]:clienteendereco[_nJ]:tpend: // NOME DO CONTATO
                 _cCargoContato := ""     //_oRetJSonC[_nI]:clienteendereco[_nJ]:tpend: // CARGO DO CONTATO
                 _cEMAILC       := ""     //_oRetJSonC[_nI]:clienteendereco[_nJ]:tpend: // EMAILCONTATO   // E-mail contato    

              EndIf 

          Next 

          _cGrupoVen := U_MOMS069G(_cCnpj)

          If SZX->(DBSeek(xFilial("SZX") + _cCnpj))
             U_ITCONOUT("[FALSO] Ja exisite o cliente: " + AllTrim(SZX->ZX_NOME) + ", cadastrado com o CNPJ " + Transform(_cCnpj,"@R! NN.NNN.NNN/NNNN-99") + ".")

             _cMotivoCli := "Ja exisite o cliente: " + AllTrim(SZX->ZX_NOME) + ", cadastrado com o CNPJ " + Transform(_cCnpj,"@R! NN.NNN.NNN/NNNN-99") + "."
             ZBM->(RecLock("ZBM",.T.))
             ZBM->ZBM_FILIAL := xFilial("ZBM") 	// Filial
             ZBM->ZBM_CNPJ	  := _cCnpj    		// Cnpj/Cpf
             ZBM->ZBM_NOME	  := _cRazaosocial	// Razão Social
             ZBM->ZBM_IDCLIE := AllTrim(Str(_oRetJSonC[_nI]:IdCliente,18))		// ID.Cliente
             ZBM->ZBM_VEND   := _cVendedor		// Cod.Vendedor
             ZBM->ZBM_MOTIVO := _cMotivoCli		// Motivo Rej
             ZBM->ZBM_DTREJ  := Date()		      // Data Rejeic
             ZBM->ZBM_HRREJ  := Time()		      // Hora Rejeic
             ZBM->ZBM_JSONRC := _cJSonCli 		// Json Recebid
             ZBM->ZBM_DTREC  := Date()    		// Data Recebim
             ZBM->ZBM_HRREC  := Time()    		// Hora Recebim
             ZBM->ZBM_STATUS := "R"		         // Status Integração
             ZBM->(MSUnLock()) 

             Loop          
          Else
             DBSelectArea("SA1")
             DBSetOrder(3)
             If SA1->(DBSeek(xFilial("SA1") + _cCnpj))
                U_ITCONOUT("[MOMS069] Ja exisite o cliente: " + AllTrim(SA1->A1_NOME) + ", cadastrado com o CNPJ " + Transform(_cCnpj,"@R! NN.NNN.NNN/NNNN-99") + ".")
      
                _cMotivoCli := "Ja exisite o cliente: " + AllTrim(SA1->A1_NOME) + ", cadastrado com o CNPJ " + Transform(_cCnpj,"@R! NN.NNN.NNN/NNNN-99") + "."

                ZBM->(RecLock("ZBM",.T.))
                ZBM->ZBM_FILIAL := xFilial("ZBM") 	// Filial
                ZBM->ZBM_CNPJ	  := _cCnpj    		// Cnpj/Cpf
                ZBM->ZBM_NOME	  := _cRazaosocial	// Razão Social
                ZBM->ZBM_IDCLIE := AllTrim(Str(_oRetJSonC[_nI]:IdCliente,18))		// ID.Cliente
                ZBM->ZBM_VEND   := _cVendedor		// Cod.Vendedor
                ZBM->ZBM_MOTIVO := _cMotivoCli		// Motivo Rej
                ZBM->ZBM_DTREJ  := Date()		      // Data Rejeic
                ZBM->ZBM_HRREJ  := Time()		      // Hora Rejeic
                ZBM->ZBM_JSONRC := _cJSonCli 		// Json Recebid
                ZBM->ZBM_DTREC  := Date()    		// Data Recebim
                ZBM->ZBM_HRREC  := Time(    )		// Hora Recebim
                ZBM->ZBM_STATUS := "R"		         // Status Integração
                ZBM->(MSUnLock()) 

                Loop
             EndIf
          EndIf   

          If !(_cTipo $ "FLRSX")
             U_ITCONOUT("[MOMS069] Tipo do cliente nao esta dentro dos parametros esperados: F=Cons.Final;L=Produtor Rural;R=Revendedor;S=Solidario;X=Exportacao")
	          Loop
          EndIf
    
          // Inicia gravação do prospect
          // Campos fixos pelo padrão
          _cPaisBacen	:= "01058"
          _cPais		:= "105"
 
          // regra 01 - se o nome reduzido estiver em branco, assumo o campo cRazão, que alimentará o A1_NOME
          If Empty(AllTrim(_cNomefantasia))
             _cNomefantasia := _cRazaosocial
          Else
             _cNomefantasia := AllTrim(_cNomefantasia)
          EndIf
          
          If Empty(_cFisicajuridica)
             _cPessoa	     	:= IIf(Len(_cCnpj) < 14,"F","J")
             _cFisicajuridica	:= _cPessoa
          EndIf 

          // Removendo caracteres especiais de campos texto.
          _cRazaosocial    := U_ITSUBCHR(_cRazaosocial)
          _cNomefantasia   := U_ITSUBCHR(_cNomefantasia)
          _cFisicajuridica := U_ITSUBCHR(_cFisicajuridica)
          _cEmail          := U_ITSUBCHR(_cEmail)
          _cEndereco       := U_ITSUBCHR(_cEndereco)
          _cBairro         := U_ITSUBCHR(_cBairro)
          _cComplemento    := U_ITSUBCHR(_cComplemento)

          If SubStr(_cCodmunicipio,1,1) == "*"
             _cCodmunicipio := ""
          EndIf 
          
          _cVencL := "31/12/" + StrZero(Year(Date()),4)  // data de vencimento do limite de crédito.
          _dVencL := Ctod(_cVencL)  // data de vencimento do limite de crédito.

          _cGrupoVen := U_MOMS069G(_cCnpj)

          // Incluindo os novos clientes no Prospect.
          SZX->(RecLock("SZX",.T.))
          SZX->ZX_FILIAL  := xFilial("SZX")
          SZX->ZX_CGC     := _cCnpj          // CNPJ           // cnpj                       
          SZX->ZX_NOME    := _cRazaosocial   // RAZAOSOCIAL    // razao_social           
          SZX->ZX_NREDUZ  := _cNomefantasia  // NOMEFANTASIA   // nome_fantasia         
          SZX->ZX_INSCR   := _cInsestadual   // INSESTADUAL    // inscricao_estadual    
          SZX->ZX_INSCRM  := _cInsmunicipal  // INSMUNICIPAL   // inscricao_municipal    
          SZX->ZX_TIPO    := _cTipo          // TIPO           // tipo                       
          SZX->ZX_DDD     := _cDdd           // DDD            //                        
          SZX->ZX_TEL     := _cTelefone      // TELEFONE       // telefone_geral_1           
          SZX->ZX_EMAIL   := _cEmail         // EMAIL          // email_nfe              
          SZX->ZX_CEP     := _cCep           // CEP            // endereco_cep               
          SZX->ZX_END     := _cEndereco      // ENDERECO       // endereco_rua           
          SZX->ZX_BAIRRO  := _cBairro        // BAIRRO         // endereco_bairro        
          SZX->ZX_COMPLEM := _cComplemento   // COMPLEMENTO    // endereco_complemento   
          SZX->ZX_EST     := _cEstado        // ESTADO         // estado_codigo_ibge     
          SZX->ZX_CODMUN  := _cCodmunicipio  // CODMUNICIPIO   // municipio_codigo_ibge        
          SZX->ZX_GRCLI   := _cSegmento      // SEGMENTO       // Segmento               
   
          SZX->ZX_VEND    := _cVendedor      // CODIGOVENDEDOR // Código Vendedor   
          SZX->ZX_EMISSAO := Date()   
          SZX->ZX_CODEMP  := '010' 
          SZX->ZX_MSBLQL  := '2'
          SZX->ZX_STATUS  := 'L'
          SZX->ZX_EVENTO  := '0'
          SZX->ZX_CHEP    := "N"  
          SZX->ZX_I_RISCO := "C"   
          SZX->ZX_I_GRPVE := _cGrupoVen // "999999"  
          SZX->ZX_PESSOA  := _cFisicajuridica    
          SZX->ZX_PAIS    := _cPais     
          SZX->ZX_CONTATO := _cContato       // NOME DO CONTATO
          SZX->ZX_CARGC   := _cCargoContato  // CARGO DO CONTATO
          SZX->ZX_EMAILC  := _cEMAILC        // EMAILCONTATO   // E-mail contato   
          SZX->ZX_I_ORIGD := "O"
          SZX->ZX_I_LC    := 10000          
          SZX->ZX_I_VENCL := _dVencL        // Data de vencimento do limite de crédito.
          SZX->ZX_I_ACRED := "Cliente importado via API broker"
          SZX->ZX_I_IBOLE := "S"

          SZX->(MSUnLock())  
          _lRet := .T.

          U_ITConOut("[MOMS069] - Cliente " + _cRazaosocial + " CNPJ " + Transform(_cCnpj,"@R! NN.NNN.NNN/NNNN-99") + " - incluido com sucesso no prospect!")

          _cMotivoCli := "Cliente " + _cRazaosocial + " CNPJ " + Transform(_cCnpj,"@R! NN.NNN.NNN/NNNN-99") + " - incluido com sucesso no prospect!"
          ZBM->(RecLock("ZBM",.T.))
          ZBM->ZBM_FILIAL := xFilial("ZBM") 	// Filial
          ZBM->ZBM_CNPJ	  := _cCnpj    		// Cnpj/Cpf
          ZBM->ZBM_NOME	  := _cRazaosocial	// Razão Social
          ZBM->ZBM_IDCLIE := AllTrim(Str(_oRetJSonC[_nI]:IdCliente,18))		// ID.Cliente
          ZBM->ZBM_VEND   := _cVendedor		// Cod.Vendedor
          ZBM->ZBM_MOTIVO := _cMotivoCli		// Motivo Rej
          ZBM->ZBM_JSONRC := _cJSonCli 		// Json Recebid
          ZBM->ZBM_DTREC  := Date()    		// Data Recebim
          ZBM->ZBM_HRREC  := Time()    		// Hora Recebim
          ZBM->ZBM_STATUS := "A"		         // Status Integração
          ZBM->(MSUnLock()) 
      Next
      
      If _lPagCompl .And. _cTipo == "P"
         _cPagina := AllTrim(Str(Val(_cPagina)+1,10))
      Else 
         Exit 
      EndIf 

   EndDo 
   
   // Grava a ultima página lida para a nova integração.
   If _cTipo == "P"
      ZFM->(RecLock("ZFM",.F.)) 
      ZFM->ZFM_AUX02 := AllTrim(_cPagina) // Numero da ultima página de cliente lida.
      ZFM->(MSUnLock())
   EndIf 

End Sequence

Return _lRet

/*
===============================================================================================================================
Função-------------: MOMS069T
Autor--------------: Julio de Paula Paz
Data da Criacao----: 27/03/2023
Descrição----------: Efetua o Login no WebService Broker da Target Sistemas para Obtenção do Token de Acesso.
                     O Período estimado de validade deste Token é de XXxxx min.
Parametros---------: _cChamada = "M" = Menu
                                 "S" = Scheduller
                     _cEmpWebSe =  Código de Empresa WebService.
Retorno------------: _cRet = Vazio ou o Token de acesso.
===============================================================================================================================
*/  
User Function MOMS069T(_cChamada, _cEmpWebSe)

Local _cRet := "" 
Local _cEmpWebService := SuperGetMV('IT_CODWSBR',.T.,"000004")
Local _cDirJSon, _cLinkWS
Local _cUsuario, _cSenha 
Local _aHeadOut := {}
Local _oRetJSonT

Default _cChamada := "M"

Begin Sequence 

   _cUsuario := ""
   _cSenha   := ""
   
   // Obtem os dados do servidor Webservice.
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK01) 
      _cUsuario := AllTrim(ZFM->ZFM_USRNOM)
      _cSenha   := AllTrim(ZFM->ZFM_SENHA)
   Else 
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Empresa WebService para envio dos dados não localizada.")
      EndIf 

      Break
   EndIf

   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120
   
   _aHeadOut := {}              
   aAdd(_aHeadOut,'accept: application/json')     
   aAdd(_aHeadOut,'username: '+AllTrim(_cUsuario)) 
   aAdd(_aHeadOut,'password: '+AllTrim(_cSenha)) 

   _cLinkWS := AllTrim(_cLinkWS) 
   
   _cGetParms := "" 
   
   _cRetHttp := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet)) 
  
   _oRetJSonT := Nil 
   _cKey := ""
   _oTokenJSon := Nil 

   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
      _cRetHttp := StrTran( _cRetHttp, "\n", "" )
      FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSonT)       
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf        

   If ! Empty(_oRetJSonT) 
      _cKey := _oRetJSonT:token
   Else 
      Break
   EndIf 

   _cRet := _cKey

End Sequence 

Return _cRet

/*
===============================================================================================================================
Função-------------: MOMS069R
Autor--------------: Julio de Paula Paz
Data da Criacao----: 27/03/2023
Descrição----------: Rotina de Recebimento de dados dos Pedidos de Vendas do Broker via WebService da Target Sistemas.
Parametros--------: _cChamada = "M" = Rotina Chamada via menu.
                                "S" = Rotina Chamada via Scheduller
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS069R(_cChamada)

Local _cEmpWebService := SuperGetMV('IT_CODWSBR',.T.,"000004") 
Local _cDirJSon, _cLinkWS
Local _cKey
Local _cCodVend := ""
Local _cPagina  := ""
Local _nI , _nJ, _nX   
Local _lPagCompl := .T.
Local _nTotRegs 
Local _cIdPedVen, _cIdPedCli  
Local _cItem 
Local _cTimeStamp, _cTabPrcVe
Local _cJSonRet
Local _oRetPedV, _cJSonPedV, _cMotivoPV

Begin Sequence 

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS  := AllTrim(ZFM->ZFM_LINK03)   // Link de Leitura dos Dados dos Pedidos de Vendas do Broker.  
      _cCodVend := AllTrim(ZFM->ZFM_AUX01)    // Código do Vendedor do Broker.
      _cPagina  := AllTrim(ZFM->ZFM_AUX03)    // Numero da ultima página de Pedidos de Vendas.
   Else 
      If _cChamada == "M" // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Empresa WebService para envio dos dados não localizada.")
      EndIf 

      Break
   EndIf

   If Empty(_cPagina)
      _cPagina := "1"
   EndIf 
 
   _cCodVend := U_ItKey(_cCodVend,"A3_COD")
   
   SA1->(DBSetOrder(3))    // A1_FILIAL+A1_CGC 
   SB1->(DBSetOrder(5))    // B1_FILIAL+B1_CODBAR
   SZW->(DBSetOrder(17))   // H-ZW_FILIAL+ZW_PEDIMPO
   ZG5->(DBSetOrder(3))  
   SA3->(DBSetOrder(1))
   SZX->(DBSetOrder(1))    // ZX_FILIAL+ZX_CGC  
    
   _cTabPrcVe := "" 
   If SA3->(MsSeek(xFilial("SA3")+U_ITkEY(_cCodVend,"A3_COD")))
      _cTabPrcVe := SA3->A3_I_TABPR
   EndIf 

   While .T. 

      _cKey := U_MOMS069T(_cChamada) // Obtem o Token de acesso. 

      If Empty(_cKey)
         If _cChamada == "M" // Chamada via menu.   
            U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Pedidos de Vendas Broker cancelada.","Atenção",,1)
         Else // Chamada via Scheduller
            U_ItConOut("[MOMS069] - Erro ao na obtenção do Token. Rotina de Integração de Pedidos de Vendas Broker cancelada.")
         EndIf

         Break
      EndIf 
   
      _aHeadOut := {}              
   
      aAdd(_aHeadOut,'accept: application/json')
      aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil 
      _nTimOut	 	:= 120
      _cGetParms  := ""   
      _cRetHttp   := ''
      _oJSonRet   := ""
      _oRetJSonP   := ""
     
      _cRetHttp := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   

      If ! Empty(_cRetHttp)
         varinfo("WebPage-http ret.", _cRetHttp)
      Else
         Break // Não há mais dados de retonro para clientes disponíveis no WebService do Broker.  
      EndIf

      FWJSonDeserialize(_cRetHttp,@_oRetJSonP)  

      If ValType(_oRetJSonP) <> "O" .And. ValType(_oRetJSonP) <> "A"
         Break // Não foi possível obter dados dos clientes para inserção no Prospect.
      EndIf 

      // As novas funções Totvs para arquivos JSon não estão funcionando com os JSons
      // retornados pelo Broker. Devido ao Conteúdo muito grande.
      // Usando como alternativa a função descontinuada da Totvs: FWJSonDeserialize() 
      If Len(_oRetJSonP) < 100 // A ultima página possui quantidade de registros menor que 100. Deve ser linda novamente na próxima integração.
         _lPagCompl := .F.
      EndIf 

      _nTotRegs := Len(_oRetJSonP)

      ProcRegua(_nTotRegs)

      For _nI := 1 To _nTotRegs 
          
          If _nI > 5 // JPP TESTE
             Break 
          EndIf 

          IncProc("Processando registro: " + AllTrim(Str(_nI,10)) + " de " + AllTrim(Str(_nTotRegs,10))) 
          
          // Se não achar o cliente no SA1 e no Prospect, desenvolver uma função para consultar o cliente no Broker, se achar integrar para o Protheus.
          If ! SA1->(MsSeek(xFilial("SA1")+U_ItKey(_oRetJSonP[_nI]:CnpjCpf,"A1_CGC"))) // Não achou o cliente na SA1 então verifica no Prospect.
             If ! SZX->(MsSeek(xFilial("SZX")+U_ItKey(_oRetJSonP[_nI]:CnpjCpf,"A1_CGC"))) // Não achou o cliente no Prospect, então chama a integração de clientes para o Pedido de Vendas.
                If ! U_MOMS069C(_cChamada, "C", _oRetJSonP[_nI]:idCliente) // Não conseguiu incluir no Prospect o cliente.
                   
                   _cMotivoPV := "Cliente do Pedidos de Vendas não cadastrados. Não foi possível incluir o cliente dos pedido de vendas no Prospect."
                 
                   ZBN->(RecLock("ZBN",.T.))
                   ZBN->ZBN_FILIAL	 := xFilial("ZBN")                              // Filial do Sistema
                   ZBN->ZBN_IDPEDV	 := AllTrim(Str(_oRetJSonP[_nI]:idPedido,16))   // Id.Pedido de Vendas
                   ZBN->ZBN_CNPJ	 := _oRetJSonP[_nI]:CnpjCpf                     // Cnpj / Cpf do Cliente
                   ZBN->ZBN_IDCLIE  := AllTrim(Str(_oRetJSonP[_nI]:idCliente ,16)) // Id.Cliente
                   ZBN->ZBN_VEND    := _cCodVend                                   // Codigo do Vendedor
                   ZBN->ZBN_MOTIVO  := _cMotivoPV                                  // Motivo da Rejeição
                   ZBN->ZBN_DTREJ   := Date()                                      // Data da Rejeição
                   ZBN->ZBN_HRREJ   := Time()                                      // Hora da Rejeição
                   ZBN->ZBN_JSONRC  := _cJSonPedV                                  // Json Recebido
                   ZBN->ZBN_DTREC   := Date()                                      // Data de Recebimento
                   ZBN->ZBN_HRREC   := Time()                                      // Hora de Recebimento
                   ZBN->ZBN_STATUS  := "R"                                         // Status da Integração
                   ZBN->(MSUnLock())

                   Loop // Não inclui o Pedido de Vendas no Portal.
                EndIf
             EndIf 
          EndIf  
     
          _nTotParc  := Len(_oRetJSonP[_nI]:PEDIDOPARCELA)
          _cParcela  := ""
          _cCondPag  := ""
          _cCodCondP := ""    
          For _nJ := 1 To _nTotParc 
              
              _cParcela := _oRetJSonP[_nI]:PEDIDOPARCELA[_nJ]:PARCELA
              
              _cCondPag := U_MOMS069P(_oRetJSonP[_nI]:PEDIDOPARCELA[_nJ]:prazo)
              If ! Empty(_cCondPag)
                 _cCodCondP := _cCondPag
              EndIf 

          Next 

          //ZW_PEDIMPO
          If ValType(_oRetJSonP[1]:idPedido) == "N"
             _cIdPedCli := _cCodVend + AllTrim(Str(_oRetJSonP[_nI]:idPedido,16))
          Else
             _cIdPedCli := _cCodVend + AllTrim(_oRetJSonP[_nI]:idPedido)                 
          EndIf 

          _cIdPedVen  := U_MOMS069N(_cCodVend)

          // CAPA
          If SZW->(MsSeek(xFilial("SZW") + U_ITkey(_cIdPedCli,"ZW_PEDIMPO")))
             // Não haverá alterações de Pedidos de Vendas nesta integração. 
             _cMotivoPV := "Pedido de Vendas Rejeitado. O pedido de vendas informado: " + _cIdPedCli + ", já existe no portal de pedidos de vendas Italac. Não é permitido alterações."

             ZBN->(RecLock("ZBN",.T.))
             ZBN->ZBN_FILIAL	 := xFilial("ZBN")                              // Filial do Sistema
             ZBN->ZBN_IDPEDV	 := AllTrim(Str(_oRetJSonP[_nI]:idPedido,16))   // Id.Pedido de Vendas
             ZBN->ZBN_CNPJ	 := _oRetJSonP[_nI]:CnpjCpf                     // Cnpj / Cpf do Cliente
             ZBN->ZBN_IDCLIE  := AllTrim(Str(_oRetJSonP[_nI]:idCliente ,16)) // Id.Cliente
             ZBN->ZBN_VEND    := _cCodVend                                   // Codigo do Vendedor
             ZBN->ZBN_MOTIVO  := _cMotivoPV                                  // Motivo da Rejeição
             ZBN->ZBN_DTREJ   := Date()                                      // Data da Rejeição
             ZBN->ZBN_HRREJ   := Time()                                      // Hora da Rejeição
             ZBN->ZBN_JSONRC  := _cJSonPedV                                  // Json Recebido
             ZBN->ZBN_DTREC   := Date()                                      // Data de Recebimento
             ZBN->ZBN_HRREC   := Time()                                      // Hora de Recebimento
             ZBN->ZBN_STATUS  := "R"                                         // Status da Integração
             ZBN->(MSUnLock())

             Loop
          EndIf 

          For _nX := 1 To Len(_oRetJSonP[_nI]:PedidoItem)

              _oRetPedV  := _oRetJSonP[_nI]
              _cJSonPedV := FwJsonSerialize(_oRetPedV)

              If ! SB1->(MsSeek(xFilial("SB1")+AllTrim(_oRetJSonP[_nI]:PedidoItem[_nX]:IDPRODUTO))) // Código de Barras de Produto não localizado.
                 _cMotivoPV := "O código de barras dos produto não está cadastrado no cadastro de produtos Italac."
                 
                 ZBN->(RecLock("ZBN",.T.))
                 ZBN->ZBN_FILIAL	 := xFilial("ZBN")                              // Filial do Sistema
                 ZBN->ZBN_IDPEDV	 := AllTrim(Str(_oRetJSonP[_nI]:idPedido,16))   // Id.Pedido de Vendas
                 ZBN->ZBN_CNPJ	 := _oRetJSonP[_nI]:CnpjCpf                     // Cnpj / Cpf do Cliente
                 ZBN->ZBN_IDCLIE  := AllTrim(Str(_oRetJSonP[_nI]:idCliente ,16)) // Id.Cliente
                 ZBN->ZBN_VEND    := _cCodVend                                   // Codigo do Vendedor
                 ZBN->ZBN_MOTIVO  := _cMotivoPV                                  // Motivo da Rejeição
                 ZBN->ZBN_DTREJ   := Date()                                      // Data da Rejeição
                 ZBN->ZBN_HRREJ   := Time()                                      // Hora da Rejeição
                 ZBN->ZBN_JSONRC  := _cJSonPedV                                  // Json Recebido
                 ZBN->ZBN_DTREC   := Date()                                      // Data de Recebimento
                 ZBN->ZBN_HRREC   := Time()                                      // Hora de Recebimento
                 ZBN->ZBN_STATUS  := "R"                                         // Status da Integração
                 ZBN->(MSUnLock())

                 Loop 
              EndIf 
              _cTimeStamp := FWTimeStamp( 4, DATE(), Time() )
             
              SZW->(RecLock("SZW",.T.)) 
			     SZW->ZW_FILIAL := xFilial("SZW")
			     SZW->ZW_CODEMP := "010"
			     SZW->ZW_IDPED  := _cIdPedVen 
			     SZW->ZW_EMISSAO:= Date()
			     SZW->ZW_TIMEEMI:= "0"
			     SZW->ZW_IDUSER := _cCodVend //"001583"
			     SZW->ZW_VEND1  := _cCodVend //"001583"
			     SZW->ZW_STATUS := "L"
              SZW->ZW_IMPRIME := "1"
			     SZW->ZW_CLIENTE := SA1->A1_COD
			     SZW->ZW_LOJACLI := SA1->A1_LOJA
			     SZW->ZW_CLIENT  := SZW->ZW_CLIENTE
			     SZW->ZW_LOJAENT := SZW->ZW_LOJACLI
			     SZW->ZW_TABELA  := If(Empty(SA1->A1_TABELA) , _cTabPrcVe , SA1->A1_TABELA)
			     SZW->ZW_CONDPAG := _cCondPag
			     SZW->ZW_TPFRETE := "C"
			     SZW->ZW_TIPO    := "12" // SC5->C5_I_OPER
			     SZW->ZW_TIPOCLI := SA1->A1_TIPO//"R"
			     SZW->ZW_TIPCAR  := "2"//"1 - Paletizada" , "2 - Batida"
			     SZW->ZW_PEDCLI  := "NT"
			     SZW->ZW_PEDIMPO := AllTrim(SZW->ZW_VEND1) + AllTrim(Str(_oRetJSonP[_nI]:idPedido,16))
              SZW->ZW_TIMEEMI:= _cTimeStamp   

			     // ITENS
              If ValType(_oRetJSonP[_nI]:PedidoItem[_nX]:seqPedidoItem) == "N"
                 _cItem := AllTrim(Str(_oRetJSonP[_nI]:PedidoItem[_nX]:seqPedidoItem,2))
              Else 
                 _cItem := AllTrim(Str(Val(_oRetJSonP[_nI]:PedidoItem[_nX]:seqPedidoItem),2))
              EndIf 
			     
              SZW->ZW_ITEM    := _cItem 
			     SZW->ZW_PRODUTO := SB1->B1_COD 
			     SZW->ZW_UM      := SB1->B1_UM 
			     SZW->ZW_QTDVEN  := _oRetJSonP[_nI]:PedidoItem[_nX]:Qtde 
			     SZW->ZW_PRCVEN  := _oRetJSonP[_nI]:PedidoItem[_nX]:ValorUnitario 
		        SZW->ZW_OBSCOM  := "Pedido Integrado do Broker."
              SZW->ZW_DESCONT := _oRetJSonP[_nI]:PedidoItem[_nX]:PercentualDesconto
			     SZW->ZW_HORAINC := Time()
			     SZW->ZW_2UM     := SB1->B1_SEGUM // "CX"
			     SZW->ZW_I_PRMP  := _oRetJSonP[_nI]:PedidoItem[_nX]:ValorUnitario // Preço minimo portal
			     SZW->ZW_I_PRNET := SZW->ZW_PRCVEN
			     SZW->ZW_PRUNIT  := _oRetJSonP[_nI]:PedidoItem[_nX]:ValorUnitario //
			     SZW->ZW_I_AGEND := "I"
			     SZW->ZW_TPVENDA := 'V'
			     
              _cArm := Posicione("SBZ",1,SZW->ZW_FILIAL+SZW->ZW_PRODUTO,"BZ_LOCPAD")
			     
              SZW->ZW_LOCAL   := _cArm 
			     
			     If SB1->B1_CONV > 0
			        If SB1->B1_TIPCONV = 'D'
				        SZW->ZW_SEGQTD := (SZW->ZW_QTDVEN/SB1->B1_CONV)
				     Else
				 	     SZW->ZW_SEGQTD := (SZW->ZW_QTDVEN*SB1->B1_CONV)
				     EndIf
			     Else
			        SZW->ZW_SEGQTD:=Val(_aDados[_nCpo,11])
			     EndIf

			     _cfilft    := SZW->ZW_FILIAL
			     _cLocal    := _cArm
			     _cMesoReg  := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MESO")
			     _cMicroReg := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MICR")
			     _cCodMunic := SA1->A1_COD_MUN
			     _cEstado   := SA1->A1_EST
			     _lBusca_2  := .F.
			     _lAchou    := .F.

			     If !Empty(_cLocal)
   			     //ZG5->(DBSetOrder(3))
				     If ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg+_cCodMunic))
				        _lAchou   := .T.
					     _lBusca_2 := .F.
				     ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg+_cMicroReg))
					     _lAchou   := .T.
					     _lBusca_2 := .F.
				     ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado+_cMesoReg))
					     _lAchou   := .T.
					     _lBusca_2 := .F.
				     ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cLocal+_cEstado))
					     _lAchou   := .T.
					     _lBusca_2 := .F.
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
				     ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg+_cMicroReg))
					      _lAchou := .T.
				     ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado+_cMesoReg))
					     _lAchou := .T.
				     ElseIf ZG5->(DBSeek(xFilial("ZG5")+_cfilft+_cEstado))
				        _lAchou := .T.
				     Else
				        _lAchou := .F.
				     EndIf
			     EndIf

			     If _lAchou
			        SZW->ZW_FECENT := Date() + IIf(ZG5->ZG5_FRDIAS >0,ZG5->ZG5_FRDIAS,ZG5->ZG5_DIAS) + 1
			     Else
				     SZW->ZW_FECENT := (Date() + 1)
			     EndIf

			     SZW->(MSUnLock())

              _cMotivoPV := "Pedido de Vendas integrado com Sucesso. O pedido de vendas informado: " + _cIdPedCli + ", foi incluído com sucesso no cadastro de pedidos de vendas do portal."

              ZBN->(RecLock("ZBN",.T.))
              ZBN->ZBN_FILIAL	 := xFilial("ZBN")                              // Filial do Sistema
              ZBN->ZBN_IDPEDV	 := AllTrim(Str(_oRetJSonP[_nI]:idPedido,16))   // Id.Pedido de Vendas
              ZBN->ZBN_CNPJ	 := _oRetJSonP[_nI]:CnpjCpf                     // Cnpj / Cpf do Cliente
              ZBN->ZBN_IDCLIE  := AllTrim(Str(_oRetJSonP[_nI]:idCliente ,16)) // Id.Cliente
              ZBN->ZBN_VEND    := _cCodVend                                   // Codigo do Vendedor
              ZBN->ZBN_MOTIVO  := _cMotivoPV                                  // Motivo da Rejeição
              ZBN->ZBN_JSONRC  := _cJSonPedV                                  // Json Recebido
              ZBN->ZBN_DTREC   := Date()                                      // Data de Recebimento
              ZBN->ZBN_HRREC   := Time()                                      // Hora de Recebimento
              ZBN->ZBN_STATUS  := "A"                                         // Status da Integração
              ZBN->(MSUnLock())

          Next 
      Next 

   EndDo 

   // Grava a ultima página lida para a nova integração.
   ZFM->(RecLock("ZFM", .F.))
   ZFM->ZFM_AUX03 := _cPagina   // Numero da ultima página de Pedidos do Portal lida.
   ZFM->(MSUnLock())
   
End Sequence

Return

/*
===============================================================================================================================
Função-------------: MOMS069S
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/03/2023
Descrição----------: Rotina para rodar em Scheduller e para fazer automaticamente as integrações de recebimento de dados  
                     do Broker (Integração Target Sistemas).
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS069S()

Local _cFilIntWS, _aFilIntWS
Local _nI  
Local _LigaDesWS 

Begin Sequence

   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   RESET ENVIRONMENT
   RpcSetType(2) // 3
   
   // Inicia processamento com base nas filiais do parâmetro.
	U_ItConOut( '[MOMS069] -  Abrindo o ambiente para filial 01...' )
 
   // Preparando o ambiente com a filial 01
   RpcSetEnv("01", "01",,,,, {"SA2","SZW","SZX","SB1"})

   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
   
   // Liga ou Desliga a integração Webservice via Scheduller
   _LigaDesWS := SuperGetMV('IT_LIGAWSB',.T.,.T.) 
   If ! _LigaDesWS
      Break 
   EndIf 

   // Inicia a Integração Webservice via Scheduller.
   _cFilIntWS := SuperGetMV('IT_FILITBR',.T.,"01;04;23;")  

   _aFilIntWS := {}
   
   ZZM->(DBGoTop())

   While ! ZZM->(Eof())
      If ZZM->ZZM_CODIGO $ _cFilIntWS
         aAdd(_aFilIntWS,ZZM->ZZM_CODIGO)
      EndIf 
     
      ZZM->(DBSkip())
   EndDo 

   // Para cada empresa cadastrada no parâmetro IT_FILITCL, inicializa o ambiente, simulando o usuário
   // fazendo login na filial a ser processada.
   For _nI := 1 To Len(_aFilIntWS)   
       
       _cfilial := _aFilIntWS[_nI]

       // Ativa a filial contida em _aFilIntWS
       RESET ENVIRONMENT
       RpcSetType(2) // 3
   
       // Inicia processamento com base nas filiais do parâmetro.
	    U_ItConOut( '[MOMS069] -  Abrindo o ambiente para filial 01...' )
 
       // Preparando o ambiente com a filial 01
       RpcSetEnv("01", _cfilial ,,,,, {"SA2","SZW","SZX","SB1"})
    
       Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
      
       cFilAnt := _cfilial 
    
	    cUSUARIO := Space(06)+"Administrador  "
	    cUserName:= "Schedule"

       U_ItConOut( '[MOMS069] - Iniciando schedule de integração de dados do Broker. ' )
   
       // Rotina de integração de envio dos dados de Produtores, Coleta de Leite e Recebimento dos dados 
       // dos Produtores do App Companhia do Leite.
       U_ItConOut( '[MOMS069] - Integrando dados dos Clientes e Pedidos de Vendas do Broker. ' )

       U_MOMS069(.T.)  // .T. = Indica que a rotina foi chamada via Scheduller. 
      
       U_ItConOut( '[MOMS069] - Finalizando schedule de integração de dados de Clientes e Pedidos de Vendas do Broker. ' )
   Next 

 End Sequence 

 Return 

/*
===============================================================================================================================
Programa----------: MOMS069P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 03/04/2023
Descrição---------: Retorna a Condição de Pagamento.
Parametros--------: _nPrazo = Numero de dias para condição de pagamento.
Retorno-----------: _cRet   = Código da condição de pagamento.
===============================================================================================================================
*/
User Function MOMS069P(_nPrazo)

Local _cRet := "" 
Local _cQry
Local _cDias 

Default _nPrazo := 0

Begin Sequence 
   
   _cDias := ""
   If ValType(_nPrazo) == "N"
      _cDias := AllTrim(Str(_nPrazo,10)) 
   ElseIf ValType(_nPrazo) == "C"
      _cDias := AllTrim(_nPrazo) 
   EndIf 
 
   If Empty(_cDias)
      Break 
   EndIf 

   If Select("TRBSE4") > 0
	   TRGSE4->( DBCloseArea() )
   EndIf

	_cQry := " SELECT E4_CODIGO AS CODIGO , E4_I_PRZMD FROM "+ RetSqlName('SE4') +" SE4 WHERE "+ RetSqlCond('SE4') +" AND  E4_I_PRZMD  = " + _cDias + "  AND E4_I_PARCS = 1 AND E4_MSBLQL <> '1' "
	
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSE4" , .T., .F. )

	TRBSE4->( DBGoTop() )
	If TRBSE4->(!Eof())
		_cRet := TRBSE4->CODIGO
	Else
		_cRet := ""
	EndIf
	

End Sequence 

If Select("TRBSE4") > 0
	TRBSE4->( DBCloseArea() )
EndIf

Return _cRet

/*
===============================================================================================================================
Programa----------: MOMS069N()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/01/2020
Descrição---------: Gera próximo numero de pedido de vendas do Portal (ZW_IDPED). Versão da Função GeraZWIDPED(_cCodVen).
Parametros--------: _cCodVend = Código do Vendedor.
Retorno-----------: _cRet     = Próximo numero do Pedido de Vendas Portal, por Vendedor.
===============================================================================================================================
*/
User Function MOMS069N(_cCodVend)

Local _cAlias := GetNextAlias()
Local _nPos   := 0 
Local _cQry   

   _cQry := " SELECT  NVL(MAX(ZW_IDPED),'0') AS CODIGO FROM "+ RetSqlName('SZW') +" SZW WHERE ZW_VEND1 = '"+_cCodVend+"' "

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry) , _cAlias , .T., .F. )

   (_cAlias)->( DBGoTop() )
   If (_cAlias)->(!Eof()) .And. (_cAlias)->CODIGO <> '0'
      _nPos := At("-",(_cAlias)->CODIGO)
	   _cRet := Left( (_cAlias)->CODIGO,_nPos )
	   _cRet := _cRet + Soma1( AllTrim(SubStr( (_cAlias)->CODIGO,_nPos+1)) )
   Else
	   _cRet := AllTim(Str(Val(_cCodVen)))+"-00001"
   EndIf

   If Empty(_cRet) 
      _cRet := AllTrim(Str(Val(_cCodVen)))+"-00001"
   EndIf


(_cAlias)->(DBCloseArea())

DBSelectArea("SZW")

Return _cRet

/*
===============================================================================================================================
Função-------------: MOMS069E
Autor--------------: Julio de Paula Paz
Data da Criacao----: 27/03/2023
Descrição----------: Rotina de Envio dos dados da nota Fiscal para o Broker via WebService da Target Sistemas.
Parametros--------: _lSCheduller = .T. = Rotina Chamada via menu.
                                   .F. = Rotina Chamada via Scheduller
Retorno------------: _lRet    = .T. = Gravou Prospect.
                              = .F. = Não gravou Prospect.
===============================================================================================================================
*/  
User Function MOMS069E(_lSCheduller)

Local _cEmpWebSe := SuperGetMV('IT_CODWSBR',.T.,"000004") 
Local _cDirJSon, _cLinkWS
Local _cKey
Local _cCodVend := ""
Local _cLinkEnv := ""
Local _lRet := .F.
Local _cJSonRet

Default _cTipo := "P"

Begin Sequence 

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebSe))
      _cDirJSon  := AllTrim(ZFM->ZFM_LOCXML)
      _cLinkWS   := AllTrim(ZFM->ZFM_LINK05)  // Link envio dos dados das notas fiscais Pedidos Venadas Broker.
      _cCodVend  := AllTrim(ZFM->ZFM_AUX01)   // Código do Vendedor do Broker.
      _LinkCerto := AllTrim(ZFM->ZFM_HOMEPG)  // Para garantir que os dados de desenvolvimento não sejam enviados/Transmitidos para a produção.   

   Else 
      If ! _lSCheduller // Chamada via menu.
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Empresa WebService para envio dos dados não localizada.")
      EndIf 

      Break
   EndIf

   If !totvs.framework.environment.Type.get() == '1' .Or. Empty(_LinkCerto) //1-Produção, 2-Homologação,3-Desenvolvimento
      If ! _lSCheduller // Chamada via menu.
         U_ITMsg("Você está em um ambiente de testes, mas os links estão direcionados para o ambiente de produção. ","Atenção","Altere os links deste ambiente para os links dos ambientes de testes.",1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Você está em um ambiente de testes, mas os links estão direcionados para o ambiente de produção. Altere os links deste ambiente para os links dos ambientes de testes.")      
      EndIf 

      Break
   EndIf  

   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf

   // Lê os arquivos modelo JSON e os transforma em String.
   _cCabec := U_MOMS069X(_cDirJSon+"Cabec_Faturamento_Broker.txt") 
   If Empty(_cCabec)
      If ! _lSCheduller  // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON modelo do cabeçalho integração Italac x Broker.","Atenção",,1) 
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Erro na leitura do arquivo modelo JSON modelo do cabeçalho integração Italac x Broker.")
      EndIf 

      Break
   EndIf

   _cDetalhe := U_MOMS069X(_cDirJSon+"Detalhe_Faturamento_Broker.txt") 

   If Empty(_cDetalhe)
      If ! _lSCheduller  // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON detalhe integração com o Broker.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Erro na leitura do arquivo modelo JSON detalhe integração com o Broker.")
      EndIf

      Break
   EndIf
   
   _cRodape := U_MOMS069X(_cDirJSon+"Rodape_Faturamento_Broker.txt") 
   If Empty(_cRodape)
      If ! _lSCheduller  // Chamada via menu.   
         U_ITMsg("Erro na leitura do arquivo modelo JSON Rodape de integração Italac x Broker.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Erro na leitura do arquivo modelo JSON Rodape de integração Italac x Broker.")
      EndIf 

      Break
   EndIf 

   If ! _lSCheduller // Chamada via menu.
      ProcRegua(0)
         
      Processa( {|| _lRet := U_MOMS069I(.F., _cCodVend) } , 'Aguarde!' , 'Lendo dados das notas fiscais e títulos...' )
   Else // Chamada via Scheduller
      _lRet := U_MOMS069I(.T., _cCodVend) // Lendo dados das notas fiscais e títulos... 
   EndIf 

   If ! _lRet  // Não há dados de notas fiscais para integração com o Broker
      Break
   EndIf 

   _cKey := U_MOMS069T(_lSCheduller, _cEmpWebSe) // Obtem o Token de acesso. 

   If Empty(_cKey)
      If ! _lSCheduller // Chamada via menu.   
         U_ITMsg("Erro ao na obtenção do Token. Rotina de Integração de Clientes Broker cancelada.","Atenção",,1)
      Else // Chamada via Scheduller
         U_ItConOut("[MOMS069] - Erro ao na obtenção do Token. Rotina de Integração de Clientes Broker cancelada.")
      EndIf

      Break
   EndIf 

   _cLinkEnv := _cLinkWS 
   _cChaveNFE := QRYSF2->F2_CHVNFE

   _cJSonDet := ""
   _cJSonRod := _cRodape 

   SZW->(DBSetOrder(1)) // ZW_FILIAL+ZW_IDPED

   While ! QRYSF2->(Eof())
      
      SZW->(MsSeek(QRYSF2->F2_FILIAL + QRYSF2->C5_I_IDPED))


      If _cChaveNFE <> QRYSF2->F2_CHVNFE
         _cChaveNFE := QRYSF2->F2_CHVNFE 
         
         _aHeadOut := {}              
   
         aAdd(_aHeadOut,'Content-Type: application/json')
         aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )

         _cJSonEnv :=  _cJSonCab + _cJSonDet  + _cJSonRod

         _nStart 		:= 0
         _nRetry 		:= 0
         _cJSonRet 	:= Nil 
         _nTimOut	 	:= 120
         _cRetorno   := ""
         _cRetHttp    := ''
      
         _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) ) 
         
         If ! Empty(_cRetHttp)
            varinfo("WebPage-http ret.", _cRetHttp)
            _cRetHttp := StrTran( _cRetHttp, "\n", "" )
            FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)             
         EndIf
         
         _cJSonDet := ""
      EndIf

      // Dados de cabeçalho
      _cIdPedido   := SubStr(SZW->ZW_PEDIMPO,7,20)

      _cIdNotaF    := QRYSF2->F2_FILIAL + QRYSF2->F2_DOC + QRYSF2->F2_SERIE + QRYSF2->F2_CLIENTE + QRYSF2->F2_LOJA 
      _cNrNotaF    := AllTrim(Str(Val(AllTrim(QRYSF2->F2_DOC)),16))
      _cSerieNF    := QRYSF2->F2_SERIE
      _cDtEmisNf   := DToS(QRYSF2->F2_EMISSAO)
      _cChaveNf    := QRYSF2->F2_CHVNFE
      _cProtocNf   := QRYSF2->F3_PROTOC
      
      _cJSonCab    := &(_cCabec)

      // Dados de detalhe
      _cIdFinanc := QRYSF2->F2_FILIAL + QRYSF2->E1_NUM + QRYSF2->E1_PREFIXO + QRYSF2->E1_CLIENTE + QRYSF2->E1_LOJA 
      _cNrTitulo := AllTrim(Str(Val(AllTrim(QRYSF2->E1_NUM)),9))
		_cParcela  := QRYSF2->E1_PARCELA
      _cTipoTit  := If(QRYSF2->A1_I_IBOLE = "S","DP","CR")
      _cLinhaDig := If(QRYSF2->A1_I_IBOLE = "S","COBRANCA VIA BOLETO BANCARIO","CREDIDO EM CONTA BANCARIA")
      _cDtEmiss  := DToS(QRYSF2->E1_EMISSAO)
      _cDtVenc   := DToS(QRYSF2->E1_VENCREA) 
		_cValTitul := Str(QRYSF2->E1_VALOR,17,2)
      _cValAbati := Str(QRYSF2->E1_I_DESCO,17,2)
      _cValDesco := Str(QRYSF2->E1_DESCONT + QRYSF2->E1_I_DESCO + QRYSF2->E1_DESCFIN,17,2)
      _cValTaxa  := Str(QRYSF2->E1_JUROS,17,2)
      _cTaxaJuro := Str(QRYSF2->E1_PORCJUR,17,2)
      _cValMulta := Str(QRYSF2->E1_MULTA,17,2)
      _cDtPagto  := DToS(QRYSF2->E1_BAIXA)
      _cValPago  := "0"
      _cDataAtua := DToS(Date())

      _cSituacao := ""
      If QRYSF2->E1_SALDO == QRYSF2->E1_VALOR
         _cSituacao := "AB" // Em Aberto
      ElseIf QRYSF2->E1_SALDO == 0
         _cSituacao := "LQ" // Liquidado
      ElseIf QRYSF2->E1_SALDO < QRYSF2->E1_VALOR .And. QRYSF2->E1_SALDO > 0
         _cSituacao := "PL" // Parcialmente liquidado.
      ElseIf QRYSF2->SITRSE1 == "*" // Regitro da SE1 Excluido.
         _cSituacao := "CA" // Cancelado
      EndIf
      
      If Empty(_cParcela)
         _cParcela := "0"
      EndIf 

      _cJSonDet += If(!Empty(_cJSonDet) , ',' ," ") + &(_cDetalhe)
      
      QRYSF2->(DBSkip())

   EndDo   

   If ! Empty(_cJSonDet)
      _aHeadOut := {}              
   
      aAdd(_aHeadOut,'Content-Type: application/json')
      aAdd(_aHeadOut,'Authorization: Bearer ' + AllTrim(_cKey) )

      _cJSonEnv :=  _cJSonCab + _cJSonDet + _cJSonRod

      _nStart 		:= 0
      _nRetry 		:= 0
      _cJSonRet 	:= Nil 
      _nTimOut	 	:= 120
      _cRetorno   := ""
      _cRetHttp    := ''
      
      _cRetHttp := AllTrim( HttpPost( _cLinkWS , '' , _cJSonEnv , _nTimOut , _aHeadOut , @_cJSonRet ) ) 
         
      If ! Empty(_cRetHttp)
         varinfo("WebPage-http ret.", _cRetHttp)
         _cRetHttp := StrTran( _cRetHttp, "\n", "" )
      EndIf

   EndIf 

Break // JPP TESTE

      If ! Empty(_cRetHttp)
         varinfo("WebPage-http ret.", _cRetHttp)
      Else
         Break // Não há mais dados de retonro para clientes disponíveis no WebService do Broker.  
      EndIf

      FWJSonDeserialize(_cRetHttp,@_oRetJSonC)  

      If ValType(_oRetJSonC) <> "O" .And. ValType(_oRetJSonC) <> "A"
         Break // Não foi possível obter dados dos clientes para inserção no Prospect.
      EndIf 

      // As novas funções Totvs para arquivos JSon não estão funcionando com os JSons
      // retornados pelo Broker. Devido ao Conteúdo muito grande.
      // Usando como alternativa a função descontinuada da Totvs: FWJSonDeserialize() 

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS069F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/04/2023
Descrição---------: Permite Visualizar os Clientes Rejeitados e Aceitos nos Recebimentos de Dados do Broker.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function MOMS069F(_cTipoDado)

Private aRotina := {}
Private cCadastro 

Begin Sequence 
   
   If _cTipoDado == "R"
      ZBM->(DbSetFilter( { || ZBM_STATUS == "R" }, 'ZBM_STATUS == "R"' ) )
      cCadastro := "Clientes Rejeitados no Recebimento de Dados do Broker" 
   Else
      ZBM->(DbSetFilter( { || ZBM_STATUS == "A" }, 'ZBM_STATUS == "A"' ) )
      cCadastro := "Clientes Aceitos no Recebimento de Dados do Broker"
   EndIf 

   ZBM->(DBGoTop())
   
   aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"                     ,"AxVisual" ,0,2})

   DBSelectArea("ZBM")
   ZBM->(DBSetOrder(1)) 
   ZBM->(DBGoTop())
      
   MBrowse(6,1,22,75,"ZBM")

   ZBM->(DBClearFilter())

End Sequence 

Return    

/*
===============================================================================================================================
Programa----------: MOMS069H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/04/2023
Descrição---------: Permite Visualizar os Pedidos de Vendas Rejeitados e Aceitos nos Recebimentos de Dados do Broker.
Parametros--------: _cTipoDado == "R" = Dados rejeitados na integração
                                  "A" = Dados aceitos na integração
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function MOMS069H(_cTipoDado)

Private aRotina := {}
Private cCadastro 

Begin Sequence 
   
   If _cTipoDado == "R"
      ZBN->(DbSetFilter( { || ZBN_STATUS == "R" }, 'ZBN_STATUS == "R"' ) )
      cCadastro := "Pedidos de Vendas Rejeitados no Recebimento de Dados do Broker" 
   Else
      ZBN->(DbSetFilter( { || ZBN_STATUS == "A" }, 'ZBN_STATUS == "A"' ) )
      cCadastro := "Pedidos de Vendas Aceitos no Recebimento de Dados do Broker"
   EndIf 

   ZBN->(DBGoTop())
   
   aAdd(aRotina,{"Pesquisar"                      ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"                     ,"AxVisual" ,0,2})

   DBSelectArea("ZBN")
   ZBN->(DBSetOrder(1)) 
   ZBN->(DBGoTop())
      
   MBrowse(6,1,22,75,"ZBN")

   ZBN->(DBClearFilter())

End Sequence 

Return    

/*
===============================================================================================================================
Programa----------: MOMS069G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/04/2023
Descrição---------: Verifica se existe grupo de vendas e retorna o grupo de vendas do CNPJ passado por parâmetro.
Parametros--------: _cCnpj = CNPJ a ser consultado.
Retorno-----------: _cRet = Grupo de vendas.
===============================================================================================================================
*/  
User Function MOMS069G(_cCnpj)

Local _cQry 
Local _cRaizCnpj
Local _cRet := "999999"

Begin Sequence 
   
   _cRaizCnpj := SubStr(_cCnpj,1,8)
   
   _cQry := " SELECT MIN(A1_GRPVEN) GRUPOVENDA "
   _cQry += " FROM "+ RetSqlName("SA1") + " SA1 "
   _cQry += " WHERE SA1.D_E_L_E_T_	<> '*' "
   _cQry += " AND A1_MSBLQL = '2' "
   _cQry += " AND	SubStr(SA1.A1_CGC,1,8)	= '"+_cRaizCnpj+"' "

   If Select("QRYSA1") > 0
	   QRYSA1->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "QRYSA1" , .T. , .F. )

   If ! QRYSA1->(Eof()) .And. ! QRYSA1->(Bof())
      _cRet := QRYSA1->GRUPOVENDA
   EndIf 

   If Empty(_cRet)
      _cRet := "999999"
   EndIf 

End Sequence 

If Select("QRYSA1") > 0
	QRYSA1->( DBCloseArea() )
EndIf

Return _cRet 

/*
===============================================================================================================================
Programa----------: MOMS069I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/04/2023
Descrição---------: Efetura a leitura das Notas Fiscais e Titulos Financeiros para envio ao Broker.
Parametros--------: _lScheduller = Rotina chamada via Scheduller (.T./.F.).
                    _cCodVend    = Código do Vendedor/Broker
Retorno-----------: _lRet = .T. = Há dados
                            .F. = Não há dados.
===============================================================================================================================
*/  
User Function MOMS069I(_lScheduller,_cCodVend)

Local _lRet := .F.
Local _cQry := ""
Local _nTotRegs
Local _dPerInic, _cPerInic


   _cPerInic := SuperGetMV("IT_PERINBR",.T.,"20/03/2023") // Periodo inicial de leitura dos dados da query.
   _dPerInic := Ctod(_cPerInic)

   _cQry := " SELECT DISTINCT F2_CHVNFE, " 
   _cQry += "        F2_FILIAL, "
   _cQry += "        F2_I_PEDID, "
   _cQry += "        F2_DOC, "
   _cQry += "        F2_SERIE, "
   _cQry += "        F2_CLIENTE, "
   _cQry += "        F2_LOJA, "
   _cQry += "        F2_FORMUL, "
   _cQry += "        F2_TIPO, "
   _cQry += "        F2_EMISSAO, "
   _cQry += "        F2_VEND1, "  
   _cQry += "        F2_PREFIXO, "
   _cQry += "        E1_PARCELA," 
   _cQry += "        E1_TIPO, "   
   _cQry += "        F3_PROTOC, "
   _cQry += "        F3_CODRSEF, "  
   _cQry += "        C5_I_IDPED, " 
   _cQry += "        A1_I_IBOLE, "
   _cQry += "        E1_TIPO, "
   _cQry += "        E1_EMISSAO, "
   _cQry += "        E1_VENCREA, "
   _cQry += "        E1_VALOR, " 
   _cQry += "        E1_I_DESCO, "
   _cQry += "        E1_DESCONT, "
   _cQry += "        E1_I_DESCO, "
   _cQry += "        E1_DESCFIN, " 
   _cQry += "        E1_JUROS, "   
   _cQry += "        E1_PORCJUR, " 
   _cQry += "        E1_MULTA, "   
   _cQry += "        E1_SALDO, " 
   _cQry += "        E1_VALOR, "
   _cQry += "        E1_BAIXA, "
   _cQry += "        E1_NUM, "    
   _cQry += "        E1_PREFIXO, "
   _cQry += "        E1_CLIENTE, "  
   _cQry += "        E1_LOJA, "
   _cQry += "        SE1.D_E_L_E_T_ AS SITRSE1 "
   _cQry += "        FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("SE1") + " SE1, " + RetSqlName("SA1") + " SA1, " + RetSqlName("SC5") + " SC5, " + RetSqlName("SF3") + " SF3, " + RetSqlName("SZW") + " SZW "      
   _cQry += "        WHERE SF2.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' AND SC5.D_E_L_E_T_ = ' ' AND SF3.D_E_L_E_T_ = ' ' AND SZW.D_E_L_E_T_ = ' ' " // Não incluir o delete da SE1 pois os registros excluidos da SE1 referem-se a Titulos Cancelados.
   _cQry += "        AND SF2.F2_FILIAL  = SC5.C5_FILIAL "
   _cQry += "        AND SF2.F2_DOC     = SC5.C5_NOTA "    
   _cQry += "        AND SF2.F2_SERIE   = SC5.C5_SERIE "
   _cQry += "        AND SF2.F2_CLIENTE  = SC5.C5_CLIENTE " 
   _cQry += "        AND SF2.F2_LOJA    = SC5.C5_LOJACLI  "
   _cQry += "        AND SF3.F3_FILIAL  = SF2.F2_FILIAL "   
   _cQry += "        AND SF3.F3_CHVNFE  = SF2.F2_CHVNFE  "
   _cQry += "        AND SF2.F2_FILIAL  = SE1.E1_FILIAL "
   _cQry += "        AND SF2.F2_DOC     = SE1.E1_NUM"    
   _cQry += "        AND SF2.F2_SERIE   = SE1.E1_PREFIXO "
   _cQry += "        AND SF2.F2_CLIENTE  = SE1.E1_CLIENTE " 
   _cQry += "        AND SF2.F2_LOJA    = SE1.E1_LOJA  "
   _cQry += "        AND SF2.F2_CLIENTE  = SA1.A1_COD "
   _cQry += "        AND SF2.F2_LOJA    = SA1.A1_LOJA "
   _cQry += "        AND SZW.ZW_FILIAL  = SC5.C5_FILIAL "
   _cQry += "        AND SZW.ZW_NUMPED	 = SC5.C5_NUM "
   _cQry += "        AND SZW.ZW_I_PEDDW = SC5.C5_I_PEDDW "
   _cQry += "        AND SZW.ZW_STATUS  = 'I'  "
   _cQry += "        AND SZW.ZW_OBSCOM  = 'Pedido Integrado do Broker.' "
   _cQry += "        AND F2_EMISSAO     >= '" + DToS(_dPerInic) + "' "
   _cQry += "        AND F2_VEND1       = '" + _cCodVend + "' "
   _cQry += "        AND F3_CODRSEF     = '100' "

   If Select("QRYSF2") > 0
      QRYSF2->(DBCloseArea())
   EndIf

   DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "QRYSF2" , .F. , .T. )
   TCSetField('QRYSF2',"F2_EMISSAO","D",8,0)
   TCSetField('QRYSF2',"E1_EMISSAO","D",8,0)
   TCSetField('QRYSF2',"E1_VENCREA","D",8,0)
   TCSetField('QRYSF2',"E1_BAIXA"  ,"D",8,0)
   
   Count to _nTotRegs

   QRYSF2->(DBGoTop())

   If _nTotRegs > 0
      _lRet := .T.
   Else 
      _lRet := .F.
   EndIf

   ProcRegua(_nTotRegs)

Return _lRet 

/*
===============================================================================================================================
Função-------------: MOMS069X
Autor--------------: Julio de Paula Paz
Data da Criacao----: 26/04/2023
Descrição---------: Lê o arquivo JSON modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq = diretório + nome do arquivo a ser lido.
Retorno-----------: _cRet
===============================================================================================================================
*/  
User Function MOMS069X(_cArq)

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
