/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |28/01/2025| Chamado 49712. Ajustes no retorno da integração.
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
Jose Gavetti  |07/10/2025| Chamado 52346. Ajuste para inscrição estadual isento estado MG.
Jose Gavetti  |26/11/2025| Chamado 51341. __cUserId não deve ter seu conteúdo alterado orientação TOTVS. 
===============================================================================================================================
*/

#Include "TOTVS.ch"  
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: AOMS138
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2017
Descrição---------: Rotina integração de dados cadastrais cisp/sintegra/receita e atualização do cadastro de clientes.
                    Chamado 44289.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS138()

Local _cMatUsr			:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
Local _cAutoriz		:= GetAdvFVal( "ZZL" , "ZZL_ATUCLI" , xFilial("ZZL") + _cMatUsr , 1 , "N" )

Private oproc
Private _cdtl := Date() - u_itgetmv("ITDIASCLI",30) //data limite de atualização dos clientes
Private _bType := {|x| Type(x)}
Private _aDadosRel := {}

Begin Sequence 
   //====================================================================================================
   // Controle de acesso por usuario conforme parametrizacao no Gerenciador (Gestao de Usuarios) 
   //====================================================================================================
   If !( _cAutoriz == "S" )
	   U_ITMsg("Usuário sem acesso à rotina de avaliação dos Pedidos bloqueados para análise de Crédito.","Atenção!",,1)
	   Break 
   EndIf

   //Log de utilização
   U_ITLOGACS()

   aRotina := {{ OemToAnsi("Pesquisar")  , "AxPesqui"   , 0 , 1 },; 
               { OemToAnsi("Visualizar") , 'AxVisual'   , 0 , 2 },; 
               { OemToAnsi("Atualizar")  , 'U_AOMS138M("P")' , 0 , 2 },;
               { OemToAnsi("Atua Geral") , 'U_AOMS138M("G")' , 0 , 2 },;
               { OemToAnsi("Legenda")    , 'U_AOMS138L()'    , 0 , 2 }}  
 
   cCadastro := OemToAnsi( "Integração dados cadastrais CISP/SINTEGRA/RECEITA" )

   _aCores :=   {{'SA1->A1_I_D3ST > _cdtl ', 'ENABLE'},;        // Atualizado
                 {'SA1->A1_I_D3ST <= _cdtl' , 'BR_VERMELHO' }}        // Desautalizado
 
   SA1->(MsFilter("SA1->A1_PESSOA == 'J' .And. SA1->A1_COD	> '000001'")) // 000001 = Código Italac, não atualizar via CISP.
   MBrowse( ,,,, "SA1" ,,,,,, _acores )
   SA1->(Dbclearfilter())

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: AOMS138M
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/07/2023
Descrição---------: Chamada das rotinas, conforme opção de menu.
Parametros--------: _cOpcMenu = P = Registro posicionado. 
                              = G = Geral, todo o cadastro.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS138M(_cOpcMenu)

Begin Sequence 
   If _cOpcMenu == "P"
      Processa( {|| U_AOMS138A() }, "Aguarde Consulta Posicionado...", "Iniciando Consulta Posicionado...",.F.)
   Else 
      Processa( {|| U_AOMS138G() }, "Aguarde Consulta Geral..."      , "Iniciando Consulta Geral...",.F.)
   EndIf 

End Sequence


Return 


/*
===============================================================================================================================
Programa----------: AOMS138A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/07/2023
Descrição---------: Chamada de integração webservice de atualização do CISP/SINTEGRA/RECEITA FEDERAL posicionado no cliente.
Parametros--------: _lSchedule  = .T. = Rotina chamada via Scheduller / .F. = Rotina chamada manualmente.
                    _lEnvMail   = .T. / .F. = Envia e-mail = Sim / Não
                    _aDadosGeral = Daddo de processamento geral
                    _lExibeMsg   = Exibe mensagem na tela .T. / Não exibe mensagem na tela.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS138A(_lSchedule,_lEnvMail,_aDadosGeral,_lExibeMsg)
// Links Produção
Local _cLinkCspP  := U_ItGetMv("IT_LNKCSPP", "https://servicos.cisp.com.br/v1/avaliacao-analitica/raiz/")
Local _cLinkRecP  := U_ItGetMv("IT_LNKRECP", "https://api.maxxi.cisp.com.br/public-bases/v1/receita-federal/cnpj/")
Local _cLinkSufP  := U_ItGetMv("IT_LNKSUFP", "https://api.maxxi.cisp.com.br/public-bases/v1/suframa/cnpj/")
Local _cLinkSimP  := U_ItGetMv("IT_LNKSINP", "https://api.maxxi.cisp.com.br/public-bases/v1/simples-nacional/cnpj/")
Local _cLinkSnTP  := U_ItGetMv("IT_LNKSNTP", "https://api.maxxi.cisp.com.br/public-bases/v1/sintegra/cnpj/")
// Links Homologação
Local _cLinkCspH  := U_ItGetMv("IT_LNKCSPH", "https://servicos.cisp.com.br/v1/avaliacao-analitica/raiz/")
Local _cLinkRecH  := U_ItGetMv("IT_LNKRECH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/receita-federal/cnpj/")
Local _cLinkSufH  := U_ItGetMv("IT_LNKSUFH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/suframa/cnpj/")
Local _cLinkSimH  := U_ItGetMv("IT_LNKSINH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/simples-nacional/cnpj/")
Local _cLinkSnTH  := U_ItGetMv("IT_LNKSNTH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/sintegra/cnpj/")

// Token Produção
Local _cToknRecP  := U_ItGetMv("IT_TKNRECP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")
Local _cToknSufP  := U_ItGetMv("IT_TKNSUFP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")
Local _cToknSimP  := U_ItGetMv("IT_TKNSINP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")
Local _cToknSnTP  := U_ItGetMv("IT_TKNSNTP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")

// Token Homologação
Local _cToknRecH  := U_ItGetMv("IT_TKNRECH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")
Local _cToknSufH  := U_ItGetMv("IT_TKNSUFH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")
Local _cToknSimH  := U_ItGetMv("IT_TKNSINH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")
Local _cToknSnTH  := U_ItGetMv("IT_TKNSNTH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")

// Usuário e Senha Cisp
Local _cPasswd    := u_ItGetMv("IT_PWCISP" ,"!t@lac95_01#")
Local _cUser	   := u_ItGetMv("IT_USCISP" ,"ws09501")

// Indica se utilizará link de produção ou link de homologação
Local _lLinkPrd   := U_ItGetMv("IT_LKCISPP", .T.) 

// Declarações comuns.
Local _cUrlCisp  := ""
Local _cUrlRecF  := ""
Local _cUrlSufr  := ""
Local _cUrlSimp  := ""
Local _cUrlSint  := ""
Local _lRet      := .F.
Local _lRetCisp  := .F.
Local _lRetSint  := .F.
Local _lRetRec   := .F.
Local _lRetSufr  := .F.
Local _lRetSimpN := .F. 
Local _nPosIni 
Local _nPodFin
Local _nI 
Local _cObserv
Local _cUfMVA    := U_ITGetMV("IT_UFSMVA","PR")
Local _cTRIBMVA  := U_ITGetMV("IT_TRIBMVA","023")
Local _aStrSubst :=  {{"*",""},{"$",""},{""," "},{"Ã","A"},{"?"," "}}
Local _cTextoAux := ""

Local _oBusiness   := Nil
Local _cCNAECisp   := ""
Local _cCodNegoc   := ""
Local _cDesecNegoc := ""


Private _cUsuario 

Default _lSchedule   := .F.
Default _lEnvMail    := .T.
Default _aDadosGeral := {}
Default _lExibeMsg   := .T.

Begin Sequence 

   //==========================================
   // Não atualiza cliente bloqueado
   //==========================================
   If (SA1->A1_MSBLQL = "1")

      If ! _lSchedule .And. _lExibeMsg
         U_ITMsg("Cliente Bloqueado. Esta rotina não atualiza cliente bloqueado.","Atenção",,1)
      Else 
         U_ITConout("[AMOS138] - Cliente Bloqueado. Esta rotina não atualiza cliente bloqueado.")
      EndIf
	   
      _lRet :=  .F.
	   
      Break
	
   EndIf

   //=========================================
   // Só atualiza pessoas juridicas
   //=========================================
   If !(SA1->A1_PESSOA = "J")

      If ! _lSchedule .And. _lExibeMsg
    	   U_ITMsg("Cliente pessoa fisica. Esta rotina só atualiza pessoa jurídica.","Atenção",,1)
      Else 
         U_ITConout("[AMOS138] - Cliente pessoa fisica. Esta rotina só atualiza pessoa jurídica.")
      EndIf
	   
      _lRet :=  .F.
	   
      Break
	
   EndIf
  
   //==========================================================
   // Não atualiza clientes marcados como não atualizaveis
   //==========================================================
   If SA1->A1_I_ATCIS == "N"
      If ! _lSchedule .And. _lExibeMsg
    	   U_ITMsg("Este Cliente esta marcado para não ser atualizado Via CISP.","Atenção",,1)
      Else 
         U_ITConout("[AMOS138] - Este Cliente esta marcado para não ser atualizado Via CISP.")
      EndIf
	   
      _lRet :=  .F.
	   
      Break
   EndIf
   
   //=====================================
   If _lSchedule 
      _cUsuario := "SCHEDULLER"
   Else 
      _cUsuario := __cUserId + "-" + UsrFullName(__cUserId)
   EndIf 

   If ! _lSchedule .And. _lExibeMsg
      ProcRegua(0)
   EndIf 

   //=============================================================================
   // Define se os links a serem utilizados serão de Produção ou de Homologação.
   //=============================================================================
   If _lLinkPrd
      _cUrlCisp  := _cLinkCspP + SubStr(AllTrim(SA1->A1_CGC),1,8)
      _cUrlRecF  := _cLinkRecP + AllTrim(SA1->A1_CGC) + _cToknRecP
      _cUrlSufr  := _cLinkSufP + AllTrim(SA1->A1_CGC) + "/uf/" + AllTrim(SA1->A1_EST) + _cToknSufP
      _cUrlSimp  := _cLinkSimP + AllTrim(SA1->A1_CGC) + _cToknSimP
      _cUrlSint  := _cLinkSnTP + AllTrim(SA1->A1_CGC )+ "/uf/" + AllTrim(SA1->A1_EST) + _cToknSnTP
   Else 
      _cUrlCisp  := _cLinkCspH + SubStr(AllTrim(SA1->A1_CGC),1,8)
      _cUrlRecF  := _cLinkRecH + AllTrim(SA1->A1_CGC) + _cToknRecH
      _cUrlSufr  := _cLinkSufH + AllTrim(SA1->A1_CGC) + "/uf/" + AllTrim(SA1->A1_EST)  + _cToknSufH
      _cUrlSimp  := _cLinkSimH + AllTrim(SA1->A1_CGC) + _cToknSimH
      _cUrlSint  := _cLinkSnTH + AllTrim(SA1->A1_CGC )+ "/uf/" + AllTrim(SA1->A1_EST) + _cToknSnTH
   EndIf 

   //========================================
   // Consultando CISP
   //========================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Consultando / Acessando link da CISP...")
   Else 
      U_ITConout("[AMOS138] - onsultando / Acessando link da CISP...")
   EndIf

   _aHeadOut := {}
   aAdd( _aHeadOut , "Authorization: Basic "+Encode64(_cuser + ":" + _cpasswd ) )

   //Faz chamada ao webservice do Cisp
   _cHdcisp   := ""
   _cRetCisp  := HttpGet(_cUrlCisp,"",NIL,_aHeadOut,@_cHdcisp)

   //======================================================
   // Descriptografia do JSon Recebido
   //======================================================
   _cTextoAux := ""
   If ! Empty(_cRetCisp)
      _cTextoAux := DecodeUTF8(_cRetCisp, "cp1252")   
   EndIf 

   If ! Empty(_cTextoAux)
      _cRetCisp := _cTextoAux
   EndIf 
   
   //======================================================
   // Remover caracteres especiais do JSON.
   //======================================================
   _cRetCisp := U_ITSUBCHR(_cRetCisp, _aStrSubst)

   //======================================================
   // Consultando SINTEGRA
   //======================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Consultando / Acessando link do SINTEGRA...")
   Else 
      U_ITConout("[AMOS138] - Consultando / Acessando link do SINTEGRA...")
   EndIf

   _aHeadOut := {} 
   aAdd( _aHeadOut , "accept:application/json")

   //Faz chamada ao webservice do Sintegra
   _cHdSint  := "" 
   _cRetSint := HttpGet(_cUrlSint,"",NIL,_aHeadOut,@_cHdSint)

   //======================================================
   // Descriptografia do JSon Recebido
   //======================================================
   _cTextoAux := ""
   If ! Empty(_cRetSint)
      _cTextoAux := DecodeUTF8(_cRetSint, "cp1252")   
   EndIf 

   If ! Empty(_cTextoAux)
      _cRetSint := _cTextoAux
   EndIf 
    
   //======================================================
   // Remover caracteres especiais do JSON.
   //======================================================
   _cRetSint := U_ITSUBCHR(_cRetSint, _aStrSubst)

   //======================================================
   // Consultando Cisp-Receita Federal 
   //======================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Consultando / Acessando link do CISP...")
   Else 
      U_ITConout("[AMOS138] - Consultando / Acessando link do CISP...")
   EndIf

   _aHeadOut := {} 
   aAdd( _aHeadOut , "accept:application/json")
   _cHdReceit := ""

   //Faz chamada ao webservce da Receita
   _cRetRece := HttpGet(_cUrlRecF,"",NIL,_aHeadOut,@_cHdReceit)

   //======================================================
   // Descriptografia do JSon Recebido
   //======================================================
   _cTextoAux := ""
   If ! Empty(_cRetRece)
      _cTextoAux := DecodeUTF8(_cRetRece, "cp1252")   
   EndIf

   If ! Empty(_cTextoAux)
      _cRetRece := _cTextoAux   
   EndIf 

   //======================================================
   // Remover caracteres especiais do JSON.
   //======================================================
   _cRetRece := U_ITSUBCHR(_cRetRece, _aStrSubst)

   //======================================================
   // Consultando Cisp-Simples Nacional
   //======================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Consultando / Acessando link do Simples Nacional...")
   Else 
      U_ITConout("[AMOS138] - Consultando / Acessando link do Simples Nacional...")
   EndIf

   _aHeadOut := {} 
   aAdd( _aHeadOut , "accept:application/json")
   _cHdSimple := ""

   //Faz chamada ao webservice do Simples Nacional
   _cHdSimple := ""
   _cRetSimpN := HttpGet(_cUrlSimp,"",NIL,_aHeadOut,@_cHdSimple)

   //======================================================
   // Descriptografia do JSon Recebido
   //======================================================
   _cTextoAux := ""
   If ! Empty(_cRetSimpN)
      _cTextoAux := DecodeUTF8(_cRetSimpN, "cp1252")   
   EndIf 

   If ! Empty(_cTextoAux) 
      _cRetSimpN := _cTextoAux
   EndIf 
   
   //======================================================
   // Remover caracteres especiais do JSON.
   //======================================================
   _cRetSimpN := U_ITSUBCHR(_cRetSimpN, _aStrSubst)

   //======================================================
   // Consultando Cisp-Suframa
   //======================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Consultando / Acessando link do Cisp-Suframa...")
   Else 
      U_ITConout("[AMOS138] - Consultando / Acessando link do Cisp-Suframa...")
   EndIf

   _cHdSufra := ""
   If SA1->A1_EST $ "AM,AC,RO,RR,AP" // Verifica se o estado do Cliente é suframa antes da consulta.

      _aHeadOut := {} 
      aAdd( _aHeadOut , "accept:application/json")
      
      // Faz a chamada ao webservice Suframa
      _cRetSufra := HttpGet(_cUrlSufr,"",NIL,_aHeadOut,@_cHdSufra)

      //======================================================
      // Descriptografia do JSon Recebido
      //======================================================
      _cTextoAux := ""
      If ! Empty(_cRetSufra)
         _cTextoAux := DecodeUTF8(_cRetSufra, "cp1252")      
      EndIf 

      If ! Empty(_cTextoAux)
         _cRetSufra := _cTextoAux 
      EndIf 

      //======================================================
      // Remover caracteres especiais do JSON.
      //======================================================
      _cRetSufra := U_ITSUBCHR(_cRetSufra, _aStrSubst)
      
   EndIf

   //===================================================================
   // Verifica se os retornos do WebService Foram bem sucedidos ou não.
   //===================================================================
   _lRetCisp  := .F. // Retorno Cisp
   If SubStr(_cHdcisp,1,15) == "HTTP/1.1 200 OK"
      _lRetCisp  := .T.
   EndIf 

   _lRetSint  := .F. // Retorno Sintegra
   If SubStr(_cHdSint,1,12) == "HTTP/1.1 200"
      _lRetSint  := .T. 
   EndIf 

   _lRetRec   := .F. // Retorno Receita Federal
   If SubStr(_cHdReceit,1,12) == "HTTP/1.1 200"
      _lRetRec   := .T. 
   EndIf 

   _lRetSufr  := .F. // Retorno Suframa
   If SubStr(_cHdSufra,1,12) == "HTTP/1.1 200"
      _lRetSufr  := .T.
   EndIf 

   _lRetSimpN := .F. // Retorno Simples Nacional 
   If SubStr(_cHdSimple,1,12) == "HTTP/1.1 200"
      _lRetSimpN := .T.
   EndIf  

   //=============================================================
   // Verifica os retornos de erro dos WebServices.
   //=============================================================
   If ! _lRetCisp .And. _lRetSint .And. _lRetRec  // Se as três consultas principais retornar erro, não atualizar cliente.
    
      RecLock("SA1",.F.)
      SA1->A1_I_SCST := "ERRO DE CONSULTA"
  	   SA1->A1_I_D1ST := SToD("20010101")
  	   SA1->A1_I_D2ST := SToD("20010101") //Grava uma data impossível para facilitar localização de registros com problema de consulta
  	   SA1->A1_I_D3ST := Date()
  	   SA1->A1_I_HRST := Time()
      SA1->(MSUnLock())

      If ! _lSchedule .And. _lExibeMsg
    	   U_ITMsg("Erro ao consultar os links CISP / SINTEGRA / RECEITA FEDERAL.","Atenção",,1)
      Else 
         U_ITConout("[AMOS138] - Erro ao consultar os links CISP / SINTEGRA / RECEITA FEDERAL.")
      EndIf

      Break

   EndIf 

   //=================================================================
   // Faz a leitura do JSons e Grava as informações em objetos JSon.
   //=================================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Lendo os dados dos JSons retornados...")
   Else 
      U_ITConout("[AMOS138] - Lendo os dados dos JSons retornados...")
   EndIf
   
   //========================================
   // Lendo JSon Cisp e gerando objeto.
   //========================================
   If _lRetCisp 
      _oJSonCisp := ""
      
      If ! FWJsonDeserialize(_cRetCisp,@_oJSonCisp)
         _lRetCisp := .F.
      EndIf 

   EndIf 

   //======================================================
   // Lendo JSon SINTEGRA e gerando objeto
   //======================================================
   If _lRetSint 

      _oJSonSint := ""

      If ! FWJsonDeserialize(_cRetSint,@_oJSonSint)
         _lRetSint := .F.
      EndIf 

   EndIf 

   //======================================================
   // Lendo JSon Cisp-Receita Federal e gerando objeto
   //======================================================
   If _lRetRec
      _oJSonRece := ""

      If ! FWJsonDeserialize(_cRetRece,@_oJSonRece)
         _lRetRec := .F.
      EndIf 

   EndIf 

   //======================================================
   // Lendo JSon Cisp-Simples Nacional e gerando objeto
   //======================================================
   
   If _lRetSimpN 
      _oJSonSmpN := ""

      If ! FWJsonDeserialize(_cRetSimpN,@_oJSonSmpN)
         _lRetSimpN := .F.
      EndIf 

   EndIf 

   //======================================================
   // Lendo JSon Cisp-Suframa e gerando objeto.
   //======================================================
   If _lRetSufr
      _oJsonSufr := ""     

      If ! FWJsonDeserialize(_cRetSufra,@_oJsonSufr)
         _lRetSufr := .F.
      EndIf 
        
   EndIf 

   //====================================================
   // Atribuindo dados dos JSon Cisp em variáveis.
   //====================================================
   _cNomCisp  := ""
   _cFanCisp  := ""
   _cInscCisp := ""
   _cEndCisp  := ""
   _cBairCisp := ""
   _cUfCisp   := ""
   _cMunCisp  := ""
   _cCMunCisp := ""
   _cCepCisp  := ""
   _cSimNCisp := ""
   _cSufrCisp := ""
   _cSitCCisp := ""
   _cDtCSCisp := ""
   _cDtASCisp := ""
   _cDtARCisp := ""
   _cHrAcCisp := ""
   _cSitRCisp := ""
   _cDtCRCisp := ""
   _cDtATCisp := ""
   _cBlqCisp  := ""
   _cLogrCisp := ""
   _cNumECisp := ""
   _cComECisp := ""
   
   If _lRetCisp    
      If Type("_oJSonCisp:CLIENTE:RAZAOSOCIAL") <> "U"
         _cNomCisp  := _oJSonCisp:CLIENTE:RAZAOSOCIAL
      EndIf

      If Type("_oJSonCisp:CLIENTE:NOMEFANTASIA") <> "U"
         _cFanCisp  := _oJSonCisp:CLIENTE:NOMEFANTASIA
      EndIf

      If Type("_oJSonCisp:CLIENTE:ENDERECO") <> "U"
         _cEndCisp  := _oJSonCisp:CLIENTE:ENDERECO
      EndIf

      If Type("_oJSonCisp:CLIENTE:BAIRRO") <> "U"
         _cBairCisp := _oJSonCisp:CLIENTE:BAIRRO
      EndIf

      If Type("_oJSonCisp:CLIENTE:UF") <> "U"
         _cUfCisp   := _oJSonCisp:CLIENTE:UF
      EndIf

      If Type("_oJSonCisp:CLIENTE:CIDADE") <> "U"
         _cMunCisp  := _oJSonCisp:CLIENTE:CIDADE
         _cMunCisp  := Upper(_cMunCisp)
      EndIf

      If Type("_oJSonCisp:CLIENTE:CEP") <> "U"
         _cCepCisp  := _oJSonCisp:CLIENTE:CEP 
      EndIf

      If Type("_oJSonCisp:CLIENTE:ENDERECO") <> "U"
         _cLogrCisp := _oJSonCisp:CLIENTE:ENDERECO
      EndIf

      If ! Empty(_cUfCisp) .And. ! Empty(_cMunCisp)
         //4=CC2_FILIAL+CC2_EST+CC2_MUN
         _cCMunCisp := Posicione("CC2",4,xFilial("CC2")+_cUfCisp+U_ItKey(_cMunCisp,"CC2_MUN"),"CC2_CODMUN")
      EndIf

      _cDtARCisp := DToC(Date())
      _cHrAcCisp := Time()

   EndIf 

   //======================================================
   // Lendo JSon SINTEGRA e gerando objeto
   //======================================================
   _cNomSint  := ""
   _cFanSint  := ""
   _cInscSint := ""
   _cEndSint  := ""
   _cBairSint := ""
   _cUfSint   := ""
   _cMunSint  := ""
   _cCMunSint := ""
   _cCepSint  := ""
   _cSimNSint := ""
   _cSufrSint := ""
   _cSitCSint := ""
   _cDtCSSint := ""
   _cDtASSint := ""
   _cDtARSint := ""
   _cHrACSint := ""
   _cSitRSint := ""
   _cDtCRSint := ""
   _cDtATSint := ""
   _cBlqSint  := ""
   _cLogrSint := ""
   _cNumESint := ""
   _cComESint := ""

   If _lRetSint 

      If Type("_oJSonSint:COMPANY[1]:REGISTEREDNAME") <> "U"
         _cNomSint  := _oJSonSint:COMPANY[1]:REGISTEREDNAME
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:DOCUMENTS[1]:VALUE") <> "U"
         _cInscSint := _oJSonSint:COMPANY[1]:DOCUMENTS[1]:VALUE
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:LINE1") <> "U"
         _cEndSint  := _oJSonSint:COMPANY[1]:ADDRESS:LINE1 + " " + _oJSonSint:COMPANY[1]:ADDRESS:LINE2 + " " + _oJSonSint:COMPANY[1]:ADDRESS:EXTENSION
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:DISTRICT") <> "U"
         _cBairSint := _oJSonSint:COMPANY[1]:ADDRESS:DISTRICT
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:STATE:CODE") <> "U"
         _cUfSint   := _oJSonSint:COMPANY[1]:ADDRESS:STATE:CODE
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:CITY") <> "U"
         _cMunSint  := Upper(_oJSonSint:COMPANY[1]:ADDRESS:CITY)
      EndIf

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:POSTALCODE") <> "U"
         _cCepSint  := _oJSonSint:COMPANY[1]:ADDRESS:POSTALCODE
      EndIf 
      
      If Type("_oJSonSint:COMPANY[1]:REGISTER:STATUS") <> "U"
         _cSitCSint := Upper(_oJSonSint:COMPANY[1]:REGISTER:STATUS)
      EndIf 

      _cDtCSSint := Date()
   
      If Type("_oJSonSint:UPDATEDATE") <> "U"
         _cDtASSint := _oJSonSint:UPDATEDATE

         If ! Empty(_cDtASSint)
            _cDtASSint := StrTran(_cDtASSint,"-","")
            _cDtASSint := DToC(SToD(_cDtASSint))
         EndIf 
      EndIf 

      If ! Empty(_cUfSint) .And. ! Empty(_cMunSint)
         //4=CC2_FILIAL+CC2_EST+CC2_MUN
         _cCMunSint := Posicione("CC2",4,xFilial("CC2")+_cUfSint+U_ItKey(_cMunSint,"CC2_MUN"),"CC2_CODMUN")
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:LINE1") <> "U"
         _cLogrSint := _oJSonSint:COMPANY[1]:ADDRESS:LINE1 
      EndIf

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:LINE2") <> "U"
         _cNumESint := _oJSonSint:COMPANY[1]:ADDRESS:LINE2 
      EndIf 

      If Type("_oJSonSint:COMPANY[1]:ADDRESS:EXTENSION") <> "U"
         _cComESint := _oJSonSint:COMPANY[1]:ADDRESS:EXTENSION
      EndIf 

   EndIf 

   //======================================================
   // Lendo JSon Cisp-Receita Federal e gerando objeto
   //======================================================
   _cNomRecF  := ""
   _cFanRecF  := ""
   _cInscRecF := ""
   _cEndRecF  := ""
   _cBairRecF := ""
   _cUfRecF   := ""
   _cMunRecF  := ""
   _cCMunRecF := "" 
   _cCepRecF  := ""
   _cSimNRecF := ""
   _cSufrRecF := ""
   _cSitCRecF := ""
   _cDtCSRecF := ""
   _cDtARSecF := ""
   _cDtARRecF := ""
   _cHrACRecF := ""
   _cSitRRecF := ""
   _cDtCRRecF := ""
   _cDtATRecF := ""
   _cBlqRecF := ""
   _cLogrRecF := ""
   _cNumERecF := ""
   _cComERecF := ""
   
   
   If _lRetRec .And. Type("_oJSonRece") == "U"
      _oJSonRece := ""

      _lRetRec := FWJsonDeserialize(_cRetRece,@_oJSonRece)

   EndIf 

   If _lRetRec

      If Type("_oJSonRece:COMPANY") == "A"
         _oReceita  := _oJSonRece:company[1]
      Else 
         If Type("_oJSonRece:COMPANY") <> "U"
            _oReceita  := _oJSonRece:company
         Else 
            _oReceita  := Nil
         EndIf 
      EndIf    

      If Type("_oReceita:business") <> "U" 
         _oBusiness := _oReceita:business
      Else 
         _oBusiness := Nil
      EndIf 
     
      _cCNAECisp   := ""
      _cCodNegoc   := ""
      _cDesecNegoc := ""

      If ValType(_oBusiness) == "O"
         If ValType(_oBusiness:industries) == "A"
            _oIndustri := _oBusiness:industries
         Else
            _oIndustri := {_oBusiness:industries}
         EndIf
      Else
         _oIndustri := {}
      EndIf 

      For _nI := 1 To Len(_oIndustri)
         _aIndAtiva := _oIndustri[_nI]
   	   _lIndAtiva := _oIndustri[_nI]:main
   	   
         If _lIndAtiva 
   	      _cCodNegoc   := _oIndustri[_nI]:code
            _cDesecNegoc := _oIndustri[_nI]:description
         EndIf 
      Next
      
      _cCodNegoc := SubStr(_cCodNegoc,1,2) + SubStr(_cCodNegoc,4,4) + "/" + SubStr(_cCodNegoc,9,2)
      _cCNAECisp := AllTrim(_cCodNegoc) 

      If Type("_oJSonRece:COMPANY[1]:REGISTEREDNAME") <> "U"
         _cNomRecF  := _oJSonRece:COMPANY[1]:REGISTEREDNAME
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:LINE1") <> "U"
         _cEndRecF  := _oJSonRece:COMPANY[1]:ADDRESS:LINE1 + " " +_oJSonRece:COMPANY[1]:ADDRESS:LINE2 + " " + _oJSonRece:COMPANY[1]:ADDRESS:EXTENSION
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:DISTRICT") <> "U"
         _cBairRecF := _oJSonRece:COMPANY[1]:ADDRESS:DISTRICT
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:STATE:CODE") <> "U"
         _cUfRecF   := _oJSonRece:COMPANY[1]:ADDRESS:STATE:CODE
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:CITY") <> "U"
         _cMunRecF  := Upper(_oJSonRece:COMPANY[1]:ADDRESS:CITY)
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:POSTALCODE") <> "U"
         _cCepRecF := _oJSonRece:COMPANY[1]:ADDRESS:POSTALCODE
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:REGISTER:STATUS") <> "U"
         _cSitCRecF := Upper(_oJSonRece:COMPANY[1]:REGISTER:STATUS)
      EndIf 
    
      If Type("_oJSonRece:UPDATEDATE") <> "U"
         _cDtARRecF := _oJSonRece:UPDATEDATE

         If ! Empty(_cDtARRecF)
            _cDtARRecF := StrTran(_cDtARRecF,"-","")
            _cDtARRecF := DToC(SToD(_cDtARRecF))
         EndIf 
      EndIf 

      If ! Empty(_cUfRecF) .And. ! Empty(_cMunRecF)
         //4=CC2_FILIAL+CC2_EST+CC2_MUN
         _cCMunRecF:= Posicione("CC2",4,xFilial("CC2")+_cUfRecF+U_ItKey(_cMunRecF,"CC2_MUN"),"CC2_CODMUN")
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:LINE1") <> "U"
         _cLogrRecF := _oJSonRece:COMPANY[1]:ADDRESS:LINE1
      EndIf

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:LINE2") <> "U"
         _cNumERecF := _oJSonRece:COMPANY[1]:ADDRESS:LINE2 
      EndIf 

      If Type("_oJSonRece:COMPANY[1]:ADDRESS:EXTENSION") <> "U"
         _cComERecF := _oJSonRece:COMPANY[1]:ADDRESS:EXTENSION
      EndIf 
   
       _cDtCRRecF := Date() 

   EndIf 

   //======================================================
   // Lendo JSon Cisp-Simples Nacional e gerando objeto
   //======================================================
   _cNomSimN  := ""
   _cFanSimN  := ""
   _cInscSimN := ""
   _cEndSimN  := ""
   _cBairSimN := ""
   _cUfSimN   := ""
   _cMunSimN  := ""
   _cCMunSimN := ""
   _cCepSimN  := ""
   _cSimNSimN := ""
   _cSufrSimN := ""
   _cSitCSimN := ""
   _cDtCSSimN := ""
   _cDtASSimN := ""
   _cDtARSimN := ""
   _cHrACSimN := ""
   _cSitRSimN := ""
   _cDtCRSimN := ""
   _cDtATSimN := ""
   _cBlqSimN  := ""
   _cLogrSimN := ""
   _cNumESimN := ""
   _cComESimN := ""

   If _lRetSimpN 
      If Type("_oJSonSmpN:COMPANY[1]:REGISTEREDNAME") <> "U"
         _cNomSimN  := _oJSonSmpN:COMPANY[1]:REGISTEREDNAME
      EndIf 
      
      If Type("_oJSonSmpN:COMPANY[1]:BUSINESS:TAXSYSTEM:STATUSSIMPLESNACIONAL") <> "U"
         _cSimNSimN := _oJSonSmpN:COMPANY[1]:BUSINESS:TAXSYSTEM:STATUSSIMPLESNACIONAL // "NÃƒO optante pelo Simples Nacional"

         If ! Empty(_cSimNSimN)
            _cSimNSimN := U_ITSUBCHR(_cSimNSimN, {{"Ãƒ","A"}})
            _cSimNSimN := Upper(_cSimNSimN)

            If "NAO" $ _cSimNSimN
               _cSimNSimN := "NAO"
            Else
               _cSimNSimN := "SIM"
            EndIf 
         EndIf 
      EndIf 

   EndIf 

   //======================================================
   // Lendo JSon Cisp-Suframa e gerando objeto.
   //======================================================
   _cNomSufr := ""
   _cFanSufr := ""
   _cInscSufr := ""
   _cEndSufr := ""
   _cBairSufr := ""
   _cUfSufr := ""
   _cMunSufr := ""
   _cCMunSufr := ""
   _cCepSufr := ""
   _cSimNSufr := ""
   _cSufrSufr := ""
   _cSitCSufr := ""
   _cDtCSSufr := ""
   _cDtASSufr := ""
   _cDtARSufr := ""
   _cHrACSufr := ""
   _cSitRSufr := ""
   _cDtCRSufr := ""
   _cDtATSufr := ""
   _cBlqSufr  := ""
   _cLogrSufr := ""
   _cNumESufr := ""
   _cComESufr := ""

   If _lRetSufr
      If Type("_oJsonSufr:COMPANY[1]:REGISTEREDNAME") <> "U"
         _cNomSufr  := _oJsonSufr:COMPANY[1]:REGISTEREDNAME
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:ADDRESS:LINE1") <> "U"
        _cEndSufr  := _oJsonSufr:COMPANY[1]:ADDRESS:LINE1 + " " + _oJsonSufr:COMPANY[1]:ADDRESS:LINE2 + " " + _oJsonSufr:COMPANY[1]:ADDRESS:EXTENSION
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:ADDRESS:DISTRICT") <> "U"
        _cBairSufr := _oJsonSufr:COMPANY[1]:ADDRESS:DISTRICT
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:ADDRESS:STATE:CODE") <> "U"
        _cUfSufr   := _oJsonSufr:COMPANY[1]:ADDRESS:STATE:CODE
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:ADDRESS:CITY") <> "U"
        _cMunSufr  := Upper(_oJsonSufr:COMPANY[1]:ADDRESS:CITY)
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:ADDRESS:POSTALCODE") <> "U"
        _cCepSufr  := _oJsonSufr:COMPANY[1]:ADDRESS:POSTALCODE
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:DOCUMENTS[1]:VALUE") <> "U"
        _cSufrSufr := _oJsonSufr:COMPANY[1]:DOCUMENTS[1]:VALUE 
      EndIf 

      If Type("_oJsonSufr:COMPANY[1]:REGISTER:STATUS") <> "U"
        _cSitCSufr := _oJsonSufr:COMPANY[1]:REGISTER:STATUS
      EndIf

      If ! Empty(_cUfSufr) .And. ! Empty(_cMunSufr)
        _cCMunSufr := Posicione("CC2",4,xFilial("CC2")+ _cUfSufr + U_ItKey(_cMunSufr,"CC2_MUN"),"CC2_CODMUN")
      EndIf

   EndIf 

   If !(_cSitCSint== "HABILITADO"          .Or. _cSitCSint == "HABILITADA"          .Or. _cSitCSint == "ATIVO"            .Or. _cSitCSint== "ATIVA" .Or. Empty(AllTrim(_cSitCSint)) .Or. ;
        _cSitCSint == "ATIVO - HABILITADO" .Or. _cSitCSint == "HABILITADO - ATIVO") .Or. !(AllTrim(_cSitCRecF) == "ATIVA" .Or. AllTrim(_cSitCRecF) == "ATIVO" .Or. Empty(AllTrim(_cSitCRecf)))
  	   _cBlqSint := "SIM"	
      _cBlqRecF := "SIM"
   ElseIf AllTrim(_cSitCCisp) == "ERRO DE CONSULTA" .And. (dDatabase-30) >= SToD(SA1->A1_ULTCOM)
  	   _cBlqSint := "SIM"	
      _cBlqRecF := "SIM"
   Else 
      _cBlqSint := "NAO"	
      _cBlqRecF := "NAO"
   EndIf

   _aDados := {}

   aAdd(_aDados,{"A1_NOME"   ,"Razão Social"               , _cNomCisp  , _cNomSint  ,	_cNomRecF  ,_cNomSimN  , _cNomSufr})
   aAdd(_aDados,{"A1_NREDUZ" ,"Nome Fantasia"              , _cFanCisp  , _cFanSint  ,	_cFanRecF  ,_cFanSimN  , _cFanSufr})
   aAdd(_aDados,{"A1_INSCR"  ,"Inscrição Estadual"         , _cInscCisp , _cInscSint ,	_cInscRecF ,_cInscSimN , _cInscSufr})
   aAdd(_aDados,{"A1_END"    ,"Endereço"                   , _cEndCisp  , _cEndSint  ,	_cEndRecF  ,_cEndSimN  , _cEndSufr})
   aAdd(_aDados,{"A1_BAIRRO" ,"Bairro"                     , _cBairCisp , _cBairSint ,	_cBairRecF ,_cBairSimN , _cBairSufr})
   aAdd(_aDados,{"A1_EST"    ,"Estado"                     , _cUfCisp   , _cUfSint   ,	_cUfRecF	  , _cUfSimN  , _cUfSufr})
   aAdd(_aDados,{"A1_MUN"    ,"Municipio"                  , _cMunCisp  , _cMunSint  ,	_cMunRecF  ,_cMunSimN  , _cMunSufr})
   aAdd(_aDados,{"A1_COD_MUN","Código Município"           , _cCMunCisp , _cCMunSint ,	_cCMunRecF ,_cCMunSimN , _cCMunSufr})
   aAdd(_aDados,{"A1_CEP"    ,"Cep"                        , _cCepCisp  , _cCepSint  , _cCepRecF  ,_cCepSimN  , _cCepSufr })
   aAdd(_aDados,{"A1_SIMPNAC","Simples Nacional"           , _cSimNCisp , _cSimNSint ,	_cSimNRecF ,_cSimNSimN , _cSimNSufr})
   aAdd(_aDados,{"A1_SUFRAMA","Suframa"                    , _cSufrCisp , _cSufrSint ,	_cSufrRecF ,_cSufrSimN , _cSufrSufr})
   aAdd(_aDados,{"A1_I_SCST" ,"Sit Cadastral Sintegra"     , ""         , _cSitCSint ,	""         ,""         , ""        })
   aAdd(_aDados,{"A1_I_D1ST" ,"Data Consulta Sintegra"     , ""         , _cDtCSSint ,	"" /*_cDtCSRecF*/ ,_cDtCSSimN , _cDtCSSufr})
   aAdd(_aDados,{"A1_I_D2ST" ,"Data Atualizacao Sintegra"  , ""         , _cDtASSint ,	/*_cDtARSecF*/"" ,_cDtASSimN , _cDtASSufr})
   aAdd(_aDados,{"A1_I_D3ST" ,"Data Atualizacao Reg Cisp"  , _cDtARCisp , _cDtARSint ,	/*_cDtARRecF*/ "" ,_cDtARSimN , _cDtARSufr})
   aAdd(_aDados,{"A1_I_HRST" ,"Hora Atualizacao Cisp"      , _cHrAcCisp , _cHrACSint ,	_cHrACRecF ,_cHrACSimN , _cHrACSufr})
   aAdd(_aDados,{"A1_I_SCRC" ,"Sit Cadastral Receita Fed"  , ""         , _cSitRSint ,	_cSitCRecF ,_cSitRSimN , _cSitRSufr})
   aAdd(_aDados,{"A1_I_D1RC" ,"Data Consulta Receita Fed"  , ""         , _cDtCRSint ,	_cDtCRRecF ,_cDtCRSimN , _cDtCRSufr})
   aAdd(_aDados,{"A1_I_D2RC" ,"Data Atualizacao Receita"   , ""         , _cDtATSint ,	_cDtARRecF ,_cDtATSimN , _cDtATSufr})
   aAdd(_aDados,{"A1_MSBLQL" ,"Bloqueado"                  , _cBlqCisp  , _cBlqSint  ,	_cBlqRecF  ,_cBlqSimN  , _cBlqSufr})
   aAdd(_aDados,{"A1_I_LOGRA","Logradouro  / Endereço"     , _cLogrCisp , _cLogrSint ,	_cLogrRecF ,_cLogrSimN , _cLogrSufr})
   aAdd(_aDados,{"A1_I_NUMER","Numero do Endereço"         , _cNumECisp , _cNumESint ,	_cNumERecF ,_cNumESimN , _cNumESufr})
   aAdd(_aDados,{"A1_I_COMPL","Complemento do Endereço Sin", _cComECisp , _cComESint ,	_cComERecF ,_cComESimN , _cComESufr})
   aAdd(_aDados,{"A1_CNAE"   ,"CNAE"                       , _cCNAECisp , ""         ,	""         ,""         , ""        })

   _aCabec := {"Campos","Descrição","CISP","SINTEGRA","RECEITA FEDERAL","SIMPLES NACIONAL","SUFRAMA"}

   If ! _lSchedule .And. _lExibeMsg
      If ! U_ItlistBox("Dados Cisp para Atualização",_aCabec,_aDados,.T.,1)
         U_ITMsg("Atualização de cliente cancelada pelo usuário.","Atenção",,1)
         Break 
      EndIf 
   EndIf  

   //===========================================================================
   // Grava array com dados das atualizações antes/depois para envio de e-mail.
   //===========================================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Atualizando cadastro de clientes com a CISP...")
   Else 
      U_ITConout("[AMOS138] - Atualizando cadastro de clientes com os dados da CISP...")
   EndIf

   _cObserv := "Dados não atualizados."

   _nPosIni := Len(_aDadosRel) + 1
   _nPodFin := Len(_aDados) + _nPosIni
   //_aDadosRel
   For _nI := 1 To Len(_aDados)
       aAdd(_aDadosRel,{SA1->A1_COD,;                        //  1 - Codigo Cliente 
                        SA1->A1_LOJA,;                       //  2 - Loja Cliente
                        SA1->A1_CGC,;                        //  3 - CNPJ Cliente
                        _aDados[_nI,1],;                     //  4 - Campo Atualizado
                        _aDados[_nI,2],;                     //  5 - Descrição Campo Atualizado
                        &("SA1->"+_aDados[_nI,1]),;          //  6 - Informação Antes Atualização
                        _aDados[_nI,3],;                     //  7 - Dados Cisp
                        _aDados[_nI,4],;                     //  8 - Dados Cisp-Sintegra
                        _aDados[_nI,5],;                     //  9 - Dados Cisp-Receita Federal
                        _aDados[_nI,6],;                     // 10 - Dados Cisp-Simples Nacional
                        _aDados[_nI,7],;                     // 11 - Dados Cisp-Suframa
                        _cUsuario,;                          // 12 - Usuário responsável pela atualização
                        "" })                                // 13 - Observação
   Next 
   
   //===================================================================
   // Atualiza cadastro de clientes.
   //===================================================================
   // Só atualiza se existir o parâmetro ativando gravação do SA1
   //===================================================================
  	If U_ITGETMV("ITGRVCLI",.F.)
  	   
  	  	SA1->(RecLock("SA1",.F.))
      If ! Empty(_cNomCisp) .Or. ! Empty(_cNomRecF)
         SA1->A1_NOME := If(!Empty(_cNomRecF), _cNomRecF, _cNomCisp) // _aDados[1,3]  // Razão Social"               , _cNomCisp  , _cNomSint  ,	_cNomRecF  ,_cNomSimN  , _cNomSufr})
      EndIf 

      If ! Empty(_cCNAECisp)
         SA1->A1_CNAE := _cCNAECisp 
      EndIf 

      //If ! Empty(_cFanCisp)
      //   SA1->A1_NREDUZ := _cFanCisp    // _aDados[2,3]  // Nome Fantasia"              , _cFanCisp  , _cFanSint  ,	_cFanRecF  ,_cFanSimN  , _cFanSufr})
      //EndIf 

      If ! Empty(_cInscSint)
         SA1->A1_INSCR := U_AOMS138N(_cInscSint,IIf(Empty(_cUfSint),_cUfRecF,_cUfSint))     // Inscrição Estadual"         , _cInscCisp , _cInscSint ,	_cInscRecF ,_cInscSimN , _cInscSufr})
      EndIf 

      If ! Empty(_cEndSint)
         SA1->A1_END := _cEndSint      // Endereço"                   , _cEndCisp  , _cEndSint  ,	_cEndRecF  ,_cEndSimN  , _cEndSufr})
      ElseIf ! Empty(_cEndRecF)
         SA1->A1_END := _cEndRecF
      EndIf 

      If ! Empty(_cBairSint)
         SA1->A1_BAIRRO := _cBairSint  // Bairro"                     , _cBairCisp , _cBairSint ,	_cBairRecF ,_cBairSimN , _cBairSufr})
      ElseIf ! Empty(_cBairRecF)
         SA1->A1_BAIRRO := _cBairRecF
      EndIf 

      If ! Empty(_cUfSint)
         SA1->A1_EST := _cUfSint      // Estado"                     , _cUfCisp   , _cUfSint   ,	_cUfRecF	  , _cUfSimN  , _cUfSufr})
      ElseIf ! Empty(_cUfRecF)
         SA1->A1_EST := _cUfRecF
      EndIf 

      If ! Empty(_cMunSint)
         SA1->A1_MUN  := _cMunSint    // Municipio"                  , _cMunCisp  , _cMunSint  ,	_cMunRecF  ,_cMunSimN  , _cMunSufr})
      ElseIf ! Empty(_cMunRecF)
         SA1->A1_MUN := _cMunRecF 
      EndIf 

      If ! Empty(_cCMunSint)
         SA1->A1_COD_MUN := _cCMunSint // Código Município"           , _cCMunCisp , _cCMunSint ,	_cCMunRecF ,_cCMunSimN , _cCMunSufr})
      ElseIf ! Empty(_cCMunRecF)
         SA1->A1_COD_MUN := _cCMunRecF
      EndIf 

      If ! Empty(_cCepSint)
         SA1->A1_CEP := _cCepSint      // Cep"                        , _cCepCisp  , _cCepSint  , _cCepRecF  ,_cCepSimN  , _cCepSufr })
      ElseIf ! Empty(_cCepRecF)
         SA1->A1_CEP := _cCepRecF 
      EndIf 

      If ! Empty(_cSimNSimN)
         SA1->A1_SIMPNAC := If(AllTrim(_cSimNSimN) == "NAO", "2", "1") // Simples Nacional"           , _cSimNCisp , _cSimNSint ,	_cSimNRecF ,_cSimNSimN , _cSimNSufr})

         If ! Empty(_cUfSint) .And. AllTrim(_cUfSint) $ _cUfMVA
            If AllTrim(_cSimNSimN) <> "NAO" 
               SA1->A1_GRPTRIB := _cTRIBMVA // "023" // Solicitação Chamado: 44096 = Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
            Else 
               If AllTrim(SA1->A1_GRPTRIB) == AllTrim(_cTRIBMVA)
                  SA1->A1_GRPTRIB := " "
               EndIf 
            EndIf 
         ElseIf ! Empty(_cUfRecF) .And. AllTrim(_cUfRecF) $ _cUfMVA
            If AllTrim(_cSimNSimN) <> "NAO"
               SA1->A1_GRPTRIB := _cTRIBMVA // "023" // Solicitação Chamado: 44096 = Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
            Else 
               If AllTrim(SA1->A1_GRPTRIB) == AllTrim(_cTRIBMVA)
                  SA1->A1_GRPTRIB := " "
               EndIf 
            EndIf 
         EndIf
      EndIf 

      If ! Empty(_cSufrSufr)
         SA1->A1_SUFRAMA := _cSufrSufr // Suframa"                    , _cSufrCisp , _cSufrSint ,	_cSufrRecF ,_cSufrSimN , _cSufrSufr})
      EndIf 
      
      If ! Empty(_cSitCSint)
         SA1->A1_I_SCST := _cSitCSint   // Sit Cadastral Sintegra"     , ""         , _cSitCSint ,	""         ,""         , ""        })
      EndIf 

      If ! Empty(_cDtCSSint)
         SA1->A1_I_D1ST := _cDtCSSint  // Data Consulta Sintegra"     , ""         , _cDtCSSint ,	"" /*_cDtCSRecF*/ ,_cDtCSSimN , _cDtCSSufr})
      EndIf 
      
      If ! Empty(_cDtASSint)
         SA1->A1_I_D2ST := Ctod(_cDtASSint)  // Data Atualizacao Sintegra"  , ""         , _cDtASSint ,	/*_cDtARSecF*/"" ,_cDtASSimN , _cDtASSufr})
      EndIf 

      If ! Empty(_cDtARCisp)
         SA1->A1_I_D3ST := Ctod(_cDtARCisp)   // Data Atualizacao Reg Cisp"  , _cDtARCisp , _cDtARSint ,	/*_cDtARRecF*/ "" ,_cDtARSimN , _cDtARSufr})
      EndIf 
      
      If ! Empty(_cHrAcCisp)
         SA1->A1_I_HRST := _cHrAcCisp   // Hora Atualizacao Cisp"      , _cHrAcCisp , _cHrACSint ,	_cHrACRecF ,_cHrACSimN , _cHrACSufr})
      EndIf 

      If ! Empty(_cSitCRecF)
         SA1->A1_I_SCRC := _cSitCRecF   // Sit Cadastral Receita Fed"  , ""         , _cSitRSint ,	_cSitCRecF ,_cSitRSimN , _cSitRSufr})
      EndIf 

      If ! Empty(_cDtCRRecF)
         SA1->A1_I_D1RC := If(ValType(_cDtCRRecF) <> "D",Ctod(_cDtCRRecF),_cDtCRRecF) // _cDtCRRecF  // Data Consulta Receita Fed"  , ""         , _cDtCRSint ,	_cDtCRRecF ,_cDtCRSimN , _cDtCRSufr})
      EndIf 

      If ! Empty(_cDtARRecF)
         SA1->A1_I_D2RC := Ctod(_cDtARRecF)  // Data Atualizacao Receita"   , ""         , _cDtATSint ,	_cDtARRecF ,_cDtATSimN , _cDtATSufr})
      EndIf 

      If ! Empty(_cBlqSint)
         SA1->A1_MSBLQL := If(AllTrim(_cBlqSint) == "NAO","2","1")  // Bloqueado"                  , _cBlqCisp  , _cBlqSint  ,	_cBlqRecF  ,_cBlqSimN  , _cBlqSufr})
      EndIf 
      
      If SA1->A1_I_ATCIS != "N" .And. U_ITGETMV("ITGRVCLI",.F.)
         If ! Empty(_cLogrSint)
            SA1->A1_I_LOGRA := _cLogrSint // Logradouro  / Endereço"     , _cLogrCisp , _cLogrSint ,	_cLogrRecF ,_cLogrSimN , _cLogrSufr})
         ElseIf ! Empty(_cLogrRecF)
            SA1->A1_I_LOGRA := _cLogrRecF
         EndIf 
         
         If ! Empty(_cNumESint)
            SA1->A1_I_NUMER := _cNumESint  // Numero do Endereço"         , _cNumECisp , _cNumESint ,	_cNumERecF ,_cNumESimN , _cNumESufr})
         ElseIf ! Empty(_cNumERecF)
            SA1->A1_I_NUMER := _cNumERecF
         EndIf 

         If ! Empty(_cComESint)
            SA1->A1_I_COMPL := _cComESint  // Complemento do Endereço Sin", _cComECisp , _cComESint ,	_cComERecF ,_cComESimN , _cComESufr})
         ElseIf ! Empty(_cComERecF)
            SA1->A1_I_COMPL := _cComERecF
         EndIf 
      EndIf 

      SA1->(MSUnLock())
      _cObserv := "Cadastro de Clientes atualizados com os dados da CISP."

   Else 
      _cObserv := "Cadastro não atualizado, parâmetro ITGRVCLI desabilitado."
   EndIf 
      
   //=====================================================
   // Grava log de Consulta e Atualização
   //=====================================================
   ZGF->(RecLock("ZGF",.T.))
  	ZGF->ZGF_CODCLI := SA1->A1_COD
  	ZGF->ZGF_LOJA := SA1->A1_LOJA
  	ZGF->ZGF_NOMEA := SA1->A1_NOME
  	ZGF->ZGF_NOMEN := _cNomCisp  

  	ZGF->ZGF_INSCA := SA1->A1_INSCR 
  	ZGF->ZGF_INSCN := _cInscSint  

  	ZGF->ZGF_ENDA := SA1->A1_END
  	ZGF->ZGF_ENDN := _cEndSint
  	ZGF->ZGF_SIMPA := SA1->A1_SIMPNAC
  	ZGF->ZGF_SIMPN := If(AllTrim(_cSimNSimN) == "NAO", "2", "1") 
  	ZGF->ZGF_BAIRA := SA1->A1_BAIRRO
  	ZGF->ZGF_BAIRN := _cBairSint
  	ZGF->ZGF_MUNA := SA1->A1_MUN
  	ZGF->ZGF_MUNN := _cMunSint
  	ZGF->ZGF_CMUNA := SA1->A1_COD_MUN
  	ZGF->ZGF_CMUNN := _cCMunSint
  	ZGF->ZGF_ESTA := SA1->A1_EST
  	ZGF->ZGF_ESTN := _cUfSint
   ZGF->ZGF_CEPA := SA1->A1_CEP   
  	ZGF->ZGF_CEPN := _cCepSint 
  	ZGF->ZGF_SCSTA := SA1->A1_I_SCST
  	ZGF->ZGF_SCSTN := _cSitCSint
  	ZGF->ZGF_D1STA := SA1->A1_I_D1ST
  	ZGF->ZGF_D1STN := Date()
  	ZGF->ZGF_D2STA := SA1->A1_I_D2ST
  	ZGF->ZGF_D2STN := CTod(_cDtASSint) 
  	ZGF->ZGF_D3STA := SA1->A1_I_D3ST
  	ZGF->ZGF_D3STN := Date()
   ZGF->ZGF_MSBLA := SA1->A1_MSBLQL
   ZGF->ZGF_MSBLN := If(AllTrim(_cBlqSint) == "NAO","2","1")
   ZGF->ZGF_HRSTA := SA1->A1_I_HRST
   ZGF->ZGF_HRSTN := Time()
   ZGF->ZGF_RCSTA := SA1->A1_I_SCRC
   ZGF->ZGF_RCSTN := _cSitCRecF 
   ZGF->ZGF_D1RCA := SA1->A1_I_D1RC
   ZGF->ZGF_D1RCN := If(ValType(_cDtCRRecF) <> "D",Ctod(_cDtCRRecF),_cDtCRRecF)
   ZGF->ZGF_D2RCA := SA1->A1_I_D2RC
   ZGF->ZGF_D2RCN := Ctod(_cDtARRecF)
   ZGF->ZGF_USER  := _cUsuario
   ZGF->ZGF_OBS   := _cObserv
   ZGF->ZGF_SUFRA := SA1->A1_SUFRAMA
   ZGF->ZGF_SUFRN := _cSufrSufr
   ZGF->(MSUnLock())
    
   For _nI := _nPosIni To (_nPodFin - 1)  // Atualiza observações
       _aDadosRel[_nI,13] := Upper(_cObserv)
   Next 
   
   If _lEnvMail
      If ! _lSchedule .And. _lExibeMsg
         IncProc("Enviando e-mail com as atualizações...")
      Else 
         U_ITConout("[AMOS138] - Enviando e-mail com as atualizações...")
      EndIf

      U_AOMS138E(_aDadosRel) // ENVIO DE E-MAIL.
   EndIf 

   //===================================================================================
   // Grava os dados dos clientes nas tabelas de muro para integração com o sistema RDC.
   //===================================================================================
   If ! _lSchedule .And. _lExibeMsg
      IncProc("Grava as tabelas de muro para envio de dados para o RDC...")
   Else 
      U_ITConout("[AMOS138] - Grava as tabelas de muro para envio de dados para o RDC...")
   EndIf
   U_AOMS076G()

End Sequence 

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS138E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/07/2023
Descrição---------: Rotina para enviar e-mail de notificação de atualização de cadastro de cliente
Parametros--------: _aDadosEnv = Dados a serem enviados no e-mail
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS138E(_aDadosEnv)

Local _aConfig	:= U_ITCFGEML('')
Local _cMsgEml	:= ''
Local _cEmail	:= U_ITGETMV( 'IT_CISPCLI' , 'sistema@italac.com.br' )
Local _cData	:= DToC(DATE())
Local _cHoraT   := Time()
Local _cAssunto := 'Workflow - Atualização de cadastro de cliente com os dados da CISP - ' + AllTrim(SA1->A1_COD) + "/" + AllTrim(SA1->A1_LOJA) + " - " + AllTrim(SA1->A1_NOME)
Local _cNomeArq,_cDirExcel ,_cTitulo, _aCabec
Local _cAnexo

Begin Sequence 
   _cNomeArq  := "Workflow_Atualizacao_Clientes_com_dados_CISP_" + DToS(Date()) + "-" + StrTran(TIME(),":","" )+".xml" 
   _cDirExcel := "\SPOOL\"
   _cTitulo   := 'Workflow - Atualização de cadastro de cliente com os dados da CISP ' 
   _aCabec    := {}
   aAdd(_aCabec,{"Codigo Cliente"                 ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Loja Client"                    ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"CNPJ Cliente"                   ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Campo Atualizado"               ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Descrição Campo Atualizado"     ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Informação Antes Atualização"   ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Dados Cisp"                     ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Dados Cisp-Sintegra"            ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Dados Cisp-Receita Federal"     ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Dados Cisp-Simples Nacional"    ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Dados Cisp-Suframa"             ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Usuário responsável"            ,1           ,1         ,.F.})   
   aAdd(_aCabec,{"Observação"                     ,1           ,1         ,.F.})   
   U_ITGEREXCEL(_cNomeArq,_cDirExcel ,_cTitulo,"Workflow_Atualização_Cliente_CISP",_aCabec    ,_aDadosEnv  ,.F.        ,          ,        ,.T.         ,            ,          ,   .T. ) 

   Sleep(2000)

   _cAnexo := _cDirExcel + _cNomeArq

   _cMsgEml := '<html>'
   _cMsgEml += '<head><title></title>Log de Processamento</head>'
   _cMsgEml += '<body>'
   _cMsgEml += '<style Type="text/css"><!--'
   _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
   _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
   _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
   _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
   _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
   _cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
   _cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
   _cMsgEml += '--></style>'
   _cMsgEml += '<center>'
   _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
   _cMsgEml += '<table class="bordasimples" width="700">'
   _cMsgEml += '    <tr>'
   //_cMsgEml += '	<td class="titulos"><center>Atualização dados Manual no cadasto de clientes - ' + AllTrim(SA1->A1_COD) + "/" + AllTrim(SA1->A1_LOJA) + " - " + AllTrim(SA1->A1_NOME) + "</center></td>'
   _cMsgEml += '	<td class="titulos"><center>Atualização do cadasto de clientes com os dados da CISP.</center></td>'
   _cMsgEml += '	</tr>'
   _cMsgEml += '</table>'
   _cMsgEml += '<br>'
   _cMsgEml += '<table class="bordasimples" width="700">'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td align="center" colspan="2" class="grupos">Log Processamento</b></td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" width="20%"><b>Data:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" >'+ _cData +'</td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" width="20%"><b>Hora:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" >'+ _cHoraT +'</td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '	<tr>'
   _cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '</table>'

   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center">     </td>'
   _cMsgEml += '      <td class="itens" align="left" >      </td>'
   _cMsgEml += '    </tr>'

   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > ['+ GetEnvServer() +'] </td>'
   _cMsgEml += '    </tr>'

   _cMsgEml += '</body>'
   _cMsgEml += '</html>'

    _cEmlLog := ''
    //    ITEnvMail(cFrom     ,cEmailTo ,cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
    U_ITENVMAIL( _aConfig[01] , _cEmail ,        ,         ,_cAssunto, _cMsgEml ,_cAnexo ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

End Sequence 

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS138G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/07/2023
Descrição---------: Atualização geral de clientes
Parametros--------: _lSchedule = .T. / .F. = Indica se a rotina foi chamada via Scheduller ou via Menu. 
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS138G(_lSchedule)

// Links Produção
Local _cLinkMnST  := U_ItGetMv("IT_LNKMSIP", "https://servicos.cisp.com.br/v1/monitoramento-sintegra/atual")
Local _cLinkSimP  := U_ItGetMv("IT_LNKSINP", "https://api.maxxi.cisp.com.br/public-bases/v1/simples-nacional/cnpj/")
Local _cLinkSufP  := U_ItGetMv("IT_LNKSUFP", "https://api.maxxi.cisp.com.br/public-bases/v1/suframa/cnpj/")
Local _cLinkRecP  := U_ItGetMv("IT_LNKRECP", "https://api.maxxi.cisp.com.br/public-bases/v1/receita-federal/cnpj/")

// Links Homologação
Local _cLinkSufH  := U_ItGetMv("IT_LNKSUFH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/suframa/cnpj/")
Local _cLinkSimH  := U_ItGetMv("IT_LNKSINH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/simples-nacional/cnpj/")
Local _cLinkRecH  := U_ItGetMv("IT_LNKRECH", "https://api-homol.maxxi.cisp.com.br/public-bases/v1/receita-federal/cnpj/")

// Token Produção
Local _cToknSufP  := U_ItGetMv("IT_TKNSUFP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")
Local _cToknSimP  := U_ItGetMv("IT_TKNSINP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")
Local _cToknRecP  := U_ItGetMv("IT_TKNRECP", "?key=dwnljGS5DRJ0BkzGGgRsrNZCUxqdqrZw")

// Token Homologação
Local _cToknSufH  := U_ItGetMv("IT_TKNSUFH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")
Local _cToknSimH  := U_ItGetMv("IT_TKNSINH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")
Local _cToknRecH  := U_ItGetMv("IT_TKNRECH", "?key=43c629ff-e72e-4172-a0fe-ffdef386573a")

// Usuário e Senha Cisp
Local _cPasswd    := u_ItGetMv("IT_PWCISP" ,"!t@lac95_01#")
Local _cUser	   := u_ItGetMv("IT_USCISP" ,"ws09501")

// Indica se utilizará link de produção ou link de homologação
Local _lLinkPrd   := U_ItGetMv("IT_LKCISPP", .T.)

// Declarações comuns.
Local _cUrlSufr  := ""
Local _cUrlSimp  := ""
//Local _lRet      := .F.
Local _lRetSufr  := .F.
Local _lRetSimpN := .F. 
Local _nPosIni 
Local _nPodFin
Local _nI 
Local _cObserv
Local _nTotJSons 
Local _oItemCisp
Local _cClieProc := ""
Local _cFiltCnpj
Local _cUfMVA := U_ITGetMV("IT_UFSMVA","PR")
Local _cTRIBMVA := U_ITGetMV("IT_TRIBMVA","023")
Local _aStrSubst :=  {{"*",""},{"$",""},{""," "},{"Ã","A"},{"?"," "}}
Local _cTextoAux := ""

Local _oBusiness   := Nil
Local _cCNAECisp   := ""
Local _cCodNegoc   := ""
Local _cDesecNegoc := ""

Private _cUsuario
Private _cUFProc := Space(100) // Lista de estados a serem processados na atualização geral 

Default _lSchedule := .F.

Begin Sequence 

   If ! _lSchedule  .And. ! U_AOMS138T()
      U_ITMsg( "Rotina cancelada pelo usuário!" , "Atenção!",,1 )
      Break
   EndIf 

   If ! _lSchedule
      ProcRegua(0)
   EndIf 

   //========================================
   // Consultando CISP-Monitoramento-Sintegra 
   //========================================
   If ! _lSchedule // .And. _lExibeMsg
      IncProc("Consultando / Acessando link da CISP-Monitoramento Sintegra...")
   Else 
      U_ITConout("[AMOS138] - Consultando / Acessando link da CISP-Monitoramento-Sintegra...")
   EndIf

   _aHeadOut := {}
   aAdd( _aHeadOut , "Authorization: Basic "+Encode64(_cuser + ":" + _cpasswd ) )

   //Faz chamada ao webservice do Cisp-Monitoramento-Sintegra
   _cHdcisp   := ""
   _cRetCisp  := HttpGet(_cLinkMnST,"",NIL,_aHeadOut,@_cHdcisp)  

   //======================================================
   // Descriptografia do JSon Recebido
   //======================================================
   _cTextoAux := ""
   If ! Empty(_cRetCisp)
      _cTextoAux := DecodeUTF8(_cRetCisp, "cp1252")     
   EndIf 

   If ! Empty(_cTextoAux)
      _cRetCisp := _cTextoAux
   EndIf 

   //======================================================
   // Remover caracteres especiais do JSON.
   //======================================================
   _cRetCisp := U_ITSUBCHR(_cRetCisp, _aStrSubst)

   //===================================================================
   // Verifica se os retornos do WebService Foram bem sucedidos ou não.
   //===================================================================
   _lRetCisp  := .F. // Retorno Cisp
   If SubStr(_cHdcisp,1,15) == "HTTP/1.1 200 OK"
      _lRetCisp  := .T.
   EndIf 

   //=================================================================
   // Faz a leitura do JSons e Grava as informações em objetos JSon.
   //=================================================================
   If ! _lSchedule //.And. _lExibeMsg
      IncProc("Lendo os dados dos JSons retornados...")
   Else 
      U_ITConout("[AMOS138] - Lendo os dados dos JSons retornados...")
   EndIf
   
   //===========================================================
   // Lendo JSon Cisp-Monitoramento-Sintegra e gerando objeto.
   //===========================================================
   If _lRetCisp 
      _oJSonCisp := ""
      
      If ! FWJsonDeserialize(_cRetCisp,@_oJSonCisp)
         _lRetCisp := .F.
      EndIf 

   EndIf

   //===================================================================================
   // Atualiza Cadastro de Clientes com os Dados dos JSons Cisp-Monitoramento-Sintegra.
   //===================================================================================
   If _lRetCisp 
      
      SA1->(DBSetOrder(3))

      _nTotJSons := Len(_oJSonCisp)

      For _nI := 1 To _nTotJSons
          _oItemCisp := _oJSonCisp[_nI]

          If ! SA1->(MsSeek(xFilial("SA1")+U_ItKey(_oItemCisp:IDENTIFICACAOCLIENTE,"A1_CGC")))
             Loop 
          EndIf 

         //===================================================================
         // Grava os Clientes já Processados para filtro da query.
         //===================================================================
         _cClieProc += SA1->A1_CGC + ";"

          //==========================================
          // Não atualiza cliente bloqueado
          //==========================================
          If SA1->A1_MSBLQL == "1"
             U_ITConout("[AMOS138] - Cliente Bloqueado. Esta rotina não atualiza cliente bloqueado.")
             Loop
          EndIf

          //=========================================
          // Só atualiza pessoas juridicas
          //=========================================
          If !(SA1->A1_PESSOA == "J")
             U_ITConout("[AMOS138] - Cliente pessoa fisica. Esta rotina só atualiza pessoa jurídica.")
             Loop
          EndIf

          //==========================================================
          // Não atualiza clientes marcados como não atualizaveis
          //==========================================================
          If SA1->A1_I_ATCIS == "N"
             U_ITConout("[AMOS138] - Este Cliente esta marcado para não ser atualizado Via CISP.")
             Loop
          EndIf

          //=============================================================================
          // Define se os links a serem utilizados serão de Produção ou de Homologação.
          //=============================================================================
          If _lLinkPrd
             _cUrlSufr  := _cLinkSufP + AllTrim(SA1->A1_CGC) + "/uf/" + AllTrim(SA1->A1_EST) + _cToknSufP
             _cUrlSimp  := _cLinkSimP + AllTrim(SA1->A1_CGC) + _cToknSimP
             _cUrlRecF  := _cLinkRecP + AllTrim(SA1->A1_CGC) + _cToknRecP
          Else 
             _cUrlSufr  := _cLinkSufH + AllTrim(SA1->A1_CGC) + "/uf/" + AllTrim(SA1->A1_EST)  + _cToknSufH
             _cUrlSimp  := _cLinkSimH + AllTrim(SA1->A1_CGC) + _cToknSimH
             _cUrlRecF  := _cLinkRecH + AllTrim(SA1->A1_CGC) + _cToknRecH
          EndIf 

          //=============================================================================
          // Faz a filtragem da atualização por estado, se o usuário informou algum.
          //=============================================================================
          If ! Empty(_cUFProc)
             If !(SA1->A1_EST $ _cUFProc)
                Loop 
             EndIf 
          EndIf 

          //====================================================
          // Atribuindo dados dos JSon Cisp em variáveis.
          //====================================================
          _cNomCisp  := ""
          _cFanCisp  := ""
          _cInscCisp := ""
          _cEndCisp  := ""
          _cBairCisp := ""
          _cUfCisp   := ""
          _cMunCisp  := ""
          _cCMunCisp := ""
          _cCepCisp  := ""
          _cSimNCisp := ""
          _cSufrCisp := ""
          _cSitCCisp := ""
          _cDtCSCisp := ""
          _cDtASCisp := ""
          _cDtARCisp := ""
          _cHrAcCisp := ""
          _cSitRCisp := ""
          _cDtCRCisp := ""
          _cDtATCisp := ""
          _cBlqCisp  := ""
          _cLogrCisp := ""
          _cNumECisp := ""
          _cComECisp := ""
          _cCNAECisp := ""

          If _lRetCisp 
             _cNomCisp  := _oItemCisp:razaoSocial
             _cFanCisp  := _oItemCisp:nomeFantasia
             _cEndCisp  := _oItemCisp:endereco + " " + _oItemCisp:numero + " " + _oItemCisp:complemento
             _cBairCisp := _oItemCisp:bairro
             _cUfCisp   := _oItemCisp:uf
            
             _cMunCisp  := _oItemCisp:cidade
             _cMunCisp  := Upper(_cMunCisp)
            
             _cCepCisp  := StrZero(_oItemCisp:cep,8)
             _cLogrCisp := _oItemCisp:endereco
             _cNumECisp := _oItemCisp:numero
             _cComECisp := _oItemCisp:complemento

            _cInscCisp  := _oItemCisp:inscricaoEstadual
            _cSitCCisp  := _oItemCisp:situacaoCadastral

             //4=CC2_FILIAL+CC2_EST+CC2_MUN
             _cCMunCisp := Posicione("CC2",4,xFilial("CC2")+_cUfCisp+U_ItKey(_cMunCisp,"CC2_MUN"),"CC2_CODMUN")
             _cDtARCisp := DToC(Date())
             _cHrAcCisp := Time()
	
             If !(_cSitCCisp == "HABILITADO" .Or. _cSitCCisp == "HABILITADA"         .Or. _cSitCCisp == "ATIVO" .OR.;
                  _cSitCCisp == "ATIVA"      .Or. _cSitCCisp == "ATIVO - HABILITADO" .Or. _cSitCCisp == "HABILITADO - ATIVO")
  	             _cBlqCisp := "SIM"	
             ElseIf AllTrim(_cSitCCisp) == "ERRO DE CONSULTA" .And. (dDatabase-30) >= SToD(SA1->A1_ULTCOM)
  	             _cBlqCisp := "SIM"	
             Else 
                _cBlqCisp := "NAO"	
             EndIf

            _cHdReceit := ""

            //Faz chamada ao webservce da Receita
            _cRetRece := HttpGet(_cUrlRecF,"",NIL,_aHeadOut,@_cHdReceit)

            //======================================================
            // Descriptografia do JSon Recebido
            //======================================================
            _cTextoAux := ""
            If ! Empty(_cRetRece)
               _cTextoAux := DecodeUTF8(_cRetRece, "cp1252")   
            EndIf

            If ! Empty(_cTextoAux)
               _cRetRece := _cTextoAux   
            EndIf 

            //======================================================
            // Remover caracteres especiais do JSON.
            //======================================================
            _cRetRece := U_ITSUBCHR(_cRetRece, _aStrSubst)

            _lRetRec   := .F. // Retorno Receita Federal
            If SubStr(_cHdReceit,1,15) == "HTTP/1.1 200 OK"
               _lRetRec   := .T. 
            EndIf 

            If _lRetRec
               _oJSonRece := ""

               If ! FWJsonDeserialize(_cRetRece,@_oJSonRece)
                  _lRetRec := .F.
               EndIf 

            EndIf 

            If _lRetRec
               
               _oReceita  := _oJSonRece:company[1]

               _oBusiness := _oReceita:business
              
               _cCNAECisp   := ""
               _cCodNegoc   := ""
               _cDesecNegoc := ""

               If ValType(_oBusiness) <> "U"
                  
                  _oIndustri := _oBusiness:industries

                  For _nI := 1 To Len(_oIndustri)

                      _aIndAtiva := _oIndustri[_nI]
               	   _lIndAtiva := _oIndustri[_nI]:main
               	   If _lIndAtiva 
               	      _cCodNegoc := _oIndustri[_nI]:code
                         _cDesecNegoc := _oIndustri[_nI]:description
                      EndIf 

                  Next 

               EndIf 

               _cCodNegoc := SubStr(_cCodNegoc,1,2) + SubStr(_cCodNegoc,4,4) + "/" + SubStr(_cCodNegoc,9,2)
               _cCNAECisp := AllTrim(_cCodNegoc) 
            EndIf
            
             //========================================================================
             // Não consultar Sintegra - Manter variável para manter estrutra de dados
             //========================================================================
             _cNomSint  := ""
             _cFanSint  := ""
             _cInscSint := ""
             _cEndSint  := ""
             _cBairSint := ""
             _cUfSint   := ""
             _cMunSint  := ""
             _cCMunSint := ""
             _cCepSint  := ""
             _cSimNSint := ""
             _cSufrSint := ""
             _cSitCSint := ""
             _cDtCSSint := ""
             _cDtASSint := ""
             _cDtARSint := ""
             _cHrACSint := ""
             _cSitRSint := ""
             _cDtCRSint := ""
             _cDtATSint := ""
             _cBlqSint  := ""
             _cLogrSint := ""
             _cNumESint := ""
             _cComESint := ""

            //==============================================================================
            // Não consultar Receita Federal- Manter variável para manter estrutra de dados
            //==============================================================================
            _cNomRecF  := ""
            _cFanRecF  := ""
            _cInscRecF := ""
            _cEndRecF  := ""
            _cBairRecF := ""
            _cUfRecF   := ""
            _cMunRecF  := ""
            _cCMunRecF := "" 
            _cCepRecF  := ""
            _cSimNRecF := ""
            _cSufrRecF := ""
            _cSitCRecF := ""
            _cDtCSRecF := ""
            _cDtARSecF := ""
            _cDtARRecF := ""
            _cHrACRecF := ""
            _cSitRRecF := ""
            _cDtCRRecF := ""
            _cDtATRecF := ""
            _cBlqRecF := ""
            _cLogrRecF := ""
            _cNumERecF := ""
            _cComERecF := ""
      
            //======================================================
            // Consultando Cisp-Simples Nacional
            //======================================================
            If ! _lSchedule 
               IncProc("Consultando / Acessando link do Simples Nacional...")
            Else 
               U_ITConout("[AMOS138] - Consultando / Acessando link do Simples Nacional...")
            EndIf

            _aHeadOut := {} 
            aAdd( _aHeadOut , "accept:application/json")
            _cHdSimple := ""

            //Faz chamada ao webservice do Simples Nacional
            _cHdSimple := ""
            _cRetSimpN := HttpGet(_cUrlSimp,"",NIL,_aHeadOut,@_cHdSimple)

            //======================================================
            // Descriptografia do JSon Recebido
            //======================================================
            _cTextoAux := ""
            If ! Empty(_cRetSimpN)
               _cTextoAux := DecodeUTF8(_cRetSimpN, "cp1252")                     
            EndIf 

            If ! Empty(_cTextoAux)
               _cRetSimpN := _cTextoAux
            EndIf 
            
            //======================================================
            // Remover caracteres especiais do JSON.
            //======================================================
            _cRetSimpN := U_ITSUBCHR(_cRetSimpN,_aStrSubst)

            //======================================================
            // Consultando Cisp-Suframa
            //======================================================
            If ! _lSchedule
               IncProc("Consultando / Acessando link do Cisp-Suframa...")
            Else 
               U_ITConout("[AMOS138] - Consultando / Acessando link do Cisp-Suframa...")
            EndIf

            _cHdSufra := ""
            If SA1->A1_EST $ "AM,AC,RO,RR,AP" // Verifica se o estado do Cliente é suframa antes da consulta.
               _aHeadOut := {} 
               aAdd( _aHeadOut , "accept:application/json")
      
               // Faz a chamada ao webservice Suframa
               _cRetSufra := HttpGet(_cUrlSufr,"",NIL,_aHeadOut,@_cHdSufra)

               //======================================================
               // Descriptografia do JSon Recebido
               //======================================================
               _cTextoAux := ""
               If ! Empty(_cRetSufra)
                  _cTextoAux := DecodeUTF8(_cRetSufra, "cp1252")                       
               EndIf 

               If ! Empty(_cTextoAux)
                  _cRetSufra := _cTextoAux
               EndIf 

               //======================================================
               // Remover caracteres especiais do JSON.
               //======================================================
               _cRetSufra := U_ITSUBCHR(_cRetSufra, _aStrSubst)

            EndIf
    
            _lRetSufr  := .F. // Retorno Suframa
            If SubStr(_cHdSufra,1,15) == "HTTP/1.1 200 OK"
               _lRetSufr  := .T.
            EndIf 

            _lRetSimpN := .F. // Retorno Simples Nacional 
            If SubStr(_cHdSimple,1,15) == "HTTP/1.1 200 OK"
               _lRetSimpN := .T.
            EndIf  

            //======================================================
            // Lendo JSon Cisp-Simples Nacional e gerando objeto
            //======================================================
            If _lRetSimpN 
               _oJSonSmpN := ""

               If ! FWJsonDeserialize(_cRetSimpN,@_oJSonSmpN)
                  _lRetSimpN := .F.
               EndIf 
            EndIf 

            //======================================================
            // Lendo JSon Cisp-Suframa e gerando objeto.
            //======================================================
            If _lRetSufr
               _oJsonSufr := ""     

               If ! FWJsonDeserialize(_cRetSufra,@_oJsonSufr)
                  _lRetSufr := .F.
               EndIf 
            EndIf 

            //======================================================
            // Lendo JSon Cisp-Simples Nacional e gerando objeto
            //======================================================
            _cNomSimN  := ""
            _cFanSimN  := ""
            _cInscSimN := ""
            _cEndSimN  := ""
            _cBairSimN := ""
            _cUfSimN   := ""
            _cMunSimN  := ""
            _cCMunSimN := ""
            _cCepSimN  := ""
            _cSimNSimN := ""
            _cSufrSimN := ""
            _cSitCSimN := ""
            _cDtCSSimN := ""
            _cDtASSimN := ""
            _cDtARSimN := ""
            _cHrACSimN := ""
            _cSitRSimN := ""
            _cDtCRSimN := ""
            _cDtATSimN := ""
            _cBlqSimN  := ""
            _cLogrSimN := ""
            _cNumESimN := ""
            _cComESimN := ""
            If _lRetSimpN 
               If Type("_oJSonSmpN:COMPANY[1]:REGISTEREDNAME") <> "U"
                  _cNomSimN  := _oJSonSmpN:COMPANY[1]:REGISTEREDNAME
               EndIf 
      
               If Type("_oJSonSmpN:COMPANY[1]:BUSINESS:TAXSYSTEM:STATUSSIMPLESNACIONAL") <> "U"
                  _cSimNSimN := _oJSonSmpN:COMPANY[1]:BUSINESS:TAXSYSTEM:STATUSSIMPLESNACIONAL // "NÃƒO optante pelo Simples Nacional"
                  
                  If ! Empty(_cSimNSimN)
                     _cSimNSimN := U_ITSUBCHR(_cSimNSimN, {{"Ãƒ","A"}})
                     _cSimNSimN := Upper(_cSimNSimN)

                     If "NAO" $ _cSimNSimN
                        _cSimNSimN := "NAO"
                     Else
                        _cSimNSimN := "SIM"
                     EndIf 
                  EndIf 
               EndIf 
            EndIf 
         EndIf 

         //======================================================
         // Lendo JSon Cisp-Suframa e gerando objeto.
         //======================================================
         _cNomSufr := ""
         _cFanSufr := ""
         _cInscSufr := ""
         _cEndSufr := ""
         _cBairSufr := ""
         _cUfSufr := ""
         _cMunSufr := ""
         _cCMunSufr := ""
         _cCepSufr := ""
         _cSimNSufr := ""
         _cSufrSufr := ""
         _cSitCSufr := ""
         _cDtCSSufr := ""
         _cDtASSufr := ""
         _cDtARSufr := ""
         _cHrACSufr := ""
         _cSitRSufr := ""
         _cDtCRSufr := ""
         _cDtATSufr := ""
         _cBlqSufr  := ""
         _cLogrSufr := ""
         _cNumESufr := ""
         _cComESufr := ""

         If _lRetSufr
            If Type("_oJsonSufr:COMPANY[1]:REGISTEREDNAME") <> "U"
               _cNomSufr  := _oJsonSufr:COMPANY[1]:REGISTEREDNAME
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:ADDRESS:LINE1") <> "U"
               _cEndSufr  := _oJsonSufr:COMPANY[1]:ADDRESS:LINE1 + " " + _oJsonSufr:COMPANY[1]:ADDRESS:LINE2 + " " + _oJsonSufr:COMPANY[1]:ADDRESS:EXTENSION
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:ADDRESS:DISTRICT") <> "U"
               _cBairSufr := _oJsonSufr:COMPANY[1]:ADDRESS:DISTRICT
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:ADDRESS:STATE:CODE") <> "U"
               _cUfSufr   := _oJsonSufr:COMPANY[1]:ADDRESS:STATE:CODE
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:ADDRESS:CITY") <> "U"
               _cMunSufr  := _oJsonSufr:COMPANY[1]:ADDRESS:CITY
               _cMunSufr := Upper(_cMunSufr)
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:ADDRESS:POSTALCODE") <> "U"
               _cCepSufr  := _oJsonSufr:COMPANY[1]:ADDRESS:POSTALCODE
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:DOCUMENTS[1]:VALUE") <> "U"
               _cSufrSufr := _oJsonSufr:COMPANY[1]:DOCUMENTS[1]:VALUE 
            EndIf 

            If Type("_oJsonSufr:COMPANY[1]:REGISTER:STATUS") <> "U"
               _cSitCSufr := _oJsonSufr:COMPANY[1]:REGISTER:STATUS
            EndIf

            If ! Empty(_cUfSufr) .And. ! Empty(_cMunSufr)
               _cCMunSufr := Posicione("CC2",4,xFilial("CC2")+ _cUfSufr + U_ItKey(_cMunSufr,"CC2_MUN"),"CC2_CODMUN")
            EndIf
         EndIf  
         
         _aDados := {}
         aAdd(_aDados,{"A1_NOME"   ,"Razão Social"               , _cNomCisp  , _cNomSint  ,	_cNomRecF  ,_cNomSimN  , _cNomSufr})
         aAdd(_aDados,{"A1_NREDUZ" ,"Nome Fantasia"              , _cFanCisp  , _cFanSint  ,	_cFanRecF  ,_cFanSimN  , _cFanSufr})
         aAdd(_aDados,{"A1_INSCR"  ,"Inscrição Estadual"         , _cInscCisp , _cInscSint ,	_cInscRecF ,_cInscSimN , _cInscSufr})
         aAdd(_aDados,{"A1_END"    ,"Endereço"                   , _cEndCisp  , _cEndSint  ,	_cEndRecF  ,_cEndSimN  , _cEndSufr})
         aAdd(_aDados,{"A1_BAIRRO" ,"Bairro"                     , _cBairCisp , _cBairSint ,	_cBairRecF ,_cBairSimN , _cBairSufr})
         aAdd(_aDados,{"A1_EST"    ,"Estado"                     , _cUfCisp   , _cUfSint   ,	_cUfRecF	  , _cUfSimN  , _cUfSufr})
         aAdd(_aDados,{"A1_MUN"    ,"Municipio"                  , _cMunCisp  , _cMunSint  ,	_cMunRecF  ,_cMunSimN  , _cMunSufr})
         aAdd(_aDados,{"A1_COD_MUN","Código Município"           , _cCMunCisp , _cCMunSint ,	_cCMunRecF ,_cCMunSimN , _cCMunSufr})
         aAdd(_aDados,{"A1_CEP"    ,"Cep"                        , _cCepCisp  , _cCepSint  , _cCepRecF  ,_cCepSimN  , _cCepSufr })
         aAdd(_aDados,{"A1_SIMPNAC","Simples Nacional"           , _cSimNCisp , _cSimNSint ,	_cSimNRecF ,_cSimNSimN , _cSimNSufr})
         aAdd(_aDados,{"A1_SUFRAMA","Suframa"                    , _cSufrCisp , _cSufrSint ,	_cSufrRecF ,_cSufrSimN , _cSufrSufr})
         aAdd(_aDados,{"A1_I_SCST" ,"Sit Cadastral Sintegra"     , ""         , _cSitCSint ,	""         ,""         , ""        })
         aAdd(_aDados,{"A1_I_D1ST" ,"Data Consulta Sintegra"     , ""         , _cDtCSSint ,	"" /*_cDtCSRecF*/ ,_cDtCSSimN , _cDtCSSufr})
         aAdd(_aDados,{"A1_I_D2ST" ,"Data Atualizacao Sintegra"  , ""         , _cDtASSint ,	/*_cDtARSecF*/"" ,_cDtASSimN , _cDtASSufr})
         aAdd(_aDados,{"A1_I_D3ST" ,"Data Atualizacao Reg Cisp"  , _cDtARCisp , _cDtARSint ,	/*_cDtARRecF*/ "" ,_cDtARSimN , _cDtARSufr})
         aAdd(_aDados,{"A1_I_HRST" ,"Hora Atualizacao Cisp"      , _cHrAcCisp , _cHrACSint ,	_cHrACRecF ,_cHrACSimN , _cHrACSufr})
         aAdd(_aDados,{"A1_I_SCRC" ,"Sit Cadastral Receita Fed"  , ""         , _cSitRSint ,	_cSitCRecF ,_cSitRSimN , _cSitRSufr})
         aAdd(_aDados,{"A1_I_D1RC" ,"Data Consulta Receita Fed"  , ""         , _cDtCRSint ,	_cDtCRRecF ,_cDtCRSimN , _cDtCRSufr})
         aAdd(_aDados,{"A1_I_D2RC" ,"Data Atualizacao Receita"   , ""         , _cDtATSint ,	_cDtARRecF ,_cDtATSimN , _cDtATSufr})
         aAdd(_aDados,{"A1_MSBLQL" ,"Bloqueado"                  , _cBlqCisp  , _cBlqSint  ,	_cBlqRecF  ,_cBlqSimN  , _cBlqSufr})
         aAdd(_aDados,{"A1_I_LOGRA","Logradouro  / Endereço"     , _cLogrCisp , _cLogrSint ,	_cLogrRecF ,_cLogrSimN , _cLogrSufr})
         aAdd(_aDados,{"A1_I_NUMER","Numero do Endereço"         , _cNumECisp , _cNumESint ,	_cNumERecF ,_cNumESimN , _cNumESufr})
         aAdd(_aDados,{"A1_I_COMPL","Complemento do Endereço Sin", _cComECisp , _cComESint ,	_cComERecF ,_cComESimN , _cComESufr})
         aAdd(_aDados,{"A1_CNAE"   ,"CNAE"                       , _cCNAECisp , ""         ,	""         ,""         , ""        })

         //===========================================================================
         // Grava array com dados das atualizações antes/depois para envio de e-mail.
         //===========================================================================
         If ! _lSchedule 
            IncProc("Atualizando cadastro de clientes com a CISP...")
         Else 
            U_ITConout("[AMOS138] - Atualizando cadastro de clientes com os dados da CISP...")
         EndIf

         _cObserv := "Dados não atualizados com o Retorno da Cisp-Monitoramento-Sintegra."

         _nPosIni := Len(_aDadosRel) + 1
         _nPodFin := Len(_aDados) + _nPosIni
  
         For _nI := 1 To Len(_aDados)
             aAdd(_aDadosRel,{SA1->A1_COD,;                        //  1 - Codigo Cliente 
                              SA1->A1_LOJA,;                       //  2 - Loja Cliente
                              SA1->A1_CGC,;                        //  3 - CNPJ Cliente
                              _aDados[_nI,1],;                     //  4 - Campo Atualizado
                              _aDados[_nI,2],;                     //  5 - Descrição Campo Atualizado
                              &("SA1->"+_aDados[_nI,1]),;          //  6 - Informação Antes Atualização
                              _aDados[_nI,3],;                     //  7 - Dados Cisp
                              _aDados[_nI,4],;                     //  8 - Dados Cisp-Sintegra
                              _aDados[_nI,5],;                     //  9 - Dados Cisp-Receita Federal
                              _aDados[_nI,6],;                     // 10 - Dados Cisp-Simples Nacional
                              _aDados[_nI,7],;                     // 11 - Dados Cisp-Suframa
                              _cUsuario,;                          // 12 - Usuário responsável pela atualização
                              "" })                                // 13 - Observação
         Next 
   
         //===================================================================
         // Atualiza cadastro de clientes.
         //===================================================================
         // Só atualiza se existir o parâmetro ativando gravação do SA1
         //===================================================================         
  	      If U_ITGETMV("ITGRVCLI",.F.)
  	     	  	
            SA1->(RecLock("SA1",.F.))
            If ! Empty(_cNomCisp) 
               SA1->A1_NOME := _cNomCisp // _aDados[1,3]  // Razão Social"               , _cNomCisp  , _cNomSint  ,	_cNomRecF  ,_cNomSimN  , _cNomSufr})
            EndIf 

            //If ! Empty(_cFanCisp)
            //   SA1->A1_NREDUZ := _cFanCisp    // _aDados[2,3]  // Nome Fantasia"              , _cFanCisp  , _cFanSint  ,	_cFanRecF  ,_cFanSimN  , _cFanSufr})
            //EndIf 

            If ! Empty(_cInscCisp)
               SA1->A1_INSCR := _cInscCisp    // Inscrição Estadual"         , _cInscCisp , _cInscSint ,	_cInscRecF ,_cInscSimN , _cInscSufr})
            EndIf 

            If ! Empty(_cEndCisp)
               SA1->A1_END := _cEndCisp      // Endereço"                   , _cEndCisp  , _cEndSint  ,	_cEndRecF  ,_cEndSimN  , _cEndSufr})
            EndIf 

            If ! Empty(_cBairCisp)
               SA1->A1_BAIRRO := _cBairCisp  // Bairro"                     , _cBairCisp , _cBairSint ,	_cBairRecF ,_cBairSimN , _cBairSufr})
            EndIf 

            If ! Empty(_cUfCisp)
               SA1->A1_EST := _cUfCisp      // Estado"                     , _cUfCisp   , _cUfSint   ,	_cUfRecF	  , _cUfSimN  , _cUfSufr})
            EndIf 

            If ! Empty(_cMunCisp)
               SA1->A1_MUN  := _cMunCisp    // Municipio"                  , _cMunCisp  , _cMunSint  ,	_cMunRecF  ,_cMunSimN  , _cMunSufr})
            EndIf 

            If ! Empty(_cCMunCisp)
               SA1->A1_COD_MUN := _cCMunCisp // Código Município"           , _cCMunCisp , _cCMunSint ,	_cCMunRecF ,_cCMunSimN , _cCMunSufr})
            EndIf 

            If ! Empty(_cCepCisp)
               SA1->A1_CEP := _cCepCisp      // Cep"                        , _cCepCisp  , _cCepSint  , _cCepRecF  ,_cCepSimN  , _cCepSufr })
            EndIf 

            If ! Empty(_cSimNSimN)
               SA1->A1_SIMPNAC := If(AllTrim(_cSimNSimN) == "NAO", "2", "1") // Simples Nacional"           , _cSimNCisp , _cSimNSint ,	_cSimNRecF ,_cSimNSimN , _cSimNSufr})
   
               If ! Empty(_cUfCisp) .And. AllTrim(_cUfCisp) $ _cUfMVA
                  If AllTrim(_cSimNSimN) <> "NAO" 
                     SA1->A1_GRPTRIB := _cTRIBMVA // "023" // Solicitação Chamado: 44096 = Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
                  Else  
                     If AllTrim(SA1->A1_GRPTRIB) == AllTrim(_cTRIBMVA)
                        SA1->A1_GRPTRIB := " "
                     EndIf
                  EndIf 
               EndIf
            EndIf 

            If ! Empty(_cSufrSufr)
               SA1->A1_SUFRAMA := _cSufrSufr // Suframa"                    , _cSufrCisp , _cSufrSint ,	_cSufrRecF ,_cSufrSimN , _cSufrSufr})
            EndIf 
    
            If ! Empty(_cSitCCisp)
               SA1->A1_I_SCST := _cSitCCisp   // Sit Cadastral Sintegra"     , ""         , _cSitCSint ,	""         ,""         , ""        })
            EndIf          

            SA1->A1_I_D1ST := Date()   // Data Consulta Sintegra"     , ""         , _cDtCSSint ,	"" / *_cDtCSRecF* / ,_cDtCSSimN , _cDtCSSufr})
               
            If ! Empty(_cDtARCisp)
               SA1->A1_I_D2ST := Ctod(_cDtARCisp)  // Data Atualizacao Sintegra"  , ""         , _cDtASSint ,	/ *_cDtARSecF * /"" ,_cDtASSimN , _cDtASSufr})
            EndIf 

            If ! Empty(_cDtARCisp)
               SA1->A1_I_D3ST := Ctod(_cDtARCisp)   // Data Atualizacao Reg Cisp"  , _cDtARCisp , _cDtARSint ,	/ *_cDtARRecF* / "" ,_cDtARSimN , _cDtARSufr})
            EndIf 
      
            If ! Empty(_cHrAcCisp)
               SA1->A1_I_HRST := _cHrAcCisp   // Hora Atualizacao Cisp"      , _cHrAcCisp , _cHrACSint ,	_cHrACRecF ,_cHrACSimN , _cHrACSufr})
            EndIf 

            If ! Empty(_cSitCCisp)
               SA1->A1_I_SCRC := _cSitCCisp   // Sit Cadastral Receita Fed"  , ""         , _cSitRSint ,	_cSitCRecF ,_cSitRSimN , _cSitRSufr})
            EndIf 

            If ! Empty(_cDtARCisp)
               SA1->A1_I_D1RC := CTod(_cDtARCisp)  // Data Consulta Receita Fed"  , ""         , _cDtCRSint ,	_cDtCRRecF ,_cDtCRSimN , _cDtCRSufr})
            EndIf 

            If ! Empty(_cDtARCisp)
               SA1->A1_I_D2RC := CTod(_cDtARCisp)  // Data Atualizacao Receita"   , ""         , _cDtATSint ,	_cDtARRecF ,_cDtATSimN , _cDtATSufr})
            EndIf 

            If ! Empty(_cBlqCisp)
               SA1->A1_MSBLQL := If(AllTrim(_cBlqCisp) == "NAO","2","1")  // Bloqueado"                  , _cBlqCisp  , _cBlqSint  ,	_cBlqRecF  ,_cBlqSimN  , _cBlqSufr})
            EndIf 
      
            If SA1->A1_I_ATCIS != "N" .And. U_ITGETMV("ITGRVCLI",.F.)
               If ! Empty(_cLogrCisp)
                  SA1->A1_I_LOGRA := _cLogrCisp // Logradouro  / Endereço"     , _cLogrCisp , _cLogrSint ,	_cLogrRecF ,_cLogrSimN , _cLogrSufr})
               EndIf 
         
               If ! Empty(_cNumECisp)
                  SA1->A1_I_NUMER := _cNumECisp  // Numero do Endereço"         , _cNumECisp , _cNumESint ,	_cNumERecF ,_cNumESimN , _cNumESufr})
               EndIf 

               If ! Empty(_cComECisp)
                  SA1->A1_I_COMPL := _cComECisp  // Complemento do Endereço Sin", _cComECisp , _cComESint ,	_cComERecF ,_cComESimN , _cComESufr})
               EndIf 
            EndIf 
     
            SA1->(MSUnLock())
            _cObserv := "Cadastro de Clientes atualizados com os dados da Cisp-Monitoramento-Sintegra."

            //===================================================================================
            // Grava os dados dos clientes nas tabelas de muro para integração com o sistema RDC.
            //===================================================================================
            If ! _lSchedule 
               IncProc("Grava as tabelas de muro para envio de dados para o RDC...")
            Else 
               U_ITConout("[AMOS138] - Grava as tabelas de muro para envio de dados para o RDC...")
            EndIf
            U_AOMS076G()
         Else 
            _cObserv := "Cadastro não atualizado com Cisp-Monitoramento-Sintegra, parâmetro ITGRVCLI desabilitado."
         EndIf 
      
         //=====================================================
         // Grava log de Consulta e Atualização
         //=====================================================
         ZGF->(RecLock("ZGF",.T.))
        	ZGF->ZGF_CODCLI := SA1->A1_COD
  	      ZGF->ZGF_LOJA := SA1->A1_LOJA
  	      ZGF->ZGF_NOMEA := SA1->A1_NOME
  	      ZGF->ZGF_NOMEN := _cNomCisp  

  	      ZGF->ZGF_INSCA := SA1->A1_INSCR 
  	      ZGF->ZGF_INSCN := _cInscCisp 

  	      ZGF->ZGF_ENDA := SA1->A1_END
  	      ZGF->ZGF_ENDN := _cEndCisp
  	      ZGF->ZGF_SIMPA := SA1->A1_SIMPNAC
  	      ZGF->ZGF_SIMPN := If(AllTrim(_cSimNSimN) == "NAO", "2", "1") 
  	      ZGF->ZGF_BAIRA := SA1->A1_BAIRRO
  	      ZGF->ZGF_BAIRN := _cBairCisp
  	      ZGF->ZGF_MUNA := SA1->A1_MUN
  	      ZGF->ZGF_MUNN := _cCMunCisp
  	      ZGF->ZGF_CMUNA := SA1->A1_COD_MUN
  	      ZGF->ZGF_CMUNN := _cMunCisp
  	      ZGF->ZGF_ESTA := SA1->A1_EST
  	      ZGF->ZGF_ESTN := _cUfCisp
         ZGF->ZGF_CEPA := SA1->A1_CEP   
  	      ZGF->ZGF_CEPN := _cCepCisp  
  	      ZGF->ZGF_SCSTA := SA1->A1_I_SCST
  	      ZGF->ZGF_SCSTN := _cSitCCisp
  	      ZGF->ZGF_D1STA := SA1->A1_I_D1ST
  	      ZGF->ZGF_D1STN := Date()
  	      ZGF->ZGF_D2STA := SA1->A1_I_D2ST
  	      ZGF->ZGF_D2STN := CTod(_cDtARCisp)
  	      ZGF->ZGF_D3STA := SA1->A1_I_D3ST
  	      ZGF->ZGF_D3STN := Date()
         ZGF->ZGF_MSBLA := SA1->A1_MSBLQL
         ZGF->ZGF_MSBLN := If(AllTrim(_cBlqCisp) == "NAO","2","1")
         ZGF->ZGF_HRSTA := SA1->A1_I_HRST
         ZGF->ZGF_HRSTN := Time()
         ZGF->ZGF_RCSTA := SA1->A1_I_SCRC
         ZGF->ZGF_RCSTN := _cSitCCisp
         ZGF->ZGF_D1RCA := SA1->A1_I_D1RC
         ZGF->ZGF_D1RCN := CTod(_cDtARCisp)
         ZGF->ZGF_D2RCA := SA1->A1_I_D2RC
         ZGF->ZGF_D2RCN := CTod(_cDtARCisp)
         ZGF->ZGF_USER  := _cUsuario
         ZGF->ZGF_OBS   := _cObserv
         ZGF->ZGF_SUFRA := SA1->A1_SUFRAMA
         ZGF->ZGF_SUFRN := _cSufrSufr
         ZGF->(MSUnLock())
    
         For _nI := _nPosIni To (_nPodFin - 1)  // Atualiza observações
             _aDadosRel[_nI,13] := Upper(_cObserv)
         Next 
         
      Next   
   
   EndIf 

   //===============================================================================================================
   // Atualiza demais clientes ativos na Cisp que não tenha atualização recente
   //===============================================================================================================
   If ! _lSchedule
      IncProc("Atualizando demais clientes ativos na CISP...")
   Else  
      U_ITConout("[AMOS138] - Atualizando demais clientes ativos na CISP...")
   EndIf
  
   _cdatalim := DToS(Date() - u_itgetmv("ITDIASCLI",30)) //data limite de atualização dos clientes
   _nlimite  := u_itgetmv("ITLIMCLI",10) // quantidade máxima de clientes a ser atualizada

   _cFiltCnpj := ""
   If ! Empty(_cClieProc)
      _cFiltCnpj := FormatIn(_cClieProc,";")
      _cFiltCnpj := StrTran(_cFiltCnpj,",''","")
   EndIf 
  
   //===========================================================================
   // Monta a consulta de atualização do Cadastro de Clientes na base da CISP |
   //===========================================================================
   _cQry := " SELECT SA1.R_E_C_N_O_ NREC "
   _cQry += " FROM "+ RetSqlName("SA1") +" SA1 JOIN "+ RetSqlName("SZY") +" SZY ON TRIM(SZY.ZY_PCCCLI) = TRIM(SubStr(SA1.A1_CGC,1,8)) "
   _cQry += " WHERE "   
   _cQry += " 		SA1.D_E_L_E_T_			= ' ' "
   _cQry += " AND		 SA1.A1_PESSOA			= 'J' "
   _cQry += " AND     SA1.A1_I_ATCIS         <> 'N' "
   _cQry += " AND     SA1.A1_MSBLQL          <> '1' "
   _cQry += " AND     (((SA1.A1_I_D1ST < '" + _cdatalim + "' OR SA1.A1_I_D1RC  < '" + _cdatalim + "') "
   _cQry += " AND     SA1.A1_I_D3ST < '" +  _cdatalim + "') OR SA1.A1_SIMPNAC = ' ') "
   _cQry += " AND     SZY.ZY_PCDUCM > '" + DToS(DATE()-365) + "' "
   _cQry += " AND     SZY.D_E_L_E_T_ = ' ' " 
      
   If ! Empty(_cFiltCnpj)
      _cQry += " AND     SA1.A1_CGC NOT IN " + _cFiltCnpj
   EndIf 

   If ! Empty(_cUFProc) // Filtro por Estado.  
      _cQry += " AND SA1.A1_EST IN " + FormatIn(_cUFProc,";")
   EndIf 

   _cQry += " ORDER BY SA1.A1_COD"

   If Select("TRBCISP") > 0
	   TRBCISP->( DBCloseArea() )
   EndIf

   //DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , cTrbAux , .F. , .T. )
   //DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "TRBCISP" , .F. , .T. )
   TCQUERY _cQry NEW ALIAS "TRBCISP"

   _nI := 1
   Count To _nTotReg	

   DBSelectArea("TRBCISP")
   TRBCISP->( DBGoTop() )

   //ProcRegua(_nTotReg)
   ProcRegua(_nLimite)

   While ! TRBCISP->( Eof() ) .And. _nI <= _nLimite
  	 
      If ! _lSchedule
         IncProc("Atualizando registros - " + StrZero(_nI,6) + "/Limite: " + StrZero(_nLimite,6) + "-Total Regs: " + StrZero(_nTotReg,6))
      Else  
         U_ITConout("[AMOS138] - Atualizando registros - " + StrZero(_nI,6) + " de " + StrZero(_nTotReg,6))
      EndIf

	   SA1->(DBGoTo(TRBCISP->NREC))

      //========================================================
      // Chama a rotina de atualização de clientes Posicionado.
      //======================================================== 
      U_AOMS138A(_lSchedule,.F., {}, .F.)

      _nI += 1 

      TRBCISP->(DBSkip())
   EndDo
	   
   If ! _lSchedule 
      IncProc("Enviando e-mail com as atualizações...")
   Else 
      U_ITConout("[AMOS138] - Enviando e-mail com as atualizações...")
   EndIf

   If ! Empty(_aDadosRel)
      U_AOMS138E(_aDadosRel) // ENVIO DE E-MAIL.
   EndIf 

End Sequence 

If Select("TRBCISP") > 0
   TRBCISP->( DBCloseArea() )
EndIf

Return 

/*
===============================================================================================================================
Programa----------: AOMS138S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 24/07/2023
Descrição---------: Rotina de atualização dos dados cadastrais do cliente com os dados da CISP, via Scheduller.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS138S()
Private _aDadosRel

Begin Sequence

   U_ItConOut( '[AOMS138] - Atualização Clientes com a CISP: ['+ DToC(Date()) +' - '+ Time() +'] - Abrindo o ambiente...' )
   RpcClearEnv()
   RPCSetType(2)
      
   RpcSetEnv( "01" , "01" ,,,"OMS", "SCHEDULLER_INT_CISP-SINTEGRA-RECEITA_FEDERAL-SIMPLES NACIONAL-SUFRAMA" , {'SA1','ZP1'} )
   
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

   cUSUARIO := Space(06)+"Administrador  "
   cUserName:= "Schedure"
   
   _aDadosRel := {}

   U_AOMS138G(.T.)
   
End Sequence

Return    

/*
===============================================================================================================================
Programa--------: AOMS138T()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 28/06/2023
Descrição-------: Tela para seleção filtros para processamento geral.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS138T()
Local _lRet := .T.

Begin Sequence
   //================================================================================
   // Tela de Aprovação de Pedido de Vendas
   //================================================================================      
   _cTitulo := "Atualização Geral CISP - Seleção de Estados"
   _bOk := {|| (_lRet := .T., _oDlgCISP:End())}
   _bCancel := {|| _lRet := .F., _oDlgCISP:End()}
   
   _cUFProc := Space(100)

   Define MsDialog _oDlgCISP Title _cTitulo From 9,0 To 17,90 Of oMainWnd 
      
      @ 40,20 Say "Estado/Estados: " Of _oDlgCISP Pixel 
      @ 39,80 MSGet _cUFProc Picture "@!" F3 "LSTEST"  Size 100, 10 Of _oDlgCISP Pixel

   Activate MsDialog _oDlgCISP On Init EnchoiceBar(_oDlgCISP,_bOk,_bCancel) CENTERED 

   If _lRet .And. ! U_ITMsg("Confirma a atualização geral de clientes?","Atenção",,3,2,2)
		_lRet := .F.
	EndIf

End Sequence

Return _lRet   

/*
===============================================================================================================================
Programa----------: AOMS138L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 28/08/2023
Descrição---------: Função utilizada no botão de legenda mostrar o significado das legendas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS138L()

Local cCadastro:=OemToAnsi("Efetivação do Cadastro de Prospect")

BrwLegenda(cCadastro,"Legenda",{	{'ENABLE'     ,"Atualizado"},;
	                              {"BR_VERMELHO","Desatualizado"}})

Return

/*
===============================================================================================================================
Programa----------: AOMS138N
Autor-------------: Igor Melgaço
Data da Criacao---: 24/07/2024
Descrição---------: Limpa a Inscricao Estadual.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS138N(cInscEst,cUF)
Local cIncricao := ""
Local n := 0

If Upper(AllTrim(cInscEst)) == "ISENTO"
   cIncricao := "ISENTO"
Else
   For n := 1 To Len(cInscEst)
      If Subs(cInscEst,n,1) $ "1234567890"
         cIncricao += Subs(cInscEst,n,1) 
      EndIf
   Next
EndIf

If AllTrim(cUF) == "MG" .And. cIncricao <> "ISENTO"
   cIncricao := StrZero(Val(cIncricao),13)
EndIf

Return cIncricao
