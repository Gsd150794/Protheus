/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  |24/01/2024| Chamado 46112. Tratamento para execução apenas dos registros do RDC ZFK_TIPOI = 1
Julio Paz     |28/03/2025| Chamado 45229. Atualizando o chamado 46112 em produção, para dar andamento ao chamado 45229.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "APWEBSRV.CH"

/*
===============================================================================================================================
Programa----------: AOMS087
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/12/2016
Descrição---------: Rotina de integração e envio de dados de vinculação Nota Fiscal Eletrônica com Pedidos de Vendas 
                    via webservice para o sistema RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS087()

Local _aCores := {}
Private aRotina := {}
Private cCadastro 

//Grava Log de execução da rotina
U_ITLOGACS()

Begin Sequence
   cCadastro := "Integração dos Dados de Vinculação NFE com Pedidos de Vendas Via Webservice: Italac <---> RDC"
   aAdd(aRotina,{"Pesquisar"              ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"             ,"AxVisual"   ,0,2})
   aAdd(aRotina,{"Integracao Webservice"  ,"U_AOMS087I" ,0,4})   
   aAdd(aRotina,{"Carga de Dados NFE/Ped.","U_AOMS087S" ,0,3}) 
   aAdd(aRotina,{"Legenda"                ,"U_AOMS087L" ,0,6})
   
   aAdd(_aCores,{"ZFK_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZFK_SITUAC == 'P'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZFK_SITUAC == 'R'" ,"BR_AMARELO" })

   DBSelectArea("ZFK")
   ZFK->(DBSetOrder(1)) 
   ZFK->(DBGoTop())
   MBrowse(6,1,22,75,"ZFK", , , , , , _aCores)
   
End Sequence

Return    

/*
===============================================================================================================================
Função------------: AOMS087L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/12/2016
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS087L()       

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
Função------------: AOMS087I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/12/2016
Descrição---------: Rotina de integração e envio de dados dos Pedidos de Vendas via webservice para empresa RDC.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS087I()

Local _lRet := .F.
Local _aStrucZFK
Local _aOrd := SaveOrd({"SX3","ZFK"})
Local _aCmpZFK := {}
Local _aButtons := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgInt, _nI
Local _otemp

Private _oMarkZFK, _cMarcaZFK := GetMark() 
Private _cArqZFK
Private aHeader := {} , aCols := {}

Begin Sequence
   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFK := ZFK->(DbStruct())
   aAdd(_aStrucZFK,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFK,{"WKRECNO", "N", 10,0})
   
   //================================================================================
   // Abre o arquivo TRBZFQ criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZFK",  _aStrucZFK)
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZFK_DATA"} )
   _otemp:Create()   
   
   DBSelectArea("TRBZFK")
  
   //============================================================================
   // Montagem do aheader                                                        
   //=============================================================================
   FillGetDados(1,"ZFK",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
   
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZFQ 
   //================================================================================
   aAdd( _aCmpZFK , { "WK_OK"		,    , "Marca"                                          ,"@!"})
   
   For _nI := 1 To Len(aHeader)
       If !X3USO( aHeader[_nI,7] ) .Or. aHeader[_nI,10] == 'V' .Or. (AllTrim(aHeader[_nI,2]) $ "ZFK_ALI_WT/ZFK_REC_WT")
          Loop
       EndIf
       aAdd( _aCmpZFK , { aHeader[_nI,2], "" , aHeader[_nI,1]  , aHeader[_nI,3] } )
   Next 

   //================================================================================
   // Carrega os dados da tabela ZFK
   //================================================================================
   Processa( {|| U_AOMS087D()(  ) } , 'Aguarde!' , 'Lendo dados a serem integrados...' )

   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}
   aAdd(_aButtons,{"",{|| U_AOMS087M("T") },"Marc/Des" ,"Marca/Desmarca Todos"})
                                          
   _cTitulo := cCadastro
   
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   Define MsDialog _oDlgInt Title _cTitulo From 9,0 To 200,80 //Of oMainWnd 
      
      _oMarkZFK := MsSelect():New("TRBZFK","WK_OK","",_aCmpZFK,@_lInverte, @_cMarcaZFK,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
      _oMarkZFK:bAval := {|| U_AOMS087M("P")}
      _oDlgInt:lMaximized:=.T.
      
   Activate MsDialog _oDlgInt On Init (EnchoiceBar(_oDlgInt,_bOk,_bCancel,,_aButtons), _oMarkZFK:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkZFK:oBrowse:Refresh() )
   
   If _lRet
      Processa( {|| U_AOMS087W(  ) } , 'Aguarde!' , 'Integrando Dados do Pedido de Venadas...' )
   EndIf

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZFK") > 0
   TRBZFK->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Função----------: AOMS087M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 07/12/2016
Descrição-------: Função para marcar e desmarcar todos Pedidos de Vendas que serão integrados via Webservice.
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.                                           
Retorno---------: Nenhum                  
===============================================================================================================================
*/
User Function AOMS087M(_cTipoMarca)

Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZFK->(Recno()) 

Begin Sequence          
   If Empty(TRBZFK->WK_OK )
      _cSimboloMarca := _cMarcaZFK
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZFK->(RecLock("TRBZFK",.F.))
      TRBZFK->WK_OK := _cSimboloMarca 
      TRBZFK->(MSUnLock())
   Else
      TRBZFK->(DBGoTop())
      While ! TRBZFK->(Eof())
         TRBZFK->(RecLock("TRBZFK",.F.))
         TRBZFK->WK_OK := _cSimboloMarca 
         TRBZFK->(MSUnLock()) 
         
         TRBZFK->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZFK->(DBGoTo(_nRegAtu)) 
_oMarkZFK:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Função------------: AOMS087W
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/12/2016
Descrição---------: Gera os dados XML com base nos Pedidos de Vendas selecionados e integra via webservice.
Parametros--------: _lScheduler = .T. indica rotina em Scheduler; .F. indica rotina manual
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS087W(_lScheduler)             

Local _cDirXML := ""
Local _cLink   := ""
Local _cCabXML := ""
Local _cRodXML := "" 
Local _lItemSelect := .F.
Local _aOrd := SaveOrd({"ZFK","ZFM","SC9"})
Local _cXML 
Local _cResult := ""
Local _cResposta, _cSituacao
Local _cEmpWebService := SuperGetMV('IT_EMPWEBS',.F.,'000001')

Default _lScheduler := .F.

Begin Sequence
   //================================================================================
   // Verifica se há itens selecionados e lê o código da empresa de WebService.
   //================================================================================                    
   If ! _lScheduler
      ProcRegua(8)
      IncProc("Verificando itens selecionados...")
   Else
      u_itconout("Verificando itens selecionados para integração Vinc.NFE x Pedidos de Vendas.")
   EndIf                    
   
   TRBZFK->(DBGoTop())                                                                   
   While ! TRBZFK->(Eof())
      If ! Empty(TRBZFK->WK_OK)   
         _cEmpWebService := TRBZFK->ZFK_CODEMP                         
         _lItemSelect := .T. 
         Exit
      EndIf                 
      
      TRBZFK->(DBSkip())
   EndDo 
     
   If ! _lItemSelect 
      If ! _lScheduler
         MsgInfo("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.","Atenção")
      Else
         u_itconout("Nenhum item foi selecionado para integração Webservice. Não será possível realizar a integração Italac <---> RDC.")
      EndIf                                                                                                                         
      
      Break   
   EndIf              
   
   //================================================================================
   // Lê o diretório dos arquivos XML modelos e o link de envio dos dados.
   //================================================================================
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

   //================================================================================
   // Lê os arquivos modelo XML e os transforma em String.
   //================================================================================
   If ! _lScheduler
      IncProc("Lendo arquivo XML Modelo de Cabeçalho...")                      
   Else
      u_itconout("Lendo arquivo XML Modelo de Cabeçalho...")
   EndIf                                                
   
   _cCabXML := U_AOMS087X(_cDirXML+"Cab_VinculaNfePedido.txt") 
   If Empty(_cCabXML)
      If ! _lScheduler
         MsgInfo("Erro na leitura do arquivo XML modelo do cabeçalho de envio vinculação NFE com Pedido de Vendas. ","Atenção")
      Else
         u_itconout("Erro na leitura do arquivo XML modelo do cabeçalho de envio vinculação NFE com Pedido de Vendas. ")
      EndIf
      
      Break
   EndIf
   
   If ! _lScheduler
      IncProc("Lendo arquivo XML Modelo de Detalhe ...")
   Else
      u_itconout("Lendo arquivo XML Modelo de Detalhe ...")
   EndIf                                               
   
   _cDet_XML := U_AOMS087X(_cDirXML+"Det_VinculaNfePedido.txt")
   If Empty(_cDet_XML)
      If ! _lScheduler
         MsgInfo("Erro na leitura do arquivo XML modelo do detalhe de envio vinculação NFE com Pedido de Vendas.","Atenção")
      Else
         u_itconout("Erro na leitura do arquivo XML modelo do detalhe de envio vinculação NFE com Pedido de Vendas.")
      EndIf
      
      Break
   EndIf            
   
   If ! _lScheduler  
      IncProc("Lendo arquivo XML Modelo de Rodapé...")
   Else
      u_itconout("Lendo arquivo XML Modelo de Rodapé...")
   EndIf                                             
   
   _cRodXML := U_AOMS087X(_cDirXML+"Rodape_VinculaNfePedido.txt")
   If Empty(_cRodXML)
      If ! _lScheduler
         MsgInfo("Erro na leitura do arquivo XML modelo do rodapé de envio vinculação NFE com Pedido de Vendas.","Atenção")
      Else
         u_itconout("Erro na leitura do arquivo XML modelo do rodapé de envio vinculação NFE com Pedido de Vendas.")
      EndIf    
      
      Break
   EndIf
   
   //================================================================================
   // Ativa a classe de envio de dados.
   //================================================================================     
   If ! _lScheduler                  
      IncProc("Montando dados de envio...")
   Else
      u_itconout("Montando dados de envio...")
   EndIf

   oWsdl := tWSDLManager():New() // Cria o objeto da WSDL.  
   oWsdl:nTimeout := 60          // Timeout de xx segundos                                                               
   oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                               
   
   oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.   
   oWsdl:SetOperation( "VinculaNfePedido") // Define qual operação será realizada.   
   
   _aresult := {}
   
   TRBZFK->(DBGoTop())                                                                   
   While ! TRBZFK->(Eof())
          
      If ! Empty(TRBZFK->WK_OK)   
         ZFK->(DBGoTo(TRBZFK->WKRECNO))

            Begin Transaction

               //-----------------------------------------------------------------------------------------
               // Realiza a integração dos pedidos de vendas (Envio de XML) via WebService.
               //-----------------------------------------------------------------------------------------
                        
               //Monta XML
               _cXML := _cCabXML + &(_cDet_XML) + _cRodXML  // Monta o XML de envio.
               
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
                  _cSituacao := "N" 
               ElseIf !("IMPORTADO COM SUCESSO" $ _cResposta)       	
                  _cSituacao := "N"
               EndIf

               //grava resultado // sempre como processado
               ZFK->(RecLock("ZFK",.F.))
               ZFK->ZFK_SITUAC  := _cSituacao // IIf(_cok, "P", "N")
               ZFK->ZFK_USUARI  := __cUserId
               ZFK->ZFK_DATAAL  := Date()
               ZFK->ZFK_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFK,dizendo que deu certo ou não.
               ZFK->ZFK_XML     := _cXML
               
               ZFK->(MSUnLock()) 
                     
               aAdd(_aresult,{ZFK->ZFK_PEDIDO,ZFK->ZFK_CGC,ZFK->ZFK_RETORN}) // adicona em um array para fazer um item list, exibir os resultados.
               Sleep(100) //Espera para não travar a comunicação com o webservice da RDC
               
               If ! _lScheduler  
                  IncProc(ZFK->ZFK_CGC+ " - "  + ZFK->ZFK_RETORN)
               Else
                  u_itconout(ZFK->ZFK_CGC+ " - "  + ZFK->ZFK_RETORN)
               EndIf
                  
            End Transaction
         
      EndIf       
                
      TRBZFK->(DBSkip())
         
   EndDo 
   
   If ! _lScheduler  
      _aCabecalho := {}
      aAdd(_aCabecalho,"PEDIDO") 
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
Função-------------: AOMS087X
Aut2or-------------: Julio de Paula Paz
Data da Criacao---: 07/12/2016
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS087X(_cArq)

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
=================================================================================================================================
Programa--------: AOMS087S()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 07/12/2016
Descrição-------: Chama a rotina de leitura de dados das notas fiscais enviadas para o sistema RDC, permitindo a exibição 
                  da regua de processo.
Parametros------: Nenhum
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS087S()

Begin Sequence
   
   Processa( {|| U_AOMS087R(.F.) } , 'Aguarde!' , 'Lendo dados dos Livros Fiscais...' )

End Sequence

Return
                     
/*
=================================================================================================================================
Programa--------: AOMS087R()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 07/12/2016
Descrição-------: Lê os dados da tabela de SF2(Notas fiscais de Saída) que já foram processados e gravaram os XMLs de notas 
                  fiscais em diretório para envio ao RDC, identifica o pedido de vendas vinculado a NFE e grava os dados na 
                  tabela de muro ZFK para integração da vinculação da NFE com o Pedido de Vendas e envio ao RDC.
Parametros------: _lScheduler = .T. indica rotina em scheduler, .F. indica rotina manual.
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS087R(_lScheduler)

Local _cQry, _nTotRegs
Local _aOrd := SaveOrd({"SA2","SF2","SC5"})
Local _aFilial := FwLoadSM0()
Local _nI, _cCnpj
Local _cCodEmpWS := SuperGetMV('IT_EMPWEBS',.F.,'000001')
Local _cPedido
Local _cFilial, _nRegAtu
Local _cPedOrig 

Default _lScheduler := .F.

If ! _lScheduler                  
   ProcRegua(0)
   IncProc("Lendo dados...") 
   IncProc("Lendo dados...") 
EndIf

Begin Sequence 
   u_itconout("Lendo dados da tabela Notas Fiscais de Saída SF2 para integração RDC.")
   
   _cQry := " SELECT R_E_C_N_O_ AS NRRECNO FROM "+RetSqlName("SF2")+" SF2 "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND F2_I_SITUA = 'P' " 
                                                              
   If Select("TRBSF2") > 0
      TRBZF2->(DBCloseArea())
   EndIf                     
             
   DbUseArea(.T., "TOPCONN", TcGenQry(,,_cQry), "TRBSF2", .T., .F.)
   
   Count To _nTotRegs
   
   If _nTotRegs == 0 
      If _lScheduler
         u_itconout("Nenhum registro de notas fiscais foi encontrado para integração RDC.")
      Else
         MsgInfo("Nenhum registro de notas fiscais foi encontrado para integração RDC.","Atenção")
      EndIf
      
      Break
   EndIf
   
   If ! _lScheduler                  
      ProcRegua(_nTotRegs)
   EndIf
   
   SA2->(DBSetOrder(3)) // A2_FILIAL+A2_CGC
   SF2->(DBSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO  
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM                                                                                                
   
   TRBSF2->(DBGoTop()) 
       
   While ! TRBSF2->(Eof())                 
       
      SF2->(DBGoTo(TRBSF2->NRRECNO))
      
      If _lScheduler
         u_itconout("Processando Filial/Nota Fiscal: "+SF2->F2_FILIAL+"/"+AllTrim(SF2->F2_DOC)+"-"+SF2->F2_SERIE)
      Else
         IncProc("Processando Filial/Nota Fiscal: "+SF2->F2_FILIAL+"/"+AllTrim(SF2->F2_DOC)+"-"+SF2->F2_SERIE) 
      EndIf

      _nI := aScan(_aFilial,{|x| x[5] = SF2->F2_FILIAL})   
      _cCnpj := _aFilial[_nI,18]
      SA2->(DBSetOrder(3)) 
      SA2->(DBSeek(xFilial("SA2")+_cCnpj))
      
      _cPedido := SF2->F2_I_PEDID
      If SC5->(DBSeek(SF2->F2_FILIAL+_cPedido)) 
      
      	//============================================================
      	//Determina cnpj da filial de carregamento para troca nota
      	//============================================================
      	
         If SC5->C5_I_TRCNF == "S"
            _nI := aScan(_aFilial,{|x| x[5] = SC5->C5_I_FLFNC})   
            _cCnpj := _aFilial[_nI,18]
         EndIf
       	
         If SC5->C5_I_PEDPA == "S"
            If SC5->C5_I_TRCNF == "S" .And. SC5->C5_I_OPER == "20" .And. SC5->C5_FILIAL <> SC5->C5_I_FILFT 
               //========================================================================================
               // Pega o numero do pedido e filial do pedido que originou o pedido de pallet.
               //========================================================================================
               _cPedOrig := SC5->C5_I_NPALE
               _cFilial := SC5->C5_FILIAL
               _nRegAtu := SC5->(Recno())
               //========================================================================================
               // Posiciona no pedido que originou o pedido de pallet, e pega o cnpj e o numero do pedido
               // que deu origem ao pedido de carregamento.
               //========================================================================================
               If SC5->(DBSeek(_cFilial+_cPedOrig))
                  _cPedido := SC5->C5_I_PDFT
               EndIf 
               SC5->(DBGoTo(_nRegAtu))
            Else
               _cPedido := SC5->C5_I_NPALE
            EndIf
         Else
            If SC5->C5_I_TRCNF == "S" .And. SC5->C5_I_OPER == "20" .And. SC5->C5_FILIAL <> SC5->C5_I_FILFT 
               _cPedido := SC5->C5_I_PDFT
            EndIf
         EndIf                                      
      EndIf

      ZFK->(RecLock("ZFK",.T.))
      ZFK->ZFK_FILIAL  := SF2->F2_FILIAL     //	Filial do Sistema
      ZFK->ZFK_HORA    := Time()             // Hora de inclusão do registro na tabela de muro.
      ZFK->ZFK_DATA    := Date()	         //	Data de Emissão
      ZFK->ZFK_CGC     := _cCnpj             //	CNPJ FORNECEDOR
      ZFK->ZFK_CHVNFE  := SF2->F2_CHVNFE     //	Chave da NFe SEFAZ
      ZFK->ZFK_PEDIDO  := _cPedido           //	Numero do Pedido(Na Italac há um pedido por nota) // SF2->F2_I_PEDID
      ZFK->ZFK_COD     := SF2->F2_CLIENTE    // Código Cliente    // SA2->A2_COD  - Fornecedor    // O correto é: A1_COD
      ZFK->ZFK_LOJA    := SF2->F2_LOJA       // Loja Cliente      // SA2->A2_LOJA - Fornecedor    //              A1_LOJA
      ZFK->ZFK_NOME    := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME")   // Nome Cliente      // SA2->A2_NOME - Fornecedor   //              A1_NOME
      ZFK->ZFK_USUARI  := __cUserId	         //	Codigo do Usuário
      ZFK->ZFK_DATAAL  := Date()	         //	Data de Alteração
      ZFK->ZFK_SITUAC  := "N"                //	Situação do Registro
      If SC5->C5_I_PEDPA == "S"              //  "S" = é um pedido de pallet.
         ZFK->ZFK_PEDPAL  := "S"             //  Grava dados informando que é um pedido de pallet.
         ZFK->ZFK_NRPPAL  := SF2->F2_I_PEDID //  Grava o numero do pedido de Pallet.
      Else
         ZFK->ZFK_PEDPAL  := "N"             //  Não é um pedido de Pallet.
      EndIf
      ZFK->ZFK_CODEMP  := _cCodEmpWS         //	Codigo Empresa WebServer 
      ZFK->ZFK_TIPOI   := "1"
      ZFK->(MSUnLock())
      
            
      SF2->(RecLock("SF2",.F.))
      SF2->F2_I_SITUA := "I"  // Enviado para Integração
      SF2->(MSUnLock())
   
      TRBSF2->(DBSkip())
   EndDo
   
End Sequence

If Select("TRBSF2") > 0
   TRBSF2->(DBCloseArea())
EndIf   

RestOrd(_aOrd,.T.) // Volta a ordem os indices das tabelas para ordem anterior e volta os ponteiros de registros das tabelas

Return           

/*
===============================================================================================================================
Função------------: AOMS084D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2016
Descrição---------: Grava em tabela temporária os dados a serem integrados via webservice.
Parametros--------: _lScheduler = .T. rotina em scheduler; .F. rotina manual.
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS087D(_lScheduler)

Local _lRet := .F.
Local cFilZFK:=xFilial("ZFK")
Local _nI

Default _lScheduler := .F.

Begin Sequence
   
   If ! _lScheduler
      //===================================================
      // Processamento da rotina chamada em tela.
      //===================================================
      ProcRegua(0)
      ZFK->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC
      ZFK->(DBSeek(cFilZFK+"N"))
      While ! ZFK->(Eof()) .And. ZFK->(ZFK_FILIAL+ZFK_SITUAC) == cFilZFK+"N"
         
         If ZFK->ZFK_TIPOI = "1"
            IncProc("Lendo PC: "+ZFK->ZFK_PEDIDO)
            
            TRBZFK->(DBAPPEND())
            For _nI := 1 To ZFK->(FCount())                  
               nPos:=TRBZFK->(FieldPos( ZFK->( FieldName(_nI)) ))
               If nPos # 0
                  TRBZFK->(FieldPut(nPos,  ZFK->( FieldGet(_nI) ) )) 
               EndIf
            Next            
            
            TRBZFK->WKRECNO := ZFK->(Recno())

            _lRet := .T.
         EndIf

         ZFK->(DBSkip())
      EndDo

   Else
      //===================================================
      // Processamento da rotina chamada via Scheduller. 
      //===================================================
      ZFK->(DBSetOrder(2))  // ZFF_FILIAL+ZFF_SITUAC

      ZZM->(DBGoTop())
      While ! ZZM->(Eof())
            
         ZFK->(DBSeek(ZZM->ZZM_CODIGO+"N"))
         While ! ZFK->(Eof()) .And. ZFK->(ZFK_FILIAL+ZFK_SITUAC) == ZZM->ZZM_CODIGO+"N"
            If ZFK->ZFK_TIPOI = "1"
               TRBZFK->(DBAPPEND())
               For _nI := 1 To ZFK->(FCount())                  
                  nPos:=TRBZFK->(FieldPos( ZFK->( FieldName(_nI)) ))
                  If nPos # 0
                     TRBZFK->(FieldPut(nPos,  ZFK->( FieldGet(_nI) ) )) 
                  EndIf
               Next            
               TRBZFK->WK_OK   := _cMarcaZFK
               TRBZFK->WKRECNO := ZFK->(Recno())
         
               _lRet := .T.
            EndIf
            ZFK->(DBSkip())
         EndDo
         
         ZZM->(DBSkip())
      
      EndDo
      
   EndIf 

   TRBZFK->(DBGoTop())

End Sequence

Return _lRet

/*
===============================================================================================================================
Função----------: AOMS087A
Autor-----------: Julio de Paula Paz
Data da Criacao-: 07/12/2016
Descrição-------: Função para rodar a rotina de integração Vinculação NFE com Pedido de Vendas de forma agendada (Scheduller).
Parametros------: Nenhum
Retorno---------: Nenhum                  
===============================================================================================================================
*/
User Function AOMS087A()             

Local _aOrd 
Local _otemp

Private _cArqZFK
Private _cMarcaZFK 
Private aHeader := {} , aCols := {}

Begin Sequence
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)

   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})

   cFilAnt := "01"

   //================================================================================
   _aOrd := SaveOrd({"SX3","ZFK"})
   _cMarcaZFK := GetMark()

   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZFK := ZFK->(DbStruct())
   aAdd(_aStrucZFK,{"WK_OK"  , "C", 2 ,0})
   aAdd(_aStrucZFK,{"WKRECNO", "N", 10,0})
   
   //================================================================================
   // Abre o arquivo TRBZFQ criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBZFK",  _aStrucZFK)
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZFK_DATA"} )
   _otemp:Create()   
   
   DBSelectArea("TRBZFK")
       
   //================================================================================
   // Lê os dados da tabela Notas Fiscais de Saída SF2 e grava na tabela de muro ZFK.
   //================================================================================
   U_AOMS087R(.T.)

   //================================================================================
   // Grava os dados das tabelas de muro em tabela temporária para serem processados
   // via scheduller.
   //================================================================================
   U_AOMS087D(.T.)

   //================================================================================
   // Gera os dados dos XML e integra via webservices.
   //================================================================================ 
   U_AOMS087W(.T.)             

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZFK") > 0
   TRBZFK->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return
