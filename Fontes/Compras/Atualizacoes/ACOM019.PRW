/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |14/07/2022| Chamado 40694. Ajustes para gravação de Usuario de Alteração e janela de log de processamento.
Igor Melgaço  |14/07/2022| Chamado 40694. Ajustes para fixar a aplicação como I - Investimento.
Lucas Borges  |27/05/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM019
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/08/2016                                    .
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
User Function ACOM019(lMult as Logical)

Local _oDlgInv := Nil As Object
Local _lRet    := .F. As Logical
Local _cTitulo := "" As Character
Local _cMsg    := "" As Character
Local _nTamanho:= 0 As Numeric
Local _cVersaoProtheus := AllTrim(OAPP:CVERSION) As Character
Local _nLinA, _nLinB, _nColF := 0 As Numeric

Default lMult := .F.

Private cCInve := "" As Character
Private cDsInv := "" As Character
Private cCInve2 := "" As Character
Private cDsInv2 := "" As Character
Private cCInve3 := "" As Character
Private cDsInv3 := "" As Character

Private oCInve := Nil As Object
Private oDsInv := Nil As Object
Private oSInve2 := Nil As Object
Private oCInve2 := Nil As Object
Private oDsInv2 := Nil As Object
Private oSInve3 := Nil As Object
Private oCInve3 := Nil As Object
Private oDsInv3 := Nil As Object

Public cAplic := "" As Character

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
            FWAlertWarning("Usuário sem permissão para alterar o código de Projeto. Qualquer dúvida entrar em contato com a area Resonsavel.","ACOM01901")
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
   _cTitulo := "Alteração do Código de Projeto da Solicitação de Compras"
   _cMsg    := "Confirma a alteração do Código de Projeto para solicitação de compras posicionada e a atualização dos pedidos relacionados a solicitação de compras."
   
   _bOk := {|| If(U_MT110VPg(),If(MsgYesNo(_cMsg,"Atenção"),(_lRet := .T., _oDlgInv:End()),),) }
   _bCancel := {|| _lRet := .F., _oDlgInv:End()}                                                                                      
   
   cDsInv  := Space(Len(cCInve))
   cCInve2 := Space(Len(cCInve))
   cDsInv2 := Space(Len(cCInve))

   cCInve3 := Space(Len(cCInve))
   cDsInv3 := Space(Len(cCInve))

   Define MsDialog _oDlgInv Title _cTitulo From 9,0 To 32,_nColF Of oMainWnd 
      
      @ _nLinA, _nColA Say 'A SC será referente a ?' PIXEL SIZE 199,99 Of _oDlgInv 
      _nLinA+=9
      @ _nLinA, _nColA MSCOMBOBOX cAplic ITEMS {"C=Consumo","I=Investimento","M=Manutenção","S=Serviço"} SIZE 065, 010 OF _oDlgInv COLORS 0, 16777215 PIXEL Valid {|| ACOM019GI()} WHEN .F.
      
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
      Processa( {|| IIf(lMult,U_ACOM019M(  ) ,U_ACOM019P(  )) } , 'Aguarde!' , 'Alterando código de Projeto...' ) 
      If !lMult
         FWAlertSuccess("Atualização do código de Projeto concluida com sucesso.","ACOM01902")
      EndIf
   EndIf
          
End Sequence 

Return

/*
===============================================================================================================================
Programa----------: ACOM019P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/08/2016
Descrição---------: Grava o código de Projeto selecionado na solicitação de compras e no pedido de vendas caso exista.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM019P()

Local _cQry := "" As Character
Local _nRegAtu := 0 As Numeric
Local _aOrd := SaveOrd({"SC1","SC7"}) As Array
Local _cSCNum := "" As Character
Local _nTotreg := 0 As Numeric

Begin Sequence 
   ProcRegua(0)
   _cSCNum := SC1->C1_NUM      
   _nRegAtu := SC1->(Recno())
   SC1->(DBSetOrder(1)) // C1_FILIAL+C1_NUM+C1_ITEM
   SC1->(DBSeek(xFilial("SC1")+_cSCNum))
   
   While ! SC1->(Eof()) .And. SC1->(C1_FILIAL+C1_NUM) == xFilial("SC1")+_cSCNum
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
      SC1->(DBSkip())
   EndDo                            
   
   SC1->(DBGoTo(_nRegAtu))
   
   _cQry := " SELECT SC7.R_E_C_N_O_ AS NRECNO, C7_NUM FROM "+RetSqlName("SC7")+" SC7 "
   _cQry += " WHERE SC7.D_E_L_E_T_ = ' ' AND C7_FILIAL = '"+xFilial("SC7")+"' "
   _cQry += " AND C7_NUMSC = '"+_cSCNum+"' "

   If Select("QRYSC7") > 0
      QRYSC7->(DBCloseArea())
   EndIf
           
   _cQry := ChangeQuery(_cQry) 
   MPSysOpenQuery(_cQry,"QRYSC7")
   (DBSelectArea("QRYSC7"))

   COUNT TO _nTotreg
   
   If _nTotreg == 0
      Break
   EndIf
              
   ProcRegua(_nTotreg)
   
   QRYSC7->(DBGoTop())
                                                       
   SC7->(DBSetOrder(1)) // C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN                                                                                                                              
   SC7->(DBSeek(xFilial("SC7")+QRYSC7->C7_NUM))
   
   While ! SC7->(Eof()) .And. SC7->(C7_FILIAL+C7_NUM) == xFilial("SC7")+QRYSC7->C7_NUM
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
      SC7->(MSUnLock())
      
      SC7->(DBSkip())
   EndDo

End Sequence

If Select("QRYSC7") > 0
   QRYSC7->(DBCloseArea())
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Programa----------: ACOM019M
Autor-------------: Igor Melgaço
Data da Criacao---: 13/07/2022
Descricao---------: Rotina de Alteração em multiplos projetos - Chamado 40694 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM019M

Local _aParRet := {} As Array
Local _aParAux := {} As Array
Local nI       := 0 As Numeric
Local _bOK     := {||.T. } As Codeblock

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

FWMsgRun(,{|oproc|  ACOM019Q(oproc) },'Aguarde processamento...','Lendo dados...')

Return

/*
===============================================================================================================================
Programa----------: ACOM019Q
Autor-------------: Igor Melgaço
Data da Criacao---: 13/07/2022
Descricao---------: Monta a tela para seleção das solicitações - Chamado 40694 
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM019Q(oproc As Object)

Local _lRet       := .F. As Logical
Local _cQry		   := "" As Character
Local _ntot       := 0 As Numeric
Local _npos       := 1 As Numeric
Local _cAlias     := GetNextAlias() As Character
Local i           := 0 As Numeric
Local _lContinua  := .F. As Logical
Local _aDados     := {} As Array
Local _aProc      := {} As Array
Local _aTam       := {} As Array
Local _aCabec     := {} As Array
Local _aTamlog    := {} As Array
Local _aCabeclog  := {} As Array

DEFAULT oproc     := NIL

oproc:cCaption := ("Lendo Tabelas de Preço...")
ProcessMessages()

_cQry := "SELECT C1_FILIAL, C1_NUM , C1_EMISSAO, C1_FILENT, C1_NOMAPRO, C1_I_APLIC, C1_OBS"
_cQry += " FROM " + RetSqlName("SC1") + " SC1 "
_cQry += " WHERE SC1.D_E_L_E_T_ = ' ' "
_cQry += "   AND SC1.C1_I_CODAP <> '" + __cUserId + "' "
_cQry += "   AND SC1.C1_I_CDSOL <> '" + __cUserId + "' "
_cQry += "   AND SC1.C1_FILIAL = '"+xFilial("SC1")+"' "

If !Empty(AllTrim(MV_PAR02))
   _cQry += "  AND C1_NUM BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR02 +"' "
EndIf

If !Empty(AllTrim(DToS(MV_PAR04)))
   _cQry += "  AND C1_EMISSAO BETWEEN '"+ DToS(MV_PAR03) +"' AND '"+ DToS(MV_PAR04) +"' "
EndIf

_cQry += " GROUP BY C1_FILIAL, C1_NUM , C1_EMISSAO, C1_FILENT, C1_NOMAPRO, C1_I_APLIC, C1_OBS "
_cQry := ChangeQuery(_cQry)
MPSysOpenQuery(_cQry,_cAlias)

DBSelectArea(_cAlias)
COUNT TO _ntot

_aDados := {}

(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())
	
   oproc:cCaption := ("Lendo Tabela " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
   ProcessMessages()
   _npos++
  
   aAdd(_aDados,{ .F.,;
         (_cAlias)->C1_NUM,;
         DToC(SToD((_cAlias)->C1_EMISSAO)),;
         (_cAlias)->C1_FILENT,;
         (_cAlias)->C1_NOMAPRO,;
         (_cAlias)->C1_I_APLIC,;
         (_cAlias)->C1_OBS })
   
   (_cAlias)->(DBSkip())
EndDo

If Len(_aDados) = 0
   FWAlertInfo("Não foram encontrados dados para esses produtos. Tente novamente com outros produtos","ACOM01901")
   _lLoop:=.T.
   Return .T.
EndIf

_lLoop   := .F.
_aCabec  := {'','Numero','Emissao','Filial de Entrega','Nome Aprovador','Aplicação','Obs'}
_aTam    := {10,40,70,30,60,50,100}
_cMsgTop := "Selecione as Solicitações de Compra para modificar o projeto"
_lRet    := U_ITListBox( 'Alteração Múltipla de Projeto das Solicitações de Compra',; // , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                        _aCabec , _aDados , .T.    , 2    , _cMsgTop ,          ,;
                        _aTam, 2 ) // _aSizes , _nCampo , bOk , bCancel )

If _lRet
   For i := 1 To Len(_aDados)
      If _aDados[i][1]
         _lContinua := .T.

         If _aDados[i][6] <> cAplic
            _lContinua := FWAlertYesNo( "A aplicação desta Solicitação de Compra Nr. "+_aDados[i][2]+" esta gravado como "+ACOM019DA(_aDados[i][6]) +". "+;
            "Deseja realmente alterar para "+ACOM019DA(cAplic)+"?","ACOM01903")
         EndIf

         If _lContinua
            DBSelectArea("SC1")
            SC1->(DBSetOrder(1))
            If SC1->(DBSeek(xFilial("SC1")+_aDados[i][2]))
               U_ACOM019P()
            Else
               _lContinua := .T.               
            EndIf
         EndIf
         aAdd(_aProc,{ _lContinua,_aDados[i][2],_aDados[i][3],_aDados[i][4],_aDados[i][5],_aDados[i][6],_aDados[i][7],IIf(_lContinua,"Atualização Processada","Atualização Não Processada")})
      EndIf
   Next   
   _aTamlog    := {10,40,70,30,60,50,50,50}
   _aCabeclog  := {'','Numero','Emissao','Filial de Entrega','Nome Aprovador','Aplicação','Obs','Log'}
   U_ITListBox( 'Processamento das Solicitações de Compra',; // , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                        _aCabeclog , _aProc , .T.    , 4   , 'Resultado de Processamento:' ,          ,;
                        _aTamlog, 2 ,/*bOk*/ , /*bCancel*/ ,/*_abuttons*/  , /*_aCab*/ , /*bDblClk*/ , /*_aColXML*/ ,/*bCondMarca*/  , /*_bLegenda*/ ,/*_lHasOk*/ .F.) // _aSizes , _nCampo 
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: ACOM019GI
Autor-------------: Igor Melgaço
Data da Criacao---: 13/07/2022
Descricao---------: Gatilho após seleção da apliação - Chamado 40694 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM019GI()

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
Programa----------: ACOM019DA
Autor-------------: Igor Melgaço
Data da Criacao---: 13/07/2022
Descricao---------: Devolve a descrição da apliação - Chamado 40694 
Parametros--------: _cAplicaca - Codigo da Aplicação
Retorno-----------: cReturn - Descrição da Aplicação
===============================================================================================================================
*/
Static Function ACOM019DA(_cAplicaca As Character)

Local cReturn := "" As Character

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
