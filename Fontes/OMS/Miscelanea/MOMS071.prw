/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
    Autor     |    Data    |                                             Motivo                                           
------------------------------------------------------------------------------------------------------------------------------- 
              |            |
=============================================================================================================================== 
*/

//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDef.Ch"

//Static _cChamada := "LINHA"
/*
===============================================================================================================================
Função-------------: MOMS071
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/04/2024
===============================================================================================================================
Descrição----------: Rotina para rodar em Scheduller e para excluir pedidos de vendas do portal rejeitados, após um 
                     numeros de dias informados em parâmetro. Chamado 41001.
===============================================================================================================================
Parametros---------: Nenhum
===============================================================================================================================
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS071()
Local _LigaDesWS

Begin Sequence

   //=============================================================================
   // Ativa a filial "01" apenas para exclusão do Pedidos do Portal
   //=============================================================================
   RpcClearEnv()  // Fecha o ambiente caso esteja aberto.
   RpcSetType(2)  // Indica que o ambiente será aberto sem consumir licença.
   
   //=============================================================================
   // Inicia processamento com base nas filiais do parâmetro.
   //=============================================================================
	U_ItConOut( '[MOMS071] -  Abrindo o ambiente para filial 01...' )
 
   //===========================================================================================
   // Preparando o ambiente com a filial 01
   //===========================================================================================
   RpcSetEnv("01", "01",,,"OMS",, {"SA2","SC5","SC6",'SZW', "ZZM"})

   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
   
   //========================================================================
   // Liga ou Desliga a exclusão de pedidos de vendas rejeitados do portal.
   //========================================================================
   _LigaDesWS := U_ITGETMV('IT_LIGAEXPV', .T.) 
   If ! _LigaDesWS
      Break 
   EndIf 

   U_ItConOut( '[MOMS071] - Iniciando Schedule de Exclusao de Pedidos de Vendas do Portal')
   //=========================================================================
   // Roda a rotina Schechuduller de exclusão de Pedidos de Vendas do Portal.
   //=========================================================================
   U_ItConOut( '[MOMS071D] - Efetuando a leitura dos dados. Localizando Pedidos de Vendas do Portal Rejeitados...')
   
   U_MOMS071D(.T.) // Efetura a leitura dos dados.
   
   //=========================================================================
   // Excluindo os pedidos de vendas do portal rejeitados conforme
   // período informado em parâmetro.
   //=========================================================================
   U_ItConOut( '[MOMS071D] - Exclui os pedidos de vendas, conforme leitura realizada.')

   U_MOMS071E(.T.) // Efetura a exclusão dos Pedidos de Vendas, conforme leitura dos dados.

   U_ItConOut( '[MOMS071] - Finalizando schedule de Exclusao de Pedidos de Vendas do Portal ' )

 End Sequence 

If Select("TRBSZW") > 0
   TRBSZW->( DBCloseArea() )
EndIf

Return 

 /*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Julio de Paula Paz
Data da Criacao---: 26/10/2023
===============================================================================================================================
Descrição---------: Rotina de construção do menu
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina Title 'Pesquisar'  Action 'U_MOMS071P()'  OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Exclusão PV Rejeitados do Portal'  Action 'U_MOMS071T()'  OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: MOMS071P
Autor-------------: Julio de Paula Paz
Data--------------: 04/04/2024
===============================================================================================================================
Descrição---------: Permite pesquisar um pedido de Vendas do Portal.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS071P()

Local _oGet1	  := Nil 
Local _oDlgP	  := Nil 
Local _cGet1	  := Space(60)
Local _nOpca	  := 0
Local _cComboBx1  := "Filial e Pedido"
Local _aComboBx1  := {"Filial e Pedido Portal","Filial e Pedido Protheus"}
Local _nRegAtu    := TRBSZW->(Recno())

Begin Sequence 

   DEFINE MSDIALOG _oDlgP TITLE "Pesquisar Pedido de Vendas Portal" FROM 178,181 TO 259,697 PIXEL

      @ 004,003 ComboBox	_cComboBx1	Items _aComboBx1 Size 213,010 OF _oDlgP PIXEL
	  @ 020,003 MsGet		_oGet1	Var _cGet1		Size 212,009 OF _oDlgP PIXEL COLOR CLR_BLACK Picture "@!"
	
	  DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlgP:End() ) OF _oDlgP
	  DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlgP:End() ) OF _oDlgP

   ACTIVATE MSDIALOG _oDlgP CENTERED

   If _nOpca == 1
      If AllTrim(_cComboBx1) == AllTrim(_aComboBx1[1])
         TRBSZW->(DBSetOrder(1))
      Else
         TRBSZW->(DBSetOrder(2))        
      EndIf 
   
      If ! TRBSZW->(MsSeek(RTrim(_cGet1)))
         U_ITMsg("Pedido de Vendas não encontrado.","Atenção",,1)
         TRBSZW->(DBSetOrder(1))
         TRBSZW->(DBGoTo(_nRegAtu))
      Else
         _oMarkBRW:oBrowse:Refresh()
      EndIf 
   EndIf

End Sequence

Return .T. 

/*
===============================================================================================================================
Função-------------: MOMS071T
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/04/2024
===============================================================================================================================
Descrição----------: Rotina de Exclusão de Pedidos de Vendas Rejeitados do Portal em Tela.
===============================================================================================================================
Parametros---------: Nenhum
===============================================================================================================================
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS071T()
Local _aFields := {}
Local _nDiasExPv := U_ITGETMV('IT_NDIASEXP', 7)

Private _oMarkBRW

Begin Sequence

   Processa( {|| U_MOMS071D()  } , "Efetuando Leitura dos Dados..." , "Aguarde!" )

   _aFields := {}
   aAdd( _aFields , { "Filial"		   , {|| TRBSZW->ZW_FILIAL }  , "C" , "@!" , 0 , 2		                   , 0 } )
   aAdd( _aFields , { "Pedido Portal"  , {|| TRBSZW->ZW_IDPED }	, "C" , "@!" , 0 , TamSX3("ZW_IDPED")[01]	 , 0 } )
   aAdd( _aFields , { "Dt.Emissão"	   , {|| TRBSZW->ZW_EMISSAO}	, "D" , "@!" , 0 , 8					          , 0 } )
   aAdd( _aFields , { "Cliente"		   , {|| TRBSZW->ZW_CLIENTE } , "C" , "@!" , 0 , TamSX3("ZW_CLIENTE")[01], 0 } )
   aAdd( _aFields , { "Loja"	         , {|| TRBSZW->ZW_LOJACLI } , "C" , "@!" , 0 , TamSX3("ZW_LOJACLI")[01], 0 } )
   aAdd( _aFields , { "Nome "		      , {|| TRBSZW->WK_NOMECLI } , "C" , "@!" , 0 , TamSX3("C5_I_NOME")[01] , 0 } )
   aAdd( _aFields , { "Representante"  , {|| TRBSZW->ZW_VEND1}  	, "C" , "@!" , 0 , TamSX3("ZW_VEND1")[01]	 , 0 } )
   aAdd( _aFields , { "Nome Repres."   , {|| TRBSZW->WK_NOMEVEN}  , "C" , "@!" , 0 , TamSX3("C5_I_NOME")[01] , 0 } )
   aAdd( _aFields , { "Pedido Protheus", {|| TRBSZW->ZW_NUMPED }	, "C" , "@!" , 0 , TamSX3("ZW_NUMPED")[01] , 0 } ) 
   aAdd( _aFields , { "Status"         , {|| TRBSZW->ZW_STATUS}  	, "C" , "@!" , 0 , TamSX3("ZW_STATUS")[01] , 0 } )
   aAdd( _aFields , { "Des.Status"     , {|| TRBSZW->WK_DESSTAT}  , "C" , "@!" , 0 , 25                  	 , 0 } )

   _oMarkBRW := FWMarkBrowse():New()		   												// Inicializa o Browse

   _oMarkBRW:SetAlias( "TRBSZW" )			   												// Define Alias que será a Base do Browse
   _oMarkBRW:SetDescription( "Exclusão de Pedidos de Vendas Rejeitados no Portal, a " + AllTrim(Str(_nDiasExPv,10)) + " Dias. "   )	// Define o titulo do browse de marcacao
   _oMarkBRW:SetFieldMark( "MARCA" )														// Define o campo que sera utilizado para a marcação
   _oMarkBRW:SetMenuDef( 'MOMS0071' )	
   _oMarkBRW:SetAllMark({|| U_MOMS071A()})  

   _oMarkBRW:SetAfterMark({|| U_MOMS071M() })  // Executa um bloco de código após um registro ser marcado. 

   _oMarkBRW:SetFields( _aFields )													 		// Campos para exibição
   _oMarkBRW:AddButton( "Pesquisar" , {|| Processa( {|| U_MOMS071P() } , "Pesquisando Pedidos do Portal..." , "Aguarde!" ) } ,, 4 )
   _oMarkBRW:AddButton( "Excluir Pedidos" , {|| Processa( {|| U_MOMS071E(.F.) } , "Excluindo Pedidos do Portal..." , "Aguarde!" ) } ,, 4 )
   
   _oMarkBRW:Activate()																		// Ativacao da classe
 
End Sequence 

If Select("TRBSZW") > 0
   TRBSZW->( DBCloseArea() )
EndIf

Return 

/*
===============================================================================================================================
Função-------------: MOMS071D
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/04/2024
===============================================================================================================================
Descrição----------: Rotina de Leitura dos dados  para a Exclusão de Pedidos de Vendas Rejeitados do Portal em Tela.
===============================================================================================================================
Parametros---------: _lScheduller = .T. = Rotina rodada em modo Scheduller.
                                    .F. = Rotina rodada em tela.
===============================================================================================================================
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS071D(_lScheduller)
Local _aCpos  := {}
Local _cMarca := GetMark()  
Local _nDiasExPv := U_ITGETMV('IT_NDIASEXP', 7)
Local _dDataExPv  // Data para exclusão de pedido de vendas

Begin Sequence

   aAdd( _aCpos , { "MARCA"		, "C" , 2					    , 0 } )
   aAdd( _aCpos , { "ZW_FILIAL"	, "C" , 2                       , 0 } )
   aAdd( _aCpos , { "ZW_IDPED"	, "C" , TamSX3("ZW_IDPED")[01]  , 0 } )
   aAdd( _aCpos , { "ZW_EMISSAO", "D" , 8		                , 0 } )
   aAdd( _aCpos , { "ZW_NUMPED"	, "C" , TamSX3("ZW_NUMPED")[01] , 0 } )
   aAdd( _aCpos , { "ZW_CLIENTE", "C" , TamSX3("ZW_CLIENTE")[01], 0 } )
   aAdd( _aCpos , { "ZW_LOJACLI", "C" , TamSX3("ZW_LOJACLI")[01], 0 } )
   aAdd( _aCpos , { "WK_NOMECLI", "C" , TamSX3("C5_I_NOME")[01]	, 0 } )
   aAdd( _aCpos , { "ZW_VEND1 "	, "C" , TamSX3("ZW_VEND1")[01]	, 0 } )
   aAdd( _aCpos , { "WK_NOMEVEN", "C" , TamSX3("C5_I_NOME")[01]	, 0 } )
   aAdd( _aCpos , { "ZW_STATUS" , "C" , TamSX3("ZW_STATUS")[01]	, 0 } )
   aAdd( _aCpos , { "WK_DESSTAT", "C" , 25                   	, 0 } )
   aAdd( _aCpos , { "WK_RECNO"	, "N" , 10                      , 0 } )

   If Select("TRBSZW") > 0
	   TRBSZW->( DBCloseArea() )
   EndIf

   _otemp := FWTemporaryTable():New("TRBSZW", _aCpos )
   
   _otemp:AddIndex( "01", {"ZW_FILIAL","ZW_IDPED"} )
   _otemp:AddIndex( "02", {"ZW_FILIAL","ZW_NUMPED"} )

   _otemp:Create()  // Cria a tabela temporária

   _dDataExPv := Date() - _nDiasExPv  // Data para exclusão de pedido de vendas
   
   _cQry := "SELECT ZW_FILIAL, ZW_STATUS, ZW_IDPED, ZW_EMISSAO, ZW_NUMPED, ZW_CLIENTE, ZW_LOJACLI, ZW_VEND1 , SZW.R_E_C_N_O_ NRREG " 
   _cQry += " FROM  " + RetSqlName("SZW") + " SZW "
   _cQry += " WHERE "
   _cQry += "     SZW.D_E_L_E_T_  = ' ' "
   _cQry += " AND SZW.ZW_STATUS = 'R' "  
   _cQry += " AND SZW.ZW_DTREC <> ' ' "
   _cQry += " AND SZW.ZW_DTREC <= '" + DToS(_dDataExPv) + "' "
   _cQry += " ORDER BY ZW_FILIAL, ZW_IDPED "

   If Select("QRYSZW") > 0
	   QRYSZW->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "QRYSZW" , .T. , .F. )
   TCSetField('QRYSZW',"ZW_EMISSAO","D",8,0)
   
   If ! _lScheduller
      Count To _nTotRegs
      ProcRegua(_nTotRegs)
   EndIf 
   
   QRYSZW->(DBGoTop())

   _nI := 1

   While ! QRYSZW->(Eof())
      If ! _lScheduller
         IncProc("Lendo dados: " + AllTrim(Str(_nI,10)) + " de " + AllTrim(Str(_nTotRegs,10))  )
      EndIf 
      _nI += 1

      _cDeStatus := ""
      If QRYSZW->ZW_STATUS == "R"
         _cDeStatus := "REPROVADO"
      ElseIf QRYSZW->ZW_STATUS == "L"
         _cDeStatus := "LIBERADO"
      ElseIf QRYSZW->ZW_STATUS == "I"
         _cDeStatus := "IMPORTADO"
      ElseIf QRYSZW->ZW_STATUS == "A"
         _cDeStatus := "AGUARDANDO APROVACAO"
      EndIf 

      TRBSZW->( RecLock( "TRBSZW" , .T. ) )
      If _lScheduller
         TRBSZW->MARCA := _cMarca
      EndIf 
      TRBSZW->ZW_FILIAL  := QRYSZW->ZW_FILIAL
      TRBSZW->ZW_IDPED   := QRYSZW->ZW_IDPED
      TRBSZW->ZW_EMISSAO := QRYSZW->ZW_EMISSAO
      TRBSZW->ZW_NUMPED  := QRYSZW->ZW_NUMPED
      TRBSZW->ZW_CLIENTE := QRYSZW->ZW_CLIENTE
      TRBSZW->ZW_LOJACLI := QRYSZW->ZW_LOJACLI
      TRBSZW->WK_NOMECLI := Posicione("SA1",1,xFilial("SA1")+QRYSZW->ZW_CLIENTE+QRYSZW->ZW_LOJACLI,"A1_NOME")
      TRBSZW->ZW_VEND1   := QRYSZW->ZW_VEND1
      TRBSZW->WK_NOMEVEN := Posicione("SA3",1,xFilial("SA3")+QRYSZW->ZW_VEND1,"A3_NOME")
      TRBSZW->ZW_STATUS  := QRYSZW->ZW_STATUS
      TRBSZW->WK_DESSTAT := _cDeStatus
      TRBSZW->WK_RECNO   := QRYSZW->NRREG
      TRBSZW->( MSUnLock() )

      QRYSZW->(DBSkip())

   EndDo 
 
End Sequence 

If Select("QRYSZW") > 0
   QRYSZW->( DBCloseArea() )
EndIf

Return 

/*
===============================================================================================================================
Função-------------: MOMS071M
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/04/2024
===============================================================================================================================
Descrição----------: Função Rodada após a marcação de um registro.
===============================================================================================================================
Parametros---------: Nenhum 
===============================================================================================================================
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS071M()
Local _aItensPV := {}
Local _nI
Local _cMarcaIte 

Begin Sequence 
   If IsInCallStack("U_MOMS071A") // If _cChamada <> "LINHA"
      Break 
   EndIf

   _cMarca := _oMarkBRW:Mark()

   If _oMarkBRW:IsMark(_cMarca)
      _cMarcaIte := _cMarca 
   Else
      _cMarcaIte := Space(2)
   EndIf 
   
   _nRegAtu := TRBSZW->(Recno())

   TRBSZW->(DBSetOrder(1))

   _cCodFil := TRBSZW->ZW_FILIAL
   _cPedido := TRBSZW->ZW_IDPED

   TRBSZW->(MsSeek(_cCodFil + _cPedido))

   While ! TRBSZW->(Eof()) .And. TRBSZW->ZW_FILIAL+TRBSZW->ZW_IDPED == _cCodFil + _cPedido
         
      aAdd(_aItensPV,TRBSZW->(Recno()))

      TRBSZW->(DBSkip())
   EndDo 
   
   //==============================================================================
   // Um RecLock dentro de um While, as vezes desposiciona o ponteiro de registros 
   // e encerra o While antes de terminar o processamento de todos os registros.
   // Utilizando um For...Next como alternativa.
   //==============================================================================
   For _nI := 1 To Len(_aItensPV)  
       TRBSZW->(DBGoTo(_aItensPV[_nI]))
       TRBSZW->MARCA := _cMarcaIte
       TRBSZW->(MSUnLock())
   Next 

   TRBSZW->(DBGoTo(_nRegAtu))

End Sequence 

_oMarkBRW:Refresh(.F.)

Return 

/*
===============================================================================================================================
Função-------------: MOMS071A
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/04/2024
===============================================================================================================================
Descrição----------: Rotina chamada e rodada na marcação / Desmarcação de todos os registros.
===============================================================================================================================
Parametros---------: Nenhum
===============================================================================================================================
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS071A()
Local _aItensPV := {}
Local _nI
Local _cMarcaIte 

Begin Sequence
   
   _cMarca := _oMarkBRW:Mark()

   If _oMarkBRW:IsMark(_cMarca)
      _cMarcaIte := Space(2)
      //_cMarcaIte := _cMarca
   Else
      //_cMarcaIte := Space(2)
      _cMarcaIte := _cMarca
   EndIf 
   
   _nRegAtu := TRBSZW->(Recno())

   TRBSZW->(DBGoTop())

   While ! TRBSZW->(Eof())
         
      aAdd(_aItensPV,TRBSZW->(Recno()))

      TRBSZW->(DBSkip())
   EndDo 
   
   //==============================================================================
   // Um RecLock dentro de um While, as vezes desposiciona o ponteiro de registros 
   // e encerra o While antes de terminar o processamento de todos os registros.
   // Utilizando um For...Next como alternativa.
   //==============================================================================
   For _nI := 1 To Len(_aItensPV)  
       TRBSZW->(DBGoTo(_aItensPV[_nI]))
       TRBSZW->MARCA := _cMarcaIte
       TRBSZW->(MSUnLock())
   Next 

   TRBSZW->(DBGoTop())

End Sequence 

_oMarkBRW:Refresh()

Return 

/*
===============================================================================================================================
Função-------------: MOMS071E
Autor--------------: Julio de Paula Paz
Data da Criacao----: 04/04/2024
===============================================================================================================================
Descrição----------: Excluindo Pedidos de Vendas Selecionados em modo tela, com data de rejeição superior ao numero de dias
                     configurado em Parâmetro. 
                     Em modo Scheduller,  exclui todos os pedidos de vendas rejeitados, com data de rejeição superior ao numero
                     de dias configurado em parâmetro.
===============================================================================================================================
Parametros---------: _lScheduller = .T. = Rotina rodada em modo Scheduller.
                                    .F. = Rotina rodada em tela.
===============================================================================================================================
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS071E(_lScheduller)

Local _aTRBRecno := {}
Local _nI 

Begin Sequence     
    
   If ! _lScheduller
      If ! U_ITMsg("Confirma a exclusão dos Pedidos de Vendas do Portal Rejeitados?","Exclusão de Pedidos de Vendas Rejeitados do Portal.",,2,2,2) 
         Break 
      EndIf 
   EndIf  

   TRBSZW->(DBGoTop())

   _aTRBRecno := {}
   While ! TRBSZW->(Eof())
         
      If ! Empty(TRBSZW->MARCA) // Exclui os pedidos do portal.
         SZW->(DBGoTo(TRBSZW->WK_RECNO))
         SZW->(RecLock("SZW",.F.))
         SZW->(DbDelete())
         SZW->(MSUnLock())

         aAdd(_aTRBRecno,TRBSZW->(Recno()))
      EndIf 

      TRBSZW->(DBSkip())
   EndDo 

   If ! Empty(_aTRBRecno) // Exclui os Pedidos da tabela temporária.
      For _nI := 1 To Len(_aTRBRecno)
          TRBSZW->(DBGoTo(_aTRBRecno[_nI]))
          TRBSZW->(RecLock("TRBSZW",.F.))
          TRBSZW->(DbDelete())
          TRBSZW->(MSUnLock())
      Next 
   EndIf 

   If ! _lScheduller
      U_ITMsg("Exclusão de pedidos de vendas do Portal concluida.","Atenção",,1)       
   Else 
      U_ITCONOUT("[MOMS071E] - Exclusão de pedidos de vendas do Portal concluida.")       
   EndIf 

End Sequence 

TRBSZW->(DBGoTop())

If ! _lScheduller
   _oMarkBRW:Refresh()
EndIf 

Return
