/*
===========================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===========================================================================================================================================
 Autor            |   Data     |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 02/03/2023 | Incluir na rotina uma nova opção de filtro por código de vendedor. Chamado 42489. 
===========================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ROMS069
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/05/2022
===============================================================================================================================
Descrição---------: Painel de Comissão Gerencial. Chamado 39101.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069()
Local _lRet := .F.
Local _aStrucZBK
Local _aCmpZBK := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInverte := .F.
Local _oDlgP 
Local _nLinha, _nColuna 

Private _oMarkZBK, _cMarcaZBK := GetMark() 
Private aHeader := {} , aCols := {}

Private _cPeriodo  := Space(6) 
Private _cCodGNac  := Space(6)
Private _cCodGer   := Space(6)
Private _cCodCoord := Space(6)
Private _cCodSup   := Space(6)
Private _cCodVen   := Space(6)
Private _otemp1, _otemp2, _otemp3, _otemp4, _otemp5
Private _aItalac_F3 := {}
Private _cSelectSA3, _bCondSA3

Begin Sequence
   _cSelectSA3 := "SELECT DISTINCT A3_COD, A3_NOME FROM "+RETSQLNAME("SA3")+" SA3 WHERE SA3.D_E_L_E_T_ = ' ' AND A3_I_TIPV = 'V' ORDER BY A3_COD " 
   _bCondSA3   := NIL
   aAdd(_aItalac_F3,{"_cCodVen",_cSelectSA3,{|Tab| (Tab)->A3_COD}, {|Tab| (Tab)->A3_NOME } ,_bCondSA3 ,"Vendedores",,,1,.F.        ,       , } )

   //============================================================================
   //Montagem do aheader                                                        
   //============================================================================
   aHeader := {}
   FillGetDados(1,"ZBK",1,,,{||.T.},,,,,,.T.)
   
   //                          1                    2               3              4               5                6             7        8              9                 10 
   // aAdd(aHeader, {AllTrim(SX3->X3_TITULO), SX3->X3_CAMPO, SX3->X3_PICTURE, SX3->X3_TAMANHO, SX3->X3_DECIMAL,"AllwaysTrue()", USADO, SX3->X3_TIPO, SX3->X3_ARQUIVO, SX3->X3_CONTEXT})
   
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZBK 
   //================================================================================
   //aAdd( _aCmpZBK , { "WK_OK"		,    , "Marca"                                          ,"@!"})
   aAdd( _aCmpZBK , { "ZBK_VEND"		,    , "Código"          ,"@!"})
   aAdd( _aCmpZBK , { "ZBK_NOMVEN"	,    , "Nome"            ,"@!"})
   aAdd( _aCmpZBK , { "ZBK_COMVEN"	,    , "Valor Comissão"  ,"@E 999,999,999.99"})

   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZBK := {}
   aAdd( _aStrucZBK , { "ZBK_VEND"		, "C"   , 6   ,0})
   aAdd( _aStrucZBK , { "ZBK_NOMVEN"	, "C"   , 60  ,0})
   aAdd( _aStrucZBK , { "ZBK_COMVEN"	, "N"   , 16  ,2})
   aAdd( _aStrucZBK , { "ZBK_SUPERV"	, "C"   , 6   ,0})
   aAdd( _aStrucZBK , { "ZBK_COORDE"	, "C"   , 6   ,0})
   aAdd( _aStrucZBK , { "ZBK_GERENT"	, "C"   , 6   ,0})
   aAdd( _aStrucZBK , { "ZBK_GERNAC"	, "C"   , 6   ,0})

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZBK1") > 0
      TRBZBK1->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZBK1 criado dentro do protheus. Gerente Nacional
   //================================================================================
   _otemp1 := FWTemporaryTable():New( "TRBZBK1",  _aStrucZBK )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp1:AddIndex( "01", {"ZBK_VEND"}   )
   _otemp1:AddIndex( "02", {"ZBK_SUPERV"} )
   _otemp1:AddIndex( "03", {"ZBK_COORDE"} )
   _otemp1:AddIndex( "04", {"ZBK_GERENT"} )
   _otemp1:AddIndex( "05", {"ZBK_GERNAC"} )

   _otemp1:Create()   

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZBK2") > 0
      TRBZBK2->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZBK2 criado dentro do protheus. Gerente.
   //================================================================================
   _otemp2 := FWTemporaryTable():New( "TRBZBK2",  _aStrucZBK )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp2:AddIndex( "01", {"ZBK_VEND"} )
   _otemp2:AddIndex( "02", {"ZBK_SUPERV"} )
   _otemp2:AddIndex( "03", {"ZBK_COORDE"} )
   _otemp2:AddIndex( "04", {"ZBK_GERENT"} )
   _otemp2:AddIndex( "05", {"ZBK_GERNAC"} )

   _otemp2:Create()   

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZBK3") > 0
      TRBZBK3->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZBK3 criado dentro do protheus. Coordenador.
   //================================================================================
   _otemp3 := FWTemporaryTable():New( "TRBZBK3",  _aStrucZBK )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp3:AddIndex( "01", {"ZBK_VEND"} )
   _otemp3:AddIndex( "02", {"ZBK_SUPERV"} )
   _otemp3:AddIndex( "03", {"ZBK_COORDE"} )
   _otemp3:AddIndex( "04", {"ZBK_GERENT"} )
   _otemp3:AddIndex( "05", {"ZBK_GERNAC"} )

   _otemp3:Create()   

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZBK4") > 0
      TRBZBK4->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZBK2 criado dentro do protheus. Supervisor
   //================================================================================
   _otemp4 := FWTemporaryTable():New( "TRBZBK4",  _aStrucZBK )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp4:AddIndex( "01", {"ZBK_VEND"}   )
   _otemp4:AddIndex( "02", {"ZBK_SUPERV"} )
   _otemp4:AddIndex( "03", {"ZBK_COORDE"} )
   _otemp4:AddIndex( "04", {"ZBK_GERENT"} )
   _otemp4:AddIndex( "05", {"ZBK_GERNAC"} )

   _otemp4:Create()   

   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZBK5") > 0
      TRBZBK5->( DBCloseArea() )
   EndIf

   //================================================================================
   // Abre o arquivo TRBZBK5 criado dentro do protheus. Representantes.
   //================================================================================
   _otemp5 := FWTemporaryTable():New( "TRBZBK5",  _aStrucZBK )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp5:AddIndex( "01", {"ZBK_VEND"}   )
   _otemp5:AddIndex( "02", {"ZBK_SUPERV"} )
   _otemp5:AddIndex( "03", {"ZBK_COORDE"} )
   _otemp5:AddIndex( "04", {"ZBK_GERENT"} )
   _otemp5:AddIndex( "05", {"ZBK_GERNAC"} )

   _otemp5:Create()   

   //================================================================================
   // Carrega os dados da tabela ZBK
   //================================================================================
   _bOk := {|| _lRet := .T., _oDlgInt:End()}
   _bCancel := {|| _lRet := .F., _oDlgInt:End()}
                                           
   _cTitulo := "Painel Gerencial Comissões"
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   _nPosLin := _aSizeAut[4] / 5
   _nPosLinA :=_aSizeAut[4] - (_nPosLin * 4) 
   _nPosLinB :=_aSizeAut[4] - (_nPosLin * 3) 
   _nPosLinC :=_aSizeAut[4] - (_nPosLin * 2) 
   _nPosLinD :=_aSizeAut[4] - (_nPosLin * 1) 
   
   _nColuna := 560

   Define MsDialog _oDlgP Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] PIXEL  
      
      @ 02, 05 To 35 , 550 PIXEL 

      _nLinha := 05
      @ _nLinha     , 10 Say   "Período (MMAAAA)" Pixel Size  060,012 Of _oDlgP
      @ _nLinha + 10, 10 MSGet _cPeriodo Picture "@R 99/9999" Pixel Size  040,012 Valid (U_ROMS069V("PERIODO")) Of _oDlgP

      @ _nLinha     , 70 Say   "Gerente Nacional" Pixel Size  060,012 Of _oDlgP
      @ _nLinha + 10, 70 MSGet _cCodGNac Pixel Size  040,012 F3 "SA3_04" Valid (U_ROMS069V("GERENTE_NACIONAL")) Of _oDlgP

      @ _nLinha     , 130 Say   "Gerente" Pixel Size  060,012 Of _oDlgP
      @ _nLinha + 10, 130 MSGet _cCodGer  Pixel Size  040,012 F3 "SA3_02" Valid (U_ROMS069V("GERENTE")) Of _oDlgP

      @ _nLinha     , 190 Say   "Coordenador" Pixel Size  060,012 Of _oDlgP
      @ _nLinha + 10, 190 MSGet _cCodCoord    Pixel Size  040,012 F3 "SA3_01" Valid (U_ROMS069V("COORDENADOR")) Of _oDlgP

      @ _nLinha     , 250 Say   "Supervisor" Pixel Size  060,012 Of _oDlgP
      @ _nLinha + 10, 250 MSGet _cCodSup     Pixel Size  040,012 F3 "SA3_03" Valid (U_ROMS069V("SUPERVISOR")) Of _oDlgP

      @ _nLinha     , 310 Say   "Vendedor"   Pixel Size  060,012 Of _oDlgP
      @ _nLinha + 10, 310 MSGet _cCodVen     Pixel Size  040,012 F3 "F3ITLC" Valid (U_ROMS069V("VENDEDOR")) Of _oDlgP
      //@ _nLinha + 10, 310 MSGet _cCodVen     Pixel Size  040,012 F3 "SA3BLQ" Valid (U_ROMS069V("VENDEDOR")) Of _oDlgP

      @ _nLinha + 10, 370  BUTTON _OBtnProce PROMPT "&Processar"  SIZE 50, 012 OF _oDlgP ACTION ( If(U_ROMS069V("PROCESSAR"),U_ROMS069P(),)) PIXEL
      @ _nLinha + 10, 430  BUTTON _OBtnProce PROMPT "&Gera Excel" SIZE 50, 012 OF _oDlgP ACTION ( If(U_ROMS069V("GERA_EXCEL"),U_ROMS069E(),)) PIXEL
      @ _nLinha + 10, 490  BUTTON _OBtnSair  PROMPT "&Sair"	      SIZE 50, 012 OF _oDlgP ACTION ( _oDlgP:End() ) PIXEL

      _nLinha += 30
      @ _nLinha     , 10 Say   "Gerente Nacional" Pixel Size  060,012 Of _oDlgP

      _nLinha += 10
      _oMarkZBKA := MsSelect():New("TRBZBK1","WK_OK","",_aCmpZBK,@_lInverte, @_cMarcaZBK,{_nLinha, 5, _nLinha+35 /*_aSizeAut[4]*/ , _nColuna /*_aSizeAut[3]-250*/}) 
 
      _nLinha += 35 
      @ _nLinha     , 10 Say   "Gerente" Pixel Size  060,012 Of _oDlgP
      
      _nLinha += 10
      _oMarkZBKB := MsSelect():New("TRBZBK2","WK_OK","",_aCmpZBK,@_lInverte, @_cMarcaZBK,{_nLinha, 5, _nLinha + 50 /*_aSizeAut[4]*/ , _nColuna /*_aSizeAut[3]-250*/})
 
      _nLinha += 50
      @ _nLinha     , 10 Say   "Coordenador" Pixel Size  060,012 Of _oDlgP

      _nLinha += 10
      _oMarkZBKC := MsSelect():New("TRBZBK3","WK_OK","",_aCmpZBK,@_lInverte, @_cMarcaZBK,{_nLinha, 5, _nLinha + 50 /*_aSizeAut[4]*/ , _nColuna /*_aSizeAut[3]-250*/})
 
      _nLinha += 50
      @ _nLinha     , 10 Say   "Supervisor" Pixel Size  060,012 Of _oDlgP

      _nLinha += 10
      _oMarkZBKD := MsSelect():New("TRBZBK4","WK_OK","",_aCmpZBK,@_lInverte, @_cMarcaZBK,{_nLinha, 5, _nLinha + 50  /*_aSizeAut[4]*/ , _nColuna /*_aSizeAut[3]-250*/})
 
      _nLinha += 50
      @ _nLinha     , 10 Say   "Vendedor" Pixel Size  060,012 Of _oDlgP

      _nLinha += 10
      _oMarkZBKE := MsSelect():New("TRBZBK5","WK_OK","",_aCmpZBK,@_lInverte, @_cMarcaZBK,{_nLinha, 5, _nLinha + 50 /*_aSizeAut[4]*/ , _nColuna /*_aSizeAut[3]-250*/})
 
    ACTIVATE MSDIALOG _oDlgP CENTERED

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZBK1") > 0
   TRBZBK1->(DBCloseArea())
EndIf

If Select("TRBZBK2") > 0
   TRBZBK2->(DBCloseArea())
EndIf

If Select("TRBZBK3") > 0
   TRBZBK3->(DBCloseArea())
EndIf

If Select("TRBZBK4") > 0
   TRBZBK4->(DBCloseArea())
EndIf

If Select("TRBZBK5") > 0
   TRBZBK5->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS069V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/05/2022
===============================================================================================================================
Descrição---------: Painel de Comissão Gerencial.
===============================================================================================================================
Parametros--------: _cCampo = Campo que chamou a validação.
===============================================================================================================================
Retorno-----------: _lRet = .T. = Validação Ok
                            .F. = Validação Incorreta.
===============================================================================================================================
*/
User Function ROMS069V(_cCampo)
Local _lRet := .T.
Local _cDtPer, _dDtPer  

Begin Sequence

   If _cCampo == "PERIODO"
      If Empty(_cPeriodo)
         Break 
      EndIf 

      _cDtPer := "01/" + SubStr(_cPeriodo,1,2)+"/"+ SubStr(_cPeriodo,3,4)
      _dDtPer := Ctod(_cDtPer)
      
      ZBK->(DBSetOrder(1))
      If ! ZBK->(MsSeek(xFilial("ZBK")+DToS(_dDtPer)))
         U_ITMsg("Não foi localizado nenhum fechamento de comissão processado para o período informado.","Atenção","Por favor, informe um período que possua fechamento de comissão processado.",1)
         _lRet := .F.
         Break  
      EndIf 
 
   ElseIf _cCampo == "GERENTE_NACIONAL"
      If Empty(_cCodGNac)
         Break 
      EndIf 

      SA3->(DBSetOrder(1))
      If ! SA3->(MsSeek(xFilial("SA3")+_cCodGNac))
         U_ITMsg("Não foi localizado nenhum Gerente Nacional com o código informado.","Atenção", ,1)
         _lRet := .F.
         Break  
      Else 
         //_cCodGNac  := Space(6)
         _cCodGer   := Space(6)
         _cCodCoord := Space(6)
         _cCodSup   := Space(6)
         _cCodVen   := Space(6) 
      EndIf 

   ElseIf _cCampo == "GERENTE"
      If Empty(_cCodGer)
         Break 
      EndIf 

      SA3->(DBSetOrder(1))
      If ! SA3->(MsSeek(xFilial("SA3")+_cCodGer))
         U_ITMsg("Não foi localizado nenhum Gerente com o código informado.","Atenção", ,1)
         _lRet := .F.
         Break  
      Else 
         _cCodGNac  := Space(6)
         //_cCodGer   := Space(6)
         _cCodCoord := Space(6)
         _cCodSup   := Space(6)
         _cCodVen   := Space(6) 
      EndIf 

   ElseIf _cCampo == "COORDENADOR"
      
      If Empty(_cCodCoord)
         Break 
      EndIf 

      SA3->(DBSetOrder(1))
      If ! SA3->(MsSeek(xFilial("SA3")+_cCodCoord))
         U_ITMsg("Não foi localizado nenhum Coordenador com o código informado.","Atenção", ,1)
         _lRet := .F.
         Break  
      Else 
         _cCodGNac  := Space(6)
         _cCodGer   := Space(6)
         //_cCodCoord := Space(6)
         _cCodSup   := Space(6) 
         _cCodVen   := Space(6)
      EndIf 

   ElseIf _cCampo == "SUPERVISOR"
      If Empty(_cCodSup)
         Break 
      EndIf 

      SA3->(DBSetOrder(1))
      If ! SA3->(MsSeek(xFilial("SA3")+_cCodSup))
         U_ITMsg("Não foi localizado nenhum Supervisor com o código informado.","Atenção", ,1)
         _lRet := .F.
         Break  
      Else 
         _cCodGNac  := Space(6)
         _cCodGer   := Space(6)
         _cCodCoord := Space(6)
         //_cCodSup   := Space(6) 
         _cCodVen   := Space(6) 
      EndIf 
   
   ElseIf _cCampo == "VENDEDOR"
      If Empty(_cCodVen)
         Break 
      EndIf 

      SA3->(DBSetOrder(1))
      If ! SA3->(MsSeek(xFilial("SA3")+_cCodVen))
         U_ITMsg("Não foi localizado nenhum Vendedor com o código informado.","Atenção", ,1)
         _lRet := .F.
         Break  
      Else 
         _cCodGNac  := Space(6)
         _cCodGer   := Space(6)
         _cCodCoord := Space(6)
         _cCodSup   := Space(6) 
      EndIf 
    
   ElseIf _cCampo == "PROCESSAR"

      If Empty(_cPeriodo)
         U_ITMsg("É obrigatório o preenchimento do perído para rodar esta rotina.","Atenção",,1)
         _lRet := .F.
         Break 
      EndIf 

      _cDtPer := "01/" + SubStr(_cPeriodo,1,2)+"/"+ SubStr(_cPeriodo,3,4)
      _dDtPer := Ctod(_cDtPer)
      
      ZBK->(DBSetOrder(1))
      If ! ZBK->(MsSeek(xFilial("ZBK")+DToS(_dDtPer)))
         U_ITMsg("Não foi localizado nenhum fechamento de comissão processado para o período informado.","Atenção","Por favor, informe um período que possua fechamento de comissão processado.",1)
         _lRet := .F.
         Break  
      EndIf 
      
      SA3->(DBSetOrder(1))
      If ! Empty(_cCodGNac)
         If ! SA3->(MsSeek(xFilial("SA3")+_cCodGNac))
            U_ITMsg("Não foi localizado nenhum Gerente Nacional com o código informado.","Atenção", ,1)
            _lRet := .F.
            Break  
         EndIf 
      EndIf 

      If ! Empty(_cCodGer)
         If ! SA3->(MsSeek(xFilial("SA3")+_cCodGer))
            U_ITMsg("Não foi localizado nenhum Gerente com o código informado.","Atenção", ,1)
            _lRet := .F.
            Break  
         EndIf  
      EndIf 
      
      If ! Empty(_cCodCoord)
         If ! SA3->(MsSeek(xFilial("SA3")+_cCodCoord))
            U_ITMsg("Não foi localizado nenhum Coordenador com o código informado.","Atenção", ,1)
            _lRet := .F.
            Break  
         EndIf 
      EndIf 

      If ! Empty(_cCodSup)
         If ! SA3->(MsSeek(xFilial("SA3")+_cCodSup))
            U_ITMsg("Não foi localizado nenhum Supervisor com o código informado.","Atenção", ,1)
            _lRet := .F.
            Break  
         EndIf   
      EndIf 

      If ! Empty(_cCodVen)
         If ! SA3->(MsSeek(xFilial("SA3")+_cCodVen))
            U_ITMsg("Não foi localizado nenhum Vendedor com o código informado.","Atenção", ,1)
            _lRet := .F.
            Break  
         EndIf   
      EndIf 

      If Empty(_cCodGNac) .And. Empty(_cCodGer) .And. Empty(_cCodCoord) .And. Empty(_cCodSup) .And. Empty(_cCodVen)
         U_ITMsg("Para rodar esta rotina é obrigatório informar um código para um dos campos: Gerente Nacional ou Gerente ou Coordenador ou Supervisor ou Vendedor.","Atenção", ,1)
         _lRet := .F.
         Break  
      EndIf 

   ElseIf _cCampo == "GERA_EXCEL"
      
      If Empty(_cPeriodo)
         U_ITMsg("É obrigatório o preenchimento do perído para Gerar os dados em Excel.","Atenção",,1)
         _lRet := .F.
         Break 
      EndIf 

      If Empty(_cCodGNac) .And. Empty(_cCodGer) .And. Empty(_cCodCoord) .And. Empty(_cCodSup) .And. Empty(_cCodVen)
         U_ITMsg("Para gerar os dados em Excel é obrigatório informar um código para um dos campos: Gerente Nacional ou Gerente ou Coordenador ou Supervisor ou Vendedor.","Atenção", ,1)
         _lRet := .F.
         Break  
      EndIf   
   
      If ! Empty(_cCodGNac)
         TRBZBK1->(DBGoTop())
         If TRBZBK1->(Eof()) .Or. TRBZBK1->(Bof()) 
            U_ITMsg("Não há dados para emissão do relatório em excel.","Atenção",,1)
            _lRet := .F.
            Break 
         EndIf

      ElseIf ! Empty(_cCodGer)
         TRBZBK2->(DBGoTop())
         If TRBZBK2->(Eof()) .Or. TRBZBK2->(Bof()) 
            U_ITMsg("Não há dados para emissão do relatório em excel.","Atenção",,1)
            _lRet := .F.
            Break 
         EndIf

      ElseIf ! Empty(_cCodCoord)
         TRBZBK3->(DBGoTop())
         If TRBZBK3->(Eof()) .Or. TRBZBK3->(Bof()) 
            U_ITMsg("Não há dados para emissão do relatório em excel.","Atenção",,1)
            _lRet := .F.
            Break 
         EndIf

      ElseIf ! Empty(_cCodSup)
         TRBZBK4->(DBGoTop())
         If TRBZBK4->(Eof()) .Or. TRBZBK4->(Bof()) 
            U_ITMsg("Não há dados para emissão do relatório em excel.","Atenção",,1)
            _lRet := .F.
            Break 
         EndIf

      ElseIf ! Empty(_cCodVen)
         TRBZBK5->(DBGoTop())
         If TRBZBK5->(Eof()) .Or. TRBZBK5->(Bof()) 
            U_ITMsg("Não há dados para emissão do relatório em excel.","Atenção",,1)
            _lRet := .F.
            Break 
         EndIf

      EndIf

   EndIf 

End Sequence 

Return _lRet

/*
===============================================================================================================================
Programa----------: ROMS069P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/05/2022
===============================================================================================================================
Descrição---------: Gera os dados para o painel com base no filtro e no código informado para uma das opções da tela:
                    - Gerente Nacional
                    - Gerente
                    - Coordenador
                    - Supervisor
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069P()

Begin Sequence  
   
   If ! Empty(_cCodGNac)
      If U_ITMsg("Confirma a geração dos dados do Painel Gerencial de Comissões, tendo como base o código do Gerente Nacional? ", "Atenção", "",2,2,2) 
         Processa( {|| U_ROMS069N() }, "Aguarde...", "Gerando dados do painel... ",.F.) 
      EndIf 

   ElseIf ! Empty(_cCodGer)
      If U_ITMsg("Confirma a geração dos dados do Painel Gerencial de Comissões, tendo como base o código do Gerente? ", "Atenção", "",2,2,2) 
         Processa( {|| U_ROMS069G() }, "Aguarde...", "Gerando dados do painel... ",.F.) 
      EndIf 

   ElseIf ! Empty(_cCodCoord )
      If U_ITMsg("Confirma a geração dos dados do Painel Gerencial de Comissões, tendo como base o código do Coordenador? ", "Atenção", "",2,2,2) 
         Processa( {|| U_ROMS069C() }, "Aguarde...", "Gerando dados do painel... ",.F.) 
      EndIf 

   ElseIf ! Empty(_cCodSup)
      If U_ITMsg("Confirma a geração dos dados do Painel Gerencial de Comissões, tendo como base o código do Supervisor? ", "Atenção", "",2,2,2) 
         Processa( {|| U_ROMS069S() }, "Aguarde...", "Gerando dados do painel... ",.F.) 
      EndIf 

   ElseIf ! Empty(_cCodVen)
      If U_ITMsg("Confirma a geração dos dados do Painel Gerencial de Comissões, tendo como base o código do Vendedor? ", "Atenção", "",2,2,2) 
         Processa( {|| U_ROMS069R() }, "Aguarde...", "Gerando dados do painel... ",.F.) 
      EndIf 

   EndIf 

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ROMS069N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/05/2022
===============================================================================================================================
Descrição---------: Gera os dados para o painel para o Gerente Nacional e estruturas hierárquicas subordinadas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069N()
Local _cQry, _cPeriodoQry  
Local _dFechamen, _cVersao

Begin Sequence 
   
   //============================================================================
   // Limpando o conteúdo das tabelas temporárias para gravação de novos dados.
   //============================================================================
   _otemp1:Zap()
   _otemp2:Zap()
   _otemp3:Zap()
   _otemp4:Zap()
   _otemp5:Zap()

   //============================================================================
   // Grava dados das comissões nas tabela temporárias representantes.
   //============================================================================
   ProcRegua(0)

   _dFechamen := Ctod("01/" + SubStr(_cPeriodo,1,2) + "/" + SubStr(_cPeriodo,3,4))
   
   _cVersao := U_ROMS069W(_dFechamen) // Retorna a ultima versão gravada para o período informado.
   
   IncProc("Lendo dados das comissões dos Representantes...")

   _cPeriodoQry := SubStr(_cPeriodo,3,4) + SubStr(_cPeriodo,1,2)
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_VEND, ZBK_NOMVEN, "
   _cQry += " SUM(ZBK_COMVEN) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " GROUP BY ZBK_VEND, ZBK_NOMVEN "
   _cQry += " ORDER BY ZBK_VEND "
   
   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      IncProc("Gravando dados Representante: " + TRBQRY->ZBK_VEND + "-" + AllTrim(TRBQRY->ZBK_NOMVEN))

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_VEND))

      If SA3->A3_I_TIPV == "V" // V=VENDEDOR;
         TRBZBK5->(DbAppend())
         TRBZBK5->ZBK_VEND   := TRBQRY->ZBK_VEND
         TRBZBK5->ZBK_NOMVEN := TRBQRY->ZBK_NOMVEN
         TRBZBK5->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK5->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK5->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK5->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK5->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK5->(MSUnLock())

      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf
   
   //============================================================================
   // Grava dados das comissões nas tabela temporárias supervisores.
   //============================================================================
   IncProc("Lendo dados das comissões dos Supervisores...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_SUPERV, "
   _cQry += " SUM(ZBK_COMSUP) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " GROUP BY ZBK_SUPERV "
   _cQry += " ORDER BY ZBK_SUPERV "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_SUPERV))

      IncProc("Gravando dados Supervisor: " + TRBQRY->ZBK_SUPERV + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "S" // S=SUPERVISOR; 
         TRBZBK4->(DbAppend())
         TRBZBK4->ZBK_VEND   := TRBQRY->ZBK_SUPERV
         TRBZBK4->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK4->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK4->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK4->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK4->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK4->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK4->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias coordenadores.
   //============================================================================
   IncProc("Lendo dados das comissões dos Coordenadores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_COORDE, "
   _cQry += " SUM(ZBK_COMCOO) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " GROUP BY ZBK_COORDE "
   _cQry += " ORDER BY ZBK_COORDE "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_COORDE))
      
      IncProc("Gravando dados Coordenador: " + TRBQRY->ZBK_COORDE + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "C" // C=COORDENADOR
         TRBZBK3->(DbAppend())
         TRBZBK3->ZBK_VEND   := TRBQRY->ZBK_COORDE
         TRBZBK3->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK3->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK3->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK3->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK3->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK3->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK3->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerentes.
   //============================================================================
   IncProc("Lendo dados das comissões dos Gerentes...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERENT, "
   _cQry += " SUM(ZBK_COMGER) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " GROUP BY ZBK_GERENT "
   _cQry += " ORDER BY ZBK_GERENT "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERENT))
      
      IncProc("Gravando dados Gerente: " + TRBQRY->ZBK_GERENT+ "-" + AllTrim(SA3->A3_NOME))

//      If SA3->A3_I_TIPV == "G" // G=GERENTE;                                                              
         TRBZBK2->(DbAppend())
         TRBZBK2->ZBK_VEND   := TRBQRY->ZBK_GERENT
         TRBZBK2->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK2->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK2->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK2->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK2->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK2->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK2->(MSUnLock())
//      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerente nacional.
   //============================================================================
   IncProc("Lendo dados das comissões do Gerente Nacional...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERNAC, "
   _cQry += " SUM(ZBK_COMGNC) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') + " ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " GROUP BY ZBK_GERNAC "
   _cQry += " ORDER BY ZBK_GERNAC "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERNAC))

      IncProc("Gravando dados Gerente Nacional: " + TRBQRY->ZBK_GERNAC + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "N"  // N=GERENTE NACIONAL 
         TRBZBK1->(DbAppend())
         TRBZBK1->ZBK_VEND   := TRBQRY->ZBK_GERNAC
         TRBZBK1->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK1->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK1->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK1->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK1->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK1->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK1->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   TRBZBK1->(DBGoTop())
   TRBZBK2->(DBGoTop())
   TRBZBK3->(DBGoTop())
   TRBZBK4->(DBGoTop())
   TRBZBK5->(DBGoTop())

End Sequence 

Return 

/*
===============================================================================================================================
Programa--------: ROMS069W
Autor-----------: Julio de Paula Paz
Data da Criacao-: 21/11/2019
===============================================================================================================================
Descrição-------: Retorna a ultima versão gravada na tabela ZBK para o período informado.
===============================================================================================================================
Parametros------: _dDtFecham = Data de fechamento
===============================================================================================================================
Retorno---------: _nRet = Retorna a ultima sequencia gravada para o perído informado.
===============================================================================================================================
*/
User Function ROMS069W(_dDtFecham)
Local _cRet := "001"
Local _cQry 

Begin Sequence 

   _cQry := " SELECT Max(ZBK_VERSAO) VERSAO "
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZBK_DTFECH = '" + DToS(_dDtFecham) +"' "   
   
   If Select("TRBZBK") > 0
      TRBZBK->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBZBK" , .T. , .F. )

   If ! TRBZBK->(Eof()) .And. ! TRBZBK->(Bof())
      _cRet := TRBZBK->VERSAO
   EndIf 

End Sequence 

Return _cRet 

/*
===============================================================================================================================
Programa----------: ROMS069G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2022
===============================================================================================================================
Descrição---------: Gera os dados para o painel para o Gerente e estruturas hierárquicas subordinadas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069G()
Local _cQry, _cPeriodoQry  
Local _dFechamen, _cVersao

Begin Sequence 
   
   //============================================================================
   // Limpando o conteúdo das tabelas temporárias para gravação de novos dados.
   //============================================================================
   _otemp1:Zap()
   _otemp2:Zap()
   _otemp3:Zap()
   _otemp4:Zap()
   _otemp5:Zap()

   //============================================================================
   // Grava dados das comissões nas tabela temporárias representantes.
   //============================================================================
   ProcRegua(0)

   _dFechamen := Ctod("01/" + SubStr(_cPeriodo,1,2) + "/" + SubStr(_cPeriodo,3,4))
   
   _cVersao := U_ROMS069W(_dFechamen) // Retorna a ultima versão gravada para o período informado.
   
   IncProc("Lendo dados das comissões dos Representantes...")

   _cPeriodoQry := SubStr(_cPeriodo,3,4) + SubStr(_cPeriodo,1,2)
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_VEND, ZBK_NOMVEN, "
   _cQry += " SUM(ZBK_COMVEN) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_GERENT = '" + _cCodGer + "' "
   _cQry += " GROUP BY ZBK_VEND, ZBK_NOMVEN "
   _cQry += " ORDER BY ZBK_VEND "
   
   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      IncProc("Gravando dados Representante: " + TRBQRY->ZBK_VEND + "-" + AllTrim(TRBQRY->ZBK_NOMVEN))

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_VEND))

      If SA3->A3_I_TIPV == "V" // V=VENDEDOR;
         TRBZBK5->(DbAppend())
         TRBZBK5->ZBK_VEND   := TRBQRY->ZBK_VEND
         TRBZBK5->ZBK_NOMVEN := TRBQRY->ZBK_NOMVEN
         TRBZBK5->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK5->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK5->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK5->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK5->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK5->(MSUnLock())

      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf
   
   //============================================================================
   // Grava dados das comissões nas tabela temporárias supervisores.
   //============================================================================
   IncProc("Lendo dados das comissões dos Supervisores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_SUPERV, "
   _cQry += " SUM(ZBK_COMSUP) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_GERENT = '" + _cCodGer + "' "   
   _cQry += " GROUP BY ZBK_SUPERV "
   _cQry += " ORDER BY ZBK_SUPERV "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_SUPERV))

      IncProc("Gravando dados Supervisor: " + TRBQRY->ZBK_SUPERV + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "S" // S=SUPERVISOR; 
         TRBZBK4->(DbAppend())
         TRBZBK4->ZBK_VEND   := TRBQRY->ZBK_SUPERV
         TRBZBK4->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK4->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK4->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK4->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK4->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK4->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK4->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias coordenadores.
   //============================================================================
   IncProc("Lendo dados das comissões dos Coordenadores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_COORDE, "
   _cQry += " SUM(ZBK_COMCOO) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_GERENT = '" + _cCodGer + "' "   
   _cQry += " GROUP BY ZBK_COORDE "
   _cQry += " ORDER BY ZBK_COORDE "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_COORDE))
      
      IncProc("Gravando dados Coordenador: " + TRBQRY->ZBK_COORDE + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "C" // C=COORDENADOR
         TRBZBK3->(DbAppend())
         TRBZBK3->ZBK_VEND   := TRBQRY->ZBK_COORDE
         TRBZBK3->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK3->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK3->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK3->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK3->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK3->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK3->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerentes.
   //============================================================================
   IncProc("Lendo dados das comissões dos Gerentes...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERENT, "
   _cQry += " SUM(ZBK_COMGER) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_GERENT = '" + _cCodGer + "' "   
   _cQry += " GROUP BY ZBK_GERENT "
   _cQry += " ORDER BY ZBK_GERENT "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERENT))
      
      IncProc("Gravando dados Gerente: " + TRBQRY->ZBK_GERENT+ "-" + AllTrim(SA3->A3_NOME))

//      If SA3->A3_I_TIPV == "G" // G=GERENTE;                                                              
         TRBZBK2->(DbAppend())
         TRBZBK2->ZBK_VEND   := TRBQRY->ZBK_GERENT
         TRBZBK2->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK2->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK2->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK2->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK2->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK2->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK2->(MSUnLock())
//      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerente nacional.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões do Gerente Nacional...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERNAC, "
   _cQry += " SUM(ZBK_COMGNC) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') + " ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_GERENT = '" + _cCodGer + "' "
   _cQry += " GROUP BY ZBK_GERNAC "
   _cQry += " ORDER BY ZBK_GERNAC "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERNAC))

      IncProc("Gravando dados Gerente Nacional: " + TRBQRY->ZBK_GERNAC + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "N"  // N=GERENTE NACIONAL 
         TRBZBK1->(DbAppend())
         TRBZBK1->ZBK_VEND   := TRBQRY->ZBK_GERNAC
         TRBZBK1->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK1->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK1->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK1->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK1->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK1->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK1->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   TRBZBK1->(DBGoTop())
   TRBZBK2->(DBGoTop())
   TRBZBK3->(DBGoTop())
   TRBZBK4->(DBGoTop())
   TRBZBK5->(DBGoTop())

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ROMS069C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2022
===============================================================================================================================
Descrição---------: Gera os dados para o painel para o Coordenador e estruturas hierárquicas subordinadas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069C()
Local _cQry, _cPeriodoQry  
Local _dFechamen, _cVersao

Begin Sequence 
   
   //============================================================================
   // Limpando o conteúdo das tabelas temporárias para gravação de novos dados.
   //============================================================================
   _otemp1:Zap()
   _otemp2:Zap()
   _otemp3:Zap()
   _otemp4:Zap()
   _otemp5:Zap()

   //============================================================================
   // Grava dados das comissões nas tabela temporárias representantes.
   //============================================================================
   ProcRegua(0)

   _dFechamen := Ctod("01/" + SubStr(_cPeriodo,1,2) + "/" + SubStr(_cPeriodo,3,4))
   
   _cVersao := U_ROMS069W(_dFechamen) // Retorna a ultima versão gravada para o período informado.
   
   IncProc("Lendo dados das comissões dos Representantes...")

   _cPeriodoQry := SubStr(_cPeriodo,3,4) + SubStr(_cPeriodo,1,2)
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_VEND, ZBK_NOMVEN, "
   _cQry += " SUM(ZBK_COMVEN) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_COORDE = '" + _cCodCoord + "' "
   _cQry += " GROUP BY ZBK_VEND, ZBK_NOMVEN "
   _cQry += " ORDER BY ZBK_VEND "
   
   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      IncProc("Gravando dados Representante: " + TRBQRY->ZBK_VEND + "-" + AllTrim(TRBQRY->ZBK_NOMVEN))

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_VEND))

      If SA3->A3_I_TIPV == "V" // V=VENDEDOR;
         TRBZBK5->(DbAppend())
         TRBZBK5->ZBK_VEND   := TRBQRY->ZBK_VEND
         TRBZBK5->ZBK_NOMVEN := TRBQRY->ZBK_NOMVEN
         TRBZBK5->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK5->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK5->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK5->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK5->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK5->(MSUnLock())

      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf
   
   //============================================================================
   // Grava dados das comissões nas tabela temporárias supervisores.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Supervisores...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_SUPERV, "
   _cQry += " SUM(ZBK_COMSUP) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_COORDE = '" + _cCodCoord + "' " 
   _cQry += " GROUP BY ZBK_SUPERV "
   _cQry += " ORDER BY ZBK_SUPERV "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_SUPERV))

      IncProc("Gravando dados Supervisor: " + TRBQRY->ZBK_SUPERV + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "S" // S=SUPERVISOR; 
         TRBZBK4->(DbAppend())
         TRBZBK4->ZBK_VEND   := TRBQRY->ZBK_SUPERV
         TRBZBK4->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK4->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK4->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK4->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK4->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK4->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK4->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias coordenadores.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Coordenadores...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_COORDE, "
   _cQry += " SUM(ZBK_COMCOO) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_COORDE = '" + _cCodCoord + "' "
   _cQry += " GROUP BY ZBK_COORDE "
   _cQry += " ORDER BY ZBK_COORDE "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_COORDE))
      
      IncProc("Gravando dados Coordenador: " + TRBQRY->ZBK_COORDE + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "C" // C=COORDENADOR
         TRBZBK3->(DbAppend())
         TRBZBK3->ZBK_VEND   := TRBQRY->ZBK_COORDE
         TRBZBK3->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK3->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK3->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK3->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK3->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK3->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK3->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerentes.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Gerentes...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERENT, "
   _cQry += " SUM(ZBK_COMGER) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_COORDE = '" + _cCodCoord + "' "
   _cQry += " GROUP BY ZBK_GERENT "
   _cQry += " ORDER BY ZBK_GERENT "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERENT))
      
      IncProc("Gravando dados Gerente: " + TRBQRY->ZBK_GERENT+ "-" + AllTrim(SA3->A3_NOME))

//      If SA3->A3_I_TIPV == "G" // G=GERENTE;                                                              
         TRBZBK2->(DbAppend())
         TRBZBK2->ZBK_VEND   := TRBQRY->ZBK_GERENT
         TRBZBK2->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK2->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK2->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK2->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK2->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK2->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK2->(MSUnLock())
//      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerente nacional.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões do Gerente Nacional...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERNAC, "
   _cQry += " SUM(ZBK_COMGNC) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') + " ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_COORDE = '" + _cCodCoord + "' "
   _cQry += " GROUP BY ZBK_GERNAC "
   _cQry += " ORDER BY ZBK_GERNAC "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERNAC))

      IncProc("Gravando dados Gerente Nacional: " + TRBQRY->ZBK_GERNAC + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "N"  // N=GERENTE NACIONAL 
         TRBZBK1->(DbAppend())
         TRBZBK1->ZBK_VEND   := TRBQRY->ZBK_GERNAC
         TRBZBK1->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK1->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK1->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK1->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK1->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK1->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK1->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   TRBZBK1->(DBGoTop())
   TRBZBK2->(DBGoTop())
   TRBZBK3->(DBGoTop())
   TRBZBK4->(DBGoTop())
   TRBZBK5->(DBGoTop())

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ROMS069S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2022
===============================================================================================================================
Descrição---------: Gera os dados para o painel para o Supervisor e estruturas hierárquicas subordinadas.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069S()
Local _cQry, _cPeriodoQry  
Local _dFechamen, _cVersao

Begin Sequence 
   
   //============================================================================
   // Limpando o conteúdo das tabelas temporárias para gravação de novos dados.
   //============================================================================
   _otemp1:Zap()
   _otemp2:Zap()
   _otemp3:Zap()
   _otemp4:Zap()
   _otemp5:Zap()

   //============================================================================
   // Grava dados das comissões nas tabela temporárias representantes.
   //============================================================================
   ProcRegua(0)

   _dFechamen := Ctod("01/" + SubStr(_cPeriodo,1,2) + "/" + SubStr(_cPeriodo,3,4))
   
   _cVersao := U_ROMS069W(_dFechamen) // Retorna a ultima versão gravada para o período informado.
   
   IncProc("Lendo dados das comissões dos Representantes...")

   _cPeriodoQry := SubStr(_cPeriodo,3,4) + SubStr(_cPeriodo,1,2)
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_VEND, ZBK_NOMVEN, "
   _cQry += " SUM(ZBK_COMVEN) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " GROUP BY ZBK_VEND, ZBK_NOMVEN "
   _cQry += " ORDER BY ZBK_VEND "
   
   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      IncProc("Gravando dados Representante: " + TRBQRY->ZBK_VEND + "-" + AllTrim(TRBQRY->ZBK_NOMVEN))

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_VEND))

      If SA3->A3_I_TIPV == "V" // V=VENDEDOR;
         TRBZBK5->(DbAppend())
         TRBZBK5->ZBK_VEND   := TRBQRY->ZBK_VEND
         TRBZBK5->ZBK_NOMVEN := TRBQRY->ZBK_NOMVEN
         TRBZBK5->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK5->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK5->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK5->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK5->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK5->(MSUnLock())

      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf
   
   //============================================================================
   // Grava dados das comissões nas tabela temporárias supervisores.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Supervisores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_SUPERV, "
   _cQry += " SUM(ZBK_COMSUP) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " GROUP BY ZBK_SUPERV "
   _cQry += " ORDER BY ZBK_SUPERV "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_SUPERV))

      IncProc("Gravando dados Supervisor: " + TRBQRY->ZBK_SUPERV + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "S" // S=SUPERVISOR; 
         TRBZBK4->(DbAppend())
         TRBZBK4->ZBK_VEND   := TRBQRY->ZBK_SUPERV
         TRBZBK4->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK4->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK4->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK4->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK4->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK4->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK4->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias coordenadores.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Coordenadores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_COORDE, "
   _cQry += " SUM(ZBK_COMCOO) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " GROUP BY ZBK_COORDE "
   _cQry += " ORDER BY ZBK_COORDE "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_COORDE))
      
      IncProc("Gravando dados Coordenador: " + TRBQRY->ZBK_COORDE + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "C" // C=COORDENADOR
         TRBZBK3->(DbAppend())
         TRBZBK3->ZBK_VEND   := TRBQRY->ZBK_COORDE
         TRBZBK3->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK3->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK3->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK3->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK3->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK3->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK3->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerentes.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Gerentes...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERENT, "
   _cQry += " SUM(ZBK_COMGER) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " GROUP BY ZBK_GERENT "
   _cQry += " ORDER BY ZBK_GERENT "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERENT))
      
      IncProc("Gravando dados Gerente: " + TRBQRY->ZBK_GERENT+ "-" + AllTrim(SA3->A3_NOME))

//      If SA3->A3_I_TIPV == "G" // G=GERENTE;                                                              
         TRBZBK2->(DbAppend())
         TRBZBK2->ZBK_VEND   := TRBQRY->ZBK_GERENT
         TRBZBK2->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK2->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK2->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK2->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK2->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK2->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK2->(MSUnLock())
//      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerente nacional.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões do Gerente Nacional...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERNAC, "
   _cQry += " SUM(ZBK_COMGNC) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') + " ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " GROUP BY ZBK_GERNAC "
   _cQry += " ORDER BY ZBK_GERNAC "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERNAC))

      IncProc("Gravando dados Gerente Nacional: " + TRBQRY->ZBK_GERNAC + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "N"  // N=GERENTE NACIONAL 
         TRBZBK1->(DbAppend())
         TRBZBK1->ZBK_VEND   := TRBQRY->ZBK_GERNAC
         TRBZBK1->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK1->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK1->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK1->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK1->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK1->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK1->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   TRBZBK1->(DBGoTop())
   TRBZBK2->(DBGoTop())
   TRBZBK3->(DBGoTop())
   TRBZBK4->(DBGoTop())
   TRBZBK5->(DBGoTop())

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ROMS069E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/05/2022
===============================================================================================================================
Descrição---------: Gera o relatório em Excel para os dados exibidos em tela.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069E()
Local _aDadosGNC := {}
Local _aDadosGer := {}
Local _aDadosCoo := {}
Local _aDadosSup := {}
Local _aDadosVen := {}
Local _aCabGNC   := {}
Local _aCabGer   := {}
Local _aCabCoo   := {}
Local _aCabSup   := {}
Local _aCabVen   := {}

Begin Sequence 

   If ! U_ITMsg("Confirma a exportação dos dados da tela para planilha Excel? ", "Atenção", "",2,2,2) 
      Break 
   EndIf 

   _aCabGNC   := {}
   //           Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
	aAdd(_aCabGNC,{"Codigo"         ,1           ,1         ,.F.})  // 1
   aAdd(_aCabGNC,{"Nome"           ,1           ,1         ,.F.})  // 2
   aAdd(_aCabGNC,{"Valor Comissão" ,3           ,3         ,.F.})  // 3
   
   _aCabGer   := {}
   aAdd(_aCabGer,{"Codigo"         ,1           ,1         ,.F.})  // 1
   aAdd(_aCabGer,{"Nome"           ,1           ,1         ,.F.})  // 2
   aAdd(_aCabGer,{"Valor Comissão" ,3           ,3         ,.F.})  // 3

   _aCabCoo   := {}
   aAdd(_aCabCoo,{"Codigo"         ,1           ,1         ,.F.})  // 1
   aAdd(_aCabCoo,{"Nome"           ,1           ,1         ,.F.})  // 2
   aAdd(_aCabCoo,{"Valor Comissão" ,3           ,3         ,.F.})  // 3
   aAdd(_aCabCoo,{"Codigo Gerente" ,1           ,1         ,.F.})  // 4
   aAdd(_aCabCoo,{"Nome Gerente"   ,1           ,1         ,.F.})  // 5

   _aCabSup   := {}
   aAdd(_aCabSup,{"Codigo"             ,1           ,1         ,.F.}) // 1
   aAdd(_aCabSup,{"Nome"               ,1           ,1         ,.F.}) // 2
   aAdd(_aCabSup,{"Valor Comissão"     ,3           ,3         ,.F.}) // 3
   aAdd(_aCabSup,{"Codigo Gerente"     ,1           ,1         ,.F.}) // 4
   aAdd(_aCabSup,{"Nome Gerente"       ,1           ,1         ,.F.}) // 5
   aAdd(_aCabSup,{"Codigo Coordenador" ,1           ,1         ,.F.}) // 6 
   aAdd(_aCabSup,{"Nome Coordenador"   ,1           ,1         ,.F.}) // 7

   _aCabVen   := {}
   aAdd(_aCabVen,{"Codigo"             ,1           ,1         ,.F.}) // 1
   aAdd(_aCabVen,{"Nome"               ,1           ,1         ,.F.}) // 2
   aAdd(_aCabVen,{"Valor Comissão"     ,3           ,3         ,.F.}) // 3
   aAdd(_aCabVen,{"Codigo Gerente"     ,1           ,1         ,.F.}) // 4
   aAdd(_aCabVen,{"Nome Gerente"       ,1           ,1         ,.F.}) // 5
   aAdd(_aCabVen,{"Codigo Coordenador" ,1           ,1         ,.F.}) // 6
   aAdd(_aCabVen,{"Nome Coordenador"   ,1           ,1         ,.F.}) // 7
   aAdd(_aCabVen,{"Codigo Supervisor"  ,1           ,1         ,.F.}) // 8
   aAdd(_aCabVen,{"Nome Supervisor"    ,1           ,1         ,.F.}) // 9

   //=================================================================
   // Grava dados do gerente nacional
   //=================================================================
   _aDadosGNC := {}
   TRBZBK1->(DBGoTop())
   While ! TRBZBK1->(Eof())
                       //         1              2                  3
      aAdd(_aDadosGNC,{TRBZBK1->ZBK_VEND, TRBZBK1->ZBK_NOMVEN,TRBZBK1->ZBK_COMVEN}) 
      
      TRBZBK1->(DBSkip())
   EndDo 

   If Empty(_aDadosGNC)
                //    1   2  3
      //_aDadosGNC := {"" ,"" ,0}
      aAdd(_aDadosGNC,{"" ,"" ,0})
   EndIf 

   //=================================================================
   // Grava dados do gerente
   //=================================================================
   _aDadosGer := {}
   TRBZBK2->(DBGoTop())
   While ! TRBZBK2->(Eof())
                       //     1                   2                    3
      aAdd(_aDadosGer,{TRBZBK2->ZBK_VEND, TRBZBK2->ZBK_NOMVEN,TRBZBK2->ZBK_COMVEN}) 

      TRBZBK2->(DBSkip())
   EndDo 
   
   If Empty(_aDadosGer)
                  // 1   2   3
      //_aDadosGer := {"", "" ,0}
      aAdd(_aDadosGer, {"", "" ,0})
   EndIf 

   //=================================================================
   // Grava dados do coordenador
   //=================================================================
   _aDadosCoo := {}
   TRBZBK3->(DBGoTop())
   While ! TRBZBK3->(Eof())
      _cNomeGer := ""
      If ! Empty(TRBZBK3->ZBK_GERENT)
         _cNomeGer := Posicione( "SA3" , 1 , xFilial("SA3")+TRBZBK3->ZBK_GERENT, "A3_NOME" )
      EndIf 
                       //        1               2                     3                 4                 5
      aAdd(_aDadosCoo,{TRBZBK3->ZBK_VEND, TRBZBK3->ZBK_NOMVEN,TRBZBK3->ZBK_COMVEN, TRBZBK3->ZBK_GERENT,_cNomeGer}) 

      TRBZBK3->(DBSkip())
   EndDo 
   
   If Empty(_aDadosCoo)
                //    1  2   3   4   5
      //_aDadosCoo := {"" ,"" ,0 ,"" ,""}
      aAdd(_aDadosCoo, {"" ,"" ,0 ,"" ,""})
   EndIf 
    
   //=================================================================
   // Grava dados do supervisor
   //=================================================================
   _aDadosSup := {}
   TRBZBK4->(DBGoTop())
   While ! TRBZBK4->(Eof())
      _cNomeGer := ""
      If ! Empty(TRBZBK4->ZBK_GERENT)
         _cNomeGer := Posicione( "SA3" , 1 , xFilial("SA3")+TRBZBK4->ZBK_GERENT, "A3_NOME" )
      EndIf 

      _cNomeCoo := ""
      If ! Empty(TRBZBK4->ZBK_COORDE)
         _cNomeCoo := Posicione( "SA3" , 1 , xFilial("SA3")+TRBZBK4->ZBK_COORDE, "A3_NOME" )
      EndIf 
                           //      1                  2                  3                   4            5                 6              7
      aAdd(_aDadosSup,{TRBZBK4->ZBK_VEND, TRBZBK4->ZBK_NOMVEN,TRBZBK4->ZBK_COMVEN, TRBZBK4->ZBK_GERENT,_cNomeGer, TRBZBK4->ZBK_COORDE,_cNomeCoo}) 


      TRBZBK4->(DBSkip())
   EndDo 

   If Empty(_aDadosSup)
                //   1    2  3  4   5   6   7 
      //_aDadosSup := {"", "", 0, "","" ,"" ,""}
      aAdd(_aDadosSup, {"", "", 0, "","" ,"" ,""})
   EndIf 

   
   //=================================================================
   // Grava dados do vendedor
   //=================================================================
   _aDadosVen := {}
   TRBZBK5->(DBGoTop())
   While ! TRBZBK5->(Eof())
      _cNomeGer := ""
      If ! Empty(TRBZBK5->ZBK_GERENT)
         _cNomeGer := Posicione( "SA3" , 1 , xFilial("SA3")+TRBZBK5->ZBK_GERENT, "A3_NOME" )
      EndIf 

      _cNomeCoo := ""
      If ! Empty(TRBZBK5->ZBK_COORDE)
         _cNomeCoo := Posicione( "SA3" , 1 , xFilial("SA3")+TRBZBK5->ZBK_COORDE, "A3_NOME" )
      EndIf 

      _cNomeSup := ""
      If ! Empty(TRBZBK5->ZBK_SUPERV)
         _cNomeSup := Posicione( "SA3" , 1 , xFilial("SA3")+TRBZBK5->ZBK_SUPERV, "A3_NOME" )
      EndIf 
                  //             1                 2                   3                    4             5              6                7           8                 9   
      aAdd(_aDadosVen,{TRBZBK5->ZBK_VEND, TRBZBK5->ZBK_NOMVEN,TRBZBK5->ZBK_COMVEN, TRBZBK5->ZBK_GERENT,_cNomeGer, TRBZBK5->ZBK_COORDE,_cNomeCoo,TRBZBK5->ZBK_SUPERV,_cNomeSup}) 

      TRBZBK5->(DBSkip())
   EndDo 
   
   If Empty(_aDadosVen)
              //      1  2   3  4   5   6  7  8   9
      //_aDadosVen := {"", "", 0 ,"" ,"" ,"","","",""} 
      aAdd(_aDadosVen, {"", "", 0 ,"" ,"" ,"","","",""})
   EndIf 

   _aCabec:={}
	aAdd(_aCabec,{"Gerente Nacional" ,_aCabGNC})
	aAdd(_aCabec,{"Gerente"          ,_aCabGer}) 
   aAdd(_aCabec,{"Coordenador"      ,_aCabCoo}) 
   aAdd(_aCabec,{"Supervisor"       ,_aCabSup}) 
   aAdd(_aCabec,{"Representante"    ,_aCabVen}) 

   _aDetalhe := {_aDadosGNC,_aDadosGer,_aDadosCoo,_aDadosSup,_aDadosVen}

	         //  _cNomeArq,_cDiretorio,_cTitulo                    ,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte)
	U_ITGEREXCEL(         ,           ,"Painel Gerencial Comissões",          ,_aCabec     ,_aDetalhe,           ,          ,        ,            ,.T.         ,          )

End Sequence 

TRBZBK1->(DBGoTop())
TRBZBK2->(DBGoTop())
TRBZBK3->(DBGoTop())
TRBZBK4->(DBGoTop())
TRBZBK5->(DBGoTop())

U_ITMsg("Exportação dos dados para Excel concluido.","Atenção", ,2)

Return 

/*
===============================================================================================================================
Programa----------: ROMS069R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 02/03/2023
===============================================================================================================================
Descrição---------: Gera os dados para o painel para o Vendedor / Representante e estruturas hierárquicas superiores.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS069R()
Local _cQry, _cPeriodoQry  
Local _dFechamen, _cVersao

Begin Sequence 
   
   //============================================================================
   // Limpando o conteúdo das tabelas temporárias para gravação de novos dados.
   //============================================================================
   _otemp1:Zap()
   _otemp2:Zap()
   _otemp3:Zap()
   _otemp4:Zap()
   _otemp5:Zap()

   //============================================================================
   // Grava dados das comissões nas tabela temporárias representantes.
   //============================================================================
   ProcRegua(0)

   _dFechamen := Ctod("01/" + SubStr(_cPeriodo,1,2) + "/" + SubStr(_cPeriodo,3,4))
   
   _cVersao := U_ROMS069W(_dFechamen) // Retorna a ultima versão gravada para o período informado.
   
   IncProc("Lendo dados das comissões dos Representantes...")

   _cPeriodoQry := SubStr(_cPeriodo,3,4) + SubStr(_cPeriodo,1,2)
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_VEND, ZBK_NOMVEN, "
   _cQry += " SUM(ZBK_COMVEN) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   _cQry += " AND ZBK_VEND = '" + _cCodVen + "' "
   _cQry += " GROUP BY ZBK_VEND, ZBK_NOMVEN "
   _cQry += " ORDER BY ZBK_VEND "
   
   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      IncProc("Gravando dados Representante: " + TRBQRY->ZBK_VEND + "-" + AllTrim(TRBQRY->ZBK_NOMVEN))

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_VEND))

      If SA3->A3_I_TIPV == "V" // V=VENDEDOR;
         TRBZBK5->(DbAppend())
         TRBZBK5->ZBK_VEND   := TRBQRY->ZBK_VEND
         TRBZBK5->ZBK_NOMVEN := TRBQRY->ZBK_NOMVEN
         TRBZBK5->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK5->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK5->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK5->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK5->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK5->(MSUnLock())

      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf
   
   //============================================================================
   // Grava dados das comissões nas tabela temporárias supervisores.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Supervisores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_SUPERV, "
   _cQry += " SUM(ZBK_COMSUP) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   //_cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " AND ZBK_VEND = '" + _cCodVen + "' "
   _cQry += " GROUP BY ZBK_SUPERV "
   _cQry += " ORDER BY ZBK_SUPERV "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_SUPERV))

      IncProc("Gravando dados Supervisor: " + TRBQRY->ZBK_SUPERV + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "S" // S=SUPERVISOR; 
         TRBZBK4->(DbAppend())
         TRBZBK4->ZBK_VEND   := TRBQRY->ZBK_SUPERV
         TRBZBK4->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK4->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK4->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK4->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK4->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK4->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK4->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias coordenadores.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Coordenadores...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_COORDE, "
   _cQry += " SUM(ZBK_COMCOO) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   //_cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " AND ZBK_VEND = '" + _cCodVen + "' "
   _cQry += " GROUP BY ZBK_COORDE "
   _cQry += " ORDER BY ZBK_COORDE "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 
      
      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_COORDE))
      
      IncProc("Gravando dados Coordenador: " + TRBQRY->ZBK_COORDE + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "C" // C=COORDENADOR
         TRBZBK3->(DbAppend())
         TRBZBK3->ZBK_VEND   := TRBQRY->ZBK_COORDE
         TRBZBK3->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK3->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK3->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK3->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK3->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK3->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK3->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerentes.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões dos Gerentes...")

   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERENT, "
   _cQry += " SUM(ZBK_COMGER) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   //_cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " AND ZBK_VEND = '" + _cCodVen + "' "
   _cQry += " GROUP BY ZBK_GERENT "
   _cQry += " ORDER BY ZBK_GERENT "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERENT))
      
      IncProc("Gravando dados Gerente: " + TRBQRY->ZBK_GERENT+ "-" + AllTrim(SA3->A3_NOME))

//      If SA3->A3_I_TIPV == "G" // G=GERENTE;                                                              
         TRBZBK2->(DbAppend())
         TRBZBK2->ZBK_VEND   := TRBQRY->ZBK_GERENT
         TRBZBK2->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK2->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK2->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK2->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK2->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK2->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK2->(MSUnLock())
//      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   //============================================================================
   // Grava dados das comissões nas tabela temporárias gerente nacional.
   //============================================================================
   //ProcRegua(0)
   IncProc("Lendo dados das comissões do Gerente Nacional...")
   
   SA3->(DBSetOrder(1))
       
   _cQry := " SELECT ZBK_GERNAC, "
   _cQry += " SUM(ZBK_COMGNC) AS TOTCOM"
   _cQry += " FROM "+ RetSqlName('ZBK') + " ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND SubStr( ZBK_DTFECH, 1 , 6 )  = '"+_cPeriodoQry+"' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "
   //_cQry += " AND ZBK_SUPERV = '" + _cCodSup + "' "
   _cQry += " AND ZBK_VEND = '" + _cCodVen + "' "   
   _cQry += " GROUP BY ZBK_GERNAC "
   _cQry += " ORDER BY ZBK_GERNAC "

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBQRY" , .T. , .F. )

   While ! TRBQRY->(Eof()) 

      SA3->(MsSeek(xFilial("SA3")+TRBQRY->ZBK_GERNAC))

      IncProc("Gravando dados Gerente Nacional: " + TRBQRY->ZBK_GERNAC + "-" + AllTrim(SA3->A3_NOME))

      If SA3->A3_I_TIPV == "N"  // N=GERENTE NACIONAL 
         TRBZBK1->(DbAppend())
         TRBZBK1->ZBK_VEND   := TRBQRY->ZBK_GERNAC
         TRBZBK1->ZBK_NOMVEN := SA3->A3_NOME
         TRBZBK1->ZBK_COMVEN := TRBQRY->TOTCOM
         TRBZBK1->ZBK_SUPERV := SA3->A3_I_SUPE 
         TRBZBK1->ZBK_COORDE := SA3->A3_SUPER  
         TRBZBK1->ZBK_GERENT := SA3->A3_GEREN  
         TRBZBK1->ZBK_GERNAC := SA3->A3_I_GERNC
         TRBZBK1->(MSUnLock())
      EndIf 
      
      TRBQRY->(DBSkip())
   EndDo 

   If Select("TRBQRY") > 0
      TRBQRY->( DBCloseArea() )
   EndIf

   TRBZBK1->(DBGoTop())
   TRBZBK2->(DBGoTop())
   TRBZBK3->(DBGoTop())
   TRBZBK4->(DBGoTop())
   TRBZBK5->(DBGoTop())

End Sequence 

Return 

