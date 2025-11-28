/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/06/2024| Chamado 47627. Tratamento para gerar apenas 1 item na NF-e de Produtor.
Lucas Borges  |24/07/2024| Chamado 47975. Corrigido cálculo dos impostos.
Lucas Borges  |10/10/2025| Chamado 52520. Passagem correta de usuário para as novas threads
Igor Melgaço  |05/11/2025| Chamado 52841. Ajuste para corrigir erro.log ao clicar em gerar eventos.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGLT020
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Tela de Mix - Lista os setores, linhas, produtores e seus respectivos valores
------------------: Possibilita lancamento,alteracao,exclusao de valores dos eventos de solicitacao de emprestimo ao fornecedor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT020(_nTipo)

Local _cTab		:= "TRBS"
Local _aAux 	:= {}
Local _cFiltro	:= ""
Local _cAlias	:= GetNextAlias()
Local _aSetFil	:= {}
Local _nI		:= 0
Local _nScan	:= 0
Local _cFilSet	:= ""//armazena os setores que o usuário tem acesso
Local _cFilMix	:= ""
Local _cTitOpcao:=" - "+aRotina[aScan(aRotina,{|X|"("+AllTrim(Str(_nTipo))+")"$X[2]}),1]
Local _lAgrupa	:= .T.
Local _aStruct1	:= {}
Private _aSize		:= MsAdvSize()
Private aObjects	:= {}
Private aInfo		:= {}
Private _oTempTRBS	:= ""
Private _oTempTRBL	:= ""
Private _oTempTRBP	:= ""
Private _oTempTRBF	:= ""
Private _oTempTRBG	:= ""

// Obtem tamanhos das telas
aAdd( aObjects, { 0, 0, .T., .T., .T. } )
aInfo		:= { _aSize[ 1 ], _aSize[ 2 ], _aSize[ 3 ], _aSize[ 4 ], 3, 3 }
aPosObj1	:= MsObjSize( aInfo, aObjects,  , .T. )

If _nTipo == 2 .And. dDataBase <> ZLE->ZLE_DTFIM
	MsgStop("Para executar a manutenção do MIX o usuário deve estar logado na database de fechamento do MIX selecionado!","AGLT02001")
	Return
EndIf

If _nTipo == 2 .And. ZLE->ZLE_STATUS == "F"
	MsgStop("O MIX atual já foi fechado e não poderá ser alterado!","AGLT02002")
	Return
EndIf

// Obtendo setores que o usuario pode acessar por Fabrica, executado só na manutencao ou visualizacao
If _nTipo == 2 .Or. _nTipo == 10
	DBSelectArea("ZLU")
	ZLU->( DBSetOrder(1) )
	If ZLU->( DBSeek( xFilial("ZLU") + RetCodUsr() ) )
		If ZLU->ZLU_FILMIX == 'S'//Se o usuário tem acesso, exibo tela para seleção de filiais
			_cFilMix := LstFabrica()
			If !Empty( _cFilMix )
				_cFilMix := FormatIn( _cFilMix , ";" )
				_cFiltro:= "% AND ZLT_CODIGO IN "+_cFilMix+"%"
				BeginSql alias _cAlias
					SELECT ZLT_SETOR
						FROM %Table:ZLT%
						WHERE D_E_L_E_T_ = ' '
						%exp:_cFiltro%
				EndSql
				
				_aAux := StrTokArr( U_LisSetor(.F.) , ";" )	
				While (_cAlias)->( !Eof() )
					_aSetFil := StrTokArr( AllTrim( (_cAlias)->ZLT_SETOR ) , ';' )
					For _nI := 1 To Len(_aSetFil)
						_nScan := 0
						//Verifica no array de setores do usuário, quais estão listados na filial selecionada
						If ( _nScan := aScan( _aAux , {|x| x == _aSetFil[_nI] } ) ) > 0
							_cFilSet += _aSetFil[_nI] + ';'
						EndIf
					Next _nI
					(_cAlias)->( DBSkip() )
				EndDo
				(_cAlias)->( DBCloseArea() )
				_cFilSet := FormatIn(SubStr(_cFilSet,1,Len(_cFilSet)-1),";")
			Else
				Return
			EndIf
		Else//Se não tem, já filtro os setores da filial corrente
			_cFilSet := FormatIn(U_LisSetor(.F.),";")
		EndIf
		
		If Empty(_cFilSet)
			MsgStop("Usuário não possui Setores liberados no cadastro de acessos do módulo Gestão do Leite! Solicite o acesso ao responsável pela Gestão do Leite.","AGLT02003")
			Return
		EndIf

	Else
		MsgStop("Usuário não cadastrado no controle de acessos do módulo Gestão do Leite! Solicite o acesso ao responsável pela Gestão do Leite.","AGLT02006")
		Return
	EndIf
	If MsgYesNo("Detalhar Eventos?","AGLT02007")
		_lAgrupa := .F.
	EndIf
EndIf

Do Case
	Case _nTipo == 1 //Inclusão
		AGLT020I()
	Case _ntipo == 2 .Or. _ntipo == 10 //Manutenção/Visualização
		ShowSetores(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1)
	Case _ntipo == 5 // Exclusão
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT COUNT(1) QTD
			FROM %Table:ZLF%
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_CODZLE = %Exp:ZLE->ZLE_COD%
			AND ZLF_ACERTO = 'S'
		EndSql

		If (_cAlias)->QTD > 0
			MsgStop("O MIX atual não pode ser excluído pois existem fechamentos realizados!","AGLT02008")
			(_cAlias)->( DBCloseArea())
			Return
		EndIf
			
	    (_cAlias)->( DBCloseArea())
	    
		// Verifica a confirmação e apaga os registros da ZLE e ZLF
		If MsgYesNo( "Confirma a exclusão do MIX: "+ ZLE->ZLE_COD +" ?" , "AGLT02009" )
			If !MsgYesNo( "Essa operacao irá excluir todos os Eventos gerados para o MIX! Confirma a exclusão?","AGLT02010")
		    	Return
			EndIf
			_cFiltro := " UPDATE "+RetSqlName('ZLE')+" ZLE SET D_E_L_E_T_ = '*'"
			_cFiltro += " WHERE "+ RetSqlCond('ZLE')
			_cFiltro += " AND ZLE.ZLE_COD    = '"+ ZLE->ZLE_COD	+"' "
			TcSqlExec(_cFiltro)
			_cFiltro := " UPDATE "+RetSqlName('ZLF')+" ZLF SET D_E_L_E_T_ = '*'"
			_cFiltro += " WHERE "+ RetSqlCond('ZLF')
			_cFiltro += " AND ZLF.ZLF_CODZLE = '"+ ZLE->ZLE_COD	+"' "
			TcSqlExec(_cFiltro)
		EndIf
EndCase

Return

/*
===============================================================================================================================
Programa----------: AGLT020I
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Realiza a inclusão de um novo mix com base na database
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT020I()

Local _dDataIni	:= FirstDate(DDataBase)
Local _dDataFim := LastDate(DDataBase)
Local _cAlias := GetNextAlias()

//Verifica se ja existe o Mix
BeginSql alias _cAlias
	SELECT COUNT(1) QTD
	  FROM %Table:ZLE%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLE_FILIAL = %xFilial:ZLE%
	   AND ZLE_DTINI >= %exp:_dDataIni%
	   AND ZLE_DTFIM <= %exp:_dDataFim%
EndSql
If (_cAlias)->QTD == 0
	ZLE->(RecLock("ZLE", .T.))
	ZLE->ZLE_FILIAL := xFilial("ZLE")
	ZLE->ZLE_COD    := GetSx8Num("ZLE","ZLE_COD")
	ZLE->ZLE_VERSAO := "1"
	ZLE->ZLE_DTINI  := _dDataIni
	ZLE->ZLE_DTFIM  := _dDataFim
	ZLE->ZLE_STATUS := "A"
	ZLE->(MSUnLock())
	ConfirmSX8()
	MsgInfo("Mix "+ZLE->ZLE_COD+" - "+DToC(_dDataIni)+"-"+DToC(_dDataFim)+" criado com sucesso!",'AGLT02011')
Else
	MsgInfo("Já existe um Mix cadastrado para o período corrente: "+DToC(_dDataIni)+"-"+DToC(_dDataFim),"AGLT02012")
EndIf

(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: LstFabrica
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta Tela para seleção de Filias
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function LstFabrica()    

Local _nX		:= 0
Local _aFiliais	:= {}
Local _nQdtFil	:= Len(FWAllFilial())
Local _nTam		:= 2
Local _nMax		:= 99
Local _aCat		:= {}
Local _MvPar	:= ""
Local _cTitulo	:= "Selecione as Fábricas desejadas para visualizar no Mix"
Local _MvParDef	:= ""
Local _aFil		:= {}

_aFil:=AdmGetFil(.F.,.F.,"ZLF",.T.,.F.,.F.)

For _nX:=1 To Len(_aFil)
	aAdd(_aFiliais,{_aFil[_nX][1]})
Next _nX

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

DBSelectArea("ZLS")
ZLS->(DBSetOrder(1))
ZLS->(DBGoTop())
While ZLS->(!Eof())
    //Quando o usuario nao tiver acesso a todas as Filiais       
    If Len(_aFiliais) <> _nQdtFil
		//Filtras somente as filiais que o usuario tem acesso
		If aScan(_aFiliais,{|x| x[1] == AllTrim(ZLS->ZLS_CODIGO)}) > 0
			_MvParDef += AllTrim(ZLS->ZLS_CODIGO)
			aAdd(_aCat,AllTrim(ZLS->ZLS_DESCRI))  
		EndIf
	Else
		_MvParDef += AllTrim(ZLS->ZLS_CODIGO)
		aAdd(_aCat,AllTrim(ZLS->ZLS_DESCRI))
	EndIf
	ZLS->(DBSkip())
EndDo

//Executa funcao que monta tela de opcoes
If F_Opcoes(@_MvPar,_cTitulo,_aCat,_MvParDef,,,.F.,_nTam,_nMax)
	//Tratamento para separar retorno com barra ";"
	_cFilMix := ""
	For _nX:=1 To Len(_MvPar) Step 2
		If !(SubStr(_MvPar,_nX,1) $ " |*")
			_cFilMix  += SubStr(_MvPar,_nX,2) + ";"
		EndIf
	Next _nX
	//Trata para tirar o ultimo caracter
	_cFilMix := SubStr(_cFilMix,1,Len(_cFilMix)-1)
Else
	_cFilMix := " "
	MsgInfo("Operação cancelada pelo usuário!","AGLT02013")
EndIf

Return(_cFilMix)

/*
===============================================================================================================================
Programa----------: CriaTmp
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Cria tabelas temporárias de todas as telas do Mix
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

Local _cAlias	:= GetNextAlias()
Local _cFiltro	:= "%"
Local _cTable	:= "%"
Local _cCampos	:= ""
Local _cGroup	:= "%"
Local _cOrder	:= "%"
Local _cTitulo	:= IIf(_cTab$"TRBS/TRBL/TRBP","(Prod.)","(Fret.)")
Default	_cFilial	:= ""
Default	_cSetor		:= ""
Default	_cLinha		:= ""
Default	_cFornece	:= ""
Default	_cLoja		:= ""

_aStruct1	:= {}

//Criando estrutura da tabela temporaria
//Nome do campo,Tipo,Tamanho,Decimal,Picture,Título,Largura da coluna
aAdd(_aStruct1,{"FILIAL","C",GetSX3Cache("ZLF_FILIAL","X3_TAMANHO"),00,"","Filial",05})// Filial
aAdd(_aStruct1,{"COD","C",GetSX3Cache("ZLF_A2COD","X3_TAMANHO"),00,"","Codigo",25})//Código do setor, linha, produtor e fretista
If _cTab $ "TRBP/TRBF/TRBG"
	aAdd(_aStruct1,{"LOJA","C",GetSX3Cache("ZLF_A2LOJA","X3_TAMANHO"),00,"","Loja",18})//loja do produtor e fretista
EndIf
aAdd(_aStruct1,{"DESCRI","C",40,00,"","Nome",90})//Descrição da linha, setor, nome produtor e fretista
If _cTab=="TRBG"
	aAdd(_aStruct1,{"LINHA","C",GetSX3Cache("ZLF_LINROT","X3_TAMANHO"),00,"","Linha",06})//Linha do fretista (detalhes)
EndIf
aAdd(_aStruct1,{"VOL","N",11,00,"@E 999,999,999","Volume",40}) //Volume de Leite
aAdd(_aStruct1,{"POR","N",08,04,"@E 999.9999","(%)",30}) //% do volume para aquela linha
If _cTab $ "TRBS/TRBL"
	aAdd(_aStruct1,{"NUMPRO","N",06,00,"@E 99,999","No.Produtores",45}) //No.Produtores
EndIf
aAdd(_aStruct1,{"MEDVDI","N",09,00,"@E 9,999,999","Volume Diario",43}) //Volume Diário
If _cTab$"TRBS/TRBL/TRBP"
	aAdd(_aStruct1,{"VLIQFR","N",16,02,"@E 999,999,999.99","Mix",50}) //Total Líquido Produtores+Fretistas (créditos-débitos-imp)
EndIf
aAdd(_aStruct1,{"VBRUTO","N",16,02,"@E 999,999,999.99","Valor Nota"+CRLF+"Fiscal",50}) //Total Bruto (créditos)
aAdd(_aStruct1,{"VLIQCI","N",16,02,"@E 999,999,999.99","Tot.Líq."+CRLF+_cTitulo,50}) //Total Liquido Produtor ou Fretista (créditos-débitos-imp)
aAdd(_aStruct1,{"VLIQSI","N",16,02,"@E 999,999,999.99","Total Brut"+CRLF+_cTitulo,50}) //Total Líquido Sem Impostos Produtor ou Fretista (créditos-débitos)
aAdd(_aStruct1,{"VIMP","N",16,02,"@E 999,999,999.99","Tot.Imp."+CRLF+_cTitulo,50}) //Total do Imposto
If _cTab$"TRBS/TRBL/TRBP"
	aAdd(_aStruct1,{"LLIQFR","N",10,04,"@E 9,999.9999","Mix p/Litro",50}) //Líq. p/Litro (Prod.+Fret.)
EndIf
aAdd(_aStruct1,{"LBRUTO","N",10,04,"@E 9,999.9999","Valor Litro"+CRLF+"Nota Fiscal",50}) //Total Bruto (créditos) p/Litro
aAdd(_aStruct1,{"LLIQCI","N",10,04,"@E 9,999.9999","Tot.Liq."+CRLF+"p/Litro "+_cTitulo,50}) //Total Líquido Com Impostos (créditos-débitos-imp) p/Litro
aAdd(_aStruct1,{"LLIQSI","N",10,04,"@E 9,999.9999","Total Bruto"+CRLF+"p/Litro"+_cTitulo,50}) //Total Liquido sem impostos (créditos-débitos) p/Litro

If _cTab=="TRBG"
	aAdd(_aStruct1,{"KMROD","N",6,00,"@E 99,999","KM Rodado",35})//KM Rodado
	aAdd(_aStruct1,{"DIASV","N",6,00,"@E 99,999","Dias/Viagens",40})//Dias/Viagens
	aAdd(_aStruct1,{"KMPAD","N",5,00,"@E 9,999","KM/Padrão",35})//KM Padrão
	aAdd(_aStruct1,{"VLRKM","N",08,02,"@E 9,999.99","Vlr/KM",35})//Vlr/KM
	aAdd(_aStruct1,{"KMDIA","N",8,02,"@E 9,999.99","KM/Dia",35}) //KM/Dia - //kKM Rodado divido por Dias/Viagens
EndIf

//===========================================================================================================
//Criando colunas a partir dos eventos - Agrupado ou Nao Agrupado. Quando o modo é visualização, só exibe os 
//eventos que tiveram movimento. Quando é Manutenção, exibe todos os eventos pois no modo de edição manual, é
//possível incluir qualquer evento, logo, o grid já tem que ter a coluna dele, pois os dados são recalculados, 
//mas a estrutura não é alterada.
//===========================================================================================================
_cCampos := "%"
If _lAgrupa
	_cCampos += " ZL7_COD COD, ZL7_NREDUZ NREDUZ "
	_cGroup += " ZL7_COD, ZL7_NREDUZ, ZL7_ORDMIX"
	_cOrder += " ZL7_ORDMIX, ZL7_COD "
Else 
	_cCampos += " ZL8_COD COD, ZL8_NREDUZ NREDUZ, ZL8_DEBCRE, ZL8_ALTERA, ZL8_PRIORI, ZL8_MODEDI, ZL8_PERTEN, ZL8_LIMFRT "
	_cGroup += " ZL8_COD, ZL8_NREDUZ, ZL8_DEBCRE, ZL8_ALTERA, ZL8_PRIORI, ZL8_MODEDI, ZL8_PERTEN, ZL8_LIMFRT, ZL8_ORDMIX "
	_cOrder += " ZL8_ORDMIX, ZL8_COD "
EndIf

//No Fretista deve aparecer tudo, independete de entrar ou não no MIX ZL8_MIX = S
If _cTab$"TRBF/TRBG"
	_cFiltro += " AND ZL8_PERTEN IN ('F','T')"
//No Setor e Linha, alguns eventos de Fretista precisam aparecer, então uso o ZL8_MIX para descartar vários Débitos
ElseIf _cTab$"TRBS/TRBL/TRBP"
	_cFiltro += " AND ZL8_MIX = 'S'"
EndIf
If _nTipo == 10
	//Nas telas de Fretista não faz sentido mostrar eventos do tipo T-Todos, mas que foram calculados para Produtores.
	//Já na tela de Setor e Linha, trago de ambos (Produtor e Fretista). Na tela de produtor, trato logo abaixo.
	If _cTab$"TRBF/TRBG"
		_cFiltro += " AND ZLF_A2COD LIKE 'G%' "
	EndIf
	_cFiltro += " AND ZLF.D_E_L_E_T_ = ' '
	_cFiltro += " AND ZL8_FILIAL = ZLF_FILIAL
	_cFiltro += " AND ZL8_COD = ZLF_EVENTO
	_cFiltro += " AND ZLF_CODZLE = '"+ZLE->ZLE_COD+"'"
	_cTable += ", "+RetSqlName("ZLF")+" ZLF"
	If !Empty(_cSetor)
		_cFiltro += " AND ZLF.ZLF_SETOR = '"+ _cSetor  +"' "
	EndIf
	If !Empty(_cLinha)
		_cFiltro += " AND ZLF.ZLF_LINROT = '"+ _cLinha  +"' "
	EndIf
	If !Empty(_cFornece)
		If _cTab == "TRBP" //Na tela de Produtor, filtro os evntos de fretista e produtor, mas gerados para o produtor
			_cFiltro += " AND ZLF.ZLF_RETIRO = '"+ _cFornece +"' "
			_cFiltro += " AND ZLF.ZLF_RETILJ = '"+ _cLoja +"' "
		Else
			_cFiltro += " AND ZLF.ZLF_A2COD = '"+ _cFornece +"' "
			_cFiltro += " AND ZLF.ZLF_A2LOJA = '"+ _cLoja +"' "
		EndIf
	EndIf
EndIf
//Na tela de Setor, sempre será agrupado e pode apresentar todas as filiais, logo, não filtro filial.
//Quando não For, ai estarei em uma filial específica e já consigo filtrar
If _cTab <> "TRBS" 
	_cFiltro += " AND ZL8_FILIAL = '"+ _cFilial +"' "
EndIf
_cFiltro += "%"
_cTable += "%"
_cCampos += "%"
_cGroup += "%"
_cOrder += "%"

BeginSql alias _cAlias
	SELECT %exp:_cCampos% 
		FROM %Table:ZL8% ZL8, %Table:ZL7% ZL7 %exp:_cTable%
		WHERE ZL8.D_E_L_E_T_ = ' '
		AND ZL7.D_E_L_E_T_ = ' '
		AND ZL7.ZL7_COD = ZL8.ZL8_GRUPO
		%exp:_cFiltro%
		GROUP BY %exp:_cGroup%
		ORDER BY %exp:_cOrder%
EndSql

While (_cAlias)->( !Eof() )
	//Nome do campo,Tipo,Tamanho,Decimal,Picture,Título,Largura da coluna
	aAdd(_aStruct1,{"T"+(_cAlias)->COD,"N",16,2,"@E 999,999,999.99","Total"+CRLF+Capital((_cAlias)->NREDUZ),50}) //Sempre criar a coluna do total do evento para poder calcular os totais sem divergências no arredondamento
	//Nome do campo,Tipo,Tamanho,Decimal,Picture,Título,Largura da coluna - _cTab=="TRBG" -> Não exibe o valor por litro, ou seja, 2 casas decimais
	aAdd(_aStruct1,{"E"+(_cAlias)->COD,"N",10,4,"@E 9,999.9999",Capital((_cAlias)->NREDUZ),50})
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->( DBCloseArea() )

aAdd(_aStruct1,{"STATUS","C",12,00,"","Status",30})

//Criando tabelas temporaria a partir da estrutura definida
If Select(_cTab) == 0//Evita criar desnecessáriamente a tabela quando estiver "voltando" (drill Up) na tela
	&("_oTemp"+_cTab):=FWTemporaryTable():New(_cTab,_aStruct1)
	&("_oTemp"+_cTab):AddIndex("01",{"FILIAL","COD"})
	&("_oTemp"+_cTab):Create()
EndIf

Return

/*
===============================================================================================================================
Programa----------: GravaTmp
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Grava informações do Mix na tabela temporária criada
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

Local _cFilVolTo 	:= ""
Local _cFiltro		:= ""
Local _cFilZLD 		:= "%%"
Local _cFil2ZLD 	:= ""
Local _cFilZLF 		:= "%%"
Local _cFil2ZLF 	:= ""
Local _cCampos		:= ""
Local _cCampos2 	:= ""
Local _cCampos3		:= "%%"
Local _cCampZLD 	:= "%%"
Local _cCampZLF 	:= "%%"
Local _cTable		:= "%%"
Local _cGroup 		:= ""
Local _cGroupZLD	:= "%%"
Local _cGroupZLF	:= "%%"
Local _cOrder		:= "%%"
Local _nX			:= 0
Local _nDiasMix		:= Val( SubStr( DToS( ZLE->ZLE_DTFIM ) , 7 , 2 ) )
Local _cAlias		:= GetNextAlias()
Local _cBonif		:= SuperGetMV("LT_CODBON",.F.,"")
Default	_cFilial	:= ""
Default	_cSetor		:= ""
Default	_cLinha		:= ""
Default	_cFornece	:= ""
Default	_cLoja		:= ""

/*Regras para apuração de valores no MIX:
1- ZL8_MIX/ZLF_ENTMIX -> indica quais eventos irão compor o valor do MIX, seja crédito ou débito. A única exceção são os impostos que estarão com N e serão apurados à parte
2- ZLF_TP_MIX -> L-indica eventos de produtores e F-Fretistas. Seria o mesmo que filtrar por 'P%' ou 'G%'. Como nos setores e linhas se analisa os custos incluindo os eventos
dos fretistas, esse filtro não deve ser utilizado.
3- A query que retorna as colunas a serem exibidas não está relacionada aos eventos que compõe o custo. Isso é necessário pois existem vários eventos de crédito e débito que 
não fazem parte do custo, como adiatamentos, empréstimos e outros. Terei eventos creditando e/ou debitado os valores no mix e isso não envolve custo.
*/
If Empty(_cBonif)
	MsgAlert("Parâmetro LT_CODBON não está preenchido! Verifique o parâmetro que deve estar preenchido com o código da Bonificação de Leite.","AGLT02014")
EndIf

If _lAgrupa
	_cCampos := "%ZL7_COD%"
Else
	_cCampos := "%ZL8_COD%"
EndIf

If _cTab $ "TRBS/TRBL/TRBP"
	If _cTab == "TRBS"//Setores
		_cFil2ZLD := "% AND ZLD_SETOR IN "+ _cFilSet + " %"
		_cFil2ZLF := "% AND ZLF_SETOR IN "+ _cFilSet + " %"
		_cFilVolTo := _cFil2ZLD
		_cFilZLD := "% AND ZLD_SETOR = COD%"
		_cFilZLF := "% AND ZLF_SETOR = COD%"
		_cCampZLD := "% COD, %"
		_cCampZLF := "% COD, %"
		_cCampos2 := "% COD, (SELECT ZL2_DESCRI FROM "+RetSqlName("ZL2")+" WHERE D_E_L_E_T_ = ' ' AND ZL2_FILIAL = FILIAL AND ZL2_COD = COD) DESCRI, SUM(VOLUME) VOLUME,%"
		_cCampos3 := "% COD, (SELECT ZL2_DESCRI FROM "+RetSqlName("ZL2")+" WHERE D_E_L_E_T_ = ' ' AND ZL2_FILIAL = ZLF_FILIAL AND ZL2_COD = ZLF_SETOR) DESCRI,%"
		_cGroup := "%COD%"
	ElseIf _cTab == "TRBL"//Linhas
		_cFil2ZLD := "% "
		_cFil2ZLF := "% "
		_cLinha := U_LisLinha(.F.,_cSetor)
		If !Empty(_cLinha)
			_cFil2ZLD += " AND ZLD_LINROT IN "+ FormatIn(_cLinha,";")
			_cFil2ZLF += " AND ZLF_LINROT IN "+ FormatIn(_cLinha,";")
		EndIf
		_cFilVolTo := _cFil2ZLD + " AND ZLD_FILIAL = FILIAL AND ZLD_SETOR = SETOR %"
		_cFil2ZLD += " AND ZLD_FILIAL = '"+_cFilial+"' AND ZLD_SETOR = '"+_cSetor+"' %"
		_cFil2ZLF += " AND ZLF_FILIAL = '"+_cFilial+"' AND ZLF_SETOR = '"+_cSetor+"' %"
		_cFilZLD := "% AND ZLD_SETOR = SETOR AND ZLD_LINROT = COD%"
		_cFilZLF := "% AND ZLF_SETOR = SETOR AND ZLF_LINROT = COD%"
		_cCampZLD := "% SETOR, ZLD_LINROT COD, %"
		_cCampZLF := "% SETOR, ZLF_LINROT COD, %"
		_cCampos2 := "% SETOR, COD, (SELECT ZL3_DESCRI FROM "+RetSqlName("ZL3")+" WHERE D_E_L_E_T_ = ' ' AND ZL3_FILIAL = FILIAL AND ZL3_COD = COD) DESCRI, SUM(VOLUME) VOLUME,%"
		_cCampos3 := "% SETOR, ZLF_LINROT COD, (SELECT ZL3_DESCRI FROM "+RetSqlName("ZL3")+" WHERE D_E_L_E_T_ = ' ' AND ZL3_FILIAL = ZLF_FILIAL AND ZL3_COD = ZLF_LINROT) DESCRI, %"
		_cGroupZLD := "%, ZLD_LINROT %"
		_cGroupZLF := "%, ZLF_LINROT %"
		_cGroup := "%SETOR, COD%"
	ElseIf _cTab == "TRBP"//Produtores
		_cFil2ZLD := "% AND A.D_E_L_E_T_ = ' ' AND A2_COD = ZLD_RETIRO AND A2_LOJA = ZLD_RETILJ AND ZLD_FILIAL = '"+_cFilial+"' AND ZLD_SETOR = '"+_cSetor+"' AND ZLD_LINROT = '"+_cLinha+"' AND ZLD_RETIRO <> ' ' AND ZLD_RETILJ <> ' '%"
		_cFil2ZLF := "% AND A.D_E_L_E_T_ = ' ' AND A2_COD = ZLF_RETIRO AND A2_LOJA = ZLF_RETILJ AND ZLF_FILIAL = '"+_cFilial+"' AND ZLF_SETOR = '"+_cSetor+"' AND ZLF_LINROT = '"+_cLinha+"' AND ZLF_RETIRO LIKE 'P%'%"
		_cFilVolTo := "% AND  ZLD_FILIAL = FILIAL AND ZLD_SETOR = SETOR AND ZLD_LINROT = LINHA %"
		_cFilZLD := "% AND ZLD_SETOR = SETOR AND ZLD_LINROT = LINHA AND ZLD_RETIRO = COD AND ZLD_RETILJ = LOJA%"
		_cFilZLF := "% AND ZLF_SETOR = SETOR AND ZLF_LINROT = LINHA AND ZLF_RETIRO = COD AND ZLF_RETILJ = LOJA%"
		_cCampZLD := "% SETOR, ZLD_LINROT LINHA, ZLD_RETIRO COD, ZLD_RETILJ LOJA, A2_NOME DESCRI, %"
		_cCampZLF := "% SETOR, ZLF_LINROT LINHA, ZLF_RETIRO COD, ZLF_RETILJ LOJA, A2_NOME DESCRI, %"
		_cCampos2 := "% SETOR, LINHA, COD, LOJA, DESCRI, SUM(VOLUME) VOLUME,%"
		_cCampos3 := "% SETOR, ZLF_LINROT LINHA, ZLF_RETIRO COD, ZLF_RETILJ LOJA, A2_NOME DESCRI, %"
		_cTable := "%, " + RetSqlName("SA2") + " A %"
		_cGroupZLD := "%, ZLD_LINROT, ZLD_RETIRO, ZLD_RETILJ, A2_NOME%"
		_cGroupZLF := "%, ZLF_LINROT, ZLF_RETIRO, ZLF_RETILJ, A2_NOME%"
		_cGroup := "%SETOR, LINHA, COD, LOJA, DESCRI %"
		_cOrder := "%, LOJA%"
	EndIf
	BeginSql alias _cAlias
		SELECT FILIAL, %exp:_cCampos2%
			(SELECT NVL(SUM(ZLD_QTDBOM),0) 
				FROM %Table:ZLD% ZLD
				WHERE ZLD.D_E_L_E_T_ = ' '
				%exp:_cFilVolTo%
				AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%) VOLTOT,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
				FROM %Table:ZLF% ZLF
				WHERE ZLF.D_E_L_E_T_ = ' '
				AND ZLF_FILIAL = FILIAL
				%exp:_cFilZLF%
				AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
				AND ZLF_TP_MIX = 'L'
				AND ZLF_ENTMIX = 'S'
				AND ZLF_DEBCRE = 'C') TOT_CRED,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
				FROM %Table:ZLF% ZLF
				WHERE ZLF.D_E_L_E_T_ = ' '
				AND ZLF_FILIAL = FILIAL
				%exp:_cFilZLF%
				AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
				AND ZLF_TP_MIX = 'L'
				AND ZLF_ENTMIX = 'S'
				AND ZLF_DEBCRE = 'D') TOT_DEB,
			(SELECT COUNT(1) FROM (SELECT ZLD_RETIRO, ZLD_RETILJ
						FROM %Table:ZLD% ZLD
						WHERE D_E_L_E_T_ = ' '
						AND ZLD_RETIRO <> ' '
						AND ZLD_FILIAL = FILIAL
						%exp:_cFilZLD%
						AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
						GROUP BY ZLD_RETIRO, ZLD_RETILJ)) QTD_PRD, ' ' EVENTO, 
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
				FROM %Table:ZLF% ZLF
				WHERE ZLF.D_E_L_E_T_ = ' '
				AND ZLF_FILIAL = FILIAL
				%exp:_cFilZLF%
				AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
				AND ZLF_ENTMIX = 'S') VALOR,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
				FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
				WHERE ZLF.D_E_L_E_T_ = ' '
				AND ZL8.D_E_L_E_T_ = ' '
				AND ZLF_FILIAL = ZL8_FILIAL
				AND ZLF_EVENTO = ZL8_COD
				AND ZLF_FILIAL = FILIAL
				%exp:_cFilZLF%
				AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
				AND ZLF_TP_MIX = 'L'
				AND ZL8_GRUPO = '000007') IMP,
			(SELECT Case
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'ABERTO'
				WHEN FECHADO = 0 AND ABERTO = 1 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'ABERTO'
				WHEN FECHADO = 1 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'FECHADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 1 AND BLOQUEADO = 0 THEN 'EFETIVADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 1 THEN 'BLOQUEADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 1 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'APROVADO'
				WHEN FECHADO = 1 AND (ABERTO = 1 OR PREPARADO = 1 OR EFETIVADO = 1 OR BLOQUEADO = 1) THEN 'PARC.FECHADO' 
				Else 'PARCIAL' END STATUS 
			FROM (SELECT ZLF_STATUS FROM %Table:ZLF%
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			%exp:_cFilZLF%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			GROUP BY ZLF_STATUS)
			PIVOT (COUNT(ZLF_STATUS) For ZLF_STATUS IN('A' ABERTO,'P' PREPARADO,'E' EFETIVADO,'F' FECHADO,'B' BLOQUEADO))) STATUS
		FROM (SELECT ZLD_FILIAL FILIAL, ZLD_SETOR %exp:_cCampZLD% SUM(ZLD_QTDBOM) VOLUME
				FROM %Table:ZLD% ZLD %exp:_cTable%
				WHERE ZLD.D_E_L_E_T_ = ' '
				%exp:_cFil2ZLD%
				AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
				GROUP BY ZLD_FILIAL, ZLD_SETOR %exp:_cGroupZLD%
				UNION
				SELECT ZLF_FILIAL FILIAL, ZLF_SETOR %exp:_cCampZLF% 0 VOLUME
				FROM %Table:ZLF% ZLF %exp:_cTable%
				WHERE ZLF.D_E_L_E_T_ = ' '
				%exp:_cFil2ZLF%
				AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
				GROUP BY ZLF_FILIAL, ZLF_SETOR %exp:_cGroupZLF%)
		GROUP BY FILIAL, %exp:_cGroup%
		UNION
		SELECT ZLF_FILIAL FILIAL, ZLF_SETOR %exp:_cCampos3% 0 VOLUME, 0 VOLTOT, 0 TOT_CRE, 0 TOT_DEB, 0 QTD_PRD, %exp:_cCampos% EVENTO,
		 NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0) VALOR, 0 IMP, ' ' STATUS
		FROM %Table:ZLF% ZLF %exp:_cTable%, %Table:ZL8% ZL8, %Table:ZL7% ZL7
		WHERE ZLF.D_E_L_E_T_ = ' '
		AND ZL7.D_E_L_E_T_ = ' '
		AND ZL8.D_E_L_E_T_ = ' '
		AND ZLF_FILIAL = ZL8_FILIAL
		AND ZLF_EVENTO = ZL8_COD
		AND ZL7.ZL7_COD = ZL8.ZL8_GRUPO
		AND ZLF_ENTMIX = 'S'
		%exp:_cFil2ZLF%
		AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
		GROUP BY ZLF_FILIAL, ZLF_SETOR %exp:_cGroupZLF%, %exp:_cCampos%
		ORDER BY COD %exp:_cOrder%, EVENTO
	EndSql
ElseIf _cTab == "TRBF"//Fretista
	BeginSql alias _cAlias
		SELECT FILIAL, COD, LOJA, DESCRI, SUM(VOLUME) VOLUME,
			(SELECT NVL(SUM(ZLD_QTDBOM), 0)
			FROM %Table:ZLD% ZLD
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND ZLD_FILIAL = FILIAL
			AND ZLD_SETOR = SETOR
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%) VOLTOT,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
			FROM %Table:ZLF% ZLF
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_ENTMIX = 'S'
			AND ZLF_DEBCRE = 'C') TOT_CRED,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
			FROM %Table:ZLF% ZLF
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_DEBCRE = 'D') TOT_DEB,  ' ' EVENTO, 0 VALOR,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = ZL8_FILIAL
			AND ZLF_EVENTO = ZL8_COD
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZL8_GRUPO = '000007') IMP,
			(SELECT Case
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'ABERTO'
				WHEN FECHADO = 0 AND ABERTO = 1 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'ABERTO'
				WHEN FECHADO = 1 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'FECHADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 1 AND BLOQUEADO = 0 THEN 'EFETIVADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 1 THEN 'BLOQUEADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 1 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'APROVADO'
				WHEN FECHADO = 1 AND (ABERTO = 1 OR PREPARADO = 1 OR EFETIVADO = 1 OR BLOQUEADO = 1) THEN 'PARC.FECHADO'
				Else 'PARCIAL' END STATUS
			FROM (SELECT ZLF_STATUS FROM %Table:ZLF%
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			GROUP BY ZLF_STATUS)
			PIVOT (COUNT(ZLF_STATUS) For ZLF_STATUS IN('A' ABERTO,'P' PREPARADO,'E' EFETIVADO,'F' FECHADO,'B' BLOQUEADO))) STATUS
			FROM (SELECT ZLD_FILIAL FILIAL, ZLD_SETOR SETOR, ZLD_FRETIS COD, ZLD_LJFRET LOJA, A2_NOME DESCRI, SUM(ZLD_QTDBOM) VOLUME
			FROM %Table:ZLD% ZLD, %Table:SA2% SA2
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND A2_COD = ZLD_FRETIS
			AND A2_LOJA = ZLD_LJFRET
			AND ZLD_FILIAL = %exp:_cFilial%
			AND ZLD_SETOR = %exp:_cSetor%
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
			GROUP BY ZLD_FILIAL, ZLD_SETOR, ZLD_FRETIS, ZLD_LJFRET, A2_NOME
			UNION
			SELECT ZLF_FILIAL FILIAL, ZLF_SETOR SETOR, ZLF_A2COD COD, ZLF_A2LOJA LOJA, A2_NOME DESCRI, 0 VOLUME
			FROM %Table:ZLF% ZLF, %Table:SA2% SA2
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND A2_COD = ZLF_A2COD
			AND A2_LOJA = ZLF_A2LOJA
			AND ZLF_FILIAL = %exp:_cFilial%
			AND ZLF_SETOR = %exp:_cSetor%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_A2COD LIKE 'G%'
			GROUP BY ZLF_FILIAL, ZLF_SETOR, ZLF_A2COD, ZLF_A2LOJA, A2_NOME)
			GROUP BY FILIAL, SETOR, COD, LOJA, DESCRI
			UNION
			SELECT ZLF_FILIAL FILIAL, ZLF_A2COD COD, ZLF_A2LOJA LOJA, A2_NOME DESCRI, 0 VOLUME, 0 VOLTOT, 0 TOT_CRE, 0 TOT_DEB, %exp:_cCampos% EVENTO,
			NVL(SUM(Case WHEN ZL8.ZL8_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0) VALOR, 0 IMP, ' ' STATUS
			FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL8% ZL8, %Table:ZL7% ZL7
			WHERE SA2.D_E_L_E_T_ = ' '
			AND ZLF.D_E_L_E_T_ = ' '
			AND ZL7.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND ZLF_A2COD = A2_COD
			AND ZLF_A2LOJA = A2_LOJA
			AND ZLF_FILIAL = ZL8_FILIAL
			AND ZLF_EVENTO = ZL8_COD
			AND ZL7.ZL7_COD = ZL8.ZL8_GRUPO
			AND ZLF_FILIAL = %exp:_cFilial%
			AND ZLF_SETOR = %exp:_cSetor%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_A2COD LIKE 'G%'
			GROUP BY ZLF_FILIAL, ZLF_SETOR, ZLF_A2COD, ZLF_A2LOJA, A2_NOME, %exp:_cCampos%
			ORDER BY COD, LOJA, EVENTO
	EndSql
ElseIf _cTab == "TRBG"//Detalhe Fretista
	_cLinha := U_LisLinha(.F.,_cSetor)
	If !Empty(_cLinha)
		_cFilZLD := "% AND ZLD_LINROT IN "+ FormatIn(_cLinha,";") + " %"
		_cFilZLF := "% AND ZLF_LINROT IN "+ FormatIn(_cLinha,";") + " %"
	EndIf
	BeginSql alias _cAlias
		SELECT FILIAL, LINHA, COD, LOJA, DESCRI, SUM(VOLUME) VOLUME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT,
			(SELECT NVL(SUM(ZLD_QTDBOM), 0)
			FROM %Table:ZLD% ZLD
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND ZLD_FILIAL = FILIAL
			AND ZLD_SETOR = SETOR
			AND ZLD_FRETIS = COD
            AND ZLD_LJFRET = LOJA
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%) VOLTOT,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
			FROM %Table:ZLF% ZLF
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_LINROT = LINHA
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_DEBCRE = 'C') TOT_CRED,
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
			FROM %Table:ZLF% ZLF
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_LINROT = LINHA
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_DEBCRE = 'D') TOT_DEB,  ' ' EVENTO, 0 VALOR, 
			(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = ZL8_FILIAL
			AND ZLF_EVENTO = ZL8_COD
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_LINROT = LINHA
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZL8_GRUPO = '000007') IMP,
			(SELECT NVL(SUM(KM),0) KM FROM(SELECT ZLD_TICKET, ZLD_KM KM
			FROM %Table:ZLD% ZLD
			WHERE ZLD.D_E_L_E_T_ = ' ' 
			AND ZLD_FILIAL = FILIAL
			AND ZLD_SETOR  = SETOR
			AND ZLD_LINROT = LINHA
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
			AND ZLD.ZLD_KM > 0 
			AND ZLD_FRETIS = COD
			AND ZLD_LJFRET = LOJA
			GROUP BY ZLD.ZLD_TICKET, ZLD.ZLD_CODREC, ZLD.ZLD_KM
			) TAB) KMROD,
			(SELECT COUNT(1) QTD FROM (SELECT ZLD_DTCOLE
			FROM %Table:ZLD% ZLD
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND ZLD_FILIAL = FILIAL
			AND ZLD_FRETIS = COD
			AND ZLD_LJFRET = LOJA
			AND ZLD_SETOR = SETOR
			AND ZLD_LINROT = LINHA
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
			GROUP BY ZLD_DTCOLE)) DIASV,
			(SELECT Case
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'ABERTO'
				WHEN FECHADO = 0 AND ABERTO = 1 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'ABERTO'
				WHEN FECHADO = 1 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'FECHADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 1 AND BLOQUEADO = 0 THEN 'EFETIVADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 0 AND EFETIVADO = 0 AND BLOQUEADO = 1 THEN 'BLOQUEADO'
				WHEN FECHADO = 0 AND ABERTO = 0 AND PREPARADO = 1 AND EFETIVADO = 0 AND BLOQUEADO = 0 THEN 'APROVADO'
				WHEN FECHADO = 1 AND (ABERTO = 1 OR PREPARADO = 1 OR EFETIVADO = 1 OR BLOQUEADO = 1) THEN 'PARC.FECHADO' 
				Else 'PARCIAL' END STATUS
			FROM (SELECT ZLF_STATUS FROM %Table:ZLF%
			WHERE D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = FILIAL
			AND ZLF_SETOR = SETOR
			AND ZLF_LINROT = LINHA
			AND ZLF_A2COD = COD
			AND ZLF_A2LOJA = LOJA
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			GROUP BY ZLF_STATUS)
			PIVOT (COUNT(ZLF_STATUS) For ZLF_STATUS IN('A' ABERTO,'P' PREPARADO,'E' EFETIVADO,'F' FECHADO,'B' BLOQUEADO))) STATUS
			FROM (SELECT ZLD_FILIAL FILIAL, ZLD_SETOR SETOR, ZLD_LINROT LINHA, ZLD_FRETIS COD, ZLD_LJFRET LOJA, A2_NOME DESCRI, SUM(ZLD_QTDBOM) VOLUME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT
			FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL3% ZL3
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND ZL3.D_E_L_E_T_ = ' '
			%exp:_cFilZLD%
			AND ZLD_FILIAL = ZL3_FILIAL
			AND ZLD_LINROT = ZL3_COD
			AND A2_COD = ZLD_FRETIS
			AND A2_LOJA = ZLD_LJFRET
			AND ZLD_FILIAL = %exp:_cFilial%
			AND ZLD_SETOR = %exp:_cSetor%
			AND ZLD_FRETIS = %exp:_cFornece%
			AND ZLD_LJFRET = %exp:_cLoja%
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
			GROUP BY ZLD_FILIAL, ZLD_SETOR, ZLD_LINROT, ZLD_FRETIS, ZLD_LJFRET, A2_NOME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT
			UNION
			SELECT ZLF_FILIAL FILIAL, ZLF_SETOR SETOR, ZLF_LINROT LINHA, ZLF_A2COD COD, ZLF_A2LOJA LOJA, A2_NOME DESCRI, 0 VOLUME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT
			FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL3% ZL3
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND ZL3.D_E_L_E_T_ = ' '
			%exp:_cFilZLF%
			AND ZLF_FILIAL = ZL3_FILIAL
			AND ZLF_LINROT = ZL3_COD
			AND A2_COD = ZLF_A2COD
			AND A2_LOJA = ZLF_A2LOJA
			AND ZLF_FILIAL = %exp:_cFilial%
			AND ZLF_SETOR = %exp:_cSetor%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_A2COD = %exp:_cFornece%
			AND ZLF_A2LOJA = %exp:_cLoja%
			GROUP BY ZLF_FILIAL, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA, A2_NOME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT)
			GROUP BY FILIAL, SETOR, LINHA, COD, LOJA, DESCRI, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT
			UNION
			SELECT ZLF_FILIAL FILIAL, ZLF_LINROT LINHA, ZLF_A2COD COD, ZLF_A2LOJA LOJA, A2_NOME DESCRI, 0 VOLUME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT, 0 VOLTOT, 0 TOT_CRE, 0 TOT_DEB, %exp:_cCampos% EVENTO,
			NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0) VALOR, 0 IMP, 0 KMROD, 0 DIASV, ' ' STATUS
			FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL8% ZL8, %Table:ZL7% ZL7, %Table:ZL3% ZL3
			WHERE SA2.D_E_L_E_T_ = ' '
			AND ZLF.D_E_L_E_T_ = ' '
			AND ZL7.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND ZL3.D_E_L_E_T_ = ' '
			%exp:_cFilZLF%
			AND ZLF_FILIAL = ZL3_FILIAL
			AND ZLF_LINROT = ZL3_COD
			AND ZLF_A2COD = A2_COD
			AND ZLF_A2LOJA = A2_LOJA
			AND ZLF_FILIAL = ZL8_FILIAL
			AND ZLF_EVENTO = ZL8_COD
			AND ZL7.ZL7_COD = ZL8.ZL8_GRUPO
			AND ZLF_FILIAL = %exp:_cFilial%
			AND ZLF_SETOR = %exp:_cSetor%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_A2COD = %exp:_cFornece%
			AND ZLF_A2LOJA = %exp:_cLoja%
			GROUP BY ZLF_FILIAL, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA, A2_NOME, ZL3_KM, ZL3_FRMPG, ZL3_VLRFRT, %exp:_cCampos%
			ORDER BY COD, LOJA, LINHA, EVENTO
	EndSql
EndIf

// Gravando resultado da consulta na tabela temporaria
While (_cAlias)->( !Eof() )
	If Empty((_cAlias)->EVENTO)
		(_cTab)->(RecLock(_cTab,.T.))
		(_cTab)->FILIAL	:= (_cAlias)->FILIAL
		(_cTab)->COD := (_cAlias)->COD
		If _cTab $ "TRBP/TRBF/TRBG"
			(_cTab)->LOJA := (_cAlias)->LOJA
		EndIf	
		(_cTab)->DESCRI	:= (_cAlias)->DESCRI
		(_cTab)->VOL := (_cAlias)->VOLUME
		(_cTab)->POR := (_cAlias)->VOLUME*100/(_cAlias)->VOLTOT
		If _cTab $ "TRBS/TRBL"
			(_cTab)->NUMPRO := (_cAlias)->QTD_PRD
		EndIf
		If _cTab == "TRBG"
			(_cTab)->LINHA := (_cAlias)->LINHA
			(_cTab)->KMROD := (_cAlias)->KMROD
			(_cTab)->DIASV := (_cAlias)->DIASV
			(_cTab)->KMPAD :=(_cAlias)->ZL3_KM
			(_cTab)->VLRKM := IIf((_cAlias)->ZL3_FRMPG == "K",(_cAlias)->ZL3_VLRFRT,0)
			(_cTab)->KMDIA := Round((_cAlias)->KMROD/(_cAlias)->DIASV,2) //kmRodado divido por Dias/Viagens
		EndIf
		(_cTab)->MEDVDI	:= (_cAlias)->VOLUME / _nDiasMix // Volume diaria por Setor
		If _cTab$"TRBS/TRBL/TRBP"
			(_cTab)->VLIQFR := (_cAlias)->VALOR
			(_cTab)->LLIQFR := (_cAlias)->VALOR/(_cAlias)->VOLUME
		EndIf
		(_cTab)->VBRUTO	:= (_cAlias)->TOT_CRED
		(_cTab)->VLIQCI	:= (_cAlias)->(TOT_CRED+TOT_DEB+IMP)
		(_cTab)->VLIQSI := (_cAlias)->(TOT_CRED+TOT_DEB)
		(_cTab)->VIMP := (_cAlias)->IMP
		(_cTab)->LBRUTO	:= (_cAlias)->TOT_CRED/(_cAlias)->VOLUME
		(_cTab)->LLIQCI	:= (_cAlias)->(TOT_CRED+TOT_DEB+IMP)/(_cAlias)->VOLUME
		(_cTab)->LLIQSI	:= (_cAlias)->(TOT_CRED+TOT_DEB)/(_cAlias)->VOLUME
		(_cTab)->STATUS := Capital((_cAlias)->STATUS)
	Else
		(_cTab)->(RecLock(_cTab,.F.))
	EndIf

	If Empty((_cAlias)->EVENTO)// Grava Volume e Num Pro

	ElseIf !AllTrim((_cAlias)->EVENTO) == "EVENTO"//Soma valor dos eventos
		//No detalhe do Fretista não deve mostrar o valor por litro e sim o total
		(_cTab)->&("E"+(_cAlias)->EVENTO) := NoRound((_cAlias)->VALOR,4)/(_cTab)->VOL//trunco a informação porque o banco está entregando um valor no formato X,XXXX000000001
		(_cTab)->&("T"+(_cAlias)->EVENTO) := (_cAlias)->VALOR
	EndIf		
	
	(_cTab)->(MSUnLock())
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->(DBCloseArea())

//Grava totalizadores. Não é possível realizar médias (AVG) nos valores unitários por gerar divergência de valores por causa dos arredondamentos
_cCampos := ""
//Trato todas as divisões por volume para dividir por 1 caso não tenha volume. Passou a existir transportadores que a viagem fica sem volume.
For _nX:= 1 To Len(_aStruct1)
	If _aStruct1[_nX][1] $ "VOL/NUMPRO/MEDVDI/VLIQFR/VBRUTO/VLIQCI/VLIQSI/VIMP" .Or. SubStr(_aStruct1[_nX][1],1,1) == "T"
		_cCampos += ", SUM("+_aStruct1[_nX][1]+") "+ _aStruct1[_nX][1]
	ElseIf _aStruct1[_nX][1] $ "LLIQFR/LBRUTO/LLIQCI/LLIQSI"
		_cCampos += ", SUM(V"+SubStr(_aStruct1[_nX][1],2,5)+") /DECODE(SUM(VOL),0,1,SUM(VOL)) "+ _aStruct1[_nX][1]
	ElseIf _aStruct1[_nX][1] $ "POR"
		_cCampos += ", SUM(VOL)*100/DECODE(SUM(VOL),0,1,SUM(VOL)) "+ _aStruct1[_nX][1]//Sim, conta idiota e sempre será 100%, mas se somar o valor da coluna, geralmente tem erro de arredondamento gerando 99,9999
	ElseIf SubStr(_aStruct1[_nX][1],1,1) == "E" //No Detalhe do Fretista o valor não é por litro, logo, devo somar ao invés de fazer média
		_cCampos += ", SUM(T"+SubStr(_aStruct1[_nX][1],2,6)+") "+"/DECODE(SUM(VOL),0,1,SUM(VOL)) "+ _aStruct1[_nX][1]
	ElseIf _aStruct1[_nX][2] == "N"
		_cCampos += ", SUM("+_aStruct1[_nX][1]+") "+ _aStruct1[_nX][1]
	EndIf
Next _nX
_cCampos := "% "+ SubStr(_cCampos,2,Len(_cCampos)) + " %"
_cFiltro := "% " +&("_oTemp"+_cTab):GetRealName() + " %"

_cAlias := GetNextAlias()
BeginSql Alias _cAlias
	SELECT %exp:_cCampos% FROM %exp:_cFiltro%
EndSql
RecLock(_cTab,.T.)

For _nX:= 1 to Len(_aStruct1)
	If _aStruct1[_nX][1] == "DESCRI"
		&(_cTab+"->"+_aStruct1[_nX][1]) := "Total Geral"
	ElseIf _aStruct1[_nX][2] == "N"
		&(_cTab+"->"+_aStruct1[_nX][1]) := &((_cAlias)+"->"+_aStruct1[_nX][1])
	EndIf
Next _nX

MSUnLock()
(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: UpdateTab
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Atualiza os valores da tabela temporária, normalmente após algum processo que altera seus valores
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

Local _aArea := {}
Local _lExistTMP := (Select (_cTab) > 0)

If _lExistTMP
	DBSelectArea(_cTab)
	_aArea := GetArea()//Salvo posicionamento da tela para manter o foco no mesmo registro após o refresh dos dados
	ZAP
	Processa ({||CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja),GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)},"Gravando "+_cTab)
	FWRestArea(_aArea)
Else
	Processa ({||CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja),GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)},"Gravando "+_cTab)
EndIf 

If _cTab=="TRBS"
	oBrowse1:Refresh()
ElseIf _cTab=="TRBL"
	oBrowse2:Refresh()
ElseIf _cTab=="TRBP"
	oBrowse3:Refresh()
ElseIf _cTab=="TRBF"
	oBrowse4:Refresh()
ElseIf _cTab=="TRBG"
	oBrowse5:Refresh()
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT020
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta tela com dados dos Setores
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ShowSetores(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1)

Local _oDlg1	:= Nil
Local _nX		:= 0
Local _cTitulo	:= "Mix "+ZLE->ZLE_COD+" - Setores - Período de "+DToC(ZLE->ZLE_DTINI) +" à "+ DToC(ZLE->ZLE_DTFIM)

//Cria tabela temporaria
CriaTmp(_cTab,_nTipo,.T.,_cFilSet,_aStruct1)
//Grava dados na Tabela temporaria a partir da tabela ZLF
Processa ({||GravaTmp(_cTab,_nTipo,.T.,_cFilSet,_aStruct1)},"Gravando "+_cTab)

// Cria Browse Setor
DEFINE MSDIALOG _oDlg1 FROM 00,00 TO _aSize[6],_aSize[5] TITLE _cTitulo+_cTitOpcao PIXEL OF oMainWnd
	oBrowse1 := TCBrowse():New( 00 , 00 , aPosObj1[1][3] , (aPosObj1[1,4]+20) ,,,, _oDlg1 ,,,,,,,,,,,,,, .T. )
	oBrowse1 := oBrowse1:GetBrowse()
	oBrowse1:lLineDrag	:= .T.
	For _nX:=1 To Len(_aStruct1)
		If (.T./*_lAgrupa*/ .And. SubStr(_aStruct1[_nX][1],1,1) == "T") .Or. !SubStr(_aStruct1[_nX][1],1,1)=="T" //Só exibir a coluna de total quando For agrupar
			oBrowse1:AddColumn(TCColumn():New(_aStruct1[_nX][6],&("{||"+_aStruct1[_nX][1]+"}"),_aStruct1[_nX][5],,,IIf(_aStruct1[_nX][2]=="N","RIGHT","LEFT"),_aStruct1[_nX][7],.F.,.F.,,,,.F.,,))
		EndIf
	Next _nX
	
	oBrowse1:BlDblClick := {||ShowLinhas("TRBL",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,(_cTab)->COD,(_cTab)->DESCRI)}
	
	@aPosObj1[1,4]+22,005 Button "Abrir Setor"	Size 50,10 Action Processa({||ShowLinhas("TRBL",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,(_cTab)->COD,(_cTab)->DESCRI)})		OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,060 Button "Aprovar" 	    Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,(_cTab)->COD,1/*_nAcao*/),UpdateTab(_cTab,_nTipo,.T./*_lAgrupa*/,_cFilSet,_aStruct1)})	OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,115 Button "Efetivar"		Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,(_cTab)->COD,2/*_nAcao*/),UpdateTab(_cTab,_nTipo,.T./*_lAgrupa*/,_cFilSet,_aStruct1)})	OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,170 Button "Gerar Eventos"Size 50,10 Action Processa({||GerEvts(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL)})  OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,225 Button "Transportador"Size 50,10 Action Processa({||ShowFrt("TRBF",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,(_cTab)->COD,(_cTab)->DESCRI)})			OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,280 Button "Totais Setor"	Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,.T./*_lAgrupa*/,_cFilSet,_cTitOpcao,_aStruct1,.F./*_lEdita*/,(_cTab)->FILIAL,(_cTab)->COD)})	OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,335 Button "Classif.Produtor"Size 50,10 Action Processa({||U_RGLT043()})						OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,390 Button "Imprimir"	 	Size 50,10 Action Processa({||U_RGLT027(&("_oTemp"+_cTab):GetRealName(),_aStruct1,_cTitulo)})				OF _oDlg1 PIXEL
	@aPosObj1[1,4]+22,445 Button "Fechar"	 	Size 50,10 Action _oDlg1:End()OF _oDlg1 PIXEL
	
ACTIVATE MSDIALOG _oDlg1 Centered

&("_oTemp"+_cTab+":Delete()")

Return

/*
===============================================================================================================================
Programa----------: ShowLinhas
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta tela com dados das Linhas
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cDescri
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ShowLinhas(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cDescri)

Local _oDlg2	:= Nil
Local _nX		:= 0
Local _cTitulo	:= "Mix "+ZLE->ZLE_COD+">Setor: "+_cSetor+"-"+AllTrim(_cDescri)+" - Linhas - Período de "+DToC(ZLE->ZLE_DTINI) +" à "+ DToC(ZLE->ZLE_DTFIM)

If Empty(_cFilial)//Se estiver vazio é porque está posicionado no totalizador, logo, não faz nada.
     Return
EndIf

//Cria tabela temporaria
CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor)
//Grava dados na tabela temporaria
Processa ({||GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor)},"Gravando "+_cTab)

// Cria Browse Linha
DEFINE MSDIALOG _oDlg2 FROM 00,00 TO _aSize[6],_aSize[5] TITLE _cTitulo+_cTitOpcao PIXEL OF oMainWnd
	oBrowse2 := TCBrowse():New( 00 , 00 , aPosObj1[1][3] , (aPosObj1[1,4]+20) ,,,, _oDlg2 ,,,,,,,,,,,,,, .T. )
	oBrowse2 := oBrowse2:GetBrowse()
	oBrowse2:lLineDrag	:= .T.
	For _nX:=1 To Len(_aStruct1)
		If (_lAgrupa .And. SubStr(_aStruct1[_nX][1],1,1) == "T") .Or. !SubStr(_aStruct1[_nX][1],1,1)=="T" //Só exibir a coluna de total quando For agrupar
			oBrowse2:AddColumn(TCColumn():New(_aStruct1[_nX][6],&("{||"+_aStruct1[_nX][1]+"}"),_aStruct1[_nX][5],,,IIf(_aStruct1[_nX][2]=="N","RIGHT","LEFT"),_aStruct1[_nX][7],.F.,.F.,,,,.F.,,))
		EndIf
	Next _nX
	
	oBrowse2:BlDblClick := {||ShowProdutor("TRBP",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor,(_cTab)->COD,(_cTab)->DESCRI)}

	@aPosObj1[1,4]+22,005 Button "Abrir Linha"	Size 50,10 Action Processa({||ShowProdutor("TRBP",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor,(_cTab)->COD,(_cTab)->DESCRI)})			OF _oDlg2 PIXEL
	@aPosObj1[1,4]+22,060 Button "Aprovar"		Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,1/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor)})	OF _oDlg2 PIXEL
	@aPosObj1[1,4]+22,115 Button "Efetivar"		Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,2/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor)})	OF _oDlg2 PIXEL
	@aPosObj1[1,4]+22,170 Button "Gerar Eventos"Size 50,10 Action Processa({||GerEvts(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor)})	OF _oDlg2 PIXEL
	@aPosObj1[1,4]+22,225 Button "Totais Linha"	Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.F./*_lEdita*/,_cFilial,_cSetor,(_cTab)->COD)})						OF _oDlg2 PIXEL
	@aPosObj1[1,4]+22,280 Button "Imprimir"		Size 50,10 Action Processa({||U_RGLT027(&("_oTemp"+_cTab):GetRealName(),_aStruct1,_cTitulo)}) 							OF _oDlg2 PIXEL
	@aPosObj1[1,4]+22,335 Button "Fechar"		Size 50,10 Action _oDlg2:End()	 		OF _oDlg2 PIXEL

ACTIVATE MSDIALOG _oDlg2 Centered

&("_oTemp"+_cTab+":Delete()")
//Atualiza nível anterior
UpdateTab("TRBS",_nTipo,.T.,_cFilSet,_aStruct1)

Return

/*
===============================================================================================================================
Programa----------: ShowProdutor
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta tela com dados dos Produtores
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cLinha,_cDescri
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ShowProdutor(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cLinha,_cDescri)

Local _oDlg3	:= Nil
Local _nX		:= 0
Local _cTitulo	:= "Mix "+ZLE->ZLE_COD+">Setor: "+_cSetor+"> Linha: "+_cLinha+"-"+AllTrim(_cDescri)+" - Produtores - Período de "+DToC(ZLE->ZLE_DTINI) +" à "+ DToC(ZLE->ZLE_DTFIM)

If Empty(_cFilial)//Se estiver vazio é porque está posicionado no totalizador, logo, não faz nada.
     Return
EndIf

//Cria tabela temporaria
CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha)
//Grava dados na Tabela temporaria a partir da tabela ZLF
Processa ({||GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha)},"Gravando "+_cTab)

//Cria Browse Produtores
DEFINE MSDIALOG _oDlg3 FROM  00,00 TO _aSize[6],_aSize[5] TITLE _cTitulo+_cTitOpcao PIXEL OF oMainWnd
	oBrowse3:= TCBrowse():New(00,00,aPosObj1[1,3],aPosObj1[1,4]+20,,,,_oDlg3,,,,,,,,,,,,,,.T.)
	oBrowse3:= oBrowse3:GetBrowse()
	oBrowse3:lLineDrag	:= .T.
	For _nX:=1 To Len(_aStruct1)
		If (_lAgrupa .And. SubStr(_aStruct1[_nX][1],1,1) == "T") .Or. !SubStr(_aStruct1[_nX][1],1,1)=="T" //Só exibir a coluna de total quando For agrupar
			oBrowse3:AddColumn(TCColumn():New(_aStruct1[_nX][6],&("{||"+_aStruct1[_nX][1]+"}"),_aStruct1[_nX][5],,,IIf(_aStruct1[_nX][2]=="N","RIGHT","LEFT"),_aStruct1[_nX][7],.F.,.F.,,,,.F.,,))
		EndIf
	Next _nX

	oBrowse3:BLDBLCLICK := {||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.T./*_lEdita*/,(_cTab)->FILIAL,_cSetor,_cLinha,(_cTab)->COD,(_cTab)->LOJA),oBrowse3:Refresh()}

	@aPosObj1[1,4]+22,005 Button "Editar"		Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.T./*_lEdita*/,(_cTab)->FILIAL,_cSetor,_cLinha,(_cTab)->COD,(_cTab)->LOJA)})OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,060 Button "Aprovar" 	    Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,1/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor,_cLinha)})	OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,115 Button "Efetivar"		Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,2/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor,_cLinha)})	OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,170 Button "Gerar Eventos"Size 50,10 Action Processa({||GerEvts(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor,_cLinha)})	OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,225 Button "Totais Produtor"Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.F./*_lEdita*/,_cFilial,_cSetor,_cLinha,(_cTab)->COD,(_cTab)->LOJA)})		OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,280 Button "Pesquisar"	Size 50,10 Action PesqProd(oBrowse3,_cTab)		OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,335 Button "Imprimir"		Size 50,10 Action Processa({|| U_RGLT027(&("_oTemp"+_cTab):GetRealName(),_aStruct1,_cTitulo)})									OF _oDlg3 PIXEL
	@aPosObj1[1,4]+22,390 Button "Fechar"		Size 50,10 Action _oDlg3:End()					OF _oDlg3 PIXEL

ACTIVATE MSDIALOG _oDlg3 Centered

&("_oTemp"+_cTab+":Delete()")
//Atualiza nível anterior
UpdateTab("TRBL",_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha)

Return

/*
===============================================================================================================================
Programa----------: ShowFrt
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta tela com dados dos Fretistas
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cDescri
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ShowFrt(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cDescri)

Local _oDlg4	:= Nil
Local _nX		:= 0
Local _cTitulo	:= "Mix "+ZLE->ZLE_COD+">Setor: "+_cSetor+"-"+AllTrim(_cDescri)+" - Transportadores - Período de "+DToC(ZLE->ZLE_DTINI) +" à "+ DToC(ZLE->ZLE_DTFIM)

If Empty(_cFilial)//Se estiver vazio é porque está posicionado no totalizador, logo, não faz nada.
     Return
EndIf
// Cria tabela temporaria
CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor)
//Grava dados na Tabela temporaria a partir da tabela ZLF
Processa ({||GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor)},"Gravando "+_cTab)

//Cria Browse
DEFINE MSDIALOG _oDlg4 FROM  00,00 TO _aSize[6],_aSize[5] TITLE _cTitulo+_cTitOpcao PIXEL OF oMainWnd
	oBrowse4 := TCBrowse():New(00,00,aPosObj1[1,3],aPosObj1[1,4]+22,,,,_oDlg4,,,,,, , , , , , , , ,.T.)
	oBrowse4 := oBrowse4:GetBrowse()
	oBrowse4:lLineDrag	:= .T.
	For _nX:=1 To Len(_aStruct1)
		If (_lAgrupa .And. SubStr(_aStruct1[_nX][1],1,1) == "T") .Or. !SubStr(_aStruct1[_nX][1],1,1)=="T" //Só exibir a coluna de total quando For agrupar
			oBrowse4:AddColumn(TCColumn():New(_aStruct1[_nX][6],&("{||"+_aStruct1[_nX][1]+"}"),_aStruct1[_nX][5],,,IIf(_aStruct1[_nX][2]=="N","RIGHT","LEFT"),_aStruct1[_nX][7],.F.,.F.,,,,.F.,,))
		EndIf
	Next _nX

	oBrowse4:BLDBLCLICK := {||ShowFDet("TRBG",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor,(_cTab)->COD,(_cTab)->LOJA) }

	@aPosObj1[1,4]+22,005 Button "Detalhar"		Size 50,10 Action Processa({||ShowFDet("TRBG",_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor,(_cTab)->COD,(_cTab)->LOJA)}) 				OF _oDlg4 PIXEL
	@aPosObj1[1,4]+22,060 Button "Aprovar" 	    Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,1/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor)})	OF _oDlg4 PIXEL
	@aPosObj1[1,4]+22,115 Button "Efetivar"		Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,2/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor)})	OF _oDlg4 PIXEL
	@aPosObj1[1,4]+22,170 Button "Gerar Eventos"Size 50,10 Action Processa({||GerEvts(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor)})  	OF _oDlg4 PIXEL
	@aPosObj1[1,4]+22,225 Button "Totais Fretista"Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.F./*_lEdita*/,(_cTab)->FILIAL,_cSetor)}) 						OF _oDlg4 PIXEL
	@aPosObj1[1,4]+22,280 Button "Imprimir"		Size 50,10 Action Processa({||U_RGLT027(&("_oTemp"+_cTab):GetRealName(),_aStruct1,_cTitulo)} ) 							OF _oDlg4 PIXEL
	@aPosObj1[1,4]+22,335 Button "Fechar"		Size 50,10 Action _oDlg4:End()			OF _oDlg4 PIXEL

ACTIVATE MSDIALOG _oDlg4 Centered

&("_oTemp"+_cTab+":Delete()")
//Atualiza nível anterior
updatetab("TRBS",_nTipo,.T.,_cFilSet,_aStruct1)

Return

/*
===============================================================================================================================
Programa----------: ShowFDet
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta tela com dados Detalhados dos Fretistas
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cFornece,_cLoja
Retorno-----------: _lRet
===============================================================================================================================
*/
Static Function ShowFDet(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cFornece,_cLoja)

Local _oDlg5	:= Nil
Local _nX		:= 0
Local _cTitulo	:= "Mix "+ZLE->ZLE_COD+">Setor: "+_cSetor+"> Transportador: "+_cFornece+"-"+_cLoja+" - Transportadores - Período de "+DToC(ZLE->ZLE_DTINI) +" à "+ DToC(ZLE->ZLE_DTFIM)

If Empty(_cFilial)//Se estiver vazio é porque está posicionado no totalizador, logo, não faz nada.
     Return
EndIf
// Cria tabela temporaria
CriaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,/*_cLinha*/,_cFornece,_cLoja)
// Grava dados na Tabela temporaria a partir da tabela ZLF
Processa ({||GravaTmp(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor,/*_cLinha*/,_cFornece,_cLoja)},"Gravando "+_cTab)

//Cria Browse Detalhe Fretista
DEFINE MSDIALOG _oDlg5 FROM  00,00 TO _aSize[6],_aSize[5] TITLE _cTitulo+_cTitOpcao PIXEL OF oMainWnd
	oBrowse5 := TCBrowse():New(00,00,aPosObj1[1,3],aPosObj1[1,4]+22,,,,_oDlg5,,,,,, , , , , , , , ,.T.)
	oBrowse5 := oBrowse5:GetBrowse()
	oBrowse5:lLineDrag	:= .T.
	For _nX:=1 To Len(_aStruct1)
		If (_lAgrupa .And. SubStr(_aStruct1[_nX][1],1,1) == "E") .Or. !SubStr(_aStruct1[_nX][1],1,1)=="E" //Só exibir a coluna de valor por litro quando For agrupar. É o inverso das outras telas
			oBrowse5:AddColumn(TCColumn():New(_aStruct1[_nX][6],&("{||"+_aStruct1[_nX][1]+"}"),_aStruct1[_nX][5],,,IIf(_aStruct1[_nX][2]=="N","RIGHT","LEFT"),_aStruct1[_nX][7],.F.,.F.,,,,.F.,,))
		EndIf
	Next _nX

	oBrowse5:BLDBLCLICK := {||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.T./*_lEdita*/,(_cTab)->FILIAL,_cSetor,(_cTab)->LINHA,(_cTab)->COD,(_cTab)->LOJA),oBrowse5:Refresh()}

	@aPosObj1[1,4]+22,005 Button "Editar"		Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.T./*_lEdita*/,(_cTab)->FILIAL,_cSetor,(_cTab)->LINHA,(_cTab)->COD,(_cTab)->LOJA)})				OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,060 Button "Aprovar" 	    Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,1/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor,/*_Linha*/,_cFornece,_cLoja)})	OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,115 Button "Efetivar"		Size 50,10 Action Processa({||AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,2/*_nAcao*/),UpdateTab(_cTab,_nTipo,_lAgrupa,_cFilSet,_aStruct1,(_cTab)->FILIAL,_cSetor,/*_Linha*/,_cFornece,_cLoja)})	OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,170 Button "Gerar Eventos"Size 50,10 Action Processa({||GerEvts(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,(_cTab)->FILIAL,_cSetor,/*_Linha*/,_cFornece,_cLoja)})	OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,225 Button "Totais Fret.Linha"Size 50,10 Action Processa({||ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,.F./*_lEdita*/,(_cTab)->FILIAL,_cSetor,(_cTab)->LINHA)})									OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,280 Button "Cad. Linha"	Size 50,10 Action Processa({||OpenCad("ZL3",(_cTab)->FILIAL,(_cTab)->LINHA)})  								OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,335 Button "Imprimir"		Size 50,10 Action Processa({||U_RGLT027(&("_oTemp"+_cTab):GetRealName(),_aStruct1,_cTitulo)} ) 				OF _oDlg5 PIXEL
	@aPosObj1[1,4]+22,390 Button "Fechar"		Size 50,10 Action _oDlg5:End()OF _oDlg5 PIXEL

ACTIVATE MSDIALOG _oDlg5 Centered

&("_oTemp"+_cTab+":Delete()")
//Atualiza nível anterior
updatetab("TRBF",_nTipo,_lAgrupa,_cFilSet,_aStruct1,_cFilial,_cSetor)

Return

/*
===============================================================================================================================
Programa----------: ShowTotal
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Exibe Browse com os totais dos eventos no registro posicionado ou possibilita a geração de novos eventos
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_lEdita,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ShowTotal(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_lEdita,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

Local _aArea		:= FWGetArea()
Local _cFiltro		:= "%"
Local _cCampos		:= ""
Local _cGroup		:= ""
Local _cAlias		:= ""
Local _aDados		:={}
Local _oBrowse		:= Nil
Local _oDlg			:= Nil
Local _oSize		:= Nil
Local _cCabec		:= ""
Local _nVol 		:= (_cTab)->VOL
Local _nVlrLiq 		:= IIf(_cTab$"TRBS/TRBL",(_cTab)->LLIQFR,(_cTab)->LLIQCI)
Local _oOK			:= LoadBitmap(GetResources(),"BR_VERDE")
Local _oNO			:= LoadBitmap(GetResources(),"BR_VERMELHO")
Local _cFundesa		:= SuperGetMV("LT_EVEFUND",.F.,"000014")
Local _lPermAlt		:= .F.
Default	_cFilial	:= ""
Default	_cSetor		:= ""
Default	_cLinha		:= ""
Default _cFornece	:= ""
Default _cLoja		:= ""
                                                                                       
If _lEdita .And. ZLU->ZLU_RESMIX <> 'S'
	MsgStop("Usuário atual não está liberado para as rotinas de Manutenção do MIX! Favor entrar em contato com o responsavel do Leite.","AGLT02015")
	Return
EndIf
If _lEdita .And. !(!_lAgrupa .And. _nTipo==2)
	MsgStop("A alteração só pode ser realizada no modo detalhado de Eventos e com a opção de manutenção!","AGLT02016")
    Return
EndIf
If _lEdita .And. cFilAnt != _cFilial
	MsgStop("A Filial atual é diferente da Filial que está indicada no MIX!","AGLT02017")
	Return
EndIf
If _lEdita .And. !AllTrim((_cTab)->STATUS) == "Aberto"
	MsgStop("Não é permitido editar quando o status For diferente de Aberto!","AGLT02018")
	Return
EndIf

If _cTab == "TRBS"
	_cCabec := "Setor: "+_cSetor + " - " +AllTrim((_cTab)->DESCRI)
ElseIf _cTab == "TRBP"
	_cCabec := "Setor: "+_cSetor+"> Linha: "+_cLinha+"> Produtor: "+AllTrim((_cTab)->DESCRI)
ElseIf _cTab == "TRBL"
	_cCabec := "Setor: "+_cSetor+"> Linha: "+_cLinha + " - " +AllTrim((_cTab)->DESCRI)
ElseIf _cTab == "TRBF"
	_cCabec := "Setor: "+_cSetor+"> Fretista: "+AllTrim((_cTab)->DESCRI)
ElseIf _cTab == "TRBG"
	_cCabec := "Setor: "+_cSetor+"> Linha: "+_cLinha+"> Fretista: "+AllTrim((_cTab)->DESCRI)
EndIf

//Retornar todos os eventos conforme telado MIX. Posteriormente será separado o que deve ou não compor o custo simulado.
//No Fretista deve aparecer tudo, independete de entrar ou não no MIX ZL8_MIX = S
If _cTab$"TRBF/TRBG"
	_cFiltro += " AND ZL8_PERTEN IN ('F','T')"
//No Setor e Linha, alguns eventos de Fretista precisam aparecer, então uso o ZL8_MIX para descartar vários Débitos
ElseIf _cTab$"TRBS/TRBL/TRBP"
	_cFiltro += " AND ZL8_MIX = 'S'"
EndIf

If _lEdita
	_cFiltro += "%"
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT ZL8.ZL8_PRIORI PRIORI
		FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
		WHERE ZLF.D_E_L_E_T_ = ' '
		AND ZL8.D_E_L_E_T_ = ' '
		AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
		AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
		AND ZL8.ZL8_COD = ZLF.ZLF_EVENTO
		AND ZLF.ZLF_CODZLE = %exp:ZLE->ZLE_COD%
		AND ZLF.ZLF_SETOR = %exp:_cSetor%
		AND ZLF.ZLF_LINROT = %exp:_cLinha%
		AND ZLF.ZLF_A2COD = %exp:_cFornece%
		AND ZLF.ZLF_A2LOJA = %exp:_cLoja%
		AND ZL8.ZL8_PRIORI = '999'
	EndSql

	If (_cAlias)->( !Eof() ) .And. !Empty( (_cAlias)->PRIORI )
		MsgStop("Não é possível editar a linha! Já foi calculado o Evento [999] de incentivo para a nota. Caso necessário exclua o evento para editar.","AGLT02019")
		(_cAlias)->(DBCloseArea())
		Return
	EndIf

	(_cAlias)->( DBCloseArea() )
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT ZL8_COD EVENTO, ZL8_DESCRI DESCRI, ZL8_ALTERA, ZL8_DEBCRE, ZL8_PERTEN, ZL8_MIX, ZL8_QTDUNI, ZL8_LIMFRT, ZL8_FORMUL, ZL8_MODEDI,
		NVL(SUM(Case WHEN ZL8.ZL8_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0) VALOR
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
			WHERE ZLF.D_E_L_E_T_ (+)= ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND ZL8_FILIAL = %exp:(_cTab)->FILIAL% 
			AND ZLF_FILIAL (+)= ZL8_FILIAL
			AND ZLF_EVENTO (+)= ZL8_COD
			%exp:_cFiltro%
			AND ZLF_SETOR (+)= %exp:_cSetor%
			AND ZLF_LINROT (+)= %exp:_cLinha%
			AND ZLF_A2COD (+)= %exp:_cFornece%
			AND ZLF_A2LOJA (+)= %exp:_cLoja%
			AND ZLF_CODZLE (+)= %exp:ZLE->ZLE_COD%
			GROUP BY ZL8_COD, ZL8_DESCRI, ZL8_ALTERA, ZL8_DEBCRE, ZL8_PERTEN, ZL8_MIX, ZL8_QTDUNI, ZL8_LIMFRT, ZL8_FORMUL, ZL8_MODEDI
			ORDER BY ZL8_DEBCRE, ZL8_COD
	EndSql
Else
	If _lAgrupa
		_cCampos := "% ZL7_COD EVENTO, ZL7_DESCRI DESCRI, ZL8_DEBCRE,' ' ZL8_ALTERA,' ' ZL8_PERTEN, ' ' ZL8_MIX, ' ' ZL8_QTDUNI, ' ' ZL8_LIMFRT, ' ' ZL8_FORMUL%"
		_cGroup := "% ZL7_COD, ZL7_DESCRI, ZL8_DEBCRE %"
	Else
		_cCampos := "% ZL8_COD EVENTO, ZL8_DESCRI DESCRI, ZL8_DEBCRE, ZL8_ALTERA, ZL8_PERTEN, ZL8_MIX, ZL8_QTDUNI, ZL8_LIMFRT, ZL8_FORMUL, ZL8_MODEDI%"
		_cGroup := "% ZL8_COD, ZL8_DESCRI, ZL8_DEBCRE, ZL8_ALTERA, ZL8_PERTEN,ZL8_MIX, ZL8_QTDUNI, ZL8_LIMFRT, ZL8_FORMUL, ZL8_MODEDI %"
	EndIf

	_cFiltro += IIf(!Empty(_cFilial)," AND ZLF_FILIAL = '"+_cFilial+"'"," AND ZLF_SETOR IN "+_cFilSet)
	_cFiltro += IIf(!Empty(_cSetor)," AND ZLF_SETOR = '"+_cSetor+"'","")
	_cFiltro += IIf(!Empty(_cLinha)," AND ZLF_LINROT = '"+_cLinha+"' ","")
	_cFiltro += IIf(!Empty(_cFornece)," AND ZLF_A2COD = '"+ _cFornece + "' AND ZLF_A2LOJA = '"+ _cLoja + "'","")
	_cFiltro += "%"
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT %exp:_cCampos%,
		NVL(SUM(Case WHEN ZL8.ZL8_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0) VALOR
		FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:ZL7% ZL7
		WHERE ZLF.D_E_L_E_T_ = ' '
		AND ZL7.D_E_L_E_T_ = ' '
		AND ZL8.D_E_L_E_T_ = ' '
		AND ZLF_FILIAL = ZL8_FILIAL
		AND ZLF_EVENTO = ZL8_COD
		AND ZL7.ZL7_COD = ZL8.ZL8_GRUPO
		%exp:_cFiltro%
		AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
		GROUP BY %exp:_cGroup%
		ORDER BY ZL8_DEBCRE, EVENTO
	EndSql
EndIf

While !(_cAlias)->(Eof())
	If _lEdita
		If _cTab == "TRBG"
			_lPermAlt := (_cAlias)->ZL8_MODEDI == "S"
		ElseIf _cTab == "TRBP"
			_lPermAlt := (_cAlias)->ZL8_ALTERA == "S" .And.(_cAlias)->ZL8_PERTEN $ "P/T"
		EndIf
	EndIf
	aAdd(_aDados,{_lPermAlt,;
				(_cAlias)->EVENTO,;
				(_cAlias)->DESCRI,;
				(_cAlias)->ZL8_DEBCRE,;
				(_cAlias)->VALOR/(_cTab)->VOL,;
				(_cAlias)->VALOR,;
				(_cAlias)->ZL8_PERTEN,;
				_cTab+'->E'+(_cAlias)->EVENTO,;
				(_cAlias)->ZL8_MIX,;
				(_cAlias)->ZL8_QTDUNI,;
				(_cAlias)->ZL8_LIMFRT,;
				AllTrim((_cAlias)->ZL8_FORMUL)})
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())
If Len(_aDados) > 0

	DEFINE MSDIALOG _oDlg FROM 0,0 TO 580,650 PIXEL TITLE "Totalizador por eventos " +_cTitOpcao
	//Calcula dimensões
	_oSize := FwDefSize():New(.F.,,,_oDlg)
	_oSize:AddObject( "CABECALHO",  100, 05, .T., .T. ) // Totalmente dimensionavel
	_oSize:AddObject( "GETDADOS" ,  100, 95, .T., .T. ) // Totalmente dimensionavel 
	_oSize:AddObject( "RODAPE"   ,  100, 05, .T., .T. ) // Totalmente dimensionavel

	_oSize:lProp 	:= .T. // Proporcional             
	_oSize:aMargins 	:= { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3 
	_oSize:Process() 	   // Dispara os calculos   
	//-- Cabecalho
	@_oSize:GetDimension("CABECALHO","LININI"),_oSize:GetDimension("CABECALHO","COLINI") Say _cCabec Pixel Of _oDlg
	@_oSize:GetDimension("CABECALHO","LININI"),_oSize:GetDimension("GETDADOS","XSIZE") -70 Say "Volume: " + AllTrim(Transform(_nVol,"@E 999,999,999.99")) + " Litros" Pixel Of _oDlg
	_oBrowse := TCBrowse():New(_oSize:GetDimension("GETDADOS","LININI"),_oSize:GetDimension("GETDADOS","COLINI"),_oSize:GetDimension("GETDADOS","XSIZE"),_oSize:GetDimension("GETDADOS","YSIZE"),/*bLine*/,/*aHeaders*/,/*aColSizes*/,/*oWnd*/_oDlg,/*cField*/,/*uValue1*/,/*uValue2*/,/*bChange*/,/*bLDblClick*/{||},/*bRClicked*/,/*oFont*/,/*oCursor*/,/*nClrFore*/,/*nClrBack*/,/*cMsg*/,/*uParam20*/,/*cAlias*/,/*lPixel*/.T.,/*bWhen*/,/*uParam24*/.F.,/*bValid*/,/*lHScroll*/,/*lVScroll*/ )
	_oBrowse:SetArray(_aDados)
	//(cTitulo,bData,cPicture,uParam4,uParam5,cAlinhamento,nLargura,lBitmap,lEdit,uParam10,bValid,uParam12,uParam13,uParam14)
	_oBrowse:AddColumn( TCColumn():New('Edita',			{||IIf(_aDados[_oBrowse:nAt,01],_oOK,_oNO)},,,,"CENTER",,.T.,.F.,,{||},,,))
	_oBrowse:AddColumn( TCColumn():New('Evento',		{||_aDados[_oBrowse:nAt,02]},,,,"LEFT",030,.F.,.F.,,{||},,,))
	_oBrowse:AddColumn( TCColumn():New('Descrição',		{||_aDados[_oBrowse:nAt,03]},,,,"LEFT",100,.F.,.F.,,{||},,,))
	_oBrowse:AddColumn( TCColumn():New('Débito/Crédito',{||_aDados[_oBrowse:nAt,04]},,,,"LEFT",045,.F.,.F.,,{||},,,))
	_oBrowse:AddColumn( TCColumn():New('Valor p/Litro',	{||_aDados[_oBrowse:nAt,05]},"@E 9,999.9999",,,"RIGHT",45,.F.,.F.,,{||},,,))
	_oBrowse:AddColumn( TCColumn():New('Total',			{||_aDados[_oBrowse:nAt,06]},"@E 999,999,999.99",,,"RIGHT",45,.F.,.F.,,{||},,,))
	_oBrowse:bLDblClick	:= {|z,x|IIf(_lEdita .And. _aDados[_oBrowse:nAt,01]== .T. .And. (x==05 .Or. x==06),(lEditCell(_aDados,_oBrowse,IIf(x==5,"@E 999.9999","@E 999,999,999.99"),x),;
						IIf(_lEdita,CalcTot(_cTab,_cSetor,_cLinha,_cFundesa,_oVlrLiq,@_oBrowse,@_nVlrLiq),.T.)),.F.),_oBrowse:Refresh()}
	_oBrowse:lAdjustColSize	:= .T.

	@_oSize:GetDimension("RODAPE","LININI")+2,_oSize:GetDimension("GETDADOS","XSIZE") -80 Say "Vlr/Litro Liquido: " Pixel Of _oDlg
	@_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("GETDADOS","XSIZE") -40 MsGet _oVlrLiq Var _nVlrLiq Picture "@E 9,999.9999" Pixel Of _oDlg
	
	If _lEdita
		CalcTot(_cTab,_cSetor,_cLinha,_cFundesa,_oVlrLiq,@_oBrowse,@_nVlrLiq)//Rodo o cálculo na primeira montagem da tela para calcular o valor líquido inicial
		_oBrowse:Refresh()
		TButton():New(_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("RODAPE","COLINI"),;
						"Confirmar",_oDlg,{|| CalcTot(_cTab,_cSetor,_cLinha,_cFundesa,_oVlrLiq,@_oBrowse,@_nVlrLiq),;
						 SaveRec(_oBrowse,_cTab,_cSetor,_cLinha),_oDlg:End()},50,10,,,,.T.) 
	Else
		TButton():New(_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("RODAPE","COLINI"),'Fechar',_oDlg,{||_oDlg:End()},50,10,,,,.T.)
	EndIf
	ACTIVATE MSDIALOG _oDlg CENTERED

	If _cTab=="TRBS"
		_cFilial := ""//Limpar conteúdo da variável porque na tela de setor o filtro usado é o _cFilSet, já que na tela são exibidas várias filiais.
	EndIf
	UpdateTab(_cTab,_nTipo,IIf(_cTab=="TRBS",.T.,_lAgrupa),_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)
Else
	MsgInfo("Não existem eventos lançados!","AGLT02020")
EndIf
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: SaveRec
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Processa os eventos a serem gerados pela tela de Edição
Parametros--------: _oBrowse,_cTab,_cSetor,_cLinha
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function SaveRec(_oBrowse,_cTab,_cSetor,_cLinha)

Local _aArea	:= FWGetArea()
Local _nX		:= 0
Local _lRet		:= .T.

Begin Sequence
Begin Transaction
For _nX:=1 To Len(_oBrowse:aArray)
	If _cTab == "TRBG" .And. _oBrowse:aArray[_nX][01] == .T. .And. _oBrowse:aArray[_nX][04] == "C"
		//O evento que tem CALCVOLKM na fórmula é uma exceção. Nele o valor total é descosiderado e substituído pelo valor da bonificação conforme configuração da linha (KM ou Litro)
		//Para esse evento considero o valor unitário informado pelo usuário
		If AllTrim(_oBrowse:aArray[_nX][12]) == "'CALCVOLKM'" .And. _oBrowse:aArray[_nX][05] > 0 .And. ZL3->ZL3_FRMPG == 'K'
			//Verifica o tipo de pagamento da linha do Fretista. Se For por KM, atualiza o valor que será gravado.
			_oBrowse:aArray[_nX][06] := _oBrowse:aArray[_nX][05]* U_GetKm((_cTab)->FILIAL,_cSetor,_cLinha,(_cTab)->COD,(_cTab)->LOJA,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM)
		EndIf
		//Grava ZLF caso o valor seja diferente do atual. No detalhe do fretista, sem agrupar (que é onde é possível editar), o valor é gravado na coluna de total "T" e não no Evento "E"
		If _oBrowse:aArray[_nX][06] <> (_cTab)->&("T"+_oBrowse:aArray[_nX][02])
			_lRet := gEvtFrtRat((_cTab)->FILIAL,_cSetor,_cLinha,_oBrowse:aArray[_nX][02],_oBrowse:aArray[_nX][04],_oBrowse:aArray[_nX][09],(_cTab)->COD,(_cTab)->LOJA,_oBrowse:aArray[_nX][06])
		EndIf
	ElseIf _oBrowse:aArray[_nX][01]
		// Se For Debito deve estar como negativo, então converte para positivo para poder ser gravado
		If _oBrowse:aArray[_nX][04] == "D" .And. _oBrowse:aArray[_nX][06] < 0
			_oBrowse:aArray[_nX][06] := _oBrowse:aArray[_nX][06]*-1
		EndIf
		//Grava ZLF caso o valor seja diferente do atual
		If _oBrowse:aArray[_nX][06] <> (_cTab)->&("E"+_oBrowse:aArray[_nX][02])
			//Filial,Setor,Linha,Evento,ZL8_DEBCRE,ZL8_MIX,Produtor,Loja,Valor,ZL8_QTDUNI,1-Produtor/2-Fretista
			_lRet := GrvZLF((_cTab)->FILIAL,_cSetor,_cLinha,_oBrowse:aArray[_nX][02],_oBrowse:aArray[_nX][04],_oBrowse:aArray[_nX][09],(_cTab)->COD,(_cTab)->LOJA,_oBrowse:aArray[_nX][06],_oBrowse:aArray[_nX][10],IIf(_cTab=="TRBP",1,2))
		EndIf
	EndIf
	If !_lRet
		MsgStop("Foram encontrados erros na geração dos eventos. Favor acionar a TI.","AGLT02021")
		DisarmTransaction()
		Break
	EndIf
Next _nX
End Transaction
End Sequence
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: CalcTot
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Processa validações na tela de Edição
Parametros--------: _cTab,_cSetor,_cLinha,_cFundesa,_oVlrLiq,_oBrowse,_nVlrLiq
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CalcTot(_cTab,_cSetor,_cLinha,_cFundesa,_oVlrLiq,_oBrowse,_nVlrLiq)

Local _aArea 	:= FWGetArea()
Local _npos 	:= _oBrowse:nAt
Local _nTotVlr	:= 0
Local _nFPec	:= 0
Local _nImp		:= 0
Local _nX		:= 0
Local _cAlias	:= GetNextAlias()
Local _nTotCred	:= 0
Local _nTotDeb	:= 0
Local _aBase	:= {}
Local _nBase	:= 0 //Variável lida por macroexecução (ZL8_FORMUL)
Local _nVolIncP	:= SuperGetMV("LT_VOLINCP",.F.,657000)
Local _lCalIncP	:= !Empty(Posicione('F28',1,xFilial('F28')+SuperGetMV("LT_INCINCP",.F.,""),'F28_CODIGO'))
Local _nRecPrd	:= 0
Local _nRecINS	:= 0
Local _nRecGil	:= 0
Local _lNf1Item		:= If(SM0->M0_ESTENT == 'RO',.F.,.T.)

//Posiciona nas tabelas para a execução da função de cálculo de imposto: RetImpGL
SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2")+(_cTab)->(COD+LOJA)))
ZL2->(DBSetOrder(1))
ZL2->(DBSeek(cFilAnt+_cSetor))
ZL3->(DBSetOrder(1))
ZL3->(DBSeek(cFilAnt+_cLinha))

BEGIN TRANSACTION
	//Realiza tratamentos para Incentivo à Produção em MG
	If _lCalIncP
		U_CalcInc(1,_nVolIncP,@_lCalIncP,@_nRecPrd,@_nRecINS,@_nRecGil)
	EndIf
	//Atualizo o browse de edição dos eventos
	If _oBrowse:nColPos == 05
		_oBrowse:aArray[_oBrowse:nAt][06]:= _oBrowse:aArray[_oBrowse:nAt][05]*(_cTab)->VOL
	ElseIf _oBrowse:nColPos == 06
		_oBrowse:aArray[_oBrowse:nAt][05]:= _oBrowse:aArray[_oBrowse:nAt][06]/(_cTab)->VOL
	EndIf

	If (_cTab == "TRBP" .And. _oBrowse:aArray[_oBrowse:nAt][04] == "C" .And. _oBrowse:aArray[_oBrowse:nAt][06] < 0 ) .Or.;
		(_oBrowse:aArray[_oBrowse:nAt][04] == "D" .And. _oBrowse:aArray[_oBrowse:nAt][06] > 0 )
		MsgStop("Eventos de Crédito devem ser positivos e Eventos de Débito devem ser negativos. Ajuste os valores!","AGLT02022")
		_oBrowse:aArray[_oBrowse:nAt][05]:= 0
		_oBrowse:aArray[_oBrowse:nAt][06]:= 0
	EndIf
	If _cTab == "TRBG" .And. _oBrowse:aArray[_oBrowse:nAt][11] > 0 .And. _oBrowse:aArray[_oBrowse:nAt][5] > _oBrowse:aArray[_oBrowse:nAt][11]
		MsgStop("O valor digitado para o Evento ultrapassou o Limite definido: ["+ Transform( _oBrowse:aArray[_oBrowse:nAt][11],"@E 999,999,999.99") +"]","AGLT02023")
		_oBrowse:aArray[_oBrowse:nAt][05]:= 0
		_oBrowse:aArray[_oBrowse:nAt][06]:= 0
	EndIf

	//Separar os eventos que compõe o TOT_CRED e TOT_DEB. O IMP ainda não estará calculado, logo, preciso simular seu cálculo
	//Os eventos não são os mesmos que aparecem na tela do MIX.
	For _nX:=1 To Len(_oBrowse:aArray)
		If _oBrowse:aArray[_nX][06] <> 0
			_nTotVlr += _oBrowse:aArray[_nX][06]
			If _oBrowse:aArray[_nX][04] == "C" .And. _oBrowse:aArray[_nX][09] $ "S" 
				_nTotCred+=_oBrowse:aArray[_nX][06]
			    aAdd(_aBase,_oBrowse:aArray[_nX][06])
			ElseIf _oBrowse:aArray[_nX][04] == "D" .And. _oBrowse:aArray[_nX][09] $ "S"
				_nTotDeb+=_oBrowse:aArray[_nX][06]
			EndIf
		EndIf
	Next _nX

	BeginSql alias _cAlias
		SELECT R_E_C_N_O_ RECZL8
		FROM %Table:ZL8% ZL8
		WHERE ZL8.D_E_L_E_T_ = ' '
		AND ZL8.ZL8_FILIAL = %xFilial:ZL8%
		AND ZL8.ZL8_PERTEN = 'P'
		AND ZL8.ZL8_GRUPO = '000007'
		AND ZL8.ZL8_MSBLQL <> '1'
	EndSql

	While (_cAlias)->( !Eof() )
		ZL8->(DBGoTo((_cAlias)->RECZL8))
		If &( AllTrim( ZL8->ZL8_CONDIC ) )
			//Calcula Fundesa/Fundepec. Evento tratado como exceção até padronização de todos os impostos na NF-e
			If ZL8->ZL8_COD == _cFundesa
				_nFPec:=(_cTab)->VOL*ZL8->ZL8_VALOR
			Else
				//O cálculo dos impostos não pode ler a ZLF, pois a tela simula os impostos antes da gravação na tabela
				//Se ler ela, o valor ainda não estará correto, por isso é alimentada a variável para o cálculo.
				If _lNf1Item //Quando a nota gerada possuir apenas um item tenho que passar a base total para que não haja diferença de arredontamento
					_nBase := 0
					For _nX:= 1 To Len(_aBase)
						_nBase += _aBase[_nX]
					Next _nX
					_nImp += IIf(ZL8->ZL8_DEBCRE == 'C',&( ZL8->ZL8_FORMUL),&( ZL8->ZL8_FORMUL)*-1)
				Else
					For _nX:= 1 To Len(_aBase)
						_nBase := _aBase[_nX]
						_nImp += IIf(ZL8->ZL8_DEBCRE == 'C',&( ZL8->ZL8_FORMUL),&( ZL8->ZL8_FORMUL)*-1)
					Next _nX
				EndIf
			EndIf
		EndIf
		(_cAlias)->( DBSkip() )
	EndDo

	(_cAlias)->( DBCloseArea() )
    //Quando houver o Incentivo à produção, somo o valor do incentivo nos créditos para que o cálculo do custo fique simulado corretamente
    If SA2->A2_INCLTMG == '1' .And. F28->(DBSeek(xFilial("F28")+SuperGetMV("LT_INCINCP",.F.,"")))
        _nTotCred += (_nTotCred*F28->F28_ALIQ)/100
    EndIf
	//O Débito já vem negativo do Browse, então eu somo. Os demais vem positivos, ai subtraio
	_nVlrLiq:= (_nTotCred+_nTotDeb-_nFPec+_nImp)/(_cTab)->VOL

	//Realiza tratamentos para Incentivo à Produção em MG
	If _lCalIncP
		U_CalcInc(2,_nVolIncP,_lCalIncP,_nRecPrd,_nRecINS,_nRecGil)
	EndIf
END TRANSACTION	
_oBrowse:GoPosition(_npos)
_oVlrLiq:Refresh()
_oBrowse:DrawSelect()
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: OpenCad
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Abre tela de cadastro solicitada
Parametros--------: _cTabela,_cFilial,_cChave
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function OpenCad(_cTabela,_cFilial,_cChave)

Local _aArea := FWGetArea()

DBSelectArea(_cTabela)
(_cTabela)->(DBSetOrder(1))
(_cTabela)->(DBSeek(_cFilial+_cChave))

AxVisual(_cTabela,(_cTabela)->(Recno()),5)

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: PesqProd
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Pesquisa o Produtor no Browse
Parametros--------: oBrowse3,_cTab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PesqProd(oBrowse3,_cTab)

Local _oButton1 := Nil
Local _oFornece	:= Nil
Local _cFornece	:= Space(GetSX3Cache("A2_COD","X3_TAMANHO"))
Local _oLoja	:= Nil
Local _cLoja	:= Space(GetSX3Cache("A2_LOJA","X3_TAMANHO"))
Local _oSay1	:= Nil
Local _oSay2	:= Nil
Local _oDlg		:= Nil

DEFINE MSDIALOG _oDlg TITLE "Pesquisa Produtor" FROM 000, 000  TO 110, 380 Colors 0, 16777215 Pixel
	@ 008, 013 Say _oSay1 PROMPT "Código" SIZE 031, 006 OF _oDlg Colors 0, 16777215 Pixel
	@ 015, 013 MSGET _oFornece VAR _cFornece SIZE 060, 010 OF _oDlg Picture "X99999" Colors 0, 16777215 F3 GetSX3Cache("ZLB_RETIRO","X3_F3") Pixel
	@ 008, 118 Say _oSay2 PROMPT "Loja" SIZE 025, 007 OF _oDlg Colors 0, 16777215 Pixel
	@ 015, 118 MSGET _oLoja VAR _cLoja SIZE 060, 010 OF _oDlg Picture "9999" Colors 0, 16777215 Pixel
	@ 035, 141 BUTTON _oButton1 PROMPT "Pesquisar" SIZE 037, 012 OF _oDlg ACTION FindProd(oBrowse3,_oDlg,_cTab,_cFornece,_cLoja) Pixel
ACTIVATE MSDIALOG _oDlg CENTERED

Return                         

/*
===============================================================================================================================
Programa----------: FindProd
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Pesquisa o Produtor no Browse
Parametros--------: oBrowse3,_oDlg,_cAlias,_cFornece,_cLoja
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function FindProd(oBrowse3,_oDlg,_cAlias,_cFornece,_cLoja)

If !(_cAlias)->(MsSeek(cFilAnt+_cFornece+_cLoja,.T.))
    MsgAlert("Produtor não encontrado. Favor verificar o código fornecido.","AGLT02024")
Else
	_oDlg:End()
EndIf

oBrowse3:DrawSelect()

Return
/*
===============================================================================================================================
Programa----------: getUltMix
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/09/2021
Descrição---------: Obtem numero do Mix anterior
Parametros--------: Nenhum
Retorno-----------: Código do Mix anterior ao mix corrente
===============================================================================================================================
*/
Static Function getUltMix()

Local _cAlias	:= GetNextAlias()
Local _cUlt		:= ""
Local _aArea	:= FWGetArea()

BeginSql alias _cAlias
	SELECT MAX(ZLE_COD) COD
	  FROM %Table:ZLE%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLE_COD < %exp:ZLE->ZLE_COD%
EndSql

_cUlt := (_cAlias)->COD
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return _cUlt

/*
===============================================================================================================================
Programa----------: gEvtFrtRat
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Grava Evento do Fretista rateando por Produtor
Parametros--------: _cFilial,_cSetor,_cLinha,_cEvento,_cDebCred,_cEveMix,_cFornece,_cLoja,_nValor
Retorno-----------: _lRet -> .T. - Operações realizadas com sucesso / .F. - Erro/não processamneto na execução de alguma etapa
===============================================================================================================================
*/
Static Function gEvtFrtRat(_cFilial,_cSetor,_cLinha,_cEvento,_cDebCred,_cEveMix,_cFornece,_cLoja,_nValor)

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _lRet		:= .F.
Local _nCalc	:= 0
Local _nQtdPrd	:= 0
Local _nTotParc	:= 0
Local _nVolume	:= 0

// Se For debito sai da rotina
If _cDebCred == "C"
	_lRet := .T.
EndIf
//Valida se existem registros diferentes de Aberto, impedindo que os eventos sejam executados para outros status
_lRet:= IsOpen(_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

// Localiza produtores que irao compor o rateio do Fretista
If _lRet
	BeginSql alias _cAlias
		SELECT ZLD.ZLD_FILIAL FILIAL, ZLD.ZLD_RETIRO COD, ZLD.ZLD_RETILJ LOJA,
			SUM(ZLD.ZLD_QTDBOM) VOLUME
		FROM %Table:ZLD% ZLD
		WHERE ZLD.D_E_L_E_T_ = ' '
		AND ZLD.ZLD_FILIAL = %exp:_cFilial%
		AND ZLD.ZLD_SETOR = %exp:_cSetor%
		AND ZLD.ZLD_LINROT = %exp:_cLinha%
		AND ZLD.ZLD_FRETIS = %exp:_cFornece%
		AND ZLD.ZLD_LJFRET = %exp:_cLoja%
		AND ZLD.ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
		GROUP BY ZLD.ZLD_FILIAL, ZLD.ZLD_RETIRO, ZLD.ZLD_RETILJ
		ORDER BY ZLD.ZLD_RETIRO
	EndSql

	// Calcula valor total do volume dos produtores
	While (_cAlias)->(!Eof())
		_nQtdPrd++
		_nVolume += (_cAlias)->VOLUME
		(_cAlias)->(DBSkip())
	EndDo

	(_cAlias)->(DBGoTop())

	If _nValor > 0 .And. _nQtdPrd == 0
		MsgStop("O Transportador ["+ _cFornece +"/"+ _cLoja +"] não possui recepção de Leite na Linha ["+ _cLinha +"] para  realizar o rateio!"+;
		"O Evento ["+ _cEvento +"] não pode ser gerado. Verifique se o Transportador selecionado possui movimentação no MIX!","AGLT02025")
	EndIf

	// Le os produtores para gerar ZLF rateada
	While (_cAlias)->( !Eof() )

		_nCalc++

		DBSelectArea("ZLF")
		ZLF->(DBSetOrder(5)) //ZLF_FILIAL+ZLF_CODZLE+ZLF_VERSAO+ZLF_SETOR+ZLF_LINROT+ZLF_EVENTO+ZLF_A2COD+ZLF_A2LOJA+ZLF_RETIRO+ZLF_RETILJ
		If ZLF->(DBSeek(_cFilial+ZLE->ZLE_COD+"1"+_cSetor+_cLinha+_cEvento+_cFornece+_cLoja+(_cAlias)->(COD+LOJA) ) )
			If ZLF->ZLF_STATUS == "A"//Garanto que ninguém estava na tela de edição esperando para mudar algum valor após a aprovação
				RecLock( "ZLF",.F.)
				If _nValor == 0
					ZLF->(DBDelete())
				Else
					ZLF->ZLF_QTDBOM	:= (_cAlias)->VOLUME
					ZLF->ZLF_TOTAL  := IIf(_nQtdPrd==_nCalc,_nValor-_nTotParc,Round(_nValor*((_cAlias)->VOLUME/_nVolume ),2))// rateia
					ZLF->ZLF_VLRLTR := (ZLF->ZLF_TOTAL/ZLF->ZLF_QTDBOM)
					ZLF->ZLF_DTCALC := Date()
					ZLF->( MSUnLock() )			
					_nTotParc += Round(_nValor*((_cAlias)->VOLUME/_nVolume),2)
				EndIf
				_lRet := .T.
			EndIf
		ElseIf _nValor <> 0
			RecLock("ZLF", .T.)
				ZLF->ZLF_FILIAL		:= _cFilial
				ZLF->ZLF_CODZLE		:= ZLE->ZLE_COD
				ZLF->ZLF_VERSAO		:= "1"
				ZLF->ZLF_SETOR		:= _cSetor
				ZLF->ZLF_LINROT		:= _cLinha
				ZLF->ZLF_RETIRO		:= (_cAlias)->COD
				ZLF->ZLF_RETILJ		:= (_cAlias)->LOJA
				ZLF->ZLF_A2COD		:= _cFornece
				ZLF->ZLF_A2LOJA		:= _cLoja
				ZLF->ZLF_EVENTO		:= _cEvento
				ZLF->ZLF_ENTMIX		:= _cEveMix
				ZLF->ZLF_DEBCRED	:= _cDebCred
				ZLF->ZLF_DTINI		:= ZLE->ZLE_DTINI
				ZLF->ZLF_DTFIM		:= ZLE->ZLE_DTFIM
				ZLF->ZLF_ORIGEM		:= "M"
				ZLF->ZLF_QTDBOM		:= (_cAlias)->VOLUME
				ZLF->ZLF_TOTAL		:= IIf(_nQtdPrd==_nCalc,_nValor-_nTotParc,Round(_nValor*((_cAlias)->VOLUME/_nVolume),2)) // rateia
				ZLF->ZLF_VLRLTR		:= ZLF->ZLF_TOTAL/ZLF->ZLF_QTDBOM
				ZLF->ZLF_SEQ		:= U_GetSeqZLF(ZLE->ZLE_COD,_cEvento,(_cAlias)->COD,(_cAlias)->LOJA)
				ZLF->ZLF_ACERTO		:= "N"
				ZLF->ZLF_TP_MIX		:= "F"
				ZLF->ZLF_TIPO		:= "F"
				ZLF->ZLF_STATUS		:= "A"
				ZLF->ZLF_DTCALC 	:= Date()
			MSUnLock()
			
			_nTotParc	+= Round(_nValor*((_cAlias)->VOLUME/_nVolume),2)
			_lRet := .T.
		EndIf
		
		(_cAlias)->( DBSkip() )
	EndDo
	(_cAlias)->(DBCloseArea())
EndIf

//Rateio todos os créditos calculados por ticket na ZLD
If _lRet .And. _nQtdPrd > 0 .And. _cDebCred == "C"
	_lRet := AtuZLD(_cFilial,"('"+_cSetor+"')",_cLinha,_cLinha,_cFornece,_cFornece,_cLoja,_cLoja)
EndIf

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AtuZLD
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Grava custo do frete na ZLD
Parametros--------: _cFilial,_cSetor,_cLinha,_cEvento,_cDebCred,_cEveMix,_cFornece,_cLoja,_nValor
Retorno-----------: _lRet -> .T. - Operações realizadas com sucesso / .F. - Erro/não processamneto na execução de alguma etapa
===============================================================================================================================
*/
Static Function AtuZLD(_cFilial,_cSetores,_cLinhaIni,_cLinhaFim,_cFornIni,_cFornFim,_cLojaIni,_cLojaFim)

Local _lRet		:= .T.
Local _cUpdate	:= ""
//O Update deve ser executado tanto na geração de eventos quanto na exclusão. Na exclusão, como não irá encontrar valores na ZLF, 
//gravará o valor igual a 0. Localiza o total do crédito e a base do frete
_cUpdate:=" UPDATE "+RetSqlName("ZLD")+" ZLD SET ZLD_CREDFR = Case WHEN ZLD_KM = 0 THEN 0 Else "
_cUpdate+="                        ((SELECT NVL(SUM(ZLF_TOTAL), 0) FROM "+RetSqlName("ZLF")+" ZLF, "+RetSqlName("ZL8")+" ZL8 "
_cUpdate+="                          WHERE ZLF.D_E_L_E_T_ = ' ' "
_cUpdate+="                            AND ZL8.D_E_L_E_T_ = ' ' "
_cUpdate+="                            AND ZLF_FILIAL = ZL8_FILIAL "
_cUpdate+="                            AND ZLF_EVENTO = ZL8_COD "
_cUpdate+="                            AND ZLF_FILIAL = ZLD_FILIAL "
_cUpdate+="                            AND ZLF_CODZLE = '"+ZLE->ZLE_COD+"' "
_cUpdate+="                            AND ZL8_DEBCRE = 'C' "
_cUpdate+="                            AND ZLF_SETOR = ZLD_SETOR "
_cUpdate+="                            AND ZLF_LINROT = ZLD_LINROT "
_cUpdate+="                            AND ZLF_A2COD = ZLD_FRETIS "
_cUpdate+="                            AND ZLF_A2LOJA = ZLD_LJFRET "
_cUpdate+="                            AND ZL8_FORMUL NOT LIKE 'U_CALFRETE%') /*CREDITO*/ "
_cUpdate+="                       / (SELECT NVL(SUM(KM), 0) KM FROM (SELECT ZLD2.ZLD_TICKET, ZLD2.ZLD_KM KM FROM "+RetSqlName("ZLD")+" ZLD2 "
_cUpdate+="                                    WHERE ZLD2.D_E_L_E_T_ = ' ' "
_cUpdate+="                                      AND ZLD2.ZLD_FILIAL = ZLD.ZLD_FILIAL "
_cUpdate+="                                      AND ZLD2.ZLD_SETOR = ZLD.ZLD_SETOR "
_cUpdate+="                                      AND ZLD2.ZLD_LINROT = ZLD.ZLD_LINROT "
_cUpdate+="                                      AND ZLD2.ZLD_DTCOLE BETWEEN '"+DToS(ZLE->ZLE_DTINI)+"' AND '"+DToS(ZLE->ZLE_DTFIM)+"' "
_cUpdate+="                                      AND ZLD2.ZLD_KM > 0 "
_cUpdate+="                                      AND ZLD2.ZLD_FRETIS = ZLD.ZLD_FRETIS "
_cUpdate+="                                      AND ZLD2.ZLD_LJFRET = ZLD.ZLD_LJFRET "
_cUpdate+="                                    GROUP BY ZLD2.ZLD_TICKET, ZLD2.ZLD_CODREC, ZLD2.ZLD_KM)) /*KM*/) * ZLD_KM END, "
_cUpdate+="       ZLD_VLRFRE = Case WHEN (SELECT NVL(SUM(ZLF_TOTAL), 0) FROM "+RetSqlName("ZLF")+" ZLF, "+RetSqlName("ZL8")+" ZL8 "
_cUpdate+="                             WHERE ZLF.D_E_L_E_T_ = ' ' "
_cUpdate+="                               AND ZL8.D_E_L_E_T_ = ' ' "
_cUpdate+="                               AND ZLF_FILIAL = ZL8_FILIAL "
_cUpdate+="                               AND ZLF_EVENTO = ZL8_COD "
_cUpdate+="                               AND ZLF_FILIAL = ZLD_FILIAL "
_cUpdate+="                               AND ZLF_CODZLE = '"+ZLE->ZLE_COD+"' "
_cUpdate+="                               AND ZL8_DEBCRE = 'C' "
_cUpdate+="                               AND ZLF_SETOR = ZLD_SETOR "
_cUpdate+="                               AND ZLF_LINROT = ZLD_LINROT "
_cUpdate+="                               AND ZLF_A2COD = ZLD_FRETIS "
_cUpdate+="                               AND ZLF_A2LOJA = ZLD_LJFRET "
_cUpdate+="                               AND ZL8_FORMUL LIKE 'U_CALFRETE%') /*FRETE*/ = 0 THEN 0 Else ZLD_VLRFRE END, "
_cUpdate+="       ZLD_VTABFR = Case WHEN (SELECT NVL(SUM(ZLF_TOTAL), 0) "
_cUpdate+="                              FROM "+RetSqlName("ZLF")+" ZLF, "+RetSqlName("ZL8")+" ZL8 "
_cUpdate+="                             WHERE ZLF.D_E_L_E_T_ = ' ' "
_cUpdate+="                               AND ZL8.D_E_L_E_T_ = ' ' "
_cUpdate+="                               AND ZLF_FILIAL = ZL8_FILIAL "
_cUpdate+="                               AND ZLF_EVENTO = ZL8_COD "
_cUpdate+="                               AND ZLF_FILIAL = ZLD_FILIAL "
_cUpdate+="                               AND ZLF_CODZLE = '"+ZLE->ZLE_COD+"' "
_cUpdate+="                               AND ZL8_DEBCRE = 'C' "
_cUpdate+="                               AND ZLF_SETOR = ZLD_SETOR "
_cUpdate+="                               AND ZLF_LINROT = ZLD_LINROT "
_cUpdate+="                               AND ZLF_A2COD = ZLD_FRETIS "
_cUpdate+="                               AND ZLF_A2LOJA = ZLD_LJFRET "
_cUpdate+="                               AND ZL8_FORMUL LIKE 'U_CALFRETE%') /*FRETE*/ = 0 THEN 0 Else ZLD_VTABFR END "
_cUpdate+=" WHERE D_E_L_E_T_ = ' ' "
_cUpdate+="   AND ZLD_FILIAL = '"+_cFilial+"' "
_cUpdate+="   AND ZLD_SETOR IN "+Replace(_cSetores,"%","")
_cUpdate+="   AND ZLD_LINROT BETWEEN '"+_cLinhaIni+"' AND '"+_cLinhaFim+"' "
_cUpdate+="   AND ZLD_DTCOLE BETWEEN '"+DToS(ZLE->ZLE_DTINI)+"' AND '"+DToS(ZLE->ZLE_DTFIM)+"' "
_cUpdate+="   AND ZLD_FRETIS BETWEEN '"+_cFornIni+"' AND '"+_cFornFim+"' "
_cUpdate+="   AND ZLD_LJFRET BETWEEN '"+_cLojaIni+"' AND '"+_cLojaFim+"' "
_cUpdate+="   AND ZLD_STATUS = ' ' "

If TCSqlExec(_cUpdate) < 0
	_lRet := .F.
	MsgStop("Erro ao atualizar o custo do frete. Acione a TI. Erro: "+AllTrim(TCSQLError()),"AGLT02026")
EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa----------: GrvZLF
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Grava Eventos do produtor e fretista
Parametros--------: _cFilial,_cSetor,_cLinha,_cEvento,_cDebCred,_cEveMix,_cFornece,_cLoja,_nValor,_cQtd,_cTipo
Retorno-----------: _lRet
===============================================================================================================================
*/
Static Function GrvZLF(_cFilial,_cSetor,_cLinha,_cEvento,_cDebCred,_cEveMix,_cFornece,_cLoja,_nValor,_cQtd,_cTipo)

Local _lRet := .F.
Local _aArea := FWGetArea()

If _cTipo == 1 .And. _nValor < 0
	_nValor := 0
EndIf

DBSelectArea("ZLF")
If _cTipo == 1
	ZLF->(DBSetOrder(3)) // ZLF_FILIAL+ZLF_CODZLE+ZLF_VERSAO+ZLF_SETOR+ZLF_LINROT+ZLF_EVENTO+ZLF_A2COD+ZLF_A2LOJA
Else
	ZLF->(DBSetOrder(5)) //ZLF_FILIAL+ZLF_CODZLE+ZLF_VERSAO+ZLF_SETOR+ZLF_LINROT+ZLF_EVENTO+ZLF_A2COD+ZLF_A2LOJA+ZLF_RETIRO+ZLF_RETILJ 
EndIf
If ZLF->(DBSeek(_cFilial+ZLE->ZLE_COD+"1"+_cSetor+_cLinha+_cEvento+_cFornece+_cLoja))
	If ZLF->ZLF_STATUS == "A"//Garanto que ninguém estava na tela de edição esperando para mudar algum valor após a aprovação
		RecLock("ZLF", .F.)
		If _nValor == 0
			DBDelete()
		Else
			ZLF->ZLF_QTDBOM	:= IIf(_cQtd <> 'S',U_VolLeite(_cFilial,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,_cSetor,_cLinha,_cFornece,_cLoja,""),1) 
			ZLF->ZLF_TOTAL  := _nValor
			ZLF->ZLF_VLRLTR := (_nValor/ZLF->ZLF_QTDBOM)
			ZLF->ZLF_DTCALC := Date()
		EndIf
		MSUnLock()
		_lRet := .T.
	EndIf
ElseIf _nValor <> 0 .And. IsOpen(_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)
	RecLock("ZLF", .T.)
		ZLF->ZLF_FILIAL := _cFilial
		ZLF->ZLF_CODZLE := ZLE->ZLE_COD
		ZLF->ZLF_VERSAO := "1"
		ZLF->ZLF_SETOR  := _cSetor
		ZLF->ZLF_LINROT := _cLinha
		ZLF->ZLF_A2COD  := _cFornece
		ZLF->ZLF_A2LOJA := _cLoja
		ZLF->ZLF_RETIRO := IIf(_cTipo==1,_cFornece,"")
		ZLF->ZLF_RETILJ := IIf(_cTipo==1,_cLoja,"")
		ZLF->ZLF_EVENTO := _cEvento
		ZLF->ZLF_ENTMIX := _cEveMix
		ZLF->ZLF_DEBCRED:= _cDebCred
		ZLF->ZLF_DTINI  := ZLE->ZLE_DTINI
		ZLF->ZLF_DTFIM  := ZLE->ZLE_DTFIM
		ZLF->ZLF_QTDBOM := IIf(_cQtd <> 'S',U_VolLeite(_cFilial,ZLE->ZLE_DTINI,ZLE->ZLE_DTFIM,_cSetor,_cLinha,_cFornece,_cLoja,""),1) 
		ZLF->ZLF_TOTAL  := _nValor
		ZLF->ZLF_VLRLTR := (_nValor/ZLF->ZLF_QTDBOM)
		ZLF->ZLF_ORIGEM := "M"
		ZLF->ZLF_ACERTO := "N"
		ZLF->ZLF_TP_MIX := IIf(_cTipo==1,"L","F")
		ZLF->ZLF_TIPO   := IIf(_cTipo==1,"L","F")
		ZLF->ZLF_SEQ	:= U_GetSeqZLF(ZLE->ZLE_COD,_cEvento,_cFornece,_cLoja)
		ZLF->ZLF_STATUS := "A"
		ZLF->ZLF_DTCALC := Date()
	MSUnLock()
	_lRet := .T.
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: isOpen
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Verifica se existem registros em Aberto de acordo com os parâmetros passados
Parametros--------: _cFilial,_cSetor,_cLinha,_cFornece,_cLoja
Retorno-----------: _lRet -> L -> .T.-tudo em aberto /.F.-registros não abertos
===============================================================================================================================
*/
Static Function IsOpen(_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

Local _lRet		:= .F.
Local _cAlias	:= GetNextAlias()
Local _cFiltro	:= "%"

// Obtem quantidade de registros nao abertos
IIf (!Empty(_cSetor),_cFiltro += " AND ZLF_SETOR = '"+_cSetor+"'","")
IIf (!Empty(_cLinha),_cFiltro += " AND ZLF_LINROT = '"+_cLinha+"'","")
IIf (!Empty(_cFornece),_cFiltro += " AND ZLF_A2COD = '"+_cFornece+"' AND ZLF_A2LOJA = '"+_cLoja+"'","")
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT COUNT(1) QTDREG
	  FROM %Table:ZLF%
	 WHERE D_E_L_E_T_ = ' '
	   %exp:_cFiltro%
	   AND ZLF_FILIAL = %exp:_cFilial%
	   AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
	   AND ZLF_STATUS <> 'A'
EndSql

If (_cAlias)->QTDREG == 0
	_lRet:=.T.
EndIf

(_cAlias)->(DBCloseArea())

Return _lRet

/*
===============================================================================================================================
Programa----------: AprEfet
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta a tela de Aprovação/Efetivação do Mix
Parametros--------: _cTab,_cFilSet,_cSetor,_nAcao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AprEfet(_cTab,_nTipo,_cFilSet,_cSetor,_nAcao)

Local _oDlg		:= Nil
Local _cTitulo	:= IIf(_nAcao==1,"Aprovar","Efetivar")
Local _cDesc	:= ""

If _cTab $ "TRBS/TRBL/TRBP" .And. _nAcao == 1
	_cDesc += "Esse processo irá "+_cTitulo+" apenas os eventos de PRODUTORES."
ElseIf _cTab $ "TRBF/TRBG" .And. _nAcao == 1
	_cDesc += "Esse processo irá "+_cTitulo+" apenas os eventos de FRETISTAS."
ElseIf _nAcao == 1
	_cDesc += "Esse processo irá "+_cTitulo+" apenas os eventos tanto de PRODUTORES quanto FRETISTAS."
EndIf

If Empty((_cTab)->FILIAL)//Se estiver vazio é porque está posicionado no totalizador, logo, não faz nada.
     Return
EndIf
If !(_nTipo==2)
	MsgStop("Esta opção só pode ser executada no modo Manutenção!","AGLT02027")
    Return
EndIf
If _nAcao == 1 .And. !ZLU->ZLU_APRMIX == 'S'
	MsgStop("Usuário sem acesso para Aprovar o MIX. Favor entrar em contato com o responsável pelo Departamento do Leite.","AGLT02028")
	Return
ElseIf _nAcao == 2 .And. !ZLU->ZLU_EFEMIX == 'S'
	MsgStop("Usuário sem acesso para Efetivar o MIX. Favor entrar em contato com o responsável pelo Departamento do Leite.","AGLT02029")
	Return
EndIf

// Tela de Aprovação/Efetivação
DEFINE MSDIALOG _oDlg FROM 0,0 TO 190,420 PIXEL TITLE _cTitulo

@003,003 TO 92,210

@010,010 Say "Essa rotina tem como objetivo "+_cTitulo+" os Setores do MIX. Isso podeser feito para "	PIXEL OF _oDlg
@020,010 Say "o Setor posicionado ou para todos os Setores."											PIXEL OF _oDlg
@030,010 Say "Após a aprovação e efetivação o Mix estará apto para ser fechado."						PIXEL OF _oDlg
@040,010 Say _cDesc																						PIXEL OF _oDlg

TButton():New(055,005,_cTitulo+" Setor Posicionado",_oDlg,{|| Processa({||SetStatus(_cTab,_cFilSet,_cSetor,IIf(_nAcao==1,"1","5")/*_cAcao*/)}),_oDlg:End()},100,010,,,,.T.) 
TButton():New(055,107,_cTitulo+" Todos os Setores",_oDlg,{|| Processa({||SetStatus(_cTab,_cFilSet,_cSetor,IIf(_nAcao==1,"2","6")/*_cAcao*/)}),_oDlg:End()},100,010,,,,.T.) 
TButton():New(067,005,"Reabrir Setor Posicionado",_oDlg,{|| Processa({||SetStatus(_cTab,_cFilSet,_cSetor,IIf(_nAcao==1,"3","7")/*_cAcao*/)}),_oDlg:End()},100,010,,,,.T.) 
TButton():New(067,107,"Reabrir Todos os Setores",_oDlg,{|| Processa({||SetStatus(_cTab,_cFilSet,_cSetor,IIf(_nAcao==1,"4","8")/*_cAcao*/)}),_oDlg:End()},100,010,,,,.T.) 
TButton():New(079,005,"Voltar",_oDlg,{||_oDlg:End()},100,010,,,,.T.) 

ACTIVATE MSDIALOG _oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: SetStatus
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Atualiza o status do Mix
Parametros--------: _cTab,_cFilSet,_cSetor,_cAcao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function SetStatus(_cTab,_cFilSet,_cSetor,_cAcao)

Local _cTpMix 	:= IIf(_cTab$"TRBS/TRBL/TRBP","L","F")
Local _cUpdate	:= ""
Local _cFiltro	:= "%"
Local _cAlias   := ""
Local _cStatus	:= ""

/*1-Aprovar Setor posicionado
2-Aprovar Todos os setores
3-Cancelar aprovação do setor posicionado
4-Cancelar aprovação de todos os setores
5-Efetivar Setor posicionado
6-Efetivar Todos os setores
7-Cancelar efetivação do setor posicionado
8-Cancelar efetivação de todos os setores*/

//Define status que será atualizado
If _cAcao $ "1/2/7/8"
	_cStatus := "P"
ElseIf _cAcao $ "3/4"
	_cStatus := "A"
ElseIf _cAcao $ "5/6"
	_cStatus := "E"
EndIf
// Monta Query de atualização do Status
_cUpdate := " UPDATE "+ RetSqlName("ZLF") +" SET ZLF_STATUS = '"+ _cStatus +"' " // A = Aberto , P = Aprovado , E = Efetivado
_cUpdate += " WHERE D_E_L_E_T_ = ' ' "
_cUpdate += " AND ZLF_CODZLE = '"+ZLE->ZLE_COD+"' "
_cUpdate += " AND ZLF_ACERTO != 'S' "
If _cAcao $ "1/2/3/4" //Na aprovação indico se é L-Produtor ou F-Fretista. Efetivação é sempre para ambos
	_cUpdate += " AND ZLF_TP_MIX = '"+_cTpMix+"' "
EndIf
If _cAcao $ "1/3/5/7"//Atualiza registros posicionados (Setor e Linha)
	_cUpdate += " AND ZLF_SETOR = '"+_cSetor+"'"
	_cFiltro += " AND ZL2_COD = '"+_cSetor+"'"
Else//Atualiza todos os registros que o usuário tem acesso
	_cUpdate += " AND ZLF_SETOR IN " + _cFilSet
	_cFiltro += " AND ZL2_COD IN " + _cFilSet
EndIf
If _cAcao $ "1/2"
	_cUpdate += " AND ZLF_STATUS = 'A' "
ElseIf _cAcao $ "3/4/5/6"
	_cUpdate += " AND ZLF_STATUS = 'P'"
ElseIf _cAcao $ "7/8"//
	_cUpdate += " AND ZLF_STATUS = 'E' "
EndIf

_cFiltro += " %"

Begin Transaction
	TcSqlExec(_cUpdate)

	// Validação da atualização de Status + Gravação do valor por litro na tabela do Setor
	If _cStatus $ "E/P"
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT ZL2.R_E_C_N_O_ RECNO, NVL(SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END),0) VALOR,
				(SELECT NVL(SUM(ZLD_QTDBOM), 0)
					FROM %Table:ZLD%
					WHERE D_E_L_E_T_ = ' '
					AND ZLD_FILIAL = ZL2_FILIAL
					AND ZLD_SETOR = ZL2_COD
					AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%) VOLUME,
				(SELECT NVL(SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END), 0)
					FROM %Table:ZLF% ZLF
					WHERE ZLF.D_E_L_E_T_ = ' '
					AND ZLF_FILIAL = ZL2_FILIAL
					AND ZLF_SETOR = ZL2_COD
					AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
					AND ZLF_ENTMIX = 'S'
					AND ZLF_A2COD LIKE 'G%') FRETE
			FROM %Table:ZL2% ZL2, %Table:ZLF% ZLF
			WHERE ZL2.D_E_L_E_T_ = ' '
			AND ZLF.D_E_L_E_T_ = ' '
			AND ZLF_FILIAL = ZL2_FILIAL
			AND ZLF_SETOR = ZL2_COD
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			AND ZLF_ENTMIX = 'S'
			%exp:_cFiltro%
			GROUP BY ZL2_FILIAL, ZL2_COD, ZL2.R_E_C_N_O_
		EndSql
		//Evita que testes em mix que ainda não tem o mês completo alterem o custo do mês usado pelo Custo
		If DDataBase <= Date()
			DBSelectArea('ZL2')
			While (_cAlias)->(!Eof())
				ZL2->(DBGoTo((_cAlias)->RECNO))
					RecLock('ZL2',.F.)
					ZL2->ZL2_ULTMIX	:= Round((_cAlias)->VALOR/(_cAlias)->VOLUME,4)
					ZL2->ZL2_ULMISF := Round(((_cAlias)->VALOR-(_cAlias)->FRETE)/(_cAlias)->VOLUME,4)
					ZL2->ZL2_DTUMIX	:= Date()
					ZL2->ZL2_HRUMIX	:= Time()
					ZL2->( MSUnLock() )
				(_cAlias)->( DBSkip() )
			EndDo
		EndIf
	EndIf
End Transaction

Return

/*
===============================================================================================================================
Programa----------: GerEvts
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Monta tela com eventos para a geração dos dados para o Mix
Parametros--------: _cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GerEvts(_cTab,_nTipo,_lAgrupa,_cFilSet,_cTitOpcao,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)

Local _aArea		:= FWGetArea()
Local _cAlias		:= GetNextAlias()
Local _oDlg			:= Nil
Local _oOK			:= LoadBitmap(GetResources(),'LBOK')
Local _oNO			:= LoadBitmap(GetResources(),'LBNO')
Local _oSim			:= LoadBitmap(GetResources(),'BR_VERDE')
Local _oNao			:= LoadBitmap(GetResources(),'BR_VERMELHO')
Local _oSize		:= Nil
Local _aEventos 	:= {}
Local _aSetores 	:= {}
Default	_cFilial	:= ""
Default	_cSetor		:= ""
Default	_cLinha		:= ""
Default	_cFornece	:= ""
Default	_cLoja		:= ""

If !(!_lAgrupa .And. _nTipo==2)
	MsgStop("Os eventos só podem ser gerados no modo detalhado de Eventos e com a opção de manutenção!","AGLT02030")
    Return
EndIf

If ZLU->ZLU_GEREVE <> 'S'
	MsgStop("Usuário atual não está liberado para a rotina de Geração de Eventos! Favor entrar em contato com o responsavel do Leite.","AGLT02031")
	Return
EndIf

If Empty(_cFilial)//Se estiver vazio é porque está posicionado no totalizador, logo, não faz nada.
     Return
EndIf

If _cFilial <> cFilAnt
	MsgStop("A Filial atual é diferente da Filial que está indicada no MIX!"+;
			"Para essa ação é necessário estar logado na mesma Filial do MIX selecionado.","AGLT02032")	
	Return
EndIf

// Cria array com Eventos que poderao ser executados
BeginSql alias _cAlias
	SELECT ZL8_COD, ZL8_DESCRI, ZL8_VALOR, ZL8_DEBCRE, ZL8_PRIORI, ZL8_FORMUL FROM %Table:ZL8% 
	WHERE D_E_L_E_T_ = ' ' AND ZL8_FILIAL = %exp:_cFilial% AND ZL8_TPEVEN = 'L' AND ZL8_MSBLQL <> '1' ORDER BY ZL8_PRIORI, ZL8_COD
EndSql
While (_cAlias)->( !Eof() )
	aAdd(_aEventos,{.F.,IIf( "ZL8->ZL8_VALOR"$(_cAlias)->ZL8_FORMUL,.T.,.F.),(_cAlias)->ZL8_COD,(_cAlias)->ZL8_DESCRI,(_cAlias)->ZL8_DEBCRE,(_cAlias)->ZL8_VALOR,(_cAlias)->ZL8_PRIORI})
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->(DBCloseArea())

_cAlias := GetNextAlias()
_cFiltro := '% ZL2_COD IN '+_cFilSet+"%"
BeginSql alias _cAlias
	SELECT ZL2_COD, ZL2_DESCRI FROM %Table:ZL2% WHERE D_E_L_E_T_ = ' ' AND ZL2_FILIAL = %exp:_cFilial% AND %Exp:_cFiltro% ORDER BY ZL2_COD
EndSql
While (_cAlias)->( !Eof() )
	aAdd(_aSetores,{.F.,(_cAlias)->ZL2_COD,(_cAlias)->ZL2_DESCRI})
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->(DBCloseArea())

// Tela de geracao de eventos
DEFINE MSDIALOG _oDlg FROM 0,0 TO 580,650 PIXEL TITLE "Geração de Eventos " +_cTitOpcao
//Calcula dimensões
_oSize := FwDefSize():New(.F.,,,_oDlg)
_oSize:AddObject( "CABECALHO",  100, 05, .T., .T. ) // Totalmente dimensionavel
_oSize:AddObject( "GETEVENTOS" ,100, 80, .T., .T. ) // Totalmente dimensionavel 
_oSize:AddObject( "GETSETORES" ,100, 80, .T., .T. ) // Totalmente dimensionavel 
_oSize:AddObject( "RODAPE"   ,  100, 05, .T., .T. ) // Totalmente dimensionavel

_oSize:lProp 	:= .T. // Proporcional             
_oSize:aMargins 	:= { 3, 3, 3, 3 } // Espaco ao lado dos objetos 0, entre eles 3 
_oSize:Process() 	   // Dispara os calculos   

//-- Cabecalho
@_oSize:GetDimension("CABECALHO","LININI"),_oSize:GetDimension("CABECALHO","COLINI") Say "Mix: " + ZLE->ZLE_COD Pixel Of _oDlg
@_oSize:GetDimension("CABECALHO","LININI"),_oSize:GetDimension("GETDADOS","XSIZE") -70 Say "Filial: " +_cFilial + "-" +SM0->M0_FILIAL Pixel Of _oDlg
//Browse dos Evetnos
_oBrowse := TCBrowse():New(_oSize:GetDimension("GETEVENTOS","LININI"),_oSize:GetDimension("GETEVENTOS","COLINI"),_oSize:GetDimension("GETEVENTOS","XSIZE"),_oSize:GetDimension("GETEVENTOS","YSIZE"),/*bLine*/,/*aHeaders*/,/*aColSizes*/,/*oWnd*/_oDlg,/*cField*/,/*uValue1*/,/*uValue2*/,/*bChange*/,/*bLDblClick*/{||},/*bRClicked*/,/*oFont*/,/*oCursor*/,/*nClrFore*/,/*nClrBack*/,/*cMsg*/,/*uParam20*/,/*cAlias*/,/*lPixel*/.T.,/*bWhen*/,/*uParam24*/.F.,/*bValid*/,/*lHScroll*/,/*lVScroll*/ )
_oBrowse:SetArray(_aEventos)
//(cTitulo,bData,cPicture,uParam4,uParam5,cAlinhamento,nLargura,lBitmap,lEdit,uParam10,bValid,uParam12,uParam13,uParam14)
_oBrowse:AddColumn( TCColumn():New(' ',				{||IIf(_aEventos[_oBrowse:nAt,01],_oOK,_oNO)},,,,"CENTER",,.T.,.F.,,{||},,,))
_oBrowse:AddColumn( TCColumn():New(' ',				{||IIf(_aEventos[_oBrowse:nAt,02],_oSim,_oNao)},,,,"CENTER",,.T.,.F.,,{||},,,))
_oBrowse:AddColumn( TCColumn():New('Evento',		{||_aEventos[_oBrowse:nAt,03]},,,,"LEFT",030,.F.,.F.,,{||},,,))
_oBrowse:AddColumn( TCColumn():New('Descrição',		{||_aEventos[_oBrowse:nAt,04]},,,,"LEFT",100,.F.,.F.,,{||},,,))
_oBrowse:AddColumn( TCColumn():New('Débito/Crédito',{||_aEventos[_oBrowse:nAt,05]},,,,"LEFT",045,.F.,.F.,,{||},,,))
_oBrowse:AddColumn( TCColumn():New('Valor p/Litro',	{||_aEventos[_oBrowse:nAt,06]},"@E 9,999.9999",,,"RIGHT",45,.F.,.F.,,{||},,,))
_oBrowse:bLDblClick	:= {|z,x|IIf(_aEventos[_oBrowse:nAt,02]== .T. .And. x==06,lEditCell(_aEventos,_oBrowse,"@E 9,999.9999",x),;
						IIf(x==01,_aEventos[_oBrowse:nAt][1] := !_aEventos[_oBrowse:nAt][1],)),_oBrowse:DrawSelect()}
						//_oBrowse:Refresh()}
_oBrowse:lAdjustColSize	:= .T.

// Browse dos Setores
_oBrT := TCBrowse():New(_oSize:GetDimension("GETSETORES","LININI"),_oSize:GetDimension("GETSETORES","COLINI"),_oSize:GetDimension("GETSETORES","XSIZE"),_oSize:GetDimension("GETSETORES","YSIZE"),/*bLine*/,/*aHeaders*/,/*aColSizes*/,/*oWnd*/_oDlg,/*cField*/,/*uValue1*/,/*uValue2*/,/*bChange*/,/*bLDblClick*/{||},/*bRClicked*/,/*oFont*/,/*oCursor*/,/*nClrFore*/,/*nClrBack*/,/*cMsg*/,/*uParam20*/,/*cAlias*/,/*lPixel*/.T.,/*bWhen*/,/*uParam24*/.F.,/*bValid*/,/*lHScroll*/,/*lVScroll*/ )
_oBrT:SetArray(_aSetores)
//(cTitulo,bData,cPicture,uParam4,uParam5,cAlinhamento,nLargura,lBitmap,lEdit,uParam10,bValid,uParam12,uParam13,uParam14)
_oBrT:AddColumn( TCColumn():New(' ',		{||IIf(_aSetores[_oBrT:nAt,01],_oOK,_oNO)},,,,"CENTER",,.T.,.F.,,{||},,,))
_oBrT:AddColumn( TCColumn():New('Código',	{||_aSetores[_oBrT:nAt,02]},,,,"LEFT",030,.F.,.F.,,{||},,,))
_oBrT:AddColumn( TCColumn():New('Setor',	{||_aSetores[_oBrT:nAt,03]},,,,"LEFT",100,.F.,.F.,,{||},,,))
_oBrT:bLDblClick	:= {||_aSetores[_oBrT:nAt][1] := !_aSetores[_oBrT:nAt][1],_oBrT:DrawSelect()}
_oBrT:lAdjustColSize	:= .T.

// Botoes da Geracao de Eventos
TButton():New(_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("RODAPE","COLINI"),;
						"Gerar",_oDlg,{|| Processa({||AGLT020EVE(_aSetores,_aEventos,"")}),_oDlg:End()},50,010,,,,.T.) 
TButton():New(_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("RODAPE","COLINI")+055,;
						"Apagar",_oDlg,{|| Processa({||AGLT020EVE(_aSetores,_aEventos,"Apagar")}),_oDlg:End()},050,010,,,,.T.) 
TButton():New(_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("RODAPE","COLINI")+110,;
						"Fechar",_oDlg,{||_oDlg:End()},050,010,,,,.T.) 
TButton():New(_oSize:GetDimension("RODAPE","LININI"),_oSize:GetDimension("RODAPE","COLINI")+165,;
						"Ver Evento",_oDlg,{||OpenCad("ZL8",_cFilial,_aEventos[_oBrowse:nAt][3])},050,010,,,,.T.) 

ACTIVATE MSDIALOG _oDlg CENTERED

If _cTab=="TRBS"
	_cFilial := ""//Limpar conteúdo da variável porque na tela de setor o filtro usado é o _cFilSet, já que na tela são exibidas várias filiais.
EndIf
UpdateTab(_cTab,_nTipo,IIf(_cTab=="TRBS",.T.,_lAgrupa),_cFilSet,_aStruct1,_cFilial,_cSetor,_cLinha,_cFornece,_cLoja)
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AGLT020EVE
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Executa as formulas dos eventos para todos os eventos e setores marcado, de acordo com o pergunte
Parametros--------: _aSetOri,_aEveOri,_cModo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT020EVE(_aSetOri,_aEveOri,_cModo)

Local _cAlias	:= ""
Local _lRet		:= .T.
Local _cFiltro	:= ""
Local _cFiltro2	:= ""
Local _cCampos	:= ""
Local _cGroup	:= ""
Local _cSetores := ""
Local _nTotReg	:= 0
Local _nX		:= 0
Local _aSetores	:= {}
Local _aEventos	:= {}
Local _lApagar	:= IIf(_cModo=="Apagar",.T.,.F.)
Local _aThreads := {}
Local _aDados	:= {}
Local _nThreads	:= SuperGetMV("LT_A020THR",.F.,20)//Número de threads máxima. A quantidade a ser usada vai depender do número de registros
Local _nRegProc	:= 0
Local _nInicio	:= 0
Local _cJobFile := ''
Local _aJobAux  := {}
Local _nPos		:= 0
Local _nRetry_0	:= 0
Local _nRetry_1	:= 0
Local _aProcsOk	:= {}
Local _oDlgOcorr:= Nil
Local _oOcorr	:= Nil
Local _cArqLog	:= "\temp\AGLT020_"
Local _cThreadP	:= CValToChar(ThreadID())
//Aborta caso o usuário cancele o Pergunte
If !Pergunte("AGLT020",.T.)
	Return
EndIf

// Separa lista apenas com Setores marcados
For _nX:=1 To Len(_aSetOri)
	If _aSetOri[_nX,1] == .T. // marcado
		aAdd(_aSetores,_aSetOri[_nX,2])
		_cSetores+=';'+_aSetOri[_nX,2]
	EndIf
Next _nX

// Separa lista apenas com Eventos marcados
For _nX:=1 To Len(_aEveOri)
	If _aEveOri[_nX,1] == .T. // marcado
		aAdd(_aEventos,_aEveOri[_nX,3])
		// Grava valor digitado pelo usuario na tabela
		ZL8->(DBSeek(cFilAnt+_aEveOri[_nX,3]))
		ZL8->(RecLock("ZL8",.F.))
		ZL8->ZL8_VALOR:=_aEveOri[_nX,6]
		ZL8->(MSUnLock())
	EndIf
Next _nX

If Len(_aSetores) == 0 .Or. Len(_aEventos) == 0
	MsgStop("Campos obrigatórios não foram informados corretamente! Informe pelo menos um Evento e um Setor.","AGLT02033")
	Return
EndIf

//Busca lista de Linhas que serão processadas
_cSetores := "% "+ FormatIn(SubStr(_cSetores,2,Len(_cSetores)),';') + " %"

If MV_PAR13 == 1 //1-Produtores 2-Fretistas
	_cFiltro := "% ('P','T') %"
Else
	_cFiltro := "% ('F','T') %"
EndIf
//Busco qual o último evento a ser processado. Quando executado, ele precisa ser sempre o último, logo, sempre
//que algum evento For excluído ele também deve ser, assim, forçamos o usuário a rodá-lo novamente.
//Aproveito e retorno se ele já foi executado para os parâmetros informados, pois se For geração, não deixo continuar.
_cAlias := GetNextAlias()
BeginSql alias _cAlias
	SELECT ZL8_COD, ZL8_DESCRI,
		(SELECT 'S' FROM %Table:ZLF%
			WHERE D_E_L_E_T_ = ' '
			AND ZL8_FILIAL = ZLF_FILIAL
			AND ZL8_COD = ZLF_EVENTO
			AND ZL8_FILIAL = %xFilial:ZL8%
			AND ZLF_SETOR IN %exp:_cSetores%
			AND ZLF_LINROT BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
			AND ZLF_A2COD BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
			AND ZLF_A2LOJA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			FETCH FIRST 1 ROWS ONLY) GEROU
	FROM %Table:ZL8%
	WHERE D_E_L_E_T_ = ' '
	AND ZL8_FILIAL = %xFilial:ZL8%
	AND ZL8_PRIORI = '999'
	AND ZL8_PERTEN IN %exp:_cFiltro%
EndSql

// Confirma funcao de Apagar Eventos
If _lApagar
	For _nX:=1 To Len(_aEveOri)//Adiciono o evento 999 na lista dos eventos a serem processados
		If _aEveOri[_nX,3] == (_cAlias)->ZL8_COD .And. _aEveOri[_nX,1] == .F.
			aAdd(_aEventos,_aEveOri[_nX,3])
		EndIf
	Next _nX

If !MsgYesNo("Confirma a EXCLUSÃO dos eventos selecionados? "+ IIf(!Empty((_cAlias)->ZL8_COD),"Para garantir a integridade do cálculo o evento " +;
				(_cAlias)->ZL8_COD + " - " + AllTrim((_cAlias)->ZL8_DESCRI) + " também foi incluído na lista dos eventos a "+;
				"serem excluídos e, se necessário, deverá ser recalculado.",""),"AGLT02034")
		(_cAlias)->(DBCloseArea())
		Return
	EndIf
Else
	If AllTrim((_cAlias)->GEROU) == 'S'
		MsgStop("Foi identificado que o evento "+(_cAlias)->ZL8_COD + " - " + AllTrim((_cAlias)->ZL8_DESCRI) + " já foi calculado para os parâmetros informados."+;
				"Nenhum evento pode ser gerado enquanto o cálculo do evento citado não excluído. O processo será abortado!","AGLT02035")
		(_cAlias)->(DBCloseArea())
		Return
	EndIf
EndIf

(_cAlias)->(DBCloseArea())
If !_lApagar
	If MV_PAR13 == 1 //1-Produtores 2-Fretistas
		_cFiltro := "% AND ZLD_RETIRO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR03+"' "
		_cFiltro += " AND ZLD_RETILJ BETWEEN '"+MV_PAR02+"' AND '"+MV_PAR04+"' "
		_cFiltro += " AND A2_COD = ZLD_RETIRO "
		_cFiltro += " AND A2_LOJA = ZLD_RETILJ "
		_cFiltro2 := "% AND ZLF_A2COD LIKE 'P%'%"
		_cCampos := "% ZLD_RETIRO FORNEC, ZLD_RETILJ LOJA %"
		_cGroup := "% ZLD_RETIRO, ZLD_RETILJ %"
	Else
		_cFiltro := "% AND ZLD_FRETIS BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR03+"' "
		_cFiltro += " AND ZLD_LJFRET BETWEEN '"+MV_PAR02+"' AND '"+MV_PAR04+"' "
		_cFiltro += " AND A2_COD = ZLD_FRETIS "
		_cFiltro += " AND A2_LOJA = ZLD_LJFRET "
		_cFiltro2 := "% AND ZLF_A2COD LIKE 'G%'%"
		_cCampos := "% ZLD_FRETIS FORNEC, ZLD_LJFRET LOJA %"
		_cGroup := "% ZLD_FRETIS, ZLD_LJFRET %"
	EndIf

	If MV_PAR11 == 2 //Filtra apenas donos de tanque coletivo
		_cFiltro += " AND A2_L_TANQ||A2_L_TANLJ <> A2_COD||A2_LOJA "
	EndIf
	If MV_PAR12 == 2 //Filtra apenas usuários de tanque coletivo
		_cFiltro += " AND A2_L_TANQ = A2_L_TANLJ AND A2_COD = A2_LOJA "
	EndIf
	_cFiltro += " %"

	_cAlias := GetNextAlias()
	BeginSql alias _cAlias	
		SELECT ZLD_FILIAL FILIAL, ZLD_SETOR SETOR, ZLD_LINROT LINHA, %exp:_cCampos%
			FROM %Table:ZLD% ZLD, %Table:SA2% SA2
			WHERE ZLD.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			%exp:_cFiltro%
			AND ZLD_FILIAL = %xFilial:ZLD%
			AND ZLD_SETOR IN %exp:_cSetores%
			AND ZLD_LINROT BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
			AND ZLD_DTCOLE BETWEEN %exp:ZLE->ZLE_DTINI% AND %exp:ZLE->ZLE_DTFIM%
			GROUP BY ZLD_FILIAL, ZLD_SETOR, ZLD_LINROT, %exp:_cGroup%
		UNION 
		SELECT ZLF_FILIAL, ZLF_SETOR SETOR, ZLF_LINROT LINHA, ZLF_A2COD FORNEC, ZLF_A2LOJA LOJA
			FROM %Table:ZLF% ZLF, %Table:SA2% SA2
			WHERE ZLF.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND A2_COD = ZLF_A2COD
			AND A2_LOJA = ZLF_A2LOJA
			%exp:_cFiltro2%
			AND ZLF_FILIAL = %xFilial:ZL3%
			AND ZLF_SETOR IN %exp:_cSetores%
			AND ZLF_LINROT BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
			AND ZLF_A2COD BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR03%
			AND ZLF_A2LOJA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
			AND ZLF_CODZLE = %exp:ZLE->ZLE_COD%
			GROUP BY ZLF_FILIAL, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD , ZLF_A2LOJA
			ORDER BY FILIAL, SETOR, LINHA, FORNEC, LOJA
	EndSql
	Count To _nTotReg
	(_cAlias)->( DBGoTop() )

	PutGlbValue("_nQtdProc","0")
	GlbUnLock()

	While (_cAlias)->( !Eof() )
		aAdd(_aDados,{(_cAlias)->SETOR,(_cAlias)->LINHA,(_cAlias)->FORNEC,(_cAlias)->LOJA})
		(_cAlias)->(DBSkip())
	EndDo
	(_cAlias)->(DBCloseArea())

	//Analisa a quantidade de Threads X nRegistros
	If _nTotReg == 0
		MsgAlert("Não foram encontrados registros para serem processados.","AGLT02036")
		Return
	ElseIf _nThreads == 0// Se o número de Threads estiver 0, indica que está desligado o multithread
		_aThreads := ARRAY(1)
	Else //Subo threads com média de 30 registros, limitado ao número de threads definida no _nThreads
		If Int(_nTotReg/20) < _nThreads
			_nThreads := IIf(Int(_nTotReg/30)==0,1,Int(_nTotReg/30))
		EndIf
		_aThreads := ARRAY(_nThreads)
	EndIf
	ProcRegua(_nTotReg/_nThreads,"Gerando eventos por MultiThread... Aguarde...")

	//Calcula o registro original de cada thread e aciona thread gerando arquivo de fila.
	For _nX:=1 to _nThreads
		_aThreads[_nX]:={1,1}
		// Registro inicial para processamento
		_nInicio := IIf(_nX==1,1,_aThreads[_nX-1,2]+1)
		// Quantidade de registros a processar
		_nRegProc += IIf(_nX==Len(_aThreads),_nTotReg-_nRegProc,Int(_nTotReg/_nThreads))
		_aThreads[_nX,1] := _nInicio
		_aThreads[_nX,2] := _nRegProc
	Next nX

	If _nThreads > 1// Só gero via JOB quando houver mais de uma thread
		For _nX :=1 to _nThreads
			// Informacoes do semaforo
			_cJobFile:= _cArqLog + CriaTrab(Nil,.F.)+".job"
			// Adiciona o nome do arquivo de Job no array aJobAux
			aAdd(_aJobAux,{StrZero(_nX,2),_cJobFile})
			// Inicializa variavel global de controle de thread
			_cJobAux:="AGLT020J"+_cThreadP+cEmpAnt+cFilAnt+StrZero(_nX,2)
			PutGlbValue(_cJobAux,"0")
			GlbUnLock()
			//Dispara Thread
			StartJob("U_AGLT020J",GetEnvServer(),.F.,cEmpAnt,cFilAnt,_aDados,_aThreads[_nX,1],_aThreads[_nX,2],_cJobFile,StrZero(_nX,2),_aEventos,_lApagar,ZLE->ZLE_COD,MV_PAR13,_cThreadP,totvs.framework.users.rpc.getAuthToken())
		Next _nX
		//Controle de Seguranca para MULTI-THREAD
		For _nX :=1 to _nThreads
			_nPos := aScan(_aJobAux,{|x|x[1]==StrZero(_nX,2)})
			// Informacoes do semaforo
			_cJobFile:= _aJobAux[_nPos,2]
			// Inicializa variavel global de controle de thread
			_cJobAux:="AGLT020J"+_cThreadP+cEmpAnt+cFilAnt+StrZero(_nX,2)
			//Analise das Threads em Execucao
			While .T.
				IncProc("Processando registro " + GetGlbValue("_nQtdProc") + " de " + cValToChar(_nTotReg) + "...")
				Do Case
					//Tratamento para erro de subida de Thread
					Case GetGlbValue(_cJobAux) == '0'
						If _nRetry_0 > 5
							Final("AGLT02037-Não foi possivel realizar a subida da thread")
						Else
							_nRetry_0 ++
						EndIf
					//Tratamento para erro de conexão
					Case GetGlbValue(_cJobAux) == '1'
						If FCreate(_cJobFile) # -1
							If _nRetry_1 > 5
								fErase(_cJobFile)//Apaga o arquivo de semáforo criado
								Final("AGLT02038-Erro de conexao na thread")
							Else
								// Inicializa variavel global de controle de Job
								PutGlbValue(_cJobAux, "0" )
								GlbUnLock()
								// Dispara thread novamente
								StartJob("U_AGLT020J",GetEnvServer(),.F.,cEmpAnt,cFilAnt,_aDados,_aThreads[_nX,1],_aThreads[_nX,2],_cJobFile,StrZero(_nX,2),_aEventos,_lApagar,ZLE->ZLE_COD,MV_PAR13,_cThreadP,totvs.framework.users.rpc.getAuthToken())
							EndIf
							_nRetry_1 ++
						EndIf
					//Tratamento para erro de aplicação
					Case GetGlbValue(_cJobAux) == '2'
						If FCreate(_cJobFile) # -1
							fErase(_cJobFile)//Apaga o arquivo de semáforo criado
							Final("AGLT02039-Erro de aplicacao na thread")
						EndIf
					//Thread processada corretamente
					Case GetGlbValue(_cJobAux) == '3'
						aAdd(_aProcsOk,"AGLT02040-Processamento Thread :" + _cJobAux + " - Ok ")
						fErase(_cJobFile)//Apaga o arquivo de semáforo criado
						ClearGlbValue(_cJobAux)//Limpa a variável de memória
						Exit
				EndCase
				Sleep(1000)
			End Do
		Next _nX

		//Apresenta mensagens relacionas a execucao das threads
		If Len(_aProcsOk) > 0
			DEFINE MSDIALOG _oDlgOcorr TITLE "Log de processamento" From 8,05 To 20,65 OF oMainWnd
			@ 1,001 LISTBOX _oOcorr Fields HEADER Space(63) SIZE 190,70
			_oOcorr:SetArray(_aProcsOk)
			_oOcorr:bLine := { || {_aProcsOk[_oOcorr:nAT]} }
			DEFINE SBUTTON FROM 18,202 Type 1 ACTION _oDlgOcorr:End() ENABLE OF _oDlgOcorr
			ACTIVATE MSDIALOG _oDlgOcorr
		EndIf
	Else
		U_AGLT020J(cEmpAnt,cFilAnt,_aDados,_aThreads[1,1],_aThreads[1,2],_cJobFile,StrZero(1,2),_aEventos,_lApagar,ZLE->ZLE_COD,MV_PAR13,_cThreadP,totvs.framework.users.rpc.getAuthToken())
		MsgInfo("Eventos gerados com sucesso!","AGLT02041")
	EndIf
Else//Apagar eventos apenas de produtores
	Begin Transaction
	_cFiltro := "UPDATE "+RetSqlName("ZLF")+" SET D_E_L_E_T_ = '*' "
	_cFiltro += " WHERE D_E_L_E_T_ = ' ' "
	_cFiltro += " AND ZLF_FILIAL = '"+xFilial("ZLF")+"' "
	_cFiltro += " AND ZLF_SETOR IN "+ Replace(_cSetores,"%","")
	_cFiltro += " AND ZLF_LINROT BETWEEN '"+MV_PAR09+"' AND '"+MV_PAR10+"' "
	_cFiltro += " AND ZLF_A2COD BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR03+"' "
	_cFiltro += " AND ZLF_A2LOJA BETWEEN '"+MV_PAR02+"' AND '"+MV_PAR04+"' "
	_cFiltro += " AND ZLF_CODZLE = '"+ZLE->ZLE_COD+"' "
	_cFiltro += " AND ZLF_STATUS = 'A' "
	_cFiltro += " AND ZLF_EVENTO IN "+FormatIn(Replace(Replace(AsString(_aEventos),"{",""),"}",""),",")+" "
	_cFiltro += " AND ZLF_A2COD LIKE "+IIf(MV_PAR13==1,"'P%'","'G%'")
	_cFiltro += " AND EXISTS (SELECT 1 FROM "+RetSqlName("SA2")+" WHERE D_E_L_E_T_ = ' ' "
	_cFiltro += " 				AND A2_COD = ZLF_A2COD "
	_cFiltro += " 				AND A2_LOJA = ZLF_A2LOJA "
	If MV_PAR11 == 2 //Filtra apenas donos de tanque coletivo
		_cFiltro += " 			AND A2_L_TANQ||A2_L_TANLJ <> A2_COD||A2_LOJA "
	EndIf
	If MV_PAR12 == 2 //Filtra apenas usuários de tanque coletivo
		_cFiltro += " 			AND A2_L_TANQ = A2_L_TANLJ AND A2_COD = A2_LOJA "
	EndIf
	_cFiltro += ") "
	If TCSqlExec(_cFiltro) < 0
		MsgStop("Erro ao apagar eventos. Acione a TI. Erro: "+AllTrim(TCSQLError()),"AGLT02042")
		_lRet := .F.
	EndIf
	If _lRet .And. MV_PAR13 == 2//Rateio o custo do frete na ZLD no caso de fretistas
		//AtuZLD(cFilAnt,_cSetores,_cLinhaIni,_cLinhaFim,_cFornIni, _cFornFim,_cLojaIni,_cLojaFim)
		_lRet := AtuZLD(cFilAnt,_cSetores,MV_PAR09,MV_PAR10,MV_PAR01,MV_PAR03,MV_PAR02,MV_PAR04)
	EndIf

	If _lRet
		MsgInfo("Eventos apagados com sucesso!","AGLT02043")
	Else
		DisarmTransaction()
		Break
	EndIf
	End Transaction
EndIf
Return

/*
===============================================================================================================================
Programa----------: AGLT020J
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Executa as threads gravando os eventos
Parametros--------: _cEmpAnt,_cFilAnt,_aDados,_nRegIni,_nRegFim,_cJobFile,_cThread,_aEventos,_cMix,_nTipo,_cThreadP,_cToken
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT020J(_cEmpAnt,_cFilAnt,_aDados,_nRegIni,_nRegFim,_cJobFile,_cThread,_aEventos,_lApagar,_cMix,_nTipo,_cThreadP,_cToken)

Local _nX 		:= 0
Local _nI		:= 0
Local _nValor	:= 0
Local _nHd1		:=0
Local _lJob		:= IsBlind()
If _lJob
	// Apaga arquivo ja existente
	If File(_cJobFile)
		fErase(_cJobFile)
	EndIf
	// Criacao do arquivo de controle de jobs
	_nHd1 := MSFCreate(_cJobFile)
EndIf

// STATUS 1 - Iniciando execucao do Job
PutGlbValue("AGLT020J"+_cThreadP+_cEmpAnt+_cFilAnt+_cThread,"1")
GlbUnLock()

If _lJob
	// Seta job para nao consumir licensas
	RpcSetType(3)
	// Seta job para empresa filial desejada
	RpcSetEnv(_cEmpAnt,_cFilAnt,,,'COM')
	totvs.framework.users.rpc.authByToken(_cToken)
EndIf

// STATUS 2 - Conexao efetuada com sucesso
PutGlbValue("AGLT020J"+_cThreadP+_cEmpAnt+_cFilAnt+_cThread,"2")
GlbUnLock()

For _nI := _nRegIni To _nRegFim
	ZLE->(DBSeek(xFilial("ZLE")+_cMix))
	ZL2->(DBSeek(_cFilAnt+_aDados[_nI][1]))
	ZL3->(DBSeek(_cFilAnt+_aDados[_nI][2]))
	SA2->(DBSeek(xFilial("SA2")+_aDados[_nI][3]+_aDados[_nI][4]))

	PutGlbValue("_nQtdProc",cValToChar(Val(GetGlbValue("_nQtdProc"))+1))
	GlbUnLock()
	// Le o array de Eventos p/ rodar formulas
	For _nX := 1 To Len(_aEventos)
		
		// Posiciona no Evento p/ usar tabela na execusao da formula
		ZL8->(DBSeek(_cFilAnt+_aEventos[_nX]))
		// Executa condicao do evento p/ rodar formula
		If _lApagar .Or. &(ZL8->ZL8_CONDIC)
			// Executa formula
			If !_lApagar
				_nValor := &(ZL8->ZL8_FORMUL) 
			EndIf   
			If Empty(_nValor) .Or. _lApagar
				_nValor	:=	0
			EndIf
			// Se For Debito converte para positivo na gravacao
			If ZL8->ZL8_DEBCRE == "D" .And. _nValor < 0
				_nValor := _nValor*-1
			EndIf
			//Grava o evento na ZLF. Se o valor For zero, apaga da ZLF
			If _nTipo == 1 //1-Produtores 2-Fretistas
				GrvZLF(_cFilAnt,ZL2->ZL2_COD,ZL3->ZL3_COD,ZL8->ZL8_COD,ZL8->ZL8_DEBCRE,ZL8->ZL8_MIX,SA2->A2_COD,SA2->A2_LOJA,_nValor,ZL8->ZL8_QTDUNI,_nTipo)
			Else
				// Se For Credito rateia entre os produtores. Se For Debito grava apenas um registro ao fretista
				If ZL8->ZL8_DEBCRE == "C"
					gEvtFrtRat(_cFilAnt,ZL2->ZL2_COD,ZL3->ZL3_COD,ZL8->ZL8_COD,ZL8->ZL8_DEBCRE,ZL8->ZL8_MIX,SA2->A2_COD,SA2->A2_LOJA,_nValor)
				EndIf
				If ZL8->ZL8_DEBCRE == "D"
					GrvZLF(_cFilAnt,ZL2->ZL2_COD,ZL3->ZL3_COD,ZL8->ZL8_COD,ZL8->ZL8_DEBCRE,ZL8->ZL8_MIX,SA2->A2_COD,SA2->A2_LOJA,_nValor,ZL8->ZL8_QTDUNI,_nTipo)
				EndIf
			EndIf
		EndIf
	Next _nX
Next _nI

// STATUS 3 - Processamento efetuado com sucesso
PutGlbValue("AGLT020J"+_cThreadP+_cEmpAnt+_cFilAnt+_cThread,"3")
GlbUnLock()
If _lJob
	RpcClearEnv()
EndIf

Return
