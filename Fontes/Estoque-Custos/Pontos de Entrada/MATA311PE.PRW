/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*
===============================================================================================================================
Programa----------: MATA311
Autor-------------: Alex Wallauer
Data da Criacao---: 24/08/2021
Descrição---------: Ponto de entrada MVC MATA311 - Solicitacao de transferencia de armazens. CHAMADO 23063
Parametros--------: Nenhum
Retorno-----------: lRet 
===============================================================================================================================
*/
User Function MATA311

Local aParam   := ParamIXB As Array
Local _lRet    := .T. As Logical
Local _nni	   := 0 As Numeric

Static _cArmAcesso := "" As Character
Static _cFilAcesso := "" As Character

If aParam <> NIL
   oObj      := aParam[1]
   cIdPonto  := aParam[2]
   cIdModel  := aParam[3]
   _nOper    := oObj:GetOperation()

   If cIdPonto == 'MODELVLDACTIVE' 
      _cUsrID	:= RetCodUsr()
      ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSUs
      If !ZZL->(DBSeek(xFilial("ZZL") + __cUserId)) 
         FWAlertWarning("Usuário sem permissão para acessar essa Rotina. Cadastre o seu usuario no Cadastro de Gestao de Ususarios","MATA311PE01")
         _lRet := .F.
      EndIf
      If (_nPos:=AT("/",ZZL->ZZL_ARMEFE)) > 0 
         _cFilAcesso := Left(ZZL->ZZL_ARMEFE, _nPos-1 )
         _cArmAcesso := AllTrim(SubStr(ZZL->ZZL_ARMEFE, _nPos+1 ))
      Else
         _cFilAcesso := cFilAnt
         _cArmAcesso := AllTrim(ZZL->ZZL_ARMEFE)
      EndIf   
      If _lRet .And. !(cFilAnt $ _cFilAcesso)
         FWAlertWarning("Usuário não tem permissão para acessar essa Rotina na Filial Atual: "+cFilAnt+" Usuário só pode acessar essas Filiai(s): "+(_cFilAcesso),"MATA311PE02")
         _lRet := .F.
      EndIf

      If _lRet .And. IsInCallStack('A311Efetiv')//( _nOper == 4)
         If _cUsrID == AllTrim(NNS->NNS_SOLICT)
            FWAlertWarning("Solicitante da transferência não pode efetivar sua própria solicitação","MATA311PE03")
            _lRet := .F.
         EndIf
         If dDataBase < NNS->NNS_DATA
            FWAlertError("Não é possivel efetivar transfência. Data logada no sistema tem que ser maior ou igual a data da solicitação da transferência: "+DToC(NNS->NNS_DATA)+". Entre no sistema com data maior ou igual a "+DToC(NNS->NNS_DATA),"MATA311PE04")
            _lRet := .F.
         EndIf
         NNT->(DBSetOrder(1))
         NNT->(DBSeek(NNS->NNS_FILIAL+NNS->NNS_COD))
         While _lRet  .And. !(NNT->(Eof())) .And. NNT->NNT_FILIAL+NNT->NNT_COD == NNS->NNS_FILIAL+NNS->NNS_COD
            If !(NNT->NNT_LOCLD $ _cArmAcesso) 
               FWAlertWarning("Usuário não tem permissão para efetivar o Armazém: "+NNT->NNT_LOCLD+". Usuário só pode efetivar os armazéns: "+_cArmAcesso,"MATA311PE05")
               _lRet := .F.
               Exit
            EndIf
            NNT->(DBSkip())
         EndDo
         ZZL->(DBSetOrder(1))
      ElseIf _lRet .And. (_nOper == MODEL_OPERATION_UPDATE .Or. _nOper == MODEL_OPERATION_DELETE)
         If _cUsrID <> AllTrim(NNS->NNS_SOLICT)
            FWAlertWarning("Somente o solicitante pode "+If(_nOper == MODEL_OPERATION_DELETE,"excluir","alterar")+" sua solicitação","MATA311PE05")
            _lRet := .F.
         EndIf    
      EndIf
   ElseIf cIdPonto == "MODELPOS" .And. !IsInCallStack('A311Efetiv') //"Chamada na validação total do modelo."
      _oModelDET:= oObj:GetModel('NNTDETAIL')
      _lpassou  := .F.
      _nlin 	 := _oModelDET:Length(.F.)
      lUsaRastr := AllTrim(SuperGetMv("MV_RASTRO",.F.,"")) == "S"
      SB1->(DBSetOrder(1))
      SBZ->(DBSetOrder(1))
      //Valida Linhas
      For _nni := 1 To _nlin
         _oModelDET:Goline(_nni)
         //Se a linha está deletada não faz validações
         If _oModelDET:IsDeleted(_nni)//oObj:IsDeleted(_nni) 
            Loop
         EndIf
         SBZ->(DBSeek(xFilial("SBZ") + _oModelDET:GetValue('NNT_PROD')))
         If SBZ->BZ_LOCALIZ == "S" .And. Empty(_oModelDET:GetValue('NNT_LOCALI'))//Endereço
            FWAlertWarning("Preencha o campo Endereço, linha: "+cValToChar(_nni),"MATA311PE06")
            Return .F.
         EndIf
         SB1->(DBSeek(xFilial("SB1") + _oModelDET:GetValue('NNT_PROD')))
         If lUsaRastr .And. SB1->B1_RASTRO $ "L/S" .And. Empty(_oModelDET:GetValue('NNT_LOTECT')) //Lote
            FWAlertWarning("Preencha o campo Lote, linha: "+cValToChar(_nni),"MATA311PE07")
            Return .F.
         EndIf
         If !(_oModelDET:GetValue('NNT_LOCAL') $ _cArmAcesso)
            FWAlertWarning("Usuário não tem permissão para usar o Armazém: "+_oModelDET:GetValue('NNT_LOCAL')+". Usuário só pode usar os armazéns: "+_cArmAcesso,"MATA311PE08")
            _lRet := .F.
         EndIf
      Next _nni
   ElseIf cIdPonto == "FORMPOS" //"Chamada na validação total do formulário."
   ElseIf cIdPonto == "FORMLINEPRE" //"Chamada na pré validação da linha do formulário. " 
   ElseIf cIdPonto == "FORMLINEPOS" .And. (_nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE) //"Chamada na validação da linha do formulário."
      SBZ->(DBSetOrder(1))
      SBZ->(DBSeek(xFilial("SBZ") + oObj:GetValue('NNT_PROD')))
      If SBZ->BZ_LOCALIZ == "S" .And. Empty(oObj:GetValue('NNT_LOCALI'))//Endereço
         FWAlertWarning("Preencha o campo Endereço.","MATA311PE09")
         _lRet:=.F.
      EndIf
      lUsaRastr := AllTrim(SuperGetMv("MV_RASTRO",.F.,"")) == "S"
      SB1->(DBSetOrder(1))
      SB1->(DBSeek(xFilial("SB1") + oObj:GetValue('NNT_PROD')))
      If lUsaRastr .And. SB1->B1_RASTRO == "L" .And. Empty(oObj:GetValue('NNT_LOTECT'))//LOTE
         FWAlertWarning("Preencha o campo Lote.","MATA311PE10")
         _lRet:=.F.
      EndIf
      If  !(oObj:GetValue('NNT_LOCAL') $ _cArmAcesso)
            FWAlertWarning("Usuário não tem permissão para usar os Armazéns: "+oObj:GetValue('NNT_LOCAL')+". Usuário só pode usar os armazéns: "+_cArmAcesso,"MATA311PE11")
         _lRet := .F.
      EndIf
   ElseIf cIdPonto == "MODELCOMMITTTS" //"Chamada após a gravação total do modelo e dentro da transação."
   ElseIf cIdPonto == "MODELCOMMITNTTS" .And. (_nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE) //"Chamada apos a gravacao total do modelo e fora da transacao."
      MA311Email()//INCLUIR / ALTERAR / COPIAR
   ElseIf cIdPonto == "FORMCOMMITTTSPRE" //"Chamada antes a gravação da tabela do formulário."
   ElseIf cIdPonto == "FORMCOMMITTTSPOS" //"Chamada após a gravação da tabela do formulário."
   ElseIf cIdPonto == "MODELCANCEL"
   ElseIf cIdPonto == "BUTTONBAR"
   EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MA311Email
Autor-------------: Alex Wallauer
Data da Criacao---: 04/03/2022
Descrição---------: Monta e envia email 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MA311Email

Local _aConfig	:= U_ITCFGEML('') As Array
Local _cEmlLog	:= "" As Character
Local _cMsgEml	:= "" As Character
Local _nI      := 0 As Numeric
Local _aSizes  := {} As Array
Local cGetCc	:= "" As Character
Local cGetPara	:= "" As Character
Local _cNomeFil:= cFilant+" - "+AllTrim(Posicione('SM0',1,"01"+cFilant,'M0_FILIAL')) As Character
Local cTit     := "SOLICITACAO DE TRANSFERENCIA ENTRE ARMAZENS" As Character
Local cGetAssun:= "SOLICITACAO DE TRANSFERENCIA ENTRE ARMAZENS No.: "+NNS->NNS_COD As Character
Local _aTLinhas:= {} As Array
Local _aCab    := {} As Array
Local _aSize   := {} As Array
Local _cAlias  := GetNextAlias()

//Monta os titulos das colunas
aAdd(_aCab,"Produto")//01
aAdd(_aSize,"08")
aAdd(_aCab,"Descrição")//02
aAdd(_aSize,"30")
aAdd(_aCab,"Arm.Ori.")//03
aAdd(_aSize,"08")
aAdd(_aCab,"Arm.Des.")//04
aAdd(_aSize,"08")
aAdd(_aCab,"Qtde")//05
aAdd(_aSize,"08")
aAdd(_aCab,"Lote")//06
aAdd(_aSize,"08")
aAdd(_aCab,"Observações")//07
aAdd(_aSize,"30")

cTam:=AllTrim(Str(Len(ZZL->ZZL_ARMEFE)-2))
NNT->(DBSetOrder(1))
NNT->(DBSeek(NNS->NNS_FILIAL+NNS->NNS_COD))
While !NNT->(Eof()) .And. NNT->NNT_FILIAL+NNT->NNT_COD == NNS->NNS_FILIAL+NNS->NNS_COD
   aAdd(_aTLinhas,{NNT->NNT_PROD,;
                   AllTrim(Posicione("SB1",1,xFilial("SB1")+NNT->NNT_PROD,"B1_DESC")),;
                   NNT->NNT_LOCAL,;
                   NNT->NNT_LOCLD,;
                   Trans(NNT->NNT_QUANT,"@E 999,999,999.99"),;
                   NNT->NNT_LOTECT,;
                   AllTrim(NNT->NNT_OBS)})
   NNT->(DBSkip())
EndDo

BeginSql alias _cAlias
   SELECT R_E_C_N_O_ REG_ZZL FROM  %Table:ZZL%
   WHERE D_E_L_E_T_ = ' '
   AND ZZL_FILIAL = %xFilial:ZZL%
   AND ZZL_ARMEFE <>  ' ' 
   AND ZZL_EMAIL <> ' ' "
EndSql

_aEmail:={}
While (_cAlias)->(!Eof())
	ZZL->(DBGoTo((_cAlias)->REG_ZZL))
   If (_nPos:=AT("/",ZZL->ZZL_ARMEFE)) > 0 
	   _cFilEAcesso := Left(ZZL->ZZL_ARMEFE, _nPos )
      _cArmEAcesso := AllTrim(SubStr(ZZL->ZZL_ARMEFE, _nPos+1 ))
   Else   
      _cFilEAcesso := cFilAnt
      _cArmEAcesso := AllTrim(ZZL->ZZL_ARMEFE)
   EndIf
   If !cFilant $ _cFilEAcesso
      (_cAlias)->(DBSkip())
      Loop
   EndIf
   _lLoop:=.T.
   For _nI := 1 To Len(_aTLinhas)
       If _aTLinhas[_nI][04] $ _cArmEAcesso//BASTA UMA LINHA ESTA CONTIDA
          _lLoop:=.F.
          Exit
       EndIf
   Next _nI
   If _lLoop
      (_cAlias)->(DBSkip())
      Loop
   EndIf

	aAdd(_aEmail,{AllTrim(ZZL->ZZL_EMAIL),AllTrim(ZZL->ZZL_NOME),_cArmAcesso})
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

If totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   _aEmail:={}
	aAdd(_aEmail,{Lower(AllTrim(UsrRetMail(__cUserId))),cUserName,_cArmAcesso})
EndIf

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cTit+'</title></head>'
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
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados da solicitação</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Solicitado por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Numero:</b></td>'
_cMsgEml += '      <td class="itens" >'+ NNS->NNS_COD +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

_aSizeOK:=_aSize

_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1300">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizeOK)))+'" class="grupos"><b>Produtos aguardando efetivação</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[01]+'%"><b>'+_aCab[01]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[02]+'%"><b>'+_aCab[02]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[03]+'%"><b>'+_aCab[03]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[04]+'%"><b>'+_aCab[04]+'</b></td>'
_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizeOK[05]+'%"><b>'+_aCab[05]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[06]+'%"><b>'+_aCab[06]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[07]+'%"><b>'+_aCab[07]+'</b></td>'
_cMsgEml += '    </tr>'

_cGetLista:=""
_lEnvia:=.F.
_aSizes:=_aSize

For _nI := 1 To Len(_aTLinhas)
		_cMsgEml += '    <tr>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+ _aTLinhas[_nI][01]+'</td>'
		_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ _aTLinhas[_nI][02]+'</td>'
		_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[03]+'%">'+ _aTLinhas[_nI][03]+'</td>'
		_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[04]+'%">'+ _aTLinhas[_nI][04]+'</td>'
		_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%">'+ _aTLinhas[_nI][05]+'</td>'
		_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[06]+'%">'+ _aTLinhas[_nI][06]+'</td>'
		_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%">'+ _aTLinhas[_nI][07]+'</td>'
		_cMsgEml += '    </tr>'
	    _lEnvia:=.T.
Next _nI

_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GetEnvServer() +'] / <b>Fonte:</b> [MATA311PE]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

If _lEnvia
   For _nI := 1 To Len(_aEmail)
       cGetPara:=_aEmail[_nI,1]
      // Chama a função para envio do e-mail
      U_ITENVMAIL( _aConfig[01], cGetPara, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
   		
      If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
         U_ITMsg(,"Envio do E-MAIL",,3)
         FWAlertInfo(Upper(_cEmlLog)+CRLF+ "E-mail para: "+cGetPara+" Com Copia: "+cGetCc+CRLF,"MATA311PE12")
      EndIf
   Next _nI
Else   
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
      FWAlertInfo("Não tem registros para enviar","MATA311PE13")
   EndIf   
EndIf

Return

/*
===============================================================================================================================
Programa----------: MA311VLD()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 22/05/2024
Descrição---------: Validações de Campos Customizados da Tabela NNT.
Parametros--------: _cCampo =  Campo que chamou a validação.
Retorno-----------: _lRet = .T. = Válido
                            .F. = Não Válido
===============================================================================================================================
*/
User Function MA311VLD(_cCampo As Character)

Local _lRet       := .T. As Logical
Local _oModel     := Nil As Object
Local _oModelGrid := Nil As Object

Begin Sequence 
   _oModel := FwModelActivete()
   _oModelGrid := _oModel:GetModel('NNTDETAIL')

   If _cCampo == "NNT_I_TPTR"
      _cMotTrans := _oModelGrid:GetValue("NNT_I_TPTR") 
      _cDescMoti := ""

      If ! Empty(_cMotTrans)
         _cDescMoti := Posicione("CYO",1,xFilial("CYO")+_cMotTrans,"CYO_DSRF")
      EndIf 

      _oModelGrid:LoadValue( 'NNT_I_DSCT', _cDescMoti)
   EndIf 
End Sequence 

Return _lRet
