#Include "TOTVS.ch"
#Include "RPTDEF.CH" 

/*
===============================================================================================================================
Programa----------: MCOM014
Autor-------------: Jonathan Torioni
Data da Criacao---: 17/07/20
Descrição---------: Relatório de NFs de entrada diário. - Chamado: 33543
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM014()

Local _aDados       := {}
Local _aEmails      := {}
Local oReport       := Nil
Local _nX           := 1 , nI
Local _aTabelas     := {"ZP1"}
Local _cFileName    := "cRptPortal"

Private _aProds       := {}
Private _dDate        := Date()  
Private _cDate        := Year2Str(_dDate) + Month2Str(_dDate)
Private _lPDF        := .T.
Private _lTela       := .T.

SET DATE FORMAT TO "DD/MM/YY"

If Select('SX3') == 0
   //===========================================================================
   //| Prepara e inicializa o ambiente.                                        |
   //===========================================================================
   RPCSetType(3)
   RpcSetEnv( "01" , "01" ,,,, "SCHEDULE_Relatório_de_NFs_de_entrada_diario" , _aTabelas)
   sleep( 5000 )
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MCOM014"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM01401"/*cMsgId*/, "MCOM01401 - Gerando relatório de NFs de entrada diário: " + DToC(_dDate) + " - " + Time()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MCOM014"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM01402"/*cMsgId*/, "MCOM01402 - Executando no ambiente " + Upper( GetEnvServer() )/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   _lTela := .F.
Else
   _aParAux :={}
   _aParRet :={} 
   _bOK     :={|| If(MV_PAR02 >= MV_PAR01,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }

   MV_PAR01:=dDataBase
   MV_PAR02:=dDataBase
    
   aAdd( _aParAux , { 1 , "Data de"	        , MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .T. } )
   aAdd( _aParAux , { 1 , "Data ate"	        , MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .T. } )
    
   For nI := 1 To Len( _aParAux )
       aAdd( _aParRet , _aParAux[nI][03] )
   Next nI
    //         aParametros, cTitle                 , @aRet   ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "Selecione os filtros" , @_aParRet,  _bOK , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
       Return .F.
   EndIf
   _dDate:=MV_PAR02
   _cDate:=Year2Str(_dDate) + Month2Str(_dDate)
EndIf
    
_aEmails := StrTokArr(SuperGetMV("IT_MAILM14",.F.,"sistema@italac.com.br"),";")
  
If _lTela
   _aEmails:={""}
EndIf

//=======================================
// Gera o relatório com o Layout antigo. 
// Descrição do Produto por grupo.
//=======================================
_aDados := MCOM014R()

For _nX := 1 To Len (_aEmails)
    _cFileName:= "SOBASICO_ANLT_"+DToS(Date())+"_"+StrTran(TIME(),":","_")
    oReport := MCOM014E(_aDados)
    If _lTela
       oReport:nDevice  := IMP_PDF // 
       oReport:SetReportPortal(_cFileName)     // DEFINE O NOME DO RELATÓRIO
       oReport:Print(.T.)
    Else
       oReport:nRemoteType := NO_REMOTE        // FORMA DE GERAÇÃO DO RELATÓRIO
       oReport:nDevice  := IIf(_lPDF, 8, 4)           // ENVIO DE .PDF VIA E-MAIL 8
       oReport:cEmail      := _aEmails[_nX] // DESTINATÁRIO
       oReport:CDESCRIPTION  := MCOM014H(_aEmails[_nX])    //DESCRIÇÃO NO CORPO DO E-MAIL
       oReport:SetReportPortal(_cFileName) // DEFINE O NOME DO RELATÓRIO
       oReport:Print(.F.) //Não exibe tela de configuração
    EndIf
Next _nX

//=======================================
// Gera o relatório com o Novo Layout. 
// Descrição do Produto por B1_DESC.
//=======================================
_aProds := {}
_aDados := MCOM014S()

For _nX := 1 To Len (_aEmails)
    _cFileName:= "SOBASICO_ANLT_"+DToS(Date())+"_"+StrTran(TIME(),":","_")
    oReport := MCOM014E(_aDados)
    If _lTela
       oReport:nDevice  := IMP_PDF // 
       oReport:SetReportPortal(_cFileName)     // DEFINE O NOME DO RELATÓRIO
       oReport:Print(.T.)
    Else
       oReport:nRemoteType := NO_REMOTE        // FORMA DE GERAÇÃO DO RELATÓRIO
       oReport:nDevice  := IIf(_lPDF, 8, 4)           // ENVIO DE .PDF VIA E-MAIL 8
       oReport:cEmail      := _aEmails[_nX] // DESTINATÁRIO
       oReport:CDESCRIPTION  := MCOM014H(_aEmails[_nX])    //DESCRIÇÃO NO CORPO DO E-MAIL
       oReport:SetReportPortal(_cFileName) // DEFINE O NOME DO RELATÓRIO
       oReport:Print(.F.) //Não exibe tela de configuração
    EndIf
Next _nX


If !_lTela
    RpcClearEnv()
    FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MCOM014"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM01403"/*cMsgId*/, "MCOM01403 - Termino de execucao do SCHEDULE_Relatório_de_NFs_de_entrada_diario."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM014R
Autor-------------: Jonathan Torioni
Data da Criacao---: 17/07/20
Descrição---------: Retorna com as informações referente aos produtos x QTD entrada do dia
Parametros--------: Nenhum
Retorno-----------: _aInfo
===============================================================================================================================
*/
Static Function MCOM014R()

Local _cQuery       := ""
Local _cAlias       := GetNextAlias()
Local _aInfo        := {}

_cQuery += "SELECT "
_cQuery += "D1_FILIAL, "
_cQuery += "B1_I_BIGRP, "
_cQuery += "X5_DESCRI X5DESCRI, "
_cQuery += "D1_DTDIGIT, "
_cQuery += "D1_SEGUM , "
_cQuery += "sum(d1_qtsegum) QTDE "
_cQuery += "FROM "+RetSqlName("SD1")+" D1 JOIN "+RETSQLNAME("SB1")+" B1 ON D1_COD = B1_COD "
_cQuery += "JOIN "+RetSqlName("SF4")+" F4 ON D1_FILIAL = F4_FILIAL AND D1_TES = F4_CODIGO JOIN "+RETSQLNAME("SX5")+" X5 ON B1_I_BIGRP = X5_CHAVE "
_cQuery += "JOIN "+RetSqlName("ZB9")+" ZB9 ON B1_I_SUBGR = ZB9_SUBGRU " 
_cQuery += "WHERE D1.D_E_L_E_T_ = ' ' "
_cQuery += "AND B1.D_E_L_E_T_ = ' ' "
_cQuery += "AND ZB9.D_E_L_E_T_ = ' ' "
_cQuery += "AND F4.D_E_L_E_T_ = ' '  "
_cQuery += "AND X5.D_E_L_E_T_ = ' ' "
_cQuery += "AND F4_ESTOQUE = 'S' "
_cQuery += "AND ZB9_CODFAM = '013' "
_cQuery += "AND D1_FORNECE = 'F02270' "

If _lTela
    _cQuery += "AND D1_DTDIGIT BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' "
Else
    _cQuery += "AND D1_DTDIGIT BETWEEN '" +_cDate+"01"+ "' AND '" + _cDate+StrZero(Last_Day(_dDate),2) + "' "
EndIf

_cQuery += "and x5_tabela = 'ZA' "
_cQuery += "GROUP BY  D1_FILIAL, B1_I_BIGRP, X5_DESCRI, D1_DTDIGIT, D1_SEGUM ORDER BY D1_FILIAL ,B1_I_BIGRP "

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

While (_cAlias)->(!Eof())

    aAdd(_aInfo , {(_cAlias)->B1_I_BIGRP,;                   // 1
                    AllTrim((_cAlias)->X5DESCRI),;           // 2
                    (_cAlias)->B1_I_BIGRP,;                  // 3
                    (_cAlias)->D1_SEGUM,;                    // 4
                    (_cAlias)->QTDE,;                        // 5
                    (_cAlias)->D1_DTDIGIT,;                  // 6
                    (_cAlias)->D1_FILIAL,;                   // 7
                    FWFILIALNAME(,(_cAlias)->D1_FILIAL)})    // 8 

    If aScan(_aProds, (_cAlias)->D1_FILIAL+" - "+AllTrim((_cAlias)->X5DESCRI)) == 0
        aAdd(_aProds, (_cAlias)->D1_FILIAL+" - "+AllTrim((_cAlias)->X5DESCRI))
    EndIf

    (_cAlias)->(DBSkip())
EndDo

Return _aInfo

/*
===============================================================================================================================
Programa----------: MCOM014E
Autor-------------: Jonathan Torioni
Data da Criacao---: 17/07/20
Descrição---------: Emite a gravação do relatório em PDF
Parametros--------: _aDados
Retorno-----------: oReport
===============================================================================================================================
*/
Static Function MCOM014E(_aDados)

Local oReport       := TReport():New('MCOM014', "Relatorio de NFs de entrada diario - SOBASICO" , 'MCOM014', {|oReport| MCOM014P(oReport,_aDados)} , "Relatorio de NFs de entrada diario - SOBASICO", .T. )
Local oSection      := Nil
Local _nX           := 0
Local _nDCol        := 7

oReport:SetLandscape()
oReport:SetTotalInLine()
oReport:lParamPage := .F. //DESABILITA PAGINA DE PARAMETROS

oSection  := TRSection():New(oReport, "Dados", {""},,.F.,.T. )
oSection1 := TRSection():New(oReport, "Dados", {""},,.F.,.T. )
oSection2 := TRSection():New(oReport, "Dados", {""},,.F.,.T. )

oSection1:SetLinesBefore(2)// oSection1:SetLinesBefore(17)
oSection2:SetLinesBefore(2)// oSection2:SetLinesBefore(18)

TRCell():New(oSection   ,"D1_FILIAL", "", "Filial", "@!",   6, , , , , , ,_nDCol)
TRCell():New(oSection   ,"RTL", "", "Rótulos de Linha     -> Saldos na 2aUM:", "@!",   60, , , , , , ,_nDCol)
TRCell():New(oSection1  ,"D1_FILIAL", "", "Filial", "@!",   6, , , , , , ,_nDCol)
TRCell():New(oSection1  ,"RTL", "", "Rótulos de Linha     -> Saldos na 2aUM:", "@!",   60, , , , , , ,_nDCol)
TRCell():New(oSection2  ,"D1_FILIAL", "", "Filial", "@!",   6, , , , , , ,_nDCol)
TRCell():New(oSection2  ,"RTL", "", "Rótulos de Linha     -> Saldos na 2aUM:", "@!",   60, , , , , , ,_nDCol)

oBreak  := TRBreak():New( oSection ,  oSection:CELL( "D1_FILIAL" ) , "Total por Filial " , .F. )
oBreak1 := TRBreak():New( oSection1, oSection1:CELL( "D1_FILIAL" ) , "Total por Filial " , .F. )
oBreak2 := TRBreak():New( oSection2, oSection2:CELL( "D1_FILIAL" ) , "Total por Filial " , .F. )

//  TRCell():New(oSection   , "A1_COD"            ,"TRB", "Código"                                , /*Picture*/         , /*Tamanho*/, /*lPixel*/, /*{|| code-block de impressao }*/)
//13->16
For _nX := 1 To 10
    TRCell():New(oSection   ,_cDate+StrZero(_nX,2), ""  , AllToChar(SToD(_cDate + StrZero(_nX,2))), "@E 999,999,999.999",16          ,           ,                                  , , , , ,_nDCol)       
    TRFunction():New( oSection:Cell(_cDate+StrZero(_nX,2)), /* cID */,"SUM",oBreak  /*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
Next 

For _nX := 11 To 20
    TRCell():New(oSection1   ,_cDate+StrZero(_nX,2), "", AllToChar(SToD(_cDate + StrZero(_nX,2))), "@E 999,999,999.999",16, , , , , , ,_nDCol)
    TRFunction():New(oSection1:Cell(_cDate+StrZero(_nX,2)), /* cID */,"SUM",oBreak1 /*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
Next 

For _nX := 21 To Last_Day(_dDate)
    TRCell():New(oSection2   ,_cDate+StrZero(_nX,2), "", AllToChar(SToD(_cDate + StrZero(_nX,2))), "@E 999,999,999.999",16, , , , , , ,_nDCol-2)        
    TRFunction():New(oSection2:Cell(_cDate+StrZero(_nX,2)), /* cID */,"SUM",oBreak2 /*oBreak*/, /*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/)
Next 

Return oReport

/*
===============================================================================================================================
Programa----------: MCOM014P
Autor-------------: Jonathan Torioni
Data da Criacao---: 17/07/20
Descrição---------: Emite a gravação do relatório em PDF
Parametros--------: _aDados
Retorno-----------: oReport
===============================================================================================================================
*/
Static Function MCOM014P(oReport, _aDados)

Local oSection := oReport:Section(1)
Local oSection1 := oReport:Section(2)
Local oSection2 := oReport:Section(3)

Local _nY       := 0
Local _nV       := 0
Local _nPos     := 0
Local _nPosT    := 0
Local _nPosTT   := 0
Local _aTotal   := {}
Local _aTGeral  := {}

oSection:Init()
//===================================================================================
//Preenchimento da Section
//===================================================================================
For _nY := 1 To Len(_aProds)
    oSection:Cell("RTL"):SetValue(SubStr(_aProds[_nY],6))

    For _nV := 1 To last_day(_dDate)
        _nPos := aScan(_aDados, {|x| x[7]+" - "+x[2] == _aProds[_nY] .And. x[6] == _cDate+ StrZero(_nV,2)})

        If _nPos == 0
            If _nV <= 10
                oSection:Cell(_cDate+ StrZero(_nV,2)):SetValue()
            EndIf
            Loop
        EndIf
        If _nV <= 10
            oSection:Cell(_cDate+ StrZero(_nV,2)):SetValue(_aDados[_nPos][5])
            oSection:Cell("D1_FILIAL"):SetValue(_aDados[_nPos][7]) 

            If (_nPosT:= aScan(_aTotal, {|x| x[1] == _cDate+ StrZero(_nV,2)})) == 0
                aAdd(_aTotal, {_cDate+ StrZero(_nV,2), _aDados[_nPos][5]})
            Else
                _aTotal[_nPosT][2] += _aDados[_nPos][5]
            EndIf

            If (_nPosTT := aScan(_aTGeral , {|x| x[1] == _aDados[_nPos][2]})) == 0
                aAdd(_aTGeral, {_aDados[_nPos][2], _aDados[_nPos][5]})
            Else
                _aTGeral[_nPosTT][2] += _aDados[_nPos][5]
            EndIf
        EndIf
        
    Next _nV
    oSection:PrintLine()
Next _nY
oSection:Finish()
_aTotal := {}

//===================================================================================
//Preenchimento da Section1
//===================================================================================
oSection1:Init()
For _nY := 1 To Len(_aProds)
    oSection1:Cell("RTL"):SetValue(SubStr(_aProds[_nY],6))
    For _nV := 1 To last_day(_dDate)
        _nPos := aScan(_aDados, {|x| x[7]+" - "+x[2] == _aProds[_nY] .And. x[6] == _cDate+ StrZero(_nV,2)})

        If _nPos == 0
            If _nV > 10 .And. _nV <= 20
                oSection1:Cell(_cDate+ StrZero(_nV,2)):SetValue()
            EndIf
            Loop
        EndIf

        If _nV > 10 .And. _nV <= 20
            oSection1:Cell(_cDate+ StrZero(_nV,2)):SetValue(_aDados[_nPos][5])
            oSection1:Cell("D1_FILIAL"):SetValue(_aDados[_nPos][7]) 

            If (_nPosT:= aScan(_aTotal, {|x| x[1] == _cDate+ StrZero(_nV,2)})) == 0
                aAdd(_aTotal, {_cDate+ StrZero(_nV,2), _aDados[_nPos][5]})
            Else
                _aTotal[_nPosT][2] += _aDados[_nPos][5]
            EndIf

            If (_nPosTT := aScan(_aTGeral , {|x| x[1] == _aDados[_nPos][2]})) == 0
                aAdd(_aTGeral, {_aDados[_nPos][2], _aDados[_nPos][5]})
            Else
                _aTGeral[_nPosTT][2] += _aDados[_nPos][5]
            EndIf
            
        EndIf
        
    Next _nV
    oSection1:PrintLine()
Next _nY
oSection1:Finish()

_aTotal := {}

//===================================================================================
//Preenchimento da Section2
//===================================================================================
oSection2:Init()
For _nY := 1 To Len(_aProds)
    oSection2:Cell("RTL"):SetValue(SubStr(_aProds[_nY],6))
    For _nV := 1 To last_day(_dDate)
        _nPos := aScan(_aDados, {|x| x[7]+" - "+x[2] == _aProds[_nY] .And. x[6] == _cDate+ StrZero(_nV,2)})

        If _nPos == 0
            If _nV >= 21
                oSection2:Cell(_cDate+ StrZero(_nV,2)):SetValue() 
            EndIf
            Loop
        EndIf

        If _nV >= 21
            oSection2:Cell(_cDate+ StrZero(_nV,2)):SetValue(_aDados[_nPos][5])
            oSection2:Cell("D1_FILIAL"):SetValue(_aDados[_nPos][7]) 

            If (_nPosT:= aScan(_aTotal, {|x| x[1] == _cDate+ StrZero(_nV,2)})) == 0
                aAdd(_aTotal, {_cDate+ StrZero(_nV,2), _aDados[_nPos][5]})
            Else
                _aTotal[_nPosT][2] += _aDados[_nPos][5]
            EndIf

            If (_nPosTT := aScan(_aTGeral , {|x| x[1] == _aDados[_nPos][2]})) == 0
                aAdd(_aTGeral, {_aDados[_nPos][2], _aDados[_nPos][5]})
            Else
                _aTGeral[_nPosTT][2] += _aDados[_nPos][5]
            EndIf

        EndIf
        
    Next _nV
    oSection2:PrintLine()

Next _nY
oSection2:Finish()

Return

/*
===============================================================================================================================
Programa----------: MCOM014H
Autor-------------: Jonathan Torioni
Data da Criacao---: 17/07/20
Descrição---------: Gera o html do corpo do e-mail
Parametros--------: Nenhum
Retorno-----------: _cMsgEml
===============================================================================================================================
*/
Static Function MCOM014H(_cMail)

Local _cMsgEml := ""
Local cTit := "Relatório de NFs de entrada diário - SOBASICO"
Local cPer := ""


_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cTit+" - "+_cMail+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cTit+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados do Relatório</b></td>'
_cMsgEml += '    </tr>'

cPer := "18"
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" width="'+cPer+'%"><b>Descricao:</b></td>'
_cMsgEml += '      <td class="itens" >'+ cTit +'</td>' 
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" width="'+cPer+'%"><b>Data Inicio:</b></td>'
_cMsgEml += '      <td class="itens" >'+AllToChar(SToD(_cDate+"01"))+'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" width="'+cPer+'%"><b>Data Fim:</b></td>'
_cMsgEml += '      <td class="itens" >'+AllToChar(_dDate)+'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'  
_cMsgEml += '      <td class="itens" align="left" width="'+cPer+'%"><b>Observação:</b></td>'
_cMsgEml += '      <td class="itens" >Saldos Referentes a 2aUM dos produtos.</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MCOM014]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

Return _cMsgEml

/*
===============================================================================================================================
Programa----------: MCOM014JB
Autor-------------: Jonathan Torioni
Data da Criacao---: 22/07/20
Descrição---------: EMULA A EXECUÇÃO VIA JOB .Usar somente quando For testar o envio dos e-mails
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM014JB()
    
    StartJob("U_MCOM014", GetEnvServer(), .T.)

Return (NIL)


/*
===============================================================================================================================
Programa----------: MCOM014S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/11/2025
Descrição---------: Retorna com as informações referente aos produtos x QTD entrada do dia 
                    Agrupando por descrição do produtor. (B1_DESC)
                    É uma versão da função MCOM014R() agrupando os produtos por descrição (B1_DESC).
Parametros--------: Nenhum
Retorno-----------: _aInfo = Array com os dados do relatório.
===============================================================================================================================
*/
Static Function MCOM014S()

Local _cQuery       := ""
Local _cAlias       := GetNextAlias()
Local _aInfo        := {}

_cQuery += "SELECT "
_cQuery += "D1_FILIAL, "
_cQuery += "B1_I_BIGRP, "
_cQuery += "B1_DESC, " // "X5_DESCRI X5DESCRI, "
_cQuery += "D1_DTDIGIT, "
_cQuery += "D1_SEGUM , "
_cQuery += "sum(d1_qtsegum) QTDE "
_cQuery += "FROM "+RetSqlName("SD1")+" D1 JOIN "+RETSQLNAME("SB1")+" B1 ON D1_COD = B1_COD "
_cQuery += "JOIN "+RetSqlName("SF4")+" F4 ON D1_FILIAL = F4_FILIAL AND D1_TES = F4_CODIGO " //JOIN "+RETSQLNAME("SX5")+" X5 ON B1_I_BIGRP = X5_CHAVE "
_cQuery += "JOIN "+RetSqlName("ZB9")+" ZB9 ON B1_I_SUBGR = ZB9_SUBGRU " 
_cQuery += "WHERE D1.D_E_L_E_T_ = ' ' "
_cQuery += "AND B1.D_E_L_E_T_ = ' ' "
_cQuery += "AND ZB9.D_E_L_E_T_ = ' ' "
_cQuery += "AND F4.D_E_L_E_T_ = ' '  "
//_cQuery += "AND X5.D_E_L_E_T_ = ' ' "
_cQuery += "AND F4_ESTOQUE = 'S' "
_cQuery += "AND ZB9_CODFAM = '013' "
_cQuery += "AND D1_FORNECE = 'F02270' "

If _lTela
    _cQuery += "AND D1_DTDIGIT BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' "
Else
    _cQuery += "AND D1_DTDIGIT BETWEEN '" +_cDate+"01"+ "' AND '" + _cDate+StrZero(Last_Day(_dDate),2) + "' "
EndIf

//_cQuery += "and x5_tabela = 'ZA' "
_cQuery += "GROUP BY  D1_FILIAL, B1_I_BIGRP, B1_DESC, D1_DTDIGIT, D1_SEGUM ORDER BY D1_FILIAL ,B1_I_BIGRP "

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

While (_cAlias)->(!Eof())

    aAdd(_aInfo , {(_cAlias)->B1_I_BIGRP,;                   // 1
                    AllTrim((_cAlias)->B1_DESC),;    //X5DESCRI),;           // 2
                    (_cAlias)->B1_I_BIGRP,;                  // 3
                    (_cAlias)->D1_SEGUM,;                    // 4
                    (_cAlias)->QTDE,;                        // 5
                    (_cAlias)->D1_DTDIGIT,;                  // 6
                    (_cAlias)->D1_FILIAL,;                   // 7
                    FWFILIALNAME(,(_cAlias)->D1_FILIAL)})    // 8 

    If aScan(_aProds, (_cAlias)->D1_FILIAL+" - "+AllTrim((_cAlias)->B1_DESC)) == 0 // AllTrim((_cAlias)->X5DESCRI)
       aAdd(_aProds, (_cAlias)->D1_FILIAL+" - "+AllTrim((_cAlias)->B1_DESC))      // AllTrim((_cAlias)->X5DESCRI)
    EndIf

    (_cAlias)->(DBSkip())
EndDo

Return _aInfo
