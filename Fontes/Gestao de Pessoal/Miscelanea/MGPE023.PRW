/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |31/01/2023| Chamado 42769. Realização de correções na rotina para funcionar via Scheduller.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE023
Autor-------------: Igor Melgaço
Data da Criacao---: 30/09/2022
Descrição---------: Workflow de Relação de Funcionários com Férias a vencer. Chamado 41364
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE023()
Local _lTela     := .T.
Local _cTimeIni  := Time()
Local _lRet      := .F.
Local _lMGPE023 

Begin Sequence
   
   //Testa se esta sendo rodado do menu
   If Select('SX3') == 0
        
      RPCSetType( 2 )	// Não consome licensa de uso
            
      RpcSetEnv('01','01',,,,GetEnvServer(),{ "SRA","SQB", "SRF" })
      Sleep( 5000 )					//Aguarda 5 segundos para que as jobs IPC subam.
            
      _lTela := .F.

   EndIf

   _lMGPE023  := U_ITGETMV( "IT_MGPE023" , .T.) // Parametro para ativar e desativar a rotina

   If _lMGPE023 // Executa ou não a rotina
      If _lTela
         FWMsgRun( ,{|oProc|  _lRet := MGPE023EM(oProc) } , "Hora Inicial: "+_cTimeIni+" Lendo Funcionários...")
      Else
         //Atualização tabela SM2
         FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE023"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE02301"/*cMsgId*/, "MGPE02301 - Início do Processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         _lRet := MGPE023EM()
         FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE023"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE02302"/*cMsgId*/, "MGPE02302 - Fim do processamento"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         RpcClearEnv() //Libera o Ambiente
      EndIf
   EndIf

End Sequence 

Return _lRet

/*
===============================================================================================================================
Programa----------: MGPE023EM
Autor-------------: Igor Melgaço
Data da Criacao---: 30/09/2022
Descrição---------: Rotina de envio do email
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE023EM(oProc)
Local _aConfig	 := {}
Local _cEmlLog	 := ""
Local _cMsgEml	 := ""
Local _cGetLista := ""
Local _aCab      := {}
Local _aSizes    := {}
Local cGetCc	 := ""
Local cGetPara	 := ""
Local cGetAssun  := "Controle de Férias de Funcionários " + StrZero(month(dDatabase),2) + "/" + StrZero(Year(dDatabase),4)+". "
Local _cTit      := " "
Local _nCont     := 0
Local _aFunc     := {}
Local _aResp     := {}
Local _nFunc     := 0
Local _nLin      := 0
Local _nTotalTit := 0
Local _nCol      := 0
Local cTGetPara  := ""
Local cTGetCc    := ""

//           01          02     03            04           05            06               
_aSizes := {"02"       ,"10"  ,"02"         ,"02"        ,"02"         ,"04"  }
_aCab   := {"Matricula","Nome","Data Inicio","Data Final","Data Limite","Dias"} 

If oProc <> Nil
	oProc:cCaption := ("Lendo Responsável...")
	ProcessMessages()
EndIf

_aResp := MGPE023BRO() // 

If Len(_aResp) = 0 
    If oProc <> Nil
        U_ITMsg("Não há dados no periodo.","Envio do E-MAIL",,3)
    Else
        FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE023"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE02303"/*cMsgId*/, "MGPE02303 - Não há dados no periodo."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    EndIf
Else
    For _nCont := 1 to Len(_aResp)
        _cTit    := "Filial: " + _aResp[_nCont][1] + "    Responsável: " + _aResp[_nCont][2] + " - " + _aResp[_nCont][3] + "    e-mail: " + _aResp[_nCont][4] 
        cGetPara :=  _aResp[_nCont][4] 
        cGetCC   := "" //_aResp[_nCont][5]

        //Logo Italac
        _cMsgEml := '<html>'
        _cMsgEml += '<head><title>'+_cTit+'</title></head>'
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
        _cMsgEml += '	     <td class="titulos"><center>'+_cTit+'</center></td>'
        _cMsgEml += '	 </tr>'
        _cMsgEml += '</table>'
        _cMsgEml += '<br>'


        _cMsgEml += '</center>'
        _cMsgEml += '<br>'
        _cMsgEml += '<br>'
        _cMsgEml += '    <tr>'
        _cMsgEml += '      <td class="itens" align="left" > Caro(a), '+ AllTrim(_aResp[_nCont][3]) +' <b></b></td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '<br>'
        _cMsgEml += '    <tr>'            
        _cMsgEml += '      <td class="itens" align="left" > Realize a programação de férias de seus colaboradores abaixo, agora mesmo! <b></b></td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '<br>'
        _cMsgEml += '    <tr>'    
        _cMsgEml += '      <td class="itens" align="left" > Acesse: http://sistemas.italac.com.br:1062/01/#/login <b></b></td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '<br>'

        If oProc <> Nil
            oProc:cCaption := ("Lendo Funcionários do Responsável "+_aResp[_nCont][2])
            ProcessMessages()
        EndIf

        _aFunc      := MGPE023QRY(_aResp[_nCont][1],_aResp[_nCont][2])
        _nFunc      := Len(_aFunc)
        _nTotalTit  := 0
        _cGetLista  := ""

        If _nFunc > 0
                
            //Cabeçalho
            _cMsgEml += '<br>'
            _cMsgEml += '<table class="bordasimples" width="1300">'
            _cMsgEml += '    <tr>'
            _cMsgEml += '		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+cGetAssun+'</b></td>'
            _cMsgEml += '    </tr>'
            _cMsgEml += '    <tr>'

            For _nCol :=  1 To 6
                _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[_nCol]+'%"><b>'+_aCab[_nCol]+'</b></td>'
            Next
            
            _cMsgEml += '    </tr>'
            _cMsgEml += '    #LISTA#'
            _cMsgEml += '</table>'

            For _nLin := 1 To _nFunc
                
                _cGetLista += '    <tr>'
                For _nCol :=  1 To 6
                    _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[_nCol]+'%">'+ _aFunc[_nLin][_nCol] +'</td>' 
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
        _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MGPE023]</td>'
        _cMsgEml += '    </tr>'
        _cMsgEml += '</body>'
        _cMsgEml += '</html>'

        If oProc <> Nil
            oProc:cCaption := ("Enviando o e-mail...")
            ProcessMessages()
        EndIf

        _aConfig := U_ITCFGEML('')
        
        // Chama a função para envio do e-mail
        //ITEnvMail(cFrom       ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
        U_ITENVMAIL(_aConfig[01], cGetPara,   cGetCc,       "",cGetAssun, _cMsgEml,        "",_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )

        cTGetPara += IIf(Empty(AllTrim(cTGetPara)),"","; ") + cGetPara
        cTGetCc   += IIf(Empty(AllTrim(cTGetCc)),"","; ") + cGetCc

    Next

    If oProc <> Nil
        U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
        "E-mail para: "+cTGetPara+;
        " Com Copia: "+cTGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)
    Else
        FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE023"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE02304"/*cMsgId*/, "MGPE02304 - "+Upper(_cEmlLog)+"E-mail para: "+cTGetPara+" Com Copia: "+cTGetCc/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MGPE023BRO
Autor-------------: Igor Melgaço
Data da Criacao---: 30/09/2022
Descrição---------: Responsáveis pelos deptos aos quais serão enviado o email
Parametros--------: Nenhum
Retorno-----------: _aDados = Lista dos vendedores
===============================================================================================================================
*/  
Static Function MGPE023BRO()
Local _cAliasQB   := ''
Local _cFiltro	   := ''
Local _aResp      := {}

_cAliasQB := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SRF.D_E_L_E_T_ = ' ' "
_cFiltro += " AND RF_STATUS = '1' "
_cFiltro += " AND (RF_DFEPRO1 + RF_DABPRO1 + RF_DFEPRO2 + RF_DABPRO2 + RF_DFEPRO3 + RF_DABPRO3) < 30 "
_cFiltro += " AND ( RF_DFERVAT + RF_DFERAAT - RF_DFERANT) > 0 "
_cFiltro += " AND SRA2.RA_EMAIL <> '"+ Space(Len(SRA->RA_EMAIL))+"' "
_cFiltro += " %"

BeginSql Alias _cAliasQB

    SELECT QB_FILRESP, QB_MATRESP, (SRA2.RA_NOME) AS QB_NOMRESP , (SRA2.RA_EMAIL) AS QB_EMRESP
    FROM %Table:SRF%  SRF  
        JOIN %Table:SRA%  SRA ON SRF.RF_MAT = SRA.RA_MAT AND SRA.%notDel% AND RF_FILIAL = SRA.RA_FILIAL
        LEFT JOIN %Table:SQB%  SQB ON SRA.RA_DEPTO = SQB.QB_DEPTO AND SQB.%notDel% AND RA_FILIAL = QB_FILIAL
        JOIN %Table:SRA%  SRA2 ON SQB.QB_MATRESP = SRA2.RA_MAT AND SRA2.%notDel% AND QB_FILRESP = SRA2.RA_FILIAL
    WHERE %Exp:_cFiltro%
    GROUP BY QB_FILRESP, QB_MATRESP, SRA2.RA_NOME, SRA2.RA_EMAIL
    ORDER BY QB_FILRESP, QB_MATRESP

EndSql

DBSelectArea(_cAliasQB)
(_cAliasQB)->(DBGoTop())
If !(_cAliasQB)->(Eof())
	While !(_cAliasQB)->(Eof())
		aAdd(_aResp,{(_cAliasQB)->QB_FILRESP,;
                        (_cAliasQB)->QB_MATRESP,;
                        (_cAliasQB)->QB_NOMRESP,;
                        (_cAliasQB)->QB_EMRESP})		

		(_cAliasQB)->(DBSkip())
	EndDo
	(_cAliasQB)->( DBCloseArea() )
EndIf

Return _aResp

/*
===============================================================================================================================
Programa----------: MGPE023QRY
Autor-------------: Igor Melgaço
Data da Criacao---: 30/09/2022
Descrição---------: Gera a lista de Funcionários com ferias a vencer
Parametros--------: _cFilialResp = Filial do responsável pelo Depto	
                    _cMatResp = Matricula do responsável pelo Depto	
Retorno-----------: _aDados = Array de Funcionarios 
===============================================================================================================================
*/  
Static Function MGPE023QRY(_cFilialResp,_cMatResp)
Local _cAliasSRF   := ''
Local _cFiltro	   := ''
Local _aDados      := {}

_cAliasSRF := GetNextAlias()

_cFiltro += "% "
_cFiltro += " SRF.D_E_L_E_T_ = ' ' "
_cFiltro += " AND RF_STATUS = '1' "
_cFiltro += " AND (RF_DFEPRO1 + RF_DABPRO1 + RF_DFEPRO2 + RF_DABPRO2 + RF_DFEPRO3 + RF_DABPRO3) < 30 "
_cFiltro += " AND ( RF_DFERVAT + RF_DFERAAT - RF_DFERANT) > 0 "
_cFiltro += " AND QB_FILRESP = '"+_cFilialResp+"' "
_cFiltro += " AND QB_MATRESP = '"+_cMatResp+"' "
_cFiltro += " %"

BeginSql Alias _cAliasSRF
    SELECT QB_DEPTO, SRA.RA_FILIAL, SRA.RA_MAT, SRA.RA_NOME , SRA.RA_EMAIL, SRA.RA_DEPTO, RF_STATUS, 
        (RF_DFEPRO1 + RF_DABPRO1 + RF_DFEPRO2 + RF_DABPRO2 + RF_DFEPRO3 + RF_DABPRO3) AS SOMA, RF_DATAFIM, 
        RF_DATABAS, (RF_DFERVAT + RF_DFERAAT - (RF_DFEPRO1 + RF_DABPRO1 + RF_DFEPRO2 + RF_DABPRO2 + RF_DFEPRO3 + RF_DABPRO3) ) AS RF_TOTQTD
    FROM %Table:SRF%  SRF  
        JOIN %Table:SRA%  SRA ON SRF.RF_MAT = SRA.RA_MAT AND SRA.%notDel% AND RF_FILIAL = SRA.RA_FILIAL
        LEFT JOIN %Table:SQB%  SQB ON SRA.RA_DEPTO = SQB.QB_DEPTO AND SQB.%notDel% AND RA_FILIAL = QB_FILIAL
        JOIN %Table:SRA%  SRA2 ON SQB.QB_MATRESP = SRA2.RA_MAT AND SRA2.%notDel% AND QB_FILRESP = SRA2.RA_FILIAL
    WHERE %Exp:_cFiltro%
    ORDER BY QB_MATRESP
EndSql

DBSelectArea(_cAliasSRF)
(_cAliasSRF)->(DBGoTop())
If !(_cAliasSRF)->(Eof())
	While !(_cAliasSRF)->(Eof())
		aAdd(_aDados,{(_cAliasSRF)->RA_MAT,;
                        (_cAliasSRF)->RA_NOME,; 
                        DToC(SToD((_cAliasSRF)->RF_DATABAS)),;
                        DToC(SToD((_cAliasSRF)->RF_DATAFIM)),;
                        DToC(SToD((_cAliasSRF)->RF_DATAFIM)+ 300),;
                        TRANSFORM( (_cAliasSRF)->RF_TOTQTD, "@E 999,999.99"),;
                        AllTrim(Str((_cAliasSRF)->SOMA)),;
                        (_cAliasSRF)->RA_EMAIL,;
                        (_cAliasSRF)->RA_DEPTO,;
                        (_cAliasSRF)->RA_FILIAL})		

		(_cAliasSRF)->(DBSkip())
	EndDo
	(_cAliasSRF)->( DBCloseArea() )
EndIf

Return _aDados
