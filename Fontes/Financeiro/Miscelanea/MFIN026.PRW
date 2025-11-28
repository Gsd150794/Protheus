/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |27/06/2024| Ajuste da Query para buscar os tipos NF
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIN026
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Cruzamento das informações Banco x Sistemas atravé de planilha CHAMADO 45243
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN026()
Local _nI        := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| IF(MV_PAR01 <> "" .AND. ".CSV" $ UPPER(MV_PAR01) ,.T.,(U_ITMSG("Selecione um arquivo CSV.",'Atenção!',IIF(Alltrim(MV_PAR01)="","Preencha o campo pasta!","Preencha o campo arquivo!"),3),.F.) ) }
Local _cTimeIni  := Time()
Local _lRet      := .F.

MV_PAR01 :=  Space(200)
MV_PAR02 :=  Space(200)

//aAdd( _aParAux , { 1 , "Selecione arquivo .CSV:" , MV_PAR01	, "@!", ""	, "DIR"		, "" , 120 , .F. } ) 	//| 01 |
aAdd( _aParAux , { 6 ,"Selecione arquivo .CSV:"   , MV_PAR01 ,"","","",120,.T.,"Todos os arquivos (*.*) |*.*","",GETF_MULTISELECT})
aAdd( _aParAux , { 1 , "Selecione a pasta de destino:" , MV_PAR02	, "@!", ""	, "DIRAGR"		, "" , 120 , .F. } ) 	//| 01 |

For _nI := 1 To Len( _aParAux )
      aAdd( _aParRet , _aParAux[_nI][03] )
Next _nI

If !ParamBox( _aParAux , " Cruzamento das informações Banco x Protheus " , @_aParRet, _bOK )
   _lRet := .F.
Else
   FWMsgRun( ,{|oProc|  _lRet := MFIN026IM(oProc) } , "Hora Inicial: "+_cTimeIni+" Importando arquivo: "+AllTrim(MV_PAR01) )
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MFIN026IM
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Processa a planilha
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN026IM(oProc)
Local _cArq      := "" 
Local _aDados    := {}
Local _cLinInv   := ""
Local _aLog      := {}
Local _aCab      := {}
Local _aSizes    := {}
Local _nLinProc  := 0
Local _nLinNProc := 0
Local _aButtons  := {}

_cArq += AllTrim(MV_PAR01) 

_aCab     := {" ","Linha","Nr","Nome do Pagador", "CNPJ","Emissão", "Vencto", "Nosso Numero", "Seu Numero", "Situação","Valor","Saldo Protheus","Status"}
_aSizes   := {"02","05","05","05","10","10","10","10","43","50","50","50","100"}

oProc:cCaption := ("Lendo Arquivo...")
ProcessMessages()

If !(MFIN026LA(oProc,_cArq,@_aDados,@_cLinInv)) //Faz leitura do arquivo
   Return .F.
EndIf

If Len(_aDados) <= 0
   U_ITMsg( "Não foram encontrados registros válidos no arquivo!" , "Atenção!",,1 )
   Return .F.
EndIf

_aLog := MFIN026PR(oProc,_aDados,@_nLinProc,@_nLinNProc) // Faz o processamento sem gravação e retorna um log

//Validador
_cTitAux := "Dados do Arquivo " + _cArq
_cMsgTop := "Análise prévia , Registros Lidos: " + AllTrim(TRANSFORM(_nLinProc+_nLinNProc,"@E 999,999,999")) + ", Com Erros: " + AllTrim(TRANSFORM(_nLinNProc,"@E 999,999,999"))

_aButtons := {}
aAdd(_aButtons,{"BUDGET",{|| MFIN026EE(oProc,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc,.F.)  },"", "E-mail" }) 

oProc:cCaption := ("Abrindo o Log do Arquivo...")
ProcessMessages()
U_ITLISTBOX(_cTitAux, _aCab    , _aLog     , .T.      , 4      , _cMsgTop ,          , _aSizes ,         ,     ,        , _aButtons,      ,         ,           ,          ,        , .F.)

Return .T.

/*
===============================================================================================================================
Programa----------: MFIN026LA
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Rotina de leitura do arquivo
Parametros--------: oProc    = objeto da barra de processamento
------------------: _cArq    = Arquivo usado na importação de dados
------------------: _cLinInv = Linhas inválidas não processadas
Retorno-----------: _aDados = Dados do arquivo
===============================================================================================================================
*/  
Static Function MFIN026LA(oProc,_cArq,_aDados,_cLinInv)
Local _cDados	:= ""
Local _aLinha	:= {}
Local _nCont 	:= 0
Local _nNumCol := 0
Local _nTotLin := 0

If FT_FUSE(_cArq) == -1
   U_ITMsg("Falha ao abrir o arquivo: "+_cArq,"Erro",,1)
   Return .F.
EndIf

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO

_nTotLin := FT_FLASTREC()

If _nTotLin == 0 //O arquivo informado nao possui nenhuma linha de dados
   U_ITMsg("O arquivo informado para relizar a importação não possui dados.","Arquivo inválido",;
            "Favor verificar se o arquivo informado esta no formato correto.")
   Return .F.
EndIf

FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO

_cDados := FT_FREADLN()

If !(Upper("Nr;Nome do Pagador;CPF/CNPJ do Pagador;Emissão;Vencimento;Nosso Número;Seu Número;Situação;Valor") $ Upper(AllTrim(_cDados))) ///********************
   U_ITMsg("Falha ao abrir o arquivo: "+_cArq,"Erro: Aqrquivo fora de layout padrão.",,1)
   Return .F.
EndIf

FT_FSKIP() //PULA O CABEÇALHO

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
   _nCont++

	oProc:cCaption := ( "Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nTotLin,5) + "." )
	ProcessMessages()

   _cDados  := FT_FREADLN()
   _aLinha  := StrTokArr(_cDados,";")
   
   //Verifica se é final de arquivo
   If AllTrim(_cDados) = ";;;;;;;;;;;" .And. _nCont > _nTotLin
      Exit
   EndIf 	
   
   _nNumCol := Len(_aLinha)

   //Verifica se é linha válida validando 6 colunas
   If _nNumCol = 9
      aAdd(_aDados,_aLinha)
   Else
      _cLinInv += IIf(Empty(AllTrim(_cLinInv)),"","; ") + AllTrim(Str(_nCont))
   EndIf

   FT_FSKIP()
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: MFIN026AR
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Rotina de montangem do email
Parametros--------: _cGetAssun = Assunto do email
------------------: _cTit      = Titulo da tabela
------------------: _aCab      = Cabeçalho da tabela
------------------: _aSizes    = Tamanhos das Colunas
------------------: _aLista    = Listagem dos registros do log
------------------: _cLinInv   = Linhas inválidas fora do layout
------------------: _nLinProc  = Numero de linhas Processadas
------------------: _nLinNProc = Numero de linhas Não Processadas
Retorno-----------: _cMsgEml = 
===============================================================================================================================
*/              
Static Function MFIN026ME(_cGetAssun,_cTit,_aCab,_aSizes,_aLista,_cLinInv,_nLinProc,_nLinNProc)
Local _cMsgEml   := ""
Local _cGetLista := ""
Local _nCont     := 0
Local _nI        := 0

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

//Cabeçalho
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1300">'
_cMsgEml += '    <tr>'
_cMsgEml += '		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+_cGetAssun+'</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'

For _nI := 1 To Len(_aCab)
   _cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[_nI]+'%"><b>'+_aCab[_nI]+'</b></td>'
Next

_cMsgEml += '    </tr>'
_cMsgEml += '    #LISTA#'
_cMsgEml += '</table>'

For _nCont := 1 To Len(_aLista)
   
   _cGetLista += '    <tr>'
   For _nI := 1 To Len(_aCab)
      If _nI = 1 
         _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[_nI]+'%">'+ IIf(_aLista[_nCont][01],"Verde","Vermelho") +'</td>' 
      Else
         _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[_nI]+'%">'+ _aLista[_nCont][_nI] +'</td>' 
      EndIf
   Next
 _cGetLista += '    </tr>'

Next

If _nLinProc > 0

   _cMsgEml += '</center>'
   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Qtd de linhas Processadas:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > '+ AllTrim(Str(_nLinProc)) +' <b> </b> </td>'
   _cMsgEml += '    </tr>'
   
EndIf

If _nLinNProc > 0

   _cMsgEml += '</center>'
   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Qtd de linhas com falha de processamento:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > '+ AllTrim(Str(_nLinNProc)) +' <b> </b> </td>'
   _cMsgEml += '    </tr>'
   
EndIf

If !Empty(AllTrim(_cLinInv))

   _cMsgEml += '</center>'
   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Linhas inválidas fora do Layout para o processamento:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > '+ _cLinInv +' <b> </b> </td>'
   _cMsgEml += '    </tr>'
   
EndIf

_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MFIN026]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

Return _cMsgEml

/*
===============================================================================================================================
Programa----------: MFIN026EE
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Rotina de montangem do email
Parametros--------: oProc = objeto da barra de processamento
------------------: _aCab      = Cabeçalho da tabela
------------------: _aSizes    = Tamanhos das Colunas
------------------: _aLog      = Listagem dos registros do log
------------------: _cLinInv   = Linhas inválidas fora do layout
------------------: _nLinProc  = Numero de linhas Processadas
------------------: _nLinNProc = Numero de linhas Não Processadas	
------------------: _lGrava    = Determina se o aLog veio da análise (.F.) ou processamento da importação (.T.)	
Retorno-----------: .T.
===============================================================================================================================
*/              
Static Function MFIN026EE(oProc,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc,_lGrava)
Local _cMsgEml   := ""
Local _cAssunto  := ""
Local cGetPara   := ""
Local cGetCc     := ""
Local cGetCco    := ""
Local _cEmlLog	  := ""
Local _aConfig   := {}

Local _cTit      := "" 
Local _nI        := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| If(MV_PAR03 <> "" ,.T.,(U_ITMsg("O campo 'Para' deve ser preenchido!",'Atenção!',"Preencha o campo para envio do e-mail.",3),.F.) ) }

MV_PAR02 := IIf(_lGrava,"Log de Processamento","Log da Análise Prévia") +" da Rotina MFIN026 - Importacao de dados bancarios para o cadastro de Cliente"
MV_PAR03 := "sistema@italac.com.br"+Space(200)

aAdd( _aParAux , { 1 , "Assunto: "	, MV_PAR03, ""	, ""	, ""		, "" , 120 , .F. } )   
aAdd( _aParAux , { 1 , "Para: "	   , MV_PAR04, ""	, ""	, ""		, "" , 120 , .F. } )
aAdd( _aParAux , { 1 , "CC:   "	   , MV_PAR05, ""	, ""	, ""		, "" , 120 , .F. } )
aAdd( _aParAux , { 1 , "CCO:  "	   , MV_PAR06, ""	, ""	, ""		, "" , 120 , .F. } )

For _nI := 1 To Len( _aParAux )
      aAdd( _aParRet , _aParAux[_nI][03] )
Next _nI

If ParamBox( _aParAux , " Dados para envio do e-mail " , @_aParRet, _bOK )

   _cAssunto := MV_PAR03
   _cTit     := "Processamento do Arquivo " + MV_PAR02  

   _cMsgEml  := MFIN026ME(_cAssunto,_cTit,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc)

   cGetPara  := MV_PAR04
   cGetCc    := MV_PAR05
   cGetCco   := MV_PAR06

   _aConfig	 := U_ITCFGEML('')

   oProc:cCaption := ("Enviando o e-mail...")
   ProcessMessages()

   // Chama a função para envio do e-mail
   //ITEnvMail(cFrom       ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
   U_ITENVMAIL(_aConfig[01], cGetPara,   cGetCc,  cGetCco,_cAssunto, _cMsgEml,        "",_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )

   U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
   "E-mail para: "+cGetPara+;
   " Com Copia: "+cGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)
   
EndIf
   
Return .T.

/*
===============================================================================================================================
Programa----------: MFIN026PR
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Rotina de montangem do email
Parametros--------: oProc      = objeto da barra de processamento
------------------: _aDados    = Dados para importação
------------------: _lGrava    = Determina se grava os dados ou só analisa a integridade	
------------------: _nLinProc  = Numero de linhas Processadas
------------------: _nLinNProc = Numero de linhas Não Processadas	
Retorno-----------: _aLog  = Log de processamento do arquivo
===============================================================================================================================
*/              
Static Function MFIN026PR(oProc,_aDados,_nLinProc,_nLinNProc)
Local _nCont     := 0
Local _aLog      := {}
Local _cMsgProc  := "Processando"
Local _cQuery    := ""
Local _cTitulo   := ""
Local _nValor    := 0
Local _cCGC      := ""
Local cAlias     := ""

For _nCont := 1 To Len(_aDados)

   _cTitulo := MFIN026TT(_aDados[_nCont][7]) 
   _nValor := _aDados[_nCont][9]
   _nValor := StrTran(_nValor,"R$","")
   _nValor := StrTran(_nValor,".","")
   _nValor := Val(StrTran(_nValor,",","."))
   _cCGC   := StrTran(StrTran(StrTran(_aDados[_nCont][3],".",""),"/",""),"-","")

   oProc:cCaption := (_cMsgProc +" Linha: "+AllTrim(Str(_nCont)))
   ProcessMessages()

   cAlias :=  GetNextAlias()

   If Select(cAlias) > 0
      (cAlias)->(DBCloseArea())
   EndIf

   _cQuery := " SELECT SE1.R_E_C_N_O_ AS REG_SE1 , E1_SALDO"
   _cQuery += " FROM " + RetSqlName("SE1") + " SE1 "
   _cQuery += " JOIN " + RetSqlName("SA1") + " SA1 ON SA1.A1_COD = SE1.E1_CLIENTE AND SA1.D_E_L_E_T_ = ' ' "
   _cQuery += " WHERE SE1.D_E_L_E_T_ = ' ' AND SE1.E1_TIPO='NF' "
   _cQuery += "   AND SE1.E1_NUM || SE1.E1_PARCELA = '" + _cTitulo + "' " 
   _cQuery += "   AND SA1.A1_CGC = '" + _cCGC + "' " 

   DBUsearea(.T., "TOPCONN", TCGENQRY(,, _cQuery) , cAlias, .T., .F.)

   If (cAlias)->(!Eof())

      lStatus := (cAlias)->E1_SALDO <> _nValor
      aAdd(_aLog,{lStatus,AllTrim(Str(_nCont)),_aDados[_nCont][1], _aDados[_nCont][2], _aDados[_nCont][3], _aDados[_nCont][4], _aDados[_nCont][5], _aDados[_nCont][6],_aDados[_nCont][7],_aDados[_nCont][8],_aDados[_nCont][9],Transform((cAlias)->E1_SALDO,"@E 9999,999,999.99") ,IIf(lStatus,"Saldo a Modificar","")})
      _nLinProc++

      (cAlias)->(DBSkip())
   Else
      aAdd(_aLog,{.F.,AllTrim(Str(_nCont)),_aDados[_nCont][1], _aDados[_nCont][2], _aDados[_nCont][3], _aDados[_nCont][4], _aDados[_nCont][5], _aDados[_nCont][6],_aDados[_nCont][7],_aDados[_nCont][8],_aDados[_nCont][9],Space(10)+"-","Erro: Registro não encontrado no Protheus"})
      _nLinNProc++
   EndIf

   (cAlias)->(DBCloseArea())

Next

Return _aLog

/*
===============================================================================================================================
Programa----------: MFIN026TT
Autor-------------: Igor Melgaço
Data da Criacao---: 14/05/2024
Descrição---------: Rotina de montangem da contatenação de Titulo e parcela
Parametros--------: cTitulo    
Retorno-----------: cTitPar  = Titulo + Parcela
===============================================================================================================================
*/ 
Static Function MFIN026TT(cTitulo)
Local cTitPar := ""
Local cTit := ""
Local cPar := ""
Local lPar := .F.
Local i := 0
Local _nTamE1_NUM := TamSX3("E1_NUM")[01]
Local _nTamE1_PARCELA := TamSX3("E1_PARCELA")[01]

For i :=  1 to Len(cTitulo)
   If Subs(cTitulo,i,1) == "-"
      lPar := .T.
   EndIf
   If lPar .And. Subs(cTitulo,i,1) <> "-"
      cPar += Subs(cTitulo,i,1)
   ElseIf !lPar .And. Subs(cTitulo,i,1) <> "-"
      cTit += Subs(cTitulo,i,1)
   EndIf
Next

cPar := StrZero(Val(cPar),_nTamE1_PARCELA)
cTit := StrZero(Val(cTit),_nTamE1_NUM)

If cPar == "00"
   cPar := Space(_nTamE1_PARCELA)
EndIf

cTitPar := cTit + cPar
 
Return cTitPar
