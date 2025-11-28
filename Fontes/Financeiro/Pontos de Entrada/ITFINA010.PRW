/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  |24/10/2023| Chamado 43087 - Ajustes para inclusão dos campos ED_COND, ED_CALCINS e ED_NATREN no email.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

Static _cInICIRRF, _cInICPis, _cIniCConf, _cIniCCSLL, _cIniCINSS, _cIniCond, _cIniNatRen

/*
===============================================================================================================================
Programa--------: FINA010
Autor-----------: Julio de Paula Paz
Data da Criacao-: 29/08/2019
Descrição-------: Pontos de entrada no padrão MVC do Cadastro de Naturezas. A partir do release 12.1.17, Os antigos pontos de 
                  entrada do cadastro de Naturezas serão descontinuados.
                  Os pontos de entrada no padrão MVC deverão ser adotados.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function FINA010() 
Local _aParam  := ParamIXB
Local _xRet    := .T.
Local _oObjForm
Local _cIdExec
Local _cIdForm
Local _cCodigo, _cDescr,  _cCalcIRRF, _cCalcPis, _cCalcConf, _cCalcCSLL, _cCalcINSS, _cCondNat, _cNatRen
Local _oModel , _cTextoMsg

Begin Sequence
   //-----------------------------------------------------------------------------------------------------
   // Na hipótese dos parâmetros serem nulos, aborto a execução dos pontos de entrada do MVC
   //-----------------------------------------------------------------------------------------------------
   If _aParam != Nil
      
      _oObjForm := _aParam[1]
      _cIdExec  := _aParam[2]
      _cIdForm  := _aParam[3]
      
      //-----------------------------------------------------------------------------------------------------
      // Validação Formulário antes de qualquer alteração.
      //----------------------------------------------------------------------------------------------------- 
      If _cIdExec == "FORMPRE" 
         
         If _oObjForm:GetOperation() == 4  // Equivale ao FA010ALT
            
            _oModel   := _oObjForm:GetModel()
  
            // incluir aqui o envio de e-mail na alteração de dados. 
            _cInICIRRF := SED->ED_CALCIRF // _oModel:GetValue("SEDMASTER","ED_CALCIRF")
            _cInICPis  := SED->ED_CALCPIS // _oModel:GetValue("SEDMASTER","ED_CALCPIS")
            _cIniCConf := SED->ED_CALCCOF // _oModel:GetValue("SEDMASTER","ED_CALCCOF")
            _cIniCCSLL := SED->ED_CALCCSL // _oModel:GetValue("SEDMASTER","ED_CALCCSL")
            _cIniCINSS := SED->ED_CALCINS // _oModel:GetValue("SEDMASTER","ED_CALCINS")
            _cIniCond  := SED->ED_COND    // _oModel:GetValue("SEDMASTER","ED_COND")
            _cIniNatRen := SED->ED_NATREN  // _oModel:GetValue("SEDMASTER","ED_NATREN")
         EndIf
      
      //-----------------------------------------------------------------------------------------------------
      // //Chamada após a gravação total do modelo e fora da transação.
      //----------------------------------------------------------------------------------------------------- 
      ElseIf _cIdExec == "MODELCOMMITNTTS" 
         //-----------------------------------------------------------------------------------------------------
         // Para validação de exclusão, utilizar a constante MODEL_OPERATION_INSERT e o método GetOperation()
         //-----------------------------------------------------------------------------------------------------
         If _oObjForm:GetOperation() == 3 .Or. _oObjForm:GetOperation() == 4 
            _oModel   := _oObjForm:GetModel()

            // incluir aqui o envio de e-mail na alteração de dados. 
            _cCodigo   := _oModel:GetValue("SEDMASTER","ED_CODIGO") 
            _cDescr    := _oModel:GetValue("SEDMASTER","ED_DESCRIC")
            _cCalcIRRF := _oModel:GetValue("SEDMASTER","ED_CALCIRF")
            _cCalcPis  := _oModel:GetValue("SEDMASTER","ED_CALCPIS")
            _cCalcConf := _oModel:GetValue("SEDMASTER","ED_CALCCOF")
            _cCalcCSLL := _oModel:GetValue("SEDMASTER","ED_CALCCSL")
            _cCalcINSS := _oModel:GetValue("SEDMASTER","ED_CALCINS")
            _cCondNat  := _oModel:GetValue("SEDMASTER","ED_COND")
            _cNatRen   := _oModel:GetValue("SEDMASTER","ED_NATREN")
         EndIf

         If _oObjForm:GetOperation() == 3 // MODEL_OPERATION_INSERT // Equivale ao FA010INC
            
            If (!Empty(_cCalcIRRF) .And.  _cCalcIRRF == "S") .Or. ; 
               (!Empty(_cCalcPis)  .And.  _cCalcPis == "S")  .Or. ;
               (!Empty(_cCalcConf) .And.  _cCalcConf == "S") .Or. ;
               (!Empty(_cCalcCSLL) .And.  _cCalcCSLL == "S") .Or. ;
               (!Empty(_cCalcINSS) .And.  _cCalcINSS == "S") 
               
               _cAssunto := "Criação de nova natureza com retenções para DIRF."
               _cBody    := "<b>Prezado Sr(a),</b>"
               _cBody    += '<br><br>'
               _cBody    += '&nbsp;&nbsp;&nbsp;Foram incluídas novas naturezas financeiras que contém retenções para a DIRF.' + '<br>'
               _cBody    += '<br>'
               _cBody    += '<table border="1">'
               _cBody    += '<tr>'
               _cBody    += '<th>CODIGO</th>'
               _cBody    += '<th>DESCRIÇÃOs</th>'
               _cBody    += '<th>CALCULA IRRF </th>'
               _cBody    += '<th>CALCULA PIS</th>'
               _cBody    += '<th>CALCULA CONFINS </th>'
               _cBody    += '<th>CALCULA CSLL</th>'
               _cBody    += '<th>CALCULA INSS</th>'
               _cBody    += '<th>COND NAT</th>'
               _cBody    += '<th>NAT REND</th>'
               _cBody    += '</tr>'
               _cBody    += '<tr>'
               _cBody    += '<td>'+ _cCodigo   +'</td>'
               _cBody    += '<td>'+ _cDescr    +'</td>'
               _cBody    += '<td>'+ _cCalcIRRF +'</td>'
               _cBody    += '<td>'+ _cCalcPis  +'</td>'
               _cBody    += '<td>'+ _cCalcConf +'</td>'
               _cBody    += '<td>'+ _cCalcCSLL +'</td>'
               _cBody    += '<td>'+ _cCalcINSS +'</td>'
               _cBody    += '<td>'+ _cCondNat +'</td>'
               _cBody    += '<td>'+ _cNatRen +'</td>'
               _cBody    += '</tr>'
               _cBody    += '</table>'
               _cBody    += '<br><br>'
               _cBody    += 'Favor verificar e proceder com a configuração desta natureza no Cadastro Natureza X Codigo retenção para que esta natureza seja devidamente considerada no processamento da DIRF.'
               _cBody    += '<br><br>'
               _cBody    += 'Analisar a necessidade de Natureza de Rendimentos no cadastro.'
               _cBody    += '<br><br>'
               _cBody   += '<br>'
               _cBody   += '</center>'
               _cBody   += '<br>'
               _cBody   += '<br>'
               _cBody   += '    <tr>'
               _cBody   += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
               _cBody   += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [ITFIN010]</td>'
               _cBody   += '    </tr>'
               _cBody   += '</body>'
               _cBody   += '</html>'


               FINA010A(_cAssunto, _cBody) // Envia o e-mail.
           
            EndIf

         ElseIf _oObjForm:GetOperation() == 4 // Equivale ao FA010ALT
            
            If (!Empty(_cCalcIRRF) .And.  _cCalcIRRF == "S") .Or. ; 
               (!Empty(_cCalcPis)  .And.  _cCalcPis  == "S") .Or. ;
               (!Empty(_cCalcConf) .And.  _cCalcConf == "S") .Or. ;
               (!Empty(_cCalcCSLL) .And.  _cCalcCSLL == "S") .Or. ;
               (!Empty(_cInICIRRF) .And.  _cInICIRRF == "S") .Or. ;
               (!Empty(_cInICPis)  .And.  _cInICPis  == "S") .Or. ;
               (!Empty(_cIniCConf) .And.  _cIniCConf == "S") .Or. ;
               (!Empty(_cIniCCSLL) .And.  _cIniCCSLL == "S") .Or. ;
               (!Empty(_cIniCINSS) .And.  _cIniCINSS == "S") .Or. ;
               (!Empty(_cIniCond) ) .Or. ;
               (!Empty(_cIniNatRen) ) 

               If Empty(_cInICIRRF) 
                  _cInICIRRF := ""
               EndIf

               If Empty(_cInICPis)
                 _cInICPis  := ""
               EndIf

               If Empty(_cIniCConf) 
                 _cIniCConf := ""
               EndIf

               If Empty(_cIniCCSLL) 
                  _cIniCCSLL := ""
               EndIf

               If Empty(_cIniCINSS) 
                  _cIniCINSS := ""
               EndIf

               If Empty(_cIniCond) 
                  _cIniCond := ""
               EndIf
               
               If Empty(_cIniNatRen) 
                  _cIniNatRen := ""
               EndIf

               _cTextoMsg := ""

               If _cInICIRRF <> _cCalcIRRF
                  _cTextoMsg += "Campo Calcula IRRF alterado de '" + _cInICIRRF + "' para '" + _cCalcIRRF + "'. <BR> "
               EndIf
               
               If _cInICPis  <> _cCalcPis
                  _cTextoMsg += "Campo Calcula PIS alterado de '" + _cInICPis +"' para '" + _cCalcPis + "'. <BR> "
               EndIf

               If _cIniCConf <> _cCalcConf
                  _cTextoMsg += "Campo Calcula COFINS alterado de '" + _cIniCConf +"' para '" + _cCalcConf  + "'. <BR> "
               EndIf

               If _cIniCCSLL <> _cCalcCSLL
                  _cTextoMsg += "Campo Calcula CSLL alterado de '" + _cIniCCSLL +"' para '" + _cCalcCSLL + "'. <BR> "
               EndIf

               If _cIniCINSS <> _cCalcINSS
                  _cTextoMsg += "Campo Calcula INSS alterado de '" + _cIniCINSS +"' para '" + _cCalcINSS + "'. <BR> "
               EndIf

               If _cIniCond <> _cCondNat
                  _cTextoMsg += "Campo Calcula Condição Nat. alterado de '" + _cIniCond +"' para '" + _cCondNat + "'. <BR> "
               EndIf

               If _cIniNatRen <> _cNatRen
                  _cTextoMsg += "Campo Calcula Natureza de Rendimento alterado de '" + _cIniNatRen +"' para '" + _cNatRen + "'. <BR> "
               EndIf

               _cAssunto := "Alterado uma natureza com retenções para DIRF."
               _cBody    := "<b>Prezado Sr(a),</b>"
               _cBody    += '<br><br>'
               _cBody    += '&nbsp;&nbsp;&nbsp;Foi alterada uma natureza financeira que contém retenção para a DIRF.' + '<br>'
               _cBody    += '<br>'
               _cBody    += '<table border="1">'
               _cBody    += '<tr>'
               _cBody    += '<th>CODIGO</th>'
               _cBody    += '<th>DESCRIÇÃOs</th>'
               _cBody    += '<th>CALCULA IRRF </th>'
               _cBody    += '<th>CALCULA PIS</th>'
               _cBody    += '<th>CALCULA CONFINS </th>'
               _cBody    += '<th>CALCULA CSLL</th>'
               _cBody    += '<th>CALCULA ISS</th>'
               _cBody    += '<th>COND NAT</th>'
               _cBody    += '<th>NAT REND</th>'
               _cBody    += '</tr>'
               _cBody    += '<tr>'
               _cBody    += '<td>'+ _cCodigo   +'</td>'
               _cBody    += '<td>'+ _cDescr    +'</td>'
               _cBody    += '<td>'+ _cCalcIRRF +'</td>'
               _cBody    += '<td>'+ _cCalcPis  +'</td>'
               _cBody    += '<td>'+ _cCalcConf +'</td>'
               _cBody    += '<td>'+ _cCalcCSLL +'</td>'
               _cBody    += '<td>'+ _cCalcINSS  +'</td>'
               _cBody    += '<td>'+ _cCondNat  +'</td>'
               _cBody    += '<td>'+ _cNatRen +'</td>'
               _cBody    += '</tr>'
               _cBody    += '</table>'
               _cBody    += '<BR><BR>'
               _cBody    +=  _cTextoMsg
               _cBody    += '<br><br>'
               _cBody    += 'Favor verificar e proceder com a configuração desta natureza no Cadastro Natureza X Codigo retenção para que esta natureza seja devidamente considerada no processamento da DIRF.'
               _cBody    += '<br><br>'
               _cBody    += 'Analisar a necessidade de Natureza de Rendimentos no cadastro.'
               _cBody    += '<br><br>'
               _cBody   += '<br>'
               _cBody   += '</center>'
               _cBody   += '<br>'
               _cBody   += '<br>'
               _cBody   += '    <tr>'
               _cBody   += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
               _cBody   += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [ITFIN010]</td>'
               _cBody   += '    </tr>'
               _cBody   += '</body>'
               _cBody   += '</html>'

               FINA010A(_cAssunto, _cBody) // Envia o e-mail.
            
            EndIf
         
         EndIf

      EndIf

   EndIf

End Sequence

Return _xRet

/*
===============================================================================================================================
Programa----------: AOMS097D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/02/2019
Descrição---------: Rotina de envio de relatório em Excel por e-mail da Gestão de carteira de pedidos.
Parametros--------: _cAssunto = Assunto do e-mail
                    _cBody    = Conteúdo do e-mail.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function FINA010A(_cAssunto, _cBody)
Local _aConfig	 := U_ITCFGEML('') // Configurações do servidor de envio de e-mail.
Local _cEmlLog  := ""
Local _cEmail   := U_ITGetMV("IT_WFINCDIR","") //
Local _cEmailCC := ""

Begin Sequence
     
   U_ITENVMAIL( "workflow@italac.com.br", _cEmail, _cEmailCC ,, _cAssunto, _cBody     , , _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

   _cEmlLog := Upper(_cEmlLog)
   
   If !Empty( _cEmlLog ) .And. "SUCESSO" $ _cEmlLog
      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ITFINA010"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ITFINA01001"/*cMsgId*/, "ITFINA01001 - Envio de e-mail na Inclusão ou Alteração da Natureza. "+_cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Else
      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ITFINA010"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ITFINA01002"/*cMsgId*/, "ITFINA01002 - Falha no envio de e-mail da Inclusão ou Alteração da Natureza. Assunto: "+_cAssunto/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "ITFINA010"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "ITFINA01003"/*cMsgId*/, "ITFINA01003 - "+_cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf

End Sequence

Return
