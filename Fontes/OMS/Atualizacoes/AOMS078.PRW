/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |09/09/2022| Chamado 41046. Alterar função utilizada para chamada via Scheduller para não consumir liçenças.
Julio Paz     |08/03/2024| Chamado 45006. Ajustar variável __cUserId em ambiente Scheduller p/ Protheus criar e preencher.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS078
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de integração e envio de dados dos Produtos via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078

Local _aCores := {}
Private aRotina := MenuDef()
Private cCadastro 
Private _lScheduler := ( Select("SM0") <= 0 )

Begin Sequence
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Abrindo o ambiente...' )
      RpcClearEnv()
      RPCSetType(2)
      
      RpcSetEnv( "01" , "01" ,,,"COM", "SCHEDULE_INT_CLI_RDC" , {'SB1','SB5','ZFI','SA2','ZP1'} )
      Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

      cUSUARIO := Space(06)+"Administrador  "
      cUserName:= "Schedure"
   
      U_AOMS078I()
   Else
      cCadastro := "Integração dos Dados dos Produtos Via Webservice: Italac <---> RDC"
   
      aAdd(_aCores,{"ZFI_SITUAC == 'N'" ,"BR_VERDE" })
      aAdd(_aCores,{"ZFI_SITUAC == 'P'" ,"BR_VERMELHO" })
      aAdd(_aCores,{"ZFI_SITUAC == 'R'" ,"BR_AMARELO" })

      DBSelectArea("ZFI")
      ZFI->(DBSetOrder(1)) 
      ZFI->(DBGoTop())
      MBrowse(6,1,22,75,"ZFI", , , , , , _aCores)  
   EndIf
End Sequence

Return    

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/11/2016
Descrição---------: Rotina de definição do menu da tela principal
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local _aRotina	:= {}

aAdd(_aRotina,{"Pesquisar" ,"AxPesqui" ,0,1})
aAdd(_aRotina,{"Visualizar","AxVisual",0,2})
aAdd(_aRotina,{"Integracao Webservice" ,"U_AOMS078I",0,4})
aAdd(_aRotina,{"Legenda"   ,"U_AOMS078L" ,0,3})

Return( _aRotina )

/*
===============================================================================================================================
Programa----------: AOMS078L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078L       

Local _aLegenda := {}

aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })

BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return

/*
===============================================================================================================================
Programa----------: AOMS078I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de integração e envio de dados dos Produtos via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078I()

Local _lRet := .F.
Local _aStrucZFI
Local _aOrd := SaveOrd({"SX3","ZFI"})
Local _aCmpZFI := {}
Local _aButtons := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgInt, _nI

Private _oMarkZFI, _cMarcaZFI := GetMark() 
Private aHeader, aCols, _otemp 
Private _nTot := 0

Begin Sequence
   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFI",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})

   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFI := ZFI->(DbStruct())
   aAdd(_aStrucZFI,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFI,{"WKRECNO", "N", 10,0})
      
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFI
   //================================================================================
   aAdd( _aCmpZFI , { "WK_OK"		,    , "Marca"                                          ,"@!"})
   
   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2]) $ "ZFI_FILIAL/ZFI_ALI_WT/ZFI_REC_WT"
          Loop
       EndIf
                          // X3_CAMPO             X3_TITULO          X3_PICTURE
       aAdd( _aCmpZFI , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
   Next

   //================================================================================
   // Abre o arquivo TRBZFH criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZFI",  _aStrucZFI )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZFI_DATA"} )
   _otemp:Create()
   
   //================================================================================
   // Tratamento para Schedule
   //================================================================================
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Consultando os dados para o processamento...' )

      _nTot := 0
      U_AOMS078D() // 'Lendo dados a serem integrados...'

      If _nTot = 0
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Não foram encontrados registros para processar.' )
      Else
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Processando '+ AllTrim(Str( _nTot , 6 )) +' registros...' )

         U_AOMS078W()  // 'Integrando Dados do Produto...' 
      EndIf
       
      Break

   EndIf
   
   aAdd(_aButtons,{"RESPONSA",{|| U_AOMS078M("T") },"Marc/Des","Marca/Desmarca Todos"})

   //================================================================================
   // Carrega os dados da tabela ZFI
   //================================================================================
   Processa( {|| U_AOMS078D()(  ) } , 'Aguarde!' , 'Lendo dados a serem integrados...' )

   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}
  
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgInt Title _cTitulo From 0,0 To 170,80 Of oMainWnd 
      
//      @ 05,10  Button _oButton  PROMPT "Marca/Desmarca Todos" Size 65,10   Of _oDlgInt Pixel Action U_AOMS078M("T")       
             
      _oMarkZFI := MsSelect():New("TRBZFI","WK_OK","",_aCmpZFI,@_lInverte, @_cMarcaZFI,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
      _oMarkZFI:bAval := {|| U_AOMS078M("P")}
      _oDlgInt:lMaximized:=.T.
      
   Activate MsDialog _oDlgInt On Init (EnchoiceBar(_oDlgInt,_bOk,_bCancel,,_aButtons), _oMarkZFI:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkZFI:oBrowse:Refresh() )
   
   If _lRet
      Processa( {|| U_AOMS078W(  ) } , 'Aguarde!' , 'Integrando Dados do produto...' )
   EndIf

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZFI") > 0
   TRBZFI->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa--------: AOMS078M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/09/2016
Descrição-------: Função para marcar e desmarcar todos Produtos que serão integrados via Webservice.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS078M(_cTipoMarca)

Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZFI->(Recno()) 

Begin Sequence          
   If Empty(TRBZFI->WK_OK )
      _cSimboloMarca := _cMarcaZFI
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZFI->(RecLock("TRBZFI",.F.))
      TRBZFI->WK_OK := _cSimboloMarca 
      TRBZFI->(MSUnLock())
   Else
      TRBZFI->(DBGoTop())
      While ! TRBZFI->(Eof())
         TRBZFI->(RecLock("TRBZFI",.F.))
         TRBZFI->WK_OK := _cSimboloMarca 
         TRBZFI->(MSUnLock()) 
         
         TRBZFI->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZFI->(DBGoTo(_nRegAtu)) 
_oMarkZFI:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS078W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Gera os dados XML com base nos Produtos selecionados e integra via webservice.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078W()             

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cDetXML := ""
Local _cRodXML := ""
Local _lItemSelect := .F.
Local _cEmpWebService := ""
Local _aOrd := SaveOrd({"ZFI","ZFM"})
Local _cXML 
Local _cResult := ""
Local _cOk

Begin Sequence
   //================================================================================
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   //================================================================================   
   If _lScheduler 
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Verificando itens selecionados...' )
   Else        
      ProcRegua(8)
      IncProc("Verificando itens selecionados...")
   EndIf
   
   TRBZFI->(DBGoTop())                                                                   
   While ! TRBZFI->(Eof())
      If ! Empty(TRBZFI->WK_OK)   
         _cEmpWebService := TRBZFI->ZFI_CODEMP                         
         _lItemSelect := .T. 
         Exit
      EndIf                 
      
      TRBZFI->(DBSkip())
   EndDo 
   
   If ! _lItemSelect
      If _lScheduler
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.' )
      Else
         U_ITMsg("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.","Atenção",,1)
      EndIf
      
      Break   
   EndIf              
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Identificando diretório dos XML.' )
   Else
      IncProc("Identificando diretório dos XML...")                    
   EndIf
   
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK01) 
   Else
      If _lScheduler
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Empresa WebService para envio dos dados não localizada.' )
      Else
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf
      
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lScheduler
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: ' + AllTrim(ZFM->ZFM_NOME) + "." )
      Else
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
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Lendo arquivo XML Modelo de Cabeçalho. ' )
   Else
      IncProc("Lendo arquivo XML Modelo de Cabeçalho...")                      
   EndIf
   
   _cCabXML := U_AOMS078X(_cDirXML+"Cab_EntradaProduto.txt") 
   If Empty(_cCabXML)
      If _lScheduler
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Erro na leitura do arquivo XML modelo do cabeçalho de entrada produto. ' )
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do cabeçalho de entrada produto. ","Atenção",,1)
      EndIf
      
      Break
   EndIf
   
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Lendo arquivo XML Modelo de Detalhe. ' )
   Else
      IncProc("Lendo arquivo XML Modelo de Detalhe...")
   EndIf
   
   _cDetXML := U_AOMS078X(_cDirXML+"Det_EntradaProduto.txt")
   
   If Empty(_cDetXML)
      If _lScheduler
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Erro na leitura do arquivo XML modelo do detalhe de entrada produto. ' )
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe de entrada produto.","Atenção",,1)
      EndIf
      
      Break
   EndIf            
   
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Lendo arquivo XML Modelo de Rodapé. ' )
   Else
      IncProc("Lendo arquivo XML Modelo de Rodapé...")
   EndIf
   
   _cRodXML := U_AOMS078X(_cDirXML+"Rodape_EntradaProduto.txt")
   If Empty(_cRodXML)
      If _lScheduler
         U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Erro na leitura do arquivo XML modelo do rodapé de entrada produto.' )
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do rodapé de entrada produto.","Atenção",,1)
      EndIf
      
      Break
   EndIf
  
   //================================================================================
   // Concatena os clientes selecionados e monta array de XML com os dados.
   //================================================================================                       
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Montando dados de envio.' )
   Else
      IncProc("Montando dados de envio...")
   EndIf

   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.    
   oWsdl:nTimeout := 10          // Timeout de 10 segundos
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo
                         
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
   oWsdl:SetOperation( "EnviaProduto") // Define qual operação será realizada.
   
   _aresult := {}
   
   TRBZFI->(DBGoTop())                                                                   
   While ! TRBZFI->(Eof())
    
      If ! Empty(TRBZFI->WK_OK)        
         ZFI->(DBGoTo(TRBZFI->WKRECNO))
        
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
 		
 		    // Grava Resultado sempre como processado
            ZFI->(RecLock("ZFI",.F.))
            ZFI->ZFI_SITUAC  := IIf(_cOk, "P", "N")
            If Type("__cUserId") = "C" .And. ! Empty(__cUserId)
               ZFI->ZFI_USUARI  := __cUserId
            EndIf 
            ZFI->ZFI_DATAAL  := Date()
            ZFI->ZFI_RETORN  := AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFI,dizendo que deu certo ou não.   
            ZFI->ZFI_XML     := _cXML
            ZFI->(MSUnLock())
        
            aAdd(_aResult,{ZFI->ZFI_CGC,ZFI->ZFI_NOME,ZFI->ZFI_COD,ZFI->ZFI_DESC,ZFI->ZFI_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
            Sleep(500) //Espera para não travar a comunicação com o webservice da RDC
            
            If _lScheduler
               U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - Integrado: ' + ZFI->ZFI_CGC + " - "  + ZFI->ZFI_RETORN )      
            Else
               IncProc(ZFI->ZFI_CGC + " - "  + ZFI->ZFI_RETORN)
            EndIf
            
         End Transaction
      EndIf                 
      
      TRBZFI->(DBSkip())
   EndDo 
   
   If _lScheduler
      U_ItConOut( '[AOMS078] - '+ DToC(Date()) +' - '+ Time() +'] - A integração dos dados foi finalizada. ' ) 
   Else
      _aCabecalho := {}
      aAdd(_aCabecalho,"CGC" ) 
      aAdd(_aCabecalho,"NOME") 
      aAdd(_aCabecalho,"COD.PROD") 
      aAdd(_aCabecalho,"DESCR.PROD") 
      aAdd(_aCabecalho,"RETORNO") 
             
      _cTitulo := "Resultados da integração"
      
      If Len(_aresult) > 0
      
  	     u_ITListBox( _cTitulo , _aCabecalho , _aresult  ) // Exibe uma tela de resultado.
  	  
      EndIf
   EndIf
    
End Sequence

RestOrd(_aOrd)

Return   

/*
===============================================================================================================================
Programa----------: AOMS078X
Aut2or-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078X(_cArq)

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
Programa----------: AOMS078D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Grava em tabela temporária os dados a serem integrados via webservice.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078D()

Local _lRet := .F.,_nI

Begin Sequence
   If ! _lScheduler
      ProcRegua(0)
   EndIf
   
   _nTot := 0
   
   ZFI->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC
   ZFI->(DBSeek(xFilial("ZFI")+"N"))
   While ! ZFI->(Eof()) .And. ZFI->(ZFI_FILIAL+ZFI_SITUAC) == xFilial("ZFI")+"N"
      _nTot += 1
      
      If ! _lScheduler
         IncProc("Lendo registros...")
      EndIf
      
      TRBZFI->(DBAPPEND())
      For _nI := 1 To ZFI->(FCount())                  
          nPos:=TRBZFI->(FieldPos( ZFI->( FieldName(_nI)) ))
          If nPos # 0
             TRBZFI->(FieldPut(nPos,  ZFI->( FieldGet(_nI) ) )) 
          EndIf
      Next                         
      
      If _lScheduler
         TRBZFI->WK_OK := _cMarcaZFI
      EndIf
         
      TRBZFI->WKRECNO := ZFI->(Recno())
      _lRet := .T.
      
      ZFI->(DBSkip())
   EndDo
   TRBZFI->(DBGoTop())

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS078G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/09/2016
Descrição---------: Chamada da rotina de inclusão e alteração dos dados do cadastro de Produtos e Cadastro de Complementos de
                    Produtos, grava os dados do produto(SB1) e complementos do Produto (SB5), na tabela de integração 
                    webservice (ZFI).                    
Parametros--------: _cCadastro == "SB1" = Cadastro de Produtos
                                  "SB5" = Complemento do produto.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS078G(_cCadastro)

Local _cCodEmpWS := SuperGetMV('IT_EMPWEBS',.F.,'000001')
Local _aOrd := SaveOrd({"SX3","ZFI","ZZM","SA2","SB1"})
Local _nEmpMax, _cProduto, _nQtdLastro,_nI
Local _cTipoProdutos := SuperGetMV('IT_TIPOPRO',.F.,"PA#UN#")
Local _cPesoVar := "N", _nPesoMin := 0, _nPesoMax := 0

Private aHeader, aCols

Begin Sequence     
   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFI",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})

   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2]) $ "ZFI_ALI_WT/ZFI_REC_WT"
          Loop
       EndIf
       
       &("M->"+aHeader[_nI,2]) := CriaVar(aHeader[_nI,2])
   Next

   SA2->(DBSetOrder(3))
   SB5->(DBSetOrder(1))
   SB1->(DBSetOrder(1))
   
   _nEmpMax := 0     
   _nQtdLastro := 0
   If _cCadastro == "SB1"
      _cProduto := SB1->B1_COD
      If SB5->(DBSeek(xFilial("SB5")+SB1->B1_COD))
         _nEmpMax := SB5->B5_EMPMAX
         _nQtdLastro := SB5->B5_I_QTDLT
      EndIf
   Else
      _cProduto := SB5->B5_COD                    
      SB1->(DBSeek(xFilial("SB1")+SB5->B5_COD))
      _nEmpMax := SB5->B5_EMPMAX
      _nQtdLastro := SB5->B5_I_QTDLT
   EndIf
   
   //If SB1->B1_TIPO <> "PA" .Or. SB1->B1_MSBLQL <> "2"
   If !(SB1->B1_TIPO $ _cTipoProdutos) .Or. SB1->B1_MSBLQL <> "2"
      Break
   EndIf                  

   ZZM->(DBGoTop())      

   While ! ZZM->(Eof())
      If ! SA2->(DBSeek(xFilial("SA2")+ZZM->ZZM_CGC))
         ZZM->(DBSkip())
         Loop
      EndIf
      
      ZFI->(DBSetOrder(3)) 
      If ZFI->(DBSeek(xFilial("ZFI")+_cProduto+SA2->A2_CGC+"N"))
         ZFI->(RecLock("ZFI",.F.))
      Else
         ZFI->(RecLock("ZFI",.T.))    
      EndIf
      
      For _nI := 1 To ZFI->(FCount())
          &("ZFI->"+ZFI->(FieldName(_nI))) := &("M->"+ZFI->(FieldName(_nI)))      
      Next             

      _nPesoMin := 0
      _nPesoMax := 0 

      If SB1->B1_I_PCCX > 0 // b1_i_pccx  // SB1->B1_I_FTMIN > 0 .Or. SB1->B1_I_FTMAX > 0
         _cPesoVar := "S"
         _nPesoMin := SB1->B1_I_FTMIN
         _nPesoMax := SB1->B1_I_FTMAX         
      Else
         _cPesoVar := "N"
      EndIf 

      ZFI->ZFI_FILIAL   := xFilial("ZFI")
      ZFI->ZFI_DATA     := Date() 	    
      ZFI->ZFI_HORA     := Time() // Grava a hora de inclusão do registro na tabela de muro.
      ZFI->ZFI_CGC      := SA2->A2_CGC
      ZFI->ZFI_COD      := SB1->B1_COD
      ZFI->ZFI_CODIDN   := AllTrim(SB1->B1_COD)+Right(AllTrim(SA2->A2_CGC),6)    
      ZFI->ZFI_DESC     := SB1->B1_DESC   
      ZFI->ZFI_DESCPR   := SB1->B1_DESC   
      ZFI->ZFI_POSIPI   := SB1->B1_POSIPI
      ZFI->ZFI_UM	    := If(SB1->B1_UM <> "CX","1","2")
      ZFI->ZFI_SEGUM	:= If(SB1->B1_SEGUM <> "CX","1","2")
      ZFI->ZFI_EMPMAX	:= If(_nEmpMax == 0,1,_nEmpMax)
      ZFI->ZFI_QTDEL    := If(_nQtdLastro == 0,1,_nQtdLastro)
      ZFI->ZFI_EMB	    := "1" // SB1->B1_SEGUM
      ZFI->ZFI_SUBEMB	:= "1" // SB1->B1_UM
      ZFI->ZFI_PESO	    := SB1->B1_PESBRU   // SB1->B1_PESO
      ZFI->ZFI_CODFOR	:= SA2->A2_COD
      ZFI->ZFI_LOJA	    := SA2->A2_LOJA
      ZFI->ZFI_NOME	    := SA2->A2_NOME
      If Type("__cUserId") = "C" .And. ! Empty(__cUserId)
         ZFI->ZFI_USUARI	:= __cUserId
      EndIf 
      ZFI->ZFI_DATAAL	:= Date()
      ZFI->ZFI_SITUAC	:= "N"
      ZFI->ZFI_CODEMP   := _cCodEmpWS
      ZFI->ZFI_PESVAR   := _cPesoVar
      ZFI->ZFI_PESMIN   := _nPesoMin // SB1->B1_I_FTMIN
      ZFI->ZFI_PESMAX   := _nPesoMax // SB1->B1_I_FTMAX
      
      ZFI->(MSUnLock())
   
      ZZM->(DBSkip())
   EndDo
End Sequence  

RestOrd(_aOrd)

Return
