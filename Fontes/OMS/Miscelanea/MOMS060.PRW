/*
=====================================================================================================================================
        						 ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
=====================================================================================================================================
   Autor     |	Data	 |										Motivo																
-------------------------------------------------------------------------------------------------------------------------------------
Lucas Borges |23/07/25| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
=====================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "rwmake.ch"
#Include "TBICONN.CH"  
#Include 'TOPCONN.CH'
/*
===============================================================================================================================
Programa----------: MOMS060
Autor-------------: Igor Melgaço
Data da Criacao---: 28/04/2021
===============================================================================================================================
Descrição---------: Importação de dados bancários de clientes CHAMADO 33787
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS060()
Local _nI        := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| If(MV_PAR01 <> "" .AND. MV_PAR02 <> ""  ,.T.,(U_ITMsg("Os campos pasta e arquivo precisam ser preenchidos.",'Atenção!',IIf(AllTrim(MV_PAR01)="","Preencha o campo pasta!","Preencha o campo arquivo!"),3),.F.) ) }
Local _cTimeIni  := Time()
Local _lRet      := .F.

MV_PAR01 := "\DATA\ITALAC\MOMS060\" + Space(200)
MV_PAR02 := "imp_bancos.csv       " + Space(200)
MV_PAR03 := Space(200)
MV_PAR04 := Space(200)
MV_PAR05 := Space(200)
MV_PAR06 := Space(200)

aAdd( _aParAux , { 1 , "Pasta: "	   , MV_PAR01, ""	, ""	, ""		, "" , 120 , .F. } )
aAdd( _aParAux , { 1 , "Arquivo: "	, MV_PAR02, ""	, ""	, ""		, "" , 120 , .F. } )

For _nI := 1 To Len( _aParAux )
      aAdd( _aParRet , _aParAux[_nI][03] )
Next _nI

If !ParamBox( _aParAux , " Importação de Dados Bancarios de Clientes " , @_aParRet, _bOK )
   _lRet := .F.
Else
   FWMsgRun( ,{|oProc|  _lRet := MOMS060IM(oProc) } , "Hora Inicial: "+_cTimeIni+" Importando arquivo: "+AllTrim(MV_PAR02) )
EndIf

Return _lRet



/*
===============================================================================================================================
Programa----------: MOMS060IM
Autor-------------: Igor Melgaço
Data da Criacao---: 28/04/2021
===============================================================================================================================
Descrição---------: Importa os dados do cliente
===============================================================================================================================
Parametros--------: oProc = objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS060IM(oProc)
Local _cArq      := "" 
Local _aDados    := {}
Local _cLinInv   := ""
Local _aLog      := {}
Local _aCab      := {}
Local _aSizes    := {}
Local _nLinProc  := 0
Local _nLinNProc := 0
Local _lRetMsg   := .F.
Local _lConf     := .F.
Local _lContinua := .F.
Local _aButtons  := {}

_cArq += AllTrim(MV_PAR01) + AllTrim(MV_PAR02)

_aCab     := {"Status","Linha","A1_COD", "A1_LOJA", "A1_CGC", "BANCO", "AGENCIA", "CONTA","Log"}
_aSizes   := {"02","05","05","05","10","10","10","10","43"}

oProc:cCaption := ("Lendo Arquivo...")
ProcessMessages()

If !(MOMS060LA(oProc,_cArq,@_aDados,@_cLinInv)) //Faz leitura do arquivo
   Return .F.
EndIf

If Len(_aDados) <= 0
   U_ITMsg( "Não foram encontrados registros válidos no arquivo!" , "Atenção!",,1 )
   Return .F.
EndIf

_aLog := MOMS060PR(oProc,_aDados,.F.,@_nLinProc,@_nLinNProc) // Faz o processamento sem gravação e retorna um log

//Validador
_cTitAux := "Dados do Arquivo " + _cArq
_cMsgTop := "Análise prévia da Importação, Registros Lidos: " + AllTrim(TRANSFORM(_nLinProc+_nLinNProc,"@E 999,999,999")) + ", Com Erros: " + AllTrim(TRANSFORM(_nLinNProc,"@E 999,999,999"))

_aButtons := {}
aAdd(_aButtons,{"BUDGET",{|| MOMS060EE(oProc,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc,.F.)  },"", "E-mail" }) 

oProc:cCaption := ("Abrindo o Log do Arquivo...")
ProcessMessages()

While !_lConf
       //     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
   _lRetMsg := U_ITLISTBOX(_cTitAux, _aCab    , _aLog     , .T.      , 4      , _cMsgTop ,          , _aSizes ,         ,     ,        , _aButtons)
   
   If !_lRetMsg
      _lConf     := .T.
      _lContinua := .F.
   ElseIf _lRetMsg .And. _nLinNProc > 0
      _lRetMsg := U_ITMsg("Confirma importação mesmo contendo registros com erro?",'Atenção!',,3,2,3,,"Confirmar","Voltar")
      If _lRetMsg
         _lConf     := .T.
         _lContinua := .T.
      Else
         _lConf     := .F.
         _lContinua := .F.
      EndIf
   Else
      _lConf     := .T.
      _lContinua := .T.
   EndIf

EndDo

If _lContinua  
   _nLinProc  := 0
   _nLinNProc := 0

   oProc:cCaption := ("Efetuando o processamento do arquivo...")
   ProcessMessages()

   _aLog := MOMS060PR(oProc,_aDados,.T.,@_nLinProc,@_nLinNProc) // Faz o processamento com gravação e retorna um log

   If _nLinNProc > 0
      _lRetMsg := U_ITMsg("A importação do arquivo apresentou erro! Deseja visualizar?",'Atenção!',,3,2,3,,"Sim","Não")
      If _lRetMsg
         _aButtons := {}
         aAdd(_aButtons,{"BUDGET",{|| MOMS060EE(oProc,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc,.T.)  },"", "E-mail" }) 

             //     ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _aButtons )
         _lRetMsg := U_ITLISTBOX(_cTitAux, _aCab    , _aLog     , .T.      , 4      , _cMsgTop ,          , _aSizes ,         ,     ,        , _aButtons)
      EndIf
   EndIf

   U_ITMsg( "Processamento finalizado!" , "Atenção!",,2 )

EndIf

Return .T.



/*
===============================================================================================================================
Programa----------: MOMS060LA
Autor-------------: Igor Melgaço
Data da Criacao---: 28/04/2021
===============================================================================================================================
Descrição---------: Rotina de leitura do arquivo
===============================================================================================================================
Parametros--------: oProc    = objeto da barra de processamento
------------------: _cArq    = Arquivo usado na importação de dados
------------------: _cLinInv = Linhas inválidas não processadas
===============================================================================================================================
Retorno-----------: _aDados = Dados do arquivo
===============================================================================================================================
*/  
Static Function MOMS060LA(oProc,_cArq,_aDados,_cLinInv)
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
FT_FSKIP() //PULA O CABEÇALHO

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
   _nCont++

	oProc:cCaption := ( "Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nTotLin,5) + "." )
	ProcessMessages()

   _cDados  := FT_FREADLN()
   _aLinha  := StrTokArr(_cDados,";")
   
   //Verifica se é final de arquivo
   If AllTrim(_cDados) = ';;;;;' .And. _nCont > _nTotLin
      Exit
   EndIf 	
   
   _nNumCol := Len(_aLinha)

   //Verifica se é linha válida validando 6 colunas
   If _nNumCol = 6
      aAdd(_aDados,_aLinha)
   Else
      _cLinInv += IIf(Empty(AllTrim(_cLinInv)),"","; ") + AllTrim(Str(_nCont))
   EndIf

   FT_FSKIP()
EndDo

Return .T.



/*
===============================================================================================================================
Programa----------: MOMS060AR
Autor-------------: Igor Melgaço
Data da Criacao---: 29/04/2021
===============================================================================================================================
Descrição---------: Rotina de montangem do email
===============================================================================================================================
Parametros--------: _cGetAssun = Assunto do email
------------------: _cTit      = Titulo da tabela
------------------: _aCab      = Cabeçalho da tabela
------------------: _aSizes    = Tamanhos das Colunas
------------------: _aLista    = Listagem dos registros do log
------------------: _cLinInv   = Linhas inválidas fora do layout
------------------: _nLinProc  = Numero de linhas Processadas
------------------: _nLinNProc = Numero de linhas Não Processadas
===============================================================================================================================
Retorno-----------: _cMsgEml = 
===============================================================================================================================
*/              
Static Function MOMS060ME(_cGetAssun,_cTit,_aCab,_aSizes,_aLista,_cLinInv,_nLinProc,_nLinNProc)
Local _cMsgEml   := ""
Local _cGetLista := ""
Local _nCont     := 0

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
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[01]+'%"><b>'+_aCab[01]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[02]+'%"><b>'+_aCab[02]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[03]+'%"><b>'+_aCab[03]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[04]+'%"><b>'+_aCab[04]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[05]+'%"><b>'+_aCab[05]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[06]+'%"><b>'+_aCab[06]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[07]+'%"><b>'+_aCab[07]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[08]+'%"><b>'+_aCab[08]+'</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="'+_aSizes[09]+'%"><b>'+_aCab[09]+'</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    #LISTA#'
_cMsgEml += '</table>'

For _nCont := 1 To Len(_aLista)
   
   _cGetLista += '    <tr>'
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[01]+'%">'+ IIf(_aLista[_nCont][01],"OK","ERRO") +'</td>' 
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[02]+'%">'+ _aLista[_nCont][02] +'</td>' 
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[03]+'%">'+ _aLista[_nCont][03] +'</td>' 
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[04]+'%">'+ _aLista[_nCont][04] +'</td>' 
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[05]+'%">'+ _aLista[_nCont][05] +'</td>' 
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[06]+'%">'+ _aLista[_nCont][06] +'</td>'
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[07]+'%">'+ _aLista[_nCont][07] +'</td>' 
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[08]+'%">'+ _aLista[_nCont][08] +'</td>'
   _cGetLista += '      <td class="itens" align="left" width="'+_aSizes[09]+'%">'+ _aLista[_nCont][09] +'</td>'
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
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [MOMS060]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

Return _cMsgEml



/*
===============================================================================================================================
Programa----------: MOMS060PR
Autor-------------: Igor Melgaço
Data da Criacao---: 30/04/2021
===============================================================================================================================
Descrição---------: Rotina de montangem do email
===============================================================================================================================
Parametros--------: oProc = objeto da barra de processamento
------------------: _aCab      = Cabeçalho da tabela
------------------: _aSizes    = Tamanhos das Colunas
------------------: _aLog      = Listagem dos registros do log
------------------: _cLinInv   = Linhas inválidas fora do layout
------------------: _nLinProc  = Numero de linhas Processadas
------------------: _nLinNProc = Numero de linhas Não Processadas	
------------------: _lGrava    = Determina se o aLog veio da análise (.F.) ou processamento da importação (.T.)	
===============================================================================================================================
Retorno-----------: .T.
===============================================================================================================================
*/              
Static Function MOMS060EE(oProc,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc,_lGrava)
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

MV_PAR02 := IIf(_lGrava,"Log de Processamento","Log da Análise Prévia") +" da Rotina MOMS060 - Importacao de dados bancarios para o cadastro de Cliente"
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

   _cMsgEml  := MOMS060ME(_cAssunto,_cTit,_aCab,_aSizes,_aLog,_cLinInv,_nLinProc,_nLinNProc)

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
Programa----------: MOMS060PR
Autor-------------: Igor Melgaço
Data da Criacao---: 30/04/2021
===============================================================================================================================
Descrição---------: Rotina de montangem do email
===============================================================================================================================
Parametros--------: oProc      = objeto da barra de processamento
------------------: _aDados    = Dados para importação
------------------: _lGrava    = Determina se grava os dados ou só analisa a integridade	
------------------: _nLinProc  = Numero de linhas Processadas
------------------: _nLinNProc = Numero de linhas Não Processadas	
===============================================================================================================================
Retorno-----------: _aLog  = Log de processamento do arquivo
===============================================================================================================================
*/              
Static Function MOMS060PR(oProc,_aDados,_lGrava,_nLinProc,_nLinNProc)
Local _nTamA1Cod := 0
Local _nCont     := 0
Local _aLog      := {}
Local _cMRegAlt  := ""
Local _cMRegUsa  := ""
Local _cMLinAlt  := ""
Local _cMChNEnc  := ""
Local _cMsgProc  := ""

_cMRegAlt  := "Registro alterado com sucesso!"
_cMRegUsa  := "Registro em uso por outro processo."
_cMLinAlt  := "Linha pronta para importação!"
_cMChNEnc  := "Chave de cliente não encontrada para importação."
_cMsgProc  := IIf(_lGrava,"Processando","Lendo")
_nTamA1Cod := TamSX3("A1_COD")[01]
_nTamA1Loj := TamSX3("A1_LOJA")[01]

For _nCont := 1 To Len(_aDados)
   DBSelectArea("SA1")
   DBSetOrder(1)
   If DBSeek(xFilial("SA1")+StrZero(Val(_aDados[_nCont][1]),_nTamA1Cod)+StrZero(Val(_aDados[_nCont][2]),_nTamA1Loj) )
      
      oProc:cCaption := (_cMsgProc +" Linha: "+AllTrim(Str(_nCont))+"  Cliente: "+SA1->A1_COD+" - "+SA1->A1_LOJA+"  "+SA1->A1_NREDUZ)
      ProcessMessages()
      
      If _lGrava
         Begin Transaction
            If SA1->(RecLock("SA1",.F.))
               SA1->A1_I_BREC := _aDados[_nCont][4]
               SA1->A1_I_AREC := _aDados[_nCont][5]
               SA1->A1_I_CREC := _aDados[_nCont][6]
               SA1->(MSUnLock())
               
               aAdd(_aLog,{.T.,AllTrim(Str(_nCont)),_aDados[_nCont][1], _aDados[_nCont][2], _aDados[_nCont][3], _aDados[_nCont][4], _aDados[_nCont][5], _aDados[_nCont][6],_cMRegAlt})
               _nLinProc++
            Else
               aAdd(_aLog,{.F.,AllTrim(Str(_nCont)),_aDados[_nCont][1], _aDados[_nCont][2], _aDados[_nCont][3], _aDados[_nCont][4], _aDados[_nCont][5], _aDados[_nCont][6],_cMRegUsa})
               _nLinNProc++
            EndIf
         End Transaction
      Else
         aAdd(_aLog,{.T.,AllTrim(Str(_nCont)),_aDados[_nCont][1], _aDados[_nCont][2], _aDados[_nCont][3], _aDados[_nCont][4], _aDados[_nCont][5], _aDados[_nCont][6],_cMLinAlt})
         _nLinProc++
      EndIf
   Else
      aAdd(_aLog,{.F.,AllTrim(Str(_nCont)),_aDados[_nCont][1], _aDados[_nCont][2], _aDados[_nCont][3], _aDados[_nCont][4], _aDados[_nCont][5], _aDados[_nCont][6],_cMChNEnc})
      _nLinNProc++
   EndIf
Next

Return _aLog
