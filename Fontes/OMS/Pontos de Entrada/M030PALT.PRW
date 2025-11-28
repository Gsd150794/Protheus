/*
================================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
================================================================================================================================
       Autor      |    Data    |                                             Motivo                                            |
------------------:------------:-----------------------------------------------------------------------------------------------:
 Julio Paz        | 14/09/2016 | Chamado: 16681 - Gravação da alteração de dados do cadastro de clientes nas tabelas de muro para               
                  |            | integração com o sistema RDC.                                                                
------------------:------------:-----------------------------------------------------------------------------------------------:
 Darcio Sporl	  | 20/01/2017 | Chamado: 17503 - Foi incluído o tratamento para salvar o endereço ao executar o mashup. 		   
------------------:------------:-----------------------------------------------------------------------------------------------:
 Julio Paz        | 12/03/2021 | Chamado: 35759 - Quando Cliente alterado p/Simples Nacional=Não,limpar codigo tab Treço Simp.Nac. 
------------------:------------:-----------------------------------------------------------------------------------------------:
 Julio Paz        | 29/12/2021 | Chamado: 30177 - Inclusão de rotina para bloqueio e Workflow de clientes com desconto contratual. 
------------------:------------:-----------------------------------------------------------------------------------------------:
 Julio Paz        | 09/08/2022 | Chamado: 40841 - limpar conteúdo campos Suframa,quando cliente não fizer parte dos estados Suframa.
-------------------------------------------------------------------------------------------------------------------------------:
 Julio Paz        | 09/08/2022 | Chamado: 40931 - Na incl/alt funcionários, Gravar cad.Clientes:Segmento=39 e Tipo=Consumidor Final. 
-------------------------------------------------------------------------------------------------------------------------------:
 Igor Melgaço     | 11/08/2022 | Chamado: 40048 - Ajustes para substituição de caracteres invalidos. 
-------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 25/07/2023 | Chamado: 44096. Ajustar rotina incl/alter gravar Grupo Tributação "023" p/Parana e Simples Nac
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves     | 07/02/2024 | Chamado 46248. Adicionada as UFs AC - RO nos Estados do Suframa
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves     | 28/03/2024 | Chamado 46686. Tratar o desbloqeuio quando o grupo de clientes não possuir regra de desconto
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves     | 26/04/2024 | Chamado 47084. Retorno da tratativa anterior de bloqueio conforme solicitação.
-------------------------------------------------------------------------------------------------------------------------------
 Igor Melgaço     | 02/07/2024 | Chamado: 47127 - Ajustes para não gravar o campo A1_MSBLQL.
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 23/07/2025 | Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
===============================================================================================================================
*/*/
#Include "TOTVS.ch"

Static _lAltCodTab := .F.

/*
===============================================================================================================================
Programa--------: M030PALT
Autor-----------: Darcio Ribeiro Spörl
Data da Criacao-: 22/12/2016
===============================================================================================================================
Descrição-------: Ponto de entrada executado para validação após confirmação da alteração do cliente
===============================================================================================================================
Uso-------------: Italac
===============================================================================================================================
Parametros------: ParamIXB[1] - nOpc
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
Setor-----------: TI
===============================================================================================================================
*/
User Function M030PALT()

Local _aArea	 := FWGetArea()
Local _nOpcao	 := ParamIXB[1]
Local _lRet	 	 := .T.
Local _lMashup	 := U_ItGetMV("IT_MASHUP",.F.)
Local _lLibMas	 := .F.
Local _nQtdDia	 := Val(SA1->A1_I_PEREX)
Local _nQtdiaT	 := dDataBase - SA1->A1_I_DTEXE
Local _lExec	 := IIf(_nQtdDia > _nQtdiaT, .T., .F.)
Local _aBloqSA1
Local _cA1_NOME    := ""
Local _cA1_END     := ""
Local _cA1_BAIRRO  := ""
Local _cA1_ENDCOB  := ""
Local _cA1_ENDREC  := ""
Local _cA1_ENDENT  := ""
Local _cA1_BAIRROE := ""

Local _cUfMVA := U_ITGetMV("IT_UFSMVA","PR")
Local _cTRIBMVA := U_ITGetMV("IT_TRIBMVA","023")

Begin Sequence   

	If _nOpcao == 1
	   //===================================================================================
       // Grava os dados dos clientes nas tabelas de muro para integração com o sistema RDC.
       //===================================================================================
       U_AOMS076G()
   
       //===================================================================================
       // Rotina de Mashup
       //===================================================================================
		If _lMashup
			If SA1->A1_PESSOA <> "F"
				_cUser := RetCodUsr()
			
				DBSelectArea("ZZL")
				ZZL->( DBSetOrder(3) )
				If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
					If ZZL->ZZL_LIBMAS == "S"
						_lLibMas := .T.
					EndIf
				EndIf
	            
				If !_lLibMas
					If (AllTrim(SA1->A1_I_SITRF) <> "ATIVO" .And. AllTrim(SA1->A1_I_SITRF) <> "REGULAR" .And. AllTrim(SA1->A1_I_SITRF) <> "APTO" .And. AllTrim(SA1->A1_I_SITRF) <> "ATIVA") .Or. _lExec
						If !(AllTrim(SA1->A1_I_NUM) $ SA1->A1_END)
							RecLock("SA1", .F.)
							If !Empty(SA1->A1_I_END) .And. Empty(SA1->A1_I_NUM) .And. Empty(SA1->A1_COMPLEM)
								SA1->A1_END := AllTrim(SA1->A1_I_END)
							ElseIf !Empty(SA1->A1_I_END) .And. !Empty(SA1->A1_I_NUM) .And. Empty(SA1->A1_COMPLEM)
								SA1->A1_END := AllTrim(SA1->A1_I_END) + ", " + AllTrim(SA1->A1_I_NUM)
							ElseIf !Empty(SA1->A1_I_END) .And. !Empty(SA1->A1_I_NUM) .And. !Empty(SA1->A1_COMPLEM)
								SA1->A1_END := AllTrim(SA1->A1_I_END) + ", " + AllTrim(SA1->A1_I_NUM) + " " + AllTrim(SA1->A1_COMPLEM)
							EndIf
						EndIf
						SA1->A1_I_DTEXE := dDataBase
						SA1->(MSUnLock())
					EndIf
				EndIf
			EndIf
		EndIf
		U_AOMS076G()
	EndIf
End Sequence

If !Empty(SA1->A1_INSCR)
	RecLock("SA1", .F.)
	SA1->A1_INSCR := AllTrim(StrTran(SA1->A1_INSCR,"-",""))
	MSUnLock()
EndIf

If _lAltCodTab 
    SA1->(RecLock("SA1", .F.))
	SA1->A1_TABELA := "" // Cliente alterado simples nacional = NÃO, deve limpar o codigo da tabela de preços simples nacional.
	SA1->(MSUnLock())

   _lAltCodTab := .F.
EndIf 

//=======================================================================
// Verifica se as validações da rotina de desconto contratual se 
// deve bloquear o Cliente. Caso afirmativo bloqueia o cliente por 
// Desconto Contratual.
//=======================================================================
_aBloqSA1 := U_MA30RETA()
If ValType(_aBloqSA1) == "A" .And. Len(_aBloqSA1) > 0 .And. ValType(_aBloqSA1[1]) == "L" .And. _aBloqSA1[1] // Bloqueia SA1 por Desconto Contratual = True or False
   SA1->(RecLock("SA1",.F.))
   //SA1->A1_MSBLQL  := "1" // Bloqueio por Cliente
   SA1->A1_I_BLQDC := "1"
   SA1->(MSUnLock())
   
   //==================================================================
   // Envia Workflow de bloqueio de clientes por desconto contratual.
   //==================================================================
   U_M30PALWF()

EndIf

//Substituição de caracteres de Campos
SA1->(RecLock("SA1", .F.))

_cA1_NOME := SA1->A1_NOME
If !Empty(AllTrim(M->A1_NOME))
	_lRet := U_CRMA980VCP(@_cA1_NOME   ,"A1_NOME")
	SA1->A1_NOME := _cA1_NOME
EndIf

_cA1_END := SA1->A1_END
If _lRet .And. !Empty(AllTrim(_cA1_END))
	_lRet := U_CRMA980VCP(@_cA1_END    ,"A1_END")
	SA1->A1_END := _cA1_END
EndIf

_cA1_BAIRRO := SA1->A1_BAIRRO
If _lRet .And. !Empty(AllTrim(_cA1_BAIRRO))
	_lRet := U_CRMA980VCP(@_cA1_BAIRRO ,"A1_BAIRRO")
	SA1->A1_BAIRRO := _cA1_BAIRRO
EndIf

_cA1_ENDCOB := M->A1_ENDCOB
If _lRet .And. !Empty(AllTrim(_cA1_ENDCOB))
	_lRet := U_CRMA980VCP(@_cA1_ENDCOB ,"A1_ENDCOB")
	SA1->A1_ENDCOB := _cA1_ENDCOB
EndIf

_cA1_ENDREC := M->A1_ENDREC
If _lRet .And. !Empty(AllTrim(_cA1_ENDREC))
	_lRet := U_CRMA980VCP(@_cA1_ENDREC ,"A1_ENDREC")
	SA1->A1_ENDREC := _cA1_ENDREC
EndIf

_cA1_ENDENT := M->A1_ENDENT
If _lRet .And. !Empty(AllTrim(_cA1_ENDENT))
	_lRet := U_CRMA980VCP(@_cA1_ENDENT,"A1_ENDENT")
	SA1->A1_ENDENT := _cA1_ENDENT
EndIf

_cA1_BAIRROE := M->A1_BAIRROE
If _lRet .And. !Empty(AllTrim(_cA1_BAIRROE))
	_lRet := U_CRMA980VCP(@_cA1_BAIRROE,"A1_BAIRROE")
	SA1->A1_BAIRROE := _cA1_BAIRROE
EndIf

SA1->(MSUnLock())

//=====================================================================
// Para os clientes que não são dos estados "AM-RR-AP" gravar os campos
// suframa com: A1_CALCSUF = "N" e A1_SUFRAMA = " ".
//=====================================================================
If ! (SA1->A1_EST $ "AM-RR-AP-AC-RO")
   SA1->(RecLock("SA1",.F.))
   SA1->A1_CALCSUF := "N"
   SA1->A1_SUFRAMA := " "
   SA1->(MSUnLock())
EndIf

//=====================================================================
// Para os clientes que são funcionários, gravar tipo e seguimento
// como consumidor final.
//=====================================================================
If SA1->A1_CLIFUN == "1"
   SA1->(RecLock("SA1",.F.))
   SA1->A1_TIPO    := "F"  //  Tipo = Consumidor Final
   SA1->A1_I_GRCLI := "39" //  Seguimento = Consumidor Final   
   SA1->(MSUnLock())   
EndIf 

//=====================================================================
// Para os clientes do Paraná optantes pelo Simples Nacional grava
// grava o campo Grupo Tributário com "023", para obterem benefícios.
//=====================================================================
If SA1->A1_EST $ _cUfMVA .And. SA1->A1_SIMPNAC == "1" // 1=Sim;2=Não
   SA1->(RecLock("SA1",.F.))
   SA1->A1_GRPTRIB := _cTRIBMVA //"023" //  Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
   SA1->(MSUnLock())
Else 
   If AllTrim(SA1->A1_GRPTRIB) == AllTrim(_cTRIBMVA)
	  SA1->(RecLock("SA1",.F.))
      SA1->A1_GRPTRIB := " "
	  SA1->(MSUnLock())
   EndIf	
EndIf 

FWRestArea(_aArea)

Return(_lRet)   


/*
===============================================================================================================================
Programa----------: M30PALTAB
Autor-------------: Julio de Paula Paz 
Data da Criacao---: 12/03/2021
===============================================================================================================================
Descrição---------: Determina se o campo A1_TABELA será alterado após a gravação.
===============================================================================================================================
Parametros--------: _lAltTabela = .T./.F.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M30PALTAB(_lAltTabela)

Begin Sequence
   If _lAltTabela 
      _lAltCodTab := .T.
   Else
      _lAltCodTab := .F.
   EndIf 
End Sequence

Return 

/*
===============================================================================================================================
Programa----------: M30PALWF()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 20/12/2021
===============================================================================================================================
Descrição---------: Rotina de envio de e-mail WorkFlow notificando a bloqueio do cliente por desconto contratual. 
                    Chamado 30177.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M30PALWF()
Local _aConfig	:= U_ITCFGEML('')
Local _cMsgEml	:= ''
Local _cAssunto := "WORKFLOW - CLIENTE BLOQUEADO PARA AVALIAÇÃO DE REGRA DE DESCONTO CONTRATUAL"
Local _cEmail1	:= AllTrim(U_ITGETMV("IT_EMALCL1","sistema@italac.com.br"))
Local _cEmail2	:= AllTrim(U_ITGETMV("IT_EMALCL2","sistema@italac.com.br"))
Local _cEmailEnv, _cEmlLog := "" 

If Empty(_cEmail1) .And. Empty(_cEmail2)
   Return 
EndIf 

_cEmailEnv := AllTrim(_cEmail1) + ";" + AllTrim(_cEmail2)

_cMsgEml := '<html>'
_cMsgEml += '<head><title>' + _cAssunto + '</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
_cMsgEml += 'td.AZUL    { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #0000FF; }'
_cMsgEml += 'td.amarelo { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFF00; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '	<td class="titulos"><center>Log de Processamento</center></td>'
_cMsgEml += '	</tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos" width="100%"><b>' + _cAssunto + '</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="20%"><b>Cliente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="80%">' + SA1->A1_COD +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Loja:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + SA1->A1_LOJA +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Nome:</b></td>'
_cMsgEml += '      <td class="itens" align="left width="65%">' + SA1->A1_NOME +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Rede:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + SA1->A1_GRPVEN+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Descrição Rede:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + AllTrim(Posicione("ACY",1,xFilial("ACY")+SA1->A1_GRPVEN,"ACY_DESCRI" ))+'</td>'
_cMsgEml += '    </tr>'
//_cMsgEml += '    <tr>'
//_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Usuario:</b></td>'
//_cMsgEml += '      <td class="itens" align="left" >' + __cUserId +'</td>'
//_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Usuario Alterador:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + UsrFullName (__cUserId)  +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Data da Alteração:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + DToC(Date()) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="left" width="35%"><b>Hora da Alteração:</b></td>'
_cMsgEml += '      <td class="itens" align="left" width="65%">' + Time() + '</td>'
_cMsgEml += '    </tr>'
_cMsgEml += ' <tr>'
_cMsgEml += '   <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
_cMsgEml += ' </tr>'
_cMsgEml += '</table>'

_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1300">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="grupos" align="center" width=10%"><b>Descrição</b></td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '     <td class="itens" align="left" width="10%">'
//_cMsgEml += '     Este cliente foi bloqueado pois em seus cadastro foi informado um grupo de vendas para qual já existe um contrato de desconto preexistente.'
//_cMsgEml += '     O desbloqueio do cadastro será realizado pela equipe de manutenção dos cadastros de descontos contratuais. </td>'
_cMsgEml += '     Este cliente foi bloqueado pois foi informado em seu cadastro um grupo de vendas que possui um desconto contratual de uso restrito. '
_cMsgEml += '     A avaliação deste cadastro e o seu desbloqueio será realizada pela equipe que faz a gestão dos contratos de descontos! </td> '
_cMsgEml += '</table>'

U_ITConOut('Enviando E-mail(s) para: '+_cEmailEnv+ " - Log de Processamento - Cliente Bloqueado - "+TIME()+" - [ M30PALWF]")

//    ITEnvMail(cFrom     ,cEmailTo ,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
U_ITENVMAIL( _aConfig[01] , _cEmailEnv ,"",         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

Return .T.





