/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
Analista    - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==================================================================================================================================================================================
Jerry       - Igor Melgaço  - 25/02/24 - 20/03/25 -  39201  - Ajustes para contabilizar a quantidade de alterações efetuadas no pedido de vendas.
Jerry       - Igor Melgaço  - 23/05/25 - 06/06/25 -  39201  - Ajustes para execução através de execauto na alteração do pedido de vendas.
Jerry       - Igor Melgaço  - 10/06/25 - 20/06/25 -  39201  - Ajustes para validações nos Campos C5_I_ENVRD e C5_I_OPER. 
Jerry       - Igor Melgaço  - 15/07/25 - 17/07/25 -  51224  - Ajustes para gravação do log de alteração do registro e validação do _DtValida. 
Lucas       - Lucas Borges  - 23/07/25 - 23/07/25 -  51340  - Ajustar função para validação de ambiente de teste
Jerry       - Julio         - 08/09/25 - 18/09/25 -  51806  - Ao gravar as alterações no tipo de agendamento, atualizar campos específicos de integração com o sistema RDC.
==================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "apwebsrv.ch"

/*
===============================================================================================================================
Programa----------: MOMS072
Autor-------------: Igor melgaço
Data da Criacao---: 03/02/2025
===============================================================================================================================
Descrição---------: Reagendamento de Pedidos de Venda
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS072()

Local aTables := {"SC5","SC6","DAK","DAI","SC9","SA1","SA3"} As Array  
Local _oProc := Nil As Object

Private _lSchedule := .F. 
                        
If Select("SX3") <= 0
   _lSchedule:= .T.
EndIf   
            
If _lSchedule

   RPCSetType(3)
   RpcSetEnv("01","01",,,,,aTables)     

    u_itconout('Iniciando rotina de reagendamento de pedidos' + DToC(DATE()) + ' - ' + Time())

    U_MOMS072P()

Else

   FWMsgRun( ,{|_oProc| U_MOMS072P(_oProc) } , 'Aguarde!' , 'Verificando os registros...' )
   
EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: MOMS072P
Autor-------------: Igor Melgaço
Data da Criacao---: 03/02/2025
===============================================================================================================================
Descrição---------: Rotina de processamento da query
===============================================================================================================================
Parametros--------: _oProc: objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS072P(_oProc)

Local _nTot := 0 As Numeric
Local _nReg := 0 As Numeric
Local _cQuery := "" As Character
Local _DtValida := CTOD("") As Date
Local _nDiasViagem := 0 As Numeric
Local _dData := CTOD("") As Date
Local _cAliasSC5 := GetNextAlias()  AS Character
Local _aHead := {} As Array
Local _aLog := {} As Array
Local lContinua := .F. As Logical
Local _nDias	:= SuperGetMv( 'ITMOMS072D' ,.F., 90) As Numeric

Private lMsErroAuto    := .F.
Private lAutoErrNoFile := .F.

_dData := (dDataBase - _nDias)

_cQuery := "SELECT SC5.R_E_C_N_O_ RECNO_SC5 "
_cQuery += " FROM " + RetSqlName("SC5") + " SC5 "
_cQuery += "WHERE SC5.C5_NOTA = ' ' "
_cQuery += "	AND SC5.C5_TIPO = 'N' "
_cQuery += "	AND SC5.C5_EMISSAO >= '"+DToS(_dData)+"' "
_cQuery += "	AND (SC5.C5_I_AGEND = 'A' OR SC5.C5_I_AGEND = 'M') "
_cQuery += "	AND NOT EXISTS (SELECT 'X' "
_cQuery += "					FROM " + RetSqlName("SC9") + " SC9 "
_cQuery += "					WHERE SC9.D_E_L_E_T_ = ' ' "
_cQuery += "						AND SC9.C9_FILIAL = SC5.C5_FILIAL "
_cQuery += "						AND SC9.C9_PEDIDO = SC5.C5_NUM )"
_cQuery += "	AND NOT EXISTS (SELECT 'X' "
_cQuery += "					FROM " + RetSqlName("DAI") + " DAI "
_cQuery += "					WHERE DAI.D_E_L_E_T_ = ' ' "
_cQuery += "						AND DAI.DAI_FILIAL = SC5.C5_FILIAL "
_cQuery += "						AND DAI.DAI_PEDIDO = SC5.C5_NUM ) "
_cQuery += "	AND SC5.D_E_L_E_T_ = ' ' "

_cQuery := ChangeQuery(_cQuery)

MPSysOpenQuery( _cQuery , _cAliasSC5)

DBSelectArea(_cAliasSC5)
Count to _nTot

(_cAliasSC5)->(DBGoTop())

While (_cAliasSC5)->(!Eof())
   _nReg++

   If !_lSchedule
      _oProc:cCaption := ("Procesando registro " + AllTrim(Str(_nReg)) + " de " + AllTrim(Str(_nTot)) + " ...")
      ProcessMessages()
   EndIf

   DBSelectArea("SC5")
   SC5->(DBGoTo((_cAliasSC5)->(RECNO_SC5)))

   cFilAnt := SC5->C5_FILIAL

   _nDiasViagem := SC5->C5_I_DIASV  

   _DtValida := SC5->C5_I_DTENT - _nDiasViagem 

   If _DtValida < dDataBase
      
      If SC5->C5_I_ENVRD == "S" 
         lContinua := U_AOMS094E(,.F.) //Retira o Pedido do RDC
      Else
         lContinua := .T.
      EndIf

      //Alterar o tipo de agendamento
      If lContinua
         Begin Transaction
            If RecLock("SC5",.F.)
               _aDadAlt := {}
               _cContAnt := SC5->C5_I_AGEND
               _cContPost := IIf(SC5->C5_I_AGEND='A','R','N')

               SC5->C5_I_AGEND := _cContPost

               SC5->C5_I_ENVRD := "R"
               SC5->C5_I_DTRET := Date()
               SC5->C5_I_HRRET := Time()

               SC5->(MSUnLock())

               aAdd( _aDadAlt , { "C5_I_AGEND"   ,_cContAnt  ,_cContPost  } )

               U_ITGrvLog( _aDadAlt , 'SC5' , 1 , SC5->(C5_FILIAL+C5_NUM) , "A" , IIf(_lSchedule,"000000",RetCodUsr()),Date(),Time() )
            EndIf
         End Transaction		
      EndIf
      
   EndIf

   (_cAliasSC5)->(DBSkip()) 
EndDo

(_cAliasSC5)->(DBCloseArea())

If !_lSchedule

   If Len(_alog) > 0

      _aHead := {"Filial","Pedido","Erro"}
      U_ITListBox( 'Erros na alteração de pedidos de venda' , _aHead , _aLog , .T. , 1 )
      
   EndIf
    
   _oProc:cCaption := ("Iniciando a Exclusão dos Pedidos...")
   ProcessMessages()
EndIf

MOMS072C(_oProc)

If _lSchedule 

   RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões

EndIf

cFilAnt := "01"

Return                                                                  

/*
===============================================================================================================================
Programa----------: MOMS072C
Autor-------------: Igor Melgaço
Data da Criacao---: 03/02/2025
===============================================================================================================================
Descrição---------: Rotina de processamento da query para exclusão dos pedidos
===============================================================================================================================
Parametros--------: _oProc: objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS072C(_oProc)

Local _nTot := 0 As Numeric
Local _nReg := 0 As Numeric
Local _cQuery := "" As Character
Local _aEmail := {} As Array
Local _cEmailCom := SuperGetMv("IT_MOMS072",.F.,"sistema@italac.com.br") As Character
Local _dData := CTOD("") As Date
Local _lExc := .F. As Logical 
Local _cErro := "" As Character
Local _cAliasSC5 := GetNextAlias()  AS Character
Local _aErro := {} As Array
Local _aCabec := {"Cliente","Loja","Fantasia","Filial","Pedido","Emissão","Data Entrega"} As Array
Local _aAling := {"center","center","left","center","center","center","center","center"} As Array	
Local _aSizes := {10,10,40,10,10,10,10} As Array
Local _cProds  := SuperGetMv("IT072PRO",.F.,"00090010501") As Character
Local _cTpOper	:= U_ITGETMV( 'IT_TPOPER' , '') As Character
Local lContinua := .F. As Logical

_cTpOper := StrTran(_cTpOper,",",";") 
_cTpOper := StrTran(_cTpOper,"|",";") 
_cTpOper := StrTran(_cTpOper,"/",";") 

_cProds := StrTran(_cProds,",",";") 
_cProds := StrTran(_cProds,"|",";") 
_cProds := StrTran(_cProds,"/",";") 

_dData := (dDataBase - 61)

_cQuery := "SELECT DISTINCT SC5.R_E_C_N_O_ RECNO_SC5 "
_cQuery += " FROM " + RetSqlName("SC5") + " SC5 "
_cQuery += "WHERE SC5.C5_NOTA = ' ' "
_cQuery += "	AND SC5.C5_I_PEVIN = ' ' "
_cQuery += "	AND SC5.C5_TIPO = 'N' "
_cQuery += "	AND ( SC5.C5_I_OPER IN "+FormatIn(AllTrim(_cTpOper),";")+ " OR SC5.C5_I_OPER IN ('50','51') )  "
_cQuery += "	AND SC5.C5_EMISSAO < '"+DToS(_dData)+"' "
_cQuery += "	AND NOT EXISTS (SELECT 'Y' "
_cQuery += "	                FROM " + RetSqlName("SC6") + " SC6, " + RetSqlName("SB1") + " SB1 "
_cQuery += "	                WHERE SC6.D_E_L_E_T_ = ' ' "
_cQuery += "                     AND SC6.C6_FILIAL = SC5.C5_FILIAL "
_cQuery += "	                  AND SC6.C6_NUM = SC5.C5_NUM "
_cQuery += "	                  AND B1_FILIAL = ' ' "
_cQuery += "	                  AND B1_COD = C6_PRODUTO "
_cQuery += "	                  AND ( SC6.C6_PRODUTO IN "+FormatIn(AllTrim(_cProds),";")+" OR B1_TIPCAR = '000002' ) )"
_cQuery += "	AND NOT EXISTS (SELECT 'X' "
_cQuery += "					FROM " + RetSqlName("SC9") + " SC9 "
_cQuery += "					WHERE SC9.D_E_L_E_T_ = ' ' "
_cQuery += "						AND SC9.C9_FILIAL = SC5.C5_FILIAL "
_cQuery += "						AND SC9.C9_PEDIDO = SC5.C5_NUM )"
_cQuery += "	AND NOT EXISTS (SELECT 'X' "
_cQuery += "					FROM " + RetSqlName("DAI") + " DAI "
_cQuery += "					WHERE DAI.D_E_L_E_T_ = ' ' "
_cQuery += "						AND DAI.DAI_FILIAL = SC5.C5_FILIAL "
_cQuery += "						AND DAI.DAI_PEDIDO = SC5.C5_NUM ) "
_cQuery += "	AND SC5.D_E_L_E_T_ = ' ' "

_cQuery := ChangeQuery(_cQuery)

MPSysOpenQuery( _cQuery , _cAliasSC5)

DBSelectArea(_cAliasSC5)
Count to _nTot

(_cAliasSC5)->(DBGoTop())

While (_cAliasSC5)->(!Eof())
   _nReg++

   If !_lSchedule
      _oProc:cCaption := ("Excluindo registro " + AllTrim(Str(_nReg)) + " de " + AllTrim(Str(_nTot)) + " ...")
      ProcessMessages()
   EndIf

   DBSelectArea("SC5")
   SC5->(DBGoTo((_cAliasSC5)->(RECNO_SC5)))
   
   If SC5->C5_I_ENVRD == "S" 
      lContinua := U_AOMS094E(,.F.) //Retira o Pedido do RDC
   Else
      lContinua := .T.
   EndIf

   If lContinua
      _cErro := ""	
      _lExc  := MOMS072D(@_cErro) //Excluir o pedido de venda

      If _lExc
         If !Empty(AllTrim(SC5->C5_VEND1))
            aAdd(_aEmail,{SC5->C5_VEND1 ,"VENDEDOR"    ,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FANTA,SC5->C5_FILIAL,SC5->C5_NUM,DToC(SC5->C5_EMISSAO),DToC(SC5->C5_I_DTENT)})
         EndIf
         If !Empty(AllTrim(SC5->C5_VEND2))
            aAdd(_aEmail,{SC5->C5_VEND2 ,"COORDENADOR" ,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FANTA,SC5->C5_FILIAL,SC5->C5_NUM,DToC(SC5->C5_EMISSAO),DToC(SC5->C5_I_DTENT)})
         EndIf
         If !Empty(AllTrim(SC5->C5_VEND3))
            aAdd(_aEmail,{SC5->C5_VEND3 ,"GERENTE"     ,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FANTA,SC5->C5_FILIAL,SC5->C5_NUM,DToC(SC5->C5_EMISSAO),DToC(SC5->C5_I_DTENT)})
         EndIf
         If !Empty(AllTrim(SC5->C5_ASSCOD))
            aAdd(_aEmail,{SC5->C5_ASSCOD,"ASSISTENTE"  ,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FANTA,SC5->C5_FILIAL,SC5->C5_NUM,DToC(SC5->C5_EMISSAO),DToC(SC5->C5_I_DTENT)})
         EndIf

         aAdd(_aEmail,{_cEmailCom    ,"COMERCIAL"   ,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FANTA,SC5->C5_FILIAL,SC5->C5_NUM,DToC(SC5->C5_EMISSAO),DToC(SC5->C5_I_DTENT)})
      Else
         aAdd(_aErro,{"" ,"RESPONSAVEL"    ,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FANTA,SC5->C5_FILIAL,SC5->C5_NUM,DToC(SC5->C5_EMISSAO),DToC(SC5->C5_I_DTENT),_cErro})
      EndIf
   EndIf
   (_cAliasSC5)->(DBSkip())
EndDo

(_cAliasSC5)->(DBCloseArea())

If Len(_aEmail) > 0

    _aCabec := {"Cliente","Loja","Fantasia","Filial","Pedido","Emissão","Data Entrega"}
    _aAling := {"center","center","left","center","center","center","center","center"} 	
    _aSizes := {10,10,40,10,10,10,10}

    aSort(_aEmail,,,{ |x,y| x[1]+x[3]+x[4]+x[6]+x[7] < y[1]+y[3]+y[4]+y[6]+y[7] })

   MOMS072E(_oProc,_aEmail,_aCabec,_aAling,_aSizes)

Else

   If !_lSchedule 
      U_ITMsg("Não há dados para processamento dos e-mails!","Atenção","",1)
    EndIf	

EndIf

If Len(_aErro) > 0

    aSort(_aErro,,,{ |x,y| x[1]+x[3]+x[4]+x[6]+x[7] < y[1]+y[3]+y[4]+y[6]+y[7] })

    _aCabec := {"Cliente","Loja","Fantasia","Filial","Pedido","Emissão","Data Entrega","Erro"}
    _aAling := {"center","center","left","center","center","center","center","center","center"} 	
    _aSizes := {10,10,20,10,10,10,10,20}

   MOMS072E(_oProc,_aErro,_aCabec,_aAling,_aSizes)

Else

   If !_lSchedule 
      U_ITMsg("Não há erros para processamento de e-mails!","Atenção","",1)
    EndIf	

EndIf

Return         

/*
===============================================================================================================================
Programa----------: MOMS072D
Autor-------------: Igor Melgaço
Data da Criacao---: 03/02/2025
===============================================================================================================================
Descrição---------: Rotina de Exclusão do Pedido de Venda
===============================================================================================================================
Parametros--------: _cErro
===============================================================================================================================
Retorno-----------: lRet
===============================================================================================================================
*/
Static Function MOMS072D(_cErro As Character) As Logical
Local lRet   := .F. As Logical
Local aCabec := {} As Array
Local aItens := {} As Array

Private lMsErroAuto := .F. As Logical

cFilAnt := SC5->C5_FILIAL

Begin Transaction

    lMsErroAuto    := .F.
    lAutoErrNoFile := .F.
    _cAOMS074      := "MOMS072"//DesAtiva o _lMsgEmTela := .F. no MT410TOK.PRW
    _cAOMS074Vld   := ""//Pega as mensagens de erro

    aAdd(aCabec, {"C5_NUM"    , SC5->C5_NUM     , Nil})
    aAdd(aCabec, {"C5_TIPO"   , SC5->C5_TIPO    , Nil})
    aAdd(aCabec, {"C5_CLIENTE", SC5->C5_CLIENTE , Nil})
    aAdd(aCabec, {"C5_LOJACLI", SC5->C5_LOJACLI , Nil})
    aAdd(aCabec, {"C5_LOJAENT", SC5->C5_LOJAENT , Nil})
    aAdd(aCabec, {"C5_CONDPAG", SC5->C5_CONDPAG , Nil})                
                          
    MSExecAuto({|a, b, c| MATA410(a, b, c)}, aCabec, aItens, 5)                

    If lMsErroAuto
        lRet:= .F.
        _cErro :=  "Falha na Exclusão do Pedido de Venda (MATA410) " 
        _cErro += _cAOMS074Vld + " MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MOMS072.LOG")+" ]"
        DisarmTransaction()
    Else
        lRet := .T.
    EndIf

End Transaction

Return lRet

/*
===============================================================================================================================
Programa----------: MOMS072E
Autor-------------: Igor Melgaço
Data da Criacao---: 30/01/2025
===============================================================================================================================
Descrição---------: Processamento dos dados do Email
===============================================================================================================================
Parametros--------: _aEmail
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
Static Function MOMS072E(_oProc,_aEmail,_aCabec,_aAling,_aSizes,lErro)
Local _nI := 0 As Numeric
Local _nJ := 0 As Numeric
Local _cUsr := "" As Character
Local _cUsrAnt := "" As Character
Local _aPedidos := {} As Array
Local _cEmail := "" As Character
Local _cEmailErr := SuperGetMV("IT_MOMS72E",.F.,"sistema@italac.com.br") As Character
Local _cTit := "Pedidos Excluidos"

Default lErro := .F.

If lErro
    For _nI := 1 to Len(_aEmail)
       _aLinha := {}
       
       For _nJ := 3 to Len(_aEmail[_nI])
          aAdd(_aLinha,_aEmail[_nI,_nJ])
       Next
       
       aAdd(_aPedidos,_aLinha)
    Next

    MOMS072F("",_cEmailErr,"Falha na Exclusão de Pedidos",_aPedidos,_aCabec,_aAling,_aSizes)

Else
    _cUsrAnt := _aEmail[1,1]
    For _nI := 1 to Len(_aEmail)

       _cUsr := _aEmail[_nI,1]

       If _cUsr <> _cUsrAnt 
          
          If _cTipo == "ASSISTENTE"

             _cEmail := AllTrim(Posicione("ZPG",1,xFilial("ZPG") + _cUsrAnt,"ZPG_EMAIL"))
             _cNome := AllTrim(Posicione("ZPG",1,xFilial("ZPG") + _cUsrAnt,"ZPG_ASSNOM"))

          ElseIf _cTipo == "COMERCIAL"

             _cEmail := _cUsrAnt
             _cNome := "Comercial"

          Else

             _cEmail := AllTrim(Posicione("SA3",1,xFilial("SA3") + _cUsrAnt,"A3_EMAIL"))
             _cNome := AllTrim(Posicione("SA3",1,xFilial("SA3") + _cUsrAnt,"A3_NOME"))

          EndIf

          If !_lSchedule
             _oProc:cCaption := ("Enviando Email para " + _cUsrAnt + " ...")
             ProcessMessages()
          EndIf

          MOMS072F(_cNome,_cEmail,_cTit,_aPedidos,_aCabec,_aAling,_aSizes)
            
            _aPedidos := {}

       EndIf

       _aLinha := {}
       
       For _nJ := 3 to Len(_aEmail[_nI])
          aAdd(_aLinha,_aEmail[_nI,_nJ])
       Next
       
       aAdd(_aPedidos,_aLinha)

       _cUsrAnt := _aEmail[_nI,1]
        _cTipo := _aEmail[_nI,2]
    Next

   If _cTipo == "ASSISTENTE"

      _cEmail := AllTrim(Posicione("ZPG",1,xFilial("ZPG") + _cUsrAnt,"ZPG_EMAIL"))
      _cNome := AllTrim(Posicione("ZPG",1,xFilial("ZPG") + _cUsrAnt,"ZPG_ASSNOM"))

   ElseIf _cTipo == "COMERCIAL"

      _cEmail := _cUsrAnt
      _cNome := "Comercial"

   Else

      _cEmail := AllTrim(Posicione("SA3",1,xFilial("SA3") + _cUsrAnt,"A3_EMAIL"))
      _cNome := AllTrim(Posicione("SA3",1,xFilial("SA3") + _cUsrAnt,"A3_NOME"))

   EndIf

   If !_lSchedule
      _oProc:cCaption := ("Enviando Email para " + _cUsrAnt + " ...")
      ProcessMessages()
   EndIf

    MOMS072F(_cNome,_cEmail,_cTit,_aPedidos,_aCabec,_aAling,_aSizes)

EndIf


Return  

/*
===============================================================================================================================
Programa----------: MOMS072F
Autor-------------: Igor Melgaço
Data da Criacao---: 30/01/2025
===============================================================================================================================
Descrição---------: Envio do Email
===============================================================================================================================
Parametros--------: _cUsr,_aPedidos
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
Static Function MOMS072F(_cNome,_cEmail,_cTit,_aPedidos,_aCabec,_aAling,_aSizes)
Local _cMsgEml := "" As Character
Local _cGetLista := "" As Character
Local _aConfig := U_ITCFGEML('') As Array
Local _cGetPara := "" As Character
Local _cGetCc := "" As Character
Local _cEmlLog := "" As Character
Local _cAssuRes := "" As Character
Local _nLin := 0 As Numeric
Local _nCol := 0 As Numeric
Local _cNomeArq := "" As Character

    _cAssuRes := _cTit
    //Logo Italac
    _cMsgEml := '<html>'
    _cMsgEml += '<head><title>' + _cTit + '</title></head>'
    _cMsgEml += '<body>'
    _cMsgEml += '<style Type="text/css"><!--'
    _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
    _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
    _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
    _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
    _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
    _cMsgEml += '--></style>'
    _cMsgEml += '<center>'
    _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
    _cMsgEml += '<br>'

    //Celula Azul para Título
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '	     <td class="titulos"><center>' + _cTit + '</center></td>'
    _cMsgEml += '	 </tr>'
    _cMsgEml += '</table>'
    _cMsgEml += '<br>'

    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="left" > Prezado(a) ' + AllTrim(_cNome) + ', <b></b></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '<br>'

    _cMsgEml += '    <tr>'            
    _cMsgEml += '      <td class="itens" align="left" > Abaixo a listagem de pedidos excluídos: <b></b></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '<br>'

    _cGetLista  := ""
   
    If Len(_aPedidos) > 0
        //Cabeçalho
        _cMsgEml += '<br>'
        _cMsgEml += '<table class="bordasimples" width="800">'
        _cMsgEml += '    <tr>'
        //_cMsgEml += '		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+_cGetAssun+'</b></td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '    <tr>'

        For _nCol :=  1 To Len(_aCabec)
            _cMsgEml += '      <td class="itens" align='+_aAling[_nCol]+' width="'+AllTrim(Str(_aSizes[_nCol]))+'%"><b>'+_aCabec[_nCol]+'</b></td>'
        Next
        
        _cMsgEml += '    </tr>'
        _cMsgEml += '    #LISTA#'
        _cMsgEml += '</table>'

        For _nLin := 1 To Len(_aPedidos)
            
            _cGetLista += '    <tr>'
            For _nCol :=  1 To Len(_aCabec)
                _cGetLista += ' <td class="itens" align='+_aAling[_nCol]+' width="'+AllTrim(Str(_aSizes[_nCol]))+'%">'+ _aPedidos[_nLin][_nCol] +'</td>' 
            Next
            _cGetLista += '    </tr>'
            
        Next
        
        _cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

    EndIf

    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
    _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MOMS072]</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</body>'
    _cMsgEml += '</html>'


    // Chama a função para envio do e-mail
    //ITEnvMail(cFrom       ,cEmailTo  , _cEmailCo,cEmailBcc,cAssunto  ,cMensagem,cAttach  ,cAccount    ,cPassword    ,cServer     ,cPortCon    ,lRelauth    ,cUserAut    ,cPassAut    ,cLogErro)
    U_ITENVMAIL(_aConfig[01], _cGetPara,   _cGetCc,       "",_cAssuRes, _cMsgEml,_cNomeArq,_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )

Return



