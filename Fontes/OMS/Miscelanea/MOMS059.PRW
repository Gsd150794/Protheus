/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |14/10/2021| Chamado 36246  Ajustes para apagar o vendedor 2 qdo o cliente For inativado.
Julio Paz     |27/09/2023| Chamado 44502. Alterar rotina e fixar limite de crédito quando o cliente For inativado.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada da função de conout
=====================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "rwmake.ch"
#Include "TBICONN.CH"  
#Include 'TOPCONN.CH'

Static _cVendGen  := ""

/*
===============================================================================================================================
Programa----------: MOMS059
Autor-------------: Igor Melgaço
Data da Criacao---: 21/04/2021
Descrição---------: Workflow clientes inativados por gerente CHAMADO 36246
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS059()
Local nI         := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| If(MV_PAR01 > 0,.T.,(U_ITMsg("Valor inválido atribuído ao parâmetro.",'Atenção!',"Insira um valor > 0.",3),.F.) ) }
Local _lTela     := .T.
Local _cTimeIni  := Time()
Local _lRet      := .F.

//Testa se esta sendo rodado do menu
If	Select('SX3') == 0
	

   RPCSetType( 3 )					//Não consome licensa de uso
	
   RpcSetEnv('01','01',,,,GetEnvServer(),{ "SA1","SA3","SC5" })
	sleep( 5000 )						//Aguarda 5 segundos para que as jobs IPC subam.
	
   _lTela := .F.
   
   MV_PAR01 := U_ItGetMV("IT_DIASINA",90)
   
Else
   
   MV_PAR01 := U_ItGetMV("IT_DIASINA",90)

   
   aAdd( _aParAux , { 1 , "Dias de Inatividade:"	, MV_PAR01, "999"	, ""	, ""		, "" , 020 , .F. } )
   
   For nI := 1 To Len( _aParAux )
	    aAdd( _aParRet , _aParAux[nI][03] )
   Next nI
   
   If !ParamBox( _aParAux , "Inativação de Clientes" , @_aParRet, _bOK )
	   Return .F.
   EndIf
   
EndIf

_cVendGen  := U_ItGetMV("IT_VENDGEN","000156")

If _lTela
	
	FWMsgRun( ,{|oProc|  _lRet := MOMS059EM(oProc) } , "Hora Inicial: "+_cTimeIni+" Inativação de Clientes " )

Else
	//Atualização tabela SM2
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS059"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05901"/*cMsgId*/, "MOMS05901 - INICIO DO PROCESSAMENTO - Hora Inicial: "+_cTimeIni/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	_lRet := MOMS059EM()
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MOMS059"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05902"/*cMsgId*/, "MOMS05902 - FIM DO PROCESSAMENTO - Hora Final: "+TIME()/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)	
   RpcClearEnv() //Libera o Ambiente

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS059EM
Autor-------------: Igor Melgaço
Data da Criacao---: 21/04/2021
Descrição---------: Dispara os emails
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS059EM(oProc)
Local _aConfig	  := {}
Local _cEmlLog	  := ""
Local _cMsgEml	  := ""
Local _cGetLista := ""
Local _aCab      := {}
Local _aSizes    := {}
Local cGetCc	  := ""
Local cGetPara	  := ""
Local cGetAssun  := "Clientes inativados"
Local cTit       := " "
Local _aGerent   := {}
Local _cTitulo   := "Clientes Inativados"
Local _cFonte    := "MOMS059"
Local i          := 0

//           01   02   03   04   05   06   07   08     
_aSizes := {"05","15","05","03","20","31","10","05","3","3"}
_aCab   := {"Cod Vendedor","Nome Vendedor","Cod Cliente","Loja","Fantasia","Razão Social","Municipio","UF","Ultima CPR","Dt Cadastro"} 

If oProc <> Nil
   oProc:cCaption := ("Lendo Gerentes...")
   ProcessMessages()
EndIf

_aGerent := MOMS059GER()

_aConfig	  := U_ITCFGEML('')

For i := 1 To Len(_aGerent)
   
   cTit := "Gerente: " + _aGerent[i][2] + " - " + _aGerent[i][3] + "  e-mail: " + _aGerent[i][4] + "  Cod. Vend. Inativo: " + _aGerent[i][5] + " - " + _aGerent[i][6]
   cGetPara	:= _aGerent[i][4] 
   
   //Logo Italac
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
   _cMsgEml += '<br>'
   //Celula Azul para Título
   _cMsgEml += '<table class="bordasimples" width="600">'
   _cMsgEml += '    <tr>'
   _cMsgEml += '	     <td class="titulos"><center>'+cTit+'</center></td>'
   _cMsgEml += '	 </tr>'
   _cMsgEml += '</table>'
   _cMsgEml += '<br>'

   If oProc <> Nil
      oProc:cCaption := ("Lendo clientes do gerente "+AllTrim(_aGerent[i][3]))
      ProcessMessages()
   EndIf

   _cGetLista := MOMS059CLI(_aSizes,_aGerent[i][2],_aGerent[i][5])

   If !Empty(AllTrim(_cGetLista)) 
         
      //Cabeçalho
      _cMsgEml += '<br>'
      _cMsgEml += '<table class="bordasimples" width="1300">' 
      _cMsgEml += '    <tr>'
      _cMsgEml += '		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>'+_cTitulo+'</b></td>'
      _cMsgEml += '    </tr>'
      _cMsgEml += '    <tr>'
      _cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[01]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[02]+'%"><b>'+_aCab[02]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[03]+'%"><b>'+_aCab[03]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[04]+'%"><b>'+_aCab[04]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[05]+'%"><b>'+_aCab[05]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[06]+'%"><b>'+_aCab[06]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%"><b>'+_aCab[07]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[08]+'%"><b>'+_aCab[08]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[09]+'%"><b>'+_aCab[09]+'</b></td>'
      _cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[10]+'%"><b>'+_aCab[10]+'</b></td>'
      _cMsgEml += '    </tr>'
      _cMsgEml += '    #LISTA#'
      _cMsgEml += '</table>'

      _cMsgEml := StrTran(_cMsgEml,"#LISTA#",_cGetLista)

   Else   

      _cMsgEml += '<br>'
      _cMsgEml += '<table class="bordasimples" width="1300">'
      _cMsgEml += '    <tr>'
      _cMsgEml += ' 		<td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>Não há clientes inativos nesse periodo</b></td>'
      _cMsgEml += '    </tr>'
      _cMsgEml += '</table>'
      _cMsgEml += '</body>'
      _cMsgEml += '</html>'

   EndIf

   _cMsgEml += '</center>'
   _cMsgEml += '<br>'
   _cMsgEml += '<br>'
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> ['+_cFonte+']</td>'
   _cMsgEml += '    </tr>'
   _cMsgEml += '</body>'
   _cMsgEml += '</html>'

   If oProc <> Nil
      oProc:cCaption := ("Enviando o e-mail do "+AllTrim(_aGerent[i][3]))
      ProcessMessages()
   EndIf

   // Chama a função para envio do e-mail
   //ITEnvMail(cFrom       ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
   U_ITENVMAIL(_aConfig[01], cGetPara,   cGetCc,       "",cGetAssun, _cMsgEml,        "",_aConfig[01], _aConfig[02],_aConfig[03],_aConfig[04],_aConfig[05],_aConfig[06],_aConfig[07], @_cEmlLog )
   
   If oProc <> Nil
      U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
         "E-mail para: "+cGetPara+;
         " Com Copia: "+cGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)
   EndIf   

Next

If Len(_aGerent) = 0 .And. oProc <> Nil
   U_ITMsg("Não há gerentes com clientes a inativar.","Envio do E-MAIL",,3)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS059GER
Autor-------------: Igor Melgaço
Data da Criacao---: 21/04/2021
Descrição---------: Gerentes com clientes a inativar
Parametros--------: Nenhum	
Retorno-----------: _aGerent = Array com dados dos Gerentes
===============================================================================================================================
*/  
Static Function MOMS059GER()
Local cAliasSA3 := ''
Local _cFiltro	 := ''
Local _aGerent  := {}

cAliasSA3 := GetNextAlias()

_cFiltro += "% SA1.A1_MSBLQL <> '1' "
_cFiltro += "    AND SA1.D_E_L_E_T_ = ' ' "
_cFiltro += "    AND SA1.A1_CLIFUN <> '1' "

If !Empty(AllTrim(_cVendGen))
   _cFiltro += "    AND SA1.A1_VEND NOT IN "+FormatIn(_cVendGen,";") 
EndIf

_cFiltro += "    AND SA1.A1_I_DTREA < '" + DToS(DaySub(Date(),20)) +  "' "
_cFiltro += "    AND SA3_2.A3_I_INAT <> '' "
_cFiltro += "    AND CONCAT(SA1.A1_COD,SA1.A1_LOJA) NOT IN( "
_cFiltro += "     SELECT CONCAT(SC5.C5_CLIENTE,SC5.C5_LOJACLI) "
_cFiltro += "     FROM " + RetSQLName("SC5") + " SC5 "
_cFiltro += "     WHERE SC5.C5_EMISSAO > '" + DToS(DaySub(Date(),MV_PAR01)) + "' "
_cFiltro += "        AND SC5.D_E_L_E_T_ = ' ' "
_cFiltro += "     GROUP BY CONCAT(SC5.C5_CLIENTE,SC5.C5_LOJACLI) )"
_cFiltro += " %"

BeginSql Alias cAliasSA3
   SELECT SA3_2.A3_FILIAL, SA3.A3_GEREN, SA3_2.A3_NOME, SA3_2.A3_EMAIL, SA3_2.A3_I_INAT, SA3_3.A3_NOME AS NOMEINAT  
   FROM %Table:SA1% SA1 JOIN %Table:SA3% SA3 ON (SA1.A1_VEND = A3_COD AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3% ) 
         LEFT JOIN %Table:SA3% SA3_2 ON (SA3.A3_FILIAL = SA3_2.A3_FILIAL AND SA3.A3_GEREN = SA3_2.A3_COD AND SA3_2.%notdel% )
         LEFT JOIN %Table:SA3% SA3_3 ON (SA3_2.A3_FILIAL = SA3_3.A3_FILIAL AND SA3_2.A3_I_INAT = SA3_3.A3_COD AND SA3_3.%notdel% )
   WHERE	%Exp:_cFiltro%
   GROUP BY SA3_2.A3_FILIAL, SA3.A3_GEREN, SA3_2.A3_NOME, SA3_2.A3_EMAIL, SA3_2.A3_I_INAT, SA3_3.A3_NOME 
   ORDER BY SA3_2.A3_FILIAL, SA3.A3_GEREN
EndSql

DBSelectArea(cAliasSA3)
(cAliasSA3)->(DBGoTop())
If !(cAliasSA3)->(Eof())
	While !(cAliasSA3)->(Eof())
      aAdd(_aGerent,{ (cAliasSA3)->A3_FILIAL,;
                     (cAliasSA3)->A3_GEREN,;
                     (cAliasSA3)->A3_NOME,;
                     (cAliasSA3)->A3_EMAIL,;
                     (cAliasSA3)->A3_I_INAT,;
                     (cAliasSA3)->NOMEINAT})

		(cAliasSA3)->(DBSkip())

	EndDo
   (cAliasSA3)->( DBCloseArea() )
EndIf

Return _aGerent

/*
===============================================================================================================================
Programa----------: MOMS059CLI
Autor-------------: Igor Melgaço
Data da Criacao---: 21/04/2021
Descrição---------: Gera o array da query de Títulos a Receber (SE1)
Parametros--------: _aSizes = Tamanho das colunas
                    _cCodGer = Código do gerente 
                    _cCodInat = Codigo de Vendedor Inativo para substituir o código do vendedor atual do cadastro do Cliente
Retorno-----------: _cGetLista = Lista de Clientes Inativados
===============================================================================================================================
*/  
Static Function MOMS059CLI(_aSizes,_cCodGer,_cCodInat)
Local cAliasSA1  := ""
Local _cFiltro	  := ""
Local _cGetLista := ""
Local _cCodUsr   := RetCodUsr() 
Local _aDadLog   := {}
Local _nValCbLq  := U_ITGETMV( 'IT_VALCBLQ',20.00 ) // Valor de limite de crédito de bloqueio.

cAliasSA1:= GetNextAlias()

_cFiltro += "% SA1.A1_MSBLQL <> '1' "
_cFiltro += "    AND SA1.D_E_L_E_T_ = ' ' "
_cFiltro += "    AND SA1.A1_CLIFUN <> '1' "

If !Empty(AllTrim(_cVendGen))
   _cFiltro += "    AND SA1.A1_VEND NOT IN "+FormatIn(_cVendGen,";") 
EndIf

_cFiltro += "    AND SA1.A1_I_DTREA < '" + DToS(DaySub(Date(),20)) +  "' "
_cFiltro += "    AND SA3.A3_GEREN = '"+_cCodGer+"' "
_cFiltro += "    AND CONCAT(SA1.A1_COD,SA1.A1_LOJA) NOT IN( "
_cFiltro += "     SELECT CONCAT(SC5.C5_CLIENTE,SC5.C5_LOJACLI) "
_cFiltro += "     FROM " + RetSQLName("SC5") + " SC5 "
_cFiltro += "     WHERE SC5.C5_EMISSAO > '" + DToS(DaySub(Date(),MV_PAR01)) + "' "
_cFiltro += "        AND SC5.D_E_L_E_T_ = ' ' "
_cFiltro += "     GROUP BY CONCAT(SC5.C5_CLIENTE,SC5.C5_LOJACLI) ) "
_cFiltro += " %"

BeginSql Alias cAliasSA1
   SELECT SA1.A1_VEND, SA3.A3_NOME AS NOME_VEN, SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, SA1.A1_NREDUZ, SA1.A1_MUN, SA1.A1_EST, SA1.A1_ULTCOM, SA1.A1_I_DTCAD
   FROM %Table:SA1% SA1 JOIN %Table:SA3% SA3 ON (SA1.A1_VEND = A3_COD AND SA3.%notdel% AND SA3.A3_FILIAL = %xFilial:SA3% ) 
   WHERE	%Exp:_cFiltro%
   ORDER BY SA1.A1_VEND,SA1.A1_COD, SA1.A1_LOJA
EndSql

DBSelectArea(cAliasSA1)
(cAliasSA1)->(DBGoTop())
If !(cAliasSA1)->(Eof())
	While !(cAliasSA1)->(Eof())
      _aDadLog := {}
      Begin Transaction
         DBSelectArea("SA1")
         DBSetOrder(1)
         If DBSeek(xFilial("SA1")+(cAliasSA1)->A1_COD+(cAliasSA1)->A1_LOJA)
            If SA1->(RecLock("SA1",.F.)) 

               aAdd( _aDadLog , {'A1_VEND'	,SA1->A1_VEND	 , '' } )
               aAdd( _aDadLog , {'A1_I_VEND2',SA1->A1_I_VEND2, '' } )
               aAdd( _aDadLog , {'A1_MSBLQL' ,SA1->A1_MSBLQL , '' } )
               aAdd( _aDadLog , {'A1_LC'     ,SA1->A1_LC     , '' } )
               
               SA1->A1_VEND    := _cCodInat
               SA1->A1_I_VEND2 := ""
               SA1->A1_MSBLQL  := "1"
               SA1->A1_LC      := _nValCbLq // Valor de limite de crédito de bloqueio.
               SA1->(MSUnLock()) 
               
               U_ITGrvLog( _aDadLog , 'SA1' , 1 , SA1->(A1_FILIAL + A1_COD + A1_LOJA) , 'I' , _cCodUsr , Date() , Time() )
            
               _cGetLista += '    <tr>'
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[01]+'%">'+ (cAliasSA1)->A1_VEND+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[02]+'%">'+ (cAliasSA1)->NOME_VEN+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[03]+'%">'+ (cAliasSA1)->A1_COD+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[04]+'%">'+ (cAliasSA1)->A1_LOJA+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[05]+'%">'+ AllTrim((cAliasSA1)->A1_NREDUZ)+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[06]+'%">'+ AllTrim((cAliasSA1)->A1_NOME)+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%">'+ (cAliasSA1)->A1_MUN+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[08]+'%">'+ (cAliasSA1)->A1_EST +'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[09]+'%">'+ IIf(Empty(AllTrim((cAliasSA1)->A1_ULTCOM)),"",DToC(SToD((cAliasSA1)->A1_ULTCOM)))+'</td>' 
               _cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[10]+'%">'+ IIf(Empty(AllTrim((cAliasSA1)->A1_I_DTCAD)),"",DToC(SToD((cAliasSA1)->A1_I_DTCAD)))+'</td>' 
               _cGetLista += '    </tr>'
            EndIf
         EndIf
      End Transaction

      (cAliasSA1)->(DBSkip())
	EndDo
   (cAliasSA1)->( DBCloseArea() )
EndIf

Return _cGetLista
