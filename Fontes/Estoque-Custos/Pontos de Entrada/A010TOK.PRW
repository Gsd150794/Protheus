/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
Lucas Borges  |17/09/2025| Chamado 50617. Corrigido error.log na exclusão.
==============================================================================================================================================================
*/

// USE ESSE PONTO PARA VALIDAÇÕES E O AEST045.PRW PARA GRAVAÇÕES
#Include "TOTVS.ch"
#Include "TBICONN.CH"  

/*
===============================================================================================================================
Programa----------: A010TOK
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 20/04/2010
Descrição---------: Ponto de Entrada que valida a inclusao e alteracao de produtos (Fonte: MATA010.PRX) 
                    Chamada do antigo A010TudoOk() do Fonte: MATA010.PRX
                    USE ESSE PONTO PARA VALIDAÇÕES E O AEST045.PRW PARA GRAVAÇÕES
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar lancamento
------------------: .F. = Nao Permite confirmar lancamento 
===============================================================================================================================
*/
User Function A010TOK()

Local _lExecuta   := .T.
Local _nCont
Local _oModel     := FWModelActive()
Local _oModelSB1  := _oModel:GetModel('SB1MASTER')
Local _cB1_DESC   := ""
Local _cB1_I_DESCD:= ""
Local _lFasesB1   := SuperGetMV("IT_FASESB1",.F.,.F.)
Local _cIT_PRDSVOK:= SUPERGETMV("IT_PRDSVOK",.F.,"")

// Valida digitação de caracteres invalidos
If Inclui .Or. Altera
	_cB1_DESC := _oModelSB1:GetValue('B1_DESC') 
	If !Empty(AllTrim(_cB1_DESC))
		_lExecuta := U_CRMA980VCP(@_cB1_DESC   ,"B1_DESC")
		_oModelSB1:LoadValue('B1_DESC',_cB1_DESC)  
	EndIf
	
	_cB1_I_DESCD := _oModelSB1:GetValue('B1_I_DESCD') 
	If _lExecuta .And. !Empty(AllTrim(_cB1_I_DESCD))
		_lExecuta := U_CRMA980VCP(@_cB1_I_DESCD   ,"B1_I_DESCD")
		_oModelSB1:LoadValue('B1_I_DESCD',_cB1_I_DESCD)  
	EndIf
EndIf

// Valida digitação da segunda unidade de medida do produto se não For grupo de exceção de medida
If (! Empty(M->B1_SEGUM) .And. Empty(M->B1_CONV) .And. !(M->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006") )) .OR.;
	( Empty(M->B1_SEGUM) .And. ! Empty(M->B1_CONV) .And. !(M->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006") ))
	Help(NIL, NIL, "A010TOK01", NIL, "Fator de conversão não preenchido para a segunda unidade de medida.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			 {"Favor preencher o fator de conversão. Ao informar a segunda unidade de medida, o fator de conversão precisa ser preenchido."})
   _lExecuta := .F.
EndIf

// Valida digitação da segunda unidade de medida do produto se não For grupo de exceção de medida
If !Inclui .And. _lExecuta
	If  Empty(SB1->B1_I_NIV5) .And.  Empty(M->B1_I_NIV5)//NÃO MEXEU E NÃO TEM N5
		If AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)== AllTrim(M->B1_DESC) .OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4)  .AND.;
			(!AllTrim(SB1->B1_DESC) == AllTrim(M->B1_DESC) .Or. !AllTrim(SB1->B1_I_DESCD) == AllTrim(M->B1_I_DESCD) )
			Help(NIL, NIL, "A010TOK02", NIL, "Descrições não pode ser alteradas quando o produto possui niveis preenchidos ate o nivel 4.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Favor contactar o depto de custos, resposavel pelo cadastro de niveis."})
			_lExecuta := .F.
		EndIf
	ElseIf  Empty(SB1->B1_I_NIV5) .And. !Empty(M->B1_I_NIV5)//COLOCOU  N5
	    cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)
		
		If (cCerto == AllTrim(M->B1_DESC) .And. cCerto == AllTrim(M->B1_I_DESCD)).OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5)
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições deve coincidir com a soma das descriçoes de todos os niveis.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Soma das descrições dos niveis: "+cCerto})
			_lExecuta := .F.
		EndIf
	ElseIf !Empty(SB1->B1_I_NIV5) .And.  Empty(M->B1_I_NIV5)//TIROU  N5
        cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)
        cCerto:=AllTrim(cCerto)
		If (cCerto == AllTrim(M->B1_DESC) .And. cCerto == AllTrim(M->B1_I_DESCD)).OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5) // .AND.;
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições deve coincidir com a soma das descriçoes de todos os niveis.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Soma das descrições dos niveis: "+cCerto})
			_lExecuta := .F.
		EndIf
	ElseIf !Empty(SB1->B1_I_NIV5) .And. !Empty(M->B1_I_NIV5) .And.  M->B1_I_NIV5 = SB1->B1_I_NIV5//NÃO MEXEU E TEM OU NÃO TROCOU N5
        cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)

		If (cCerto == AllTrim(M->B1_DESC) .And. cCerto == AllTrim(M->B1_I_DESCD)).OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5)  .AND.;
			(!AllTrim(SB1->B1_DESC) == AllTrim(M->B1_DESC) .Or. !AllTrim(SB1->B1_I_DESCD) == AllTrim(M->B1_I_DESCD) )
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições não pode ser alteradas quando o produto possui niveis preenchidos ate o nivel 4", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Favor contactar o depto de custos, resposavel pelo cadastro de niveis."+cCerto})
			_lExecuta := .F.
		EndIf
	ElseIf !Empty(SB1->B1_I_NIV5) .And. !Empty(M->B1_I_NIV5) .And.  M->B1_I_NIV5 <> SB1->B1_I_NIV5//NÃO MEXEU E TEM OU TROCOU 
        cCerto:=AllTrim(M->B1_I_DESN2)+" "+AllTrim(M->B1_I_DESN3)+" "+AllTrim(M->B1_I_DESN4)+" "+AllTrim(M->B1_I_DESN5)

		If (cCerto == AllTrim(M->B1_DESC) .And. cCerto == AllTrim(M->B1_I_DESCD)) .OR.;
			(M->B1_MSBLQL = '1' .And. "BLOQUEADO" $ M->B1_DESC)
			_lExecuta := .T.
		ElseIf !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4+M->B1_I_NIV5) // .AND.;
			Help(NIL, NIL, "A010TOK03", NIL, "Descrições deve coincidir com a soma das descriçoes de todos os niveis.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Soma das descrições dos niveis: "+cCerto})
			_lExecuta := .F.
		EndIf
	EndIf
ElseIf Inclui .And._lExecuta
	If !Empty(M->B1_I_NIV2+M->B1_I_NIV3+M->B1_I_NIV4)  .And. ;
	   (Empty(M->B1_I_NIV2) .Or. Empty(M->B1_I_NIV3) .Or. Empty(M->B1_I_NIV4))
	   		Help(NIL, NIL, "A010TOK03", NIL, "Todos os Niveis 2 , 3 e 4 devem ser preenchidos quando For PA ou embalagem de PA.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Preencha os niveis ou troque o tipo do produto."})
		_lExecuta := .F.
	EndIf
EndIf

// VALIDA PRODUTO ACABADO. 
If M->B1_TIPO == 'PA'
	If Empty(M->B1_I_SUBGR)
		Help(NIL, NIL, "A010TOK03", NIL, "Quando o tipo do Produto For igual a PA deve-se fornecer o Sub Grupo do Produto", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Favor preencher o campo Sub Grupo do Produto para confirmar o cadastro/alteração do Produto"})
	   _lExecuta := .F.
	EndIf     
   
   // Validação para Código EAN. 
	If Empty(M->B1_CODBAR)
		Help(NIL, NIL, "A010TOK03", NIL, "Quando o tipo do Produto For igual a PA deve-se informar o Código de Barras - EAN", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Favor preencher o campo Cod Barras para confirmar o cadastro/alteração do Produto"})
       _lExecuta := .F.
	EndIf

// VALIDA PRODUTO DE SERVIÇO. 
ElseIf M->B1_TIPO == 'SV' .And. !AllTrim(M->B1_COD) $ _cIT_PRDSVOK
	If !Empty(M->B1_PICM)
		Help(NIL, NIL, "A010TOK03", NIL, "Aliquota de ICMS não pode ser preenchida para um produto de tipo = 'SV'", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Zere Aliquota de ICMS desse produto ou troque o tipo para diferente de 'SV'"})
	   _lExecuta := .F.
	EndIf     
	If !Empty(M->B1_IPI)
		Help(NIL, NIL, "A010TOK03", NIL, "Aliquota de IPI não pode ser preenchida para um produto de tipo = 'SV'", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Zere Aliquota de IPI desse produto ou troque o tipo para diferente de 'SV'"})
	   _lExecuta := .F.
	EndIf     
EndIf
  
//  Inicio da validação realizada no campo B1_DESC afim de não permitir o uso de 
//  espaçamento feitos apartir da tecla tab e a tecla enter.
 	_nCont:= StrTran(M->B1_DESC	,'	',"") 
    
    If _nCont <> M->B1_DESC .Or. LTrim(StrTran(M->B1_DESC	,'	',"")) <> M->B1_DESC
		Help(NIL, NIL, "A010TOK03", NIL, "Erro no preenchimento do campo Descrição", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				 {"Favor retirar os espaços em branco para prosseguir com o cadastro"})
   		_lExecuta := .F. 
    EndIf    

    If Inclui .And. _lExecuta
		SB1->(DBSetOrder(3))
		SB1->(DBSeek( xFilial()+AllTrim(M->B1_DESC) ))
		While SB1->(!Eof()) .And. AllTrim(M->B1_DESC) == AllTrim(SB1->B1_DESC)
			If AllTrim(M->B1_I_DESCD) == AllTrim(SB1->B1_I_DESCD)
				Help(NIL, NIL, "A010TOK03", NIL, "Produto já cadastrado", 1, 0, NIL, NIL, NIL, NIL, NIL,;
					{"Descrição já existente no Produto: "+SB1->B1_COD})
				_lExecuta := .F. 
				Exit
			EndIf
			SB1->(DBSkip())
		EndDo
		SB1->(DBSetOrder(1))
    EndIf    

// Apagar o NCM dos produtos do GRUPO 1000, para todos os itens que forem TIPO SV - Chamado 19481
ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
If _lFasesB1
	_lValida:=!ZZL->ZZL_CADPRD = "1" // Alex: Não retirar esse comentario CHAMADO 31466 Habilitdo por enquanto  .T.//desabilitdo
Else
	_lValida:=.T.
EndIf
If (M->B1_GRUPO $ SuperGetMV("IT_GRUNCM",.F.,"1000") .And. M->B1_TIPO $ SuperGetMV("IT_TIPNCM",.F.,'SV')) .Or. M->B1_TIPO $ SuperGetMV("IT_TIPOPRD",.F.,'IM')
	If _lExecuta .And. !Empty(M->B1_POSIPI) .And. _lValida
		If (M->B1_GRUPO $ SuperGetMV("IT_GRUNCM",.F.,"1000") .And. M->B1_TIPO $ SuperGetMV("IT_TIPNCM",.F.,'SV')) 
			Help(NIL, NIL, "A010TOK03", NIL, "O produto pertence ao(s) grupo(s) "+AllTrim(SuperGetMV("IT_GRUNCM",.F.,"1000"))+" e ao(s) tipo(s) "+AllTrim(SuperGetMV("IT_TIPNCM",.F.,'SV'))+". ", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Portanto o conteúdo do campo NCM será removido."})
		Else
			Help(NIL, NIL, "A010TOK03", NIL, "O produto pertence ao(s) tipo(s) "+AllTrim(SuperGetMV("IT_TIPOPRD",.F.,'IM'))+". ", 1, 0, NIL, NIL, NIL, NIL, NIL,;
				{"Portanto o conteúdo do campo NCM será removido."})
		EndIf   
		_oModelSB1:LoadValue('B1_POSIPI', "          ")
	EndIf
ElseIf Empty(M->B1_POSIPI) .And. _lValida
	Help(NIL, NIL, "A010TOK03", NIL, "O campo da NCM não esta preenchido.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Favor preencher o campo da NCM na pasta Impostos (segunda pasta)"})
	_lExecuta := .F. 
EndIf

// Valida preenchimento Motivo do bloqueio 
If M->B1_MSBLQL == '1' .And. Empty(M->B1_I_MOTBL)
	_lExecuta := .F.
	Help(NIL, NIL, "A010TOK03", NIL, 'Campo Motivo Bloqueio vazio!', 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Para produtos bloqueados favor preencher o motivo do bloqueio."})
ElseIf M->B1_MSBLQL <> '1'
   M->B1_I_MOTBL:=Space(Len(SB1->B1_I_MOTBL))
   _oModelSB1:LoadValue('B1_I_MOTBL',Space(Len(SB1->B1_I_MOTBL)))
EndIf	

// Se For inclusão de PA, envia Workflow para sistema@italac.com.br
// Alex: Não retirar esse comentario CHAMADO 31466 desabilitdo por enquanto
If _lFasesB1
	If _lExecuta .And. (Inclui .Or. "#CONTROLE" $ SB1->B1_I_MOTBL)
		_lExecuta:=A010WlInc(_oModelSB1)
	EndIf
EndIf
// Se For inclusão de PA, envia Workflow para sistema@italac.com.br

If _lExecuta .And. !Inclui .And. (SB1->B1_UM <> M->B1_UM .Or. SB1->B1_SEGUM <> M->B1_SEGUM .Or. SB1->B1_CONV <> M->B1_CONV .Or. SB1->B1_TIPCONV <> M->B1_TIPCONV)
   If !(ISINCALLSTACK("MDIEXECUTE") .Or. ISINCALLSTACK("SIGAADV"))
	  _lExecuta := A010CadSB1()
   Else
      FWMsgRun( ,{|oProc| _lExecuta := A010CadSB1(oProc) } , "Processando..." , "Validando Armazem..." )
   EndIf
EndIf
// Se For inclusão de PA, envia Workflow para sistema@italac.com.br
If _lExecuta .And. Inclui
	WorkFlow()
EndIf

If _lExecuta .And. !Inclui .And. !FWIsInCallStack("MSEXECAUTO")
   M->B1_I_USRNA:=Capital(RTrim(UsrFullName(RetCodUsr())))
   M->B1_I_USRDA:=DToC(Date())
   _oModelSB1:LoadValue('B1_I_USRNA' ,M->B1_I_USRNA)
   _oModelSB1:LoadValue('B1_I_USRDA' ,M->B1_I_USRDA)
EndIf

//USE ESSE PONTO PARA VALIDAÇÕES E O AEST045.PRW

Return (_lExecuta)

/*
===============================================================================================================================
Programa----------: Workflow
Autor-------------: Lucas Crevilari
Data da Criacao---: 12/09/2014
Descrição---------: Envio de Workflow quando For realizado cadastro de PA. Chamado 7363
Parametros--------: Nenhum	
Retorno-----------: Nenhum
===============================================================================================================================
*/   
Static Function Workflow()

Local _cEmail := Space(0)
Local _cErrorMsg, _Remetente, _cHtml, _cSubject
Local _lResult, _cTitulo, _cTexto2, _cAlias

CONNECT SMTP ;
SERVER GetMV("MV_RElseRV") ; 	// Nome do servidor de e-mail
ACCOUNT GetMV("MV_RELACNT") ; 	// Nome da conta a ser usada no e-mail
PASSWORD GetMV("MV_RELPSW") ; 	// Senha
RESULT _lResult 					// Resultado da tentativa de conexão

If !_lResult
	// Nao foi possivel estabelecer conexao com o servidor 
	Help(NIL, NIL, "A010TOK03", NIL, "Falha no envio do email", 1, 0, NIL, NIL, NIL, NIL, NIL,{MailGetErr()})
EndIf

If _lResult 
    
	// Conectado ao Servidor, enviando o e-mail... 
	MailAuth(GetMV("MV_RELACNT"),GetMV("MV_RELPSW"))
	_Remetente := GetMV("MV_RELACNT")

	If M->B1_TIPO == "PA"
		_cSubject := "Novo Cadastro de Produto Acabado" 
	Else
		_cSubject := "Novo Cadastro de Produto"
	EndIf	 		

	_cHtml := Space(0)
	_cHtml += '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.01 Transitional//EN""http://www.w3.org/TR/html4/loose.dtd">'
	_cHtml += '<html>'
	_cHtml += '<head>'
	_cHtml += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"><title>Untitled Document</title>'
	_cHtml += '<style Type="text/css">'
	_cHtml += '<!--body,td,th { font-family: Arial, Helvetica, sans-serif; font-size: 12px;}.negrito { font-family: Arial, Helvetica, sans-serif; font-size: 12px; font-weight: bold; color: #003366;}.negrito2 { font-family: Arial, Helvetica, sans-serif; font-size: 15px; font-weight: bold; color: #003366;}.texto1 { font-family: Arial, Helvetica, sans-serif; font-size: 11px; color: #666666;}.texto2 { font-family: Arial, Helvetica, sans-serif; font-size: 9px; color: #666666;}-->'
	_cHtml += '</style>'
	_cHtml += '</head>'
	_cHtml += '<body>'                                                         
	_cHtml += '<p class=MsoNormal>'
    _cHtml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'

	If M->B1_TIPO == "PA"
		_cTitulo := "Novo Cadastro de Produto Acabado"
		_cTexto2 := "Novo Produto Acabado cadastrado no Protheus:"		
	Else	
		_cTitulo := "Novo Cadastro de Produto"
		_cTexto2 := "Novo Produto cadastrado no Protheus:"		
	EndIf	
    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	   _cTitulo += " - TESTE"
    EndIf

	_cHtml += '<table width="996" height="39"> <tr> <td align="center"><span class="negrito2" align="center">'+_cTitulo+'</span><br>'
	_cHtml += '<br> </td> </tr> </table>'
	_cHtml += '<p><span class="negrito">Prezados, </span>'
	_cHtml += '<br><span class="negrito">'+_cTexto2+'</span><span class="texto1"></span></br></p>'

	_cHtml += '<p><span class="negrito">Codigo: </span>'+M->B1_COD
	_cHtml += '<br><span class="negrito">Descricao: </span></br>'+M->B1_DESC+'</p>'
	
	_cHtml += '<p><span class="negrito">Usuário que realizou cadastro: </span>'+AllTrim(RetCodUsr())+" - "+AllTrim(UsrFullName(RetCodUsr()))
	_cHtml += '<br><span class="negrito">Data de Cadastro: </span></br>'+DToC(dDataBase)+" as "+TIME()+'</p>'
	_cHtml += '<table width="500" border="0" cellpadding="0" cellspacing="8"> <tr> <td width="167"><P class=MsoNormal> <span class="texto2" align="center"></span></p>'//</body></html>'

	_cHtml += '<br>'
	_cHtml += '<br>'
	_cHtml += '<br>'

	_cHtml += '<p><span class="negrito">Ambiente: </span></br> ['+ GETENVSERVER() +']'
	_cHtml += '   <span class="negrito"> / Fonte:    </span></br> [A010TOK] </p>'
	_cHtml += '</body>'
	_cHtml += '</html>'	
	
	// Selecionar os e-mail's dos usuarios que sera enviado o resumo do HTML
	If M->B1_TIPO == "PA"
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT ZZL_EMAIL
			FROM %Table:ZZL%
			WHERE	D_E_L_E_T_ = ' '
			AND		ZZL_ENVWFP = 'S'
		EndSql
	Else				
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT ZZL_EMAIL
			FROM %Table:ZZL%
			WHERE	D_E_L_E_T_ = ' '
			AND		ZZL_ENVWPT = 'S'
		EndSql	
	EndIf	

	// Deve existir no minimo um e-mail para a rotina processar a montagem e envio do arquivo
	If (_cAlias)->( !Eof() )
		While (_cAlias)->( !Eof() )
			_cEmail += ";"+ AllTrim( (_cAlias)->ZZL_EMAIL )
		(_cAlias)->(DBSkip() )
		EndDo
		_cEmail := SubStr( _cEmail , 2 , Len( _cEmail ) )
	EndIf

    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
	   _cEmlLog := "Rotina executada em Ambiente de Testes: ["+ GetEnvServer() +"]. Não será processado o envio de e-mail!"
            //  _cMens                                                                 ,_ctitu           ,_csolu,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		Help(NIL, NIL, "A010TOK03", NIL, Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+_cEmail+CHR(13)+CHR(10), 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
	   Return
    EndIf
	
	Send mail ; 		    // envia e-mail
	from _Remetente ; 	 // de
	To _cEmail ; 		    // para
	subject _cSubject ;  // assunto
	body _cHtml ;			// mensagem em HTML
	RESULT _lResult 
					
	If !_lResult 
	   GET MAIL ERROR _cErrorMsg
	   cLogErro := "Falha de Envio: "+ AllTrim(_cErrorMsg)
	Else
	   cLogErro := "Sucesso: e-mail enviado corretamente!"
    EndIf

   DISCONNECT SMTP SERVER

    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
		Help(NIL, NIL, "A010TOK03", NIL, Upper(cLogErro)+CHR(13)+CHR(10)+"E-mail para: "+_cEmail+CHR(13)+CHR(10), 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
    EndIf
EndIf 

Return

/*
===============================================================================================================================
Programa----------: A010CadSB1()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/11/2019
Descrição---------: Rotina para zerar a 1o Quantidade e da 2o Quantidade 
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A010CadSB1(oProc)

Local _cObs     := "MOVIMENTO GERADO PELA ALTERACAO DE U.M. (A010TOK)"
Local _cArmaz   := ""
Local _cCod     := SB1->B1_COD 
Local _lEfetivar:=.T.
Local _cAlias   := GetNextAlias()
Local aExecAuto :={}    , A
Local _aLog     :={}
Local _lRet     := .T.
Local _cQuery   := " SELECT "

BeginSql alias _cAlias
	SELECT NNR_CODIGO CODIGO, NNR_DESCRI DESCRICAO
	FROM %Table:NNR%
	WHERE D_E_L_E_T_ = ' '
EndSql

COUNT To _nRegSB1

_cTot   :=AllTrim(Str(_nRegSB1))
_nTam   :=Len(_cTot)+1
_nConta :=0		
_aLogTOK:={}

SB2->( DBSetOrder(1) )
ZZM->( DBSetOrder(1) )
ZZM->( DBGoTop() )
While ZZM->( !Eof() )
	_nConta:=0
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
		_cArmaz := (_cAlias)->CODIGO
		_nConta++
		If oProc <> NIL
	        oProc:cCaption := ("Analisando Filial ["+ZZM->ZZM_CODIGO+"] / Armazem:  ["+_cArmaz+"], "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
			ProcessMessages()
		EndIf
		
		If SB2->( DBSeek( ZZM->ZZM_CODIGO+ _cCod + _cArmaz ) )
			_nQatu   := SB2->B2_QATU
			_nQatu2N := SB2->B2_QTSEGUM
			_nVatu1  := SB2->B2_VATU1
			If SB1->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006")
				lTemSegUM:= _nQatu2N > 0 
            Else
				lTemSegUM:= (SB1->B1_CONV > 0 .And. _nQatu2N > 0) .Or. (SB1->B1_CONV = 0 .And. _nQatu2N = 0)
			EndIf
		   
			If _nQatu > 0 .And. _nVatu1 > 0 .And. lTemSegUM
				aAdd(aExecAuto,{_cArmaz,(_cAlias)->DESCRICAO,ZZM->ZZM_CODIGO,ZZM->ZZM_DESCRI})
			ElseIf _nQatu > 0 .And. _nVatu1 = 0 .And. lTemSegUM
				aAdd(aExecAuto,{_cArmaz,(_cAlias)->DESCRICAO,ZZM->ZZM_CODIGO,ZZM->ZZM_DESCRI})
			ElseIf !(_nQatu = 0 .And. _nVatu1 = 0 .And. _nQatu2N = 0)
				aAdd( _aLog ,{.F.,_cArmaz,(_cAlias)->DESCRICAO,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"Armazem com quantidades / valores incorretos",ZZM->ZZM_CODIGO+" - "+ZZM->ZZM_DESCRI} )
				_lRet:= .F.
			ElseIf _nQatu = 0 .And. _nVatu1 = 0 .And. _nQatu2N = 0
				aAdd( _aLogTOK ,{.T.,_cArmaz,(_cAlias)->DESCRICAO,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"INVENTARIAR URGENTE",ZZM->ZZM_CODIGO+" - "+ZZM->ZZM_DESCRI} )
			EndIf
		EndIf
		(_cAlias)->(DBSkip())
	EndDo
	ZZM->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

_cTot:=AllTrim(Str(Len(aExecAuto)))
_nTam:=Len(_cTot)
_nConta:=0		

_cQuery := "SELECT MAX(D3_DOC) AS MAXD3DOC "
_cQuery += " FROM " + RetSqlName("SD3") + " D3"
_cQuery += " WHERE D3.D_E_L_E_T_ = ' ' "
_cQuery += " AND SubStr( D3.D3_DOC , 1 , 1 ) IN ('0','1','2','3','4','5','6','7','8','9') "

SB2->( DBSetOrder(1) )

Begin Sequence

For A :=  1 To Len(aExecAuto)
	_cArmaz := aExecAuto[A,1]
	_cDArmaz:= aExecAuto[A,2]
	_cFilial:= aExecAuto[A,3]
	_cFilDes:= aExecAuto[A,4]

	_nConta++
    If oProc <> NIL
	   oProc:cCaption := ("Zerando Filial ["+_cFilial+"] / Armazem:  ["+_cArmaz+"], "+AllTrim(StrZero(_nConta,_nTam)) +" de "+ _cTot)
	   ProcessMessages()
	EndIf   
	
	If SB2->( DBSeek( _cFilial + _cCod + _cArmaz ) )
		_nQatu   := SB2->B2_QATU
		_nQatu2N := SB2->B2_QTSEGUM
		_nVatu1  := SB2->B2_VATU1
        
		If SB1->B1_GRUPO $ SuperGetMV("IT_GR2N",.F.,"0006")
		   lTemSegUM:= _nQatu2N > 0 
        Else
		   lTemSegUM:=(SB1->B1_CONV > 0 .And. _nQatu2N > 0) .Or. (SB1->B1_CONV = 0 .And. _nQatu2N = 0)
		EndIf   

	    If !_lRet
	       aAdd( _aLog ,{.F.,_cArmaz,_cDArmaz,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"Armazem não foi zerado, pois existem outros armazens incorretos",_cFilial+" - "+_cFilDes} )
           Loop
	    EndIf

	    _cD3_DOC:= ""
	    _cQueryF:= " AND D3.D3_FILIAL = '" + _cFilial + "'"
		DBUSEAREA(.T.,"TOPCONN", TcGenQry(,,(_cQuery+_cQueryF)), "SD3T", .T., .F. )
		If SD3T->( !Eof() )
			_cD3_DOC:=Soma1(SD3T->MAXD3DOC)
		EndIf
		SD3T->( DBCloseArea() )        

		_aSD31 := {}
        _aCab1 := {}
        _aToSD31 := {}

		If _nQatu > 0 .And. _nVatu1 > 0 .And. lTemSegUM
			_aCab1 := {	{ "D3_FILIAL"	, _cFilial			, Nil },;
			            { "D3_TM"		, "997"				, NIL },;//SAIDA
                        { "D3_CC"       ,"        "         , NIL },;
			            { "D3_DOC"		, _cD3_DOC			, NIL },;
			            { "D3_EMISSAO"	, dDataBase			, NIL } }			

			_aSD31 := {	{ "D3_COD"		, _cCod				, NIL },;
			            { "D3_LOCAL"	, _cArmaz			, NIL },;
			            { "D3_QUANT"	, _nQatu    		, NIL },;//TIRAR
			            { "D3_CUSTO1"	, _nVatu1			, NIL },;//TIRAR
		            	{ "D3_CUSTO3"	, _nVatu1			, NIL },;//TIRAR
		            	{ "D3_QTSEGUM"	, _nQatu2N			, NIL },;//TIRAR
			            { "D3_I_OBS"    , _cObs				, NIL } }
			
		ElseIf _nQatu > 0 .And. _nVatu1 = 0 .And. lTemSegUM
			_aCab1 := {	{ "D3_FILIAL"	, _cFilial			, Nil },;
			            { "D3_TM"		, "998"				, NIL },;//SAIDA
                        { "D3_CC"       ,"        "         , NIL },;
		            	{ "D3_DOC"		, _cD3_DOC			, NIL },;
			            { "D3_EMISSAO"	, dDataBase			, NIL } }			

			_aSD31 := {	{ "D3_COD"		, _cCod				, NIL },;
			            { "D3_LOCAL"	, _cArmaz			, NIL },;
		            	{ "D3_QUANT"	, _nQatu    		, NIL },;//TIRAR
		            	{ "D3_CUSTO1"	, 0  				, NIL },;
			            { "D3_CUSTO3"	, 0					, NIL },;
			            { "D3_QTSEGUM"	, _nQatu2N			, NIL },;//TIRAR
			            { "D3_I_OBS"    , _cObs				, NIL } }
		EndIf
		
        aAdd(_aToSD31,_aSD31)

		BEGIN TRANSACTION
		
		lMsErroAuto := .F.
		
		If _lEfetivar .And. Len(_aSD31) > 0
			cFilOld:=cFilAnt
			cFilAnt:=_cFilial
            MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab1 , _aToSD31 , 3 ) //Inclusao
			cFilAnt:=cFilOld
		EndIf
		
		If lMsErroAuto
			//_cErro:="MSExecAuto: [ "+MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MEST015.LOG")+" ]" 
			_cErro := "MSExecAuto: [ Este armazém não foi zerado, verifique empenhos e reservas e remova-os antes de alterar o produto. ]" 
			
			aAdd( _aLog ,{.F.,_cArmaz,_cDArmaz,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,_cErro,_cFilial+" - "+_cFilDes} )
		    _lRet:= .F.
			
			DisarmTransaction()
		ElseIf Len(_aSD31) > 0
			aAdd( _aLog ,{.T.,_cArmaz,_cDArmaz,_nQatu,_nQatu2N,_nVatu1,SB1->B1_CONV,"Armazem com quantidades/valores zerado com sucesso",_cFilial+" - "+_cFilDes} )
		EndIf
		
		END TRANSACTION
	EndIf
Next

End Sequence  

_lTudoZerado:=.F.
If Len(_aLog) = 0 .And. Len(_aLogTOK) > 0
   _lTudoZerado:=.T.
   _aLog:=_aLogTOK
EndIf

_aLogAux:=aClone(_aLog)
_aLog:={}
For A :=  1 To Len(_aLogAux)
	aAdd( _aLog ,{_aLogAux[A,1],;
	              _aLogAux[A,9],;
	              _aLogAux[A,2],;
	              (Transform(_aLogAux[A,4],PesqPict("SB2","B2_QATU   "))),;
	              (Transform(_aLogAux[A,5],PesqPict("SB2","B2_QTSEGUM"))),;
	              (Transform(_aLogAux[A,6],PesqPict("SB2","B2_VATU1  "))),;
	              (Transform(_aLogAux[A,7],PesqPict("SB1","B1_CONV   "))),;
	              _aLogAux[A,8]} )
Next A

aSort(_aLog,,,{|X,Y| (X[2]+X[3]) < (Y[2]+Y[3]) })//ORDEM DE FILIAL + ARMAZEM

A010Log(_aLog,oProc,_lRet)

Return _lRet

/*
===============================================================================================================================
Programa----------: A010Log()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/11/2019
Descrição---------: Rotina para zerar a 1o Quantidade e da 2o Quantidade 
Parametros--------: _aLog,oProc,_lRet
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A010Log(_aLog,oProc,_lRet)

Local _aCab:={}
Local _aSize:={}

If Len(_aLog) > 0
	//Monta aheader
	aAdd(_aCab,"")//01
	aAdd(_aSize,5)
	aAdd(_aCab,"Filial")//02
	aAdd(_aSize,90)
	aAdd(_aCab,"Armazem")//03
	aAdd(_aSize,5)
	aAdd(_aCab,"Qtde.1a.UM")//04
	aAdd(_aSize,45)
	aAdd(_aCab,"Qtde.2a.UM")//05
	aAdd(_aSize,45)
	aAdd(_aCab,"Vlr.Tot.Atual")//06
	aAdd(_aSize,45)
	aAdd(_aCab,"Fator.Conv.")//07
	aAdd(_aSize,45)
	aAdd(_aCab,"Resultado")//08
	aAdd(_aSize,150)

    nPosResu:=Len(_aCab)//Posiçao do "Resultado"
    A010Email(_aLog,_aCab,oProc,_lRet)

    aBotoes:={}                                           
    aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
    aAdd( aBotoes , { "" , {|| A010Email(_aLog,_aCab,oProc,_lRet) }	, "" , "Re-Envio de e-mail"		  } )
//          ITListBox(_cTitAux              , _aHeader , _aCols  , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
   _lRet:=U_ITLISTBOX("Armazens Processados", _aCab    , _aLog   , .T.      , 4      ,          ,          , _aSize  ,         ,     ,        , aBotoes)
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: A010Email()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/11/2019
Descrição---------: Monta e envia email 
Parametros--------: _aTLinhas,_aCab,oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A010Email(_aTLinhas,_aCab,oProc,_lRet)

Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local _cMsgEml	:= ""
Local _nI , _aSizes:={}
Local cGetCc	:= ""
Local cErMens	:= "Correções necessarias antes de alterar o cadastro"
Local cOKMens	:= "Inventariar o produto nos armazens relacionados"
Local cGetPara	:= "almoxarifados@italac.com.br"
Local _cTot     := AllTrim(Str(Len(_aTLinhas)))
Local _nTam     := Len(_cTot)
Local _cNomeFil := cFilant+" - "+AllTrim( Posicione('SM0',1,"01"+cFilant,'M0_FILIAL') )
Local cTit      := ""
Local cGetAssun := "Alterações do Produto "+AllTrim(SB1->B1_COD)+"-"+AllTrim(M->B1_DESC)+": "

If SB1->B1_UM <> M->B1_UM 
   cTit     +='Alteração da 1a U.M. <b>De: "'+SB1->B1_UM+'" Para: "'+M->B1_UM+'"</b>'+CHR(13)+CHR(10)
   cGetAssun+='1a U.M. De: "'+SB1->B1_UM+'" Para: "'+M->B1_UM+'", '
EndIf
If SB1->B1_SEGUM <> M->B1_SEGUM 
   cTit     +='Alteração da 2a U.M. <b>De: "'+SB1->B1_SEGUM+'" Para: "'+M->B1_SEGUM+'"</b>'+CHR(13)+CHR(10)
   cGetAssun+='2a U.M. De: "'+SB1->B1_SEGUM+'" Para: "'+M->B1_SEGUM+'", '
EndIf
If SB1->B1_TIPCONV <> M->B1_TIPCONV 
   cTit     +='Alteração do Tipo Conversão <b>De: "'+SB1->B1_TIPCONV+'" Para: "'+M->B1_TIPCONV+'"</b>'+CHR(13)+CHR(10)
   cGetAssun+='Tipo Conv. De: "'+SB1->B1_TIPCONV+'" Para: "'+M->B1_TIPCONV+'", '
EndIf
If SB1->B1_CONV <> M->B1_CONV
   cTit     +='Alteração da Conversão <b>De: "'+AllTrim(Str(SB1->B1_CONV,10,2))+'" Para: "'+AllTrim(Str(M->B1_CONV,10,2))+'"</b>'+CHR(13)+CHR(10)
   cGetAssun+='Conversão De: "'+AllTrim(Str(SB1->B1_CONV,10,2))+'" Para: "'+AllTrim(Str(M->B1_CONV,10,2))+'", '
EndIf

cTit     +="PRODUTO: <b>"+AllTrim(SB1->B1_COD)+"-"+AllTrim(M->B1_DESC)+"</b>"
cGetAssun:=LEFT(cGetAssun,Len(cGetAssun)-2)

If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   cGetPara	:= ""
EndIf
If Len(UsrRetGrp(PswChave(RetCodUsr()),RetCodUsr())) # 0 
   cGetCc  := LOWER(AllTrim(UsrRetMail(__cUserId)))+Space(150) // Pega e-mail do usuario
EndIf

If Empty(cGetPara)
   cGetPara:=cGetCc
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
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados da alteração</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Alterado por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Observações:</b></td>'
If _lRet
   _cMsgEml += '      <td class="itens" >'+cOKMens+'</td>'
Else
   _cMsgEml += '      <td class="itens" >'+cErMens+'</td>'
EndIf
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

//          01   02   03   04   05 
_aSizeOK:={"22","05","10","33","30"}
If _lRet
    _cMsgEml += '<br>'
    _cMsgEml += '<table class="bordasimples" width="1300">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td align="center" colspan="'+AllTrim(Str(Len(_aSizeOK)))+'" class="grupos"><b>Produto de Filiais / Armazens para INVENTARIAR URGENTE</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[01]+'%"><b>'+_aCab[02]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizeOK[02]+'%"><b>'+_aCab[03]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[03]+'%"><b>Produto</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[04]+'%"><b>Descrição</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizeOK[05]+'%"><b>'+_aCab[08]+'</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    #LISTAOK#'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'
EndIf

If !_lTudoZerado
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1300">'
	_cMsgEml += '    <tr>'
	//        01    02   03   04   05   06   07
	_aSizes:={"05","05","10","10","18","07","45"}
	If _lRet
		_cMsgEml += ' <td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>Valores e Quantidades de Filiais / Armazens Zerados</b></td>'
	Else
		_cMsgEml += ' <td align="center" colspan="'+AllTrim(Str(Len(_aSizes)))+'" class="grupos"><b>Filiais / Armazens com problemas</b></td>'
	EndIf
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>'+_aCab[02]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCab[03]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[03]+'%"><b>'+_aCab[04]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[04]+'%"><b>'+_aCab[05]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%"><b>'+_aCab[06]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="right"  width="'+_aSizes[06]+'%"><b>'+_aCab[07]+'</b></td>'
	_cMsgEml += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%"><b>'+_aCab[08]+'</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    #LISTA#'
	_cMsgEml += '</table>'
EndIf

_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [A010TOK]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cOKLista:=""
_cGetLista:=""
_lEnvia:=.F.
For _nI := 1 To Len(_aTLinhas)
    If oProc <> NIL
	   oProc:cCaption := ("Enviando Log: "+AllTrim(StrZero(_nI,_nTam))+" de "+ _cTot)
	   ProcessMessages()
	EndIf   
	
	If _lRet
		_cOKLista += '    <tr>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[01]+'%">'+ _aTLinhas[_nI][02]+'</td>'
		_cOKLista += '      <td class="itens" align="center" width="'+_aSizeOK[02]+'%">'+ _aTLinhas[_nI][03]+'</td>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[03]+'%">'+ SB1->B1_COD+'</td>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[04]+'%">'+ M->B1_DESC+'</td>'
		_cOKLista += '      <td class="itens" align="left"   width="'+_aSizeOK[05]+'%"><b>INVENTARIAR URGENTE</b></td>'
		_cOKLista += '    </tr>'
	    _lEnvia:=.T.
	EndIf
	
	If !_lTudoZerado
		_cGetLista += '    <tr>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+ LEFT(_aTLinhas[_nI][02],2)+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+ _aTLinhas[_nI][03]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[03]+'%">'+ _aTLinhas[_nI][04]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[04]+'%">'+ _aTLinhas[_nI][05]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[05]+'%">R$ '+ _aTLinhas[_nI][06]+'</td>'
		_cGetLista += '      <td class="itens" align="right"  width="'+_aSizes[06]+'%">'+ _aTLinhas[_nI][07]+'</td>'
		_cGetLista += '      <td class="itens" align="left"   width="'+_aSizes[07]+'%">'+ _aTLinhas[_nI][08]+'</td>'
		_cGetLista += '    </tr>'
	    _lEnvia:=.T.
	EndIf
Next

If _lEnvia
   _cMsgEml:=StrTran(_cMsgEml,"#LISTAOK#",_cOKLista)
   _cMsgEml:=StrTran(_cMsgEml,"#LISTA#",_cGetLista)
		
   // Chama a função para envio do e-mail
   U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, "", cGetAssun, _cMsgEml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   	Help(NIL, NIL, "A010TOK03", NIL, Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+cGetPara+" Com Copia: "+cGetCc+CHR(13)+CHR(10), 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
   EndIf
Else
   If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   	Help(NIL, NIL, "A010TOK03", NIL,"Não tem registros para enviar", 1, 0, NIL, NIL, NIL, NIL, NIL,{""})
   EndIf   
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: A010WlInc()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/12/2019
Descrição---------: Monta e envia email 
Parametros--------: _oModelSB1
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function A010WlInc(_oModelSB1)

Local _aConfig	:= U_ITCFGEML('') , E
Local _cEmlLog	:= ""
Local _cMsgEml	:= ""
Local cGetCc	:= ""
Local cGetPara	:= "sistema@italac.com.br"
Local cTit      := "ALTERAÇÃO DE PRODUTO"
Local cGetAssun :='NOVO PRODUTO EM PROCESSO DE INCLUSAO'

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU

If !Inclui .And. !("#CONTROLE" $ SB1->B1_I_MOTBL)
	Return .T.	    
ElseIf  (!DBSeek(xFilial("ZZL") + __cUserId) .Or. ZZL->ZZL_CADPRD = "5" .Or. ZZL->ZZL_CADPRD = " ") .OR.;
	(!ZZL->ZZL_CADPRD $ "1,0" .And. !Altera )
   	Help(NIL, NIL, "A010TOK03", NIL,"O usuário: " + cUserName + " não possui permissão para executar esta ação neste cadastro.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
		{"Verificar com a área de TI a possibilidade de habilitar o seu usuário."})
	Return .F.	    
ElseIf ZZL->ZZL_CADPRD = "0"
	Return .T.	    
EndIf

If !Inclui
	M->B1_I_MOTBL:=SB1->B1_I_MOTBL
	M->B1_MSBLQL :=SB1->B1_MSBLQL
EndIf   

If ZZL->ZZL_CADPRD = "1"//Almoxarifado (Incluir)
	If Inclui .Or. "#CONTROLE1" $ SB1->B1_I_MOTBL
		cTit :="INCLUSAO DE PRODUTO"
		cMens:="Aguardando FISCAL preencher campos"
		cTipo:=" = '2'"
		M->B1_MSBLQL :="1"
		M->B1_I_MOTBL:="#CONTROLE1 - "+cMens//Inclusão do Almoxarifado"
	Else
		Return .T.//SE NÃO TIVER NA FASE 1 NÃO ENVIA EMAIL
	EndIf   
ElseIf ZZL->ZZL_CADPRD = "2"//FISCAL 
	If "#CONTROLE1" $ SB1->B1_I_MOTBL  .Or. "#CONTROLE2" $ SB1->B1_I_MOTBL  //NA FASE  ANTERIOR OU ATUAL DE NOVO
		cMens:="Aguardando CONTABILIDADE preencher campos"
		cTipo:=" = '3'"
		M->B1_I_MOTBL:="#CONTROLE2 - "+cMens//Alteração do Fiscal"
	Else
		Return .T.//SE NÃO TIVER NA FASE 2 NÃO ENVIA EMAIL
	EndIf
ElseIf ZZL->ZZL_CADPRD = "3"//CONTABILIDADE 
	If "#CONTROLE2" $ SB1->B1_I_MOTBL .Or. "#CONTROLE3" $ SB1->B1_I_MOTBL  //NA FASE  ANTERIOR OU ATUAL DE NOVO
		cMens:="Aguardando EXPEDIÇÃO preencher campos"
		cTipo:=" = '4'"
		M->B1_I_MOTBL:="#CONTROLE3 - "+cMens//Alteração do Fiscal"
	ElseIf !"#CONTROLE3" $ SB1->B1_I_MOTBL 
		Help(NIL, NIL, "A010TOK03", NIL,"Deve-se aguardar a Fiscal preencher os campos para finalizar o processo.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Verificar com a área de Fiscal."})
		Return .F.	    
	EndIf   
ElseIf ZZL->ZZL_CADPRD = "4"//EXPEDICAO 
	cTit :="Novo produto incluido com SUCESSO no cadastro"
	cMens:="PRODUTO DESBLOQUEADO E DISPONIVEL PARA USO"
	cGetAssun :=Upper(cTit)
	If "#CONTROLE3" $ SB1->B1_I_MOTBL  
		M->B1_I_MOTBL:=""
		M->B1_MSBLQL :="2"
	Else
		Help(NIL, NIL, "A010TOK03", NIL,"Deve-se aguardar a Contabilidade preencher os campos para finalizar o processo.", 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{"Verificar com a área de Contabilidade."})
		Return .F.	    
	EndIf   
	cTipo:=" IN ('1','2','3','4') "
Else
   Return .T.
EndIf

_oModelSB1:LoadValue('B1_MSBLQL' ,M->B1_MSBLQL)
_oModelSB1:LoadValue('B1_I_MOTBL',M->B1_I_MOTBL)

_cFileName:=NIL
If !Inclui
	_cAlteracoes:="Produto:;"+M->B1_COD+"-"+AllTrim(M->B1_DESC)+CHR(13)+CHR(10)+CHR(13)+CHR(10)
	_cAlteracoes+="CAMPO;ANTES;DEPOIS"+CHR(13)+CHR(10)

	_aStruct:= SB1->(DBSTRUCT())
	For E := 1 To Len(_aStruct)
		_cUsado:=Getsx3cache(_aStruct[E][1],"X3_USADO")
		If !X3USO(_cUsado)
			Loop
		EndIf
		_cConOrg := "SB1->"+AllTrim(_aStruct[E][1] )
		_cConAlt :=   "M->"+AllTrim(_aStruct[E][1] )
		Do Case
			Case _aStruct[E][2] == "C"
				_cConOrg := AllTrim( &(_cConOrg) )
				_cConAlt := AllTrim( &(_cConAlt) )
			Case _aStruct[E][2] == "N"
				_cConOrg := " "+cValToChar( &(_cConOrg) )
				_cConAlt := " "+cValToChar( &(_cConAlt) )
			Case _aStruct[E][2] == "D"
				_cConOrg := DToC( &(_cConOrg) )
				_cConAlt := DToC( &(_cConAlt) )
			Case _aStruct[E][2] == "L"
				_cConOrg := If( &(_cConOrg) , ".T." , ".F." )
				_cConAlt := If( &(_cConAlt) , ".T." , ".F." )
			Case _aStruct[E][2] == "M"
				_cConOrg := AllTrim( &(_cConOrg) )
				_cConAlt := AllTrim( &(_cConAlt) )
		EndCase
		If !(_cConOrg == _cConAlt)
			_cAlteracoes+=AllTrim( _aStruct[E][1] )+";"+_cConOrg+";"+_cConAlt+CHR(13)+CHR(10)
		EndIf
	Next
	_cFileName:="ALTERACOES_"+DToS(Date())+"_"+StrTran(TIME(),":","_")+".CSV"
	_cFileName:=AllTrim(GETMV("MV_RELT",,"\SPOOL\"))+_cFileName
	MemoWrite(_cFileName,_cAlteracoes)
EndIf   

_cQry := "SELECT ZZL_EMAIL "
_cQry += "FROM " + RetSqlName("ZZL") + " "
_cQry += "WHERE ZZL_FILIAL = '" + xFilial("ZZL") + "' "
_cQry += "  AND ZZL_CADPRD "+cTipo
_cQry += "  AND D_E_L_E_T_ = ' ' "

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBZZL" , .T., .F. )

DBSelectArea("TRBZZL")
TRBZZL->(DBGoTop())

_acTo:={}
While !TRBZZL->(Eof())
	aAdd(_acTo,AllTrim(TRBZZL->ZZL_EMAIL))
	TRBZZL->(DBSkip())
EndDo
TRBZZL->(DBCloseArea())

If ZZL->ZZL_CADPRD <> "4" .And. Len(UsrRetGrp(PswChave(RetCodUsr()),RetCodUsr())) # 0 // Quando nao For rotina automatica do configurador
   cGetCc  := LOWER(AllTrim(UsrRetMail(__cUserId))) // Pega e-mail do usuario
   aAdd(_acTo,cGetCc)
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
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados do Produto</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>CODIGO: </b></td>'
_cMsgEml += '      <td class="itens" >'+ M->B1_COD +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>DESCRIÇÃO: </b></td>'
_cMsgEml += '      <td class="itens" >'+ M->B1_DESC +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>SOLICITANTE:</b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>STATUS: </b></td>'
_cMsgEml += '      <td class="itens" >'+cMens+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [A010TOK]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

For E := 1 To Len(_acTo)
    cGetPara:=_acTo[E]
    // Chama a função para envio do e-mail
//    ITEnvMail(cFrom        ,cEmailTo,_cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer     ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
    U_ITENVMAIL(_aConfig[01], cGetPara,         ,         ,cGetAssun,_cMsgEml ,_cFileName,_aConfig[01],_aConfig[02],_aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		
    If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
       Help(NIL, NIL, "A010TOK03", NIL,Upper(_cEmlLog)+CHR(13)+CHR(10)+"E-mail para: "+cGetPara, 1, 0, NIL, NIL, NIL, NIL, NIL,;
			{""})
    EndIf
    If _cFileName <> NIL
	   FERASE(_cFileName)
	EndIf   
Next

Return .T.
