/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa      | 23/08/2017 | Ajustes gerais para a Versão 12 - Chamado 20782			                                  
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 26/06/2019 | Revisão para loboguara - Chamado 28886 
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: COMS005
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/05/2016
===============================================================================================================================
Descrição---------: Rotina de Consulta de Pedidos Transferidos - Chamado 15222
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function COMS005()

Local _aCamposTab := {}
Local _lInverte := .F. , _cMarca := .F.
Local _lRet := .T.
Local _aSizeAut  := MsAdvSize(.T.)

Private _dDataIni:= cTod("  /  /  "), _dDataFim := cTod("  /  /  ") 
Private _aCampos := {}
Private _oMark, _oDlg,_oPanel
Private _cPedido := Space(TamSX3("C5_I_PEDOR")[1])

Begin Sequence
   //================================================================================
   // Tela de Parametros iniciais.
   //================================================================================
   If ! COMS005T()
      Break
   EndIf
   
   //================================================================================
   // Cria tabela temporária.
   //================================================================================
   aAdd(_aCamposTab,{"C5_I_PEDOR","C",TamSX3("C5_I_PEDOR")[1],0 })
   aAdd(_aCamposTab,{"C5_I_DTRAN","D",TamSX3("C5_I_DTRAN")[1],0 })
   aAdd(_aCamposTab,{"C5_I_UTRAN","C",TamSX3("C5_I_UTRAN")[1],0 })
   aAdd(_aCamposTab,{"C5_FILIAL" ,"C",TamSX3("C5_FILIAL")[1],0 })
   aAdd(_aCamposTab,{"WKNOMEFIL" ,"C",30,0})
   aAdd(_aCamposTab,{"C5_NUM"    ,"C",TamSX3("C5_NUM")[1],0 })
   aAdd(_aCamposTab,{"C5_I_MTRAN","C",TamSX3("C5_I_MTRAN")[1],0 })
   
   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
   //================================================================================
   If Select("TRBSC5") > 0
      TRBSC5->( DBCloseArea() )
   EndIf

   //================================================================================
   // Permite o uso do arquivo criado dentro do protheus.
   //================================================================================
   _otemp := FWTemporaryTable():New( "TRBSC5", _aCamposTab )

   _otemp:AddIndex( "01", {"C5_I_PEDOR"} )
   _otemp:AddIndex( "02", {"C5_NUM"} )

   _otemp:Create()  
   
   //================================================================================
   // Monta query e carrega dados na tabela temporária.
   //================================================================================
   Processa( {|| _lRet := U_COMS005D() }, "Aguarde...", "Pesquisando pedidos de vendas transferidos...",.F.)
   If ! _lRet
      U_ITMsg("Não existem dados a serem exibidos.","Atenção",,1)
      Break
   EndIf
   
   //================================================================================
   // Monta colunas do MsSelect()
   //================================================================================
                    //Campo        , "" , Titulo                                           , Picture   
   aAdd( _aCampos , { "C5_I_PEDOR"	, "" , Posicione("SX3",2,"C5_I_PEDOR","X3_TITULO")		, Posicione("SX3",2,"C5_I_PEDOR","X3_PICTURE") } )
   aAdd( _aCampos , { "C5_I_DTRAN"	, "" , Posicione("SX3",2,"C5_I_DTRAN","X3_TITULO")		, Posicione("SX3",2,"C5_I_DTRAN","X3_PICTURE") } )    
   aAdd( _aCampos , { "C5_I_UTRAN"	, "" , Posicione("SX3",2,"C5_I_UTRAN","X3_TITULO")		, Posicione("SX3",2,"C5_I_UTRAN","X3_PICTURE") } )
   aAdd( _aCampos , { "C5_FILIAL"	, "" , Posicione("SX3",2,"C5_FILIAL","X3_TITULO")		, Posicione("SX3",2,"C5_FILIAL" ,"X3_PICTURE")   } )
   aAdd( _aCampos , { "WKNOMEFIL"	, "" , "Nome da Filial"		                            , " "                                          } )    
   aAdd( _aCampos , { "C5_NUM"     , "" , "Pedido Atual"                                   , Posicione("SX3",2,"C5_NUM"    ,"X3_PICTURE")      } )
   aAdd( _aCampos , { "C5_I_MTRAN" , "" , Posicione("SX3",2,"C5_I_MTRAN","X3_TITULO")      , Posicione("SX3",2,"C5_I_MTRAN"  ,"X3_PICTURE")    } )   
   
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   DEFINE MSDIALOG _oDlg Title "Consulta de Pedidos Transferidos" From 9,0 To 200,80 Of oMainWnd
      _oDlg:lMaximized:=.T.
      _oPanel := TPanel():New(0,0,'',_oDlg,, .T., .T.,, ,100,20,.T.,.T. )
      
      @ 05,10  Say "Numero Pedido: " Of _oPanel Pixel
      @ 05,55  Get _cPedido Of _oPanel Pixel
      @ 05,100 BUTTON _oButton  PROMPT "Pesq.Ped.Origem " SIZE 65,10   Of _oPanel Pixel ACTION U_COMS005P("ORIGEM") 
      @ 05,180 BUTTON _oButton2 PROMPT "Pesq.Ped.Atual  " SIZE 65,10   Of _oPanel Pixel ACTION U_COMS005P("ATUAL")
             
      _oMark := MsSelect():New("TRBSC5","","",_aCampos,@_lInverte, @_cMarca,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]})
 
   ACTIVATE MSDIALOG _oDlg On Init (EnchoiceBar(_oDlg,{|| _oDlg:End()},{|| _oDlg:End()}),_oPanel:align:= CONTROL_ALIGN_TOP,_oMark:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT,_oMark:oBrowse:Refresh()) CENTERED 
   
End Sequence

//================================================================================
// Exclui Tabelas Temporárias
//================================================================================
If Select("TRBSC5") > 0
   TRBSC5->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Função------------: COMS005T()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/05/2016
===============================================================================================================================
Descrição---------: Tela de parametros inicias da rotina Consulta de Pedidos Transferidos.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS005T()

Local _lRet := .F.
Local _bOK := {||_lRet:= .T., _oDlg:End()}
Local _bCancel := {||_lRet:= .F., _oDlg:End()} 
Local _cTitulo := "Consulta de Pedidos Transferidos"
Local _oDlg
Local _oPanel

Begin Sequence
   //================================================================================
   // Monta Tela de parâmetros inicias.
   //================================================================================
   DEFINE MSDIALOG _oDlg TITLE _cTitulo From 05,05 To 150,320 Of oMainWnd Pixel 
      _oPanel := TPanel():New(0,0,'',_oDlg,, .T., .T.,, ,320,150,.T.,.T. )
      @ 05,10 Say "Data Inicial: " Of _oPanel Pixel
      @ 05,40 Get _dDataIni Size 35,10 Of _oPanel Pixel
      
      @ 20,10 Say "Data Final: " Of _oPanel Pixel
      @ 20,40 Get _dDataFim Size 35,10 Valid(COMS005V()) Of _oPanel Pixel

   ACTIVATE MSDIALOG _oDlg On Init (EnchoiceBar(_oDlg,_bOK,_bCancel),_oPanel:align:= CONTROL_ALIGN_ALLCLIENT) CENTERED

End Sequence

Return _lRet 

/*
===============================================================================================================================
Função------------: COMS005V()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/05/2016
===============================================================================================================================
Descrição---------: Função de validação das datas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS005V()

Local _lRet := .T.

Begin Sequence
   If Empty(_dDataFim) .And. ! Empty(_dDataIni)
      U_ITMsg("A data final deve ser preenchida.","Atenção",,1)
      _lRet := .F.
   ElseIf _dDataFim < _dDataIni
      U_ITMsg("A data inicial não pode ser superior a data final.","Atenção",,1)
      _lRet := .F.
   EndIf   

End Sequence

Return _lRet

/*
===============================================================================================================================
Função------------: COMS005P()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/05/2016
===============================================================================================================================
Descrição---------: Realiza pesquisa nos dados do MSSelect, para localizar um numero de pedido atual ou de origem.
===============================================================================================================================
Parametros--------: _cTipo : Determina se a pesquisa será realizada em cima do pedido atual ou de origem
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function COMS005P(_cTipo)

Local _lRet := .F.

Begin Sequence
   If _cTipo == "ORIGEM"
      TRBSC5->(DBSetOrder(1))
   Else
      TRBSC5->(DBSetOrder(2))
   EndIf
      
   TRBSC5->(DBSeek(_cPedido))
     
   _oMark:oBrowse:Refresh()
   
End Sequence

Return _lRet 

/*
===============================================================================================================================
Função------------: COMS005D()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/05/2016
===============================================================================================================================
Descrição---------: Monta query e carrega dados na tabela temporária.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function COMS005D()

Local _lRet := .T.
Local _cQry
Local _nTotreg, _nI

Begin Sequence
   //================================================================================
   // Monta Query de Seleção de Dados
   //================================================================================
   _cQry := "SELECT C5_I_PEDOR, C5_I_DTRAN, C5_I_UTRAN, C5_FILIAL, C5_NUM, C5_I_MTRAN "
   _cQry += " FROM "+RetSqlName("SC5")+" SC5 " 
   _cQry += " WHERE SC5.D_E_L_E_T_ = ' ' " 
   _cQry += " AND C5_I_FILOR = '"+xFilial("SC5")+"' "
   
   If ! Empty(_dDataIni)
      _cQry += " AND C5_I_DTRAN >= '"+DToS(_dDataIni)+"' "   
   EndIf
   
   If ! Empty(_dDataFim)
      _cQry += " AND C5_I_DTRAN <= '"+DToS(_dDataFim)+"' "   
   EndIf
   
   If Select("QRYSC5") > 0
      QRYSC5->(DBCloseArea())
   EndIf
   
   _cQry := ChangeQuery(_cQry) 
   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYSC5", .F., .T.)
   
   TCSetField("QRYSC5","C5_I_DTRAN","D")
   
   If QRYSC5->(Eof()) .Or. QRYSC5->(Bof())
      _lRet := .F.
      Break
   EndIf   
   
   //================================================================================
   // Realiza a contagem de registros e posiciona no inicio da tabela temporária
   //================================================================================
   COUNT TO _nTotreg
   QRYSC5->( DBGoTop() )
   
   //================================================================================
   // Exibe regua de processamento
   //================================================================================
   ProcRegua(_nTotreg)
   
   //================================================================================
   // Transfere os dados da Query para tabela temporária.
   //================================================================================
   _nI := 1
   While ! QRYSC5->(Eof())
      IncProc("Processando registro: "+StrZero(_nI,6)+"/"+StrZero(_nTotreg,6))
      
      TRBSC5->(DbAppend())
      TRBSC5->C5_I_PEDOR := QRYSC5->C5_I_PEDOR 
      TRBSC5->C5_I_DTRAN := QRYSC5->C5_I_DTRAN
      TRBSC5->C5_I_UTRAN := QRYSC5->C5_I_UTRAN 
      TRBSC5->C5_FILIAL  := QRYSC5->C5_FILIAL 
      TRBSC5->WKNOMEFIL  := COMS005R(QRYSC5->C5_FILIAL) 
      TRBSC5->C5_NUM     := QRYSC5->C5_NUM
      TRBSC5->C5_I_MTRAN := QRYSC5->C5_I_MTRAN
      TRBSC5->(MSUnLock())
      
      QRYSC5->(DBSkip())
   EndDo

End Sequence

If Select("QRYSC5") > 0
	QRYSC5->( DBCloseArea() )
EndIf

TRBSC5->( DBGoTop() )

Return _lRet

/*
===============================================================================================================================
Função------------: COMS005R()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/05/2016
===============================================================================================================================
Descrição---------: Retorna o nome da filial com base no codigo da filial
===============================================================================================================================
Parametros--------: _cCodFil : Codigo da filial a ser utilizado na pesquisa.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function COMS005R(_cCodFil)

Local _cRet := Space(30)
Local aOrd := SaveOrd({"SM0"})

Begin Sequence
   SM0->(DBSetOrder(1))
   If SM0->(DBSeek(cEmpAnt+_cCodFil))
      _cRet := SM0->M0_FILIAL
   EndIf
   
End Sequence

RestOrd(aOrd,.T.)

Return _cRet
