/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |20/07/2022| Chamado 40694. Ajustes para fixar a aplicação como I - Investimento.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM039
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2022                                    .
Descrição---------: Rotina para permitir alterar o campo código de Projeto, da solicitação de compras. Quando o 
                    Tipo de Aplicação For igual a "Projeto" (C1_I_APLIC = I) obrigar a digitação do código de projeto.
                    Se o usuário logado é o responsável pela SC (C1_I_CDSOL ) ou se o usuário logado For o Aprovador 
                    (C1_I_CODAP ) ou se o usuário logado For o Gestor de SC (ZZL_ADMSC = S). 
                    Somente permitir Alterar o código de Projeto (C1_I_CDINV). Não alterar os demais campos;
                    Caso a SC esteja vinculada a algum Pedido de Compras, replicar a alteração do código de Projeto também 
                    para o PC.
Parametros--------: lMult - Alteração em multiplas solicitações de compras
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM039(lMult)

Local _oDlgInv
Local _lRet, _cTitulo, _cMsg
Local _nTamanho
Local _cVersaoProtheus := AllTrim(OAPP:CVERSION)
Local _nLinA, _nLinB, _nColF

Default lMult := .F.

Private cCInve
Private cDsInv
Private cCInve2
Private cDsInv2
Private cCInve3
Private cDsInv3

Private oCInve
Private oDsInv
Private oSInve2
Private oCInve2
Private oDsInv2
Private oSInve3
Private oCInve3
Private oDsInv3

Public cAplic := ""	

_cSelZZI_N2 := {||"SELECT ZZI_CODINV , ZZI_DESINV FROM "+RETSQLNAME("ZZI")+" ZZI WHERE D_E_L_E_T_ = ' ' AND ZZI_MSBLQL <> '1' AND ZZI_INVPAI = '" + cCInve + "' AND ZZI_TIPO = '2'  ORDER BY ZZI_CODINV  "}
_aItalac_F3 := {} //       1           2         3                      4                      5               6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3    ,{"CCINVE2" ,_cSelZZI_N2 ,{|Tab|(Tab)->ZZI_CODINV},{|Tab|(Tab)->ZZI_DESINV}, ,"Investimento Nivel 2"        ,          ,          ,1        ,.F.        ,       , } )

_cSelZZI_N3 := {||"SELECT ZZI_CODINV , ZZI_DESINV FROM "+RETSQLNAME("ZZI")+" ZZI WHERE D_E_L_E_T_ = ' ' AND ZZI_MSBLQL <> '1' AND ZZI_INVPAI = '" + cCInve + "' AND ZZI_NIVEL2 = '" + cCInve2 + "' AND ZZI_TIPO = '3' ORDER BY ZZI_CODINV  "}
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3    ,{"CCINVE3" ,_cSelZZI_N3 ,{|Tab|(Tab)->ZZI_CODINV},{|Tab|(Tab)->ZZI_DESINV}, ,"Investimento Nivel 3"        ,          ,          ,1        ,.F.        ,       , } )

Begin Sequence	    
   If ! U_ITVACESS( 'ZZL' , 3 , 'ZZL_ADMSC' , 'S' ) // Não é gestor da SC          
      If SC1->C1_I_CODAP <> __cUserId  // Não é aprovador     
         If SC1->C1_I_CDSOL <> __cUserId  // Não é responsável pela SC
            U_ITMsg("Usuário sem permissão para alterar o código de Projeto.","Atenção",;
		               "Qualquer dúvida entrar em contato com a area Resonsavel.",3) 
            Break
         EndIf
      EndIf
   EndIf

   //================================================================================
   // Monta a tela de dados .
   //================================================================================      
   _nTamanho := Posicione("SX3",2,"C1_I_CDINV","X3_TAMANHO")               
   cCInve := Space(_nTamanho) 
    
   //================================================================================
   // Redefine as coordenadas da tela de acordo com a mudança de versão
   // Protheus 11 e Protheus 12.
   //================================================================================ 
   _nLinA := 17
   _nLinB := 15 
   _nColF := 55
   If _cVersaoProtheus <> "11"
      _nLinA := 40
      _nLinB := 38
      _nColF := 90
   EndIf 
   
   cAplic := "I"

   _nColA   := 10
   _cTitulo := "Alteração do Código de Projeto do Pedido de Compras"
   _cMsg    := "Confirma a alteração do Código de Projeto para Pedido de compras posicionado e a atualização das solicitações relacionadas ao pedido de compras."
   
   _bOk := {|| If(U_MT110VPg(),If(MsgYesNo(_cMsg,"Atenção"),(_lRet := .T., _oDlgInv:End()),),)}
   
   _bCancel := {|| _lRet := .F., _oDlgInv:End()}                                                                                      
   
   cDsInv  := Space(Len(cCInve))
   cCInve2 := Space(Len(cCInve))
   cDsInv2 := Space(Len(cCInve))

   cCInve3 := Space(Len(cCInve))
   cDsInv3 := Space(Len(cCInve))

   Define MsDialog _oDlgInv Title _cTitulo From 9,0 To 32,_nColF Of oMainWnd 
      
      @ _nLinA, _nColA Say 'A SC será referente a ?' PIXEL SIZE 199,99 Of _oDlgInv 
      _nLinA+=9
      @ _nLinA, _nColA MSCOMBOBOX cAplic ITEMS {"C=Consumo","I=Investimento","M=Manutenção","S=Serviço"} SIZE 065, 010 OF _oDlgInv COLORS 0, 16777215 PIXEL Valid {|| ACOM039GI()} When .F.
      
      _nLinA+=15

      @ _nLinA, _nColA	Say 'Código do Projeto' PIXEL SIZE 199,99 Of _oDlgInv 
      _nLinA+=9
      @ _nLinA ,_nColA MsGet oCInve Var cCInve Picture "@!" Size 40,10 F3 "ZZI_P" Valid {|| ( U_VldInf("I",.T.))} of _oDlgInv Pixel 	WHEN (cAplic = "I")
      @ _nLinA, _nColA+40	MSGET oDsInv Var cDsInv PIXEL SIZE 200,08 Of _oDlgInv WHEN .F.
	
      _nLinA+=15

      @ _nLinA, _nColA	Say oSInve2 Prompt 'Investimento Nivel 2' PIXEL SIZE 199,99 Of _oDlgInv  
      _nLinA+=9
      @ _nLinA, _nColA 	MSGET oCInve2 VAR cCInve2 F3 'F3ITLC' PIXEL SIZE 10,10 Of _oDlgInv Valid {|| U_VldInf("I2",.T.)} 
      @ _nLinA, _nColA+40	MSGET oDsInv2 VAR cDsInv2 PIXEL SIZE 200,08 Of _oDlgInv WHEN .F.

      _nLinA+=15

      @ _nLinA, _nColA	Say oSInve3 Prompt 'Investimento Nivel 3' PIXEL SIZE 199,99 Of _oDlgInv 
      _nLinA+=9
      @ _nLinA, _nColA 	MSGET oCInve3 VAR cCInve3 F3 'F3ITLC' PIXEL SIZE 10,10 Of _oDlgInv Valid {|| U_VldInf("I3",.T.)} 
      @ _nLinA, _nColA+40	MSGET oDsInv3 VAR cDsInv3 PIXEL SIZE 200,08 Of _oDlgInv WHEN .F.

      oSInve2:Hide()
      oCInve2:Hide()
      oDsInv2:Hide()
      
      oSInve3:Hide()
      oCInve3:Hide()
      oDsInv3:Hide()

   Activate MsDialog _oDlgInv On Init EnchoiceBar(_oDlgInv,_bOk,_bCancel) CENTERED
   
   If _lRet
      Processa( {|| IIf(lMult,U_ACOM039M(  ) ,U_ACOM039P(  )) } , 'Aguarde!' , 'Alterando código de Projeto...' ) 
      If !lMult
         MsgInfo("Atualização do código de Projeto concluida com sucesso.","Atenção")
      EndIf
   EndIf
          
End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ACOM039P
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2022
Descrição---------: Grava o código de Projeto selecionado na solicitação de compras e no pedido de vendas caso exista.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM039P()

Local _cQry, _nRegAtu
Local _aOrd := SaveOrd({"SC1","SC7"})
Local _cSCNum  := ""
Local _nTotreg

Local _cPCNum 

Begin Sequence 
   ProcRegua(0)

   _cPCNum  := SC7->C7_NUM      
   _nRegAtu := SC7->(Recno())

   SC7->(DBSetOrder(1)) // C1_FILIAL+C1_NUM+C1_ITEM
   SC7->(DBSeek(xFilial("SC7")+_cPCNum))

   While ! SC7->(Eof()) .And. SC7->(C7_FILIAL+C7_NUM) == xFilial("SC7")+_cPCNum
      IncProc("Atualizando Pedido de Compras/Item : "+SC7->C7_NUM+"/"+SC7->C7_ITEM) 
      SC7->(RecLock("SC7",.F.))
      SC7->C7_I_CDINV := cCInve
      SC7->C7_I_APLIC := cAplic
      If Empty(AllTrim(cCInve3))
         SC7->C7_I_SUBIN := cCInve2
      Else
         SC7->C7_I_SUBIN := cCInve3
      EndIf
      SC7->C7_USERLGA := U_RetLgiLga(__cUserId)

      _cSCNum += IIf(Empty(_cSCNum),"",";") + SC7->C7_NUMSC + SC7->C7_ITEMSC

      SC7->(MSUnLock())
      
      SC7->(DBSkip())
   EndDo

   SC7->(DBGoTo(_nRegAtu))

   _cQry := " SELECT SC1.R_E_C_N_O_ AS NRECNO, C1_NUM, C1_ITEM FROM "+RetSqlName("SC1")+" SC1 "
   _cQry += " WHERE SC1.D_E_L_E_T_ = ' ' AND C1_FILIAL = '"+xFilial("SC1")+"' "
   _cQry += " AND SC1.C1_NUM || SC1.C1_ITEM IN " + FormatIn(_cSCNum,";")

   If Select("QRYSC1") > 0
      QRYSC1->(DBCloseArea())
   EndIf
           
   _cQry := ChangeQuery(_cQry) 

   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYSC1", .F., .T.)
   
   COUNT TO _nTotreg
   
   If _nTotreg == 0
      Break
   EndIf
              
   ProcRegua(_nTotreg)
   
   QRYSC1->(DBGoTop())
   While QRYSC1->(!Eof())
      SC1->(DBSetOrder(1))
      SC1->(DBGoTo(QRYSC1->NRECNO))

      IncProc("Atualizando SC/Item : "+SC1->C1_NUM+"/"+SC1->C1_ITEM)
      SC1->(RecLock("SC1",.F.))
      SC1->C1_I_CDINV := cCInve
      SC1->C1_I_APLIC := cAplic
      If Empty(AllTrim(cCInve3))
         SC1->C1_I_SUBIN := cCInve2
      Else
         SC1->C1_I_SUBIN := cCInve3
      EndIf
      SC1->C1_USERLGA := U_RetLgiLga(__cUserId)
      SC1->(MSUnLock())

      QRYSC1->(DBSkip())
   End
   
   
End Sequence

If Select("QRYSC1") > 0
   QRYSC1->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa----------: ACOM039M
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2022
Descricao---------: Rotina de Alteração em multiplos projetos - Chamado 40694 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM039M

Local _aParRet := {}
Local _aParAux := {} , nI
Local _bOK     := {||.T. } //If(MV_PAR02 >= MV_PAR01,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }

MV_PAR01 := Space(Len(SC1->C1_NUM))
MV_PAR02 := Space(Len(SC1->C1_NUM))
MV_PAR03 := CTOD("")
MV_PAR04 := CTOD("")

aAdd( _aParAux , { 1 , "Numero de:"  , MV_PAR01, "@!" , "" , "" , "" , 060 , .F. } ) 
aAdd( _aParAux , { 1 , "Numero ate:" , MV_PAR02, "@!" , "" , "" , "" , 060 , .F. } ) 
aAdd( _aParAux , { 1 , "Data de:"	 , MV_PAR03, "@D"	, "" , "" , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data ate:"	 , MV_PAR04, "@D"	, "" , "" , "" , 050 , .F. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

If !ParamBox( _aParAux , "Alteracao de Tabela de preco de Produtos" , @_aParRet, _bOK )
   Return
EndIf

FWMsgRun(,{|oproc|  ACOM039Q(oproc) },'Aguarde processamento...','Lendo dados...')

Return

/*
===============================================================================================================================
Programa----------: ACOM039Q
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2022
Descricao---------: Monta a tela para seleção das solicitações - Chamado 40694 
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM039Q(oproc)

Local _lRet       := .F.
Local _cQry		   := ""
Local _ntot       := 0
Local _npos       := 1
Local _cAlias     := GetNextAlias()
Local i           := 0
Local _lContinua  := .F.
Local _aDados     := {}
Local _aProc      := {}
Local _aTam       := {}
Local _aCabec     := {}
Local _aTamlog    := {}
Local _aCabeclog  := {}

DEFAULT oproc     := NIL

oproc:cCaption := ("Lendo Tabelas de Preço...")
ProcessMessages()

_cQry := "SELECT C7_FILIAL, C7_NUM , C7_EMISSAO, C7_FORNECE, C7_I_NFORN, C7_I_APLIC"
_cQry += " FROM " + RetSqlName("SC7") + " SC7 "
_cQry += " WHERE SC7.D_E_L_E_T_ = ' ' "
_cQry += "   AND SC7.C7_FILIAL = '"+xFilial("SC7")+"' "

If !Empty(AllTrim(MV_PAR02))
   _cQry += "  AND C7_NUM BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
EndIf

If !Empty(AllTrim(DToS(MV_PAR04)))
   _cQry += "  AND C7_EMISSAO BETWEEN '"+ DToS(MV_PAR03) +"' AND '"+ DToS(MV_PAR04) +"' "
EndIf

_cQry += " GROUP BY C7_FILIAL, C7_NUM , C7_EMISSAO, C7_FORNECE, C7_I_NFORN, C7_I_APLIC "

DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , _cAlias , .T., .F. )

COUNT TO _ntot

_aDados := {}

(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())
	
   oproc:cCaption := ("Lendo Tabela " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
   ProcessMessages()
   _npos++
  
   aAdd(_aDados,{ .F.,;
         (_cAlias)->C7_NUM,;
         DToC(SToD((_cAlias)->C7_EMISSAO)),;
         (_cAlias)->C7_FORNECE,;
         (_cAlias)->C7_I_NFORN ,;
         (_cAlias)->C7_I_APLIC})
   
   (_cAlias)->(DBSkip())
   
EndDo

If Len(_aDados) = 0
   U_ITMsg("Não foram encontrados dados para esses produtos ",'Atenção!',"Tente novamente com outros produtos",3)
   _lLoop:=.T.
   Return .T.
EndIf

_lLoop   := .F.
_aCabec  := {'','Numero','Emissao','Cod. Forn.','Nome Fornecedor','Aplicacao'}
_aTam    := {10,40,50,50,90,100}
_cMsgTop := "Selecione as Solicitações de Compra para modificar o projeto"
_lRet    := U_ITListBox( 'Alteração Múltipla de Projeto das Solicitações de Compra',; // , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                        _aCabec , _aDados , .T.    , 2    , _cMsgTop ,          ,;
                        _aTam, 2 ) // _aSizes , _nCampo , bOk , bCancel )

If _lRet
   For i := 1 To Len(_aDados)
      If _aDados[i][1]
         _lContinua := .T.

         If _aDados[i][6] <> cAplic
                  
            _lContinua := U_ITMsg( "A aplicação deste Pedido de Compra Nr. "+_aDados[i][2]+" esta gravado como "+ACOM039DA(_aDados[i][6]) +".",;
            "Atenção",;
            "Deseja realmente alterar para "+ACOM039DA(cAplic)+"?",3,2)

         EndIf

         If _lContinua
            DBSelectArea("SC7")
            DBSetOrder(1)
            If DBSeek(xFilial("SC7")+_aDados[i][2])
               U_ACOM039P()
            Else
               _lContinua := .T.
            EndIf
         EndIf
         aAdd(_aProc,{ _lContinua,_aDados[i][2],_aDados[i][3],_aDados[i][4],_aDados[i][5],IIf(_lContinua,"Atualização Processada","Atualização Não Processada")})
      EndIf
   Next   
   _aTamlog    := {10,40,70,50,90,50}
   _aCabeclog  := {'','Numero','Emissao','Cod. Forn.','Nome Fornecedor','Log'}
   U_ITListBox( 'Processamento das Solicitações de Compra',; // , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                        _aCabeclog , _aProc , .T.    , 4   , 'Resultado de Processamento:' ,          ,;
                        _aTamlog, 2 ,/*bOk*/ , /*bCancel*/ ,/*_abuttons*/  , /*_aCab*/ , /*bDblClk*/ , /*_aColXML*/ ,/*bCondMarca*/  , /*_bLegenda*/ ,/*_lHasOk*/ .F.) // _aSizes , _nCampo 
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ACOM039GI
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2022
Descricao---------: Gatilho após seleção da apliação - Chamado 40694 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM039GI()

If cAplic <> "I"

   cCInve  := Space(Len(cCInve))
   cDsInv  := ""

   cCInve2 := Space(Len(cCInve2))
   cDsInv2 := ""
   
   cCInve3 := Space(Len(cCInve2))
   cDsInv3 := ""

   oSInve2:Hide()
   oCInve2:Hide()
   oDsInv2:Hide()
   
   oSInve3:Hide()
   oCInve3:Hide()
   oDsInv3:Hide()

   oCInve:Refresh()
   oDsInv:Refresh()

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ACOM039DA
Autor-------------: Igor Melgaço
Data da Criacao---: 19/07/2022
Descricao---------: Devolve a descrição da apliação - Chamado 40694 
Parametros--------: _cAplicaca - Codigo da Aplicação
Retorno-----------: cReturn - Descrição da Aplicação
===============================================================================================================================
*/
Static Function ACOM039DA(_cAplicaca)

Local cReturn := ""

Do Case
   Case _cAplicaca == "C"
      cReturn := "C = Consumo"
   Case _cAplicaca == "I"
      cReturn := "I = Investimento"
   Case _cAplicaca == "M"
      cReturn := "M = Manutenção"
   Case _cAplicaca == "S"
      cReturn := "S = Serviço"
End Case

Return cReturn
