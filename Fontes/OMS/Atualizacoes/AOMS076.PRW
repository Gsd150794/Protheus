/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |16/10/2023| Chamado 45259. Correção do error.log: array out of bounds.
Julio Paz     |08/03/2024| Chamado 45006. Ajustar variável __cUserId em ambiente Scheduller p/ Protheus criar e preencher.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "APWEBSRV.CH"

/*
===============================================================================================================================
Programa----------: AOMS076
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de integração e envio de dados dos clientes via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076()

Local _aCores := {}
Private aRotina := {}
Private cCadastro 
Private _lScheduler:= ( Select("SM0") <= 0 )

If _lScheduler

   u_itconout( '[AOMS076] - '+ DToC(Date()) +' - '+ Time() +'] - Abrindo o ambiente...' )

   RPCSetType(3)
   RpcSetEnv( "01" , "01" ,,,"COM", "SCHEDULE_INT_CLI_RDC" , {'SC5','SC6','ZFH','SA1','ZP1'} )
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

   cUSUARIO := Space(06)+"Administrador  " // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
   cUserName:= "Schedure"                  // Quando o ambiente é iniciado. O Protheus já está criando estas variáveis com usuário.
  
   U_AOMS076I()

Else

   cCadastro := "Integração dos Dados dos Clientes Via Webservice: Italac <---> RDC"
   aAdd(aRotina,{"Pesquisar" ,"AxPesqui" ,0,1})
   aAdd(aRotina,{"Visualizar","AxVisual",0,2})
   aAdd(aRotina,{"Integracao Webservice" ,"U_AOMS076I",0,4})
   aAdd(aRotina,{"Legenda"   ,"U_AOMS076L" ,0,3})
   
   aAdd(_aCores,{"ZFH_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZFH_SITUAC == 'P'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZFH_SITUAC == 'R'" ,"BR_AMARELO" })

   DBSelectArea("ZFH")
   ZFH->(DBSetOrder(1)) 
   ZFH->(DBGoTop())
   MBrowse(6,1,22,75,"ZFH", , , , , , _aCores)
   
EndIf

Return    

/*
===============================================================================================================================
Programa----------: AOMS076L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076L       

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
Programa----------: AOMS076I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Rotina de integração e envio de dados dos clientes via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076I()

Local _lRet := .F.
Local _aStrucZFH
Local _aOrd := SaveOrd({"ZFH"})
Local _aCmpZFH := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgInt, _nI, _aButtons:={}

Private _oMarkZFH, _cMarcaZFH := GetMark() 
Private aHeader, aCols, _otemp 

//Log de utilização
u_itlogacs()

Begin Sequence  
   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFH",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
   
   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFH := ZFH->(DbStruct())
   aAdd(_aStrucZFH,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFH,{"WKRECNO", "N", 10,0})
         
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFH 
   //================================================================================
   aAdd( _aCmpZFH , { "WK_OK"		,    , "Marca"                                          ,"@!"})
   
   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2]) $ "ZFH_FILIAL/ZFH_ALI_WT/ZFH_REC_WT"
          Loop
       EndIf
                          // X3_CAMPO             X3_TITULO          X3_PICTURE
       aAdd( _aCmpZFH , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
   Next

   //================================================================================
   // Abre o arquivo TRBZFH criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZFH",  _aStrucZFH )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZFH_DATA"} )
   _otemp:Create()

   //================================================================================
   // Tratamento para Schedule
   //================================================================================
   If _lScheduler

       u_itconout( '[AOMS076] - '+ DToC(Date()) +' - '+ Time() +'] - Consultando os dados para o processamento...' )

       _nTot := 0
       U_AOMS076D()//'Lendo dados a serem integrados...'

       If _nTot = 0

          u_itconout( '[AOMS076] - '+ DToC(Date()) +' - '+ Time() +'] - Não foram encontrados registros para processar.' )

       Else

          u_itconout( '[AOMS076] - '+ DToC(Date()) +' - '+ Time() +'] - Processando '+ AllTrim(Str( _nTot , 6 )) +' registros...' )

          U_AOMS076W()//'Integrando Dados do Cliente...' )

       EndIf
       
       Break

   EndIf
                                        
   aAdd(_aButtons,{"RESPONSA",{|| U_AOMS076M("T") },"Marc/Des","Marca/Desmarca Todos"})

   //================================================================================
   // Carrega os dados da tabela ZFH
   //================================================================================
   Processa( {|| U_AOMS076D() } , 'Aguarde!' , 'Lendo dados a serem integrados...' )

   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}
  
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgInt Title _cTitulo From 0,0 To 170,80 Of oMainWnd 
         
//      @ 05,10  Button "Marca/Desmarca Todos" Size 65,10   Of _oDlgInt Pixel Action U_AOMS076M("T")       
             
      _oMarkZFH := MsSelect():New("TRBZFH","WK_OK","",_aCmpZFH,@_lInverte, @_cMarcaZFH,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
      _oMarkZFH:bAval := {|| U_AOMS076M("P")}
      _oDlgInt:lMaximized:=.T.
      
   Activate MsDialog _oDlgInt On Init (EnchoiceBar(_oDlgInt,_bOk,_bCancel,,_aButtons), _oMarkZFH:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkZFH:oBrowse:Refresh() )
   
   If _lRet
      Processa( {|| U_AOMS076W(  ) } , 'Aguarde!' , 'Integrando Dados do Cliente...' )
   EndIf

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZFH") > 0
   TRBZFH->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa--------: AOMS076M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/09/2016
Descrição-------: Função para marcar e desmarcar todos clientes que serão integrados via Webservice.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS076M(_cTipoMarca)

Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZFH->(Recno()) 

Begin Sequence          
   If Empty(TRBZFH->WK_OK )
      _cSimboloMarca := _cMarcaZFH
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZFH->(RecLock("TRBZFH",.F.))
      TRBZFH->WK_OK := _cSimboloMarca 
      TRBZFH->(MSUnLock())
   Else
      TRBZFH->(DBGoTop())
      While ! TRBZFH->(Eof())
         TRBZFH->(RecLock("TRBZFH",.F.))
         TRBZFH->WK_OK := _cSimboloMarca 
         TRBZFH->(MSUnLock()) 
         
         TRBZFH->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZFH->(DBGoTo(_nRegAtu)) 
_oMarkZFH:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS076W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Gera os dados XML com base nos clientes selecionados e integra via webservice.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076W

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cDetXML := ""
Local _cRodXML := ""
Local _lItemSelect := .F.
Local _cEmpWebService := ""
Local _aOrd := SaveOrd({"ZFH","ZFM","SA1"})
Local _cXML 
Local _cResult := ""
Local _cResposta, _cSituacao

Begin Sequence
   //================================================================================
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   //================================================================================                    
If !_lScheduler

   ProcRegua(8)
   IncProc("Verificando itens selecionados...")
   TRBZFH->(DBGoTop())                                                                   
   While ! TRBZFH->(Eof())
      If ! Empty(TRBZFH->WK_OK)   
         _cEmpWebService := TRBZFH->ZFH_CODEMP                         
         _lItemSelect := .T. 
         Exit
      EndIf                 
      
      TRBZFH->(DBSkip())
   EndDo 
   
   If ! _lItemSelect
      U_ITMsg("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.","Atenção",,1)
      Break   
   EndIf              

   IncProc("Identificando diretório dos XML...")                    

Else

   TRBZFH->(DBGoTop())//Todos estão marcados
  _cEmpWebService := TRBZFH->ZFH_CODEMP                         

EndIf
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirXML := ZFM->ZFM_LOCXML 
      _cLink   := AllTrim(ZFM->ZFM_LINK01)
   Else
      If _lScheduler
         u_itconout( "[AOMS076] - Empresa WebService para envio dos dados não localizada.")
      Else
         U_ITMsg("Empresa WebService para envio dos dados não localizada.","Atenção",,1)
      EndIf
      Break   
   EndIf                        
   
   If Empty(_cDirXML) .Or. Empty(_cLink)
      If _lScheduler
         u_itconout("[AOMS076] - Diretório dos arquivos XML modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".")
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
   If !_lScheduler
      IncProc("Lendo arquivo XML Modelo de Cabeçalho...")    
   Else
      u_itconout("[AOMS076] - Lendo arquivo XML Modelo de Cabeçalho.")                  
   EndIf
   _cCabXML := U_AOMS076X(_cDirXML+"Cab_EntradaCliente.txt") 
   If Empty(_cCabXML)
      If _lScheduler
         u_itconout("[AOMS076] - Erro na leitura do arquivo XML modelo do cabeçalho de entrada cliente.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do cabeçalho de entrada cliente. ","Atenção",,1)
      EndIf
      Break
   EndIf
   
   If !_lScheduler
      IncProc("Lendo arquivo XML Modelo de Detalhe...")
   Else
      u_itconout("[AOMS076] - Lendo arquivo XML Modelo de Detalhe.")
   EndIf
   
   _cDetXML := U_AOMS076X(_cDirXML+"Det_EntradaCliente.txt")
   If Empty(_cDetXML)
      If _lScheduler
         u_itconout("[AOMS076] - Erro na leitura do arquivo XML modelo do detalhe de entrada cliente.")
      Else
          U_ITMsg("Erro na leitura do arquivo XML modelo do detalhe de entrada cliente.","Atenção",,1)
      EndIf
      Break
   EndIf            
   
   If !_lScheduler
      IncProc("Lendo arquivo XML Modelo de Rodapé...")
   Else
      u_itconout("[AOMS076] - Lendo arquivo XML Modelo de Rodapé.")
   EndIf
   
   _cRodXML := U_AOMS076X(_cDirXML+"Rodape_EntradaCliente.txt")
   If Empty(_cRodXML)
      If _lScheduler
         u_itconout("[AOMS076] - Erro na leitura do arquivo XML modelo do rodapé de entrada cliente.")
      Else
         U_ITMsg("Erro na leitura do arquivo XML modelo do rodapé de entrada cliente.","Atenção",,1)
      EndIf
      Break
   EndIf
   
   //================================================================================
   // Concatena os clientes selecionados e monta array de XML com os dados.
   //================================================================================                       
   If !_lScheduler
      IncProc("Montando dados de envio...")
   Else
      u_itconout("[AOMS076] - Montando dados de envio.")
   EndIf
   
   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
   oWsdl:nTimeout := 30          // Timeout de 10 segundos
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                               
   
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
      
   oWsdl:SetOperation( "EnviaCliente") // Define qual operação será realizada.
   
   _aresult := {}
                  
   TRBZFH->(DBGoTop())                                                                   
   While ! TRBZFH->(Eof())
          
      If ! Empty(TRBZFH->WK_OK)   
         ZFH->(DBGoTo(TRBZFH->WKRECNO))
         
         If Empty(ZFH->ZFH_COD)
            If ZFH->ZFH_RECSA1 > 0
               SA1->(DBGoTo(ZFH->ZFH_RECSA1))
               If Empty(SA1->A1_I_DNRDC)
                  SA1->(RecLock("SA1",.F.)) 
                  SA1->A1_I_DNRDC := U_AOMS076E() // Grava o próximo codigo DNRDC na tabala SA1.
                  SA1->(MSUnLock()) 
                                        
                  ZFH->(RecLock("ZFH",.F.))
                  ZFH->ZFH_COD := SA1->A1_I_DNRDC // Grava o código DN da tabela SA1 na tabela ZFH. 
                  ZFH->(MSUnLock())                  
               EndIf   
            EndIf
         EndIf
         
         Begin Transaction
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
               _cSituacao := "N" // "R" 
            ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta)       	
 		       _cSituacao := "N" // "R"
 		    EndIf            	
 		
 		    //grava resultado // sempre como processado
            ZFH->(RecLock("ZFH",.F.))
            ZFH->ZFH_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
            If Type("__cUserId") = "C" .And. ! Empty(__cUserId)
               ZFH->ZFH_USUARI  := __cUserId
            EndIf 
            ZFH->ZFH_DATAAL  := Date()
            ZFH->ZFH_RETORN  := StrTran(_cResult,Chr(10)," ") // grava o resultado da integração na tabela ZFH,dizendo que deu certo ou não.
            ZFH->ZFH_XML     := _cXML
            ZFH->(MSUnLock())
        
            aAdd(_aresult,{ZFH->ZFH_CGC,ZFH->ZFH_NOME,ZFH->ZFH_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
            Sleep(100) //Espera para não travar a comunicação com o webservice da RDC
            If !_lScheduler
               IncProc(ZFH->ZFH_CGC + " - "  + ZFH->ZFH_RETORN)
            Else
               u_itconout("[AOMS076] - Integrado: " + ZFH->ZFH_CGC + " - "  + ZFH->ZFH_RETORN)
            EndIf

         End Transaction
      EndIf       
                
      TRBZFH->(DBSkip())
         
   EndDo 
   
   If _lScheduler
      u_itconout("[AOMS076] - Integração finalizada. ")
   Else
      _aCabecalho := {}
      aAdd(_aCabecalho,"CGC" ) 
      aAdd(_aCabecalho,"NOME") 
      aAdd(_aCabecalho,"RETORNO") 
             
      _cTitulo := "Resultados da integração"
      
      If Len(_aresult) > 0 // .And. !_lScheduler
      
  	     u_ITListBox( _cTitulo , _aCabecalho , _aresult , /*_lMaxSiz*/ , /*_nTipo*/ ,  ) // Exibe uma tela de resultado.
  	  
  	  EndIf
   EndIf 
   
End Sequence

RestOrd(_aOrd)

Return   

/*
===============================================================================================================================
Programa----------: AOMS076X
Aut2or-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076X(_cArq)

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
Programa----------: AOMS076W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/09/2016
Descrição---------: Grava em tabela temporária os dados a serem integrados via webservice.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076D()

Local _lRet := .F.,_nI
_nTot := 0

Begin Sequence
   
   If !_lScheduler
      ProcRegua(0)
   EndIf
   ZFH->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC
   ZFH->(DBSeek(xFilial("ZFH")+"N"))
   While ! ZFH->(Eof()) .And. ZFH->(ZFH_FILIAL+ZFH_SITUAC) == xFilial("ZFH")+"N"
      If !_lScheduler
         IncProc("Lendo Cliente: "+ZFH->ZFH_COD)
      EndIf
      TRBZFH->(DBAPPEND())
      For _nI := 1 To ZFH->(FCount())                  
          nPos:=TRBZFH->(FieldPos( ZFH->( FieldName(_nI)) ))
          If nPos # 0
             TRBZFH->(FieldPut(nPos,  ZFH->( FieldGet(_nI) ) )) 
          EndIf
      Next
      If _lScheduler
         TRBZFH->WK_OK := _cMarcaZFH
      EndIf
      TRBZFH->WKRECNO := ZFH->(Recno())
      _nTot++
      _lRet := .T.
      ZFH->(DBSkip())
   EndDo
   TRBZFH->(DBGoTop())

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS076G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/09/2016
Descrição---------: Chamada da rotina de inclusão e alteração dos dados do cadastro de clientes, grava os dados do cliente(SA1) 
                    na tabela de integração webservice (ZFH).                    
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076G

Local _cCodEmpWS := SuperGetMV('IT_EMPWEBS',.F.,'000001')
Local _aOrd := SaveOrd({"SX3","ZFH"})
Local _aUF , _nI  , nPosUF
Local _cEndereco, _cNumero, _cComplemento

Private aHeader, aCols

Begin Sequence     

   If SA1->A1_PESSOA = "F"
      SRA->( DBSetOrder(20) ) //RA_CIC+RA_FILIAL+RA_MAT
	  If SRA->( DBSeek( AllTrim(SA1->A1_CGC) ) ) .And. SRA->RA_SITFOLH <> "D"
         Break//não envia funcionarios que não foram demitidos
      EndIf
   EndIf

   //================================================================================
   // Monta array dos estados
   //================================================================================
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

   //============================================================================
   //Montagem do aheader                                                        
   //=============================================================================
   aHeader := {}
   aCols   := {}
   FillGetDados(1,"ZFH",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
    
   For _nI := 1 To Len(aHeader)
       If AllTrim(aHeader[_nI,2]) $ "ZFH_ALI_WT/ZFH_REC_WT"
          Loop
       EndIf
   
       &("M->"+aHeader[_nI,2]) := CriaVar(aHeader[_nI,2])
   
   Next 
   
   ZFH->(DBSetOrder(3)) 
   If ZFH->(DBSeek(xFilial("ZFH")+SA1->A1_CGC+"N"))
      //================================================================================
      // Se já existir um registro do cliente na tabela ZFH que ainda não foi processado
      // apenas altera.
      //================================================================================
      ZFH->(RecLock("ZFH",.F.))
   Else
      ZFH->(RecLock("ZFH",.T.))    
   EndIf
      
   For _nI := 1 To ZFH->(FCount())
       &("ZFH->"+ZFH->(FieldName(_nI))) := &("M->"+ZFH->(FieldName(_nI)))      
   Next 
    
   //================================================================================                     
   // Os endereços de clientes abaixo estão com o nome da rua separada do numero,
   // e do complemento.                                                                               
   //================================================================================
   _cEndereco    := SA1->A1_I_LOGRA //A1_I_END
   _cNumero      := SA1->A1_I_NUMER //A1_I_NUM 
   _cComplemento := SA1->A1_COMPLEM 
   
   If !Empty(_cEndereco) .And. Empty(_cNumero)
      _cNumero := U_AOMS076N(_cEndereco)
   EndIf
      
   If Empty(_cEndereco)
      _cEndereco    := SA1->A1_END
      _cNumero      := U_AOMS076N(SA1->A1_END)
      _cComplemento := SA1->A1_COMPLEM 
   EndIf          
   
   If Empty(_cNumero)
      _cNumero := "000000" //U_AOMS076N(SA1->A1_END)
   EndIf
       
   ZFH->ZFH_FILIAL  := xFilial("ZFH")
   ZFH->ZFH_DATA    := Date()
   ZFH->ZFH_HORA    := Time() // hora de inclusão do registro na tabela de muro.
   ZFH->ZFH_CGC	  := SA1->A1_CGC
   ZFH->ZFH_COD	  := SA1->A1_I_DNRDC // SA1->A1_COD  
   ZFH->ZFH_NOME	  := SA1->A1_NOME
   ZFH->ZFH_END	  := _cEndereco // SA1->A1_END
   ZFH->ZFH_NUMERO  := _cNumero   // U_AOMS076N(SA1->A1_END)
   ZFH->ZFH_BAIRRO  := SA1->A1_BAIRRO
   If (nPosUF:=aScan(_aUF,{|x| x[1] == SA1->A1_EST})) > 0  .Or. (nPosUF:=aScan(_aUF,{|x| x[1] == SA1->A1_ESTC})) > 0 
      ZFH->ZFH_CMUNC:=_aUF[nPosUF][02] + SA1->A1_COD_MUN  // SA1->A1_I_CMUNC
   Else
      ZFH->ZFH_CMUNC:=SA1->A1_I_CMUNC
   EndIf
   ZFH->ZFH_CEP	 := SA1->A1_CEP    
   ZFH->ZFH_ENDENT := _cEndereco
   ZFH->ZFH_NUMENT := _cNumero
   ZFH->ZFH_BAIRRE := SA1->A1_BAIRRO  // SA1->A1_BAIRROE // NAO USADO
   If nPosUF > 0 
      ZFH->ZFH_CMUEN  := _aUF[nPosUF][02]  + SA1->A1_COD_MUN //SA1->A1_CODMUNE // SA1->A1_I_CMUEN // NAO USADO
   Else
      ZFH->ZFH_CMUEN:=SA1->A1_I_CMUNC
   EndIf
   ZFH->ZFH_CEPE   := SA1->A1_CEP     // SA1->A1_CEPE    // NAO USADO   
   ZFH->ZFH_INSCR	 := SA1->A1_INSCR  
   ZFH->ZFH_PESSOA := SA1->A1_PESSOA
   ZFH->ZFH_MSBLQL := "S" //SA1->A1_MSBLQL
   
   ZFH->ZFH_DDD	 := SA1->A1_DDD
   ZFH->ZFH_TEL	 := SA1->A1_TEL
   ZFH->ZFH_TIPO	 := SA1->A1_TIPO
   ZFH->ZFH_NREDUZ := SA1->A1_NREDUZ

   If SA1->A1_I_CHEP == "C"
      ZFH->ZFH_CHEP:= "1"  
   ElseIf SA1->A1_I_CHEP == "P"
      ZFH->ZFH_CHEP:= "3"  
   Else
      ZFH->ZFH_CHEP:= "2"  
   EndIf   
        
   If ! Empty(SA1->A1_I_GERMU)
      ZFH->ZFH_GERMU	:=	SA1->A1_I_GERMU
   EndIf
   
   If ! Empty(SA1->A1_I_DESCA)
      ZFH->ZFH_DESCA	:=	SA1->A1_I_DESCA
   EndIf
   
   If ! Empty(SA1->A1_I_TPEQP)
      ZFH->ZFH_TPEQP	:=	SA1->A1_I_TPEQP
   EndIf
   
   ZFH->ZFH_RECSA1  := SA1->(Recno())
   ZFH->ZFH_TXDIF	  := SA1->A1_I_TXDIf  
   ZFH->ZFH_CODEMP  := _cCodEmpWS  
   If Type("__cUserId") = "C" .And. ! Empty(__cUserId)
      ZFH->ZFH_USUARI  := __cUserId
   EndIf 
   ZFH->ZFH_DATAAL  := Date()
   ZFH->(MSUnLock())

End Sequence  

SRA->( DBSetOrder(1) ) //RA_FILIAL+RA_MAT

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa----------: AOMS076N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/09/2016
Descrição---------: Com base em um endereço passado como parâmetro, retorna o numero deste endereço.
Parametros--------: _cEndereco = Endereço a ser lido e retornado o número.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS076N(_cEndereco)

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

  _cret := "00000"
  
 EndIf

Return _cRet

/*
===============================================================================================================================
Programa----------: AOMS076E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 18/04/2017
Descrição---------: Retorna o maior numero sequencial disponível para o código de cliente RDC mais 1.
Parametros--------: Nenhum
Retorno-----------: _nRet = Maior numero sequencial para codigo cliente RDC + 1.
===============================================================================================================================
*/  
User Function AOMS076E

Local _cRet 
Local _cAlias := GetNextAlias()

BeginSql alias _cAlias
   SELECT Max(A1_I_DNRDC) DNRDC FROM %Table:SA1%
   WHERE D_E_L_E_T_ = ' '
   AND SubStr(A1_I_DNRDC,1,1) IN ('0','1','2','3','4','5','6','7','8','9')
   AND SubStr(A1_I_DNRDC,2,1) IN ('0','1','2','3','4','5','6','7','8','9')
   AND SubStr(A1_I_DNRDC,3,1) IN ('0','1','2','3','4','5','6','7','8','9')
   AND SubStr(A1_I_DNRDC,4,1) IN ('0','1','2','3','4','5','6','7','8','9')
   AND SubStr(A1_I_DNRDC,5,1) IN ('0','1','2','3','4','5','6','7','8','9')
   AND SubStr(A1_I_DNRDC,6,1) IN ('0','1','2','3','4','5','6','7','8','9')
 EndSql
    
_cRet := StrZero(Val((_cAlias)->DNRDC)+1,6)
(_cAlias)->(DBCloseArea())

Return _cRet
