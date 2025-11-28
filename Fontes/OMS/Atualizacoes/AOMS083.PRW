/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função EncodeUtf8 por FWHttpEncode
Igor Melgaco  |26/06/2025| Chamado 45229. Correcao de url.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===========================================================================================================================================================================================================================================================
 Analista       - Programador  - Inicio   - Envio    - Chamado - Motivo da Alteração
============================================================================================================================================================================================================================================================
Vanderlei Alves - Alex Wallauer- 21/11/25 -          - 53091   - Ajsute para ler os parametros IT_EST3FIL / IT_EST3LOC na filial correta quando rodar via scheduller.
===========================================================================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Include "APWEBSRV.CH"   

/*
===============================================================================================================================
Programa----------: AOMS083
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de integração e envio de dados dos estoques via webservice para empresa  / Multi.
===============================================================================================================================
*/  
User Function AOMS083()
Local _aCores := {}
Private aRotina := {}
Private cCadastro 

Begin Sequence

	//Grava Log de execução da rotina
	U_ITLOGACS()

   cCadastro := "Integração dos Dados dos Estoques Via Webservice: Italac <---> RDC ou TMS"
   aAdd(aRotina,{"Pesquisar" ,"AxPesqui" ,0,1})
   aAdd(aRotina,{"Visualizar","AxVisual" ,0,2})
   aAdd(aRotina,{"Gera Dados Integr.WS"  ,"U_AOMS083R",0,3})
   aAdd(aRotina,{"Integracao Webservice" ,"U_AOMS083I",0,4})
   aAdd(aRotina,{"Legenda"   ,"U_AOMS083L" ,0,6})
   
   aAdd(_aCores,{"ZFJ_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZFJ_SITUAC == 'P'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZFJ_SITUAC == 'R'" ,"BR_AMARELO" })

   DBSelectArea("ZFJ")
   ZFJ->(DBSetOrder(1)) 
   ZFJ->(DBGoTop())
   MBrowse(6,1,22,75,"ZFJ", , , , , , _aCores)
   
End Sequence

Return    

/*
===============================================================================================================================
Programa----------: AOMS083L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083L()

Local _aLegenda := {}

Begin Sequence
   aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
   aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })

   BrwLegenda(cCadastro, "Legenda", _aLegenda)

End Sequence

Return

/*
===============================================================================================================================
Programa----------: AOMS083I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de integração e envio de dados dos estoques via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083I()

Local _lRet := .F.
Local _aStrucZFJ
Local _aOrd := SaveOrd({"ZFJ"})
Local _aCmpZFJ := {}
Local _aButtons := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgInt, _nI
Private _lWsTms := If(cFilAnt $ SuperGetMV( 'IT_WEBETMS',.F.,"90") .And. !Empty(SuperGetMV( 'IT_LOEMTMS',.F.,"")) ,.T.,.F.)
Private _oMarkZFJ, _cMarcaZFJ := GetMark() 
Private aHeader, aCols

Begin Sequence
   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFJ",1,,,{||.T.},,,,,,.T.)
   
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFQ 
   aAdd( _aCmpZFJ , { "WK_OK"		,    , "Marca"    ,"@!"})
   
   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2])=="ZFJ_FILIAL" 
          Loop
       EndIf
       
       aAdd( _aCmpZFJ , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
   Next

   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFJ := {}
   aAdd(_aStrucZFJ,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFJ,{"WKRECNO", "N", 10,0})
   For _nI := 1 To Len(aHeader)
       aAdd(_aStrucZFJ,{aHeader[_nI,2], aHeader[_nI,8], aHeader[_nI,4] ,aHeader[_nI,5]})
   Next   

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZFJ") > 0
      TRBZFJ->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZFQ criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZFJ",  _aStrucZFJ )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZFJ_DATA"} )
   _otemp:Create()   
   
   DBSelectArea("TRBZFJ")
                                                                                
   //================================================================================
   // Carrega os dados da tabela ZFJ
   //================================================================================
   Processa( {|| U_AOMS083D(.F.) } , 'Aguarde!' , 'Lendo dados a serem integrados...' )

   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}
   aAdd(_aButtons,{"",{|| U_AOMS083M("T") },"Marc/Des","Marca/Desmarca Todos"})
  
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgInt Title _cTitulo From 9,0 To 200,80 Of oMainWnd 
      
      _oMarkZFJ := MsSelect():New("TRBZFJ","WK_OK","",_aCmpZFJ,@_lInverte, @_cMarcaZFJ,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
      _oMarkZFJ:bAval := {|| U_AOMS083M("P")}
      _oDlgInt:lMaximized:=.T.
      
   Activate MsDialog _oDlgInt On Init (EnchoiceBar(_oDlgInt,_bOk,_bCancel,,_aButtons), _oMarkZFJ:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkZFJ:oBrowse:Refresh() )
   
   If _lRet
      If _lWsTms
         Processa( {|| U_AOMS083Y( .F. ) , U_AOMS083W( .F. ) } , 'Aguarde!' , 'Integrando Dados do Estoque...' )
      Else
         Processa( {|| U_AOMS083W( .F. ) } , 'Aguarde!' , 'Integrando Dados do Estoque...' )
      EndIf
   EndIf

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZFJ") > 0
   TRBZFJ->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa--------: AOMS083M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/09/2016
Descrição-------: Função para marcar e desmarcar todos estoques que serão integrados via Webservice.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS083M(_cTipoMarca)

Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZFJ->(Recno()) 

Begin Sequence          
   If Empty(TRBZFJ->WK_OK )
      _cSimboloMarca := _cMarcaZFJ
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZFJ->(RecLock("TRBZFJ",.F.))
      TRBZFJ->WK_OK := _cSimboloMarca 
      TRBZFJ->(MSUnLock())
   Else
      TRBZFJ->(DBGoTop())
      While ! TRBZFJ->(Eof())
         TRBZFJ->(RecLock("TRBZFJ",.F.))
         TRBZFJ->WK_OK := _cSimboloMarca 
         TRBZFJ->(MSUnLock()) 
         
         TRBZFJ->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZFJ->(DBGoTo(_nRegAtu)) 
_oMarkZFJ:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS083W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Gera os dados XML com base nos estoques selecionados e integra via webservice.
Parametros--------: _lScheduller = .T. = Modo agendado (Scheduller) / .F. = Modo manual
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083W(_lScheduller)             

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cDetXML := ""
Local _cRodXML := ""
Local _lItemSelect := .F.
Local _cEmpWebService := ""
Local _aOrd := SaveOrd({"ZFJ","ZFM"})
Local _cXML 
Local _cResult := ""
Local _cOk := ""
Local _cResposta, _cSituacao

Default _lScheduller := .F.

Begin Sequence
   //================================================================================
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   //================================================================================                    
   If _lScheduller
      u_itconout("[AOMS083] - Verificando itens selecionados. Data: "+DToC(Date())+". Hora: "+Time())
   Else
      ProcRegua(8)     
      IncProc("Verificando itens selecionados...")      
   EndIf
   
   TRBZFJ->(DBGoTop())                                                                   
   While ! TRBZFJ->(Eof())
      If ! Empty(TRBZFJ->WK_OK)   
         _cEmpWebService := TRBZFJ->ZFJ_CODEMP                         
         _lItemSelect := .T. 
         Exit
      EndIf                 
      
      TRBZFJ->(DBSkip())
   EndDo 
   
   If ! _lItemSelect
      If _lScheduller
         Break//u_itconout("[AOMS083] - Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC. Data: "+DToC(Date())+". Hora: "+Time())
      Else
         U_ITMsg("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.","Atenção",,1)
         Break   
      EndIf
   EndIf              
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   If _lScheduller
      u_itconout("[AOMS083] - Identificando diretório dos XML. Data: "+DToC(Date())+". Hora: "+Time())
   Else
      IncProc("Identificando diretório dos XML...")                    
   EndIf

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else
      If _lScheduller
         u_itconout("[AOMS083] - Empresa WebService para envio dos dados não localizada. Data: "+DToC(Date())+". Hora: "+Time())
      Else
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf                                                              
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lScheduller
         u_itconout("[AOMS083] - Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+". Data: "+DToC(Date())+". Hora: "+Time())
      Else
         U_ITMsg("Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: ";
               +AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
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
   If _lScheduller
      u_itconout("[AOMS083] - Lendo arquivo XML Modelo de Cabeçalho. Data: "+DToC(Date())+". Hora: "+Time())
   Else
      IncProc("Lendo arquivo XML Modelo de Cabeçalho...")                      
   EndIf
   
   _cCabXML := U_AOMS083X(_cDirXML+"Cab_EntradaEstoque.txt") 
   If Empty(_cCabXML)
      If _lScheduller
         u_itconout("[AOMS083] - Erro na leitura do arquivo XML modelo do cabeçalho de entrada estoque. Data: "+DToC(Date())+". Hora: "+Time())
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do cabeçalho de entrada estoque. ","Atenção",,1)
      EndIf
      
      Break
   EndIf
   
   If _lScheduller
      u_itconout("[AOMS083] - Lendo arquivo XML Modelo de Detalhe. Data: "+DToC(Date())+". Hora: "+Time())
   Else
      IncProc("Lendo arquivo XML Modelo de Detalhe...")
   EndIf
   
   _cDetXML := U_AOMS083X(_cDirXML+"Det_EntradaEstoque.txt")
   If Empty(_cDetXML)
      If _lScheduller
         u_itconout("[AOMS083] - Erro na leitura do arquivo XML modelo do detalhe de entrada estoque.Data: "+DToC(Date())+". Hora: "+Time())
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe de entrada estoque.","Atenção",,1)
      EndIf
      
      Break
   EndIf            
   
   If _lScheduller
      u_itconout("[AOMS083] - Lendo arquivo XML Modelo de Rodapé. Data: "+DToC(Date())+". Hora: "+Time())
   Else
      IncProc("Lendo arquivo XML Modelo de Rodapé...")
   EndIf
    
   _cRodXML := U_AOMS083X(_cDirXML+"Rodape_EntradaEstoque.txt")
   If Empty(_cRodXML)
      If _lScheduller
         u_itconout("[AOMS083] - Erro na leitura do arquivo XML modelo do rodapé de entrada estoque. Data: "+DToC(Date())+". Hora: "+Time())
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do rodapé de entrada estoque.","Atenção",,1)
      EndIf
      
      Break
   EndIf
   
   //================================================================================
   // Concatena os estoques selecionados e monta array de XML com os dados.
   //================================================================================                       
   If _lScheduller
      u_itconout("[AOMS083] - Montando dados de envio. Data: "+DToC(Date())+". Hora: "+Time())
   Else
      IncProc("Montando dados de envio...")
   EndIf
   
   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.         
   oWsdl:nTimeout := 10 //timeout de 10 segundos
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                               
   
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
   oWsdl:SetOperation( "EnviaEstoque") // Define qual operação será realizada.

   If _lScheduller
      u_itconout("[AOMS083] - Enviando Dados. Data: "+DToC(Date())+". Hora: "+Time())
   EndIf
   
   _aresult := {}
   
   TRBZFJ->(DBGoTop())                                                                   
   While ! TRBZFJ->(Eof())    
      If ! Empty(TRBZFJ->WK_OK)   
         ZFJ->(DBGoTo(TRBZFJ->WKRECNO))
        
         Begin Transaction
 		    // Monta XML
 		    _cXML := _cCabXML + &(_cDetXML) + _cRodXML  // Monta o XML de envio.

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
            _lStatus := .T.
            
            If ! _cOk
               _cSituacao := "N"  
               _lStatus := .F.
            ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta)       	
               _cSituacao := "N"
               _lStatus := .F.
 		      EndIf

 		    //grava resultado // sempre como processado
            ZFJ->(RecLock("ZFJ",.F.))
            ZFJ->ZFJ_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
            ZFJ->ZFJ_USUARI  := __cUserId
            ZFJ->ZFJ_DATAAL  := Date() // Grava data de alteração da tabela de muro.
            ZFJ->ZFJ_DTENV   := Date() // Grava data de envio para o RDC.
            ZFJ->ZFJ_HRENV   := Time() // Grava hora de envio para o RDC.
            ZFJ->ZFJ_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFJ,dizendo que deu certo ou não.
            ZFJ->ZFJ_XML     := _cXML
            ZFJ->(MSUnLock())
        
            aAdd(_aresult,{_lStatus,ZFJ->ZFJ_CGC,ZFJ->ZFJ_NOME,ZFJ->ZFJ_FILTMS,AllTrim(Subs(ZFJ->ZFJ_COD,1,11)),ZFJ->ZFJ_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
            Sleep(500) //Espera para não travar a comunicação com o webservice da RDC
            IncProc(ZFJ->ZFJ_CGC + " - "  + ZFJ->ZFJ_RETORN)
         End Transaction
      EndIf                 
      
      TRBZFJ->(DBSkip())      
   
   EndDo 
   
   If ! _lScheduller
      _aCabecalho := {}
      aAdd(_aCabecalho,"Processado?" ) 
      aAdd(_aCabecalho,"CGC" ) 
      aAdd(_aCabecalho,"NOME") 
      aAdd(_aCabecalho,"FILIAL") 
      aAdd(_aCabecalho,"PRODUTO") 
      aAdd(_aCabecalho,"RETORNO") 
             
      _cTitulo := "Resultados da integração"
      
      If Len(_aresult) > 0
      	//ITListBox( _cTitAux , _aHeader    , _aCols     , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda                      ,_lHasOk,_bHeadClk,_aSX1)
			U_ITListBox( _cTitulo , _aCabecalho , _aresult   , .F.      , 4      ,          ,          ,         ,         ,     ,        ,          ,       ,         ,          ,           , {|C,L|U_AOMS083U(C,L)}        , .F.   ,         ,     )

      EndIf  
   Else
      u_itconout("[AOMS083] - Integração de envio de dados finalizada. Data: "+DToC(Date())+". Hora: "+Time())
   EndIf 
  
End Sequence

RestOrd(_aOrd)

Return   

/*
===============================================================================================================================
Programa----------: AOMS083Y
Autor-------------: Igor Melgaco
Data da Criacao---: 24/01/2024
Descrição---------: Com base nos estoques selecionados e integra via REST ao TMS.
Parametros--------: _lScheduller = .T. = Modo agendado (Scheduller) / .F. = Modo manual
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083Y(_lScheduller)             

Local _lItemSelect := .F.
Local _cEmpWebService := ""
Local _aOrd := SaveOrd({"ZFJ","ZFM"})
Local _cResposta := ""
Local _cSituacao := ""

Local oRest
Local nStatus   := 0
Local cError    := ""
Local cResult   := ""
Local cRegistro := ""
Local _aHeader  := {}
Local _cUrl     := ""
Local _cToken   := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")
Local _cParms   := "/Filial/SalvarEstoqueProdutoArmazem"
Local _aResult  := {}
Local _cCodEmpWS := ""

Default _lScheduller := .F.

Begin Sequence

   
   _cCodEmpWS := SuperGetMV('IT_EMPTMSM',.F.,"000005")

   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cCodEmpWS))
      _cUrl := AllTrim(ZFM->ZFM_LINK07)
   Else
      If _lExibeTela
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf
      
      Break   
   EndIf     
   
   //================================================================================
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   //================================================================================                    
   If !_lScheduller
      ProcRegua(8)     
      IncProc("Verificando itens selecionados...")      
   EndIf
   
   TRBZFJ->(DBGoTop())                                                                   
   While ! TRBZFJ->(Eof())
      If ! Empty(TRBZFJ->WK_OK)   
         _cEmpWebService := TRBZFJ->ZFJ_CODEMP                         
         _lItemSelect := .T. 
         Exit
      EndIf                 
      
      TRBZFJ->(DBSkip())
   EndDo 
   
   If ! _lItemSelect
      If !_lScheduller
         U_ITMsg("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> TMS.","Atenção",,1)
         Break   
      EndIf
   EndIf
      
   //================================================================================
   // Concatena os estoques selecionados e monta array de XML com os dados.
   //================================================================================                       
   If !_lScheduller
      IncProc("Montando dados de envio...")
   EndIf  

   TRBZFJ->(DBGoTop())                                                                   
   While ! TRBZFJ->(Eof())    
      If ! Empty(TRBZFJ->WK_OK)   
         ZFJ->(DBGoTo(TRBZFJ->WKRECNO))
        
         Begin Transaction

            If !Empty(AllTrim(ZFJ->ZFJ_FILTMS))
               
               _cBodyJson := '{'
               _cBodyJson += '"codigoFilial": "'+FWHttpEncode(AllTrim(ZFJ->ZFJ_FILTMS))+'",'
               _cBodyJson += '"codigoProduto": "'+FWHttpEncode(AllTrim(Subs(ZFJ->ZFJ_COD,1,11)))+'",'
               _cBodyJson += '"codigoFilialArmazem": "'+FWHttpEncode(AllTrim(ZFJ->ZFJ_CODARM))+'",'
               _cBodyJson += '"quantidadeProduto": '+FWHttpEncode(AllTrim(Str(ZFJ->ZFJ_QATU,13)))
               _cBodyJson += '}'

               _aHeader :={}

               oRest := FWRest():New(_cUrl)
               oRest:SetPath(_cParms)

               //Cabeçalho de requisição
               aAdd(_aHeader , "Content-Type: application/json")
               aAdd(_aHeader , "Authorization: Bearer Token" ) 
               aAdd(_aHeader , "Token: "+_cToken)

               oRest:SetPostParams(_cBodyJson)
               oRest:SetChkStatus(.F.)

               If oRest:Post(_aHeader)
                  cError := ""
                  nStatus := HTTPGetStatus(@cError)

                  If nStatus >= 200 .And. nStatus <= 299
                     If Empty(oRest:getResult())
                        cResult := "Falha de comunicação no retorno da requisição com o com o sistema TMS Emabarcador!" + CRLF + "Status " + AllTrim(Str(nStatus))
                        _lStatus := .F.
                        If !_lScheduller
                           U_ITMsg(cResult,"Atenção",,1)
                        Else
                           U_ItConout(cResult)
                        EndIf
                     Else
                        cResult := oRest:getResult()                

                        oJson := JsonObject():new()

                        cRegistro := oJson:fromJson(cResult)

                        If ValType(cRegistro) == "U"
                           U_ItConout("JsonObject populado com sucesso")
                        Else
                           U_ItConout("Falha ao popular JsonObject. Erro: " + cRegistro)
                        EndIf

                        _cResposta := '"status":'+oJson:GetJsonText("status")+ ', "mensagem":' + oJson:GetJsonText("mensagem") + ', "codigoMensagem":' + oJson:GetJsonText("codigoMensagem")  
                        _lStatus   := IIf(oJson:GetJsonText("status") == "false",.F.,.T.)

                        If !_lStatus .And. oJson:GetJsonText("mensagem") == "Produto não encontrado." //Trecho solicitado pelo Vanderlei
                           _lStatus := .T.
                        EndIf

                        If _lStatus
                           _cSituacao := "P"
                        Else
                           _cSituacao := "N"
                        EndIf

                        FreeObj(oJson)   
                     EndIf
                  Else

                     cResult := oRest:getResult() 

                     oJson := JsonObject():new()

                     cRegistro := oJson:fromJson(cResult)
                     
                     If ValType(cRegistro) == "U"
                        U_ItConout("[AOMS083] - JsonObject populado com sucesso")
                     Else
                        U_ItConout("[AOMS083] - Falha ao popular JsonObject. Erro: " + cRegistro)
                     EndIf

                     cRegistro := oJson:GetJsonText("erros") 

                     If cRegistro <> "null"
                        FWJsonDeserialize(cRegistro,@oErro)
                        cMsg := oErro[1]:MENSAGEM
                     Else
                        cMsg := cError
                     EndIf

                     cResult := "Falha na integração com o sistema TMS Emabarcador!" + CRLF + "Erro:" + cError  + CRLF + "Mensagem" + CRLF + cMsg // LimpaString(oErro[1]:MENSAGEM),"")

                     FreeObj(oJson) 

                     If _lScheduller
                        U_ItConout("[AOMS083] - "+ cResult)
                     EndIf

                     _cResposta := cResult
                     _cSituacao := "N"
                     _lStatus := .F.

                  EndIf
               Else
                  cResult := oRest:getResult() 

                  If ValType(cResult) == "U"
                     cResult := ""
                  EndIf
                  
                  cResult := "Falha de comunicação com o sistema TMS Emabarcador!" + CRLF + oRest:getLastError() + CRLF + cResult
                  
                  If _lScheduller
                     U_ItConout("[AOMS083] - "+cResult)
                  EndIf
                  
                  _cResposta := cResult
                  _cSituacao := "N"
                  _lStatus := .F.

               EndIf

               //grava resultado // sempre como processado
               ZFJ->(RecLock("ZFJ",.F.))
               ZFJ->ZFJ_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
               ZFJ->ZFJ_USUARI  := __cUserId
               ZFJ->ZFJ_DATAAL  := Date() // Grava data de alteração da tabela de muro.
               ZFJ->ZFJ_DTENV   := Date() // Grava data de envio para o RDC.
               ZFJ->ZFJ_HRENV   := Time() // Grava hora de envio para o RDC.
               ZFJ->ZFJ_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFJ,dizendo que deu certo ou não.
               ZFJ->ZFJ_XML     := _cBodyJson
               ZFJ->(MSUnLock())
            Else
               _cResposta := " Não há filial para transmissão. Campo ZFJ->ZFJ_FILTMS com conteudo vazio."
               _lStatus := .F.
            EndIf

            aAdd(_aResult,{_lStatus,ZFJ->ZFJ_CGC,ZFJ->ZFJ_NOME,ZFJ->ZFJ_FILTMS,AllTrim(Subs(ZFJ->ZFJ_COD,1,11)), _cResposta}) // adicona em um array para fazer um item list, exibir os resultados.
            Sleep(500) //Espera para não travar a comunicação com o webservice da RDC
            IncProc(ZFJ->ZFJ_CGC + " - "  + ZFJ->ZFJ_RETORN)

         End Transaction

      EndIf                 
      
      TRBZFJ->(DBSkip())      
   
   EndDo 
   
   If ! _lScheduller
      _aCabecalho := {}
      aAdd(_aCabecalho,"Processado?" ) 
      aAdd(_aCabecalho,"CGC" ) 
      aAdd(_aCabecalho,"NOME") 
      aAdd(_aCabecalho,"FILIAL") 
      aAdd(_aCabecalho,"PRODUTO") 
      aAdd(_aCabecalho,"RETORNO") 
             
      _cTitulo := "Resultados da integração"
      
      If Len(_aresult) > 0
			U_ITListBox( _cTitulo , _aCabecalho , _aresult   , .F.      , 4      ,  ,          ,         ,         ,     ,        ,          ,       ,         ,          ,           , {|C,L|U_AOMS083U(C,L)}        , .F.   ,         ,     )
      EndIf  
   Else
      u_itconout("[AOMS083] - Integração de envio de dados finalizada. Data: "+DToC(Date())+". Hora: "+Time())
   EndIf 
  
End Sequence

RestOrd(_aOrd)

Return   

/*
===============================================================================================================================
Programa----------: AOMS083X
Aut2or-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq
Retorno-----------: _cRet
===============================================================================================================================
*/  
User Function AOMS083X(_cArq)

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
Programa----------: AOMS083D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Grava em tabela temporária os dados a serem integrados via webservice.
Parametros--------: _lScheduller = .T. = Modo agendado (Scheduller) / .F. = Modo manual
Retorno-----------: _lRet
===============================================================================================================================
*/  
User Function AOMS083D(_lScheduller)

Local _lRet := .F.,_nI
Local _cMarkZFJ := GetMark() 
                    
Default _lScheduller := .F.

Begin Sequence      
   If ! _lScheduller
      ProcRegua(0)
   EndIf
   
   ZFJ->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC
   ZFJ->(DBSeek(xFilial("ZFJ")+"N"))
   While ! ZFJ->(Eof()) .And. ZFJ->(ZFJ_FILIAL+ZFJ_SITUAC) == xFilial("ZFJ")+"N"
      If ! _lScheduller
         IncProc("Lendo Prod.: "+ZFJ->ZFJ_COD)
      EndIf    
      TRBZFJ->(DBAPPEND())
      For _nI := 1 To ZFJ->(FCount())                  
          nPos:=TRBZFJ->(FieldPos(  ZFJ->( FieldName(_nI)) ))
          If nPos # 0
             TRBZFJ->(FieldPut(nPos,ZFJ->( FieldGet(_nI) ) )) 
          EndIf
      Next
      If _lScheduller         
         TRBZFJ->WK_OK := _cMarkZFJ
      EndIf 
      TRBZFJ->WKRECNO := ZFJ->(Recno())
      
      _lRet := .T.
      
      ZFJ->(DBSkip())
   EndDo
   TRBZFJ->(DBGoTop())

End Sequence

Return _lRet          

/*
===============================================================================================================================
Programa----------: AOMS083R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/09/2016
Descrição---------: Rotina de exibição da régua de processo e chamada da rotina de gravação dos dados de estoque para 
                    integração via webservice.                                     
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083R()

Begin Sequence              
   If ! U_ITMsg("Confirma a geração de dados dos estoques para integração via WebService?","Atenção",,2,2,2)
      Break
   EndIf
   
   Processa({|| U_AOMS083G(.F.) } , 'Aguarde!' , 'Gerando dados para integração WebService...')

End Sequence          

Return

/*
===============================================================================================================================
Programa----------: AOMS083G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/09/2016
Descrição---------: Rotina de leitura dos saldos em estoques (Tabela SB2) e gravação na tabela de integração webservice (ZFJ).   
Parametros--------: _lScheduller = .T. = Modo agendado (Scheduller) / .F. = Modo manual
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083G(_lScheduller)

Local _cCodEmpWS := SuperGetMV('IT_EMPWEBS',.F.,'000001')
Local _aOrd := SaveOrd({"ZFJ","SA2","SB1"})
Local _cQry
Local _cCod          
Local _nTamCod := TamSX3('ZFJ_COD')[1]
Local _nI
Local _nQtd
Local _cFilTer	:= AllTrim(SuperGetMV('IT_EST3FIL',.F.,'')) // Verifica parâmetro de configurações das Filiais que usam estoque em poder de terceiros
Local _cLocTer	:= AllTrim(SuperGetMV('IT_EST3LOC',.F.,'')) // Verifica parâmetro de configurações dos Armazéns que usam estoque em poder de terceiros
Local _nQtdSaldo   
Local _cTipoProduto := SuperGetMV('IT_TIPPRDS',.F.,'PA;UN;')
Local _cFilHabilit  := SuperGetMV('IT_FILINTW',.F.,'') // Filiais habilitadas na integracao Webservice Italac x RDC.
Local _cFilial := ""
Private aHeader, aCols

Default _lScheduller := .F.

Begin Sequence
   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFJ",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})

   If ! _lScheduller 
      ProcRegua(0)
      IncProc("Gerando dados...")      
      IncProc("Gerando dados...")      
   EndIf
       
   //===============================================================================
   // Seleciona os saldos dos estoques agrupados por filial e código de produto.
   //===============================================================================
   _cQry := " SELECT "
   _cQry += "      B2_FILIAL,"
   _cQry += "      B2_COD,"
   _cQry += "      B2_LOCAL,"
   _cQry += "      ZZM_CGC,"
   _cQry += "      B2_QNPT,"
   _cQry += "      (B2_QATU - B2_QEMP - B2_QEMPN - B2_RESERVA - B2_QACLASS) AS NQATU "
   _cQry += " FROM "+RetSqlName("SB2")+" SB2, "+ RetSqlName("ZZM")+" ZZM, " + RetSqlName("NNR")+" NNR, " + RetSqlName("SB1")+" SB1 " 
   _cQry += " WHERE SB2.D_E_L_E_T_ = ' ' "
   _cQry += "       AND ZZM.D_E_L_E_T_ <> '*'"
   _cQry += "       AND NNR.D_E_L_E_T_ = ' ' "
   _cQry += "       AND SB1.D_E_L_E_T_ = ' ' "
   _cQry += "       AND B2_FILIAL = ZZM_CODIGO "
   _cQry += "       AND B2_LOCAL = NNR_CODIGO "
   _cQry += "       AND NNR_I_ERDC = 'S' "
   _cQry += "       AND B1_COD = B2_COD "
   _cQry += "       AND B1_TIPO IN " + FormatIn(_cTipoProduto,";")
   _cQry += "       AND B2_FILIAL IN " + FormatIn(_cFilHabilit,";")
    
   _cQry := ChangeQuery(_cQry)

   If Select("TRBSB2") > 0
      TRBSB2->( DBCloseArea() )
   EndIf

   _cQry := ChangeQuery(_cQry)
   MPSysOpenQuery(_cQry,"TRBSB2")

   DBSelectArea("TRBSB2")

   nConta:=0
   COUNT To nConta
   If !_lScheduller 
      ProcRegua(nConta)
      IncProc("Gerando dados...")      
      IncProc("Gerando dados...")      
   EndIf

   //===============================================================================
   // Inicializa as variáveis de memória da tabela ZFJ
   //===============================================================================
   For _nI := 1 To Len(aHeader)
       If !AllTrim(aHeader[_nI,2]) $ "ZFJ_ALI_WT/ZFJ_REC_WT"
          &("M->"+aHeader[_nI,2] ) := CriaVar(aHeader[_nI,2])
       EndIf
   Next

   //===============================================================================
   // Leitura e gravação dos saldos dos Estoques na tabela de integração Webservice.
   //===============================================================================
   ZFJ->(DBSetOrder(5)) // ZFJ_FILIAL+ZFJ_COD+ZFJ_CODARM+ZFJ_CGC+ZFJ_SITUAC
   SB1->(DBSetOrder(1)) // B1_FILIAL  + B1_COD
   SA2->(DBSetOrder(3)) // A2_FILIAL  + A2_CGC
   
   TRBSB2->(DBGoTop())
   ZEL->(DBSetOrder(3))
   
   While ! TRBSB2->(Eof())   

      IncProc("Lendo Produto: "+TRBSB2->B2_COD)      

      If ZEL->(DBSeek(xFilial("ZEL")+TRBSB2->B2_FILIAL+TRBSB2->B2_LOCAL+Space(Len(ZEL->ZEL_OPERAD))+Space(Len(ZEL->ZEL_LOJAOP)) ))
         _cFilial := AllTrim(ZEL->ZEL_FILTMS)
      ElseIf ZEL->(DBSeek(xFilial("ZEL")+TRBSB2->B2_FILIAL+Space(Len(ZEL->ZEL_LOCAL))+Space(Len(ZEL->ZEL_OPERAD))+Space(Len(ZEL->ZEL_LOJAOP)) ))
         _cFilial := AllTrim(ZEL->ZEL_FILTMS)
      Else
         _cFilial := ""
      EndIf

      SB1->(DBSeek(xFilial("SB1")+TRBSB2->B2_COD))
      SA2->(DBSeek(xFilial("SA2")+TRBSB2->ZZM_CGC))
      _cCod := AllTrim(TRBSB2->B2_COD) + If(u_IT_TMS(ZEL->ZEL_CODIGO),"", Right(AllTrim(TRBSB2->ZZM_CGC),6))
      _cCod := PadR(_cCod,_nTamCod," ")   
      
      //===========================================================================================
      // Verifica se o saldo em poder de terceiros deve ser adicionado as quantidades.
      //===========================================================================================      
      _nQtdSaldo := TRBSB2->NQATU

      If _lScheduller
         cFilAnt := TRBSB2->B2_FILIAL //Considerar essa filial para buscar os parâmetros
         _cFilTer:= AllTrim(GetMV('IT_EST3FIL',.F.,'')) // Verifica parâmetro de configurações das Filiais que usam estoque em poder de terceiros
         _cLocTer:= AllTrim(GetMV('IT_EST3LOC',.F.,'')) // Verifica parâmetro de configurações dos Armazéns que usam estoque em poder de terceiros
      EndIf

      If TRBSB2->B2_FILIAL $ _cFilTer .And. TRBSB2->B2_LOCAL $ _cLocTer
         _nQtdSaldo := _nQtdSaldo + TRBSB2->B2_QNPT
      EndIf                                                                                                   

      _nQtd := _nQtdSaldo // TRBSB2->NQATU
      If Empty(SB1->B1_SEGUM) // Não há segunda unidade de medida
         _nQtd := _nQtdSaldo // TRBSB2->NQATU
      Else          
         If SB1->B1_TIPCONV == "D" // TIPO DE CONVERSAO DIVISÃO
            
            If ! Empty(SB1->B1_CONV)
		         _nQtd := _nQtdSaldo / SB1->B1_CONV // TRBSB2->NQATU / SB1->B1_CONV
            Else
               _nQtd := _nQtdSaldo / SB1->B1_I_FATCO // TRBSB2->NQATU / SB1->B1_CONV               
            EndIf   
         Else
		      _nQtd := _nQtdSaldo * SB1->B1_CONV // TRBSB2->NQATU * SB1->B1_CONV
         EndIf
      EndIf    
      //==========================================================

      If U_AOMS083S(TRBSB2->B2_FILIAL,_cCod,TRBSB2->B2_LOCAL,TRBSB2->ZZM_CGC,Int(_nQtd))   //_nQtdSaldo) //TRBSB2->NQATU)
         TRBSB2->(DBSkip())
         Loop
      EndIf

      //===========================================================================================
      // Grava em um array as filiais que serão integradas para o sistema RDC.
      //===========================================================================================
      If _lScheduller
         If aScan(_aFilProcess,TRBSB2->B2_FILIAL) == 0
            aAdd(_aFilProcess,TRBSB2->B2_FILIAL)
         EndIf
      EndIf
      
      If ZFJ->(DBSeek(TRBSB2->B2_FILIAL + _cCod + TRBSB2->B2_LOCAL + TRBSB2->ZZM_CGC + "N")) // ZFJ_FILIAL+ZFJ_COD+ZFJ_CODARM+ZFJ_CGC+ZFJ_SITUAC         
         //================================================================================
         // Se já existir um registro do estoque na tabela ZFJ que ainda não foi processado
         // apenas altera.
         //================================================================================
         ZFJ->(RecLock("ZFJ",.F.))
      Else
         ZFJ->(RecLock("ZFJ",.T.))
         ZFJ->ZFJ_FILIAL  := TRBSB2->B2_FILIAL //xFilial("ZFJ")
         ZFJ->ZFJ_DATA    := Date()
         ZFJ->ZFJ_CGC	  := TRBSB2->ZZM_CGC  // CNPJ Embarcador
         ZFJ->ZFJ_COD	  := _cCod            // Codigo Produto + Right(ZFJ_CGC,6)   

      EndIf
      
      For _nI := 1 To ZFJ->(FCount())    
          If ! AllTrim(ZFJ->(FieldName(_nI))) $ "ZFJ_FILIAL/ZFJ_DATA/ZFJ_CGC/ZFJ_COD/ZFJ_ALI_WT/ZFJ_REC_WT"
             &("ZFJ->"+ZFJ->(FieldName(_nI))) := &("M->"+ZFJ->(FieldName(_nI)))      
          EndIf
      Next             
      
      ZFJ->ZFJ_HORA    := Time()           // hora de inclusão na tabele de muro.    
      ZFJ->ZFJ_DATEST  := Date()           // Data Estoque
      ZFJ->ZFJ_QATU    := Int(_nQtd)       // Qtde Estoque // TRBSB2->NQATU    
      ZFJ->ZFJ_CODFOR  := SA2->A2_COD      // Cod.Fornece
      ZFJ->ZFJ_LOJA    := SA2->A2_LOJA     // Loja Fornece
      ZFJ->ZFJ_NOME    := SA2->A2_NOME     // Nome Fornece
      ZFJ->ZFJ_DESPR   := SB1->B1_DESC     // Desc.Produto
      ZFJ->ZFJ_SITUAC  := "N"              // Situação
      ZFJ->ZFJ_CODARM  := TRBSB2->B2_LOCAL // Codigo do Armazem
      ZFJ->ZFJ_CODEMP  := _cCodEmpWS  
      ZFJ->ZFJ_USUARI  := __cUserId
      ZFJ->ZFJ_DATAAL  := Date()
      ZFJ->ZFJ_FILTMS  := _cFilial
      ZFJ->(MSUnLock()) 
      
      TRBSB2->(DBSkip())
            
   EndDo
End Sequence  


If Select("TRBSB2") > 0
   TRBSB2->( DBCloseArea() )
EndIf

ZFJ->(DBGoTop())

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa----------: AOMS083N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/09/2016
Descrição---------: Com base em um endereço passado como parâmetro, retorna o numero deste endereço.
Parametros--------: _cEndereco = Endereço a ser lido e retornado o número.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083N(_cEndereco)

Local _cRet := "000000"
Local _nPos
Local _nI
Local _cPartNumero
Local _lTipoNumerico

Begin Sequence
   If Empty(_cEndereco)
      Break
   EndIf   
   
   _nPos := At(",",_cEndereco) // Retorna a posição da primeira virgula encontrada no endereço
   
   If _nPos == 0 // Se não existir virgula no endereço, não retorna nada.
      Break
   EndIf
   
   _cPartNumero := AllTrim(SubStr(_cEndereco,_nPos+1,Len(_cEndereco))) // Pega a parte do endereço do numero em diante.
   
   _lTipoNumerico := .T.   
   For _nI := 1 To Len(_cPartNumero) // Localiza a posição que termina o numero. 
       If ! SubStr(_cPartNumero,_nI,1) $ "0123456789"
          _lTipoNumerico := .F.
          Exit
       EndIf
       
       If SubStr(_cPartNumero,_nI,1) $ " ,.-/\" 
          _nPos := _nI - 1
          Exit
       Else
          _nPos := _nI
       EndIf
   Next     
   
   If _lTipoNumerico
      _cRet := SubStr(_cPartNumero,1,_nPos)  // Retorna apenas o numero do endereço.
   EndIf
   
End Sequence

If Empty(AllTrim(_cret))

   _cRet := "00000"
  
EndIf

Return _cRet

/*
===============================================================================================================================
Programa----------: AOMS083S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/05/2017
Descrição---------: Verifica se houve alterações nos saldos dos estoques antes de enviar para o sistema RDC.
Parametros--------: _cFilial,_cCodProduto,_cArmazem,_cCnpj,_nQtdAtu
Retorno-----------: .T. = Quantidades iguais, .F. = Quantidades diferentes.
===============================================================================================================================
*/  
User Function AOMS083S(_cFilial,_cCodProduto,_cArmazem,_cCnpj,_nQtdAtu)

Local _lRet := .T.
Local _cQry 
Local _nRegAtu := ZFJ->(Recno())

Begin Sequence
   _cQry := " SELECT MAX(ZFJ.R_E_C_N_O_) AS NRECNO "
   _cQry += " FROM "+RetSqlName("ZFJ")+" ZFJ "
   _cQry += " WHERE ZFJ.D_E_L_E_T_ = ' ' AND ZFJ_FILIAL = '"+_cFilial+"' AND ZFJ_COD = '"+_cCodProduto+"' "
   _cQry += " AND ZFJ_CODARM = '"+_cArmazem+"' AND ZFJ_CGC = '"+_cCnpj+"' AND (ZFJ_SITUAC = 'P' OR ZFJ_SITUAC = 'N') "
   
   _cQry := ChangeQuery(_cQry)

   If Select("QRYZFJ") > 0
      QRYZFJ->( DBCloseArea() )
   EndIf
    
   dbUseArea( .T., "TOPCONN", TcGenQry(,,_cQry), "QRYZFJ", .T., .F. )
      
   If QRYZFJ->(Eof()) .Or. QRYZFJ->(Bof())
      _lRet := .F.
      Break
   EndIf
   
   If QRYZFJ->NRECNO == 0
      _lRet := .F.
      Break
   EndIf
   
   ZFJ->(DBGoTo(QRYZFJ->NRECNO))
        
   If ZFJ->ZFJ_QATU <> _nQtdAtu
      _lRet := .F.
   EndIf
   
End Sequence

If Select("QRYZFJ") > 0
   QRYZFJ->( DBCloseArea() )
EndIf

ZFJ->(DBGoTo(_nRegAtu))

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS083T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 26/05/2017
Descrição---------: Rotina para rodar a integração de saldos em estoques de forma agendada(Scheduller).
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS083T()

Local _aStrucZFJ
Local _cMarcaZFJ //:= GetMark() 
Local _cfilial := "01"
Local _nI 
Private _aFilProcess := {}
Private _aFiliais := {}

Begin Sequence
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)

   //===========================================================================================
   // Preparando o ambiente com a filial da carga recebida
   //===========================================================================================
   RpcSetEnv("01", "01",,,,, {"SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})

   cFilAnt := _cfilial
   

   _cMarcaZFJ := GetMark()  
   
   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFJ",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
   
   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFJ := {}
   aAdd(_aStrucZFJ,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFJ,{"WKRECNO", "N", 10,0})
   For _nI := 1 To Len(aHeader)
       aAdd(_aStrucZFJ,{aHeader[_nI,2], aHeader[_nI,8], aHeader[_nI,4] ,aHeader[_nI,5]})
   Next   
   
   //===========================================================================================
   // Lê os saldos dos estoques e grava na tabela de muro ZFJ.
   //===========================================================================================
 U_AOMS083G(.T.) 
    
   //===================================================================================
   // Processo os dados pelas filiais carregadas com base nas filiais dos armazens.
   //===================================================================================
   For _nI := 1 To Len(_aFilProcess) 
       
       _cfilial := _aFilProcess[_nI] 


       //=====================================================================
       // Limpa o ambiente, liberando a licença e fechando as conexões
       //=====================================================================
       RpcClearEnv() 
       RpcSetType(2)
   
       //===========================================================================================
       // Preparando o ambiente com a filial da carga recebida
       //===========================================================================================
       RpcSetEnv("01", _cfilial,,,,, {"SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})

       cFilAnt := _cfilial                                                                          
       Private _lWsTms := If(cFilAnt $ SuperGetMV( 'IT_WEBETMS',.F.,"90") .And. !Empty(SuperGetMV( 'IT_LOEMTMS',.F.,"")) ,.T.,.F.)

       //================================================================================
       // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
       //================================================================================
       If Select("TRBZFJ") > 0
          TRBZFJ->( DBCloseArea() )
       EndIf

       //================================================================================
       // Abre o arquivo TRBZFQ criado dentro do protheus.
       //================================================================================
       _otemp := FWTemporaryTable():New( "TRBZFJ",  _aStrucZFJ )
   
       //================================================================================
       // Cria os indices para o arquivo.
       //================================================================================
       _otemp:AddIndex( "01", {"ZFJ_DATA"} )
       _otemp:Create()   
   
       DBSelectArea("TRBZFJ")
       
       //================================================================================
       // Carrega os dados da tabela ZFJ
       //================================================================================
       U_AOMS083D(.T.)          
   
       //===========================================================================================
       // Envia os XMLs de forma agendada (Scheduller)
       //===========================================================================================
       If _lWsTms
          U_AOMS083Y(.T.)
          U_AOMS083W(.T.)
       Else
          U_AOMS083W(.T.)
       EndIf
       
       //================================================================================
       // Exclui a tabela temporária.
       //================================================================================
       If Select("TRBZFJ") > 0
          TRBZFJ->( DBCloseArea() )
       EndIf                         
   Next

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZFJ") > 0
   TRBZFJ->(DBCloseArea())
EndIf
                 
//=====================================================================
// Limpa o ambiente, liberando a licença e fechando as conexões
//=====================================================================
RpcClearEnv() 

Return


/*
===============================================================================================================================
Programa----------: AOMS083U
Autor-------------: Igor Melgaco
Data da Criacao---: 24/01/2024
Descrição---------: Monta Legenda
Parametros--------: _aCol,_nLinha
Retorno-----------: cRet
===============================================================================================================================
*/
User Function AOMS083U(_aCol,_nLinha)

Local oOk := LoadBitmap( GetResources() , "BR_VERMELHO" )
Local oNo := LoadBitmap( GetResources() , "BR_VERDE" )

If _aCol[_nLinha,1]
   Return oOk
Else
   Return oNo
EndIf

Return oNo
