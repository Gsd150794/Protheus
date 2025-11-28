/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Jose Gavetti  |26/11/2025| Chamado 51341. cEmpAnt não deve ter seu conteúdo alterado orientação TOTVS.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIN020
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Rotina de Leitura e Inclusao de titulos - Chamado 38967
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN020

Local oproc := nil

//Grava Log de execução da rotina
U_ITLOGACS( "MFIN020" )

Private MV_PAR01:=Space(200)
Private _cSalva_MV_PAR01 := MV_PAR01

While .T.
	lSair:=.T.

	FWMsgRun( ,{|oproc| lSair:=MFIN020INI(oproc) } , "Processando..." , "Iniciando o processamento..." )

	If lSair
		Exit
	EndIf
EndDo

SET DATE FORMAT TO "DD/MM/YY"

Return

/*
===============================================================================================================================
Programa----------: MFIN020INI
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function MFIN020INI(oproc As Object) As Logical

Local _aParAux	:= {}
Local _aParRet	:= {}
Local _aCpos	:= MFIN020CPS()
Local _aFields	:= {}
Local _nreg		:= 0
Local _aDados	:= {}
Local _apesqui	:= {}
Local _nI		:= 0
Local _nlayout	:= 0
Local _carq		:= ""
Local cCodFor   := ""
Local cCodLoj   := ""
Local _otemp    := nil  , nI

Private oMarkBRW	:= Nil
Private cAliasAux	:= GetNextAlias()
Private _nTotReg	:= 0

MV_PAR01 := _cSalva_MV_PAR01

aAdd( _aParAux , { 6 ,"Selecione arquivo .CSV:"   , MV_PAR01 ,"","","",100,.T.,"Todos os arquivos (*.CSV) |*.CSV","C:\",GETF_LOCALHARD+GETF_MULTISELECT})
aAdd( _aParAux , { 9 , "Deixe o campo acima em branco e clique em OK caso queira gerar um arquivo CSV de modelo.",200,14,.T. } ) 	//| 01 |

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

	If !ParamBox( _aParAux , "Rotina de inclusao de titulos automatica" , @_aParRet )
		Return .T.
	EndIf

	_cSalva_MV_PAR01 := MV_PAR01

	If Empty(MV_PAR01)
		_aHeader:={"VALOR DO TITULO","VENCIMENTO DO TITULO","CODIGO FORNECEDOR","LOJA FORNECEDOR"}
		_aCols:={{"","","",""}}
		U_ITGERARQ( "" , _aHeader , _aCols )
		Loop
	EndIf


	oproc:cCaption := ("Abrindo arquivo...")
	ProcessMessages()

	If (Upper(right(AllTrim(MV_PAR01),4))) == ".CSV"

		_carq := AllTrim(MV_PAR01)

		If FT_FUSE(_carq) == -1

			U_ITMsg("1-Falha ao abrir o arquivo: "+_carq,"Erro",,1)

			Loop//Return .F.

		EndIf

		FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
		_cDados := FT_FREADLN()

		If Upper(AllTrim(_cDados)) == Upper("VALOR DO TITULO;VENCIMENTO DO TITULO;CODIGO FORNECEDOR;LOJA FORNECEDOR")///********************
			_nlayout := 1 //Layout Padrão
		EndIf

		//Fecha arquivo e prepara parâmetro com arquivo convertido
		FT_FUSE()

	Else

		U_ITMsg("O arquivo informado: "+AllTrim(MV_PAR01)+" não tem extenção [ .CSV ] ",;
			"Arquivo inválido",;
			"Favor informar uma arquivo no formato [ .CSV ].")
		Loop//Return .F.

	EndIf

	//Escolhido Layout continua leitura
	If _nlayout > 0

		If FT_FUSE(_carq) == -1

			U_ITMsg("2-Falha ao abrir o arquivo: "+_carq,"Erro",,1)
			Loop

		EndIf

		FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO

		_nReg:= FT_FLASTREC()

		ProcRegua(_nReg)

		FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO

		If _nReg == 0 //O arquivo informado nao possui nenhuma linha de dados

			U_ITMsg("O arquivo informado para relizar a importação não possui dados.",;
				"Arquivo inválido",;
				"Favor verificar se o arquivo informado esta no formato correto.")
			Loop

		EndIf

		If _nlayout == 1
			_aDados := MFIN020L(_nreg,oproc) //Faz leitura dos dados
		EndIf

		If Len(_aDados) <= 0
			U_ITMsg( "Não foram encontrados registros válidos no arquivo!" , "Atenção!",,1 )
			Loop
		EndIf
	Else
		U_ITMsg("O arquivo "+_carq+" informado para relizar a importação não tem o layout padrão.",;
			"Arquivo com formato inválido",;
			"O CSV deve ter as colunas [ VALOR DO TITULO;VENCIMENTO DO TITULO;CODIGO FORNECEDOR;LOJA FORNECEDOR ] e o mesmo deve ser salvo "+;
			"no Excel no formato [ CSV (separado por virgulas) ] e "+;
			"no LibreOffice Calc com Demilitador de campo Ponto e Virgula e sem delimitador de texto.",1)
		Loop
	EndIf

	Exit

EndDo
//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select(cAliasAux) > 0
	oproc:cCaption := ("Apagando temporário...")
	ProcessMessages()
	_otemp:Delete()
EndIf

oproc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()
_otemp := FWTemporaryTable():New( cAliasAux, _aCpos )

oproc:cCaption := ("Criando indices do arquivo temporário...")
ProcessMessages()

_otemp:AddIndex( "01", {"FILIAL","TITU"} )

_otemp:Create()

_aMarcados:={} 

SE2->( DBSetOrder(1) )//E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

For  _nI := 1 TO Len(_aDados)

	oproc:cCaption := ("Lendo: "+ StrZero( _nI , 6 ) +" de "+ StrZero( Len(_aDados) , 6 ) +" Registros..." )
	ProcessMessages()

	If Empty(_aDados[_nI][06])
		cCodFor := Posicione("SA2",3,xFilial("SA2")+_aDados[_nI][05],"A2_COD")
		cCodLoj	:= Posicione("SA2",3,xFilial("SA2")+_aDados[_nI][05],"A2_LOJA")
	EndIf
	(cAliasAux)->( DBAPPEND(  ) )

	(cAliasAux)->FILIAL  := xFilial("SE2")
	(cAliasAux)->PREFIXO := _aDados[_nI][01]
	(cAliasAux)->TITU    := _aDados[_nI][02]
	(cAliasAux)->TIPO    := _aDados[_nI][03]
	(cAliasAux)->NATUREZA:= _aDados[_nI][04]
	(cAliasAux)->FORNECE := IIf (!Empty(cCodFor),cCodFor,_aDados[_nI][05])
	(cAliasAux)->LOJA	 := IIf (!Empty(cCodLoj),cCodLoj,_aDados[_nI][06])
	If !Empty(_aDados[_nI][06])
		(cAliasAux)->NOME	 := Posicione("SA2",1,xFilial("SA2")+_aDados[_nI][05]+_aDados[_nI][06],"A2_NOME")
	Else
		(cAliasAux)->NOME	 := Posicione("SA2",1,xFilial("SA2")+cCodFor+cCodLoj,"A2_NOME")
	EndIf
	(cAliasAux)->EMISSAO := _aDados[_nI][07]
	(cAliasAux)->VENCIME := _aDados[_nI][08]
	(cAliasAux)->WKVALOR := _aDados[_nI][09]

	If SE2->( DBSeek( xFilial("SE2") + (cAliasAux)->PREFIXO  + (cAliasAux)->TITU  + Space(Len(SE2->E2_PARCELA)) + (cAliasAux)->TIPO + (cAliasAux)->FORNECE + (cAliasAux)->LOJA	) )
		_aDados[_nI][11]:=_aDados[_nI][11]+"[O titulo já existe: "+xFilial("SE2") +"+"+ (cAliasAux)->PREFIXO  +"+"+ (cAliasAux)->TITU +"+"+ Space(Len(SE2->E2_PARCELA)) +"+"+(cAliasAux)->TIPO +"+"+ (cAliasAux)->FORNECE +"+"+ (cAliasAux)->LOJA+"] "
		_aDados[_nI][10]:='R'
	EndIf

	(cAliasAux)->WKSTATUS:= _aDados[_nI][10]
	(cAliasAux)->ERRO    := _aDados[_nI][11]
	(cAliasAux)->ERRO    := AllTrim((cAliasAux)->ERRO)//Para tirar os espacos da frente

	If aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU }) = 0
		aAdd(_aMarcados,{(cAliasAux)->FILIAL+(cAliasAux)->TITU,.F., "" })
	EndIf

Next _nI

aAdd( _aFields , { "Filial"	 		   	, {|| (cAliasAux)->FILIAL + " - "+AllTrim(FWFilialName(cEmpAnt,(cAliasAux)->FILIAL,1)) }  	, "C" , "@!" , 0 , 12, 0 } )
aAdd( _aFields , { "Prefixo"			, {|| (cAliasAux)->PREFIXO }									, "C" , "@!" 				, 0 , 10, 0 } )
aAdd( _aFields , { "Titulo"				, {|| (cAliasAux)->TITU  }										, "C" , "@!" 				, 0 , 10, 0 } )
aAdd( _aFields , { "Tipo"    			, {|| (cAliasAux)->TIPO  }										, "C" , "@!" 				, 0 , 10, 0 } )
aAdd( _aFields , { "Natureza"			, {|| (cAliasAux)->NATUREZA  }									, "C" , "@!" 				, 0 , 10, 0 } )
aAdd( _aFields , { "Fornecedor"			, {|| (cAliasAux)->FORNECE + " - " + (cAliasAux)->LOJA }  		, "C" , "@!" , 0 , 08		, 0 } )
aAdd( _aFields , { "Nome"				, {|| (cAliasAux)->NOME }										, "C" , "@!" , 0 , 30		, 0 } )
aAdd( _aFields , { "Valor"              , {|| (cAliasAux)->WKVALOR }									, "N" , "@E 999,999,999.99" , 0 ,015, 2 } )
aAdd( _aFields , { "Dt. Emissao"        , {|| (cAliasAux)->EMISSAO }								    , "D" , "@D"                , 0 , 8 , 0 } )
aAdd( _aFields , { "Dt. Vencto"         , {|| (cAliasAux)->VENCIME }								    , "D" , "@D"                , 0 , 8 , 0 } )
aAdd( _aFields , { "Observação"			, {|| (cAliasAux)->ERRO  }									    , "C" , ""  				, 0 ,100, 0 } )


_apesqui := {}
aAdd(_apesqui,{"Titulo",{{"Filial","C",2,0,"Filial",,}, {"Titulo","C",9,0,"Titulo",,}},1})

oMarkBRW:=FWMarkBrowse():New()		   											  		// Inicializa o Browse
oMarkBRW:SetAlias( cAliasAux )			   												// Define Alias que será a Base do Browse
oMarkBRW:SetDescription( "Rotina de inclusao de titulos automatica" )					// Define o titulo do browse de marcacao
oMarkBRW:SetFieldMark( "MARCA" )														// Define o campo que sera utilizado para a marcação
oMarkBRW:SetMenuDef( 'MFIN020' )														// Força a utilização do menu da rotina atual
oMarkBRW:SetAllMark( {|| .F./*oMarkBRW:AllMark()*/ } )									// Ação do Clique no Header da Coluna de Marcação
oMarkBRW:SetCustomMarkRec({||If((cAliasAux)->WKSTATUS="A",U_MFIN020R("MARCAR"),.F.)})  // Indica o Code-Block executado para validar a marcação/desmarcação do registro
oMarkBRW:AddLegend( "(cAliasAux)->WKSTATUS = 'A'","GREEN" , "Aceitos")                  // Permite adicionar legendas no Browse
oMarkBRW:AddLegend( "(cAliasAux)->WKSTATUS = 'R'","RED"   , "Rejeitados")               // Permite adicionar legendas no Browse
oMarkBRW:AddLegend( "(cAliasAux)->WKSTATUS = 'P'","BLUE"  , "Processados")              // Permite adicionar legendas no Browse
oMarkBRW:SetFields( _aFields )													 		// Campos para exibição
oMarkBRW:SetSeek(.T., _apesqui)                                                         // Indica os campos que serão adicionados as colunas do Browse
oMarkBRW:AddButton( "Confirmar"         , {|| FWMsgRun( ,{|oproc| U_MFIN020B(oproc)},"Aguarde","Processando..."           ) } ,, 4 )// Adiciona um botão
oMarkBRW:AddButton( "Totais"            , {|| FWMsgRun( ,{|| MFIN020Totais()}, "Aguarde","Totalizando titulos marcados...") } ,, 4 )// Adiciona um botão
oMarkBRW:AddButton( "Marca Todos"       , {|| FWMsgRun( ,{|| MFIN13Todos(.T.)  }, "Aguarde","Marcando..."   ) } ,, 4 )// Adiciona um botão
oMarkBRW:AddButton( "Desmarca Todos"    , {|| FWMsgRun( ,{|| MFIN13Todos(.F.)  }, "Aguarde","Desmarcando...") } ,, 4 )// Adiciona um botão
oMarkBRW:DisableConfig()                                                                // Desabilita a utilização das configurações do Browse
oMarkBRW:Activate()																		// Ativacao da classe

(cAliasAux)->( DBCloseArea() )

Return .F.

/*
===============================================================================================================================
Programa----------: MFIN020Totais
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Mostra totais
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN020Totais()

Local _aTot:={0,0,0,0} , _cTexto:=""
(cAliasAux)->( DBGoTop() )

While (cAliasAux)->( !Eof() )

	If (cAliasAux)->WKSTATUS $ "A" .And. !Empty((cAliasAux)->MARCA)
		_aTot[1]+=(cAliasAux)->WKVALOR
		_aTot[2]+=1
	EndIf

	(cAliasAux)->( DBSkip() )

EndDo

_cTexto:="TOTAIS DOS TITULOS MARCADOS: "+cValToChar(_aTot[2])+CHR(13)+CHR(10)
_cTexto+="** VALOR TOTAL: R$ "+AllTrim(TRANSF(_aTot[1],"@E 999,999,999,999.99"))+" **"+CHR(13)+CHR(10)
U_ITMsg(_cTexto,"TOTAIS",,2)

(cAliasAux)->( DBGoTop() )
oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .T. )
oMarkBRW:Refresh()

Return

/*
===============================================================================================================================
Programa----------: MFIN020CNS
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Rotina de consulta do cadastro completo do Cliente
Parametros--------: _cChama: da onde chama
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
User Function MFIN020R(_cChama)

Local lRet:=.T.

If _cChama == "MARCAR"
	If !oMarkBRW:IsMark() //Testa pq do duplo clique ele chama essa função 2 veses OR botão Alterar
		(oMarkBRW:Alias())->MARCA := oMarkBRW:Mark()
		If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU })) # 0
			_aMarcados[_nPos,2]:=.T.
		EndIf
	Else
		(oMarkBRW:Alias())->MARCA := ""
		If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU })) # 0
			_aMarcados[_nPos,2]:=.F.//A colocação do .T. esta dentro da função MFIN13Tela("SE1",nReg,4)
			_aMarcados[_nPos,3]:="" //O preenchimento esta dentro da função MFIN13Tela("SE1",nReg,4)
		EndIf
	EndIf
EndIf

DBSelectArea(cAliasAux)//Tem volta para o alias do browse pq senão dá erro

Return lRet

/*
===============================================================================================================================
Programa----------: MFIN020CPS
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Define a criação de campos para exibição da análise
Retorno-----------: aRet - Campos que serão criados e exibidos na tela
===============================================================================================================================
*/
Static Function MFIN020CPS()

Local _aCpos := {}

aAdd( _aCpos , { "WKSTATUS"	    , "C" , 01, 0 } )
aAdd( _aCpos , { "MARCA"		, "C" , 01, 0 } )
aAdd( _aCpos , { "FILIAL"		, "C" , TamSX3("E2_FILIAL")[01]	, 0 } )
aAdd( _aCpos , { "PREFIXO"		, "C" , TamSX3("E2_PREFIXO")[01], 0 } )
aAdd( _aCpos , { "TITU"			, "C" , TamSX3("E2_NUM")[01]	, 0 } )
aAdd( _aCpos , { "TIPO"		    , "C" , TamSX3("E2_TIPO")[01]	, 0 } )
aAdd( _aCpos , { "NATUREZA"		, "C" , TamSX3("E2_NATUREZ")[01], 0 } )
aAdd( _aCpos , { "FORNECE"		, "C" , TamSX3("E2_FORNECE")[01], 0 } )
aAdd( _aCpos , { "LOJA"			, "C" , TamSX3("A1_LOJA")[01]	, 0 } )
aAdd( _aCpos , { "NOME"			, "C" , TamSX3("A2_NOME")[01]	, 0 } )
aAdd( _aCpos , { "EMISSAO"		, "D" , 08, 0 } )
aAdd( _aCpos , { "VENCIME"		, "D" , 08, 0 } )
aAdd( _aCpos , { "WKVALOR"		, "N" , 18, 2 } )
aAdd( _aCpos , { "ERRO"	  	    , "M" , 10, 0 } )

Return( _aCpos )

/*
===============================================================================================================================
Programa----------: MFIN020B
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Processa os titulos marcados
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: NIL
===============================================================================================================================
*/
User Function MFIN020B(oproc)

Local _nRegAtu	:= 0
Local _nTotReg	:= (cAliasAux)->( LASTREC() )
Local _nRegSel	:= 0
Local _nRegErro	:= 0
Local _nRecSalva:= 0


(cAliasAux)->( DBGoTop() )

While (cAliasAux)->( !Eof() )

	_nRegAtu++
	oproc:cCaption := ("Processando... ["+ StrZero(_nRegAtu,6) +"] de ["+ StrZero(_nTotReg,6) +"] Incluidos: "+StrZero(_nRegSel,5) )
	ProcessMessages()
	If (cAliasAux)->WKSTATUS = "A"
		oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .T. )
	Else
		(cAliasAux)->(DBSkip())
		Loop
	EndIf

	If (cAliasAux)->WKSTATUS = 'A' .And. oMarkBRW:IsMark()//!Empty((cAliasAux)->MARCA)

		(cAliasAux)->(DBSkip())
		_nRecSalva:=(cAliasAux)->(RECNO())
		(cAliasAux)->(DBSkip(-1))
		_cErro:=""
		If MFIN13Gera()//GERA SE2
			(cAliasAux)->WKSTATUS:='P'
			_nRegSel++
			oMarkBRW:MarkRec()
			oMarkBRW:Refresh()
		Else
			_nRegErro++
			(cAliasAux)->WKSTATUS:='R'
			(cAliasAux)->ERRO  :=_cErro
		EndIf
		(oMarkBRW:Alias())->MARCA := ""//Desmarca Sempre
		If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU })) # 0
			_aMarcados[_nPos,2]:=.F.
		EndIf

		(cAliasAux)->(DBGoTo(_nRecSalva))
	Else
		(cAliasAux)->( DBSkip() )
	EndIf

EndDo

(cAliasAux)->( DBGoTop() )

_cMen:=AllTrim(Str(_nRegAtu))+" registro(s) processado(s)."+CHR(13)+CHR(10)
_cMen+=AllTrim(Str(_nRegSel))+" registro(s) Incluido(s) com sucesso."+CHR(13)+CHR(10)
_cMen+=AllTrim(Str(_nRegErro))+" registro(s) com erro."

U_ITMsg(_cMen,"Concluído!",,2)

(cAliasAux)->( DBGoTop() )
oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .T. )
//oMarkBRW:GoTop()
oMarkBRW:Refresh()
ProcessMessages()

Return

/*
===============================================================================================================================
Programa----------: MFIN020L
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Faz a leitura de dados no layout 
Parametros--------: _nreg - número de linhas do arquivo
				    oproc - objeto da barra de processamento
Retorno-----------: _aDados - array com dados carregados do arquivo
===============================================================================================================================
*/
Static Function MFIN020L(_nreg,oproc)

Local _nCont 	:= 0
Local _cdados	:= ""
Local _alinha	:= {}
Local _aDados 	:= {}
Local _nValorTotal:=0
Local _nColVlB:= 1
Local _nColVen:= 2
Local _nColFor:= 3
Local _nColLoj:= 4
Local _cNatura:= SuperGetMV("IT_NATTIT",.F.,'232019')


FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
FT_FSKIP()

cNumero := fGerNum()

While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO

	_nCont++
	oproc:cCaption := ( "Lendo linha " + StrZero(_nCont,5) + " de " + StrZero(_nreg,5) + "." )
	ProcessMessages()

	_cDados := FT_FREADLN()
	_aLinha := StrTokArr(_cDados,";")

	//Verifica se é final de arquivo
	If AllTrim(_cdados) = ';;' .And. _nCont > 5
		Exit
	EndIf

	//Verifica se é linha válida
	If Len(_aLinha) < 3
		FT_FSKIP()
		Loop
	EndIf

	_alinha[_nColVlB]:=StrTran(_alinha[_nColVlB],".","")//Tira o seprador de milhar brasileiro
	_nValorTotal:=Val(StrTran(_alinha[_nColVlB],",","."))//Troca os sepradores de decimal brasileiro para o ingles
	_dVencto:=CTOD(_alinha[_nColVen])
	_cErro:=""
	_cTipoErro:="A"//WKSTATUS

	If Len(_aLinha[_nColFor]) > 6
		cCodFor := Posicione("SA2",3,xFilial("SA2")+_aLinha[_nColFor],"A2_COD")
		cCodLoj	:= Posicione("SA2",3,xFilial("SA2")+_aLinha[_nColFor],"A2_LOJA")

		SA2->(DBSetOrder(1))

		If !SA2->(DBSeek(xFilial("SA2")+cCodFor+cCodLoj))
			_cErro:="[Fornnecedor+Loja "+AllTrim(cCodFor+cCodLoj)+" nao cadastrado.] "
			_cTipoErro:='R'
		ElseIf SA2->A2_MSBLQL = '1'
			_cErro:="[Fornnecedor+Loja "+AllTrim(cCodFor+cCodLoj)+" bloqueado.] "
			_cTipoErro:='R'
		EndIf
		If _nValorTotal <= 0
			_cErro+="[Valor invalido.] "
			_cTipoErro:='R'
		EndIf
		If Empty(_dVencto)
			_cErro+="[Data de Vencimento invalida.] "
			_cTipoErro:='R'
		ElseIf _dVencto < dDatabase
			_cErro+="[Data de Vencimento menor que hoje.] "
			_cTipoErro:='R'
		EndIf

	aAdd(_aDados,{"TAC"              ,; //01 - PREFIXO
	cNumero            ,;	//02 - num titulo
	'RC'	 		     ,;	//03 - TIPO
	_cNatura           ,;	//04 - Natureza
	_alinha[_nColFor]  ,;	//05 - cliente
	" "			 ,; //06 - loja do cliente
	dDatabase          ,; //07 - Data de emissao
	_dVencto           ,; //08 - VENCIMENTO
	_nValorTotal       ,;	//09 - Valor Titulo
	_cTipoErro         ,;	//10 - Bolas
	_cErro             })	//11 - Erro WKSTATUS

	cNumero :=Soma1( cNumero)

	_cErro:=""

	Else
		If Len(_aLinha) < 4 .Or. Empty(Val(_alinha[_nColLoj]))
			_cLoja:=StrZero(1,Len(SE2->E2_LOJA))
		Else
			_cLoja:=StrZero(Val(_alinha[_nColLoj]),Len(SE2->E2_LOJA))
		EndIf
		If !SA2->(DBSeek(xFilial("SA2")+_alinha[_nColFor]+_cLoja))
			_cErro:="[Fornnecedor+Loja "+AllTrim(_alinha[_nColFor]+_cLoja)+" nao cadastrado.] "
			_cTipoErro:='R'
		ElseIf SA2->A2_MSBLQL = '1'
			_cErro:="[Fornnecedor+Loja "+AllTrim(_alinha[_nColFor]+_cLoja)+" bloqueado.] "
			_cTipoErro:='R'
		EndIf
		If _nValorTotal <= 0
			_cErro+="[Valor invalido.] "
			_cTipoErro:='R'
		EndIf
		If Empty(_dVencto)
			_cErro+="[Data de Vencimento invalida.] "
			_cTipoErro:='R'
		ElseIf _dVencto < dDatabase
			_cErro+="[Data de Vencimento menor que hoje.] "
			_cTipoErro:='R'
		EndIf

	aAdd(_aDados,{"TAC"              ,; //01 - PREFIXO
	cNumero            ,;	//02 - num titulo
	'RC'	 		     ,;	//03 - TIPO
	_cNatura           ,;	//04 - Natureza
	_alinha[_nColFor]  ,;	//05 - cliente
	_cLoja			 ,; //06 - loja do cliente
	dDatabase          ,; //07 - Data de emissao
	_dVencto           ,; //08 - VENCIMENTO
	_nValorTotal       ,;	//09 - Valor Titulo
	_cTipoErro         ,;	//10 - Bolas
	_cErro             })	//11 - Erro WKSTATUS

	cNumero :=Soma1( cNumero)

	_cErro:=""
	EndIf

	FT_FSKIP()

EndDo

Return _aDados

/*
===============================================================================================================================
Programa----------: MFIN13Gera()
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Gera o titulo
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function MFIN13Gera()

Local _aAutSE2	:= {}
Local _lOk		:= .T.
Local _nModAux	:= nModulo
Local _cModAux	:= cModulo

Private lMsErroAuto := .F.

If Empty((cAliasAux)->FORNECE   ) .OR.;
		Empty((cAliasAux)->LOJA      ) .OR.;
		Empty((cAliasAux)->NATUREZA  ) .OR.;
		Empty((cAliasAux)->WKVALOR   ) .OR.;
		Empty((cAliasAux)->VENCIME   ) .OR.;
		Empty((cAliasAux)->EMISSAO   )
	_cErro:="Erro: [Fornecedor ou loja ou natreza ou valor ou datas não preenchidos]"
	Return .F.
EndIf


aAdd( _aAutSE2 , { "E2_PREFIXO"	, (cAliasAux)->PREFIXO , NIL } )
aAdd( _aAutSE2 , { "E2_NUM"		, (cAliasAux)->TITU    , NIL } )
aAdd( _aAutSE2 , { "E2_TIPO"	, (cAliasAux)->TIPO    , NIL } )
aAdd( _aAutSE2 , { "E2_NATUREZ"	, (cAliasAux)->NATUREZA, NIL } )
aAdd( _aAutSE2 , { "E2_FORNECE"	, (cAliasAux)->FORNECE , NIL } )
aAdd( _aAutSE2 , { "E2_LOJA"	, (cAliasAux)->LOJA	   , NIL } )
aAdd( _aAutSE2 , { "E2_EMISSAO"	, (cAliasAux)->EMISSAO , NIL } )
aAdd( _aAutSE2 , { "E2_VENCTO"	, (cAliasAux)->VENCIME , NIL } )
//aAdd(_aAutSE2, { "E2_VENCREA"	, DataValida((_cAlias)->E2_VENCREA), nil } )
aAdd( _aAutSE2 , { "E2_VALOR"	, (cAliasAux)->WKVALOR , NIL } )
aAdd( _aAutSE2 , { "E2_ORIGEM"	, "FINA050 "		   , NIL } )

nModulo := 6
cModulo := "FIN"

MSExecAuto( {|x,y,z| Fina050(x,y,z) } , _aAutSE2 , 3 , 3 )

If lMsErroAuto
	_cErro:="Erro: ["+AllTrim(MostraErro())+"]"
	_lOk := .F.
Else
	SE2->( DBSetOrder(1) )//E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
	If !SE2->( DBSeek( xFilial("SE2") + (cAliasAux)->PREFIXO  + (cAliasAux)->TITU  + Space(Len(SE2->E2_PARCELA)) + (cAliasAux)->TIPO + (cAliasAux)->FORNECE + (cAliasAux)->LOJA	) )
		_cErro:="Erro: [O titulo nao foi encontrdo apos a inclusao "+xFilial("SE2") +"+"+ (cAliasAux)->PREFIXO  +"+"+ (cAliasAux)->TITU +"+"+ Space(Len(SE2->E2_PARCELA)) +"+"+(cAliasAux)->TIPO +"+"+ (cAliasAux)->FORNECE +"+"+ (cAliasAux)->LOJA+"]"
		_lOk := .F.
	EndIf
EndIf

nModulo := _nModAux
cModulo := _cModAux

Return _lOk

/*
===============================================================================================================================
Programa----------: MFIN13Todos
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Mostra totais
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN13Todos(_lMarca)

(cAliasAux)->( DBGoTop() )

While (cAliasAux)->( !Eof() )

	If (cAliasAux)->WKSTATUS $ 'A'
		oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .T. )
	Else
		(cAliasAux)->(DBSkip())
		Loop
	EndIf

	If _lMarca //MARCA TODOS

		If (cAliasAux)->WKSTATUS $ 'A'

			(oMarkBRW:Alias())->MARCA := oMarkBRW:Mark()

			If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU })) # 0
				_aMarcados[_nPos,2]:=.T.
				//aMarcados[_nPos,3]:=AllTrim((cAliasAux)->WKPARCELA)+" - "+DToC((cAliasAux)->VENCREA)
			EndIf

		EndIf

	ElseIf oMarkBRW:IsMark() //DESMARCA TODOS

		(oMarkBRW:Alias())->MARCA := ""
		If (_nPos:=aScan(_aMarcados,{|T| T[1]==(cAliasAux)->FILIAL+(cAliasAux)->TITU })) # 0
			_aMarcados[_nPos,2]:=.F.//A colocação do .T. esta dentro da função MFIN13Tela("SE1",nReg,4)
			_aMarcados[_nPos,3]:="" //O preenchimento esta dentro da função MFIN13Tela("SE1",nReg,4)
		EndIf

	EndIf

	(cAliasAux)->( DBSkip() )

EndDo

(cAliasAux)->( DBGoTop() )
oMarkBRW:GoTo( (cAliasAux)->( Recno() ) , .T. )
//oMarkBRW:GoTop()
oMarkBRW:Refresh()

Return

/*
===============================================================================================================================
Programa----------: fGerNum()
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 12/05/2022
Descrição---------: Busca o proximo numero do titulo
Retorno-----------: No. do titulo 
===============================================================================================================================
*/
Static Function fGerNum()

Local cNumTit	:= ""
Local cAlsNum	:= GetNextAlias()
Local cQuery	:= ""

cQuery := " SELECT MAX(E2_NUM) NUMERO "
cQuery += " FROM " + RetSqlName("SE2") + " SE2 "
cQuery += " WHERE E2_PREFIXO = 'TAC' "
cQuery += "	AND SE2.D_E_L_E_T_ = ' ' "

If Select(cAlsNum) > 0; (cAlsNum)->(DBCloseArea()); EndIf
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlsNum,.T.,.T.)

If !Empty( (cAlsNum)->NUMERO )
	cNumTit := Soma1( (cAlsNum)->NUMERO )
Else
	cNumTit := StrZero(1,Len(SE2->E2_NUM))
EndIf

(cAlsNum)->(DBCloseArea())

Return(cNumTit)
