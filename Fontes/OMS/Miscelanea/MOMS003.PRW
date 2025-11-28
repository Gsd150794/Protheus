/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |08/08/2024| Adicionado ao array o codigo cnae e mensagem para obrigatoriedade da informação
Igor Melgaço  |16/09/2024| Chamado 48523 - Ajuste para que o campo CNAE não seja obrigatório. 
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include	"TOTVS.Ch"
#Include	"FWMVCDef.Ch"

/*
===============================================================================================================================
Programa----------: MOMS003
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina de gerar clientes a partir do cadastro de fornecedores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
 */
User Function MOMS003()

Local aCampo		:= {'Data','Hora','Tp. Ocor.','Ocorrências'}

Private	_cTexto	:= ''

Public _aLogM003	:= {}

aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Iniciando o processamento' } )

//validar acessos do usuario
If !U_ITVLDUSR(9)
	
	U_ITMsg('O usuário '+UsrRetName( RetCodUsr() )+' não possui acesso para geração de clientes. ', 'Validação de acesso',;
			'Informar ao suporte T.I. para realizar essa manutenção. ',1)	
	Return .F.
	
EndIf

U_ITLOGACS() //Grava log de utilização

Processa( {|| MOMS003INI() } , "Processando..." , "Iniciando o processamento..." )

aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Encerrando o processamento' } )

U_ITListBox( 'Log de Processamento' , aCampo , _aLogM003 , .T. , 1 )

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS003INI
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS003INI()

Local aFields		:= {}
Local cQuery		:= ""
Local cAliasQry		:= GetNextAlias()
Local aCpos			:= MOMS003Y()
Local bIniChk		:= {|| .T. }
Local nAtuReg		:= 0
Local cPerg         := "MOMS003"
Local cClasse, cEst1, cEst2
Local aSeeks		:= {}

Private cAliasAux	:= GetNextAlias()
Private nOrdem      := 90
Private nTotReg		:= 0
Private oMarkBRW	:= Nil

If ! Pergunte(cPerg)
	Return
EndIf

cClasse	:= MV_PAR01
cEst1	:= MV_PAR02
cEst2	:= MV_PAR03

cQuery := " SELECT "
cQuery += "     SA2.A2_COD		AS FORNECE, "
cQuery += "     SA2.A2_LOJA		AS LOJA, "
cQuery += "     SA2.A2_NOME		AS NOME, "
cQuery += "		SA2.A2_CGC		AS CGC, "
cQuery += "		SA2.A2_EST		AS EST, "
cQuery += "		SA2.A2_I_CLASS	AS CLASSE, "
cQuery += "		SA2.R_E_C_N_O_	AS REGSA2 "
cQuery += " FROM "+ RetSqlName("SA2") +" SA2 "
cQuery += " WHERE "
cQuery += " SA2.D_E_L_E_T_  = ' ' "
cQuery += " AND SA2.A2_FILIAL   = '"+ xFilial("SA2") +"' "
cQuery += " AND SA2.A2_MSBLQL   <> '1' "
cQuery += " AND SA2.A2_I_CLASS IN "+FormatIn(cClasse,";")
cQuery += " AND SA2.A2_EST BETWEEN '"+cEst1+"' AND '"+cEst2+"' "
cQuery += " AND SA2.A2_CGC NOT IN ( SELECT SA1.A1_CGC FROM "+ RetSqlName("SA1") +" SA1 WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' ) "
cQuery += " ORDER BY SA2.A2_COD, SA2.A2_LOJA "

If Select(cAliasQry) > 0
	(cAliasQry)->( DBCloseArea() )
EndIf

ProcRegua(0)
IncProc( "Lendo registros..." )
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAliasQry , .T. , .F. )

DBSelectArea(cAliasQry)
(cAliasQry)->( DBGoTop() )
(cAliasQry)->( DBEval( {|| nTotReg++ } ) )
(cAliasQry)->( DBGoTop() )

If nTotReg <= 0
	
	(cAliasQry)->( DBCloseArea() )
	U_ITMsg( "Não foram encontrados fornecedores para esse filtro!", "Atenção!",,1 )
	Return
	
EndIf

IncProc( "Criando tabela temporária..." )

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select(cAliasAux) > 0
    (cAliasAux)->( DBCloseArea() )
EndIf

//================================================================================
// Permite o uso do arquivo criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( cAliasAux, aCpos )

_otemp:AddIndex( "01", {"NOME"} )
_otemp:AddIndex( "02", {"CGC"} )
_otemp:AddIndex( "03", {"FORNECE"} )

_otemp:Create()  
         
DBSelectArea(cAliasAux)

ProcRegua(nTotReg)

While (cAliasQry)->(!Eof())
	
	nAtuReg++
	IncProc( "Filtrando registros dos parametros... ["+ StrZero( nAtuReg , 6 ) +"] de ["+ StrZero( nTotReg , 6 ) +"]" )
	
	(cAliasAux)->( RecLock( cAliasAux , .T. ) )
	(cAliasAux)->MARCA		:= " "
	(cAliasAux)->FORNECE	:= (cAliasQry)->FORNECE
	(cAliasAux)->LOJA		:= (cAliasQry)->LOJA
	(cAliasAux)->NOME 		:= (cAliasQry)->NOME
	(cAliasAux)->CGC		:= (cAliasQry)->CGC
	(cAliasAux)->EST		:= (cAliasQry)->EST
	(cAliasAux)->CLASSE     := (cAliasQry)->CLASSE
	(cAliasAux)->REGSA2     := (cAliasQry)->REGSA2
	(cAliasAux)->( MSUnLock() )
	
	(cAliasQry)->( DBSkip() )
EndDo

(cAliasQry)->( DBCloseArea() )

aAdd( aFields , { "Fornecedor"		, {|| (cAliasAux)->FORNECE }  		, "C" , "@!" , 0 , TamSX3("A2_COD")[01]		, 0 } )
aAdd( aFields , { "Loja"			, {|| (cAliasAux)->LOJA }	  		, "C" , "@!" , 0 , TamSX3("A2_LOJA")[01]	, 0 } )
aAdd( aFields , { "Nome"			, {|| (cAliasAux)->NOME }	  		, "C" , "@!" , 0 , TamSX3("A2_NOME")[01]	, 0 } )
aAdd( aFields , { "CPF/CNPJ"		, {|| (cAliasAux)->CGC }	  		, "C" , "@!" , 0 , TamSX3("A2_CGC")[01]		, 0 } )
aAdd( aFields , { "Estado"			, {|| (cAliasAux)->EST }			, "C" , "@!" , 0 , TamSX3("A2_EST")[01]		, 0 } )
aAdd( aFields , { "Classe"			, {|| (cAliasAux)->CLASSE }			, "C" , "@!" , 0 , TamSX3("A2_I_CLASS")[01]		, 0 } )

aAdd( aSeeks, { "Nome"		, { { "Nome"		, "C" , TamSX3("A2_NOME")[01]	, 0 , "Nome"		, "@!"				} } } )
aAdd( aSeeks, { "CPF/CNPJ"	, { { "CPF/CNPJ"	, "C" , TamSX3("A2_CGC")[01]	, 0 , "CPF/CNPJ"	, "99999999999999"	} } } )
aAdd( aSeeks, { "Codigo"	, { { "Codigo"		, "C" , TamSX3("A2_COD")[01]	, 0 , "Codigo"		, "@!"				} } } )

oMarkBRW := FWMarkBrowse():New()		   	// Inicializa o Browse
oMarkBRW:SetAlias( cAliasAux )			   	// Define Alias que será a Base do Browse
oMarkBRW:SetDescription( "Fornecedores" )	// Define quais fornecedores serão marcados
oMarkBRW:SetFieldMark( "MARCA" )			// Define o campo que sera utilizado para a marcação
oMarkBRW:SetMenuDef( 'MOMS003' )			// Força a utilização do menu da rotina atual
oMarkBRW:SetAllMark( {|| oMarkBRW:AllMark() } )	// Ação do Clique no Header da Coluna de Marcação
oMarkBRW:SetFields( aFields )					// Campos para exibição
oMarkBRW:SetSeek(.T.,aSeeks)				// habilita pesquisa no browse
oMarkBRW:AddButton( "Confirmar" , {|| Processa( {|| MOMS003B() } , "Gerando Clientes..." , "Aguarde!" ) } ,, 4 )
oMarkBRW:SetIniWindow( bIniChk )	// Validação de Inicialização
oMarkBrw:SetCustomMarkRec({|| MOMS003M(oMarkBrw) }) //controle dos registros marcados 

oMarkBRW:Activate()					// Ativacao da classe

//fechar arquivo temporario
(cAliasAux)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina de construção do menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina	:= {}

ADD OPTION aRotina Title 'Visualizar'	Action 'U_MOMS003S( (cAliasAux)->REGSA2 )'	OPERATION 2 ACCESS 0

Return( aRotina )

/*
===============================================================================================================================
Programa----------: MOMS003M
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina de controle da marca
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS003M(oMarkBrw)

If ( !oMarkBrw:IsMark() )
	RecLock(oMarkBrw:Alias(),.F.)
	(oMarkBrw:Alias())->MARCA  := oMarkBrw:Mark()
	(oMarkBrw:Alias())->(MSUnLock())
Else
	RecLock(oMarkBrw:Alias(),.F.)
	(oMarkBrw:Alias())->MARCA  := ""
	(oMarkBrw:Alias())->(MSUnLock())
EndIf

Return( .T. )

/*
===============================================================================================================================
Programa----------: MOMS003S
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina de consulta do cadastro completo do Cliente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS003S( nRegSA2 )

Private cCadastro := "Cadastro do Fornecedor"

DBSelectArea("SA2")
SA2->( DBGoTo(nRegSA2) )
AxVisual( "SA2" , nRegSA2 , 2 )

Return

/*
===============================================================================================================================
Programa----------: MOMS003Y
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Define a criação de campos para exibição da análise
Parametros--------: Nenhum
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MOMS003Y()

Local aCpos := {}

aAdd( aCpos , { "MARCA"			, "C" , 1						, 0 } )
aAdd( aCpos , { "FORNECE"		, "C" , TamSX3("A2_COD")[01]	, 0 } )
aAdd( aCpos , { "LOJA"			, "C" , TamSX3("A2_LOJA")[01]	, 0 } )
aAdd( aCpos , { "NOME"			, "C" , TamSX3("A2_NOME")[01]	, 0 } )
aAdd( aCpos , { "CGC"			, "C" , TamSX3("A2_CGC")[01]	, 0 } )
aAdd( aCpos , { "EST"			, "C" , TamSX3("A2_EST")[01]	, 0 } )
aAdd( aCpos , { "CLASSE"		, "C" , TamSX3("A2_I_CLASS")[01], 0 } )
aAdd( aCpos , { "REGSA2"		, "N" , 10						, 0 } )

Return( aCpos )

/*
===============================================================================================================================
Programa----------: MOMS003B
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Processa a criação dos clientes
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS003B()

Local nRegMark	:= 0
Local nTotReg	:= 0
Local nRegSel	:= 0
Local cCliente := "Z"

ProcRegua(nTotReg)

//===========================================================================
//| Verifica a quantidade de Registros no Browse                            |
//===========================================================================
oMarkBRW:GoBottom()
nTotReg := oMarkBRW:At()
oMarkBRW:GoTop()

IndRegua(cAliasAux,CriaTrab(Nil,.F.),"MARCA",,"MARCA#' '","Filtrando registros...")

(cAliasAux)->(DBGoTop())

While (cAliasAux)->(!Eof()) .And. (cAliasAux)->MARCA # ' '
	
	IncProc( "Processando... ["+ StrZero(nRegMark++,10) +"] de ["+ StrZero(nTotReg,10) +"]" )
	
	Begin Transaction
	
	// função de gravação do SA1
	If MOMS003L( (cAliasAux)->REGSA2 )
		cCliente += ','+AllTrim( (cAliasAux)->CGC )
		nRegSel++
	EndIf
	
	End Transaction
	
	(cAliasAux)->(DBSkip())
EndDo

//===========================================================================
//| Verifica o Status geral do processamento.                               |
//===========================================================================
U_ITMsg( StrZero(nRegMark,10)+" Registros Marcados / " + StrZero(nRegSel,10)+" Registros processados com sucesso! " , "Concluído!" ,,2)

CloseBrowse()

MOMS003R(cCliente)

Return

/*
===============================================================================================================================
Programa----------: MOMS003L
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Inclusão dos clientes
Parametros--------: nregSA2 - recno do fornecedor
Retorno-----------: Logico (conclusão da operação)
===============================================================================================================================
*/
Static Function MOMS003L(nRegSA2)

Local aCli	:= {}
Local lRet  := .T.
Local cTipo := 'F' //consumidor final
Local cDDD	:= '999'
Local cTel	:= '999999999999999'
Local cQry	:= ""
Local cAlias:= GetNextAlias()
Local lNew	:= .T.
Local _cRisco 	:= ""
Local _nLimite	:= 0
Local _dLimite	:= SToD("20010101")
Local _lMVCSA1      := U_ItGetMv( "MV_MVCSA1" , .F. ) // Parammetro para habilitar execução do ExecAuto do novo CRMA980 


Private lMsErroAuto := .F.

//Posiciona no registro marcado do cadastro de fornecedor
SA2->(DBGoTo(nRegSA2))

//determinar o tipo do cliente
If SA2->A2_TIPO = 'X' //OUTROS
	cTipo := 'X'
ElseIf SA2->A2_TIPO = 'J' //JURIDICO
	cTipo := "R"
ElseIf SA2->A2_TIPO = 'F' .And. SA2->A2_I_CLASS = 'P' //FISICO E PRODUTOR
	cTipo := "L"
ElseIf SA2->A2_TIPO = 'F' .And. SA2->A2_I_CLASS # 'P' //FISICO E NÃO PRODUTOR
	cTipo := "F"
EndIf

//tratamento de telefones
If !Empty(SA2->A2_DDD)
	cDDD := SA2->A2_DDD
EndIf
If !Empty(SA2->A2_TEL)
	cTel := SA2->A2_TEL
EndIf

//================================================================================ 	
//Carrega parâmetros de limite de crédito
//================================================================================ 	
_cRisco 	:= 	U_ITGETMV( "IT_RISCOFOR" , "B" ) 
_nLimite 	:=	U_ITGETMV( "IT_LIMFORN" , 300 )
_dLimite 	:=	U_ITGETMV( "IT_VNCLIMFO" , SToD("20491231") )


//verifica se existe mais cadastros do cliente posicionado, para saber se havera limite de credito ou nao.
cQry := " SELECT COUNT(*) AS CONTADOR "
cQry += " FROM " + RetSqlName("SA1") + " "
cQry += " WHERE SubStr(A1_CGC,1,8) = '" + SubStr(SA2->A2_CGC,1,8) + "' "
cQry += "   AND A1_LC > 0 "
cQry += "   AND D_E_L_E_T_ = ' ' "

DbUseArea( .T. , "TOPCONN" , TcGenQry(,, cQry ) , cAlias , .T., .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )
If (cAlias)->CONTADOR > 0
	lNew := .F.
EndIf
DBSelectArea(cAlias)
(cAlias)->( DBCloseArea() )

aAdd( aCli , { "A1_FILIAL"		, xFilial("SA1")						, Nil }) // FILIAL
aAdd( aCli , { "A1_NOME"		, SA2->A2_NOME							, Nil }) // NOME
aAdd( aCli , { "A1_PESSOA"		, If(SA2->A2_TIPO $ 'JX','J','F')		, Nil }) // PESSOA FISICA OU JURIDICA
aAdd( aCli , { "A1_CGC"			, SA2->A2_CGC							, Nil }) // CGC
aAdd( aCli , { "A1_NREDUZ"		, SA2->A2_NREDUZ						, Nil }) // NOME REDUZIDO
aAdd( aCli , { "A1_TIPO"		, cTipo									, Nil }) // TIPO DE CLIENTE (CONSUMIDOR, PRODUTOR, REVENDEOR, SOLIDARIO, EXPORTACAO)
aAdd( aCli , { "A1_EST"			, SA2->A2_EST							, Nil }) // ESTADO
aAdd( aCli , { "A1_COD_MUN"		, SA2->A2_COD_MUN						, Nil }) // COD.MUNICIPIO
aAdd( aCli , { "A1_CEP"			, SA2->A2_CEP							, Nil }) // CEP
aAdd( aCli , { "A1_END"			, SA2->A2_END							, Nil }) // ENDEREÇO
aAdd( aCli , { "A1_BAIRRO"		, SA2->A2_BAIRRO						, Nil }) // BAIRRO
aAdd( aCli , { "A1_DDD"			, cDDD									, Nil }) // DDD DO TELEFONE
aAdd( aCli , { "A1_TEL"			, cTel									, Nil }) // NUMERO DO TELEFONE
aAdd( aCli , { "A1_PAIS"		, SA2->A2_PAIS							, Nil }) // PAIS
aAdd( aCli , { "A1_ESTC"		, SA2->A2_EST							, Nil }) // ESTADO COBRANCA
aAdd( aCli , { "A1_I_CMUNC"		, SA2->A2_COD_MUN						, Nil }) // COD.MUNICIPIO COBRANCA
aAdd( aCli , { "A1_CEPC"		, SA2->A2_CEP							, Nil }) // CEP COBRANCA
aAdd( aCli , { "A1_ENDCOB "		, SA2->A2_END							, Nil }) // ENDERECO COBRANCA
aAdd( aCli , { "A1_BAIRROC"		, SA2->A2_BAIRRO						, Nil }) // BAIRRO COBRANCA
aAdd( aCli , { "A1_INSCR"		, SA2->A2_INSCR							, Nil }) // INSCRICAO ESTADUAL
aAdd( aCli , { "A1_I_GRCLI"		, "11"									, Nil }) // GRUPO CLIENTE
aAdd( aCli , { "A1_NATUREZ"		, "111001"								, Nil }) // NATUREZA
aAdd( aCli , { "A1_VEND"		, "000156"								, Nil }) // CODIGO DO VENDEDOR
aAdd( aCli , { "A1_GRPVEN"		, "999999"								, Nil }) // GRUPO DE VENDAS
aAdd( aCli , { "A1_RISCO"		, _cRisco								, Nil }) // RISCO CLIENTE
If lNew
	aAdd( aCli , { "A1_LC"		, _nLimite								, Nil }) // VALOR DO LIMITE
	aAdd( aCli , { "A1_VENCLC"	, _dLimite								, Nil }) // VENCIMENTO DO LIMITE
Else
	aAdd( aCli , { "A1_LC"		, 0.01									, Nil }) // VALOR DO LIMITE (COLOCA 0.01 PARA PASSAR PELA VALIDACAO SEM LIBERAR CREDITO)
																				  // LIMITE DE CREDITO É CONCENTRADO EM UMA FILIAL DO CLIENTE
EndIf
aAdd( aCli , { "A1_EMAIL"		, SA2->A2_EMAIL							, Nil }) // EMAIL
aAdd( aCli , { "A1_CONTA"		, " "									, Nil }) // Conta Contabil
aAdd( aCli , { "A1_COND"		, "001"									, Nil }) // CONDICAO DE PAGTO
aAdd( aCli , { "A1_MSBLQL"		, "2"									, Nil }) // bloqueio

aAdd( aCli , { "A1_I_END"		, SA2->A2_I_END							, Nil }) // Endereço na Receita Federal
aAdd( aCli , { "A1_I_NUM"		, SA2->A2_I_NUM							, Nil }) // Número na Receita Federal
aAdd( aCli , { "A1_I_SITRF"		, SA2->A2_I_SITRF						, Nil }) // Situação na Receita Federal
aAdd( aCli , { "A1_I_DTSRF"		, SA2->A2_I_DTSRF						, Nil }) // Data da Situação na Receita Federal

aAdd( aCli , { "A1_CONTRIB"		, SA2->A2_CONTRIB						, Nil }) // Número na Receita Federal
aAdd( aCli , { "A1_SIMPNAC"		, SA2->A2_SIMPNAC						, Nil }) // Situação na Receita Federal
aAdd( aCli , { "A1_CNAE"		, SA2->A2_CNAE							, Nil }) // Situação na Receita Federal


If Empty(SA2->A2_CONTRIB) .Or. Empty(SA2->A2_SIMPNAC) 

	_ctexto := "Campos obrigatórios, Contribuinte ICMS , Part Simples não preenchidos no fornecedor!"
	aAdd( _aLogM003 , { Date() , Time() ,'Erro' ,_cTexto } )
	lRet := .F.

EndIf

If lRet

    aCli:=U_AcertaDados("SA1",aCli)//por causado MVC
	
    If _lMVCSA1
        MSExecAuto( {|x,y,z| CRMA980(x,y,z) } , aCli , 3 , ) // SIGA AUTO PARA A INCLUSAO DO CLIENTE
    Else
        MSExecAuto( {|x,y,z| mata030(x,y,z) } , aCli ,, 3 ) // SIGA AUTO PARA A INCLUSAO DO CLIENTE
    EndIf

	If lMsErroAuto
		If ( __lSx8 )
			RollBackSx8()
		EndIf
		_cTexto := MostraErro("\system\", SA2->A2_CGC + DToS(dDataBase) + ".log")
		//_cTexto := MOMS003P(_cTexto)
		aAdd( _aLogM003 , { Date() , Time() ,'Erro' ,_cTexto } )
		lRet := .F.
	Else
		If __lSX8
			While ( GetSX8Len() > nSaveSX8 )
				ConfirmSX8()
			EndDo
		EndIf
	EndIf
EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: MOMS003P
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina para capturar o erro emitido pela execauto
Parametros--------: cTexto => Recebe o texto emitido pelo erra da execauto
Retorno-----------: cRet => Retorna o texto que será utilizado na janela de log ao final do processamento
===============================================================================================================================
*/
Static Function MOMS003P(_cTexto)
Local cRet		:= ""
Local cErroTemp	:= ""
Local cBuffer	:= ""
Local nLinhas	:= 0
Local cCampo	:= ""
Local nErrLin	:= 0

cErroTemp	:= AllTrim(_cTexto)
nLinhas		:= MLCount(cErroTemp)
cBuffer		:= ""
cCampo		:= ""
nErrLin		:= 0
cBuffer		:= RTrim(MemoLine(cErroTemp,200,nErrLin))
  
//Carrega o nome do campo
While (nErrLin <= nLinhas)
     nErrLin++
     cBuffer:=RTrim(MemoLine(cErroTemp,200,nErrLin))
     If "INVALIDO" $ Upper(cBuffer) .And. "A1_EMAIL" $ Upper(cBuffer)
     	cRet += "\" + AllTrim(SubStr(cBuffer,1,at("A",cBuffer)-3)) + " - " + SubStr(cBuffer,at("=",cBuffer)+2,Len(cBuffer))
     ElseIf "A1_CGC" $ Upper(cBuffer)
     	cRet += "\" + AllTrim(SubStr(cBuffer,1,at("-",cBuffer)-1)) + " - " + SubStr(cBuffer,at("=",cBuffer)+2,Len(cBuffer))
     ElseIf "A1_NOME" $ Upper(cBuffer)
     	cRet += " \ " + AllTrim(SubStr(cBuffer,1,at("-",cBuffer)-1)) + " - " + SubStr(cBuffer,at("=",cBuffer)+2,Len(cBuffer))
     ElseIf "INVALIDO" $ Upper(cBuffer)
     	cRet += "\" + AllTrim(SubStr(cBuffer,1,at("-",cBuffer)-1)) + " - " + SubStr(cBuffer,at("=",cBuffer)+2,Len(cBuffer))
     EndIf
End

Return(cRet)

/*
===============================================================================================================================
Programa----------: MOMS003R
Autor-------------: Xavier
Data da Criacao---: 22/04/2015
Descrição---------: Rotina para montar o array com os registros que foram processados corretamente
Parametros--------: cCliente => Recebe os CNPJ's dos cliente que tiveram seus processos ok
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS003R(cCliente)
Local cQuery  := ""

cQuery += " SELECT A1_COD, A1_LOJA, A1_NOME, A1_CGC, A1_EST"
cQuery += " FROM " + RetSqlName("SA1") + " SA1 "
cQuery += " WHERE SA1.D_E_L_E_T_ = ' ' "
cQuery += " AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' "
cQuery += " AND A1_CGC IN "+FormatIn(cCliente,',')
cQuery += " ORDER BY SA1.A1_COD, SA1.A1_LOJA "

dbUseArea( .T., "TOPCONN",TcGenQry(,,cQuery),"TMPOK",.F.,.F.)

DBSelectArea("TMPOK")
TMPOK->(DBGoTop())

While !TMPOK->(Eof())
	aAdd( _aLogM003 , { Date() , Time() ,'Log' ,'Cliente: ' + TMPOK->A1_COD + " Loja: " + TMPOK->A1_LOJA + " Nome: " + AllTrim(TMPOK->A1_NOME) + ", processado com sucesso." } )
	TMPOK->(DBSkip())
End

DBSelectArea("TMPOK")
TMPOK->(DBCloseArea())

Return
